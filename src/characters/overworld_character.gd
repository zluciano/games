extends Node2D
## Overworld character sprite using region_rect for precise frame selection.
## Sprite sheets are 512x256 with 3 rows x 10 columns.
## Row 0: walk down, Row 1: walk up, Row 2: walk sideways (flip for left/right)

@export var sprite_path: String = ""
@export var character_id: String = ""
@export var walk_speed: float = 60.0

enum Direction { DOWN = 0, UP = 1, LEFT = 2, RIGHT = 3 }

const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const SHADOW_RADIUS := Vector2(12.0, 6.0)

const FRAME_W := 51
const FRAME_H := 85
const ROW_Y := [0, 85, 170]
const FRAME_COUNT_FRONT := 10
const FRAME_COUNT_SIDE := 8

var current_direction: int = Direction.DOWN
var is_moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var _frame: int = 0


func _ready() -> void:
	sprite.offset.y = -22
	if not sprite_path.is_empty():
		load_sprite(sprite_path)
	anim_timer.timeout.connect(_advance_frame)


func _draw() -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var angle := i * TAU / 16.0
		points.append(Vector2(cos(angle) * SHADOW_RADIUS.x,
							  sin(angle) * SHADOW_RADIUS.y))
	draw_colored_polygon(points, SHADOW_COLOR)


func load_sprite(path: String) -> void:
	sprite_path = path
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if not tex:
		return
	sprite.texture = tex
	sprite.region_enabled = true
	_update_frame()


func walk(direction: int) -> void:
	current_direction = direction
	is_moving = true
	var max_frames := FRAME_COUNT_SIDE if direction >= Direction.LEFT else FRAME_COUNT_FRONT
	if _frame >= max_frames:
		_frame = 0
	_update_frame()
	if anim_timer.is_stopped():
		anim_timer.start()


func idle(direction: int = -1) -> void:
	if direction >= 0:
		current_direction = direction
	is_moving = false
	_frame = 0
	_update_frame()
	anim_timer.stop()


func face_towards(target_pos: Vector2) -> void:
	var delta := target_pos - global_position
	if abs(delta.x) > abs(delta.y):
		idle(Direction.RIGHT if delta.x > 0 else Direction.LEFT)
	else:
		idle(Direction.DOWN if delta.y > 0 else Direction.UP)


func _advance_frame() -> void:
	if not is_moving:
		return
	var max_frames := FRAME_COUNT_SIDE if current_direction >= Direction.LEFT else FRAME_COUNT_FRONT
	_frame = (_frame + 1) % max_frames
	_update_frame()


func _update_frame() -> void:
	var row: int
	match current_direction:
		Direction.DOWN:
			row = 0
			sprite.flip_h = false
		Direction.UP:
			row = 1
			sprite.flip_h = false
		Direction.LEFT:
			row = 2
			sprite.flip_h = true
		Direction.RIGHT:
			row = 2
			sprite.flip_h = false
		_:
			row = 0
			sprite.flip_h = false
	sprite.region_rect = Rect2(_frame * FRAME_W, ROW_Y[row], FRAME_W, FRAME_H)
