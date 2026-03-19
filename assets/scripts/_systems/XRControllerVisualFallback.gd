## Shows a simple controller proxy when the runtime doesn't provide a render
## model. On runtimes that support OpenXR render models, the proxy is hidden as
## soon as the OpenXRRenderModelManager spawns a render model child.

extends XRController3D

@export var render_model_manager: OpenXRRenderModelManager

var _fallback_visual: Node3D


func _ready() -> void:
	if not render_model_manager:
		render_model_manager = get_node_or_null("OpenXRRenderModelManager") as OpenXRRenderModelManager

	_fallback_visual = get_node_or_null("ControllerProxy") as Node3D
	if not _fallback_visual:
		_fallback_visual = _build_fallback_visual()

	if render_model_manager:
		render_model_manager.render_model_added.connect(_on_render_model_added)
		render_model_manager.render_model_removed.connect(_on_render_model_removed)

	_update_fallback_visibility()


func _on_render_model_added(_render_model: OpenXRRenderModel) -> void:
	_update_fallback_visibility()


func _on_render_model_removed(_render_model: OpenXRRenderModel) -> void:
	call_deferred("_update_fallback_visibility")


func _update_fallback_visibility() -> void:
	if _fallback_visual:
		_fallback_visual.visible = not _has_render_model()


func _has_render_model() -> bool:
	return render_model_manager != null and render_model_manager.get_child_count() > 0


func _build_fallback_visual() -> Node3D:
	var proxy := Node3D.new()
	proxy.name = "ControllerProxy"

	var pitch := -18.0
	var roll := -10.0 if tracker == &"left_hand" else 10.0
	proxy.rotation_degrees = Vector3(pitch, 0.0, roll)
	add_child(proxy)

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.17, 0.18, 0.2)
	body_material.metallic = 0.25
	body_material.roughness = 0.65

	var accent_material := StandardMaterial3D.new()
	accent_material.albedo_color = Color(0.2, 0.7, 0.95) if tracker == &"left_hand" else Color(0.95, 0.55, 0.18)
	accent_material.emission_enabled = true
	accent_material.emission = accent_material.albedo_color
	accent_material.emission_energy_multiplier = 0.4
	accent_material.roughness = 0.3

	var grip_mesh := MeshInstance3D.new()
	var grip_shape := CapsuleMesh.new()
	grip_shape.radius = 0.018
	grip_shape.mid_height = 0.10
	grip_mesh.mesh = grip_shape
	grip_mesh.material_override = body_material
	grip_mesh.position = Vector3(0.0, -0.04, 0.015)
	grip_mesh.rotation_degrees = Vector3(12.0, 0.0, 0.0)
	proxy.add_child(grip_mesh)

	var body_mesh := MeshInstance3D.new()
	var body_shape := BoxMesh.new()
	body_shape.size = Vector3(0.045, 0.035, 0.07)
	body_mesh.mesh = body_shape
	body_mesh.material_override = body_material
	body_mesh.position = Vector3(0.0, 0.0, 0.02)
	proxy.add_child(body_mesh)

	var halo_mesh := MeshInstance3D.new()
	var halo_shape := SphereMesh.new()
	halo_shape.radius = 0.024
	halo_shape.height = 0.048
	halo_mesh.mesh = halo_shape
	halo_mesh.material_override = accent_material
	halo_mesh.position = Vector3(0.0, 0.04, -0.005)
	halo_mesh.scale = Vector3(1.0, 0.45, 1.3)
	proxy.add_child(halo_mesh)

	var trigger_mesh := MeshInstance3D.new()
	var trigger_shape := BoxMesh.new()
	trigger_shape.size = Vector3(0.018, 0.022, 0.028)
	trigger_mesh.mesh = trigger_shape
	trigger_mesh.material_override = body_material
	trigger_mesh.position = Vector3(0.0, -0.008, 0.052)
	trigger_mesh.rotation_degrees = Vector3(22.0, 0.0, 0.0)
	proxy.add_child(trigger_mesh)

	var button_mesh := MeshInstance3D.new()
	var button_shape := SphereMesh.new()
	button_shape.radius = 0.007
	button_shape.height = 0.014
	button_mesh.mesh = button_shape
	button_mesh.material_override = accent_material
	button_mesh.position = Vector3(0.0, 0.019, 0.046)
	proxy.add_child(button_mesh)

	return proxy
