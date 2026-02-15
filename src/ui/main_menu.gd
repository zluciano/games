extends Control
## Main menu - New Game / Continue / Options with cursor navigation.

const MENU_ITEMS := ["New Game", "Continue", "Options"]

var selected_index: int = 0
var _can_input: bool = false

@onready var item_container: VBoxContainer = $ItemContainer
@onready var cursor: Label = $Cursor


func _ready() -> void:
	GameManager.change_state(GameManager.State.MAIN_MENU)
	_build_menu()
	# Defer cursor update so VBoxContainer has laid out its children
	await get_tree().process_frame
	_update_cursor()

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	await tween.finished
	_can_input = true


func _build_menu() -> void:
	for i in MENU_ITEMS.size():
		var item := _create_menu_item(MENU_ITEMS[i], i)
		item_container.add_child(item)

	# Disable continue if no saves
	if not _has_any_save():
		var cont := item_container.get_child(1)
		cont.modulate.a = 0.4


func _create_menu_item(text: String, _index: int) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(500, 70)

	# Background bar
	var bar := ColorRect.new()
	bar.color = Color(0.1, 0.15, 0.3, 0.7)
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bar)

	# Text label
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 35)
	container.add_child(label)

	return container


func _input(event: InputEvent) -> void:
	if not _can_input:
		return

	if event.is_action_pressed("ui_up"):
		_move_cursor(-1)
	elif event.is_action_pressed("ui_down"):
		_move_cursor(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_select_item()
	elif event.is_action_pressed("ui_cancel"):
		SceneManager.goto_scene("res://scenes/title/title_screen.tscn")


func _move_cursor(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, 0, MENU_ITEMS.size())
	_update_cursor()


func _update_cursor() -> void:
	if item_container.get_child_count() == 0:
		return
	var target := item_container.get_child(selected_index) as Control
	var target_pos := target.global_position
	cursor.global_position = Vector2(target_pos.x - 50, target_pos.y + 15)


func _select_item() -> void:
	match selected_index:
		0: # New Game
			_can_input = false
			GameManager.start_new_game()
		1: # Continue
			if _has_any_save():
				_can_input = false
				# Load most recent save for now
				for slot in range(SaveManager.MAX_SLOTS - 1, -1, -1):
					if SaveManager.has_save(slot):
						GameManager.load_game(slot)
						break
		2: # Options
			pass # TODO: options screen


func _has_any_save() -> bool:
	for slot in SaveManager.MAX_SLOTS:
		if SaveManager.has_save(slot):
			return true
	return false
