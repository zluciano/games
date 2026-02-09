extends Control
## Layered character portrait: body base + expression overlay + animated mouth.

var character_id: String = ""
var is_talking: bool = false

var _mouth_frames: Array[Texture2D] = []
var _mouth_index: int = 0
var _talk_mouth_count: int = 4  # Cycle through first 4 mouth frames for talk anim

@onready var body_sprite: TextureRect = $Body
@onready var expression_sprite: TextureRect = $Expression
@onready var mouth_sprite: TextureRect = $Mouth
@onready var mouth_timer: Timer = $MouthTimer


func _ready() -> void:
	mouth_timer.timeout.connect(_on_mouth_tick)


func set_character(char_id: String) -> void:
	character_id = char_id
	var base_path := CharacterDB.get_bustup_path(char_id)

	# Load base body (body0004.png - 256x256)
	var body_path := base_path + "body0004.png"
	if ResourceLoader.exists(body_path):
		body_sprite.texture = load(body_path)

	# Load default expression (body0006.png)
	set_expression(0)

	# Load mouth frames
	_mouth_frames.clear()
	var idx := 1
	while true:
		var mouth_path := base_path + "mouth%04d.png" % idx
		if not ResourceLoader.exists(mouth_path):
			break
		_mouth_frames.append(load(mouth_path))
		idx += 2  # Odd numbers: 0001, 0003, 0005...

	# Set default closed mouth
	if _mouth_frames.size() > 0:
		mouth_sprite.texture = _mouth_frames[0]


func set_expression(index: int) -> void:
	var base_path := CharacterDB.get_bustup_path(character_id)
	# Expressions start at body0006 and go by even numbers
	var file_index := 6 + (index * 2)
	var expr_path := base_path + "body%04d.png" % file_index
	if ResourceLoader.exists(expr_path):
		expression_sprite.texture = load(expr_path)


func start_talking() -> void:
	is_talking = true
	_mouth_index = 0
	mouth_timer.start()


func stop_talking() -> void:
	is_talking = false
	mouth_timer.stop()
	# Reset to closed mouth
	if _mouth_frames.size() > 0:
		mouth_sprite.texture = _mouth_frames[0]


func _on_mouth_tick() -> void:
	if not is_talking or _mouth_frames.is_empty():
		return
	_mouth_index = (_mouth_index + 1) % mini(_talk_mouth_count, _mouth_frames.size())
	mouth_sprite.texture = _mouth_frames[_mouth_index]
