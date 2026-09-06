using System;
using System.IO;
using System.Collections.Generic;
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
                GameObject root=SceneForgeWindow.Import(answer.scene);
                var recipeSource=root.GetComponent<SceneForgeSource>();
                if(recipeSource==null||recipeSource.RecipeJson!=answer.scene.recipe_json) throw new Exception("Source snapshot lost at import");
                var restoredObject=new GameObject("Recipe serialization check");
                var restoredSource=restoredObject.AddComponent<SceneForgeSource>();
                EditorJsonUtility.FromJsonOverwrite(EditorJsonUtility.ToJson(recipeSource),restoredSource);
                if(restoredSource.RecipeJson!=recipeSource.RecipeJson) throw new Exception("Source snapshot lost in component serialization");
                Response rebuilt=JsonUtility.FromJson<Response>(Native.Compile(restoredSource.RecipeJson));
                if(!rebuilt.ok||rebuilt.scene.recipe_json!=answer.scene.recipe_json) throw new Exception("Restored source cannot be recompiled");
                UnityEngine.Object.DestroyImmediate(restoredObject);
                MeshFilter[] filters=root.GetComponentsInChildren<MeshFilter>();
                if(filters.Length!=answer.scene.instances.Length) throw new Exception("Instances lost in Unity adapter");
                foreach(MeshFilter item in filters) if(item.sharedMesh.vertexCount==0||item.sharedMesh.normals.Length!=item.sharedMesh.vertexCount) throw new Exception("Invalid imported mesh");
                var sharedMeshes=new Dictionary<int,Mesh>();
                var sharedMaterials=new Dictionary<int,Material>();
                for(int i=0;i<filters.Length;i++) {
                    int meshIndex=answer.scene.instances[i].mesh;
                    MeshData source=answer.scene.meshes[meshIndex];
                    Material material=filters[i].GetComponent<MeshRenderer>().sharedMaterial;
                    if(sharedMeshes.ContainsKey(meshIndex)) {
                        if(sharedMeshes[meshIndex]!=filters[i].sharedMesh||sharedMaterials[meshIndex]!=material) throw new Exception("Repeated geometry or material is not shared");
                    } else {sharedMeshes.Add(meshIndex,filters[i].sharedMesh);sharedMaterials.Add(meshIndex,material);}
                    float roughness=source.material!=null?source.material.roughness:0.85f;
                    float metallic=source.material!=null?source.material.metallic:0f;
                    if(source.paint_texture!=null && (material.mainTexture==null || material.mainTexture.width!=source.paint_texture.width || material.mainTexture.height!=source.paint_texture.height)) throw new Exception("Paint texture missing or resized");
                    if(!Mathf.Approximately(material.GetFloat("_Metallic"),metallic)) throw new Exception("Metallic setting lost");
                    string smoothProperty=material.HasProperty("_Smoothness")?"_Smoothness":"_Glossiness";
                    if(!Mathf.Approximately(material.GetFloat(smoothProperty),1f-roughness)) throw new Exception("Roughness to smoothness conversion lost");
                }
                Debug.Log("SCENE_FORGE_UNITY_PASS: "+filters.Length+" instances, "+sharedMeshes.Count+" shared meshes; materials verified");
                UnityEngine.Object.DestroyImmediate(root);
                EditorApplication.Exit(0);
            } catch(Exception error) {Debug.LogException(error);EditorApplication.Exit(1);}
        }
    }
}
