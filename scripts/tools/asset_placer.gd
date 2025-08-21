@tool
extends Node3D
class_name AssetPlacer

## Utility for placing downloaded .glb models in scenes
## Place .glb files in res://assets/models/ and use this to position them

@export var model_path: String = ""
@export var apply_toon_material: bool = true
@export var toon_material: Material
@export var add_collision: bool = false
@export_range(0.1, 10.0) var scale_factor: float = 1.0

var _loaded_model: Node3D

func _ready() -> void:
	if model_path != "":
		load_model(model_path)

func load_model(path: String) -> void:
	if _loaded_model:
		_loaded_model.queue_free()

	if not ResourceLoader.exists(path):
		push_error("AssetPlacer: Model not found at " + path)
		return

	var scene = load(path)
	if scene is PackedScene:
		_loaded_model = scene.instantiate()
	elif scene is Mesh:
		_loaded_model = MeshInstance3D.new()
		(_loaded_model as MeshInstance3D).mesh = scene
	else:
		push_error("AssetPlacer: Unsupported resource type")
		return

	add_child(_loaded_model)
	_loaded_model.scale = Vector3.ONE * scale_factor

	if apply_toon_material and toon_material:
		_apply_material_recursive(_loaded_model, toon_material)

	if add_collision:
		_add_collision_recursive(_loaded_model)

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in range(mesh_instance.get_surface_override_material_count()):
			mesh_instance.set_surface_override_material(i, mat)

	for child in node.get_children():
		_apply_material_recursive(child, mat)

func _add_collision_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.create_trimesh_collision()

	for child in node.get_children():
		_add_collision_recursive(child)


## Static helper to batch-place models
static func place_models_at_positions(parent: Node3D, model_path: String, positions: Array[Vector3], material: Material = null) -> Array[Node3D]:
	var instances: Array[Node3D] = []

	if not ResourceLoader.exists(model_path):
		push_error("AssetPlacer: Model not found at " + model_path)
		return instances

	var scene = load(model_path)

	for pos in positions:
		var instance: Node3D
		if scene is PackedScene:
			instance = scene.instantiate()
		else:
			continue

		parent.add_child(instance)
		instance.global_position = pos

		if material:
			_apply_material_to_node(instance, material)

		instances.append(instance)

	return instances

static func _apply_material_to_node(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for i in range(mesh_instance.get_surface_override_material_count()):
			mesh_instance.set_surface_override_material(i, mat)

	for child in node.get_children():
		_apply_material_to_node(child, mat)
