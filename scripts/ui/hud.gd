class_name GameHud
extends CanvasLayer

var hp_bar: ColorRect
var hp_label: Label
var flux_bar: ColorRect
var flux_label: Label
var slot1_label: Label
var slot2_label: Label
var elem_label: Label
var lock_label: Label
var room_label: Label
var combo_label: Label
var move_name_label: Label
var pouch_labels: Array = []
var prompt_label: Label
var toast_label: Label
var minimap_control: Control

var _toast_timer: float = 0.0
var _move_timer: float = 0.0
var _player_hp_ratio: float = 1.0
var _player_flux_ratio: float = 0.4


func _ready() -> void:
	layer = 10
	_build_ui()
	GameState.loadout_changed.connect(refresh_loadout)
	GameState.lock_state_changed.connect(_on_lock_changed)
	GameState.room_changed.connect(_on_room_changed)
	HitstopManager.toast_requested.connect(push_toast)
	refresh_loadout()


func _build_ui() -> void:
	# Top-Left Stats & Weapons
	var panel_tl := ColorRect.new()
	panel_tl.position = Vector2(8, 8)
	panel_tl.size = Vector2(215, 76)
	panel_tl.color = Color(0.05, 0.06, 0.10, 0.78)
	add_child(panel_tl)

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(14, 14)
	hp_bg.size = Vector2(120, 8)
	hp_bg.color = Color(0.16, 0.14, 0.20)
	add_child(hp_bg)

	hp_bar = ColorRect.new()
	hp_bar.position = Vector2(14, 14)
	hp_bar.size = Vector2(120, 8)
	hp_bar.color = Color(0.90, 0.26, 0.34)
	add_child(hp_bar)

	hp_label = _mk_label(Vector2(140, 11), "120/120", 8, Color.WHITE)
	add_child(hp_label)

	var fl_bg := ColorRect.new()
	fl_bg.position = Vector2(14, 25)
	fl_bg.size = Vector2(120, 6)
	fl_bg.color = Color(0.14, 0.16, 0.22)
	add_child(fl_bg)

	flux_bar = ColorRect.new()
	flux_bar.position = Vector2(14, 25)
	flux_bar.size = Vector2(48, 6)
	flux_bar.color = Color(0.32, 0.85, 1.0)
	add_child(flux_bar)

	flux_label = _mk_label(Vector2(140, 21), "FLUX 40", 8, Color(0.65, 0.92, 1.0))
	add_child(flux_label)

	slot1_label = _mk_label(Vector2(14, 36), "[1] Longsword Lv.2", 8, Color.WHITE)
	add_child(slot1_label)
	slot2_label = _mk_label(Vector2(14, 48), "[2] Wand Lv.2", 8, Color(0.75, 0.8, 0.9))
	add_child(slot2_label)
	elem_label = _mk_label(Vector2(14, 62), "ELEM [E]: FIRE | off: ICE", 8, Color(1.0, 0.55, 0.3))
	add_child(elem_label)

	# Top-Center Lock & Room Status
	var panel_tc := ColorRect.new()
	panel_tc.position = Vector2(236, 8)
	panel_tc.size = Vector2(178, 30)
	panel_tc.color = Color(0.05, 0.06, 0.10, 0.78)
	add_child(panel_tc)

	room_label = _mk_label(Vector2(242, 10), "Sanctuary Hub", 8, Color(0.88, 0.92, 1.0))
	add_child(room_label)
	lock_label = _mk_label(Vector2(242, 22), "[PREP ZONE - KIT EDITABLE]", 8, Color(0.45, 0.95, 0.72))
	add_child(lock_label)

	# Top-Right Minimap & Style Combo
	var panel_tr := ColorRect.new()
	panel_tr.position = Vector2(506, 8)
	panel_tr.size = Vector2(126, 76)
	panel_tr.color = Color(0.05, 0.06, 0.10, 0.78)
	add_child(panel_tr)

	minimap_control = MinimapWidget.new()
	minimap_control.position = Vector2(516, 12)
	minimap_control.size = Vector2(106, 34)
	add_child(minimap_control)

	combo_label = _mk_label(Vector2(512, 48), "RANK D | 0 HIT", 9, Color(1.0, 0.88, 0.42))
	add_child(combo_label)

	move_name_label = _mk_label(Vector2(512, 62), "", 8, Color(0.55, 0.94, 1.0))
	move_name_label.size = Vector2(118, 16)
	add_child(move_name_label)

	# Bottom-Left 4-Slot Item Pouch
	var pouch_bg := ColorRect.new()
	pouch_bg.position = Vector2(8, 326)
	pouch_bg.size = Vector2(316, 26)
	pouch_bg.color = Color(0.05, 0.06, 0.10, 0.80)
	add_child(pouch_bg)

	for i in range(4):
		var lbl := _mk_label(Vector2(14 + i * 78, 333), "[%d] Item" % (i + 1), 8, Color(0.88, 0.92, 0.98))
		add_child(lbl)
		pouch_labels.append(lbl)

	# Bottom-Right Interact & Controls Hint
	var ctrl_bg := ColorRect.new()
	ctrl_bg.position = Vector2(334, 326)
	ctrl_bg.size = Vector2(298, 26)
	ctrl_bg.color = Color(0.05, 0.06, 0.10, 0.80)
	add_child(ctrl_bg)

	var ctrl := _mk_label(Vector2(340, 333), "J:Atk K:Hvy U:Art Q:Swap E:Elem L:Dash C:Vault I:Parry", 8, Color(0.75, 0.82, 0.92))
	add_child(ctrl)

	prompt_label = _mk_label(Vector2(170, 294), "", 9, Color(0.55, 1.0, 0.82))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size = Vector2(300, 18)
	add_child(prompt_label)

	toast_label = _mk_label(Vector2(120, 48), "", 9, Color(1.0, 0.9, 0.35))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.size = Vector2(400, 20)
	add_child(toast_label)


