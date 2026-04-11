using UnityEngine;

namespace KingdomCome.Supabase
{
    /// <summary>
    /// Drop this on a GameObject named [KingdomCome] in your first scene.
    /// It spawns all Supabase singletons and persists across scenes.
    /// </summary>
    public class KingdomComeBootstrap : MonoBehaviour
    {
        void Awake()
        {
            if (FindObjectsOfType<KingdomComeBootstrap>().Length > 1)
            {
                Destroy(gameObject);
                return;
            }

            DontDestroyOnLoad(gameObject);

            EnsureComponent<SupabaseClient>();
            EnsureComponent<AuthService>();
            EnsureComponent<GameDataService>();
            EnsureComponent<PlayerService>();

            Debug.Log("[KingdomCome] Supabase initialized — " + SupabaseConfig.ProjectUrl);
        }

        void EnsureComponent<T>() where T : Component
        {
            if (GetComponent<T>() == null)
                gameObject.AddComponent<T>();
        }
    }
}
