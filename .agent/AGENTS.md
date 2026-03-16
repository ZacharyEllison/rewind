# Agent Instructions: Godot 4.6 XR Application Assistant

## Project: rewind - XR Experience

---

## 📋 Project Context

### Overview
This is a Godot 4.6 XR application for immersive extended reality experiences using OpenXR.

### Current State
- **Engine Version**: Godot 4.6
- **XR Plugin**: OpenXR
- **Target Platforms**: Quest 3, VR headsets, PC VR
- **Primary Interaction**: Hand tracking, controllers, haptic feedback

### Technology Stack
- **GDScript**: Primary scripting language
- **C#**: Optional for performance-critical systems
- **OpenXR**: XR interoperability layer
- **Godot 4.x Rendering**: Forward+ rendering pipeline

### XR Features
- Hand tracking with gesture recognition
- Controller input with ray casting
- Haptic feedback patterns
- Spatial audio for immersion
- Foveated rendering (target platform dependent)
- Passthrough/AR integration capabilities

### Code Style Guidelines
- Use GDScript for most game logic
- PascalCase for classes, camelCase for variables/functions
- Minimize global usage; use nodes as singletons via `get_tree().root`
- Prefer signals over global events for decoupling
- Document public APIs with Godot docs comments

---

## 🧠 Session Memory

### Active Context Variables
- **last_session**: Current XR project context maintained across agent sessions
- **recent_changes**: Track recent file modifications and feature implementations
- **bug_tracker**: Active issues and their current state
- **pending_decisions**: Architectural or design decisions awaiting confirmation

### Session Preservation
Information in `.agent/session-memory.md` should persist between agent sessions to maintain continuity of work.

---

## 📁 Agent Directory Structure

```.agent/
├── AGENTS.md              # This file - main agent instructions
├── context.md             # Project overview, architecture, and coding standards
├── session-memory.md      # Session summaries, tasks, bugs, decisions
├── plans.md               # Active plans and project roadmap
└── notes.md               # Temporary notes and observations
```

---

## 🎯 Agent Responsibilities

### 1. Code Generation
- Generate GDScript/C# code following project conventions
- Ensure compatibility with Godot 4.6
- Implement XR-specific features (OpenXR interactions)
- Add proper input handling for VR controllers and hand tracking

### 2. Bug Resolution
- Diagnose XR-specific issues (tracking problems, latency, crashes)
- Identify engine version incompatibilities
- Suggest fixes for common OpenXR pitfalls

### 3. Documentation
- Update `.agent/context.md` as architecture evolves
- Document new systems and their XR integrations
- Track decisions in `.agent/session-memory.md`

### 4. Best Practices Enforcement
- VR comfort guidelines (vignette, locomotion options)
- Performance optimization (occlusion, draw calls)
- Accessibility considerations (motion sickness, UI scaling)

---

## 📍 XR Specific Guidelines

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

## 📝 Session Notes Format

### Important: Session Management
**Sessions should be condensed and summarized** into the session-memory files. Each session ends with a summary of:
- What was accomplished
- Any decisions made
- Current blockers
- Next immediate steps

### Format
```markdown
## Session Date: YYYY-MM-DD

### Goals
[ ] Task 1
[ ] Task 2

### Completed
- Completed item 1
- Completed item 2

### Blockers
- Current block 1
- Current block 2

### Next Actions
- Immediate next step
- Follow-up tasks
```

---

## 🔧 File Operations

### Preferred Files for Agent Operations
- **Scripts**: `res://scripts/` for reusable systems
- **Scenes**: `res://scenes/` for XR environment
- **Assets**: `res://assets/` for textures, models, audio
- **Config**: `project.godot` for engine settings

### Godot Project File
Always reference `project.godot` for XR configuration:
```
[rendering]
xr/enabled=true
xr/forward_plus=true
xr/environment/enable_foveated_rendering=true
```

---

## 🎮 XR Features Checklist

### Core Requirements
- [ ] OpenXR enabled in project settings
- [ ] Hand tracking integration
- [ ] Controller interaction with grab/pickup
- [ ] Haptic feedback system
- [ ] Spatial audio setup
- [ ] UI with diegetic/non-diegetic options

### Performance Metrics
- [ ] Maintain stable frame rate
- [ ] Optimize shader complexity
- [ ] Implement LOD systems
- [ ] Profile XR rendering pipeline

---

## 🚀 Getting Started for New Agent Sessions

1. **Read `.agent/context.md`** to understand current project state
2. **Review `.agent/session-memory.md`** for ongoing tasks and recent changes
3. **Check `.agent/plans.md`** for active milestones and roadmap
4. **Identify immediate tasks** from ACTIVE_TASKS section in session-memory
5. **Update context.md** as project evolves

---

## 💡 Agent Interaction Guidelines

### When Asked for Help:
1. Read relevant context before answering
2. Consider Godot 4.6 specific changes from previous versions
3. Account for XR performance constraints
4. Suggest alternative approaches when appropriate
5. Always provide verbatim code snippets for copy-paste

### When Creating/New Features:
1. Update `.agent/context.md` as architecture evolves
2. Add to `.agent/session-memory.md` for tracking
3. Create plan entry if part of larger objective
4. Document design decisions in `.agent/notes.md`

### When Fixed Bugs:
1. Update `.agent/session-memory.md` with resolution (Bugs and Fixes section)
2. Note prevention measures in `.agent/notes.md`
3. Update `.agent/context.md` if architecture changed

---

## 🔄 Documentation Maintenance Guidelines

### Session End Responsibilities
At the end of each agent session, ensure:
- **Summarize** what was accomplished into `.agent/session-memory.md`
- **Move** temporary notes to `.agent/context.md` as permanent docs
- **Update** task status in `.agent/session-memory.md`
- **Flag** new blockers or decisions for next session

### Context Update Frequency
- **Immediate**: Architecture changes, new subsystems
- **During session**: Significant feature additions
- **Session review**: Batch minor updates between sessions

### Notes Flow
```
notes.md (temporary)
  ↓ (if decision/pattern solidifies)
context.md (permanent documentation)
```

### Key Rules
1. **Don't let docs rot** – update context proactively
2. **Summarize each session** – maintain session continuity
3. **Consolidate notes** – convert repeated observations to docs
4. **Timestamp critical changes** – track evolution over time

---

**Keep documentation current – outdated docs cause more problems than no docs.**

---

**Last Updated**: Session initialization for Godot 4.6 XR Project  
**Agent Version**: 1.0
