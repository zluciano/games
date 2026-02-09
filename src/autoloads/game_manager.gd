extends Node
## Master game state machine controlling the entire game flow.

signal state_changed(old_state: String, new_state: String)
signal game_started
signal game_loaded

enum State { BOOT, TITLE, MAIN_MENU, BIG_MAP, LOCATION, DIALOG, SAVE_LOAD, OPTIONS }

var current_state: int = State.BOOT
var previous_state: int = State.BOOT

var game_data: Dictionary = {}


func _ready() -> void:
	_init_game_data()


func _init_game_data() -> void:
	game_data = {
		"location": "BG_22_01",
		"time_of_day": "day",
		"day_number": 1,
		"story_flags": {},
		"characters_met": [],
		"player_name": "Player",
		"play_time_seconds": 0,
	}


func change_state(new_state: int) -> void:
	previous_state = current_state
	current_state = new_state
	state_changed.emit(previous_state, current_state)


func start_new_game() -> void:
	_init_game_data()
	TimeManager.set_time("day")
	game_started.emit()
	change_state(State.LOCATION)
	SceneManager.goto_location("BG_22_01")


func load_game(slot: int) -> void:
	var data := SaveManager.load_game(slot)
	if data.is_empty():
		return
	game_data = data
	TimeManager.set_time(game_data.get("time_of_day", "day"))
	game_loaded.emit()
	change_state(State.LOCATION)
	SceneManager.goto_location(game_data.get("location", "BG_22_01"))
