# Project Status — Rewind Hourglass
Last updated: 2026-03-18

---

## 1. Core Systems

| Script | Role | Status |
|--------|------|--------|
| `GameManager.gd` | State machine, recording, rewind trigger, crystal/ghost-slot accounting | Working. Accumulator-based position sampling is solid. `goal_reached()` stops recording and emits `attempt_completed` but does NOT load the next level — that response is unimplemented. `_update_level()` exists but is never called. |
| `RobotCharacterController.gd` | CharacterBody3D physics, VR + desktop input, fall/respawn, rewind trigger | Working. Camera-relative movement, edge-detected rewind button, fall respawn. On respawn calls `retry_current_attempt()` which does NOT restart recording — robot is frozen until the player manually presses the rewind button again. |
| `GhostRobot.gd` | Interpolated playback of recorded positions + animation states | Working. Smooth lerp between samples, rotation derived from movement delta, animation playback with fallback name map. Calls `GhostAppearance.apply(self)` in `_ready()`. |
| `RobotAnimationController.gd` | Drives AnimationPlayer (idle/walk/run/jump/fall) from CharacterBody3D velocity | Working. Graceful no-op if AnimationPlayer or parent CharacterBody3D is absent. Fallback name map matches GhostRobot. |
| `SandCrystal.gd` | Procedurally built diamond mesh + Area3D pickup | Working. Rotates and bobs in `_process`. On body_entered by a CharacterBody3D, calls `add_sand_crystal` on the `game_manager` group via `call_group`, then frees itself. |
| `GoalZone.gd` | Procedurally built glowing plane + Area3D | Working. On body_entered by a CharacterBody3D, calls `goal_reached` on the `game_manager` group and emits `player_reached_goal`. `player_reached_goal` is declared but never connected anywhere — no level transition occurs. |
| `GhostAppearance.gd` | Applies two-pass fill + outline ShaderMaterial to all MeshInstance3D in a subtree | Working structurally. Depends on `res://assets/shaders/ghost_fill.gdshader` and `res://assets/shaders/ghost_outline.gdshader` — if either file is absent the ghost will have no material and a push_error will fire. Shader files not verified present. |
| `HUD.gd` | CanvasLayer with run counter, crystal count, ghost slot display | Working. Connects to `sand_crystal_collected`, `ghost_slots_changed`, and `recording_started` signals from GameManager. No sand-timer countdown display (time remaining is not shown). No rewind/retry prompt for the player. |
| `scenes/main.gd` | Wires GameManager + RobotCharacter + GhostRobot; manages ghost pool; XR/flat fallback | Working. Ghost pool rebuilds correctly on crystal collection. Multi-ghost playback count-down to `complete_rewind()` is correct. XR fallback to `FallbackCamera` works if `StartXR` signals failure. |

---

## 2. Scene Structure

### `scenes/main.tscn`

```
main (Node3D, main.gd)
  GameManager (Node, GameManager.gd)          — group: "game_manager"
  WorldEnvironment
  DirectionalLight3D
  Level01 (instance of scenes/level_01.tscn)
  RobotCharacter (CharacterBody3D, RobotCharacterController.gd)
    CollisionShape3D (CapsuleShape3D r=0.25 h=0.9, offset y=0.45)
    robot_gobot (robot_gobot.glb instance, RobotAnimationController.gd)
  GhostRobot (Node3D, GhostRobot.gd)
    robot_gobot (robot_gobot.glb instance)     — ghost mesh IS present
  StartXR (godot-xr-tools start_xr.tscn)
  FallbackCamera (Camera3D)                    — desktop fallback
  XROrigin3D
    XRCamera3D
    OpenXRRenderModelManager
    RightHandController (XRController3D, tracker=right_hand)
      OpenXRRenderModel
    LeftHandController (XRController3D, tracker=left_hand)
      OpenXRRenderModel
  HUD (CanvasLayer, HUD.gd)
```

Notes:
- `RobotCharacter` exports `left_controller`, `right_controller`, and `xr_camera` are wired by NodePath in the scene file.
- `robot_gobot` under `GhostRobot` is present in the scene. `GhostAppearance.apply()` will attempt to override its materials at runtime using the ghost shaders.
- No `XRController3D` nodes have `robot_mesh` assigned in the Inspector — that export on `RobotCharacterController` is optional and falls back to a child name search (`robot_gobot`), which will resolve correctly.

### `scenes/level_01.tscn`

```
Level01 (Node3D)
  StartPlatform (StaticBody3D) — 6x0.4x6, at origin, green material
  Platform1 (StaticBody3D)    — 3x0.4x3, pos (5, 1, 0), blue-grey
  Platform2 (StaticBody3D)    — 3x0.4x3, pos (10, 2, -3), blue-grey
  Platform3 (StaticBody3D)    — 3x0.4x2.5, pos (14, 3, 0), blue-grey
  Platform4 (StaticBody3D)    — 2.5x0.4x2.5, pos (18, 4.5, 3), blue-grey
  GoalPlatform (StaticBody3D) — 4x0.4x4, pos (22, 6, 0), green
    GoalZone (Area3D, GoalZone.gd)
      CollisionShape3D (BoxShape3D 3.5x0.5x3.5)
      [MeshInstance3D built at runtime by GoalZone.gd]
  SandCrystal_Platform2 (Area3D, SandCrystal.gd) — pos (10, 2.8, -3)
    [mesh and CollisionShape3D built at runtime by SandCrystal.gd]
  SandCrystal_GoalPlatform (Area3D, SandCrystal.gd) — pos (22, 7.2, 0)
    [mesh and CollisionShape3D built at runtime by SandCrystal.gd]
```

