# Kingdom Come — Claude Code Guidelines

## Project Overview
Kingdom Come is a Unity game project. All game logic is written in C#.

## Unity Environment

### Unity Version
- Check `ProjectSettings/ProjectVersion.txt` for the exact Unity version.
- Use Unity Hub or the matching Unity Editor CLI for builds.

### Build Commands
```bash
# Build for Linux (headless)
/path/to/Unity -batchmode -quit -projectPath . \
  -buildTarget Linux64 -executeMethod BuildScript.Build

# Run tests (EditMode + PlayMode)
/path/to/Unity -batchmode -quit -projectPath . \
  -runTests -testPlatform EditMode -testResults results/edit.xml

/path/to/Unity -batchmode -quit -projectPath . \
  -runTests -testPlatform PlayMode -testResults results/play.xml
```

### Code Style (C#)
- Follow Microsoft C# coding conventions.
- Use PascalCase for public members, camelCase for private fields with underscore prefix (`_fieldName`).
- Keep MonoBehaviour classes focused — prefer composition over inheritance.
- Avoid `Update()` polling; use events and coroutines instead.
- Always null-check `GameObject` and `Component` references obtained at runtime.

### Asset Organization
```
Assets/
  _Game/
    Scripts/       # All C# scripts
    Prefabs/       # Prefabs
    ScriptableObjects/
    Scenes/
    UI/
  Plugins/         # Third-party assets (read-only)
  Resources/       # Only assets that must be loaded by name at runtime
```

### Common Unity CLI Flags
| Flag | Purpose |
|------|---------|
| `-batchmode` | Headless / no display |
| `-quit` | Exit after operation |
| `-nographics` | Skip GPU initialization |
| `-logFile -` | Stream log to stdout |
| `-projectPath <path>` | Path to Unity project root |

## Development Workflow

1. **Never commit** `Library/`, `Temp/`, `obj/`, or `*.csproj` files.
2. Scene files (`.unity`) are binary — avoid large merge conflicts by splitting scenes into prefabs.
3. Use Git LFS for large binary assets (textures, audio, models).
4. Run tests before every commit; check the test results XML for failures.

## unity-dev-toolkit

This project uses the **unity-dev-toolkit** Claude Code plugin which provides:
- C# LSP integration via `csharp-lsp` for IntelliSense-style code navigation
- Unity build & test helpers
- Automated `.gitignore` management for Unity projects
