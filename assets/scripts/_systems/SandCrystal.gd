extends Area3D

var base_y: float

func _ready() -> void:
	add_to_group("crystal")
	base_y = global_position.y
	_build_mesh()
	_build_collision()
	body_entered.connect(_on_body_entered)

func _build_mesh() -> void:
	# Vertices
	var top    := Vector3(0.0,   0.25,  0.0)
	var bottom := Vector3(0.0,  -0.25,  0.0)
	var v0     := Vector3( 0.12, 0.0,  0.12)
	var v1     := Vector3(-0.12, 0.0,  0.12)
	var v2     := Vector3(-0.12, 0.0, -0.12)
	var v3     := Vector3( 0.12, 0.0, -0.12)

	# Each face is a triangle; normals are computed per face.
	# Top pyramid: 4 faces (top, v0, v1), (top, v1, v2), (top, v2, v3), (top, v3, v0)
	# Bottom pyramid: 4 faces (bottom, v1, v0), (bottom, v2, v1), (bottom, v3, v2), (bottom, v0, v3)
	var face_tris: Array[PackedVector3Array] = [
		# top pyramid
		PackedVector3Array([top, v0, v1]),
		PackedVector3Array([top, v1, v2]),
		PackedVector3Array([top, v2, v3]),
		PackedVector3Array([top, v3, v0]),
		# bottom pyramid (winding reversed so normals face outward)
		PackedVector3Array([bottom, v1, v0]),
		PackedVector3Array([bottom, v2, v1]),
		PackedVector3Array([bottom, v3, v2]),
		PackedVector3Array([bottom, v0, v3]),
	]

	var verts  := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	for i in face_tris.size():
		var tri: PackedVector3Array = face_tris[i]
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		var n: Vector3 = (b - a).cross(c - a).normalized()
		var base_idx: int = i * 3
		verts.append(a)
		verts.append(b)
		verts.append(c)
		normals.append(n)
		normals.append(n)
		normals.append(n)
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX]  = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.albedo_color        = Color(1.0, 0.8, 0.1)
	mat.emission_enabled    = true
	mat.emission            = Color(1.0, 0.6, 0.0)
	mat.emission_energy_multiplier = 1.5

	array_mesh.surface_set_material(0, mat)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	add_child(mesh_instance)

func _build_collision() -> void:
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	var col := CollisionShape3D.new()
	col.shape = shape
	add_child(col)

func _process(delta: float) -> void:
	rotate_y(delta * 1.2)
	position.y = base_y + sin(Time.get_ticks_msec() * 0.002) * 0.08

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		get_tree().call_group("game_manager", "add_sand_crystal")
		queue_free()
