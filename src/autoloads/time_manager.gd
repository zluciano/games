extends Node
## Tracks in-game time, controls day/sunset/night cycle.

signal time_changed(new_time: String)
signal day_advanced(day_number: int)

const TIME_PHASES := ["day", "sunset", "night"]
const BIG_MAP_FOLDERS := {
	"day": "w_day",
	"sunset": "w_sunset",
	"night": "w_night",
}

var time_of_day: String = "day"
var day_number: int = 1


func advance_time() -> void:
	var idx := TIME_PHASES.find(time_of_day)
	idx = (idx + 1) % TIME_PHASES.size()

	if idx == 0:
		day_number += 1
		GameManager.game_data["day_number"] = day_number
		day_advanced.emit(day_number)

	set_time(TIME_PHASES[idx])


func set_time(phase: String) -> void:
	if phase not in TIME_PHASES:
		push_warning("Invalid time phase: %s" % phase)
		return
	time_of_day = phase
	GameManager.game_data["time_of_day"] = phase
	time_changed.emit(phase)


func get_big_map_folder() -> String:
	return BIG_MAP_FOLDERS.get(time_of_day, "w_day")
