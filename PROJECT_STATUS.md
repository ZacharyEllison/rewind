# Project Status — Rewind Hourglass
Last updated: 2026-03-18

---

## What Is Built

### Core Systems (all scripts in `assets/scripts/_systems/`)

| Script | Status | Notes |
|--------|--------|-------|
| `GameManager.gd` | Working | Recording, rewind state machine, sand crystal logic, respawn |
| `RobotCharacterController.gd` | Working | CharacterBody3D, gravity, jump, VR joystick + desktop WASD/Space, auto-starts recording on ready |
| `GhostRobot.gd` | Working | Interpolated position playback from recorded Array[Vector3], emits `playback_finished` |
| `RobotAnimationController.gd` | Working | Drives AnimationPlayer (idle/walk/run/jump/fall) from velocity; graceful fallback if clips missing |

### Scenes

| Scene | Status | Notes |
|-------|--------|-------|
| `scenes/main.tscn` | Working | GameManager + RobotCharacter + GhostRobot wired together via `scenes/main.gd` |
| `scenes/level_01.tscn` | Exists | Basic level geometry; actual contents not yet verified |
| `project_root/main.tscn` | Exists | Older entry point — may be redundant with `scenes/main.tscn` |

### Plugins / Addons
- `addons/godot-xr-tools` — installed (full toolkit: pickup, snap zones, hands, staging, etc.)
- `addons/godot-xr-toggle` — installed
- `addons/xr-simulator` — installed (desktop XR simulation)

### Input
- VR: left or right thumbstick (dominant magnitude wins), A/X = jump, B/Y = rewind trigger
- Desktop: WASD movement, Space = jump, Escape = rewind trigger

---

## What Is Missing (Blocking for Jam Submission)

1. **Hourglass object** — no physical hourglass exists; rewind is triggered by a controller button. The core VR mechanic (grab + flip) is not implemented.
2. **Goal / level-complete detection** — no Area3D goal trigger, no level-complete signal, no scene transition.
3. **Crystal pickups** — `add_sand_crystal()` exists in GameManager but nothing calls it. No Area3D pickup zones in any scene.
4. **HUD / UI** — no sand timer display, no attempt counter, no level-complete screen, no retry button visible to player.
5. **Audio** — nothing. No SFX, no music.
6. **Levels 2–10** — only `level_01.tscn` exists.
7. **Level select / main menu** — no scenes exist for these.
8. **Ghost robot visual** — GhostRobot.gd has no semi-transparent mesh child confirmed in scene; needs verification and material setup.

---

## Known Issues / Gaps

- `project_root/main.tscn` and `scenes/main.tscn` may conflict as entry points — confirm which is active in `project.godot`.
- GameManager's position recording uses `current_attempt_duration % 0.1 < delta` — this is imprecise at variable framerates. Low priority but worth noting.
- `_update_sand_system()` sets crystals based on level number at init, not from actual in-game collection — the two code paths (level-lookup vs. `add_sand_crystal()`) need to be reconciled.
- Ghost robot rotation is not recorded — ghost will always face a fixed direction during playback.
