class_name RoomBuilder
extends Node2D

var current_room_node: Node2D = null
var interact_zones: Array = []


func build_room(room_id: StringName, entry_tag: StringName) -> Dictionary:
	if is_instance_valid(current_room_node):
		current_room_node.queue_free()
	interact_zones.clear()

	var root := Node2D.new()
	root.name = String(room_id)
	add_child(root)
	current_room_node = root

	match room_id:
		&"room_sanctuary":
			return _build_sanctuary(root, entry_tag)
		&"room_bastion":
			return _build_bastion(root, entry_tag)
		&"room_spire":
			return _build_spire(root, entry_tag)
	return _build_sanctuary(root, entry_tag)


func _build_sanctuary(root: Node2D, entry_tag: StringName) -> Dictionary:
	var bounds := Rect2(0, 0, 960, 420)
	_add_bg(root, bounds, Color(0.08, 0.09, 0.14), Color(0.14, 0.17, 0.26))
	_add_perimeter(root, bounds)

	# Main sanctuary floor & training ledges
	_add_solid(root, Rect2(0, 340, 960, 80))
	_add_solid(root, Rect2(90, 220, 150, 18))
	_add_solid(root, Rect2(640, 230, 170, 18))
	# Background Wall-Run practice panel
	_add_wallrun_panel(root, Rect2(380, 110, 150, 150))
	_add_solid(root, Rect2(390, 110, 130, 16))

	# Prep Shrine
	_add_sprite(root, "res://assets/sprites/world/shrine.png", Vector2(280, 308))
	var shrine := _add_interact(root, Vector2(280, 316), Vector2(44, 56), &"shrine", "[F] Open Prep Shrine (Loadout / Upgrade)")
	shrine.set_meta("prompt", "[F] Open Prep Shrine (Edit 2 Weapons, EQ & Items)")

	# Stage Gate (Right) -> locks Kit on entry
	_add_sprite(root, "res://assets/sprites/world/gate.png", Vector2(890, 300))
	var gate := _add_interact(root, Vector2(890, 304), Vector2(44, 72), &"gate", "[F] Enter Sunken Bastion (LOCKS KIT)")
	gate.target_room = &"room_bastion"
	gate.target_entry = &"from_sanctuary"

	# Left Shortcut Return Pad (from Astral Spire)
	_add_label(root, Vector2(60, 195), "SPIRE SHORTCUT LANDING", Color(0.45, 0.92, 1.0))
	_add_label(root, Vector2(215, 255), "PREP SHRINE\n[F] EDIT KIT", Color(0.55, 0.95, 1.0))
	_add_label(root, Vector2(490, 260), "TRAINING DUMMY\nTEST COMBOS & INFUSION", Color(0.95, 0.85, 0.55))
	_add_label(root, Vector2(780, 240), "STAGE GATE ->\nLOCKS DEPLOYMENT KIT", Color(0.95, 0.55, 0.95))

	# Training Dummy
	_spawn_enemy(root, &"training_dummy", Vector2(540, 340))

	var spawn := Vector2(180, 340)
	if entry_tag == &"from_bastion":
		spawn = Vector2(835, 340)
	elif entry_tag == &"from_shortcut":
		spawn = Vector2(150, 220)
	return {"spawn_pos": spawn, "bounds": bounds, "in_prep": true, "title": "Sanctuary Hub (Prep Zone)"}


func _build_bastion(root: Node2D, entry_tag: StringName) -> Dictionary:
	var bounds := Rect2(0, 0, 1440, 540)
	_add_bg(root, bounds, Color(0.11, 0.08, 0.11), Color(0.22, 0.14, 0.18))
	_add_perimeter(root, bounds)

	_add_solid(root, Rect2(0, 460, 1440, 80))
	_add_solid(root, Rect2(220, 340, 220, 18))
	_add_solid(root, Rect2(560, 250, 280, 18))
	_add_solid(root, Rect2(1020, 240, 420, 18))
	# Central Wall-Run Shaft bridging courtyard -> upper rampart
	_add_wallrun_panel(root, Rect2(440, 150, 140, 210))
	_add_wallrun_panel(root, Rect2(840, 130, 180, 170))

	# Left Gate back to Sanctuary
	_add_sprite(root, "res://assets/sprites/world/gate.png", Vector2(56, 420))
	var back_gate := _add_interact(root, Vector2(60, 424), Vector2(44, 72), &"gate", "[F] Return to Sanctuary (Unlock Kit)")
	back_gate.target_room = &"room_sanctuary"
	back_gate.target_entry = &"from_bastion"

	# Right Gate to Astral Spire
	_add_sprite(root, "res://assets/sprites/world/gate.png", Vector2(1380, 200))
	var next_gate := _add_interact(root, Vector2(1380, 204), Vector2(44, 72), &"gate", "[F] Enter Astral Spire")
	next_gate.target_room = &"room_spire"
	next_gate.target_entry = &"from_bastion"

	_add_label(root, Vector2(445, 128), "WALL-RUN SHAFT (HOLD W/A/D ON RUNES)", Color(0.55, 0.92, 1.0))

	# Roster tailored to Bastion Intel: Armored Sentinel, Barrier Wraith, Agile Duelist
	_spawn_enemy(root, &"armored_sentinel", Vector2(480, 460))
	_spawn_enemy(root, &"barrier_wraith", Vector2(700, 250))
	_spawn_enemy(root, &"agile_duelist", Vector2(1050, 460))

	var spawn := Vector2(120, 460)
	if entry_tag == &"from_spire":
		spawn = Vector2(1310, 240)
	return {"spawn_pos": spawn, "bounds": bounds, "in_prep": false, "title": "Sunken Bastion (Stage Locked)"}


