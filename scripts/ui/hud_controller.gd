extends Control
class_name HUDController

## HUD Controller - Updates the Persona-style date/time display and minimap

@onready var date_label: Label = %DateLabel
@onready var time_label: Label = %TimeLabel
@onready var minimap: Minimap = %Minimap

var time_system: TimeSystem


func _ready() -> void:
	# Wait a frame to ensure GameManager is ready
	await get_tree().process_frame

	if GameManager and GameManager.time_system:
		time_system = GameManager.time_system
		time_system.time_advanced.connect(_on_time_advanced)
		time_system.day_changed.connect(_on_day_changed)
		_update_display()

	# Connect to scene changes for minimap updates
	if SceneManager:
		SceneManager.scene_change_completed.connect(_on_scene_changed)
		# Set initial location
		_update_minimap_location(SceneManager.current_location)


func _update_display() -> void:
	if not time_system:
		return

	date_label.text = time_system.get_date_string()
	time_label.text = time_system.get_period_name()


func _on_time_advanced(_new_period: TimeSystem.TimePeriod) -> void:
	_update_display()
	# Add animation here later (like Persona's time transition)


func _on_day_changed(_new_day: int, _new_month: int) -> void:
	_update_display()
	# Add day transition animation here later


func _on_scene_changed(new_location: int) -> void:
	_update_minimap_location(new_location)


func _update_minimap_location(location: int) -> void:
	if not minimap:
		return

	# Map Location enum to minimap keys
	var location_keys: Dictionary = {
		0: "courtyard",         # COURTYARD
		1: "slifer_dorm",       # SLIFER_DORM
		2: "academy_hallway",   # ACADEMY_HALLWAY
		3: "classroom",         # CLASSROOM
		4: "card_shop",         # CARD_SHOP
	}

	var key: String = location_keys.get(location, "courtyard")
	minimap.set_location(key)
