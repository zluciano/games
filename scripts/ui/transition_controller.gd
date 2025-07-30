extends CanvasLayer
class_name TransitionController

## Transition UI - Full screen fade with location name display

@onready var fade_rect: ColorRect = $FadeRect
@onready var location_label: Label = $FadeRect/LocationLabel

# Transition settings
@export var fade_duration: float = 0.4
@export var location_display_time: float = 0.8

# Colors
var fade_color: Color = Color(0, 0, 0, 1)
var transparent_color: Color = Color(0, 0, 0, 0)


func _ready() -> void:
	# Start fully transparent
	fade_rect.color = transparent_color
	fade_rect.visible = false
	location_label.text = ""
	location_label.modulate.a = 0.0


## Fade to black and show location name
func fade_out(location_name: String = "") -> void:
	fade_rect.visible = true
	fade_rect.color = transparent_color
	location_label.text = location_name
	location_label.modulate.a = 0.0

	# Fade to black
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(fade_rect, "color", fade_color, fade_duration)
	await tween.finished

	# Show location name if provided
	if location_name != "":
		var label_tween = create_tween()
		label_tween.tween_property(location_label, "modulate:a", 1.0, 0.3)
		await label_tween.finished

		# Hold for display time
		await get_tree().create_timer(location_display_time).timeout


## Fade from black to transparent
func fade_in() -> void:
	# Hide location label first
	if location_label.modulate.a > 0:
		var label_tween = create_tween()
		label_tween.tween_property(location_label, "modulate:a", 0.0, 0.2)
		await label_tween.finished

	# Fade to transparent
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(fade_rect, "color", transparent_color, fade_duration)
	await tween.finished

	fade_rect.visible = false
	location_label.text = ""


## Quick fade (no location display)
func quick_fade_out() -> void:
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", fade_color, fade_duration * 0.5)
	await tween.finished


func quick_fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color", transparent_color, fade_duration * 0.5)
	await tween.finished
	fade_rect.visible = false