Notes:
- Both crystals and the GoalZone have their CollisionShape3D children listed in the scene file, but `SandCrystal._build_collision()` also calls `add_child` for a new `CollisionShape3D` at runtime. This means each SandCrystal ends up with **two** CollisionShape3D children — the one baked into the scene (empty, no shape assigned in the .tscn) and the one built in `_ready()`. The runtime-built one has the correct SphereShape3D; the scene-baked one is harmless but redundant.
- GoalZone in the .tscn already has a `CollisionShape3D` child (BoxShape3D 3.5x0.5x3.5). `GoalZone._build_collision()` adds a second one at runtime. Same double-collision situation as the crystals — functionally harmless but wasteful.
- The path from StartPlatform to GoalPlatform has gaps that require jumping. Platform heights increase from Y=0 to Y=6.

---

## 3. Known Issues / Bugs

1. **Double CollisionShape3D on SandCrystal and GoalZone.** Both scripts call `_build_collision()` in `_ready()` which appends a new `CollisionShape3D`, but the .tscn already bakes one in. Two shapes exist; the baked one has no assigned shape resource (just a bare `CollisionShape3D` node) so it is disabled — harmless but messy.

2. **Fall respawn does not restart recording.** `RobotCharacterController.respawn()` calls `game_manager.retry_current_attempt()`, which resets position but sets `is_recording = false` without restarting. The robot is then stuck: recording is off, rewinding is off. The player must press the rewind button to get back into a live state. This is likely unintended.

3. **`goal_reached()` does not trigger a level transition.** `GameManager.goal_reached()` stops recording and emits `attempt_completed`. Nothing listens to `attempt_completed` — no scene change, no win screen, no message to the player.

4. **`GoalZone.player_reached_goal` signal is never connected.** It is emitted inside `_on_body_entered` but no node listens to it. Dead signal.

5. **Ghost shader files not confirmed present.** `GhostAppearance` hard-references `res://assets/shaders/ghost_fill.gdshader` and `res://assets/shaders/ghost_outline.gdshader`. If those files are missing the ghost robot will render without any material override (push_error at runtime, ghost mesh visible but unstyled).

6. **HUD is a CanvasLayer — not visible in VR.** A `CanvasLayer` renders to a 2D screen overlay. In OpenXR mode (Quest 3) the player will not see it. For VR it needs to be a `SubViewport` projected onto a mesh in world space, or replaced with a `Label3D`.

7. **`_update_level()` is never called.** `GameManager._update_level(level)` updates `current_level` but nothing calls it. `current_level` stays at 1 permanently.

8. **`RobotCharacterController.robot_mesh` export is unassigned in the scene.** The code falls back to `get_node_or_null("robot_gobot")`, which will work given the scene structure — but the exported field appears unused.

9. **XROrigin3D is elevated (Y=2.49, Z=2.14).** This places the VR tracking origin significantly above and behind the robot. On Quest 3 with a seated player the camera view angle will depend on physical head position relative to this offset. May need tuning once tested on device.

10. **`start_new_attempt()` clears `past_runs` before ghosts finish.** If called while a ghost is still playing back, `past_runs` is cleared and `is_rewinding` is set false. The ghost pool's `playback_finished` callbacks will still fire and decrement `_ghosts_playing`, which could go negative (guarded by `<= 0` check). Low risk but worth noting.

---

## 4. What Is NOT Yet Implemented

- **Level transition / win state.** `attempt_completed` signal exists but nothing responds to it. No scene change on goal reached.
- **Hourglass VR object.** Rewind is triggered by a controller button (B/Y) or Escape key. The grab-and-flip physical hourglass mechanic does not exist.
- **Sand timer display in HUD.** The HUD shows crystal count and ghost slots but not the remaining attempt time countdown.
- **Retry / rewind prompt visible to player.** There is no in-world label or UI element telling the player what button does what.
- **In-world retry button.** `retry_current_attempt()` exists in GameManager but there is no interactable object wired to it.
- **Audio.** No SFX, no music, no AudioStreamPlayer nodes anywhere.
- **Levels 2+.** Only `level_01.tscn` exists.
- **Main menu / level select.** No scenes exist for these.
- **VR-visible HUD.** Current `CanvasLayer` HUD is invisible in OpenXR mode.
- **Ghost shader files.** Need to confirm `ghost_fill.gdshader` and `ghost_outline.gdshader` exist under `res://assets/shaders/`.
- **`project.godot` main scene verification.** Not confirmed that `scenes/main.tscn` is set as the project entry point (vs. a possible stale root-level `main.tscn`).
