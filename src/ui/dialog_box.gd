extends CanvasLayer
## Dialog system - processes dialog lines with bustup portraits and typewriter text.

signal dialog_started
signal dialog_finished
signal choice_made(index: int)

var _lines: Array = []
var _current_line: int = 0
var _is_active: bool = false
var _waiting_for_input: bool = false

@onready var panel: Control = $Panel
@onready var portrait: Control = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var text_display: RichTextLabel = $Panel/TextDisplay
@onready var continue_indicator: Label = $Panel/ContinueIndicator
@onready var dim_bg: ColorRect = $DimBG


func _ready() -> void:
	panel.visible = false
	dim_bg.visible = false
	continue_indicator.visible = false
	text_display.text_finished.connect(_on_text_finished)


func start_dialog(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_current_line = 0
	_is_active = true
	panel.visible = true
	dim_bg.visible = true
	dialog_started.emit()
	_show_line(_lines[0])


func _show_line(line: Dictionary) -> void:
	continue_indicator.visible = false
	_waiting_for_input = false

	# Set character portrait
	var speaker: String = line.get("speaker", "")
	if not speaker.is_empty():
		portrait.visible = true
		portrait.set_character(speaker)
		var expression: int = line.get("expression", 0)
		portrait.set_expression(expression)
		portrait.start_talking()
		name_label.text = CharacterDB.get_character(speaker).get("name", speaker)
	else:
		portrait.visible = false
		name_label.text = ""

	# Display text with typewriter effect
	var dialog_text: String = line.get("text", "")
	text_display.display_text(dialog_text)


func _on_text_finished() -> void:
	portrait.stop_talking()
	_waiting_for_input = true
	continue_indicator.visible = true


func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if text_display.is_playing():
			# Skip typewriter
			text_display.skip()
		elif _waiting_for_input:
			_advance()


func _advance() -> void:
	_current_line += 1
	if _current_line >= _lines.size():
		_close()
	else:
		_show_line(_lines[_current_line])


func _close() -> void:
	_is_active = false
	panel.visible = false
	dim_bg.visible = false
	portrait.stop_talking()
	_lines.clear()
	dialog_finished.emit()
