class_name PrepUi
extends CanvasLayer

signal closed

var root_panel: ColorRect
var info_label: Label
var shards_label: Label
var dual_badge_label: Label

var weapon_buttons_col: VBoxContainer
var eq_buttons_col: VBoxContainer
var intel_label: Label

var _selected_weapon_slot: int = 0
var _selected_elem_slot: int = 0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	GameState.loadout_changed.connect(_refresh)
	GameState.stash_changed.connect(_refresh)


func open_prep() -> void:
	if not GameState.can_edit_loadout():
		HitstopManager.show_toast("Loadout LOCKED in Stage! Return to Sanctuary Prep Shrine.", Color(1.0, 0.45, 0.38))
		return
	visible = true
	get_tree().paused = true
	_refresh()


func close_prep() -> void:
	visible = false
	get_tree().paused = false
	GameState.save_game()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		close_prep()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(640, 360)
	dim.color = Color(0.02, 0.03, 0.06, 0.82)
	add_child(dim)

	root_panel = ColorRect.new()
	root_panel.position = Vector2(20, 16)
	root_panel.size = Vector2(600, 328)
	root_panel.color = Color(0.09, 0.11, 0.17, 0.98)
	add_child(root_panel)

	var title := _mk_label(Vector2(14, 8), "SANCTUARY PREP SHRINE — LOCKED EXPEDITION KIT", 10, Color(0.55, 0.94, 1.0))
	root_panel.add_child(title)

	shards_label = _mk_label(Vector2(380, 8), "Shards: 60", 9, Color(1.0, 0.88, 0.38))
	root_panel.add_child(shards_label)

	var close_btn := _mk_btn(Vector2(516, 6), Vector2(74, 18), "DEPLOY [F]", Callable(self, "close_prep"))
	root_panel.add_child(close_btn)

	dual_badge_label = _mk_label(Vector2(14, 24), "Slot Mode: 2 Distinct Weapons", 8, Color(0.75, 0.92, 0.78))
	root_panel.add_child(dual_badge_label)

	# Scrollable Left & Center Columns so all rows always stay accessible
	var w_scroll := ScrollContainer.new()
	w_scroll.position = Vector2(14, 42)
	w_scroll.size = Vector2(215, 240)
	root_panel.add_child(w_scroll)

	weapon_buttons_col = VBoxContainer.new()
	weapon_buttons_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_buttons_col.add_theme_constant_override("separation", 2)
	w_scroll.add_child(weapon_buttons_col)

	var eq_scroll := ScrollContainer.new()
	eq_scroll.position = Vector2(236, 42)
	eq_scroll.size = Vector2(182, 240)
	root_panel.add_child(eq_scroll)

	eq_buttons_col = VBoxContainer.new()
	eq_buttons_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_buttons_col.add_theme_constant_override("separation", 2)
	eq_scroll.add_child(eq_buttons_col)

	var intel_bg := ColorRect.new()
	intel_bg.position = Vector2(426, 42)
	intel_bg.size = Vector2(164, 240)
	intel_bg.color = Color(0.06, 0.07, 0.12)
	root_panel.add_child(intel_bg)

	intel_label = _mk_label(Vector2(432, 48), "", 8, Color(0.84, 0.88, 0.96))
	intel_label.size = Vector2(152, 228)
	intel_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root_panel.add_child(intel_label)

	# Bottom action bar
	info_label = _mk_label(Vector2(14, 286), "", 8, Color(0.92, 0.92, 0.78))
	info_label.size = Vector2(360, 34)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	root_panel.add_child(info_label)

	var test_btn := _mk_btn(Vector2(382, 294), Vector2(126, 22), "Sample: Unlock All 7", Callable(GameState, "unlock_all_for_sample_testing"))
	root_panel.add_child(test_btn)

	var reset_btn := _mk_btn(Vector2(514, 294), Vector2(76, 22), "Reset Save", Callable(GameState, "reset_save_data"))
	root_panel.add_child(reset_btn)


