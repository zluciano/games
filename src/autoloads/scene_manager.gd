extends Node
## Handles scene transitions with visual effects.

signal scene_change_started
signal scene_change_finished

var current_scene: Node = null
var is_transitioning: bool = false

var _transition_rect: ColorRect


func _ready() -> void:
	# Create a persistent transition overlay
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	_transition_rect = ColorRect.new()
	_transition_rect.color = Color.BLACK
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.modulate.a = 0.0
	canvas.add_child(_transition_rect)

	# Grab the initial scene
	await get_tree().process_frame
	current_scene = get_tree().current_scene


func goto_scene(path: String, transition: String = "fade", duration: float = 0.4) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	scene_change_started.emit()

	# Fade out
	await _fade_out(duration)

	# Switch scene
	get_tree().change_scene_to_file(path)
	await get_tree().tree_changed
	await get_tree().process_frame
	current_scene = get_tree().current_scene

	# Fade in
	await _fade_in(duration)

	is_transitioning = false
	scene_change_finished.emit()


func goto_location(map_id: String, spawn_point: String = "default") -> void:
	var path := "res://scenes/locations/%s.tscn" % map_id
	if not ResourceLoader.exists(path):
		push_warning("Location scene not found: %s" % path)
		return

	if is_transitioning:
		return
	is_transitioning = true
	scene_change_started.emit()

	await _fade_out(0.4)

	get_tree().change_scene_to_file(path)
	await get_tree().tree_changed
	await get_tree().process_frame
	current_scene = get_tree().current_scene

	# Tell the location where to spawn the player
	if current_scene and current_scene.has_method("set_spawn_point"):
		current_scene.set_spawn_point(spawn_point)

	GameManager.game_data["location"] = map_id

	await _fade_in(0.4)

	is_transitioning = false
	scene_change_finished.emit()


func goto_big_map() -> void:
	GameManager.change_state(GameManager.State.BIG_MAP)
	await goto_scene("res://scenes/big_map/big_map.tscn")


func _fade_out(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 1.0, duration)
	await tween.finished


func _fade_in(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 0.0, duration)
	await tween.finished
