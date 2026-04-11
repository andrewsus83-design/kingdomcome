using System;
using System.Collections;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;

namespace KingdomCome.Supabase
{
    public class AuthService : MonoBehaviour
    {
        public static AuthService Instance { get; private set; }

        public bool IsLoggedIn => !string.IsNullOrEmpty(SupabaseClient.Instance?.AccessToken);
        public string UserId   { get; private set; }
        public string Email    { get; private set; }

        void Awake()
        {
            if (Instance != null) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        // ─── Sign Up ──────────────────────────────────────────────────────────

        public IEnumerator SignUp(string email, string password,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url  = $"{SupabaseConfig.AuthUrl}/signup";
            string body = $"{{\"email\":\"{email}\",\"password\":\"{password}\"}}";
            yield return AuthPost(url, body, onSuccess, onError);
        }

        // ─── Sign In ──────────────────────────────────────────────────────────

        public IEnumerator SignIn(string email, string password,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url  = $"{SupabaseConfig.AuthUrl}/token?grant_type=password";
            string body = $"{{\"email\":\"{email}\",\"password\":\"{password}\"}}";
            yield return AuthPost(url, body, (json) =>
            {
                var resp = JsonUtility.FromJson<AuthResponse>(json);
                SupabaseClient.Instance.AccessToken = resp.access_token;
                UserId = resp.user?.id;
                Email  = email;
                onSuccess?.Invoke(json);
            }, onError);
        }

        // ─── Sign Out ─────────────────────────────────────────────────────────

        public IEnumerator SignOut(Action onDone = null)
        {
            string url = $"{SupabaseConfig.AuthUrl}/logout";
            using var req = new UnityWebRequest(url, "POST");
            req.downloadHandler = new DownloadHandlerBuffer();
            req.SetRequestHeader("apikey", SupabaseConfig.AnonKey);
            req.SetRequestHeader("Authorization",
                $"Bearer {SupabaseClient.Instance.AccessToken}");
            yield return req.SendWebRequest();
            SupabaseClient.Instance.AccessToken = null;
            UserId = null;
            Email  = null;
            onDone?.Invoke();
        }

        // ─── Refresh Token ────────────────────────────────────────────────────

        public IEnumerator RefreshSession(string refreshToken,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string url  = $"{SupabaseConfig.AuthUrl}/token?grant_type=refresh_token";
            string body = $"{{\"refresh_token\":\"{refreshToken}\"}}";
            yield return AuthPost(url, body, (json) =>
            {
                var resp = JsonUtility.FromJson<AuthResponse>(json);
                SupabaseClient.Instance.AccessToken = resp.access_token;
                onSuccess?.Invoke(json);
            }, onError);
        }

        // ─── Internal ─────────────────────────────────────────────────────────

        IEnumerator AuthPost(string url, string body,
            Action<string> onSuccess, Action<string> onError)
        {
            using var req = new UnityWebRequest(url, "POST");
            req.uploadHandler   = new UploadHandlerRaw(Encoding.UTF8.GetBytes(body));
            req.downloadHandler = new DownloadHandlerBuffer();
            req.SetRequestHeader("apikey", SupabaseConfig.AnonKey);
            req.SetRequestHeader("Content-Type", "application/json");
            yield return req.SendWebRequest();

            if (req.result == UnityWebRequest.Result.Success)
                onSuccess?.Invoke(req.downloadHandler.text);
            else
            {
                string err = $"[Auth] {req.responseCode} — {req.downloadHandler.text}";
                Debug.LogError(err);
                onError?.Invoke(err);
            }
        }

        // ─── Response Models ──────────────────────────────────────────────────

        [Serializable] class AuthResponse
        {
            public string access_token;
            public string refresh_token;
            public AuthUser user;
        }

        [Serializable] class AuthUser
        {
            public string id;
            public string email;
        }
    }
}
