extends Node

signal loadout_changed
signal stash_changed
signal room_changed(room_id: StringName)
signal lock_state_changed(locked: bool)
signal player_stats_changed

const SAVE_PATH := "user://hackslash_sample_save.json"
const MAX_ACTIVE_WEAPONS := 2
const MAX_WEAPON_LEVEL := 5
const EXP_THRESHOLDS: Array = [0, 100, 220, 380, 580]
const SHARD_UPGRADE_COSTS: Array = [0, 40, 70, 110, 160]

var is_in_prep_zone: bool = true
var loadout_locked: bool = false
var current_room_id: StringName = &"room_sanctuary"
var active_weapon_slot: int = 0
var active_element_slot: int = 0

var stash: Dictionary = {}
var deployment_kit: Dictionary = {}


func _enter_tree() -> void:
	_register_input_map()


func _ready() -> void:
	_init_default_state()
	load_game()


func _init_default_state() -> void:
	stash = {
		"unlocked_weapons": {
			"ls_vanguard": true,
			"kt_crimson": true,
			"wd_aether": true,
		},
		"weapon_levels": {
			"ls_vanguard": 2,
			"kt_crimson": 2,
			"wd_aether": 2,
			"kt_phantom": 1,
			"gs_obsidian": 1,
			"bw_tempest": 1,
			"dp_viper": 1,
		},
		"weapon_exp": {
			"ls_vanguard": 0,
			"kt_crimson": 0,
			"wd_aether": 0,
			"kt_phantom": 0,
			"gs_obsidian": 0,
			"bw_tempest": 0,
			"dp_viper": 0,
		},
		"mastery_shards": 60,
		"owned_armors": ["cloak_windwalker", "plate_obsidian", "robe_aether"],
		"owned_mods": [
			"mod_afterimage_dash",
			"mod_launcher_shock",
			"mod_perfect_dodge_reset",
			"mod_flux_siphon",
		],
		"unlocked_elements": ["fire", "ice", "lightning", "wind", "void"],
		"owned_items": {
			"flask_heal": 6,
			"tonic_flux": 4,
			"oil_overdrive": 4,
			"bomb_stagger": 6,
		},
		"enemy_pity": {},
		"visited_rooms": {"room_sanctuary": true},
		"unlocked_shortcuts": {},
	}

	deployment_kit = {
		"weapons": ["ls_vanguard", "wd_aether"],
		"armor": "cloak_windwalker",
		"mods": ["mod_afterimage_dash", "mod_launcher_shock"],
		"active_elements": ["fire", "ice"],
		"item_pouch": [
			{"id": "flask_heal", "count": 3},
			{"id": "tonic_flux", "count": 2},
			{"id": "oil_overdrive", "count": 2},
			{"id": "bomb_stagger", "count": 3},
		],
	}
	active_weapon_slot = 0
	active_element_slot = 0


