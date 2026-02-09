extends RichTextLabel
## Typewriter text display - reveals characters one at a time.

signal text_finished

var _target_length: int = 0
var _tween: Tween


func display_text(text: String, chars_per_second: float = 30.0) -> void:
	self.text = text
	visible_characters = 0
	_target_length = text.length()

	if _tween:
		_tween.kill()

	var duration := _target_length / chars_per_second
	_tween = create_tween()
	_tween.tween_property(self, "visible_characters", _target_length, duration)
	_tween.tween_callback(_on_finished)


func skip() -> void:
	if _tween:
		_tween.kill()
	visible_characters = _target_length
	_on_finished()


func is_playing() -> bool:
	return visible_characters < _target_length


func _on_finished() -> void:
	visible_characters = -1  # Show all
	text_finished.emit()
