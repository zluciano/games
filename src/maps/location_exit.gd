extends Area2D
## Exit zone that triggers scene transition to another location.

@export var target_map_id: String = ""
@export var target_spawn_point: String = "default"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _on_body_entered(_body: Node2D) -> void:
	_trigger_exit()


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("player"):
		_trigger_exit()


func _trigger_exit() -> void:
	if SceneManager.is_transitioning:
		return
	SceneManager.goto_location(target_map_id, target_spawn_point)
