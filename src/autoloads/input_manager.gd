extends Node
## Maps input to actions, provides button prompt textures.

const PROMPT_BASE := "res://assets/tagforce/ui/input/"

# Map action names to input prompt texture filenames
const PROMPT_MAP := {
	"ui_accept": "input0001.png",
	"ui_cancel": "input0002.png",
	"interact": "input0001.png",
	"ui_up": "input0003.png",
	"ui_down": "input0004.png",
	"ui_left": "input0005.png",
	"ui_right": "input0006.png",
}


func get_prompt_texture(action: String) -> Texture2D:
	var filename: String = PROMPT_MAP.get(action, "")
	if filename.is_empty():
		return null
	var path := PROMPT_BASE + filename
	if ResourceLoader.exists(path):
		return load(path)
	return null


func is_gamepad() -> bool:
	return Input.get_connected_joypads().size() > 0
