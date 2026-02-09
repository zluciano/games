extends Node2D
## Root controller for a location scene. Manages NPCs, exits, and player spawning.

const DIALOG_BOX_SCENE := preload("res://scenes/components/dialog_box.tscn")
const NPC_SCENE := preload("res://scenes/components/npc.tscn")

@export var map_id: String = ""
@export var display_name: String = ""
@export var is_interior: bool = false

var _spawn_point: String = "default"

@onready var player: Node2D = $Player
@onready var location_label: Label = $UI/LocationLabel


func _ready() -> void:
	GameManager.change_state(GameManager.State.LOCATION)

	# Add dialog box to scene
	var dialog_box := DIALOG_BOX_SCENE.instantiate()
	dialog_box.add_to_group("dialog_box")
	add_child(dialog_box)

	# Spawn NPCs based on schedule
	_spawn_npcs()

	# Position player at spawn point
	_apply_spawn_point()

	# Show location name briefly
	if location_label:
		location_label.text = display_name
		location_label.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(location_label, "modulate:a", 0.0, 0.5)


func set_spawn_point(point: String) -> void:
	_spawn_point = point
	_apply_spawn_point()


func _apply_spawn_point() -> void:
	match _spawn_point:
		"default":
			player.position = Vector2(240, 180)
		_:
			var marker := find_child(_spawn_point)
			if marker:
				player.position = marker.position
			else:
				player.position = Vector2(240, 180)


func _spawn_npcs() -> void:
	var time := TimeManager.time_of_day
	var npc_list: Array = CharacterDB.get_characters_at_location(map_id, time)
	for npc_data in npc_list:
		var npc := NPC_SCENE.instantiate()
		npc.character_id = npc_data.get("id", "")
		var pos: Array = npc_data.get("position", [240, 136])
		npc.position = Vector2(pos[0], pos[1])
		npc.idle_direction = npc_data.get("direction", 0)
		add_child(npc)
