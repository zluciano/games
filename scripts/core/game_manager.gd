extends Node

## Main game manager - handles global game state
## Access via autoload: GameManager.time_system, GameManager.change_state(), etc.

# Game state
enum GameState { EXPLORATION, DIALOGUE, DUEL, MENU, CUTSCENE, TRANSITION }
var current_state: GameState = GameState.EXPLORATION

# References
var time_system: TimeSystem
var player: PlayerController

# Signals
signal state_changed(new_state: GameState)
signal game_paused
signal game_resumed


func _ready() -> void:
	# Find or create time system
	time_system = TimeSystem.new()
	add_child(time_system)


func _process(_delta: float) -> void:
	# Find player reference if not set
	if not player:
		var found_player = get_tree().get_first_node_in_group("player")
		if found_player and found_player is PlayerController:
			player = found_player


func change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	var old_state = current_state
	current_state = new_state

	match new_state:
		GameState.EXPLORATION:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_tree().paused = false
		GameState.DIALOGUE, GameState.MENU:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameState.DUEL:
			# Will handle EDOPro integration later
			pass
		GameState.CUTSCENE, GameState.TRANSITION:
			# Disable player input during cutscenes/transitions
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	state_changed.emit(new_state)
	print("[GameManager] State changed: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])


func is_exploration() -> bool:
	return current_state == GameState.EXPLORATION


func is_dialogue() -> bool:
	return current_state == GameState.DIALOGUE


func start_duel(opponent_deck: String = "") -> void:
	change_state(GameState.DUEL)
	# TODO: Launch EDOPro with deck configurations
	print("[GameManager] Starting duel against: %s" % opponent_deck)


func end_duel(victory: bool) -> void:
	change_state(GameState.EXPLORATION)
	print("[GameManager] Duel ended. Victory: %s" % victory)
	# TODO: Award DP (duel points) based on victory


# Save/Load system placeholder
func save_game(slot: int = 0) -> void:
	print("[GameManager] Saving game to slot %d" % slot)
	# TODO: Implement save system


func load_game(slot: int = 0) -> void:
	print("[GameManager] Loading game from slot %d" % slot)
	# TODO: Implement load system