func _refresh() -> void:
	if not visible:
		return
	for child in weapon_buttons_col.get_children():
		child.queue_free()
	for child in eq_buttons_col.get_children():
		child.queue_free()

	shards_label.text = "Mastery Shards: %d" % int(GameState.stash.get("mastery_shards", 0))
	if GameState.is_dual_katana_active():
		dual_badge_label.text = "DUAL KATANA MODE ACTIVE (Option A: Uses Slot 1 + Slot 2 | U = Combine Art)"
		dual_badge_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	else:
		dual_badge_label.text = "Active Loadout: Slot 1 + Slot 2 (Swap: Q) | Only 2 Weapons Enter Stage"
		dual_badge_label.add_theme_color_override("font_color", Color(0.75, 0.92, 0.78))

	# Slot selector row
	var slot_row := HBoxContainer.new()
	for s in range(2):
		var cur_w := WeaponRegistry.get_weapon(StringName(GameState.deployment_kit["weapons"][s]))
		var prefix := "[EDIT] " if _selected_weapon_slot == s else ""
		var b := _mk_inline_btn("%sS%d: %s" % [prefix, s + 1, cur_w.get_type_name()], Callable(self, "_on_select_weapon_slot").bind(s))
		slot_row.add_child(b)
	weapon_buttons_col.add_child(slot_row)

	# Weapon list (Non-duplicate unlocks)
	for wid in WeaponRegistry.weapon_order:
		var w := WeaponRegistry.get_weapon(wid)
		var unlocked := GameState.is_weapon_unlocked(wid)
		var lv := GameState.get_weapon_level(wid)
		var row := HBoxContainer.new()
		var eq_tag := ""
		if String(GameState.deployment_kit["weapons"][0]) == String(wid):
			eq_tag = "[S1] "
		elif String(GameState.deployment_kit["weapons"][1]) == String(wid):
			eq_tag = "[S2] "

		var label_txt := "%s%s (Lv.%d)" % [eq_tag, w.display_name, lv] if unlocked else "LOCKED: %s" % w.display_name
		var wb := _mk_inline_btn(label_txt, Callable(self, "_on_pick_weapon").bind(wid))
		if not unlocked:
			wb.add_theme_color_override("font_color", Color(0.52, 0.54, 0.62))
		row.add_child(wb)

		if unlocked and lv < GameState.MAX_WEAPON_LEVEL:
			var cost := int(GameState.SHARD_UPGRADE_COSTS[lv])
			var up_b := _mk_inline_btn("+Lv(%d)" % cost, Callable(self, "_on_upgrade_weapon").bind(wid))
			row.add_child(up_b)
		weapon_buttons_col.add_child(row)

	# Center Column: 2 Active Elements, Armor, 2 Mods, Refill Pouch
	var el_row := HBoxContainer.new()
	for es in range(2):
		var eid := StringName(GameState.deployment_kit["active_elements"][es])
		var edata := ElementRegistry.get_element(eid)
		var pre := "*" if _selected_elem_slot == es else ""
		var eb := _mk_inline_btn("%sElem %d: %s" % [pre, es + 1, edata["short"]], Callable(self, "_on_select_elem_slot").bind(es))
		el_row.add_child(eb)
	eq_buttons_col.add_child(el_row)

	var elem_pick_row := HBoxContainer.new()
	for eid in ElementRegistry.ELEMENT_ORDER:
		var edata := ElementRegistry.get_element(eid)
		var pb := _mk_inline_btn(String(edata["short"]), Callable(self, "_on_pick_element").bind(eid))
		elem_pick_row.add_child(pb)
	eq_buttons_col.add_child(elem_pick_row)

	eq_buttons_col.add_child(_mk_label(Vector2.ZERO, "-- Armor (1 Slot) --", 8, Color(0.65, 0.82, 1.0)))
	for aid in WeaponRegistry.armors.keys():
		var a: Dictionary = WeaponRegistry.armors[aid]
		var active := String(GameState.deployment_kit["armor"]) == String(aid)
		var ab := _mk_inline_btn("%s%s" % ["[EQ] " if active else "", a["name"]], Callable(self, "_on_pick_armor").bind(aid))
		eq_buttons_col.add_child(ab)

	eq_buttons_col.add_child(_mk_label(Vector2.ZERO, "-- Combat Mods (2 Slots) --", 8, Color(0.65, 0.82, 1.0)))
	for mid in WeaponRegistry.mods.keys():
		var m: Dictionary = WeaponRegistry.mods[mid]
		var mods_arr: Array = GameState.deployment_kit["mods"]
		var idx := mods_arr.find(String(mid))
		var prefix := "[M%d] " % (idx + 1) if idx >= 0 else ""
		var mb := _mk_inline_btn("%s%s" % [prefix, m["name"]], Callable(self, "_on_pick_mod").bind(mid))
		eq_buttons_col.add_child(mb)

	var refill_b := _mk_inline_btn("Refill 4-Slot Item Pouch", Callable(self, "_on_refill_pouch"))
	eq_buttons_col.add_child(refill_b)

	intel_label.text = (
		"ZONE INTEL BOARD\n\n"
		+ "[SUNKEN BASTION]\n"
		+ "- Armored Sentinel\n  Counter: Greatsword\n  Drop: Obsidian Cleaver\n"
		+ "- Barrier Wraith (10-Hit)\n  Counter: Katana / Dual\n  Drop: Phantom Gale\n"
		+ "- Agile Duelist\n  Counter: Longsword Parry\n\n"
		+ "[ASTRAL SPIRE]\n"
		+ "- Sky Hawker\n  Counter: Bow Weakpoint\n  Drop: Tempest Recurve\n"
		+ "- Blink Stalker\n  Counter: Dual Pistol\n  Drop: Viper Twinlocks\n"
		+ "- Astral Phantom (75% PR)\n  Counter: Wand / Elem"
	)


