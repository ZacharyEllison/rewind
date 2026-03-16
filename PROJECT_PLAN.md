# 🎮 Rewind Hourglass - XR Game Jam Project

## 📋 Project Overview

**IMPORTANT:** Before making any changes, check [AGENTS.md](AGENTS.md) for context reference rules and the project.godot lesson.

## 📦 Project Structure

| Property | Value |
|----------|-------|
| **Game Jam Theme** | Rewind |
| **Engine** | Godot 4.x |
| **Platforms** | Quest 3 (standalone), PCVR |
| **Dev Duration** | 1 week (solo) |
| **Play Mode** | Seated XR |
| **Perspective** | First-person hands, overhead robot view (Astro Bot style) |
| **Input** | Controllers only (no hand tracking) |
| **Core Mechanic** | Hourglass flip = rewind time (sideways = pause) |
| **Art Style** | Low-poly (Kenny Assets) |

---

## 🎯 Core Gameplay Loop

```
[Attempt 1]
Player controls Robot → walks for 30 seconds → collects crystal (optional) → flips hourglass
	↓
[RECORDING PHASE]
Timestamp: t=0 to t=30 | Robot position saved every frame/keyframe
	↓
[REWIND PHASE]
Hourglass flipped → Past-Bot instance plays back recorded path (uncontrollable)
	↓
[ATTEMPT 2]
Player controls Robot AGAIN → uses knowledge from Past-Bot's path → reaches goal
    ↓
[RETRY BUTTON]
Can restart current attempt anytime without resetting level progression
```

---

## 📦 Project Structure

```
/storage/emulated/0/Code/rewind/
├── project.godot                 # Project configuration
├── PROJECT_PLAN.md               # This document
├── README.md                     # Quick start instructions
├── addons/                       # External templates
│   └── xr_tools/                # Godot XR Tools package
├── assets/
│   ├── audio/                   # SFX/music (placeholder for now)
│   ├── models/                  # 3D models
│   │   ├── robot_gobot.glb      # ✅ Main robot (GDQuest asset)
│   │   ├── ...                  # Alternative robots available
│   │   ├── ROBOT_ASSETS_README.md
│   ├── scenes/                  # Godot scene files
│   │   ├── _base/              # Shared base scenes (level_template, robot, hourglass)
│   │   ├── level_01.tscn       # Level 1: Robot to crystal (baseline)
│   │   ├── level_02.tscn       # Level 2: Button + platform lift
│   │   ├── level_03.tscn       # ...
│   │   ├── level_04.tscn       # ...
│   │   ├── level_05.tscn       # Level 5: Crystal #2
│   │   ├── level_06.tscn       # ...
│   │   ├── level_07.tscn       # Level 7: Crystal #3
│   │   ├── level_08.tscn       # ...
│   │   ├── level_09.tscn       # Level 9: Crystal #4
│   │   ├── level_10.tscn       # Level 10: Final level
│   │   ├── _ui/                # UI scenes
│   │   ├── main_menu.tscn      # Title screen
│   │   ├── level_select.tscn   # Level selection
│   │   ├── game_over.tscn      # Level complete/retry screen
│   │   ├── pause_menu.tscn     # Pause options
│   ├── scripts/                 # GDScript files
│   │   ├── _base/
│   │   │   ├── Robot.gd
│   │   │   ├── Hourglass.gd
│   │   │   ├── TimeRecorder.gd
│   │   │   ├── TimePlayback.gd
│   │   │   └── SandSystem.gd
│   │   ├── _systems/
│   │   │   ├── XRInputHandler.gd
│   │   │   ├── LevelManager.gd
│   │   │   ├── GameState.gd
│   │   └── _ui/
│   │       ├── UIManager.gd
│   │       ├── SandCounter.gd
│   │       └── PauseMenu.gd
│   ├── shaders/                  # Custom shaders
│   └── textures/                # UI textures
├── project_root/                 # Runtime scenes
│   └── main.tscn                # Entry point
└── .git/                        # Git repository
```

---

## 🤖 Robot Character Assets - CURRENT STATE

