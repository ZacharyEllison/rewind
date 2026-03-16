# 🤖 Robot Character Assets

Source: GDQuest Godot 4 3D Characters Demo ([GitHub](https://github.com/gdquest-demos/godot-4-3D-Characters))

## Available Robots

| File Name | Size | Description | Best For |
|-----------|------|-------------|----------|
| `robot_gobot.glb` | 1.4MB | Blue robot, cylindrical body, wheels | **Recommended** - Classic robot look |
| `robot_gdbot.glb` | 3.3MB | Square robot, boxy design | Good alternative |
| `robot_beetle.glb` | 1.8MB | Insect-like, hexapod legs | Creative choice |
| `robot_bee.glb` | 2.8MB | Bee-inspired robot | Fun/quirky |
| `character_sophia.glb` | 2.6MB | Humanoid female character | Not recommended - humanoid |
| `robot_bat.glb` | 668KB | Bat-like flying robot | Specialized use |

## Recommended for VR Game Jam

**Primary Choice: `robot_gobot.glb`**
- ✅ Classic robot appearance (perfect for "little robot" concept)
- ✅ Good polygon count for Quest 3 performance
- ✅ Recognizable robot silhouette
- ✅ Easy to see from overhead perspective

**Alternative: `robot_gdbot.glb`**
- ✅ More modern boxy design
- ⚠️ Larger file size

## Usage

Import these GLB files into Godot as scenes:
```bash
# In Godot Editor
File → Import... → Select robot_gobot.glb → Import as Scene
```

## Licensing

These assets are from the GDQuest demo repository. Check the repository's LICENSE file for usage terms. Most GDQuest assets are permissive (MIT-style).

---

## Next Steps

1. Choose your robot (`robot_gobot.glb` recommended)
2. Import into Godot as a `.tscn` scene
3. Create robot movement script
4. Set up for VR perspective (overhead view)
