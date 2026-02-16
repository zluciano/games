extends Node
## Central registry of all character data. Loaded from JSON.

const REGISTRY_PATH := "res://data/characters/character_registry.json"
const SCHEDULES_PATH := "res://data/characters/character_schedules.json"
const BUSTUP_BASE := "res://assets/tagforce/characters/bustup/"
const SLA_BASE := "res://assets/tagforce/characters/sprites_sla/"
const VER_BASE := "res://assets/tagforce/characters/sprites_ver/"

var characters: Dictionary = {}
var schedules: Dictionary = {}


func _ready() -> void:
	_load_registry()
	_load_schedules()


func _load_registry() -> void:
	if not FileAccess.file_exists(REGISTRY_PATH):
		return
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		characters = json.data
	file.close()


func _load_schedules() -> void:
	if not FileAccess.file_exists(SCHEDULES_PATH):
		return
	var file := FileAccess.open(SCHEDULES_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		schedules = json.data
	file.close()


func get_character(id: String) -> Dictionary:
	return characters.get(id, {})


func get_characters_at_location(map_id: String, time: String) -> Array:
	var location_schedules: Dictionary = schedules.get(map_id, {})
	return location_schedules.get(time, [])


func get_bustup_path(char_id: String) -> String:
	var data := get_character(char_id)
	var folder: String = data.get("bustup_folder", char_id)
	return BUSTUP_BASE + folder + "/"


func get_sla_path(char_id: String) -> String:
	var data := get_character(char_id)
	var sprite: String = data.get("sla_sprite", "")
	if sprite.is_empty():
		return ""
	return SLA_BASE + sprite


func get_ver_path(char_id: String) -> String:
	var sla := get_sla_path(char_id)
	if sla.is_empty():
		return ""
	return sla.replace("sprites_sla", "sprites_ver").replace("_sla.", "_ver.")
