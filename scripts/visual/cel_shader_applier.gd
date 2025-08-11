extends Node
## Carefully applies cel shading only to primitive meshes, not imported assets

@export var apply_to_children: bool = true
@export var add_outlines: bool = true

var cel_material: ShaderMaterial
var outline_material: ShaderMaterial

# Paths/names to skip (imported assets that already look good)
var skip_patterns: Array[String] = [
	"glTF", "gltf", "glb", "GLB",
	"Tree", "Bush", "Flower", "Grass",
	"kenney", "Kenney",
	"fountain", "Fountain",
	"hedge", "Hedge",
	"bench", "Bench",
	"academy", "Academy"
]

func _ready() -> void:
	cel_material = preload("res://materials/cel_white.tres")
	outline_material = preload("res://materials/cel_outline.tres")

	if apply_to_children:
		call_deferred("_apply_to_all_meshes")

func _apply_to_all_meshes() -> void:
	_process_node(get_parent())

func _process_node(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_cel_shader(node)

	for child in node.get_children():
		_process_node(child)

func _should_skip(mesh_instance: MeshInstance3D) -> bool:
	# Check node name and parent names for skip patterns
	var check_node: Node = mesh_instance
	while check_node != null:
		var node_name := check_node.name.to_lower()
		for pattern in skip_patterns:
			if pattern.to_lower() in node_name:
				return true

		# Check if this is an instanced scene from an imported file
		if check_node.scene_file_path != "":
			var path := check_node.scene_file_path.to_lower()
			if ".glb" in path or ".gltf" in path:
				return true

		check_node = check_node.get_parent()

	return false

func _apply_cel_shader(mesh_instance: MeshInstance3D) -> void:
	# Skip imported assets
	if _should_skip(mesh_instance):
		return

	# Skip if already has a shader material override
	if mesh_instance.material_override is ShaderMaterial:
		return

	# Get the current material
	var current_mat = mesh_instance.get_surface_override_material(0)
	if current_mat == null and mesh_instance.mesh:
		if mesh_instance.mesh.get_surface_count() > 0:
			current_mat = mesh_instance.mesh.surface_get_material(0)

	# Only process StandardMaterial3D without textures
	if not current_mat is StandardMaterial3D:
		return

	var std_mat := current_mat as StandardMaterial3D

	# Skip if it has an albedo texture (likely a proper textured material)
	if std_mat.albedo_texture != null:
		return

	# Extract the base color
	var base_color := std_mat.albedo_color

	# Create new cel material with the extracted color
	var new_mat := cel_material.duplicate() as ShaderMaterial
	new_mat.set_shader_parameter("color", base_color)

	# Adjust specular based on material properties
	var spec_color := Color(0.3, 0.3, 0.3, std_mat.metallic * 0.5 + 0.1)
	new_mat.set_shader_parameter("specular", spec_color)

	# Apply the material
	mesh_instance.material_override = new_mat

	# Add outline pass if enabled
	if add_outlines:
		new_mat.next_pass = outline_material
