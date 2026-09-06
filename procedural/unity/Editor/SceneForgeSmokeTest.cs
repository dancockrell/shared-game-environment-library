using System;
using System.IO;
using UnityEditor;
using UnityEngine;
namespace SharedEnvironment.SceneForge {
    public static class SceneForgeSmokeTest {
        public static void Run() {
            try {
                string[] args=Environment.GetCommandLineArgs();
                int index=Array.IndexOf(args,"-sceneForgeRecipe");
                if(index<0||index+1>=args.Length) throw new Exception("Recipe argument missing");
                Response answer=JsonUtility.FromJson<Response>(Native.Compile(File.ReadAllText(args[index+1])));
                if(!answer.ok) throw new Exception(answer.error);
                if(answer.scene.instances.Length!=52||answer.scene.meshes.Length!=8) throw new Exception("Unexpected fixture counts");
                GameObject root=SceneForgeWindow.Import(answer.scene);
                MeshFilter[] filters=root.GetComponentsInChildren<MeshFilter>();
                if(filters.Length!=52) throw new Exception("Instances lost in Unity adapter");
                foreach(MeshFilter item in filters) if(item.sharedMesh.vertexCount==0||item.sharedMesh.normals.Length!=item.sharedMesh.vertexCount) throw new Exception("Invalid imported mesh");
                if(filters[0].sharedMesh!=filters[13].sharedMesh) throw new Exception("Repeated floor mesh is not shared");
                Debug.Log("SCENE_FORGE_UNITY_PASS: 52 instances, 8 shared meshes, native ABI and coordinate adapter loaded");
                UnityEngine.Object.DestroyImmediate(root);
                EditorApplication.Exit(0);
            } catch(Exception error) {Debug.LogException(error);EditorApplication.Exit(1);}
        }
    }
}
