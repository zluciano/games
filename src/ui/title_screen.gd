extends Control
## Title screen - assembled from main_title textures with "PRESS START" blink.

@onready var press_start: TextureRect = $PressStart

var _can_proceed: bool = false
var _blink_tween: Tween


func _ready() -> void:
	GameManager.change_state(GameManager.State.TITLE)
	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)
	await tween.finished
	_can_proceed = true
	_start_blink()


func _start_blink() -> void:
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(press_start, "modulate:a", 0.0, 0.4)
	_blink_tween.tween_property(press_start, "modulate:a", 1.0, 0.4)


func _input(event: InputEvent) -> void:
	if not _can_proceed:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_can_proceed = false
		if _blink_tween:
			_blink_tween.kill()
		if press_start:
			press_start.modulate.a = 1.0
		SceneManager.goto_scene("res://scenes/main_menu/main_menu.tscn")
