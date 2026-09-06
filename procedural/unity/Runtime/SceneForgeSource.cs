using UnityEngine;

namespace SharedEnvironment.SceneForge {
    /// One source snapshot per imported root, serialized with the scene.
    /// Manual engine edits are not written back into this construction recipe.
    [DisallowMultipleComponent]
    public sealed class SceneForgeSource : MonoBehaviour {
        [SerializeField, HideInInspector] private string recipeJson;
        public string RecipeJson => recipeJson;
        public void Initialize(string source) { recipeJson = source ?? ""; }
    }
}
