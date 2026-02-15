extends CanvasLayer
## Card shop UI - browse and buy booster packs with opening animation.

signal shop_closed

const PACKS_PATH := "res://data/cards/packs.json"
const PACK_TEX_BASE := "res://assets/tagforce/ui/shop/en/pack_tex%02d.png"

var _packs: Array = []
var _current_index: int = 0
var _can_input: bool = false
var _is_opening: bool = false

@onready var content: Control = $Content
@onready var pack_display: TextureRect = $Content/PackDisplay
@onready var pack_name_label: Label = $Content/PackNameLabel
@onready var pack_price_label: Label = $Content/PackPriceLabel
@onready var dp_label: Label = $Content/DPLabel
@onready var hint_label: Label = $Content/HintLabel
@onready var left_arrow: Label = $Content/LeftArrow
@onready var right_arrow: Label = $Content/RightArrow
@onready var open_overlay: ColorRect = $Content/OpenOverlay
@onready var open_card_display: Control = $Content/OpenOverlay/CardDisplay


func _ready() -> void:
	_load_packs()
	open_overlay.visible = false
	_update_display()

	# Fade in via Content wrapper (CanvasLayer has no modulate)
	content.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 0.3)
	await tween.finished
	_can_input = true


func _load_packs() -> void:
	if not FileAccess.file_exists(PACKS_PATH):
		return
	var file := FileAccess.open(PACKS_PATH, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Array:
		_packs = json.data
	file.close()


func _update_display() -> void:
	if _packs.is_empty():
		return

	var pack: Dictionary = _packs[_current_index]

	# Load pack cover texture
	var tex_path := PACK_TEX_BASE % pack.get("id", _current_index)
	if ResourceLoader.exists(tex_path):
		pack_display.texture = load(tex_path)

	# Update labels
	pack_name_label.text = pack.get("name", "Unknown Pack")

	var price: int = pack.get("price", 100)
	pack_price_label.text = "%d DP" % price

	var dp: int = GameManager.game_data.get("dp", 0)
	dp_label.text = "Your DP: %d" % dp

	# Color price red if can't afford
	if dp < price:
		pack_price_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		pack_price_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

	# Show pack index
	hint_label.text = "%d / %d    [Z] Buy  [X] Exit" % [_current_index + 1, _packs.size()]

	# Arrow visibility
	left_arrow.visible = _current_index > 0
	right_arrow.visible = _current_index < _packs.size() - 1


func _input(event: InputEvent) -> void:
	if not _can_input:
		return

	if _is_opening:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_close_opening()
		return

	if event.is_action_pressed("ui_right"):
		if _current_index < _packs.size() - 1:
			_current_index += 1
			_update_display()
	elif event.is_action_pressed("ui_left"):
		if _current_index > 0:
			_current_index -= 1
			_update_display()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_try_buy()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_X):
		_close_shop()


func _try_buy() -> void:
	if _packs.is_empty():
		return

	var pack: Dictionary = _packs[_current_index]
	var price: int = pack.get("price", 100)
	var dp: int = GameManager.game_data.get("dp", 0)

	if dp < price:
		# Flash price red
		var tween := create_tween()
		tween.tween_property(pack_price_label, "modulate", Color.RED, 0.1)
		tween.tween_property(pack_price_label, "modulate", Color.WHITE, 0.1)
		return

	# Deduct DP
	GameManager.game_data["dp"] = dp - price
	_update_display()

	# Open pack animation
	_can_input = false
	await _play_opening(pack)
	_can_input = true


func _play_opening(pack: Dictionary) -> void:
	_is_opening = true

	# Flash white
	open_overlay.visible = true
	open_overlay.color = Color.WHITE

	var tween := create_tween()
	tween.tween_property(open_overlay, "color", Color(0.05, 0.05, 0.1, 0.95), 0.4)
	await tween.finished

	# Generate 5 random "cards" and display them
	var cards := _generate_cards(pack, 5)
	_show_cards(cards)


