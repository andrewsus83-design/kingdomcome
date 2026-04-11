using System;
using System.Collections;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;

namespace KingdomCome.Supabase
{
    /// <summary>
    /// Core HTTP client for Supabase REST API.
    /// Attach to a persistent GameObject — use SupabaseManager.Instance.
    /// </summary>
    public class SupabaseClient : MonoBehaviour
    {
        public static SupabaseClient Instance { get; private set; }

        // Set after successful login via AuthService
        public string AccessToken { get; set; }

        void Awake()
        {
            if (Instance != null) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        // ─── GET ──────────────────────────────────────────────────────────────

        public IEnumerator Get(string table, string query,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url = $"{SupabaseConfig.RestUrl}/{table}?{query}";
            using var req = UnityWebRequest.Get(url);
            AddHeaders(req);
            yield return req.SendWebRequest();
            HandleResponse(req, onSuccess, onError);
        }

        // ─── POST ─────────────────────────────────────────────────────────────

        public IEnumerator Post(string table, string json,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url = $"{SupabaseConfig.RestUrl}/{table}";
            using var req = new UnityWebRequest(url, "POST");
            req.uploadHandler   = new UploadHandlerRaw(Encoding.UTF8.GetBytes(json));
            req.downloadHandler = new DownloadHandlerBuffer();
            AddHeaders(req, withJson: true);
            yield return req.SendWebRequest();
            HandleResponse(req, onSuccess, onError);
        }

        // ─── PATCH ────────────────────────────────────────────────────────────

        public IEnumerator Patch(string table, string query, string json,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url = $"{SupabaseConfig.RestUrl}/{table}?{query}";
            using var req = new UnityWebRequest(url, "PATCH");
            req.uploadHandler   = new UploadHandlerRaw(Encoding.UTF8.GetBytes(json));
            req.downloadHandler = new DownloadHandlerBuffer();
            AddHeaders(req, withJson: true);
            yield return req.SendWebRequest();
            HandleResponse(req, onSuccess, onError);
        }

        // ─── RPC ──────────────────────────────────────────────────────────────

        public IEnumerator Rpc(string functionName, string json,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url = $"{SupabaseConfig.RestUrl}/rpc/{functionName}";
            using var req = new UnityWebRequest(url, "POST");
            req.uploadHandler   = new UploadHandlerRaw(Encoding.UTF8.GetBytes(json));
            req.downloadHandler = new DownloadHandlerBuffer();
            AddHeaders(req, withJson: true);
            yield return req.SendWebRequest();
            HandleResponse(req, onSuccess, onError);
        }

        // ─── Helpers ──────────────────────────────────────────────────────────

        void AddHeaders(UnityWebRequest req, bool withJson = false)
        {
            req.SetRequestHeader("apikey", SupabaseConfig.AnonKey);
            req.SetRequestHeader("Authorization",
                string.IsNullOrEmpty(AccessToken)
                    ? $"Bearer {SupabaseConfig.AnonKey}"
                    : $"Bearer {AccessToken}");

            if (withJson)
                req.SetRequestHeader("Content-Type", "application/json");

            req.SetRequestHeader("Prefer", "return=representation");
        }

        void HandleResponse(UnityWebRequest req,
            Action<string> onSuccess, Action<string> onError)
        {
            if (req.result == UnityWebRequest.Result.Success)
                onSuccess?.Invoke(req.downloadHandler.text);
            else
            {
                string err = $"[Supabase] {req.responseCode} — {req.downloadHandler.text}";
                Debug.LogError(err);
                onError?.Invoke(err);
            }
        }
    }
}
