# Kingdom Come — Audio Assets

All audio files are served from Cloudflare R2:
`https://assets.kingdomcomeapp.com/audio/...`

## Folder Structure

```
assets/audio/
├── music/
│   ├── themes/         # App & screen background music (Suno)
│   ├── saints/         # Per-saint theme music (Suno)
│   ├── seasons/        # Liturgical season ambience (Suno)
│   └── minigames/      # Mini-game background tracks (Suno)
├── narration/
│   ├── quests/         # Quest intro/completion narration (Modal TTS)
│   ├── saints/         # Saint biography narration (Modal TTS)
│   └── bible/          # Bible verse narration (Modal TTS)
└── sfx/                # UI sound effects (short clips)
```

## Source by Type

| Folder | Source | Format | Notes |
|---|---|---|---|
| `music/themes/` | Suno AI | MP3 | Pre-generated, upload to R2 |
| `music/saints/` | Suno AI | MP3 | One track per saint |
| `music/seasons/` | Suno AI | MP3 | 7 liturgical seasons |
| `music/minigames/` | Suno AI | MP3 | One per game type |
| `narration/` | Modal TTS (Bark) | WAV | Generated on-demand or cached |
| `sfx/` | Free sources | MP3/WAV | Button clicks, level up, etc. |

## Naming Convention

```
music/themes/main-theme.mp3
music/themes/kingdom-screen.mp3
music/themes/bible-reading.mp3
music/themes/prayer-time.mp3
music/themes/quiz-screen.mp3

music/saints/st-francis-of-assisi.mp3
music/saints/st-therese-of-lisieux.mp3
music/saints/st-joan-of-arc.mp3
... (one per saint slug)

music/seasons/advent.mp3
music/seasons/christmas.mp3
music/seasons/lent.mp3
music/seasons/holy-week.mp3
music/seasons/easter.mp3
music/seasons/ordinary-time.mp3
music/seasons/pentecost.mp3

music/minigames/saint-defender.mp3
music/minigames/scripture-builder.mp3
music/minigames/rosary-runner.mp3
music/minigames/virtue-forge.mp3
music/minigames/bible-trivial-duel.mp3
music/minigames/liturgy-calendar.mp3

sfx/button-tap.mp3
sfx/level-up.mp3
sfx/quest-complete.mp3
sfx/saint-unlock.mp3
sfx/coin-collect.mp3
sfx/streak-milestone.mp3
sfx/wrong-answer.mp3
sfx/correct-answer.mp3
```

## Suno Prompts

### Main Theme
```
Epic Catholic orchestral hymn, children's adventure game theme, choir of angels,
Gregorian chant elements blended with modern orchestral, triumphant and uplifting,
major key, 120bpm, suitable for ages 8-18, no lyrics
```

### Kingdom Screen
```
Medieval Catholic monastery ambience, peaceful Gregorian chant background,
soft organ and string ensemble, contemplative and serene, 70bpm, loopable, no lyrics
```

### Lent Season
```
Somber Catholic Lenten music, minor key, cello and oboe, penitential and reflective,
ancient chant motifs, 60bpm, loopable ambient, no lyrics
```

### Easter Season
```
Joyful Catholic Easter hymn, alleluia orchestral fanfare, full choir, bells,
triumphant resurrection theme, 130bpm, major key, uplifting, no lyrics
```

### Saint Defender (Mini-game)
```
Heroic Catholic battle hymn, fast-paced orchestral action, crusader drums,
trumpet fanfare, 150bpm, exciting and intense but still sacred, no lyrics
```

## R2 Upload

After generating with Suno, upload files to R2:
```bash
# Using wrangler R2
wrangler r2 object put kingdom-come-assets/audio/music/themes/main-theme.mp3 \
  --file ./main-theme.mp3 \
  --content-type audio/mpeg

# Or bulk upload via R2 dashboard at:
# https://dash.cloudflare.com → R2 → kingdom-come-assets → Upload
```
