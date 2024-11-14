extends Node
class_name SceneManagerClass

## Scene Manager - Handles scene transitions with fade effects
## Access via autoload: SceneManager.change_scene(), SceneManager.current_location, etc.

# Location data
enum Location {
	COURTYARD,
	SLIFER_DORM,
	ACADEMY_HALLWAY,
	CLASSROOM,
	CARD_SHOP
}

const LOCATION_PATHS: Dictionary = {
	Location.COURTYARD: "res://scenes/locations/courtyard.tscn",
	Location.SLIFER_DORM: "res://scenes/locations/slifer_dorm.tscn",
	Location.ACADEMY_HALLWAY: "res://scenes/locations/academy_hallway.tscn",
	Location.CLASSROOM: "res://scenes/locations/classroom.tscn",
	Location.CARD_SHOP: "res://scenes/locations/card_shop.tscn"
}

const LOCATION_NAMES: Dictionary = {
	Location.COURTYARD: "Academy Courtyard",
	Location.SLIFER_DORM: "Slifer Red Dorm",
	Location.ACADEMY_HALLWAY: "Academy Hallway",
	Location.CLASSROOM: "Classroom",
	Location.CARD_SHOP: "Card Shop"
}

# Current state
var current_location: Location = Location.COURTYARD
var current_spawn_point: String = "default"
var is_transitioning: bool = false

# Transition UI reference
var _transition_ui: CanvasLayer = null

# Preloaded scenes cache
var _preloaded_scenes: Dictionary = {}

# Adjacent locations for preloading (which scenes connect to which)
# Card Shop is INSIDE the academy building, accessed from hallway
const ADJACENT_LOCATIONS: Dictionary = {
	Location.COURTYARD: [Location.ACADEMY_HALLWAY, Location.SLIFER_DORM],
	Location.ACADEMY_HALLWAY: [Location.COURTYARD, Location.CLASSROOM, Location.CARD_SHOP],
	Location.CLASSROOM: [Location.ACADEMY_HALLWAY],
	Location.SLIFER_DORM: [Location.COURTYARD],
	Location.CARD_SHOP: [Location.ACADEMY_HALLWAY]
}

# Signals
signal scene_change_started(from_location: Location, to_location: Location)
signal scene_change_completed(new_location: Location)
signal transition_midpoint  # Fired when screen is fully black


func _ready() -> void:
	# Create transition UI
	_create_transition_ui()
	print("[SceneManager] Initialized")

	# Preload adjacent scenes for starting location after a brief delay
	await get_tree().create_timer(1.0).timeout
	_preload_adjacent_scenes(current_location)


func _create_transition_ui() -> void:
	# Load transition scene
	var transition_scene = load("res://scenes/ui/transition.tscn")
	if transition_scene:
		_transition_ui = transition_scene.instantiate()
		add_child(_transition_ui)
	else:
		push_warning("[SceneManager] Could not load transition UI scene")


## Change to a new scene/location
func change_scene(location: Location, spawn_point: String = "default") -> void:
	if is_transitioning:
		push_warning("[SceneManager] Already transitioning, ignoring request")
		return

	if not LOCATION_PATHS.has(location):
		push_error("[SceneManager] Invalid location: %s" % location)
		return

	var old_location = current_location
	is_transitioning = true
	scene_change_started.emit(old_location, location)

	print("[SceneManager] Transitioning from %s to %s (spawn: %s)" % [
		LOCATION_NAMES.get(old_location, "Unknown"),
		LOCATION_NAMES.get(location, "Unknown"),
		spawn_point
	])

	# Store target data
	current_spawn_point = spawn_point

	# Start transition
	await _perform_transition(location)

	current_location = location
	is_transitioning = false
	scene_change_completed.emit(location)

	# Preload adjacent scenes in background for faster future transitions
	_preload_adjacent_scenes(location)


## Change scene by path (for non-enum scenes)
func change_scene_path(scene_path: String, location_name: String = "", spawn_point: String = "default") -> void:
	if is_transitioning:
		return

	is_transitioning = true
	current_spawn_point = spawn_point

	await _perform_transition_path(scene_path, location_name)

	is_transitioning = false


func _perform_transition(location: Location) -> void:
	var scene_path = LOCATION_PATHS[location]
	var location_name = LOCATION_NAMES.get(location, "")
	await _perform_transition_path(scene_path, location_name)