func _generate_cards(pack: Dictionary, count: int) -> Array:
	var rarity_level: int = pack.get("rarity", 1)
	var cards := []

	# Card name pools by type
	var monsters := [
		"Dark Magician", "Blue-Eyes White Dragon", "Red-Eyes B. Dragon",
		"Elemental HERO Neos", "Elemental HERO Avian", "Elemental HERO Burstinatrix",
		"Elemental HERO Sparkman", "Elemental HERO Clayman", "Cyber Dragon",
		"Armed Dragon LV5", "Ojama Yellow", "Ojama Green", "Ojama Black",
		"Crystal Beast Ruby Carbuncle", "Winged Kuriboh", "Neo-Spacian Grand Mole",
		"Yubel", "Rainbow Dragon", "Ancient Gear Golem", "Destiny HERO - Diamond Dude",
		"Uria, Lord of Searing Flames", "Hamon, Lord of Striking Thunder",
		"Raviel, Lord of Phantasms", "Stardust Dragon", "Junk Warrior",
	]
	var spells := [
		"Polymerization", "Monster Reborn", "Pot of Greed", "Graceful Charity",
		"Heavy Storm", "Mystical Space Typhoon", "Swords of Revealing Light",
		"Dark Hole", "Change of Heart", "Premature Burial", "Snatch Steal",
		"Future Fusion", "Power Bond", "Miracle Fusion", "Skyscraper",
	]
	var traps := [
		"Mirror Force", "Magic Cylinder", "Negate Attack", "Sakuretsu Armor",
		"Torrential Tribute", "Bottomless Trap Hole", "Hero Signal",
		"Ring of Destruction", "Call of the Haunted", "Solemn Judgment",
	]

	for i in count:
		var card := {}
		var roll := randi() % 100

		# Higher rarity packs have better odds
		var rare_threshold := 70 - (rarity_level * 8)
		var super_threshold := 90 - (rarity_level * 4)

		if roll < 50:
			card["name"] = monsters[randi() % monsters.size()]
			card["type"] = "monster"
		elif roll < 80:
			card["name"] = spells[randi() % spells.size()]
			card["type"] = "spell"
		else:
			card["name"] = traps[randi() % traps.size()]
			card["type"] = "trap"

		# Last card in pack has higher rarity
		if i == count - 1:
			rare_threshold -= 30

		var rarity_roll := randi() % 100
		if rarity_roll < rare_threshold:
			card["rarity"] = "Common"
			card["rarity_color"] = Color(0.7, 0.7, 0.7)
		elif rarity_roll < super_threshold:
			card["rarity"] = "Rare"
			card["rarity_color"] = Color(0.3, 0.6, 1.0)
		elif rarity_roll < 95:
			card["rarity"] = "Super Rare"
			card["rarity_color"] = Color(1.0, 0.85, 0.2)
		else:
			card["rarity"] = "Ultra Rare"
			card["rarity_color"] = Color(1.0, 0.3, 0.8)

		cards.append(card)

	return cards


func _show_cards(cards: Array) -> void:
	# Clear previous cards
	for child in open_card_display.get_children():
		child.queue_free()

	# Create card display nodes
	var card_width := 175
	var card_height := 250
	var spacing := 30
	var total_width := cards.size() * card_width + (cards.size() - 1) * spacing
	var start_x := (1195 - total_width) / 2.0
	var card_y := 100.0

	for i in cards.size():
		var card: Dictionary = cards[i]
		var card_node := _create_card_visual(card, card_width, card_height)
		card_node.position = Vector2(start_x + i * (card_width + spacing), card_y)

		# Animate cards appearing one by one
		card_node.modulate.a = 0.0
		card_node.scale = Vector2(0.5, 0.5)
		open_card_display.add_child(card_node)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(card_node, "modulate:a", 1.0, 0.2).set_delay(i * 0.15)
		tween.tween_property(card_node, "scale", Vector2.ONE, 0.3).set_delay(i * 0.15).set_trans(Tween.TRANS_BACK)

		if i == cards.size() - 1:
			await tween.finished

	# Show "press button to continue"
	var continue_label := Label.new()
	continue_label.text = "Press [Z] to continue"
	continue_label.position = Vector2(375, 425)
	continue_label.add_theme_font_size_override("font_size", 25)
	continue_label.modulate = Color(0.7, 0.7, 0.8, 0.8)
	open_card_display.add_child(continue_label)

	# Blink the continue label
	var blink := create_tween().set_loops()
	blink.tween_property(continue_label, "modulate:a", 0.3, 0.5)
	blink.tween_property(continue_label, "modulate:a", 0.8, 0.5)