func _mk_label(pos: Vector2, txt: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_label.text = ""
	if _move_timer > 0.0:
		_move_timer -= delta
		if _move_timer <= 0.0:
			move_name_label.text = ""


func show_move_name(mname: String) -> void:
	move_name_label.text = mname
	_move_timer = 1.6


func update_health(hp: float, max_hp: float) -> void:
	_player_hp_ratio = clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	hp_bar.size.x = 120.0 * _player_hp_ratio
	hp_label.text = "%d/%d" % [int(round(hp)), int(round(max_hp))]


func update_flux(flux: float, max_flux: float) -> void:
	_player_flux_ratio = clampf(flux / maxf(max_flux, 1.0), 0.0, 1.0)
	flux_bar.size.x = 120.0 * _player_flux_ratio
	flux_label.text = "FLUX %d" % int(round(flux))


func update_combo(combo: int, rank: String) -> void:
	combo_label.text = "RANK %s | %d HIT" % [rank, combo]


func set_interact_prompt(prompt: String) -> void:
	prompt_label.text = prompt


func set_room_title(title: String) -> void:
	room_label.text = title


func push_toast(message: String, color: Color = Color.WHITE) -> void:
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", color)
	_toast_timer = 3.2


func refresh_loadout() -> void:
	var kit := GameState.deployment_kit
	var w0 := WeaponRegistry.get_weapon(StringName(kit["weapons"][0]))
	var w1 := WeaponRegistry.get_weapon(StringName(kit["weapons"][1]))
	var lv0 := GameState.get_weapon_level(w0.id)
	var lv1 := GameState.get_weapon_level(w1.id)
	var dual := GameState.is_dual_katana_active()

	var tag0 := ">> " if GameState.active_weapon_slot == 0 else "   "
	var tag1 := ">> " if GameState.active_weapon_slot == 1 else "   "
	slot1_label.text = "%s%s Lv.%d" % [tag0, w0.display_name, lv0]
	slot2_label.text = "%s%s Lv.%d%s" % [tag1, w1.display_name, lv1, " [DUAL]" if dual else ""]
	slot1_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45) if GameState.active_weapon_slot == 0 else Color(0.75, 0.80, 0.90))
	slot2_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45) if GameState.active_weapon_slot == 1 else Color(0.75, 0.80, 0.90))

	var e_act := ElementRegistry.get_element(GameState.get_active_element_id())
	var e_off := ElementRegistry.get_element(GameState.get_off_element_id())
	elem_label.text = "ELEM [E]: %s | Sub: %s" % [String(e_act["name"]).to_upper(), String(e_off["short"])]
	elem_label.add_theme_color_override("font_color", e_act["color"])

	var pouch: Array = kit["item_pouch"]
	for i in range(4):
		var item_entry: Dictionary = pouch[i]
		var short_name := String(item_entry["id"]).split("_")[-1].capitalize()
		(pouch_labels[i] as Label).text = "[%d]%s x%d" % [i + 1, short_name, int(item_entry["count"])]

	if is_instance_valid(minimap_control):
		minimap_control.queue_redraw()


func _on_lock_changed(locked: bool) -> void:
	if locked:
		lock_label.text = "[LOCKED IN STAGE]"
		lock_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35))
	else:
		lock_label.text = "[PREP ZONE - KIT EDITABLE]"
		lock_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.72))


func _on_room_changed(_room_id: StringName) -> void:
	if is_instance_valid(minimap_control):
		minimap_control.queue_redraw()


class MinimapWidget extends Control:
	func _draw() -> void:
		var visited: Dictionary = GameState.stash.get("visited_rooms", {})
		var shortcuts: Dictionary = GameState.stash.get("unlocked_shortcuts", {})
		var cur := GameState.current_room_id

		var r1 := Rect2(4, 14, 28, 16)
		var r2 := Rect2(38, 14, 30, 16)
		var r3 := Rect2(74, 2, 26, 28)

		draw_line(Vector2(32, 22), Vector2(38, 22), Color(0.6, 0.7, 0.85), 2.0)
		draw_line(Vector2(68, 20), Vector2(74, 20), Color(0.6, 0.7, 0.85), 2.0)
		if bool(shortcuts.get("spire_to_sanctuary", false)):
			draw_line(Vector2(18, 14), Vector2(86, 2), Color(0.45, 1.0, 0.7), 1.5)

		_draw_room_box(r1, &"room_sanctuary", cur, visited, Color(0.35, 0.85, 0.75))
		_draw_room_box(r2, &"room_bastion", cur, visited, Color(0.85, 0.45, 0.55))
		_draw_room_box(r3, &"room_spire", cur, visited, Color(0.55, 0.65, 1.0))

	func _draw_room_box(rect: Rect2, rid: StringName, cur: StringName, visited: Dictionary, base_col: Color) -> void:
		var is_vis := bool(visited.get(String(rid), false))
		var fill := base_col if is_vis else Color(0.18, 0.2, 0.28)
		if rid == cur:
			fill = Color(1.0, 0.92, 0.35)
		draw_rect(rect, Color(fill.r, fill.g, fill.b, 0.45), true)
		draw_rect(rect, fill, false, 1.5)