func _perform_transition_path(scene_path: String, location_name: String) -> void:
	# Disable player input during transition
	GameManager.change_state(GameManager.GameState.CUTSCENE)

	# Start background loading immediately (loads during fade-out)
	var load_status = ResourceLoader.load_threaded_request(scene_path)
	if load_status != OK:
		push_error("[SceneManager] Failed to start loading scene: %s" % scene_path)
		is_transitioning = false
		GameManager.change_state(GameManager.GameState.EXPLORATION)
		return

	# Fade out (scene loads in background during this time)
	if _transition_ui and _transition_ui.has_method("fade_out"):
		await _transition_ui.fade_out(location_name)
	else:
		await get_tree().create_timer(0.5).timeout

	transition_midpoint.emit()

	# Wait for scene to finish loading if it hasn't yet
	var packed_scene: PackedScene = null
	while true:
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			packed_scene = ResourceLoader.load_threaded_get(scene_path)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			push_error("[SceneManager] Failed to load scene: %s" % scene_path)
			is_transitioning = false
			GameManager.change_state(GameManager.GameState.EXPLORATION)
			return
		await get_tree().process_frame

	# Change to loaded scene
	var error = get_tree().change_scene_to_packed(packed_scene)
	if error != OK:
		push_error("[SceneManager] Failed to change to scene: %s" % scene_path)
		is_transitioning = false
		GameManager.change_state(GameManager.GameState.EXPLORATION)
		return

	# Wait for scene to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	# Position player at spawn point BEFORE any physics runs
	_position_player_at_spawn()

	# Wait for physics to settle after positioning
	await get_tree().create_timer(0.15).timeout

	# Setup camera after player is positioned
	_setup_camera_for_player()

	# Extra wait to ensure everything is stable
	await get_tree().process_frame
	await get_tree().process_frame

	# Fade in
	if _transition_ui and _transition_ui.has_method("fade_in"):
		await _transition_ui.fade_in()
	else:
		await get_tree().create_timer(0.5).timeout

	# Re-enable player input
	GameManager.change_state(GameManager.GameState.EXPLORATION)


func _position_player_at_spawn() -> void:
	# Find player in the new scene
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try to find by class
		for node in get_tree().get_nodes_in_group("player"):
			if node is CharacterBody3D:
				player = node
				break

	if not player:
		push_warning("[SceneManager] Could not find player node")
		return

	# Find spawn point
	var spawn_points = get_tree().get_nodes_in_group("spawn_points")
	var target_spawn: Node3D = null

	for spawn in spawn_points:
		if spawn.name == current_spawn_point or (current_spawn_point == "default" and spawn.name == "DefaultSpawn"):
			target_spawn = spawn
			break

	# Fallback to first spawn point
	if not target_spawn and spawn_points.size() > 0:
		target_spawn = spawn_points[0]

	if target_spawn:
		# Position player at spawn point (slight Y offset to ensure grounding)
		var spawn_pos = target_spawn.global_position
		spawn_pos.y = max(spawn_pos.y, 0.05)  # Ensure slightly above floor
		player.global_position = spawn_pos

		# Reset ALL movement state
		player.velocity = Vector3.ZERO
		if "current_speed" in player:
			player.current_speed = 0.0
		if "movement_direction" in player:
			player.movement_direction = Vector3.ZERO
		if "input_direction" in player:
			player.input_direction = Vector2.ZERO

		# Set rotation based on spawn point's look_direction
		var look_dir = 0.0
		if target_spawn.has_meta("look_direction"):
			look_dir = target_spawn.get_meta("look_direction")

		# Player body rotation stays at 0 - we only rotate the skin to face the look direction
		player.rotation.y = 0.0
		player.rotation.x = 0.0
		player.rotation.z = 0.0

		# Rotate the skin to face the spawn direction
		# This prevents moonwalking by ensuring skin faces where player should be looking
		if player.get("skin"):
			player.skin.rotation.y = look_dir
			player.skin.rotation.x = 0.0
			player.skin.rotation.z = 0.0
		elif player.has_node("SophiaSkin"):
			var skin = player.get_node("SophiaSkin")
			skin.rotation.y = look_dir
			skin.rotation.x = 0.0
			skin.rotation.z = 0.0
		elif player.has_node("JudaiSkin"):
			var skin = player.get_node("JudaiSkin")
			skin.rotation.y = look_dir
			skin.rotation.x = 0.0
			skin.rotation.z = 0.0

		print("[SceneManager] Player positioned at spawn: %s, pos: %s, facing: %s rad" % [target_spawn.name, spawn_pos, look_dir])
	else:
		push_warning("[SceneManager] No spawn point found, player stays at origin")


func _setup_camera_for_player() -> void:
	# Find the camera and player, then connect them
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Find ThirdPersonCamera in the scene
	var camera = _find_node_by_class(get_tree().root, "ThirdPersonCamera")
	if camera and camera.has_method("set_target"):
		camera.set_target(player)
		print("[SceneManager] Camera connected to player")
	elif camera:
		# Fallback: set _target_node directly if possible
		if "_target_node" in camera:
			camera._target_node = player
			print("[SceneManager] Camera _target_node set to player")


func _find_node_by_class(node: Node, class_name_str: String) -> Node:
	if node.get_class() == class_name_str or (node.get_script() and node.get_script().get_global_name() == class_name_str):
		return node
	for child in node.get_children():
		var found = _find_node_by_class(child, class_name_str)
		if found:
			return found
	return null


## Get the display name for a location
func get_location_name(location: Location) -> String:
	return LOCATION_NAMES.get(location, "Unknown Location")


## Get current location name
func get_current_location_name() -> String:
	return LOCATION_NAMES.get(current_location, "Unknown Location")


## Preload adjacent scenes in background for faster transitions
func _preload_adjacent_scenes(location: Location) -> void:
	if not ADJACENT_LOCATIONS.has(location):
		return

	for adjacent in ADJACENT_LOCATIONS[location]:
		if not LOCATION_PATHS.has(adjacent):
			continue

		var path = LOCATION_PATHS[adjacent]
		if _preloaded_scenes.has(path):
			continue  # Already preloaded

		# Start background load
		var status = ResourceLoader.load_threaded_request(path)
		if status == OK:
			print("[SceneManager] Preloading: %s" % LOCATION_NAMES.get(adjacent, path))
