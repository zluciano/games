extends Node2D
## Overworld character using SLA spritesheet (512x256, 8 cols x 4 rows, 64x64 frames).
## Row 0: walk down, Row 1: walk left, Row 2: walk right, Row 3: walk up

@export var sprite_path: String = ""
@export var character_id: String = ""
@export var walk_speed: float = 60.0

enum Direction { DOWN = 0, LEFT = 1, RIGHT = 2, UP = 3 }

var current_direction: int = Direction.DOWN
var is_moving: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: Timer = $AnimTimer

var _frame: int = 0
var _anim_frames := [0, 1, 2, 3, 4, 5, 6, 7]


func _ready() -> void:
	if not sprite_path.is_empty():
		load_sprite(sprite_path)
	anim_timer.timeout.connect(_advance_frame)


func load_sprite(path: String) -> void:
	sprite_path = path
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			sprite.texture = tex
			sprite.hframes = 8
			sprite.vframes = 4
			sprite.frame = 0


func walk(direction: int) -> void:
	current_direction = direction
	is_moving = true
	sprite.frame = current_direction * 8 + _frame
	if anim_timer.is_stopped():
		anim_timer.start()


func idle(direction: int = -1) -> void:
	if direction >= 0:
		current_direction = direction
	is_moving = false
	_frame = 0
	sprite.frame = current_direction * 8
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
	_frame = (_frame + 1) % 8
	sprite.frame = current_direction * 8 + _frame
