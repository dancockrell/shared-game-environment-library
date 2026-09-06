using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace SharedGames.CharacterBuilder
{
    // Engine adapter only. Construction and appearance decisions stay in the workshop.
    public static class SharedCharacterImport
    {
        [Serializable] private class Manifest
        {
            public int schemaVersion;
            public string model, modelSha256, format, units, upAxis, artStatus;
            public Appearance appearance;
            public Geometry geometry;
        }
        [Serializable] private class Appearance { public int schemaVersion; }
        [Serializable] private class Geometry { public int retained_meshes; }
        [Serializable] private class Resource { public string uri; }
        [Serializable] private class Gltf { public Resource[] buffers, images; }

        public static string Verify(string manifestPath)
        {
            var manifest = JsonUtility.FromJson<Manifest>(File.ReadAllText(manifestPath));
            if (manifest == null || manifest.schemaVersion != 1 || manifest.format != "glTF-2.0-binary" ||
                manifest.units != "metres" || manifest.upAxis != "Y")
                throw new InvalidDataException("Unsupported character package contract.");
            var name = manifest.model;
            if (String.IsNullOrEmpty(name) || name != Path.GetFileName(name) || name.Contains("\\") ||
                name.Contains("/") || name.Contains(":") || !name.EndsWith(".glb", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("Model must be a sibling GLB filename.");
            if (manifest.appearance == null || manifest.geometry == null || manifest.artStatus == null)
                throw new InvalidDataException("Missing character provenance.");
            var path = Path.Combine(Path.GetDirectoryName(Path.GetFullPath(manifestPath)), name);
            var bytes = File.ReadAllBytes(path);
            string hash;
            using (var sha = SHA256.Create())
                hash = BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "").ToLowerInvariant();
            if (hash != manifest.modelSha256)
                throw new InvalidDataException("Model does not match its character manifest.");
            if (bytes.Length < 20 || BitConverter.ToUInt32(bytes, 0) != 0x46546c67 ||
                BitConverter.ToUInt32(bytes, 4) != 2 || BitConverter.ToUInt32(bytes, 8) != bytes.Length ||
                BitConverter.ToUInt32(bytes, 16) != 0x4e4f534a)
                throw new InvalidDataException("Invalid GLB container.");
            var jsonLength = BitConverter.ToUInt32(bytes, 12);
            if (jsonLength > bytes.Length - 20) throw new InvalidDataException("Truncated GLB document.");
            var gltf = JsonUtility.FromJson<Gltf>(Encoding.UTF8.GetString(bytes, 20, (int)jsonLength));
            if (gltf == null) throw new InvalidDataException("Invalid GLB document.");
            foreach (var resources in new[] { gltf.buffers, gltf.images })
                if (resources != null)
                    foreach (var resource in resources)
                        if (resource == null || resource.uri != null)
                            throw new InvalidDataException("Character packages must embed all resources.");
            return path;
        }

        [MenuItem("Tools/Shared Character Builder/Import built character")]
        private static void Import()
        {
            var manifestPath = EditorUtility.OpenFilePanel("Built character manifest", "", "json");
            if (String.IsNullOrEmpty(manifestPath)) return;
            try
            {
                var source = Verify(manifestPath);
                const string root = "Assets/SharedCharacters";
                if (!AssetDatabase.IsValidFolder(root)) AssetDatabase.CreateFolder("Assets", "SharedCharacters");
                var folder = root + "/" + Guid.NewGuid().ToString("N");
                AssetDatabase.CreateFolder(root, Path.GetFileName(folder));
                var modelPath = folder + "/" + Path.GetFileName(source);
                var recordPath = folder + "/" + Path.GetFileName(manifestPath);
                File.Copy(source, modelPath, false);
                File.Copy(manifestPath, recordPath, false);
                // Recheck copied bytes before handing any model to the engine importer.
                Verify(recordPath);
                AssetDatabase.ImportAsset(recordPath, ImportAssetOptions.ForceSynchronousImport);
                AssetDatabase.ImportAsset(modelPath, ImportAssetOptions.ForceSynchronousImport);
                var model = AssetDatabase.LoadAssetAtPath<GameObject>(modelPath);
                if (model == null)
                    throw new InvalidOperationException("Files verified and copied to " + folder +
                        ", but no GLB model imported. Install Unity's com.unity.cloud.gltfast package, then reimport the GLB.");
                Selection.activeObject = model;
                EditorGUIUtility.PingObject(model);
                Debug.Log("Built character imported. Appearance record: " + recordPath +
                    ". Import does not grant final-art approval.", model);
            }
            catch (Exception error)
            {
                Debug.LogException(error);
                EditorUtility.DisplayDialog("Character import", error.Message, "OK");
            }
        }
    }
}
