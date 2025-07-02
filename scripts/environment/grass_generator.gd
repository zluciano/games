@tool
class_name GrassGenerator
extends MultiMeshInstance3D

## Generates dense anime-style grass using GPU instancing

@export_category("Grass Area")
@export var area_size: Vector2 = Vector2(60, 50)
@export var grass_density: float = 8.0  # Blades per square unit

@export_category("Grass Appearance")
@export var blade_height: float = 0.5
@export var blade_height_variation: float = 0.3
@export var blade_width: float = 0.04
@export var blade_segments: int = 3

@export_category("Distribution")
@export var exclude_radius: float = 5.0  # Area around center to exclude
@export var path_width: float = 8.0  # Width of main path to exclude
@export var random_seed: int = 12345

@export_category("Material")
@export var grass_material: ShaderMaterial

@export_category("Generation")
@export var regenerate: bool = false:
	set(value):
		if value:
			generate_grass()
		regenerate = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_grass()

func generate_grass() -> void:
	# Create grass blade mesh
	var blade_mesh = _create_blade_mesh()

	# Calculate instance count
	var total_area = area_size.x * area_size.y
	var instance_count = int(total_area * grass_density)

	# Create multimesh
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade_mesh
	mm.instance_count = instance_count

	# Load grass material
	if not grass_material:
		grass_material = load("res://materials/grass_blades_material.tres")

	if grass_material:
		blade_mesh.surface_set_material(0, grass_material)

	# Generate positions
	var rng = RandomNumberGenerator.new()
	rng.seed = random_seed

	var valid_count = 0
	var half_size = area_size / 2.0

	for i in range(instance_count * 2):  # Generate extra to account for exclusions
		if valid_count >= instance_count:
			break

		var x = rng.randf_range(-half_size.x, half_size.x)
		var z = rng.randf_range(-half_size.y, half_size.y)

		# Skip if in excluded areas
		if _is_excluded(x, z):
			continue

		# Random rotation and scale
		var rotation = rng.randf() * TAU
		var scale_var = 0.7 + rng.randf() * 0.6

		var transform = Transform3D()
		transform = transform.rotated(Vector3.UP, rotation)
		transform = transform.scaled(Vector3(scale_var, scale_var, scale_var))
		transform.origin = Vector3(x, 0, z)

		mm.set_instance_transform(valid_count, transform)
		valid_count += 1

	# Trim unused instances
	mm.instance_count = valid_count

	multimesh = mm
	print("[GrassGenerator] Generated %d grass blades" % valid_count)

func _is_excluded(x: float, z: float) -> bool:
	# Exclude center fountain area
	var dist_from_center = sqrt(x * x + z * z)
	if dist_from_center < exclude_radius:
		return true

	# Exclude main path (along Z axis from spawn to academy)
	if abs(x) < path_width / 2.0 and z > -10 and z < 55:
		return true

	# Exclude building area
	if z < -2 and abs(x) < 25:
		return true

	# Exclude near hedges
	if abs(x) > 15 and abs(x) < 22:
		return true

	return false

func _create_blade_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var segment_height = blade_height / blade_segments

	# Create blade geometry (tapered quad strip)
	for i in range(blade_segments + 1):
		var t = float(i) / blade_segments
		var y = t * blade_height
		var width = blade_width * (1.0 - t * 0.7)  # Taper towards tip

		# Left vertex
		vertices.append(Vector3(-width / 2, y, 0))
		normals.append(Vector3(0, 0, 1))
		uvs.append(Vector2(0, t))

		# Right vertex
		vertices.append(Vector3(width / 2, y, 0))
		normals.append(Vector3(0, 0, 1))
		uvs.append(Vector2(1, t))

	# Create triangles
	for i in range(blade_segments):
		var base = i * 2
		# First triangle
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		# Second triangle
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh
