## HourglassPedestal
## Player-following pedestal that accepts the hourglass when it falls into the
## trigger area. Accepts either orientation:
##   - Upside-down + recording active → lerp to SnapAnchor and trigger a rewind.
##   - Right-side-up (or can't rewind) → lerp to RestAnchor (just resting).
## The hourglass uses physics (gravity) after being released, so the player
## can physically place or toss it onto the pedestal.

class_name HourglassPedestal
extends Node3D

@export var hourglass_path: NodePath
@export var rest_anchor_path: NodePath
@export var snap_anchor_path: NodePath
@export var trigger_area_path: NodePath

const PULL_DURATION: float = 0.35

var _hourglass: Hourglass
var _rest_anchor: Node3D
var _snap_anchor: Node3D
var _trigger_area: Area3D
var _game_manager: Node = null
var _triggered_this_attempt: bool = false
var _is_resetting: bool = false
var _pull_request_id: int = 0


func _ready() -> void:
	_resolve_nodes()
	_game_manager = get_tree().get_first_node_in_group("game_manager")

	if _hourglass:
		_hourglass.picked_up.connect(_on_hourglass_picked_up)
		_hourglass.dropped.connect(_on_hourglass_dropped)

	if _trigger_area:
		_trigger_area.body_entered.connect(_on_trigger_body_entered)

	if _game_manager and _game_manager.has_signal("new_attempt_started"):
		_game_manager.new_attempt_started.connect(reset)

	call_deferred("reset")


func reset() -> void:
	if not _hourglass or not _rest_anchor:
		return

	_cancel_pending_pull()
	_triggered_this_attempt = false
	_is_resetting = true
	_hourglass.cancel_pending_return()

	if _hourglass.is_picked_up():
		_hourglass.drop()

	_hourglass.freeze = true
	_hourglass.reset_to_anchor(_rest_anchor)
	_is_resetting = false


func _resolve_nodes() -> void:
	_hourglass = _resolve_node(hourglass_path, "Hourglass") as Hourglass
	_rest_anchor = _resolve_node(rest_anchor_path, "RestAnchor") as Node3D
	_snap_anchor = _resolve_node(snap_anchor_path, "SnapAnchor") as Node3D
	_trigger_area = _resolve_node(trigger_area_path, "TriggerArea") as Area3D


func _resolve_node(path: NodePath, fallback_name: String) -> Node:
	if not path.is_empty():
		var resolved := get_node_or_null(path)
		if resolved:
			return resolved
	return get_node_or_null(fallback_name)


func _on_hourglass_picked_up(_pickable) -> void:
	if not _hourglass:
		return
	_cancel_pending_pull()
	_hourglass.cancel_pending_return()


func _on_hourglass_dropped(_pickable) -> void:
	if _is_resetting or not _hourglass or not _rest_anchor:
		return
	# Physics is now active on the hourglass. Schedule a fallback return in case
	# it misses the pedestal entirely. body_entered on _trigger_area handles the
	# normal case where the hourglass falls into the pedestal zone.
	_hourglass.schedule_return(_rest_anchor)


## Called when a physics body enters the pedestal trigger zone.
## This is the primary snap handler — fires when the falling hourglass arrives.
func _on_trigger_body_entered(body: Node3D) -> void:
	if body != _hourglass:
		return
	# Ignore if being held, resetting, or already frozen (placed by code, not physics).
	if _hourglass.is_picked_up() or _is_resetting or _hourglass.freeze:
		return
	_hourglass.cancel_pending_return()

	if _should_pull_top_cap():
		if not _triggered_this_attempt:
			if _game_manager and _game_manager.has_method("is_recording_active") and _game_manager.is_recording_active():
				_accept_drop()
				return
		_pull_to_anchor(_snap_anchor)
		return

	_pull_to_anchor(_rest_anchor)


func _accept_drop() -> void:
	_triggered_this_attempt = true
	_hourglass.cancel_pending_return()
	var request_id := _pull_to_anchor(_snap_anchor)

	if not _game_manager or not _game_manager.has_method("trigger_rewind"):
		return

	get_tree().create_timer(PULL_DURATION).timeout.connect(
		_on_rewind_pull_finished.bind(request_id),
		CONNECT_ONE_SHOT
	)


func _on_rewind_pull_finished(request_id: int) -> void:
	if request_id != _pull_request_id or _is_resetting or not _hourglass:
		return
	if not _game_manager or not _game_manager.has_method("trigger_rewind"):
		return

	var triggered: bool = _game_manager.trigger_rewind("hourglass")
	if not triggered:
		_triggered_this_attempt = false
		_pull_to_anchor(_rest_anchor)


func _pull_to_anchor(anchor: Node3D) -> int:
	if not _hourglass or not anchor:
		return _pull_request_id
	_pull_request_id += 1
	_hourglass.lerp_to_anchor(anchor, PULL_DURATION)
	return _pull_request_id


func _cancel_pending_pull() -> void:
	_pull_request_id += 1


func _should_pull_top_cap() -> bool:
	if not _hourglass:
		return false
	if not _rest_anchor and not _snap_anchor:
		return _hourglass.is_upside_down()

	var top_cap := _hourglass.top_cap
	var bottom_cap := _hourglass.bottom_cap
	if not top_cap and not bottom_cap:
		return _hourglass.is_upside_down()
	if top_cap and not bottom_cap:
		return true
	if bottom_cap and not top_cap:
		return false

	var target_position := _snap_anchor.global_position if _snap_anchor else _rest_anchor.global_position
	return top_cap.global_position.distance_squared_to(target_position) < bottom_cap.global_position.distance_squared_to(target_position)
