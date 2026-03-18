# Project Plan — Rewind Hourglass
Game Jam Entry | Theme: Rewind | Engine: Godot 4.6 | Target: Quest 3 + PCVR (OpenXR)

---

## Game Summary

Seated XR platformer. Player watches a small robot from above (Astro Bot perspective). Each attempt records the robot's path. Pressing the rewind trigger replays the ghost of that path. The player uses that knowledge to guide the robot differently on the next attempt and reach the level goal.

Core loop: Move robot → trigger rewind → watch ghost → retry with new knowledge → reach goal.

---

## Priorities (Jam Context: Playable Beats Polished)

### Immediate — needed before the game is playable at all

1. **Confirm scene entry point**
   - Verify `project.godot` main scene is `scenes/main.tscn`. Remove or archive `project_root/main.tscn` if it is the old one.

2. **Ghost robot mesh**
   - Add `robot_gobot` mesh as a child of the `GhostRobot` node with a semi-transparent material (albedo alpha ~0.4, transparency enabled).
   - Verify ghost appears and moves during rewind playback.

3. **Goal trigger for level_01**
   - Add an Area3D at the destination in `level_01.tscn`.
   - On `body_entered`, signal GameManager → show level-complete state → load next level (or restart for now).

4. **Crystal pickup trigger**
   - Add an Area3D crystal in `level_01.tscn`.
   - On `body_entered`, call `game_manager.add_sand_crystal()`.
   - Reconcile `_update_sand_system()` (level-lookup at init) with `add_sand_crystal()` (incremental) — pick one approach and remove the other.

5. **Minimal HUD (Label3D or SubViewport)**
   - Attempt number, current rewind-time budget (crystals collected × 30s), and a "REWIND / RETRY" prompt so the player knows what the button does.
   - Does not need to be beautiful — a Label3D floating in world space is fine.

---

### Short-term — needed before a full playthrough exists

6. **Hourglass object (VR mechanic)**
   - Create `Hourglass.tscn`: RigidBody3D + grab point (XR Tools `pickable.tscn` as base).
   - Detect flip: when the hourglass local Y-axis flips past ~90° from upright, fire `trigger_rewind()` on GameManager.
   - Replace the controller-button rewind trigger with this (or keep button as fallback).

7. **Ghost rotation recording**
   - Extend GameManager recording to store `Array[Basis]` or `Array[float]` (Y-rotation only) alongside positions.
   - Apply in `GhostRobot._physics_process` so the ghost faces the direction it was moving.

8. **Levels 2–3 (minimum viable content)**
   - Duplicate `level_01.tscn`, modify geometry and obstacle layout.
   - Level 2: introduce a button the ghost must press to raise a platform.
   - Level 3: longer path, second crystal.

9. **Level transition**
   - On goal reached: fade out, load next level scene, reset GameManager state.
   - A simple `get_tree().change_scene_to_file()` is sufficient.

10. **Retry button (in-world)**
    - A grabbable or pokeable button (XR Tools `interactable_area_button`) that calls `game_manager.retry_current_attempt()`.

---

### Stretch — if time permits

- Levels 4–10 (template: alternate crystal / no-crystal levels; crystals at 1, 3, 5, 7, 9)
- Audio: single ambient loop + 3 SFX (footstep, crystal collect, level complete)
- Main menu scene
- Level select scene
- Quest 3 export and on-device test (120Hz, confirm no hitches during ghost playback)

---

## Architecture Reference (current)

```
scenes/main.tscn  (entry point)
  GameManager (GameManager.gd)
  RobotCharacter (RobotCharacterController.gd + CharacterBody3D)
    robot_gobot (mesh)
      RobotAnimationController.gd
  GhostRobot (GhostRobot.gd + Node3D)
    [needs: robot_gobot mesh, semi-transparent material]
```

Signal flow:
- RobotCharacterController detects input → calls `GameManager.stop_recording()` + `trigger_rewind()`
- GameManager emits `rewinding_started` → main.gd starts `GhostRobot.start_playback()`
- GhostRobot emits `playback_finished` → main.gd sets `GameManager.is_rewinding = false` + emits `rewind_completed`
- Player presses rewind again (after ghost finishes) → `start_new_attempt()` + `start_recording()`

---

## Constraints

- No fail state — robot respawns on fall, player can always retry
- 30s max attempt time per crystal (1 crystal = 30s, 5 crystals = 150s)
- Controller-only input (no hand tracking required)
- Seated VR — do not require standing or room-scale
- Quest 3 performance target: 90Hz minimum, 120Hz preferred