func _on_select_weapon_slot(slot_idx: int) -> void:
	_selected_weapon_slot = slot_idx
	_refresh()


func _on_pick_weapon(wid: StringName) -> void:
	var w := WeaponRegistry.get_weapon(wid)
	if not GameState.is_weapon_unlocked(wid):
		info_label.text = "%s drops from: %s" % [w.display_name, w.counter_role]
		return
	GameState.equip_weapon_slot(_selected_weapon_slot, wid)
	info_label.text = "%s: %s" % [w.display_name, w.description]


func _on_upgrade_weapon(wid: StringName) -> void:
	GameState.upgrade_weapon_with_shards(wid)


func _on_select_elem_slot(slot_idx: int) -> void:
	_selected_elem_slot = slot_idx
	_refresh()


func _on_pick_element(eid: StringName) -> void:
	GameState.equip_element_slot(_selected_elem_slot, eid)
	var edata := ElementRegistry.get_element(eid)
	info_label.text = "%s: %s" % [edata["name"], edata["description"]]


func _on_pick_armor(aid: StringName) -> void:
	GameState.equip_armor(aid)
	var a := WeaponRegistry.get_armor(aid)
	info_label.text = "%s: %s" % [a["name"], a["description"]]


func _on_pick_mod(mid: StringName) -> void:
	var mods_arr: Array = GameState.deployment_kit["mods"]
	var idx := mods_arr.find(String(mid))
	GameState.equip_mod_slot(0 if idx != 0 else 1, mid)
	var m := WeaponRegistry.get_mod(mid)
	info_label.text = "%s: %s" % [m["name"], m["description"]]


func _on_refill_pouch() -> void:
	GameState.refill_pouch_at_shrine()
	info_label.text = "Expedition Item Pouch refilled to max stack limits."


func _mk_label(pos: Vector2, txt: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _mk_btn(pos: Vector2, sz: Vector2, txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = sz
	b.text = txt
	b.add_theme_font_size_override("font_size", 8)
	b.pressed.connect(cb)
	return b


func _mk_inline_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 8)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	return b
