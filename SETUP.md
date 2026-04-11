# Kingdom Come — Setup Guide

## 1. Ludo AI MCP (Claude Code)

Already configured. On next Claude Code session restart, `ludo` tools will be available.

**Config files:**
- `.mcp.json` — Ludo MCP server URL
- `.claude/settings.json` — enables the ludo MCP server
- `.claude/settings.local.json` — holds `LUDO_API_KEY` (gitignored)

**Verify it works:** After restart, run `/mcp` in Claude Code — you should see `ludo` listed as connected.

---

## 2. Unity → Supabase

### Quick Start

1. Copy `Unity/Scripts/Supabase/` into your Unity project under `Assets/Scripts/Supabase/`
2. Create an empty GameObject in your **first scene**, name it `[KingdomCome]`
3. Add the `KingdomComeBootstrap` component to it
4. That's it — all services auto-initialize and persist across scenes

### Usage Examples

```csharp
// ── Auth ──────────────────────────────────────────────────────────────
StartCoroutine(AuthService.Instance.SignIn("player@email.com", "password",
    onSuccess: json => Debug.Log("Logged in: " + json),
    onError:   err  => Debug.LogError(err)
));

// ── Load all caves ────────────────────────────────────────────────────
StartCoroutine(GameDataService.Instance.GetAllCaves(
    onSuccess: json => Debug.Log(json)
));

// ── Load floors for a cave ────────────────────────────────────────────
StartCoroutine(GameDataService.Instance.GetCaveFloors("cave_genesis",
    onSuccess: json => Debug.Log(json)
));

// ── Load a boss ───────────────────────────────────────────────────────
StartCoroutine(GameDataService.Instance.GetBoss("boss_serpent",
    onSuccess: json => Debug.Log(json)
));

// ── Player streak ─────────────────────────────────────────────────────
StartCoroutine(PlayerService.Instance.GetStreak(
    onSuccess: json => Debug.Log(json)
));

// ── Record boss kill ──────────────────────────────────────────────────
StartCoroutine(PlayerService.Instance.RecordBossKill(
    bossId: "boss_serpent", caveId: "cave_genesis",
    onSuccess: json => Debug.Log("Boss killed!")
));
```

### Project Constants

| | Value |
|---|---|
| **Supabase URL** | `https://diyimabdmsjykvitomgd.supabase.co` |
| **Anon Key** | see `SupabaseConfig.cs` |

### File Structure

```
Unity/Scripts/Supabase/
  SupabaseConfig.cs          ← URL + anon key
  SupabaseClient.cs          ← GET / POST / PATCH / RPC
  KingdomComeBootstrap.cs    ← Drop on first-scene GameObject
  Services/
    AuthService.cs           ← SignIn / SignUp / SignOut
    GameDataService.cs       ← Caves, floors, enemies, saints, config
    PlayerService.cs         ← Progress, streaks, inventory, boss kills
```

### Active Phase 1 Data

| Table | Count | Notes |
|---|---|---|
| kc_prophets | 35 active | All have portrait_url |
| kc_caves | 18 main caves | All have boss + enemy_pool |
| kc_floors | 200 | All have bilingual narratives |
| kc_enemies | 29 active | All have portrait_url |
| kc_bosses | 14 active | All have portrait_url |
| kc_saints | 44 active | portrait_url linked |
| kc_classes | 7 | Mystic, Sage, Warrior, etc. |
