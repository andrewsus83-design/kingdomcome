using System;
using System.Collections;
using UnityEngine;

namespace KingdomCome.Supabase
{
    /// <summary>
    /// Read/write player-specific data: progress, streaks, inventory, saints.
    /// Requires AuthService.Instance.UserId to be set.
    /// </summary>
    public class PlayerService : MonoBehaviour
    {
        public static PlayerService Instance { get; private set; }

        void Awake()
        {
            if (Instance != null) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        SupabaseClient DB  => SupabaseClient.Instance;
        string PlayerId    => AuthService.Instance.UserId;

        // ─── Player Profile ───────────────────────────────────────────────────

        public IEnumerator GetPlayer(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_players",
                $"id=eq.{PlayerId}&select=*", onSuccess, onError);
        }

        public IEnumerator UpdatePlayer(string json,
            Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Patch("kc_players", $"id=eq.{PlayerId}", json, onSuccess, onError);
        }

        // ─── Progress ─────────────────────────────────────────────────────────

        public IEnumerator GetProgress(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_player_progress",
                $"player_id=eq.{PlayerId}&select=*", onSuccess, onError);
        }

        public IEnumerator UpsertProgress(string json,
            Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Post("kc_player_progress", json, onSuccess, onError);
        }

        // ─── Cave Progress ────────────────────────────────────────────────────

        public IEnumerator GetCaveProgress(string caveId,
            Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_player_castle_progress",
                $"player_id=eq.{PlayerId}&cave_id=eq.{caveId}&select=*",
                onSuccess, onError);
        }

        // ─── Streaks ──────────────────────────────────────────────────────────

        public IEnumerator GetStreak(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_player_streaks",
                $"player_id=eq.{PlayerId}&select=*", onSuccess, onError);
        }

        public IEnumerator UpdateStreak(string json,
            Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Patch("kc_player_streaks",
                $"player_id=eq.{PlayerId}", json, onSuccess, onError);
        }

        // ─── Inventory ────────────────────────────────────────────────────────

        public IEnumerator GetInventory(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_player_inventory",
                $"player_id=eq.{PlayerId}&select=*&order=created_at.desc",
                onSuccess, onError);
        }

        // ─── Saints Collection ────────────────────────────────────────────────

        public IEnumerator GetMySaints(Action<string> onSuccess, Action<string> onError = null)
        {
            string q = $"player_id=eq.{PlayerId}&select=saint_id,devotion_level,is_equipped,kc_saints(id,name,name_id,portrait_url,passive_ability)";
            yield return DB.Get("kc_player_saints", q, onSuccess, onError);
        }

        // ─── Boss Kills ───────────────────────────────────────────────────────

        public IEnumerator GetBossKills(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_player_boss_kills",
                $"player_id=eq.{PlayerId}&select=*", onSuccess, onError);
        }

        public IEnumerator RecordBossKill(string bossId, string caveId,
            Action<string> onSuccess, Action<string> onError = null)
        {
            string json = $"{{\"player_id\":\"{PlayerId}\",\"boss_id\":\"{bossId}\",\"cave_id\":\"{caveId}\"}}";
            yield return DB.Post("kc_player_boss_kills", json, onSuccess, onError);
        }

        // ─── Journal (scroll unlocks) ─────────────────────────────────────────

        public IEnumerator GetJournal(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_player_journal",
                $"player_id=eq.{PlayerId}&select=*&order=unlocked_at.desc",
                onSuccess, onError);
        }
    }
}