func _build_spire(root: Node2D, entry_tag: StringName) -> Dictionary:
	var bounds := Rect2(0, 0, 1280, 680)
	_add_bg(root, bounds, Color(0.06, 0.08, 0.15), Color(0.12, 0.18, 0.30))
	_add_perimeter(root, bounds)

	_add_solid(root, Rect2(0, 600, 1280, 80))
	_add_solid(root, Rect2(300, 470, 260, 18))
	_add_solid(root, Rect2(760, 390, 280, 18))
	_add_solid(root, Rect2(420, 270, 280, 18))
	_add_solid(root, Rect2(0, 200, 290, 18))

	# Vertical Wall-Run Panels ascending the tower
	_add_wallrun_panel(root, Rect2(580, 290, 160, 220))
	_add_wallrun_panel(root, Rect2(260, 120, 180, 200))

	# Bottom-left Door back to Sunken Bastion
	_add_sprite(root, "res://assets/sprites/world/gate.png", Vector2(56, 560))
	var back_gate := _add_interact(root, Vector2(60, 564), Vector2(44, 72), &"gate", "[F] Return to Sunken Bastion")
	back_gate.target_room = &"room_bastion"
	back_gate.target_entry = &"from_spire"

	# Top-left Shortcut Lever & Gate -> direct loop back to Sanctuary!
	_add_sprite(root, "res://assets/sprites/world/shrine.png", Vector2(110, 168))
	var shortcut := _add_interact(root, Vector2(110, 174), Vector2(52, 56), &"shortcut", "[F] Pull Shortcut Lever -> Sanctuary")
	shortcut.target_room = &"room_sanctuary"
	shortcut.target_entry = &"from_shortcut"

	_add_label(root, Vector2(45, 128), "METROIDVANIA LOOP SHORTCUT -> SANCTUARY", Color(0.55, 1.0, 0.72))

	# Roster tailored to Astral Spire Intel: Sky Hawker, Blink Stalker, Astral Phantom
	_spawn_enemy(root, &"sky_hawker", Vector2(540, 380))
	_spawn_enemy(root, &"blink_stalker", Vector2(920, 600))
	_spawn_enemy(root, &"astral_phantom", Vector2(560, 195))

	var spawn := Vector2(120, 600)
	var _unused := entry_tag
	return {"spawn_pos": spawn, "bounds": bounds, "in_prep": false, "title": "Astral Spire (Stage Locked)"}


func _add_bg(root: Node2D, bounds: Rect2, c_top: Color, c_bot: Color) -> void:
	var bg := Polygon2D.new()
	bg.z_index = -30
	bg.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(bounds.size.x, 0),
		Vector2(bounds.size.x, bounds.size.y),
		Vector2(0, bounds.size.y),
	])
	bg.vertex_colors = PackedColorArray([c_top, c_top, c_bot, c_bot])
	root.add_child(bg)

	# Parallax background stone pillars for spatial speed sense
	for x in range(80, int(bounds.size.x), 180):
		var col := ColorRect.new()
		col.z_index = -20
		col.position = Vector2(x, 0)
		col.size = Vector2(36, bounds.size.y)
		col.color = Color(0.03, 0.04, 0.07, 0.45)
		root.add_child(col)


func _add_perimeter(root: Node2D, bounds: Rect2) -> void:
	_add_solid(root, Rect2(-24, 0, 24, bounds.size.y))
	_add_solid(root, Rect2(bounds.size.x, 0, 24, bounds.size.y))
	_add_solid(root, Rect2(0, -24, bounds.size.x, 24))


func _add_solid(root: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)

	var tile_path := "res://assets/sprites/world/tile_solid.png"
	if ResourceLoader.exists(tile_path):
		var tr := TextureRect.new()
		tr.texture = load(tile_path)
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.position = -rect.size * 0.5
		tr.size = rect.size
		body.add_child(tr)
	else:
		var cr := ColorRect.new()
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.position = -rect.size * 0.5
		cr.size = rect.size
		cr.color = Color(0.2, 0.22, 0.3)
		body.add_child(cr)

	root.add_child(body)


func _add_wallrun_panel(root: Node2D, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 32
	body.collision_mask = 0
	body.z_index = -5
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)

	var tile_path := "res://assets/sprites/world/tile_wallrun.png"
	if ResourceLoader.exists(tile_path):
		var tr := TextureRect.new()
		tr.texture = load(tile_path)
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(0.85, 0.95, 1.0, 0.8)
		tr.position = -rect.size * 0.5
		tr.size = rect.size
		body.add_child(tr)

	root.add_child(body)


func _add_sprite(root: Node2D, path: String, pos: Vector2) -> void:
	if not ResourceLoader.exists(path):
		return
	var sp := Sprite2D.new()
	sp.texture = load(path)
	sp.position = pos
	sp.z_index = -2
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sp)


func _add_interact(root: Node2D, pos: Vector2, size: Vector2, kind: StringName, prompt: String) -> InteractZone:
	var iz := InteractZone.new()
	iz.position = pos
	iz.kind = kind
	iz.set_prompt(prompt)
	var sh := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	sh.shape = box
	iz.add_child(sh)
	root.add_child(iz)
	interact_zones.append(iz)
	return iz


func _add_label(root: Node2D, pos: Vector2, txt: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.position = pos
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", col)
	lbl.z_index = -4
	root.add_child(lbl)


func _spawn_enemy(root: Node2D, archetype: StringName, pos: Vector2) -> EnemyBase:
	var e := EnemyBase.new()
	e.archetype_id = archetype
	e.position = pos
	root.add_child(e)
	return e
