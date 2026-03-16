# Agent Guidelines

## Context Reference Rule

**Before making any changes**, ALWAYS check the context section below. This contains:
- Project structure and architecture decisions
- Lessons learned from previous changes
- Key constraints and requirements
- What works vs what failed

**Step-by-step for agents:**
1. Read the current context before starting any task
2. Reference the project.godot lesson (never overwrite with my version)
3. Confirm with the developer what's been changed
4. Wait for approval before proceeding to the next file

This ensures no conflicts and keeps changes deliberate.

## Single File Rule

**Never** proceed with structure or architecture decisions after changing a file. Work on only one file at a time and wait for confirmation before moving to the next. This ensures:

1. Each change is properly tested and validated
2. No cascading changes are made without explicit approval
3. The developer maintains full visibility of each modification
4. Structure decisions are made deliberately, not by accumulation of changes

## Development Workflow

1. **Check context first** - Review current state before starting
2. **Discuss changes** with the developer first
3. **Get explicit approval** before writing/changing files
4. **Wait for confirmation** that the change is complete and works
5. **Only then** suggest next steps or new changes

## Example

❌ BAD: Create 5 new script files in sequence without approval
❌ BAD: Restructure folder hierarchy immediately after modifying one file
✅ GOOD: Suggest one change, wait for approval, then implement

---

## Project Context

| Aspect | Value |
--------|----|
| **Game Jam Theme** | Rewind |
| **Engine** | Godot 4.x |
| **Platforms** | Quest 3 (standalone), PCVR |
| **Dev Duration** | 1 week (solo) |
| **Play Mode** | Seated XR |
| **Perspective** | First-person hands, overhead robot view |
| **Input** | Controllers only |
| **Core Mechanic** | Hourglass flip = rewind time |

---

## Core Gameplay Loop

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

## Lessons Learned - project.godot & Project Files

**Critical Lesson 1: Never overwrite `project.godot` with an AI-generated version.**

**What failed:**
- AI version was too verbose with 10+ duplicate right_stereo_mode sections
- Included complex input event objects with full device/window details
- Had conflicting mobile/desktop rendering settings
- Missing `config_version=5` (required for Godot 4.6)
- Size: ~7.6KB vs Godot's clean ~2.4KB

**Correct approach:**
- Let Godot generate `project.godot` - use it as-is
- Reference it for correct syntax instead of generating from scratch
- Only add project.godot settings after confirming with developer
- Use AI for scripts, scenes, and documentation instead

**Current project.godot:**
- Godot 4.6 generated version - importable and working
- `config_version=5`
- `config/features=PackedStringArray("4.6", "Mobile")`
- `renderer/rendering_method="mobile"`

**Critical Lesson 2: Always update docs after adding new assets.**

When cloning external repositories or adding assets:
- Create/UPDATE READMEs with asset details
- Document source, usage, and licensing
- Keep AGENTS.md in sync with context changes

**GDQuest robot assets example:**
- Source: [github.com/gdquest-demos/godot-4-3D-Characters](https://github.com/gdquest-demos/godot-4-3D-Characters)
- Main robot: `robot_gobot.glb` (1.4MB, classic robot appearance)
- Documentation created: `assets/models/ROBOT_ASSETS_README.md`
- Updated: `README.md` and `PROJECT_PLAN.md` to reference assets

---

---

## Development Timeline (1 Week)

| Day | Priority | Tasks |
|-----|----------|--------|
| **Day 1** | P0 | Project setup, XR Tools import, Kenny assets, basic VR interaction, hourglass grab physics |
| **Day 2** | P0 | Robot movement, level framework, crystal collection, sand counter (number) |
| **Day 3** | P1 | Time recorder/playback system, past-bot instance, hourglass flip detection |
| **Day 4** | P1 | Level 2 button mechanic, platform lift system, retry mechanism |
| **Day 5-6** | P2 | Create levels 3-10 with reusing templates (crystals at 1,3,5,7,9) |
| **Day 7** | P3 | UI polish, tutorial hints, bug fixes, Quest 3 optimization, build & test |

---

## Success Criteria

- ✅ Hourglass grab & flip interaction
- ✅ Time recording system (record robot path for 30s)
- ✅ Past-bot playback (uncontrollable instance replays path)
- ✅ Sand counter (visual pieces 1 to 5)
- ✅ 10 levels with varied puzzles
- ✅ Retry button for any attempt
- ✅ Quest 3 performance stable (120Hz target)
- ✅ PCVR support via OpenXR

---

## Agent Action Checklist

Before writing any file:
- [ ] Check context section for lessons learned
- [ ] Reference project.godot (never overwrite my version)
- [ ] Confirm with developer what the current state is
- [ ] Get explicit approval for the change
- [ ] Write ONE file, wait, then proceed

**When in doubt: ASK FIRST.**

---

## Recent Project Changes - Documentation

### Created VR Scene Structure
**File:** `project_root/main.tscn`

**Scene Hierarchy:**
```
Main
├── GameManager (script attached)
│   ├── PlayerCamera (VirtualCamera3D)
│   │   ├── RobotView
│   │   │   └── Robot (Node3D)
│   │   │       └── RobotController (RobotCharacterController)
```

**Key Features:**
- ✅ Overhead robot view (Astro Bot style)
- ✅ Camera angled at 25° from vertical
- ✅ Game state managed by GameManager at root
- ✅ Robot movement via RobotCharacterController (extends CharacterBody3D)

### VR Input System
- Uses Godot XR Tools plugin
- Input actions configured in `project.godot`:
  - `move_robot_forward/backward/left/right`
  - `flip_hourglass`, `reset_attempt`, `pause_menu`

### Scripts Created
1. **GameManger.gd** - Core game state, recording system, sand mechanics
2. **RobotCharacterController.gd** - Robot movement with recording

---

