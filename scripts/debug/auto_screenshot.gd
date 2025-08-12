extends Node

func _ready():
	# Wait for scene to fully render
	await get_tree().create_timer(2.0).timeout

	# Take screenshot
	var image = get_viewport().get_texture().get_image()
	var path = "/tmp/godot_internal_screenshot.png"
	var err = image.save_png(path)
	if err == OK:
		print("[AutoScreenshot] Saved to: " + path)
	else:
		print("[AutoScreenshot] Failed to save, error: " + str(err))

	# Quit after screenshot
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
