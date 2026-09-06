using System;
using System.IO;
using System.Text;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace SharedEnvironment.SceneForge {
    [Serializable] public sealed class MaterialData { public float roughness, metallic; }
    [Serializable] public sealed class PaintTextureData { public int width, height; public int[] rgba; }
    [Serializable] public sealed class MeshData { public string name; public float[] positions, normals, uvs, color; public int[] indices; public MaterialData material; public PaintTextureData paint_texture; }
    [Serializable] public sealed class InstanceData { public int mesh; public float[] position; public float yaw, scale; }
    [Serializable] public sealed class SceneData { public int version; public string coordinate_system, recipe_json; public MeshData[] meshes; public InstanceData[] instances; public long estimated_geometry_bytes; }
    [Serializable] public sealed class Response { public bool ok; public string error; public SceneData scene; }
    public static class Native {
        [DllImport("scene_forge", CallingConvention=CallingConvention.Cdecl)] private static extern IntPtr scene_forge_compile(byte[] input, UIntPtr length, out UIntPtr outputLength);
        [DllImport("scene_forge", CallingConvention=CallingConvention.Cdecl)] private static extern void scene_forge_free(IntPtr output, UIntPtr length);
        public static string Compile(string recipe) {
            byte[] bytes=Encoding.UTF8.GetBytes(recipe);
            if(bytes.Length>16*1024*1024) throw new ArgumentException("Recipe exceeds 16 MiB");
            UIntPtr length; IntPtr pointer=scene_forge_compile(bytes,(UIntPtr)bytes.Length,out length);
            if(pointer==IntPtr.Zero) throw new InvalidOperationException("Native compiler rejected the request");
            try { int n=checked((int)length.ToUInt64()); byte[] result=new byte[n]; Marshal.Copy(pointer,result,0,n); return Encoding.UTF8.GetString(result); }
            finally { scene_forge_free(pointer,length); }
        }
    }
    public sealed class SceneForgeWindow : EditorWindow {
        private Task<string> job;
        private string status="Local Rust generation; no server";
        [MenuItem("Tools/Scene Forge")]
        private static void Open() { GetWindow<SceneForgeWindow>("Scene Forge"); }
        private void OnGUI() {
            EditorGUILayout.HelpBox(status,MessageType.Info);
            if(GUILayout.Button("Export selected source recipe…")) ExportSource();
            using(new EditorGUI.DisabledScope(job!=null)) if(GUILayout.Button("Compile recipe into scene")) {
                string path=EditorUtility.OpenFilePanel("Procedural recipe","","json");
                if(!string.IsNullOrEmpty(path)) {
                    job=Task.Run(()=>{if(new FileInfo(path).Length>16*1024*1024) throw new IOException("Recipe exceeds 16 MiB");return Native.Compile(File.ReadAllText(path));});
                    status="Compiling…";
                }
            }
        }
        private void ExportSource() {
            var selected=Selection.activeGameObject;
            var source=selected!=null?selected.GetComponentInParent<SceneForgeSource>():null;
            if(source==null||string.IsNullOrEmpty(source.RecipeJson)) {
                status="No source snapshot: select an imported root or part. Older imports may lack the recipe.";
                return;
            }
            string path=EditorUtility.SaveFilePanel("Export original recipe (manual engine edits not included)","","scene-forge-recipe","json");
            if(string.IsNullOrEmpty(path)) return;
            try {
                File.WriteAllText(path,source.RecipeJson,new UTF8Encoding(false));
                status="Original recipe exported; manual engine edits are not included";
            } catch(Exception error) {status="Source export failed: "+error.Message;}
        }
        private void OnInspectorUpdate() {
            if(job==null||!job.IsCompleted) return;
            try {
                Response response=JsonUtility.FromJson<Response>(job.GetAwaiter().GetResult());
                if(!response.ok) throw new InvalidOperationException(response.error);
                Import(response.scene);
                status="Imported "+response.scene.instances.Length+" shared-mesh instances";
            } catch(Exception error) {status=error.Message;Debug.LogException(error);} finally {job=null;Repaint();}
        }
        public static GameObject Import(SceneData data) {
            if(data.version!=1||data.coordinate_system!="right-handed-y-up-ccw-metres") throw new InvalidDataException("Unsupported scene format");
            var meshes=new Mesh[data.meshes.Length];var materials=new Material[data.meshes.Length];
            Shader shader=Shader.Find("Universal Render Pipeline/Lit")??Shader.Find("Standard");
            if(shader==null) throw new InvalidOperationException("No supported lit shader found");
            for(int i=0;i<meshes.Length;i++) {
                MeshData source=data.meshes[i];var vertices=new Vector3[source.positions.Length/3];var normals=new Vector3[vertices.Length];var uv=new Vector2[vertices.Length];
                for(int j=0;j<vertices.Length;j++) {
                    vertices[j]=new Vector3(source.positions[j*3],source.positions[j*3+1],-source.positions[j*3+2]);
                    normals[j]=new Vector3(source.normals[j*3],source.normals[j*3+1],-source.normals[j*3+2]);
                    uv[j]=new Vector2(source.uvs[j*2],source.uvs[j*2+1]);
                }
                // Reflect Z into Unity's left-handed space; CCW becomes Unity's CW.
                var mesh=new Mesh{name=source.name,indexFormat=IndexFormat.UInt32};
                mesh.vertices=vertices;mesh.normals=normals;mesh.uv=uv;mesh.triangles=source.indices;mesh.RecalculateBounds();meshes[i]=mesh;
                var material=new Material(shader){name=source.name,enableInstancing=true};material.color=new Color(source.color[0],source.color[1],source.color[2],source.color[3]);
                float roughness=source.material!=null?source.material.roughness:0.85f;
                material.SetFloat("_Metallic",source.material!=null?source.material.metallic:0f);
                // Both supported shaders use smoothness; the portable recipe uses roughness.
                if(material.HasProperty("_Smoothness")) material.SetFloat("_Smoothness",1f-roughness);
                if(material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness",1f-roughness);
                if(material.HasProperty("_WorkflowMode")) material.SetFloat("_WorkflowMode",1f);
                if(source.paint_texture!=null) {
                    var pixels=source.paint_texture;
                    var texture=new Texture2D(pixels.width,pixels.height,TextureFormat.RGBA32,true,false){name=source.name+" painted underlayer",wrapMode=TextureWrapMode.Repeat,filterMode=FilterMode.Trilinear};
                    byte[] rgba=Array.ConvertAll(pixels.rgba,value=>checked((byte)value));
                    texture.LoadRawTextureData(rgba);texture.Apply(true,false);
                    material.color=Color.white;
                    material.mainTexture=texture;
                    if(material.HasProperty("_BaseMap")) material.SetTexture("_BaseMap",texture);
                }
                materials[i]=material;
            }
            var root=new GameObject("Scene Forge");Undo.RegisterCreatedObjectUndo(root,"Import procedural scene");
            root.AddComponent<SceneForgeSource>().Initialize(data.recipe_json);
            foreach(InstanceData instance in data.instances) {
                var item=new GameObject(data.meshes[instance.mesh].name);item.transform.SetParent(root.transform,false);
                item.transform.localPosition=new Vector3(instance.position[0],instance.position[1],-instance.position[2]);
                item.transform.localRotation=Quaternion.Euler(0,-instance.yaw*Mathf.Rad2Deg,0);item.transform.localScale=Vector3.one*instance.scale;
                item.AddComponent<MeshFilter>().sharedMesh=meshes[instance.mesh];item.AddComponent<MeshRenderer>().sharedMaterial=materials[instance.mesh];
            }
            Selection.activeGameObject=root;
            return root;
        }
    }
}
