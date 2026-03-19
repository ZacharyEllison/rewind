# Project Plan — Rewind Hourglass
Game Jam Entry | Theme: Rewind | Engine: Godot 4.6 | Target: Quest 3 + PCVR (OpenXR)

---

## Game Summary

Seated XR platformer where the player guides a small robot across a series of platforms from an above-shoulder perspective. Each attempt records the robot's path; pressing the rewind trigger plays back a ghost of that path. The player uses the ghost's route as a reference to navigate farther on the next attempt and eventually reach the goal zone.

---

## Immediate — blocking basic playability right now

1. **Confirm project entry point**
   Open `project.godot` and verify `run/main_scene` points to `res://scenes/main.tscn`. If a stale root-level `main.tscn` exists, delete or archive it.

2. **Confirm ghost shaders exist**
   Verify `res://assets/shaders/ghost_fill.gdshader` and `res://assets/shaders/ghost_outline.gdshader` are present. `GhostAppearance.apply()` will silently fail and the ghost will be invisible/unstyled without them. If missing, create minimal passthrough versions or replace with a simple semi-transparent `StandardMaterial3D`.

3. **Fix fall-respawn recording gap**
   `RobotCharacterController.respawn()` calls `retry_current_attempt()` which sets `is_recording = false` without restarting. After a fall the robot is unresponsive until the player presses the rewind button. Fix: call `game_manager.start_recording()` inside `respawn()` after `retry_current_attempt()`, or have `retry_current_attempt()` restart recording internally.

4. **Implement level transition on goal reached**
   `GameManager.goal_reached()` emits `attempt_completed` but nothing listens. Connect `attempt_completed` in `main.gd` (or level-completion flow) to show a brief win state and reload / advance the scene. A `get_tree().reload_current_scene()` is sufficient for a jam; a proper `change_scene_to_file()` is better.

5. **Replace CanvasLayer HUD with world-space UI**
   `HUD.gd` uses `CanvasLayer` which is invisible in OpenXR. Replace with either:
   - A `SubViewport` texture projected onto a quad mesh anchored near the robot (follows play area), or
   - A set of `Label3D` nodes parented to a world-space anchor near `XROrigin3D`.
   Minimum display: attempt number, crystals collected, time remaining.

---

## Short-term — needed for a complete playable loop

6. **Sand timer countdown in HUD**
   `GameManager.current_attempt_duration` is updated in `_process`. Expose remaining time via a signal or a getter, and display it in the HUD so the player knows when rewind will auto-trigger.

7. **Player prompt / tutorial text**
   A `Label3D` in world space (or part of the HUD) showing "B/Y = Rewind" and "A/X = Jump" until the player has pressed rewind at least once. Removes confusion about what the controller does.

8. **Hourglass VR object (core jam mechanic)**
   Create `Hourglass.tscn`: `RigidBody3D` + XR Tools pickable base.
   Flip detection: when local Y-axis dot product with `Vector3.UP` drops below 0 (i.e. held upside-down), call `GameManager.stop_recording()` then `trigger_rewind()`.
   Keep B/Y button as a fallback so desktop testing still works.

9. **Levels 2–3 (minimum viable content)**
   Duplicate `level_01.tscn`. Level 2: add a moving platform or a narrower gap. Level 3: longer route, require ghost knowledge to time a gap. Wire level transitions from step 4 to load these in sequence.

10. **Level transition with fade**
    On `attempt_completed`: fade viewport to black (a `ColorRect` AnimationPlayer tween is fine), call `get_tree().change_scene_to_file()`, fade back in. Reset `GameManager` state between levels via `_initialize_game()`.

11. **Remove double CollisionShape3D from SandCrystal and GoalZone**
    Both scripts build a collision shape in `_ready()` AND the .tscn bakes a bare `CollisionShape3D` child. Remove the baked-in `CollisionShape3D` nodes from `level_01.tscn` (and any future levels) so each Area3D has exactly one shape. Low impact on gameplay but keeps the scene clean.

---

## Stretch — polish and extra content

- **In-world retry button** — XR Tools interactable area or poke button that calls `retry_current_attempt()` + `start_recording()`.
- **Levels 4–10** — alternate crystal / no-crystal levels; crystals placed at levels 1, 3, 5, 7, 9.
- **Audio** — ambient loop, footstep SFX (on `move_and_slide` landing), crystal collect chime, level-complete sting.
- **Main menu scene** — title card + "Start" button.
- **Quest 3 export + on-device test** — confirm 90Hz minimum, no hitches during ghost playback, HUD readable at arm's length.
- **Ghost tint variation** — oldest ghost slightly more transparent than newest so players can distinguish runs at a glance.

---

## Architecture Reference

```
scenes/main.tscn  (entry point)
  GameManager (Node, GameManager.gd)          group: "game_manager"
  Level01 (instance: scenes/level_01.tscn)
    GoalZone (Area3D, GoalZone.gd)            → call_group("game_manager", "goal_reached")
    SandCrystal x2 (Area3D, SandCrystal.gd)  → call_group("game_manager", "add_sand_crystal")
  RobotCharacter (CharacterBody3D, RobotCharacterController.gd)
    robot_gobot (GLB mesh, RobotAnimationController.gd)
  GhostRobot (Node3D, GhostRobot.gd)          — pool managed by main.gd; duplicated per crystal
    robot_gobot (GLB mesh)                    — materials overridden at runtime by GhostAppearance
  HUD (CanvasLayer → should become world-space, HUD.gd)
  StartXR / XROrigin3D / FallbackCamera
```

Signal flow:
```
RobotCharacterController
  → presses B/Y/Escape
  → GameManager.stop_recording() + trigger_rewind()
  → GameManager emits rewinding_started
  → main.gd starts GhostRobot(s).start_playback()
  → each GhostRobot emits playback_finished
  → main.gd decrements counter; when 0 → GameManager.complete_rewind()
  → GameManager emits rewind_completed
  → presses B/Y again → start_new_attempt() + start_recording()

GoalZone.body_entered
  → GameManager.goal_reached()
  → GameManager emits attempt_completed
  → [TODO: main.gd listens → load next level]

SandCrystal.body_entered
  → GameManager.add_sand_crystal()
  → GameManager emits sand_crystal_collected + ghost_slots_changed
  → main.gd rebuilds ghost pool
  → HUD updates crystal count and ghost slot display
```

---

## Constraints

- No fail state — robot respawns on fall; player can always retry
- 30 s max attempt time baseline; each crystal adds 1 ghost slot (and 30 s of rewind history)
- Controller input required; hand tracking not required
- Seated VR — no standing or room-scale requirement
- Quest 3 performance target: 90 Hz minimum, 120 Hz preferred
- Renderer: `gl_compatibility` (required for Meta Quest 3 via OpenXR)
