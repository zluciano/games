extends CanvasLayer
## Screen transition overlay - supports fade and dissolve effects.

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	layer = 100
	color_rect.color = Color.BLACK
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_out(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished


func fade_in(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished
