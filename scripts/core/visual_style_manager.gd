extends Node
class_name VisualStyleManager

## Visual Style Manager - Controls lighting, atmosphere, and post-processing
## Syncs with TimeSystem for dynamic time-of-day visuals

# Time-of-day lighting presets (Persona-inspired)
const LIGHTING_PRESETS = {
	TimeSystem.TimePeriod.EARLY_MORNING: {
		"sun_color": Color(1.0, 0.85, 0.7),
		"sun_energy": 0.6,
		"sun_angle": -15.0,
		"ambient_color": Color(0.4, 0.45, 0.6),
		"ambient_energy": 0.4,
		"fog_color": Color(0.7, 0.75, 0.85),
		"fog_density": 0.01,
		"sky_top": Color(0.4, 0.5, 0.7),
		"sky_horizon": Color(1.0, 0.8, 0.6),
	},
	TimeSystem.TimePeriod.MORNING: {
		"sun_color": Color(1.0, 0.95, 0.9),
		"sun_energy": 1.0,
		"sun_angle": 30.0,
		"ambient_color": Color(0.5, 0.55, 0.65),
		"ambient_energy": 0.5,
		"fog_color": Color(0.8, 0.85, 0.9),
		"fog_density": 0.005,
		"sky_top": Color(0.3, 0.5, 0.8),
		"sky_horizon": Color(0.7, 0.8, 0.9),
	},
	TimeSystem.TimePeriod.AFTERNOON: {
		"sun_color": Color(1.0, 0.98, 0.95),
		"sun_energy": 1.2,
		"sun_angle": 60.0,
		"ambient_color": Color(0.55, 0.6, 0.7),
		"ambient_energy": 0.55,
		"fog_color": Color(0.85, 0.88, 0.92),
		"fog_density": 0.003,
		"sky_top": Color(0.25, 0.45, 0.85),
		"sky_horizon": Color(0.6, 0.75, 0.9),
	},
	TimeSystem.TimePeriod.EVENING: {
		"sun_color": Color(1.0, 0.6, 0.3),
		"sun_energy": 0.8,
		"sun_angle": 10.0,
		"ambient_color": Color(0.6, 0.4, 0.5),
		"ambient_energy": 0.4,
		"fog_color": Color(0.9, 0.7, 0.5),
		"fog_density": 0.008,
		"sky_top": Color(0.3, 0.25, 0.5),
		"sky_horizon": Color(1.0, 0.5, 0.3),
	},
	TimeSystem.TimePeriod.NIGHT: {
		"sun_color": Color(0.4, 0.5, 0.7),
		"sun_energy": 0.15,
		"sun_angle": -30.0,
		"ambient_color": Color(0.15, 0.18, 0.3),
		"ambient_energy": 0.3,
		"fog_color": Color(0.1, 0.12, 0.2),
		"fog_density": 0.015,
		"sky_top": Color(0.05, 0.08, 0.15),
		"sky_horizon": Color(0.1, 0.15, 0.25),
	},
}

# References
var environment: Environment
var sun: DirectionalLight3D
var world_environment: WorldEnvironment

# Transition
var transition_duration: float = 2.0
var current_preset: Dictionary = {}
var target_preset: Dictionary = {}
var transition_progress: float = 1.0


func _ready() -> void:
	# Connect to time system
	if GameManager and GameManager.time_system:
		GameManager.time_system.time_advanced.connect(_on_time_advanced)
		# Initialize with current period
		call_deferred("_initialize_lighting")


func _initialize_lighting() -> void:
	_find_environment_nodes()
	if GameManager and GameManager.time_system:
		var period = GameManager.time_system.current_period
		if period in LIGHTING_PRESETS:
			current_preset = LIGHTING_PRESETS[period].duplicate()
			target_preset = current_preset.duplicate()
			_apply_preset_immediate(current_preset)


func _find_environment_nodes() -> void:
	# Find WorldEnvironment in current scene
	world_environment = get_tree().get_first_node_in_group("world_environment")
	if not world_environment:
		var nodes = get_tree().get_nodes_in_group("")
		for node in get_tree().root.get_children():
			var found = _find_node_of_type(node, "WorldEnvironment")
			if found:
				world_environment = found
				break

	if world_environment:
		environment = world_environment.environment

	# Find DirectionalLight3D (sun)
	sun = get_tree().get_first_node_in_group("sun")
	if not sun:
		for node in get_tree().root.get_children():
			var found = _find_node_of_type(node, "DirectionalLight3D")
			if found:
				sun = found
				break


func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found = _find_node_of_type(child, type_name)
		if found:
			return found
	return null


func _process(delta: float) -> void:
	if transition_progress < 1.0:
		transition_progress += delta / transition_duration
		transition_progress = min(transition_progress, 1.0)
		_lerp_preset(transition_progress)


func _on_time_advanced(new_period: TimeSystem.TimePeriod) -> void:
	if new_period in LIGHTING_PRESETS:
		target_preset = LIGHTING_PRESETS[new_period].duplicate()
		transition_progress = 0.0
		print("[VisualStyle] Transitioning to %s lighting" % TimeSystem.PERIOD_NAMES[new_period])


func _lerp_preset(t: float) -> void:
	if current_preset.is_empty() or target_preset.is_empty():
		return

	# Smooth easing
	var ease_t = _ease_in_out(t)

	# Update sun
	if sun:
		sun.light_color = current_preset.sun_color.lerp(target_preset.sun_color, ease_t)
		sun.light_energy = lerp(current_preset.sun_energy, target_preset.sun_energy, ease_t)
		var current_angle = current_preset.sun_angle
		var target_angle = target_preset.sun_angle
		sun.rotation_degrees.x = lerp(current_angle, target_angle, ease_t)

	# Update environment
	if environment:
		environment.ambient_light_color = current_preset.ambient_color.lerp(target_preset.ambient_color, ease_t)
		environment.ambient_light_energy = lerp(current_preset.ambient_energy, target_preset.ambient_energy, ease_t)

		# Fog
		if environment.fog_enabled:
			environment.fog_light_color = current_preset.fog_color.lerp(target_preset.fog_color, ease_t)
			environment.fog_density = lerp(current_preset.fog_density, target_preset.fog_density, ease_t)

		# Sky (if using ProceduralSkyMaterial)
		if environment.sky and environment.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat: ProceduralSkyMaterial = environment.sky.sky_material
			sky_mat.sky_top_color = current_preset.sky_top.lerp(target_preset.sky_top, ease_t)
			sky_mat.sky_horizon_color = current_preset.sky_horizon.lerp(target_preset.sky_horizon, ease_t)
			sky_mat.ground_horizon_color = current_preset.sky_horizon.lerp(target_preset.sky_horizon, ease_t)

	# Update current when done
	if t >= 1.0:
		current_preset = target_preset.duplicate()


func _apply_preset_immediate(preset: Dictionary) -> void:
	if sun:
		sun.light_color = preset.sun_color
		sun.light_energy = preset.sun_energy
		sun.rotation_degrees.x = preset.sun_angle

	if environment:
		environment.ambient_light_color = preset.ambient_color
		environment.ambient_light_energy = preset.ambient_energy

		if environment.fog_enabled:
			environment.fog_light_color = preset.fog_color
			environment.fog_density = preset.fog_density

		if environment.sky and environment.sky.sky_material is ProceduralSkyMaterial:
			var sky_mat: ProceduralSkyMaterial = environment.sky.sky_material
			sky_mat.sky_top_color = preset.sky_top
			sky_mat.sky_horizon_color = preset.sky_horizon
			sky_mat.ground_horizon_color = preset.sky_horizon


func _ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


## Force update lighting for current time period
func refresh_lighting() -> void:
	_find_environment_nodes()
	_initialize_lighting()