### ✅ Primary Choice: **robot_gobot.glb**
- **Source:** GDQuest Godot 4 3D Characters Demo
- **Repository:** [github.com/gdquest-demos/godot-4-3D-Characters](https://github.com/gdquest-demos/godot-4-3D-Characters)
- **Local Path:** `assets/models/robot_gobot.glb`
- **File Size:** 1.4MB (optimal for Quest 3 performance)
- **Features:**
  - ✅ Classic robot appearance - perfect for "little robot" concept
  - ✅ Cylindrical body + wheels - easy to identify in overhead view
  - ✅ Recognizable robot silhouette from all angles
- **Usage:** Main robot character, player-controlled during each attempt

### Alternative Robots Available
| Robot | Size | Description |
|-------|----|--------|
| robot_gdbot | 3.3MB | Box-shaped robot alternative |
| robot_beetle | 1.8MB | Insect-like hexapod robot |
| robot_bee | 2.8MB | Bee-inspired robot |
| robot_bat | 668KB | Flying bat robot (specialized) |

### Asset Documentation
- **Imported to project:** ✅ All robot GLB files in `assets/models/`
- **Documentation:** `assets/models/ROBOT_ASSETS_README.md`
- **Import instruction:** `File → Import... → Select robot_gobot.glb → Import as Scene`

### ⚠️ Kenny Assets - SKIPPED FOR NOW
- **Decision:** No Kenny assets needed at this time
- **Reason:** We have robot assets, can create custom low-poly props later
- **Focus:** Start development with what we have

---

## 🎮 Core Systems Architecture

### 1. Hourglass System
```gdscript
# Hourglass.gd
extends RigidBody3D

# Signals
signal flip_detected
signal sand_amount_updated(amount)

# Core functions
func trigger_rewind():
    TimeSystem.start_rewind()
    
func trigger_pause():
    TimeSystem.pause_rewind()
    
func get_rotation_axis() -> String:
    # Returns "X", "Y", or "Z" based on flip direction
    pass
```

### 2. Time Recorder
```gdscript
# TimeRecorder.gd
extends Node

var recorded_positions: Array[Vector3] = []
var recorded_timestamps: Array[float] = []
var recording_active: bool = false

func start_recording():
    recorded_positions.clear()
    recorded_timestamps.clear()
    recording_active = true
    
func record_frame(position: Vector3, delta: float):
    if recording_active:
        recorded_positions.append(position)
        recorded_timestamps.append(Time.get_ticks_usec())
        
func generate_past_bot_instance() -> PastBot:
    var future = load("res://assets/models/past_bot.tscn").instantiate()
    future.set_recorded_path(recorded_positions)
    return future
```

### 3. Sand Resource System
```gdscript
# SandSystem.gd
extends Node

var max_rewind_seconds: float = 30.0
var sand_crystal_count: int = 1
var recorded_rewind_times: Array[float] = []

const CRYSTAL_SAND_VALUE = 30  # Each crystal adds 30 seconds

const LEVEL_CRYSTALS = {
    1: true,  # Level 1: Crystal #1
    2: false,
    3: true,  # Level 3: Crystal #2
    4: false,
    5: true,  # Level 5: Crystal #3
    6: false,
    7: true,  # Level 7: Crystal #4
    8: false,
    9: true,  # Level 9: Crystal #5
    10: false
}

func collect_crystal(level: int):
    if LEVEL_CRYSTALS.get(level, false):
        sand_crystal_count += 1
        max_rewind_seconds = CRYSTAL_SAND_VALUE * sand_crystal_count

func get_available_rewind_time() -> float:
    # Can rewind up to max_rewind_seconds per attempt
    return min(max_rewind_seconds, recorded_rewind_times.size() > 0 ? recorded_rewind_times.back() : max_rewind_seconds)
```

### 4. Robot Movement System
```gdscript
# Robot.gd
extends CharacterBody3D

var current_position: Vector3 = Vector3.ZERO

func start_record():
    # Begin recording position timestamps
    pass
    
func record_movement(delta: float):
    # Add current position to recorded path
    TimeRecorder.record_frame(current_position, delta)
    
func stop_record():
    # Prepare for rewind playback
    TimeRecorder.generate_past_bot_instance()
```

---

## 🗓️ Development Timeline (1 Week)

| Day | Priority | Tasks | Notes |
|-----|----------|-------|-----|
| **Day 1** | P0 | Project setup, XR Tools import, Kenny assets, basic VR interaction, hourglass grab physics | Get core VR interaction working |
| **Day 2** | P0 | Robot movement, level framework, crystal collection, sand counter (number) | Functional gameplay loop |
| **Day 3** | P1 | Time recorder/playback system, past-bot instance, hourglass flip detection | Core rewind mechanic |
| **Day 4** | P1 | Level 2 button mechanic, platform lift system, retry mechanism | First puzzle level |
| **Day 5-6** | P2 | Create levels 3-10 with reusing templates (varied obstacles, crystals at 1,3,5,7,9) | Complete all levels |
| **Day 7** | P3 | UI polish, tutorial hints, bug fixes, Quest 3 optimization, build & test | Polish & publish |

---

## 🎨 Asset Plan (Kenny Assets)

| Asset Pack | Usage | Source |
|-----------|-------|--------|
| Low Poly Characters | Robot base model | [kenney.nl](https://kenney.nl/assets) |
| Low Poly Environments | Level floors, platforms | Download & filter by "VR" |
| Low Poly Props | Crystals, buttons, obstacles | [kenney.nl](https://kenney.nl/assets) |
| Kenny XR Hands | Controller visuals | Built-in to XR Tools |
| Kenny UI Icons | Sand counter icons | [kenney.nl](https://kenney.nl/assets) |

---

## ⚙️ Technical Specs & Optimization

### Quest 3 Performance
| Concern | Target | Solution |
|---------|--------|----------|
| **Frame Rate** | 120Hz (90Hz fallback) | Stable VR targeting |
| **Polygon Count** | <5K per static scene | Low-poly, baked lighting |
| **Shadow Maps** | None or 1024² | No dynamic shadows where possible |
| **Physics** | Single rigid body | Hourglass only (robot on CharacterBody3D) |
| **Memory** | <100MB | Past bots only exist during rewind |
| **Texture Size** | 512x512 max | Compressed KTX2 textures |
| **Draw Calls** | <100 per frame | Batching, LODs |

### Time Recording Optimization
- Record keyframes every **0.1 seconds** instead of every frame
- Store as float/Vector3 packed (6 bytes per frame)
- Limit recording duration to **max_rewind_seconds**
- Clear recorded data after successful playback

---

## 🎭 Level Design Template

```gdscript
# Level Template Pattern (shared across all 10 levels)
# ┌─────────────────────────────────────┐
# │  STARTING AREA                      │
# │     Robot spawn point               │
# │     Hourglass spawn point           │
# └─────────────────────────────────────┘
#              │
#              ▼
# ┌─────────────────────────────────────┐
# │  INTERMEDIATE OBSTACLES             │
# │     Platform gaps                   │
# │     Static obstacles                │
│  Buttons/Pressure plates (levels 2+)  │
# └─────────────────────────────────────┘
#              │
#              ▼
# ┌─────────────────────────────────────┐
# │  CRYSAL PLATFORM (if applicable)    │
# │     Collect crystal                 │
# │     Increases max rewind time       │
# └─────────────────────────────────────┘
#              │
#              ▼
# ┌─────────────────────────────────────┐
# │  DESTINATION PLATFORM               │
# │     Reach goal → Level Complete     │
# └─────────────────────────────────────┘
```

---

## ⚙️ XR Tools Plugin Setup

### Recommended Godot XR Tools Packages
1. **XR Interaction Toolkit (XRI)** - Built into Godot 4.x
2. **XR Plugin Management** - For Quest/PCVR support
3. **XR Hands** - Controller rendering with grip/flip
4. **XR Tools (Custom)** - For Quest 3 optimized templates

### Configuration Steps
```bash
# 1. Download Godot XR Tools repository
git clone https://github.com/godotxrtools/godot-xr-tools.git addons/xr_tools

# 2. Enable plugins in project settings
# - Enable "XR Tools - OpenXR", "XRI - Unity", etc.

# 3. Configure OpenXR Extension
# - Enable OpenXR in project settings
# - Add "Oculus Quest 2/XR Plugin" for Quest
# - Add "PCVR Plugin" for Unity/OpenXR on PC
```

---

## 📊 Progression & Game Loop

```
Level 1: Tutorial
└─ Robot walks to crystal (30s rewind time)
└─ Crystal collected → sand crystal count = 2

Level 2: Button Mechanic
└─ Past-bot must press button
└─ Robot #2 uses lifted platform to reach goal
└─ No crystal this level

Level 3: Extended Rewind
└─ Longer path + obstacle
└─ Crystal collected → sand crystal count = 3

... Repeat pattern ...

Levels with Crystals: 1, 3, 5, 7, 9
Levels without Crystals: 2, 4, 6, 8, 10 (10 = final challenge)
```

---

## 🎯 Success Criteria (Jam Completion)

| Criteria | Status |
|----------|--------|
| ✅ Hourglass grab & flip interaction | Core VR mechanic |
| ✅ Time recording system | Record robot path for 30s |
| ✅ Past-bot playback | Uncontrollable instance replays path |
| ✅ Sand counter (visual pieces) | 1 → 5 sand pieces max |
| ✅ 10 levels with varied puzzles | Template-based, crystals at 1,3,5,7,9 |
| ✅ Retry button for any attempt | No fail state, just retry |
| ✅ Quest 3 performance stable | 120Hz target |
| ✅ PCVR support | OpenXR dual-target |

---

## 🚀 Next Steps

1. **Set up project**: Configure Godot 4.x with OpenXR
2. **Import XR Tools**: Download and configure the XR Tools plugin
3. **Import Kenny Assets**: Download and set up low-poly models
4. **Day 1**: Build core hourgrab & flip interaction
5. **Day 2**: Implement robot movement & sand counter
6. **Day 3**: Build time recording/playback system
7. **Day 4**: Add button mechanic & platform lift
8. **Day 5-6**: Create levels 3-10 with reusing template
9. **Day 7**: Polish, test, optimize, build

## 📝 Notes & Considerations

- **No fail state**: Robots don't die, can retry anytime
- **30s rewind**: Each attempt can record up to 30s of robot movement
- **One robot at a time**: Can't control past-bot, only learn from it
- **Seated VR**: Don't over-exaggerate player movement
- **Controller-only**: No hand tracking required
- **Low-poly**: Use Kenny assets for speed, no custom modeling

---

**Ready to start development? Let's begin with Day 1 tasks!**
