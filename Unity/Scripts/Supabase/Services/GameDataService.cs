using System;
using System.Collections;
using UnityEngine;

namespace KingdomCome.Supabase
{
    /// <summary>
    /// Fetch read-only game content: caves, floors, prophets, enemies, saints, config.
    /// All data is public (anon key sufficient).
    /// </summary>
    public class GameDataService : MonoBehaviour
    {
        public static GameDataService Instance { get; private set; }

        void Awake()
        {
            if (Instance != null) { Destroy(gameObject); return; }
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }

        SupabaseClient DB => SupabaseClient.Instance;

        // ─── Game Config ──────────────────────────────────────────────────────

        public IEnumerator GetGameConfig(Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_game_config", "select=key,value", onSuccess, onError);
        }

        // ─── Prophets (Playable Characters) ───────────────────────────────────

        public IEnumerator GetAllProphets(Action<string> onSuccess, Action<string> onError = null)
        {
            string q = "select=id,name,name_id,portrait_url,art_status,live2d_status&is_archived=eq.false&order=name";
            yield return DB.Get("kc_prophets", q, onSuccess, onError);
        }

        public IEnumerator GetProphet(string prophetId, Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_prophets", $"id=eq.{prophetId}", onSuccess, onError);
        }

        // ─── Caves ────────────────────────────────────────────────────────────

        public IEnumerator GetAllCaves(Action<string> onSuccess, Action<string> onError = null)
        {
            string q = "select=id,name,name_id,cave_type,region,boss_enemy_id,enemy_pool,floor_count,is_unlocked&order=id";
            yield return DB.Get("kc_caves", q, onSuccess, onError);
        }

        public IEnumerator GetCave(string caveId, Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_caves", $"id=eq.{caveId}&select=*", onSuccess, onError);
        }

        // ─── Floors ───────────────────────────────────────────────────────────

        public IEnumerator GetCaveFloors(string caveId, Action<string> onSuccess, Action<string> onError = null)
        {
            string q = $"cave_id=eq.{caveId}&select=id,floor_num,theme,transition_narrative,transition_narrative_id,boss_config&order=floor_num";
            yield return DB.Get("kc_floors", q, onSuccess, onError);
        }

        public IEnumerator GetFloor(string caveId, int floorNum, Action<string> onSuccess, Action<string> onError = null)
        {
            string q = $"cave_id=eq.{caveId}&floor_num=eq.{floorNum}&select=*";
            yield return DB.Get("kc_floors", q, onSuccess, onError);
        }

        // ─── Enemies & Bosses ─────────────────────────────────────────────────

        public IEnumerator GetEnemiesByCave(string caveId, Action<string> onSuccess, Action<string> onError = null)
        {
            string q = $"cave_id=eq.{caveId}&is_archived=eq.false&select=id,name,name_id,is_boss,hp,attack,defense,speed,portrait_url,weakness,vice_type,lore_text,exp_reward,faith_reward&order=is_boss";
            yield return DB.Get("kc_enemies", q, onSuccess, onError);
        }

        public IEnumerator GetBoss(string bossId, Action<string> onSuccess, Action<string> onError = null)
        {
            string q = $"id=eq.{bossId}&is_boss=eq.true&select=*";
            yield return DB.Get("kc_enemies", q, onSuccess, onError);
        }

        // ─── Saints ───────────────────────────────────────────────────────────

        public IEnumerator GetAllSaints(Action<string> onSuccess, Action<string> onError = null)
        {
            string q = "is_archived=eq.false&select=id,name,name_id,title,category,portrait_url,lore_text,passive_ability,feast_date,drop_rate&order=name";
            yield return DB.Get("kc_saints", q, onSuccess, onError);
        }

        public IEnumerator GetSaint(string saintId, Action<string> onSuccess, Action<string> onError = null)
        {
            yield return DB.Get("kc_saints", $"id=eq.{saintId}&is_archived=eq.false&select=*", onSuccess, onError);
        }

        // ─── Cave Scrolls ─────────────────────────────────────────────────────

        public IEnumerator GetCaveScrolls(string caveId, Action<string> onSuccess, Action<string> onError = null)
        {
            string q = $"cave_id=eq.{caveId}&select=id,floor_num,title,story_text,key_verses,themes,didache_point,journey_teaser&order=floor_num";
            yield return DB.Get("kc_cave_scrolls", q, onSuccess, onError);
        }

        // ─── Classes ──────────────────────────────────────────────────────────

        public IEnumerator GetClasses(Action<string> onSuccess, Action<string> onError = null)
        {
            string q = "select=id,slug,name,name_id,description,description_id,primary_stat,bonus_type,bonus_value,bonus_unit,icon,color_hex&order=sort_order";
            yield return DB.Get("kc_classes", q, onSuccess, onError);
        }

        // ─── Streak Elixir Tiers ──────────────────────────────────────────────

        public IEnumerator GetElixirTiers(Action<string> onSuccess, Action<string> onError = null)
        {
            string q = "select=id,streak_day_min,streak_day_max,elixir_count,label,label_id&order=streak_day_min";
            yield return DB.Get("kc_streak_elixir_tiers", q, onSuccess, onError);
        }
    }
}
