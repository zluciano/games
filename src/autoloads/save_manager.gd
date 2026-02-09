extends Node
## Serializes/deserializes game state to user://saves/.

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 3


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: int) -> bool:
	var data := GameManager.game_data.duplicate(true)
	data["save_timestamp"] = Time.get_datetime_string_from_system()

	var path := _slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to save: %s" % path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_game(slot: int) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("Failed to parse save: %s" % path)
		return {}

	return json.data as Dictionary


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


func delete_save(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func get_save_info(slot: int) -> Dictionary:
	var data := load_game(slot)
	if data.is_empty():
		return {}
	return {
		"location": data.get("location", "Unknown"),
		"time_of_day": data.get("time_of_day", "day"),
		"day_number": data.get("day_number", 1),
		"play_time": data.get("play_time_seconds", 0),
		"timestamp": data.get("save_timestamp", ""),
	}


func _slot_path(slot: int) -> String:
	return SAVE_DIR + "slot_%d.json" % slot
