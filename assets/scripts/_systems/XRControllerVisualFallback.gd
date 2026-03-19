## Shows a hand fallback when the runtime doesn't provide a controller render model.
## On runtimes that support OpenXR render models, the fallback is hidden as soon as
## the OpenXRRenderModelManager spawns a render model child.

extends XRController3D

@export var render_model_manager: OpenXRRenderModelManager
@export var fallback_visual: Node3D


func _ready() -> void:
	if render_model_manager:
		render_model_manager.render_model_added.connect(_on_render_model_added)
		render_model_manager.render_model_removed.connect(_on_render_model_removed)

	_update_fallback_visibility()


func _on_render_model_added(_render_model: OpenXRRenderModel) -> void:
	_update_fallback_visibility()


func _on_render_model_removed(_render_model: OpenXRRenderModel) -> void:
	call_deferred("_update_fallback_visibility")


func _update_fallback_visibility() -> void:
	if fallback_visual:
		fallback_visual.visible = not _has_render_model()


func _has_render_model() -> bool:
	return render_model_manager != null and render_model_manager.get_child_count() > 0