func _register_input_map() -> void:
	_bind_keys(&"move_left", [KEY_A, KEY_LEFT])
	_bind_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_bind_keys(&"move_up", [KEY_W, KEY_UP])
	_bind_keys(&"move_down", [KEY_S, KEY_DOWN])
	_bind_keys(&"jump", [KEY_SPACE])
	_bind_keys(&"attack", [KEY_J])
	_bind_keys(&"heavy", [KEY_K])
	_bind_keys(&"skill", [KEY_U])
	_bind_keys(&"dash", [KEY_L, KEY_SHIFT])
	_bind_keys(&"parry", [KEY_I])
	_bind_keys(&"vault", [KEY_C])
	_bind_keys(&"weapon_swap", [KEY_Q])
	_bind_keys(&"element_swap", [KEY_E])
	_bind_keys(&"interact", [KEY_F])
	_bind_keys(&"item_1", [KEY_1])
	_bind_keys(&"item_2", [KEY_2])
	_bind_keys(&"item_3", [KEY_3])
	_bind_keys(&"item_4", [KEY_4])
	_bind_keys(&"debug_hitbox", [KEY_F9])
	_bind_keys(&"debug_slowmo", [KEY_F10])

	_bind_joy(&"jump", JOY_BUTTON_A)
	_bind_joy(&"attack", JOY_BUTTON_X)
	_bind_joy(&"heavy", JOY_BUTTON_Y)
	_bind_joy(&"dash", JOY_BUTTON_B)
	_bind_joy(&"weapon_swap", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_joy(&"element_swap", JOY_BUTTON_LEFT_SHOULDER)
	_bind_joy(&"interact", JOY_BUTTON_BACK)
	_bind_joy_axis(&"skill", JOY_AXIS_TRIGGER_RIGHT)
	_bind_joy_axis(&"parry", JOY_AXIS_TRIGGER_LEFT)


func _bind_keys(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


func _bind_joy(action: StringName, btn: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


func _bind_joy_axis(action: StringName, axis: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = 1.0
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)


func set_room_state(room_id: StringName, in_prep: bool) -> void:
	current_room_id = room_id
	is_in_prep_zone = in_prep
	loadout_locked = not in_prep
	stash["visited_rooms"][String(room_id)] = true
	room_changed.emit(room_id)
	lock_state_changed.emit(loadout_locked)


func can_edit_loadout() -> bool:
	return is_in_prep_zone and not loadout_locked


func get_active_weapon_id() -> StringName:
	var slots: Array = deployment_kit["weapons"]
	return StringName(slots[clampi(active_weapon_slot, 0, MAX_ACTIVE_WEAPONS - 1)])


func get_offhand_weapon_id() -> StringName:
	var slots: Array = deployment_kit["weapons"]
	return StringName(slots[1 - clampi(active_weapon_slot, 0, MAX_ACTIVE_WEAPONS - 1)])


func get_active_weapon() -> WeaponData:
	return WeaponRegistry.get_weapon(get_active_weapon_id())


func get_offhand_weapon() -> WeaponData:
	return WeaponRegistry.get_weapon(get_offhand_weapon_id())


func is_dual_katana_active() -> bool:
	var w0: WeaponData = WeaponRegistry.get_weapon(StringName(deployment_kit["weapons"][0]))
	var w1: WeaponData = WeaponRegistry.get_weapon(StringName(deployment_kit["weapons"][1]))
	if w0 == null or w1 == null:
		return false
	return (
		w0.weapon_type == WeaponData.WeaponType.KATANA
		and w1.weapon_type == WeaponData.WeaponType.KATANA
		and w0.id != w1.id
	)


func get_active_element_id() -> StringName:
	var elems: Array = deployment_kit["active_elements"]
	return StringName(elems[clampi(active_element_slot, 0, 1)])


func get_off_element_id() -> StringName:
	var elems: Array = deployment_kit["active_elements"]
	return StringName(elems[1 - clampi(active_element_slot, 0, 1)])


func swap_active_weapon_slot() -> int:
	active_weapon_slot = 1 - active_weapon_slot
	loadout_changed.emit()
	return active_weapon_slot


func cycle_active_element() -> StringName:
	active_element_slot = 1 - active_element_slot
	loadout_changed.emit()
	return get_active_element_id()


func get_weapon_level(weapon_id: StringName) -> int:
	var lv_map: Dictionary = stash["weapon_levels"]
	return clampi(int(lv_map.get(String(weapon_id), 1)), 1, MAX_WEAPON_LEVEL)


func get_weapon_exp(weapon_id: StringName) -> int:
	return int(stash["weapon_exp"].get(String(weapon_id), 0))


func get_next_level_exp(level: int) -> int:
	if level >= MAX_WEAPON_LEVEL:
		return 0
	return int(EXP_THRESHOLDS[level])


func is_weapon_unlocked(weapon_id: StringName) -> bool:
	return bool(stash["unlocked_weapons"].get(String(weapon_id), false))


func has_mod(mod_id: StringName) -> bool:
	return String(mod_id) in deployment_kit["mods"]


func get_equipped_armor() -> Dictionary:
	return WeaponRegistry.get_armor(StringName(deployment_kit["armor"]))


func equip_weapon_slot(slot_idx: int, weapon_id: StringName) -> bool:
	if not can_edit_loadout():
		HitstopManager.show_toast("Loadout LOCKED in stage! Return to Sanctuary Shrine.", Color(1.0, 0.45, 0.4))
		return false
	if slot_idx < 0 or slot_idx >= MAX_ACTIVE_WEAPONS:
		return false
	if not is_weapon_unlocked(weapon_id):
		return false
	var slots: Array = deployment_kit["weapons"]
	var other_idx := 1 - slot_idx
	if String(slots[other_idx]) == String(weapon_id):
		# Swap slots cleanly so same unique weapon cannot occupy both hands
		slots[other_idx] = slots[slot_idx]
	slots[slot_idx] = String(weapon_id)
	loadout_changed.emit()
	return true


func equip_element_slot(slot_idx: int, elem_id: StringName) -> bool:
	if not can_edit_loadout():
		HitstopManager.show_toast("Elements LOCKED in stage!", Color(1.0, 0.45, 0.4))
		return false
	if slot_idx < 0 or slot_idx > 1:
		return false
	var elems: Array = deployment_kit["active_elements"]
	var other_idx := 1 - slot_idx
	if String(elems[other_idx]) == String(elem_id):
		elems[other_idx] = elems[slot_idx]
	elems[slot_idx] = String(elem_id)
	loadout_changed.emit()
	return true


func equip_armor(armor_id: StringName) -> bool:
	if not can_edit_loadout():
		return false
	deployment_kit["armor"] = String(armor_id)
	loadout_changed.emit()
	return true


func equip_mod_slot(slot_idx: int, mod_id: StringName) -> bool:
	if not can_edit_loadout():
		return false
	if slot_idx < 0 or slot_idx > 1:
		return false
	var mods: Array = deployment_kit["mods"]
	var other_idx := 1 - slot_idx
	if String(mods[other_idx]) == String(mod_id):
		mods[other_idx] = mods[slot_idx]
	mods[slot_idx] = String(mod_id)
	loadout_changed.emit()
	return true


func set_pouch_slot(slot_idx: int, item_id: StringName) -> bool:
	if not can_edit_loadout():
		return false
	if slot_idx < 0 or slot_idx >= 4:
		return false
	var def := WeaponRegistry.get_item(item_id)
	if def.is_empty():
		return false
	var max_stack := int(def["max_stack"])
	var owned := int(stash["owned_items"].get(String(item_id), 0))
	deployment_kit["item_pouch"][slot_idx] = {
		"id": String(item_id),
		"count": mini(max_stack, maxi(owned, max_stack)),
	}
	loadout_changed.emit()
	return true


func refill_pouch_at_shrine() -> void:
	if not can_edit_loadout():
		return
	for i in range(4):
		var slot: Dictionary = deployment_kit["item_pouch"][i]
		var def := WeaponRegistry.get_item(StringName(slot["id"]))
		if not def.is_empty():
			slot["count"] = int(def["max_stack"])
	loadout_changed.emit()


func consume_pouch_slot(slot_idx: int) -> StringName:
	if slot_idx < 0 or slot_idx >= 4:
		return &""
	var slot: Dictionary = deployment_kit["item_pouch"][slot_idx]
	if int(slot["count"]) <= 0:
		HitstopManager.show_toast("Item pouch slot empty!", Color(1.0, 0.55, 0.45))
		return &""
	slot["count"] = int(slot["count"]) - 1
	loadout_changed.emit()
	return StringName(slot["id"])


func add_weapon_exp(weapon_id: StringName, amount: int) -> void:
	var key := String(weapon_id)
	var lv := get_weapon_level(weapon_id)
	if lv >= MAX_WEAPON_LEVEL:
		return
	var xp := int(stash["weapon_exp"].get(key, 0)) + amount
	while lv < MAX_WEAPON_LEVEL and xp >= int(EXP_THRESHOLDS[lv]):
		xp -= int(EXP_THRESHOLDS[lv])
		lv += 1
		var w := WeaponRegistry.get_weapon(weapon_id)
		var wname := w.display_name if w != null else key
		HitstopManager.show_toast("%s reached Lv.%d! New Move Unlocked!" % [wname, lv], Color(1.0, 0.9, 0.35))
	stash["weapon_levels"][key] = lv
	stash["weapon_exp"][key] = xp
	stash_changed.emit()
	loadout_changed.emit()


func upgrade_weapon_with_shards(weapon_id: StringName) -> bool:
	if not can_edit_loadout():
		return false
	if not is_weapon_unlocked(weapon_id):
		return false
	var lv := get_weapon_level(weapon_id)
	if lv >= MAX_WEAPON_LEVEL:
		return false
	var cost := int(SHARD_UPGRADE_COSTS[lv])
	if int(stash["mastery_shards"]) < cost:
		HitstopManager.show_toast("Need %d Mastery Shards!" % cost, Color(1.0, 0.5, 0.45))
		return false
	stash["mastery_shards"] = int(stash["mastery_shards"]) - cost
	stash["weapon_levels"][String(weapon_id)] = lv + 1
	stash["weapon_exp"][String(weapon_id)] = 0
	var w := WeaponRegistry.get_weapon(weapon_id)
	HitstopManager.show_toast("Upgraded %s to Lv.%d!" % [w.display_name, lv + 1], Color(0.55, 1.0, 0.65))
	stash_changed.emit()
	loadout_changed.emit()
	return true


func roll_enemy_drop(enemy_id: StringName) -> Dictionary:
	var table: Dictionary = WeaponRegistry.drop_tables.get(enemy_id, {})
	if table.is_empty():
		stash["mastery_shards"] = int(stash["mastery_shards"]) + 20
		stash_changed.emit()
		return {"type": "shards", "amount": 20}

	var drop_wep_id := StringName(table["weapon_id"])
	var shards := int(table["fallback_shards"])

	# Non-duplicate rule: if already unlocked or no weapon assigned, give Mastery Shards instead
	if drop_wep_id == &"" or is_weapon_unlocked(drop_wep_id):
		stash["mastery_shards"] = int(stash["mastery_shards"]) + shards
		stash_changed.emit()
		HitstopManager.show_toast("+%d Mastery Shards (No Duplicates -> Shards)" % shards, Color(0.65, 0.90, 1.0))
		return {"type": "shards", "amount": shards}

	var pity_map: Dictionary = stash["enemy_pity"]
	var misses := int(pity_map.get(String(enemy_id), 0))
	var chance := minf(1.0, float(table["base_chance"]) + float(misses) * float(table["pity_step"]))
	if randf() <= chance:
		pity_map[String(enemy_id)] = 0
		stash["unlocked_weapons"][String(drop_wep_id)] = true
		stash_changed.emit()
		var w := WeaponRegistry.get_weapon(drop_wep_id)
		var msg := "NEW WEAPON UNLOCKED (To Stash): %s!" % w.display_name
		HitstopManager.show_toast(msg, Color(1.0, 0.85, 0.28))
		save_game()
		return {"type": "weapon", "weapon_id": drop_wep_id}
	else:
		pity_map[String(enemy_id)] = misses + 1
		stash["mastery_shards"] = int(stash["mastery_shards"]) + 15
		stash_changed.emit()
		var next_chance := int(minf(100.0, (float(table["base_chance"]) + float(misses + 1) * float(table["pity_step"])) * 100.0))
		HitstopManager.show_toast("+15 Shards | Drop Pity Raised (%d%% next kill)" % next_chance, Color(0.75, 0.82, 0.95))
		return {"type": "shards", "amount": 15}


func unlock_all_for_sample_testing() -> void:
	for wid in WeaponRegistry.weapon_order:
		stash["unlocked_weapons"][String(wid)] = true
		if int(stash["weapon_levels"].get(String(wid), 1)) < 3:
			stash["weapon_levels"][String(wid)] = 3
	stash["mastery_shards"] = int(stash["mastery_shards"]) + 300
	stash_changed.emit()
	loadout_changed.emit()
	HitstopManager.show_toast("Sample Test: All 7 Weapons Unlocked (Lv.3+) & +300 Shards!", Color(0.55, 1.0, 0.80))
	save_game()


func reset_save_data() -> void:
	_init_default_state()
	save_game()
	stash_changed.emit()
	loadout_changed.emit()
	HitstopManager.show_toast("Save Data Reset to Default Starter Kit.", Color(1.0, 0.78, 0.4))


func save_game() -> void:
	var payload := {
		"stash": stash,
		"deployment_kit": deployment_kit,
	}
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	var dir := DirAccess.open("user://")
	if dir != null:
		if dir.file_exists("hackslash_sample_save.json"):
			dir.remove("hackslash_sample_save.json")
		dir.rename("hackslash_sample_save.json.tmp", "hackslash_sample_save.json")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	if parsed.has("stash") and typeof(parsed["stash"]) == TYPE_DICTIONARY:
		for k in parsed["stash"].keys():
			stash[k] = parsed["stash"][k]
	if parsed.has("deployment_kit") and typeof(parsed["deployment_kit"]) == TYPE_DICTIONARY:
		for k in parsed["deployment_kit"].keys():
			deployment_kit[k] = parsed["deployment_kit"][k]
	_migrate_legacy_ids()
	stash_changed.emit()
	loadout_changed.emit()


func _migrate_legacy_ids() -> void:
	var legacy_map := {"sc_aether": "wd_aether"}
	for old_id in legacy_map.keys():
		var new_id: String = legacy_map[old_id]
		var unlocked: Dictionary = stash.get("unlocked_weapons", {})
		if unlocked.has(old_id):
			unlocked[new_id] = unlocked[old_id]
			unlocked.erase(old_id)
		var levels: Dictionary = stash.get("weapon_levels", {})
		if levels.has(old_id):
			levels[new_id] = maxi(int(levels.get(new_id, 1)), int(levels[old_id]))
			levels.erase(old_id)
		var xp: Dictionary = stash.get("weapon_exp", {})
		if xp.has(old_id):
			xp[new_id] = maxi(int(xp.get(new_id, 0)), int(xp[old_id]))
			xp.erase(old_id)
		var eq_weapons: Array = deployment_kit.get("weapons", [])
		for i in range(eq_weapons.size()):
			if String(eq_weapons[i]) == old_id:
				eq_weapons[i] = new_id
