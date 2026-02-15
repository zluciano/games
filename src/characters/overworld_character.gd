extends Node2D
## Overworld character sprite using region_rect for precise frame selection.
## Sprite sheets are 512x256 with 3 rows x 10 columns.
## Row 0: walk SW/S/SE, Row 1: walk NW/N/NE, Row 2: walk E/W (flip for W)
## 8 directions: S, SW, W, NW, N, NE, E, SE

@export var sprite_path: String = ""
@export var character_id: String = ""
@export var walk_speed: float = 60.0

enum Direction { S = 0, SW = 1, W = 2, NW = 3, N = 4, NE = 5, E = 6, SE = 7 }

const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const SHADOW_RADIUS := Vector2(12.0, 6.0)

const FRAME_W := 51
const FRAME_H := 85
const ROW_Y := [0, 85, 170]
const FRAME_COUNT_FRONT := 10
const FRAME_COUNT_SIDE := 8

# Maps each direction to [row_index, flip_h]
const DIR_MAP := {
	Direction.S:  [0, false],
	Direction.SW: [0, false],
	Direction.SE: [0, true],
	Direction.N:  [1, false],
	Direction.NW: [1, false],
	Direction.NE: [1, true],
	Direction.E:  [2, false],
	Direction.W:  [2, true],
}

var current_direction: int = Direction.S
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


func _max_frames_for(direction: int) -> int:
	var row: int = DIR_MAP[direction][0]
	return FRAME_COUNT_SIDE if row == 2 else FRAME_COUNT_FRONT


func walk(direction: int) -> void:
	current_direction = direction
	is_moving = true
	if _frame >= _max_frames_for(direction):
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
	var dir: int = _vector_to_direction(delta)
	idle(dir)


func _advance_frame() -> void:
	if not is_moving:
		return
	var max_frames := _max_frames_for(current_direction)
	_frame = (_frame + 1) % max_frames
	_update_frame()


func _update_frame() -> void:
	var mapping: Array = DIR_MAP[current_direction]
	var row: int = mapping[0]
	sprite.flip_h = mapping[1]
	sprite.region_rect = Rect2(_frame * FRAME_W, ROW_Y[row], FRAME_W, FRAME_H)


## Convert a movement vector to the closest 8-way direction.
static func _vector_to_direction(v: Vector2) -> int:
	if v == Vector2.ZERO:
		return Direction.S
	var angle := v.angle()
	# Snap to 8 sectors (each 45 degrees = PI/4)
	# angle=0 is right (E), goes counter-clockwise in math but
	# Godot's y-axis is inverted so positive angle = clockwise = south
	var sector := int(round(angle / (PI / 4.0))) % 8
	if sector < 0:
		sector += 8
	# sector 0=E, 1=SE, 2=S, 3=SW, 4=W, 5=NW, 6=N, 7=NE
	const SECTOR_TO_DIR := [Direction.E, Direction.SE, Direction.S, Direction.SW,
							Direction.W, Direction.NW, Direction.N, Direction.NE]
	return SECTOR_TO_DIR[sector]
