# Rewind Hourglass - XR Game Jam

VR Puzzle Platformer using an hourglass to rewind time. Help the robot overcome challenges by observing its past performance.

## 🎮 Quick Start

1. **Install Godot 4.6** - Download from [godotengine.org](https://godotengine.org/download/)
2. **Import Project** - Import `/storage/emulated/0/Code/rewind` as a Godot project
3. **Import Robot Scene** - Import `assets/models/robot_gobot.glb` as a scene in Godot
4. **Import XR Tools** - Clone [godot-xr-tools](https://github.com/godotxrtools/godot-xr-tools) to `addons/xr_tools/`
5. **Build for Quest 3** - Configure OpenXR and export for Android (120Hz)

### CURRENT ASSETS

| Asset | Source | Usage |
|-------|---|---|
| **robot_gobot.glb** | GDQuest 3D Characters | ✅ Main robot character (imported) |
| All robot variants | GDQuest | `assets/models/` - available alternatives |

### NOT NEEDED YET
- ❌ Kenny Assets - Skipped for now, create custom low-poly props manually
- ❌ External models - We're using what we have
- ❌ Audio placeholders - Can add SFX later

### Robot Assets Imported

- **Main Robot:** `robot_gobot.glb` (1.4MB, classic robot appearance)
- **GDQuest Repository:** [github.com/gdquest-demos/godot-4-3D-Characters](https://github.com/gdquest-demos/godot-4-3D-Characters)
- **All variants:** 6 robots in `assets/models/` (gobot, gdbot, beetle, bee, bat, sophia)
- **Documentation:** `assets/models/ROBOT_ASSETS_README.md`

---

## 📁 Project Structure

```
rewind/
├── addons/xr_tools/           # XR Tools plugin
├── assets/
│   ├── audio/               # Sound effects & music
│   ├── models/              # 3D models
│   │   ├── robot_gobot.glb    # ✅ Main robot character (GDQuest asset)
│   │   ├── robot_gdbot.glb    # Alternative robot
│   │   ├── robot_beetle.glb   # Alternative robot
│   │   ├── robot_bee.glb      # Alternative robot
│   │   ├── robot_bat.glb      # Specialized robot
│   │   ├── ROBOT_ASSETS_README.md  # Asset documentation
│   │   └── ...
│   ├── scenes/              # Godot scene files (.tscn)
│   │   ├── _base/          # Shared base scenes
│   │   ├── level_01.tscn   # ... level_10.tscn
│   │   ├── _ui/            # UI scenes
│   ├── scripts/            # GDScript files
│   │   ├── _base/          # Core system scripts
│   │   ├── _systems/       # Game system scripts
│   └── shaders/            # Custom shaders
├── project_root/           # Runtime scenes
│   └── main.tscn           # Entry point
└── README.md               # This file
```

## 🎯 Core Gameplay

- **Hourglass**: Grab, flip to rewind time, sideways to pause
- **Robot**: Walk-only movement, follow recorded paths from past attempts
- **Crystals**: Collect at levels 1, 3, 5, 7, 9 to increase rewind duration
- **Retry Button**: F key or controller menu button to restart attempt

## 🔧 Development

### Recommended Plugins

- **Godot XR Tools**: [godotxrtools/godot-xr-tools](https://github.com/godotxrtools/godot-xr-tools)
- **Kenny Assets**: [kenney.nl](https://kenney.nl/assets)

### Platform Support

- Quest 3 (standalone) - 120Hz target
- PCVR via OpenXR

## 📜 License

Game Jam entry - Theme: Rewind

---

See `PROJECT_PLAN.md` for full development timeline and architecture details.
