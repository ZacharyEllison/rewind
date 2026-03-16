# Project Context - rewind XR Application

---

## Project Information

| Attribute | Value |
|-----------|-------|
| **Engine Version** | Godot 4.6 |
| **XR Plugin** | OpenXR |
| **Target Platforms** | Quest 3, VR headsets, PC VR |
| **Primary Interaction** | Hand tracking, controllers, haptic feedback |

---

## Technology Stack

- **GDScript**: Primary scripting language
- **C#**: Optional for performance-critical systems
- **OpenXR**: XR interoperability layer
- **Godot 4.x Rendering**: Forward+ rendering pipeline

---

## XR Features

- [ ] Hand tracking with gesture recognition
- [ ] Controller interaction with grab/pickup
- [ ] Haptic feedback patterns
- [ ] Spatial audio for immersion
- [ ] Foveated rendering (target platform dependent)
- [ ] Passthrough/AR integration capabilities

---

## Code Style Guidelines

- Use GDScript for most game logic
- PascalCase for classes, camelCase for variables/functions
- Minimize global usage; use nodes as singletons via `get_tree().root`
- Prefer signals over global events for decoupling
- Document public APIs with Godot docs comments

---

## XR Specific Guidelines

### Input Handling
```gdscript
# Use InputMap for XR devices, don't hardcode button names
func _on_button_pressed():
    if get_viewport().gui_focus == -1:
        _trigger_action()
```

### VR Comfort
- Offer snap turning AND smooth turning options
- Implement vignette for locomotion acceleration
- Provide seated/standing/room-scale mode selection
- Limit FOV during rapid movements

### Performance
- Target 72-90 FPS for Quest-based applications
- Use occlusion culling for complex scenes
- Implement dynamic resolution scaling
- Batch draw calls for XR rendering

### OpenXR Integration
```gdscript
# Reference the XRInterface for XR-specific calls
var xr_interface: XRInterface = null

if Engine.has_singletons():
    xr_interface = XRServer.get_interface(0)
```

---

## Project Files

| File | Purpose |
|------|---------|
| `project.godot` | Engine configuration and XR settings |
| `res://scripts/` | Reusable game logic systems |
| `res://scenes/` | XR environment scenes |
| `res://assets/` | Textures, models, audio assets |

---

## Last Updated
Session initialization for Godot 4.6 XR Project

---

**Keep this file current as project evolves**