func _create_card_visual(card: Dictionary, w: int, h: int) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(w, h)

	# Card background
	var bg_rect := ColorRect.new()
	bg_rect.size = Vector2(w, h)
	bg_rect.color = _get_card_bg_color(card.get("type", "monster"))
	container.add_child(bg_rect)

	# Card border
	var border := ColorRect.new()
	border.size = Vector2(w, h)
	border.color = card.get("rarity_color", Color.WHITE)
	border.modulate.a = 0.6
	container.add_child(border)

	# Inner fill (slightly smaller)
	var inner := ColorRect.new()
	inner.position = Vector2(2, 2)
	inner.size = Vector2(w - 4, h - 4)
	inner.color = _get_card_bg_color(card.get("type", "monster"))
	container.add_child(inner)

	# Card art placeholder (darker area)
	var art := ColorRect.new()
	art.position = Vector2(8, 45)
	art.size = Vector2(w - 16, h - 100)
	art.color = _get_card_bg_color(card.get("type", "monster")).darkened(0.3)
	container.add_child(art)

	# Type icon indicator
	var type_label := Label.new()
	type_label.position = Vector2(10, 8)
	type_label.add_theme_font_size_override("font_size", 17)
	match card.get("type", "monster"):
		"monster":
			type_label.text = "MONSTER"
			type_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		"spell":
			type_label.text = "SPELL"
			type_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
		"trap":
			type_label.text = "TRAP"
			type_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.5))
	container.add_child(type_label)

	# Card name
	var name_label := Label.new()
	name_label.position = Vector2(10, h - 55)
	name_label.size = Vector2(w - 20, 50)
	name_label.text = card.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.clip_text = true
	container.add_child(name_label)

	# Rarity indicator
	var rarity_label := Label.new()
	rarity_label.position = Vector2(10, h - 30)
	rarity_label.add_theme_font_size_override("font_size", 15)
	rarity_label.text = card.get("rarity", "Common")
	rarity_label.add_theme_color_override("font_color", card.get("rarity_color", Color.WHITE))
	container.add_child(rarity_label)

	# Rarity glow effect for rare+ cards
	if card.get("rarity", "Common") != "Common":
		var glow := ColorRect.new()
		glow.size = Vector2(w, h)
		glow.color = card.get("rarity_color", Color.WHITE)
		glow.modulate.a = 0.15
		container.add_child(glow)

	return container


func _get_card_bg_color(type: String) -> Color:
	match type:
		"monster":
			return Color(0.6, 0.45, 0.2)  # Brown/tan (normal monster)
		"spell":
			return Color(0.15, 0.4, 0.35)  # Teal (spell)
		"trap":
			return Color(0.45, 0.15, 0.25)  # Magenta (trap)
		_:
			return Color(0.3, 0.3, 0.3)


func _close_opening() -> void:
	_is_opening = false
	var tween := create_tween()
	tween.tween_property(open_overlay, "color:a", 0.0, 0.3)
	await tween.finished
	open_overlay.visible = false

	# Clear card display
	for child in open_card_display.get_children():
		child.queue_free()

	_update_display()


func _close_shop() -> void:
	_can_input = false
	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 0.0, 0.3)
	await tween.finished
	shop_closed.emit()
	queue_free()
