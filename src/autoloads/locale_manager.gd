extends Node
## Manages language switching for localized asset paths.

signal locale_changed(new_locale: String)

const SUPPORTED_LOCALES := ["en", "fr", "de", "it", "es"]

var current_locale: String = "en"


func set_locale(locale: String) -> void:
	if locale not in SUPPORTED_LOCALES:
		push_warning("Unsupported locale: %s" % locale)
		return
	current_locale = locale
	locale_changed.emit(locale)


func get_localized_path(base_path: String) -> String:
	return base_path.replace("{lang}", current_locale)


func get_ui_texture(category: String, filename: String) -> Texture2D:
	var path := "res://assets/tagforce/ui/%s/%s/%s" % [category, current_locale, filename]
	if ResourceLoader.exists(path):
		return load(path)
	# Fallback to English
	path = "res://assets/tagforce/ui/%s/en/%s" % [category, filename]
	if ResourceLoader.exists(path):
		return load(path)
	# Try non-localized
	path = "res://assets/tagforce/ui/%s/%s" % [category, filename]
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Texture not found: %s/%s" % [category, filename])
	return null
