extends Node

const MoveDataRes = preload("res://scripts/data/move_data.gd")
const WeaponDataRes = preload("res://scripts/data/weapon_data.gd")

var weapons: Dictionary = {}
var weapon_order: Array = []
var armors: Dictionary = {}
var mods: Dictionary = {}
var items: Dictionary = {}
var drop_tables: Dictionary = {}


func _ready() -> void:
	_build_weapons()
	_build_equipment_and_items()
	_build_drop_tables()


func _mv(cfg: Dictionary) -> MoveData:
	return MoveDataRes.make(cfg)


func _build_weapons() -> void:
	# 1. Vanguard Longsword (Technical Duelist & Parry Riposte)
	var ls := WeaponDataRes.new()
	ls.id = &"ls_vanguard"
	ls.display_name = "Vanguard Longsword"
	ls.weapon_type = WeaponDataRes.WeaponType.LONGSWORD
	ls.sprite_path = "res://assets/sprites/weapons/longsword.png"
	ls.phys_mult = 1.05
	ls.elem_mult = 1.00
	ls.poise_mult = 1.05
	ls.speed_mult = 1.05
	ls.primary_trait = &"parry_riposte"
	ls.secondary_modifier = &"smooth_cancel"
	ls.counter_role = "Agile Duelist (Parry Riposte)"
	ls.description = "Technical duelist blade. 4-hit rapier combos, ankle sweeps, dragon spirals, and Parry Riposte."
	ls.moves = [
		_mv({"move_id": &"ls_l1", "display_name": "Quick Slash", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 3, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 0.95, "poise_damage": 13.0, "hitstop_frames": 3, "knockback": Vector2(65, -20), "self_impulse": Vector2(65, 0), "hitbox_offset": Vector2(26, -24), "hitbox_size": Vector2(36, 28), "swing_style": &"ls_fencing_slash"}),
		_mv({"move_id": &"ls_l2", "display_name": "Reverse Edge", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 3, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 1.10, "poise_damage": 15.0, "hitstop_frames": 3, "knockback": Vector2(75, -35), "self_impulse": Vector2(80, 0), "hitbox_offset": Vector2(28, -24), "hitbox_size": Vector2(40, 30), "swing_style": &"ls_reverse_cut"}),
		_mv({"move_id": &"ls_l3", "display_name": "Triple Rapier Flurry", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 4, "active_frames": 9, "recovery_frames": 8, "cancel_from_frame": 9, "damage_mult": 0.55, "poise_damage": 8.0, "hitstop_frames": 2, "knockback": Vector2(45, -15), "self_impulse": Vector2(105, 0), "hitbox_offset": Vector2(34, -24), "hitbox_size": Vector2(50, 26), "swing_style": &"ls_rapier_flurry", "multi_hits": 3}),
		_mv({"move_id": &"ls_l4", "display_name": "Vanguard Cross", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 5, "active_frames": 7, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 0.92, "poise_damage": 16.0, "hitstop_frames": 5, "knockback": Vector2(195, -65), "self_impulse": Vector2(135, 0), "hitbox_offset": Vector2(34, -24), "hitbox_size": Vector2(52, 36), "swing_style": &"ls_cross_cleave", "multi_hits": 2}),
		_mv({"move_id": &"ls_dash", "display_name": "Piercing Skewer", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 3, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.35, "poise_damage": 20.0, "hitstop_frames": 4, "knockback": Vector2(165, -45), "self_impulse": Vector2(210, 0), "hitbox_offset": Vector2(36, -24), "hitbox_size": Vector2(54, 24), "swing_style": &"ls_lunge_thrust"}),
		_mv({"move_id": &"ls_vault", "display_name": "Backstab Riposte", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 3, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.55, "poise_damage": 26.0, "hitstop_frames": 5, "knockback": Vector2(175, -55), "self_impulse": Vector2(120, -35), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(48, 28), "swing_style": &"ls_lunge_thrust"}),
		_mv({"move_id": &"ls_heavy", "display_name": "Helm Piercer", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 7, "active_frames": 5, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.65, "poise_damage": 28.0, "hitstop_frames": 5, "knockback": Vector2(210, -70), "self_impulse": Vector2(135, 0), "hitbox_offset": Vector2(34, -24), "hitbox_size": Vector2(50, 30), "swing_style": &"ls_lunge_thrust"}),
		_mv({"move_id": &"ls_heavy2", "display_name": "Aether Wave Follow-Up", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 5, "active_frames": 5, "recovery_frames": 10, "cancel_from_frame": 8, "damage_mult": 1.75, "poise_damage": 24.0, "hitstop_frames": 5, "knockback": Vector2(205, -60), "self_impulse": Vector2(75, 0), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(42, 32), "swing_style": &"ls_reverse_cut", "is_projectile": true, "projectile_speed": 430.0}),
		_mv({"move_id": &"ls_up_heavy", "display_name": "Dragon Spiral", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 5, "active_frames": 8, "recovery_frames": 10, "cancel_from_frame": 10, "damage_mult": 0.90, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(65, -240), "self_impulse": Vector2(45, -185), "hitbox_offset": Vector2(14, -28), "hitbox_size": Vector2(64, 52), "swing_style": &"ls_dragon_spiral", "multi_hits": 2, "is_launcher": true, "arc_angle_deg": 240.0}),
		_mv({"move_id": &"ls_down_heavy", "display_name": "Ankle Sweep", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 4, "active_frames": 5, "recovery_frames": 9, "cancel_from_frame": 7, "damage_mult": 1.35, "poise_damage": 26.0, "hitstop_frames": 4, "knockback": Vector2(95, -145), "self_impulse": Vector2(150, 0), "hitbox_offset": Vector2(30, -10), "hitbox_size": Vector2(52, 22), "swing_style": &"ls_ankle_sweep"}),
		_mv({"move_id": &"ls_air1", "display_name": "Air Crescent", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 3, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 0.98, "poise_damage": 12.0, "hitstop_frames": 3, "knockback": Vector2(65, -110), "self_impulse": Vector2(20, -60), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(38, 36), "swing_style": &"ls_fencing_slash"}),
		_mv({"move_id": &"ls_air2", "display_name": "Air Reverse", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 3, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 1.15, "poise_damage": 14.0, "hitstop_frames": 3, "knockback": Vector2(85, -95), "self_impulse": Vector2(30, -55), "hitbox_offset": Vector2(26, -24), "hitbox_size": Vector2(40, 36), "swing_style": &"ls_reverse_cut"}),
		_mv({"move_id": &"ls_air3", "display_name": "Aerial Cross-Thrust", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 4, "active_frames": 6, "recovery_frames": 9, "cancel_from_frame": 8, "damage_mult": 0.85, "poise_damage": 14.0, "hitstop_frames": 4, "knockback": Vector2(175, 45), "self_impulse": Vector2(85, -30), "hitbox_offset": Vector2(30, -22), "hitbox_size": Vector2(48, 34), "swing_style": &"ls_cross_cleave", "multi_hits": 2}),
		_mv({"move_id": &"ls_air_heavy", "display_name": "Helm Splitter", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 6, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.75, "poise_damage": 30.0, "hitstop_frames": 6, "knockback": Vector2(160, 145), "self_impulse": Vector2(55, 110), "hitbox_offset": Vector2(28, -16), "hitbox_size": Vector2(48, 44), "swing_style": &"ls_cross_cleave", "arc_angle_deg": 130.0}),
		_mv({"move_id": &"ls_launch", "display_name": "Rising Fang", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 5, "active_frames": 5, "recovery_frames": 10, "cancel_from_frame": 8, "damage_mult": 1.25, "poise_damage": 20.0, "hitstop_frames": 4, "knockback": Vector2(40, -255), "self_impulse": Vector2(25, -210), "hitbox_offset": Vector2(24, -34), "hitbox_size": Vector2(34, 48), "swing_style": &"ls_dragon_spiral", "is_launcher": true}),
		_mv({"move_id": &"ls_dive", "display_name": "Plunge Thrust", "slot_tag": &"dive", "required_level": 2, "startup_frames": 4, "active_frames": 14, "recovery_frames": 10, "cancel_from_frame": 10, "damage_mult": 1.45, "poise_damage": 24.0, "hitstop_frames": 5, "knockback": Vector2(120, 140), "self_impulse": Vector2(30, 330), "hitbox_offset": Vector2(12, -10), "hitbox_size": Vector2(32, 34), "swing_style": &"ls_lunge_thrust", "is_dive": true}),
		_mv({"move_id": &"ls_sig", "display_name": "Aether Blade Wave", "slot_tag": &"signature", "required_level": 3, "startup_frames": 6, "active_frames": 5, "recovery_frames": 11, "cancel_from_frame": 9, "damage_mult": 1.9, "poise_damage": 26.0, "hitstop_frames": 5, "knockback": Vector2(170, -60), "self_impulse": Vector2(85, 0), "hitbox_offset": Vector2(32, -26), "hitbox_size": Vector2(48, 34), "swing_style": &"ls_fencing_slash", "is_signature": true, "is_projectile": true, "projectile_speed": 410.0, "flux_cost": 18.0}),
		_mv({"move_id": &"ls_switch", "display_name": "Flash Draw", "slot_tag": &"switch", "required_level": 4, "startup_frames": 2, "active_frames": 5, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 1.4, "poise_damage": 22.0, "hitstop_frames": 4, "knockback": Vector2(140, -45), "self_impulse": Vector2(140, 0), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(46, 32), "swing_style": &"ls_lunge_thrust", "is_switch_attack": true}),
		_mv({"move_id": &"ls_ult", "display_name": "Sovereign Cross", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 7, "active_frames": 9, "recovery_frames": 14, "cancel_from_frame": 13, "damage_mult": 1.65, "poise_damage": 26.0, "hitstop_frames": 7, "knockback": Vector2(260, -135), "self_impulse": Vector2(170, -20), "hitbox_offset": Vector2(34, -28), "hitbox_size": Vector2(72, 48), "swing_style": &"ls_cross_cleave", "multi_hits": 2, "aoe_ring_radius": 68.0, "is_ultimate": true, "has_hyper_armor": true, "flux_cost": 40.0}),
	]
	weapons[ls.id] = ls

	# 2. Crimson Edge (Katana #1 — Iaido Bleed & Rapid Draw)
	var kt1 := WeaponDataRes.new()
	kt1.id = &"kt_crimson"
	kt1.display_name = "Crimson Edge (Katana)"
	kt1.weapon_type = WeaponDataRes.WeaponType.KATANA
	kt1.sprite_path = "res://assets/sprites/weapons/katana_crimson.png"
	kt1.phys_mult = 0.90
	kt1.elem_mult = 1.05
	kt1.poise_mult = 0.65
	kt1.speed_mult = 1.30
	kt1.primary_trait = &"bleed_burst"
	kt1.secondary_modifier = &"echo_slash"
	kt1.counter_role = "Barrier Wraith (Rapid Hit-Count)"
	kt1.description = "Iaido blood-draw katana: 3-hit rapid flurry, Sakura Whirlwind, and blink sheathe slashes."
	kt1.moves = _build_crimson_katana_moves()
	weapons[kt1.id] = kt1

	# 3. Phantom Gale (Katana #2 — Blink Phase & Vortex Pull)
	var kt2 := WeaponDataRes.new()
	kt2.id = &"kt_phantom"
	kt2.display_name = "Phantom Gale (Katana)"
	kt2.weapon_type = WeaponDataRes.WeaponType.KATANA
	kt2.sprite_path = "res://assets/sprites/weapons/katana_phantom.png"
	kt2.phys_mult = 0.92
	kt2.elem_mult = 1.12
	kt2.poise_mult = 0.65
	kt2.speed_mult = 1.35
	kt2.primary_trait = &"blink_cut"
	kt2.secondary_modifier = &"vortex_pull"
	kt2.counter_role = "Barrier Wraith (Dual Vortex)"
	kt2.description = "Wind-phase katana with Vacuum Vortex Spins & Blink Cuts. Pair with Crimson Edge for Dual Katana."
	kt2.moves = _build_phantom_katana_moves()
	weapons[kt2.id] = kt2

	# 4. Aether Wand (Arcane Catalyst, Rune Vortices & Pillars)
	var wd := WeaponDataRes.new()
	wd.id = &"wd_aether"
	wd.display_name = "Aether Wand"
	wd.weapon_type = WeaponDataRes.WeaponType.WAND
	wd.sprite_path = "res://assets/sprites/weapons/wand.png"
	wd.phys_mult = 0.45
	wd.elem_mult = 1.85
	wd.poise_mult = 0.75
	wd.speed_mult = 1.00
	wd.primary_trait = &"elemental_detonate"
	wd.secondary_modifier = &"flux_surge"
	wd.counter_role = "Astral Phantom (75% Phys Resist)"
	wd.description = "Slender arcane wand (1.85x Element). Crisp spell flicks, geometric rune circles, Gravity Wells & Status Detonation."
	wd.moves = [
		_mv({"move_id": &"wd_l1", "display_name": "Wand Flick", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 0.95, "poise_damage": 10.0, "hitstop_frames": 2, "knockback": Vector2(65, -20), "self_impulse": Vector2(30, 0), "hitbox_offset": Vector2(28, -24), "hitbox_size": Vector2(44, 28), "swing_style": &"wand_jab", "flux_gain": 14.0}),
		_mv({"move_id": &"wd_l2", "display_name": "Arc Bolt", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.1, "poise_damage": 12.0, "hitstop_frames": 3, "knockback": Vector2(85, -30), "self_impulse": Vector2(-15, 0), "hitbox_offset": Vector2(22, -26), "hitbox_size": Vector2(30, 26), "swing_style": &"wand_jab", "is_projectile": true, "projectile_speed": 370.0, "flux_gain": 12.0}),
		_mv({"move_id": &"wd_l3", "display_name": "Arcane Vortex Twirl", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 4, "active_frames": 8, "recovery_frames": 8, "cancel_from_frame": 8, "damage_mult": 0.75, "poise_damage": 11.0, "hitstop_frames": 3, "knockback": Vector2(25, -45), "self_impulse": Vector2(40, 0), "hitbox_offset": Vector2(12, -24), "hitbox_size": Vector2(72, 46), "swing_style": &"wand_circle_cast", "multi_hits": 2, "pull_enemies": 115.0, "arc_angle_deg": 240.0, "flux_gain": 16.0}),
		_mv({"move_id": &"wd_l4", "display_name": "Elemental Pillar Slam", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 6, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.60, "poise_damage": 22.0, "hitstop_frames": 5, "knockback": Vector2(140, -105), "self_impulse": Vector2(30, 0), "hitbox_offset": Vector2(36, -24), "hitbox_size": Vector2(66, 48), "swing_style": &"wand_whip_arc", "aoe_ring_radius": 78.0, "flux_gain": 16.0}),
		_mv({"move_id": &"wd_dash", "display_name": "Phase Orb Surge", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 3, "active_frames": 5, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 1.3, "poise_damage": 14.0, "hitstop_frames": 3, "knockback": Vector2(95, -40), "self_impulse": Vector2(90, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(40, 30), "swing_style": &"wand_jab", "blink_distance": 58.0, "is_projectile": true, "projectile_speed": 430.0, "flux_gain": 14.0}),
		_mv({"move_id": &"wd_vault", "display_name": "Astral Nova Drop", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 4, "active_frames": 5, "recovery_frames": 9, "cancel_from_frame": 7, "damage_mult": 1.45, "poise_damage": 20.0, "hitstop_frames": 4, "knockback": Vector2(130, -80), "self_impulse": Vector2(0, -40), "hitbox_offset": Vector2(18, -22), "hitbox_size": Vector2(72, 52), "swing_style": &"wand_ground_point", "aoe_ring_radius": 72.0, "flux_gain": 15.0}),
		_mv({"move_id": &"wd_heavy", "display_name": "Aether Tri-Cast", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 7, "active_frames": 5, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.45, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(140, -55), "self_impulse": Vector2(-35, 0), "hitbox_offset": Vector2(24, -26), "hitbox_size": Vector2(36, 30), "swing_style": &"wand_jab", "is_projectile": true, "projectile_speed": 410.0, "projectile_count": 3, "projectile_spread_deg": 14.0, "flux_gain": 10.0}),
		_mv({"move_id": &"wd_heavy2", "display_name": "Resonance Nova", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 6, "active_frames": 6, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.95, "poise_damage": 26.0, "hitstop_frames": 6, "knockback": Vector2(160, -110), "self_impulse": Vector2(0, 0), "hitbox_offset": Vector2(28, -26), "hitbox_size": Vector2(88, 62), "swing_style": &"wand_ground_point", "aoe_ring_radius": 90.0, "flux_gain": 12.0}),
		_mv({"move_id": &"wd_up_heavy", "display_name": "Skyward Geyser", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 5, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.5, "poise_damage": 22.0, "hitstop_frames": 4, "knockback": Vector2(35, -245), "self_impulse": Vector2(0, -140), "hitbox_offset": Vector2(30, -34), "hitbox_size": Vector2(56, 60), "swing_style": &"wand_sky_raise", "aoe_ring_radius": 62.0, "is_launcher": true}),
		_mv({"move_id": &"wd_down_heavy", "display_name": "Gravity Well", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 5, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.4, "poise_damage": 24.0, "hitstop_frames": 5, "knockback": Vector2(10, -45), "self_impulse": Vector2(0, 0), "hitbox_offset": Vector2(24, -20), "hitbox_size": Vector2(92, 54), "swing_style": &"wand_ground_point", "pull_enemies": 165.0, "aoe_ring_radius": 92.0}),
		_mv({"move_id": &"wd_air1", "display_name": "Air Orb", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.05, "poise_damage": 10.0, "hitstop_frames": 2, "knockback": Vector2(70, -60), "self_impulse": Vector2(-20, -65), "hitbox_offset": Vector2(22, -22), "hitbox_size": Vector2(32, 28), "swing_style": &"wand_jab", "is_projectile": true, "projectile_speed": 350.0, "flux_gain": 12.0}),
		_mv({"move_id": &"wd_air2", "display_name": "Starfall Spin", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 4, "active_frames": 7, "recovery_frames": 8, "cancel_from_frame": 8, "damage_mult": 0.80, "poise_damage": 12.0, "hitstop_frames": 3, "knockback": Vector2(85, -35), "self_impulse": Vector2(15, -55), "hitbox_offset": Vector2(12, -22), "hitbox_size": Vector2(64, 48), "swing_style": &"wand_circle_cast", "multi_hits": 2, "arc_angle_deg": 240.0, "flux_gain": 14.0}),
		_mv({"move_id": &"wd_air3", "display_name": "Comet Barrage", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 5, "active_frames": 5, "recovery_frames": 9, "cancel_from_frame": 8, "damage_mult": 1.15, "poise_damage": 14.0, "hitstop_frames": 4, "knockback": Vector2(110, 55), "self_impulse": Vector2(-25, -75), "hitbox_offset": Vector2(20, -20), "hitbox_size": Vector2(34, 30), "swing_style": &"wand_whip_arc", "is_projectile": true, "projectile_speed": 420.0, "projectile_count": 3, "projectile_pitch_deg": 28.0, "projectile_spread_deg": 16.0}),
		_mv({"move_id": &"wd_air_heavy", "display_name": "Meteor Catalyst", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 6, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.85, "poise_damage": 26.0, "hitstop_frames": 6, "knockback": Vector2(140, 120), "self_impulse": Vector2(0, 60), "hitbox_offset": Vector2(16, -16), "hitbox_size": Vector2(76, 56), "swing_style": &"wand_ground_point", "aoe_ring_radius": 76.0}),
		_mv({"move_id": &"wd_launch", "display_name": "Geyser Pillar", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 6, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.35, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(25, -245), "self_impulse": Vector2(0, -160), "hitbox_offset": Vector2(32, -36), "hitbox_size": Vector2(46, 56), "swing_style": &"wand_sky_raise", "is_launcher": true, "flux_gain": 12.0}),
		_mv({"move_id": &"wd_dive", "display_name": "Meteor Drop", "slot_tag": &"dive", "required_level": 2, "startup_frames": 5, "active_frames": 14, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.5, "poise_damage": 22.0, "hitstop_frames": 5, "knockback": Vector2(125, 110), "self_impulse": Vector2(0, 310), "hitbox_offset": Vector2(0, -12), "hitbox_size": Vector2(56, 40), "swing_style": &"wand_ground_point", "is_dive": true}),
		_mv({"move_id": &"wd_sig", "display_name": "Elemental Detonate", "slot_tag": &"signature", "required_level": 3, "startup_frames": 6, "active_frames": 6, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 2.25, "poise_damage": 28.0, "hitstop_frames": 6, "knockback": Vector2(160, -110), "self_impulse": Vector2(-20, -30), "hitbox_offset": Vector2(18, -28), "hitbox_size": Vector2(96, 68), "swing_style": &"wand_ground_point", "aoe_ring_radius": 96.0, "is_signature": true, "flux_cost": 22.0}),
		_mv({"move_id": &"wd_switch", "display_name": "Blink Sigil", "slot_tag": &"switch", "required_level": 4, "startup_frames": 2, "active_frames": 5, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 1.4, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(120, -45), "self_impulse": Vector2(-70, -40), "hitbox_offset": Vector2(24, -26), "hitbox_size": Vector2(68, 48), "swing_style": &"wand_circle_cast", "is_switch_attack": true, "flux_gain": 18.0}),
		_mv({"move_id": &"wd_ult", "display_name": "Cataclysm Convergence", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 8, "active_frames": 9, "recovery_frames": 15, "cancel_from_frame": 14, "damage_mult": 3.2, "poise_damage": 42.0, "hitstop_frames": 8, "knockback": Vector2(220, -155), "self_impulse": Vector2(0, -50), "hitbox_offset": Vector2(10, -34), "hitbox_size": Vector2(128, 86), "swing_style": &"wand_ground_point", "pull_enemies": 160.0, "aoe_ring_radius": 115.0, "is_ultimate": true, "has_hyper_armor": true, "flux_cost": 45.0}),
	]
	weapons[wd.id] = wd

	# 5. Obsidian Cleaver (Greatsword — Colossal Cleaver & Whirlwind)
	var gs := WeaponDataRes.new()
	gs.id = &"gs_obsidian"
	gs.display_name = "Obsidian Cleaver"
	gs.weapon_type = WeaponDataRes.WeaponType.GREATSWORD
	gs.sprite_path = "res://assets/sprites/weapons/greatsword.png"
	gs.phys_mult = 1.35
	gs.elem_mult = 0.85
	gs.poise_mult = 1.65
	gs.speed_mult = 0.88
	gs.primary_trait = &"armor_shatter"
	gs.secondary_modifier = &"hyper_cleave"
	gs.counter_role = "Armored Sentinel (Armor Break)"
	gs.description = "Hyper-armor colossus blade. 360-degree Obsidian Whirlwinds, Quake Stomps, and wall-splat slams."
	gs.moves = [
		_mv({"move_id": &"gs_l1", "display_name": "Heavy Cleave", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 7, "active_frames": 5, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.45, "poise_damage": 30.0, "hitstop_frames": 5, "knockback": Vector2(170, -40), "self_impulse": Vector2(60, 0), "hitbox_offset": Vector2(34, -26), "hitbox_size": Vector2(54, 40), "swing_style": &"gs_heavy_cleave", "arc_angle_deg": 125.0}),
		_mv({"move_id": &"gs_l2", "display_name": "Sweeping Rend", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 8, "active_frames": 5, "recovery_frames": 11, "cancel_from_frame": 11, "damage_mult": 1.65, "poise_damage": 36.0, "hitstop_frames": 5, "knockback": Vector2(220, -60), "self_impulse": Vector2(85, 0), "hitbox_offset": Vector2(36, -26), "hitbox_size": Vector2(58, 40), "swing_style": &"gs_upward_rend", "has_hyper_armor": true, "arc_angle_deg": 135.0}),
		_mv({"move_id": &"gs_l3", "display_name": "Obsidian Whirlwind", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 7, "active_frames": 10, "recovery_frames": 11, "cancel_from_frame": 14, "damage_mult": 1.05, "poise_damage": 26.0, "hitstop_frames": 4, "knockback": Vector2(150, -55), "self_impulse": Vector2(125, 0), "hitbox_offset": Vector2(10, -26), "hitbox_size": Vector2(96, 46), "swing_style": &"gs_whirlwind", "multi_hits": 2, "has_hyper_armor": true, "arc_angle_deg": 280.0}),
		_mv({"move_id": &"gs_l4", "display_name": "Guillotine Earth-Slam", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 9, "active_frames": 6, "recovery_frames": 13, "cancel_from_frame": 12, "damage_mult": 2.25, "poise_damage": 54.0, "hitstop_frames": 8, "knockback": Vector2(350, -100), "self_impulse": Vector2(115, 0), "hitbox_offset": Vector2(40, -24), "hitbox_size": Vector2(70, 52), "swing_style": &"gs_heavy_cleave", "aoe_ring_radius": 74.0, "has_hyper_armor": true, "arc_angle_deg": 145.0}),
		_mv({"move_id": &"gs_dash", "display_name": "Battering Ram Cleave", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 5, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.80, "poise_damage": 44.0, "hitstop_frames": 6, "knockback": Vector2(310, -75), "self_impulse": Vector2(215, 0), "hitbox_offset": Vector2(36, -24), "hitbox_size": Vector2(60, 42), "swing_style": &"gs_heavy_cleave", "has_hyper_armor": true}),
		_mv({"move_id": &"gs_vault", "display_name": "Falling Guillotine", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 5, "active_frames": 6, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.95, "poise_damage": 46.0, "hitstop_frames": 6, "knockback": Vector2(260, 80), "self_impulse": Vector2(45, 70), "hitbox_offset": Vector2(30, -18), "hitbox_size": Vector2(60, 48), "swing_style": &"gs_heavy_cleave", "has_hyper_armor": true}),
		_mv({"move_id": &"gs_heavy", "display_name": "Colossus Breaker", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 10, "active_frames": 6, "recovery_frames": 13, "cancel_from_frame": 12, "damage_mult": 2.35, "poise_damage": 62.0, "hitstop_frames": 7, "knockback": Vector2(390, -100), "self_impulse": Vector2(120, 0), "hitbox_offset": Vector2(38, -26), "hitbox_size": Vector2(66, 46), "swing_style": &"gs_heavy_cleave", "has_hyper_armor": true, "arc_angle_deg": 145.0}),
		_mv({"move_id": &"gs_heavy2", "display_name": "Cataclysm Aftershock", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 8, "active_frames": 7, "recovery_frames": 14, "cancel_from_frame": 12, "damage_mult": 2.55, "poise_damage": 70.0, "hitstop_frames": 8, "knockback": Vector2(420, -120), "self_impulse": Vector2(95, 0), "hitbox_offset": Vector2(42, -20), "hitbox_size": Vector2(88, 52), "swing_style": &"gs_earth_slam", "aoe_ring_radius": 86.0, "has_hyper_armor": true}),
		_mv({"move_id": &"gs_up_heavy", "display_name": "Tectonic Crescent", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 8, "active_frames": 6, "recovery_frames": 12, "cancel_from_frame": 11, "damage_mult": 1.9, "poise_damage": 44.0, "hitstop_frames": 6, "knockback": Vector2(95, -270), "self_impulse": Vector2(40, -170), "hitbox_offset": Vector2(32, -34), "hitbox_size": Vector2(56, 56), "swing_style": &"gs_upward_rend", "is_launcher": true, "has_hyper_armor": true}),
		_mv({"move_id": &"gs_down_heavy", "display_name": "Quake Stomp", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 6, "active_frames": 6, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.85, "poise_damage": 52.0, "hitstop_frames": 6, "knockback": Vector2(220, -135), "self_impulse": Vector2(35, 0), "hitbox_offset": Vector2(18, -14), "hitbox_size": Vector2(86, 34), "swing_style": &"gs_earth_slam", "aoe_ring_radius": 76.0, "has_hyper_armor": true}),
		_mv({"move_id": &"gs_air1", "display_name": "Air Hew", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 6, "active_frames": 5, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.4, "poise_damage": 26.0, "hitstop_frames": 4, "knockback": Vector2(150, -90), "self_impulse": Vector2(20, -45), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(52, 42), "swing_style": &"gs_heavy_cleave"}),
		_mv({"move_id": &"gs_air2", "display_name": "Air Cyclone", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 5, "active_frames": 9, "recovery_frames": 10, "cancel_from_frame": 11, "damage_mult": 1.0, "poise_damage": 22.0, "hitstop_frames": 4, "knockback": Vector2(140, -70), "self_impulse": Vector2(35, -60), "hitbox_offset": Vector2(12, -22), "hitbox_size": Vector2(80, 48), "swing_style": &"gs_whirlwind", "multi_hits": 2, "arc_angle_deg": 260.0}),
		_mv({"move_id": &"gs_air3", "display_name": "Sky Crusher", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 7, "active_frames": 6, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.85, "poise_damage": 38.0, "hitstop_frames": 6, "knockback": Vector2(250, 140), "self_impulse": Vector2(40, 25), "hitbox_offset": Vector2(34, -18), "hitbox_size": Vector2(58, 48), "swing_style": &"gs_heavy_cleave", "has_hyper_armor": true}),
		_mv({"move_id": &"gs_air_heavy", "display_name": "Gravity Spike", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 8, "active_frames": 6, "recovery_frames": 12, "cancel_from_frame": 11, "damage_mult": 2.2, "poise_damage": 52.0, "hitstop_frames": 7, "knockback": Vector2(280, 180), "self_impulse": Vector2(30, 130), "hitbox_offset": Vector2(32, -16), "hitbox_size": Vector2(64, 50), "swing_style": &"gs_heavy_cleave", "has_hyper_armor": true}),
		_mv({"move_id": &"gs_launch", "display_name": "Tectonic Upper", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 8, "active_frames": 6, "recovery_frames": 12, "cancel_from_frame": 11, "damage_mult": 1.65, "poise_damage": 38.0, "hitstop_frames": 6, "knockback": Vector2(60, -280), "self_impulse": Vector2(30, -195), "hitbox_offset": Vector2(30, -36), "hitbox_size": Vector2(46, 54), "swing_style": &"gs_upward_rend", "is_launcher": true, "has_hyper_armor": true}),
		_mv({"move_id": &"gs_dive", "display_name": "Meteor Slam", "slot_tag": &"dive", "required_level": 2, "startup_frames": 5, "active_frames": 16, "recovery_frames": 13, "cancel_from_frame": 13, "damage_mult": 2.0, "poise_damage": 50.0, "hitstop_frames": 7, "knockback": Vector2(260, -80), "self_impulse": Vector2(25, 380), "hitbox_offset": Vector2(10, -14), "hitbox_size": Vector2(64, 38), "swing_style": &"gs_earth_slam", "is_dive": true, "has_hyper_armor": true}),
		_mv({"move_id": &"gs_sig", "display_name": "Elemental Fissure", "slot_tag": &"signature", "required_level": 3, "startup_frames": 9, "active_frames": 7, "recovery_frames": 13, "cancel_from_frame": 12, "damage_mult": 2.4, "poise_damage": 58.0, "hitstop_frames": 7, "knockback": Vector2(320, -120), "self_impulse": Vector2(85, 0), "hitbox_offset": Vector2(46, -24), "hitbox_size": Vector2(92, 46), "swing_style": &"gs_earth_slam", "aoe_ring_radius": 84.0, "is_signature": true, "has_hyper_armor": true, "flux_cost": 20.0}),
		_mv({"move_id": &"gs_switch", "display_name": "Shoulder Crash", "slot_tag": &"switch", "required_level": 4, "startup_frames": 3, "active_frames": 6, "recovery_frames": 9, "cancel_from_frame": 7, "damage_mult": 1.75, "poise_damage": 44.0, "hitstop_frames": 6, "knockback": Vector2(290, -70), "self_impulse": Vector2(150, 0), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(54, 40), "swing_style": &"gs_heavy_cleave", "is_switch_attack": true, "has_hyper_armor": true}),
		_mv({"move_id": &"gs_ult", "display_name": "Earthsplitter", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 11, "active_frames": 9, "recovery_frames": 16, "cancel_from_frame": 15, "damage_mult": 3.6, "poise_damage": 85.0, "hitstop_frames": 9, "knockback": Vector2(440, -150), "self_impulse": Vector2(140, 0), "hitbox_offset": Vector2(48, -32), "hitbox_size": Vector2(104, 64), "swing_style": &"gs_earth_slam", "aoe_ring_radius": 110.0, "is_ultimate": true, "has_hyper_armor": true, "flux_cost": 40.0}),
	]
	weapons[gs.id] = gs

	# 6. Tempest Recurve (Bow — Parkour Sniper & Trick-Arrow Acrobat)
	var bw := WeaponDataRes.new()
	bw.id = &"bw_tempest"
	bw.display_name = "Tempest Recurve"
	bw.weapon_type = WeaponDataRes.WeaponType.BOW
	bw.sprite_path = "res://assets/sprites/weapons/bow.png"
	bw.phys_mult = 1.00
	bw.elem_mult = 1.15
	bw.poise_mult = 0.85
	bw.speed_mult = 1.10
	bw.primary_trait = &"weakpoint_snipe"
	bw.secondary_modifier = &"piercing_trick"
	bw.counter_role = "Sky Hawker (Aerial Weakpoint)"
	bw.description = "Acrobatic parkour bow. Backflip volleys, anti-air fans, explosive trick arrows, 2.6x weakpoint."
	bw.moves = [
		_mv({"move_id": &"bw_l1", "display_name": "Snap Arrow", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 3, "active_frames": 3, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 0.95, "poise_damage": 10.0, "hitstop_frames": 2, "knockback": Vector2(90, -25), "self_impulse": Vector2(-15, 0), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(24, 20), "swing_style": &"bow_draw", "is_projectile": true, "projectile_speed": 520.0}),
		_mv({"move_id": &"bw_l2", "display_name": "Twin Nock", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 4, "active_frames": 3, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 0.72, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(100, -35), "self_impulse": Vector2(-20, 0), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(24, 20), "swing_style": &"bow_draw", "is_projectile": true, "projectile_speed": 550.0, "projectile_count": 2, "projectile_spread_deg": 10.0}),
		_mv({"move_id": &"bw_l3", "display_name": "Acrobatic Backflip Volley", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 4, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 0.70, "poise_damage": 11.0, "hitstop_frames": 3, "knockback": Vector2(125, -45), "self_impulse": Vector2(-135, -135), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(26, 22), "swing_style": &"bow_flip_shot", "is_projectile": true, "projectile_speed": 560.0, "projectile_count": 3, "projectile_spread_deg": 16.0, "projectile_pitch_deg": 12.0}),
		_mv({"move_id": &"bw_l4", "display_name": "Piercing Gale Rail", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 5, "active_frames": 4, "recovery_frames": 9, "cancel_from_frame": 7, "damage_mult": 1.65, "poise_damage": 24.0, "hitstop_frames": 5, "knockback": Vector2(210, -55), "self_impulse": Vector2(-55, 0), "hitbox_offset": Vector2(20, -24), "hitbox_size": Vector2(28, 22), "swing_style": &"bow_draw", "is_projectile": true, "projectile_speed": 740.0}),
		_mv({"move_id": &"bw_dash", "display_name": "Slide-Shot Volley", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 2, "active_frames": 4, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 0.85, "poise_damage": 11.0, "hitstop_frames": 3, "knockback": Vector2(115, -35), "self_impulse": Vector2(145, 0), "hitbox_offset": Vector2(18, -20), "hitbox_size": Vector2(26, 22), "swing_style": &"bow_slide_shot", "is_projectile": true, "projectile_speed": 580.0, "projectile_count": 2, "projectile_spread_deg": 8.0}),
		_mv({"move_id": &"bw_vault", "display_name": "Point-Blank Aerial Scatter", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 3, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 0.72, "poise_damage": 12.0, "hitstop_frames": 3, "knockback": Vector2(120, 75), "self_impulse": Vector2(-95, -135), "hitbox_offset": Vector2(18, -18), "hitbox_size": Vector2(28, 24), "swing_style": &"bow_flip_shot", "is_projectile": true, "projectile_speed": 560.0, "projectile_count": 4, "projectile_pitch_deg": 34.0, "projectile_spread_deg": 18.0}),
		_mv({"move_id": &"bw_heavy", "display_name": "Charged Rail Arrow", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 8, "active_frames": 4, "recovery_frames": 10, "cancel_from_frame": 10, "damage_mult": 2.0, "poise_damage": 28.0, "hitstop_frames": 5, "knockback": Vector2(220, -60), "self_impulse": Vector2(-65, 0), "hitbox_offset": Vector2(20, -24), "hitbox_size": Vector2(30, 22), "swing_style": &"bow_draw", "is_projectile": true, "projectile_speed": 720.0}),
		_mv({"move_id": &"bw_heavy2", "display_name": "Explosive Trick Arrow", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 6, "active_frames": 4, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 2.1, "poise_damage": 32.0, "hitstop_frames": 6, "knockback": Vector2(240, -90), "self_impulse": Vector2(-75, 0), "hitbox_offset": Vector2(20, -24), "hitbox_size": Vector2(30, 24), "swing_style": &"bow_draw", "aoe_ring_radius": 64.0, "is_projectile": true, "projectile_speed": 620.0}),
		_mv({"move_id": &"bw_up_heavy", "display_name": "Skyward Anti-Air Volley", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 0.85, "poise_damage": 14.0, "hitstop_frames": 3, "knockback": Vector2(75, -140), "self_impulse": Vector2(-25, 0), "hitbox_offset": Vector2(18, -30), "hitbox_size": Vector2(28, 28), "swing_style": &"bow_anti_air", "is_projectile": true, "projectile_speed": 610.0, "projectile_count": 3, "projectile_pitch_deg": -42.0, "projectile_spread_deg": 16.0}),
		_mv({"move_id": &"bw_down_heavy", "display_name": "Caltrop Shock Shot", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 4, "active_frames": 5, "recovery_frames": 9, "cancel_from_frame": 7, "damage_mult": 1.35, "poise_damage": 26.0, "hitstop_frames": 4, "knockback": Vector2(180, -80), "self_impulse": Vector2(-145, -85), "hitbox_offset": Vector2(26, -12), "hitbox_size": Vector2(54, 26), "swing_style": &"bow_slide_shot", "aoe_ring_radius": 58.0}),
		_mv({"move_id": &"bw_air1", "display_name": "Aerial Volley", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 3, "active_frames": 3, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 1.0, "poise_damage": 12.0, "hitstop_frames": 2, "knockback": Vector2(90, -45), "self_impulse": Vector2(-25, -75), "hitbox_offset": Vector2(18, -22), "hitbox_size": Vector2(24, 22), "swing_style": &"bow_draw", "is_projectile": true, "projectile_speed": 540.0}),
		_mv({"move_id": &"bw_air2", "display_name": "Kick-Vault Flip", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 0.90, "poise_damage": 15.0, "hitstop_frames": 3, "knockback": Vector2(140, -60), "self_impulse": Vector2(-120, -145), "hitbox_offset": Vector2(18, -22), "hitbox_size": Vector2(28, 26), "swing_style": &"bow_flip_shot", "is_projectile": true, "projectile_speed": 570.0, "projectile_count": 2, "projectile_spread_deg": 12.0}),
		_mv({"move_id": &"bw_air3", "display_name": "Hawk Down-Scatter", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 0.80, "poise_damage": 12.0, "hitstop_frames": 3, "knockback": Vector2(115, 70), "self_impulse": Vector2(-35, -90), "hitbox_offset": Vector2(18, -18), "hitbox_size": Vector2(26, 22), "swing_style": &"bow_flip_shot", "is_projectile": true, "projectile_speed": 560.0, "projectile_count": 3, "projectile_pitch_deg": 38.0, "projectile_spread_deg": 16.0}),
		_mv({"move_id": &"bw_air_heavy", "display_name": "Air Rail Snipe", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 7, "active_frames": 4, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 2.1, "poise_damage": 30.0, "hitstop_frames": 6, "knockback": Vector2(230, -50), "self_impulse": Vector2(-95, -60), "hitbox_offset": Vector2(20, -22), "hitbox_size": Vector2(30, 24), "swing_style": &"bow_draw", "is_projectile": true, "projectile_speed": 750.0}),
		_mv({"move_id": &"bw_launch", "display_name": "Skyward Arc", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 5, "active_frames": 4, "recovery_frames": 9, "cancel_from_frame": 7, "damage_mult": 1.25, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(35, -230), "self_impulse": Vector2(-45, -180), "hitbox_offset": Vector2(22, -34), "hitbox_size": Vector2(34, 48), "swing_style": &"bow_anti_air", "is_launcher": true}),
		_mv({"move_id": &"bw_dive", "display_name": "Arrow Rain Dive", "slot_tag": &"dive", "required_level": 2, "startup_frames": 4, "active_frames": 12, "recovery_frames": 10, "cancel_from_frame": 9, "damage_mult": 1.3, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(120, 90), "self_impulse": Vector2(-30, 280), "hitbox_offset": Vector2(14, -12), "hitbox_size": Vector2(36, 32), "swing_style": &"bow_flip_shot", "is_dive": true, "is_projectile": true, "projectile_speed": 480.0, "projectile_count": 3, "projectile_pitch_deg": 55.0}),
		_mv({"move_id": &"bw_sig", "display_name": "Trick Arrow Barrage", "slot_tag": &"signature", "required_level": 3, "startup_frames": 6, "active_frames": 5, "recovery_frames": 10, "cancel_from_frame": 8, "damage_mult": 1.2, "poise_damage": 20.0, "hitstop_frames": 4, "knockback": Vector2(160, -50), "self_impulse": Vector2(-95, -80), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(28, 26), "swing_style": &"bow_flip_shot", "is_signature": true, "is_projectile": true, "projectile_speed": 580.0, "projectile_count": 4, "projectile_spread_deg": 18.0, "flux_cost": 18.0}),
		_mv({"move_id": &"bw_switch", "display_name": "Backstep Volley", "slot_tag": &"switch", "required_level": 4, "startup_frames": 2, "active_frames": 4, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 1.2, "poise_damage": 16.0, "hitstop_frames": 3, "knockback": Vector2(120, -40), "self_impulse": Vector2(-130, -90), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(26, 24), "swing_style": &"bow_flip_shot", "is_switch_attack": true, "is_projectile": true, "projectile_speed": 560.0, "projectile_count": 2}),
		_mv({"move_id": &"bw_ult", "display_name": "Starlight Piercer", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 8, "active_frames": 6, "recovery_frames": 13, "cancel_from_frame": 11, "damage_mult": 2.95, "poise_damage": 42.0, "hitstop_frames": 7, "knockback": Vector2(280, -90), "self_impulse": Vector2(-110, -40), "hitbox_offset": Vector2(22, -26), "hitbox_size": Vector2(36, 30), "swing_style": &"bow_draw", "is_ultimate": true, "is_projectile": true, "projectile_speed": 780.0, "projectile_count": 3, "projectile_spread_deg": 12.0, "flux_cost": 40.0}),
	]
	weapons[bw.id] = bw

	# 7. Viper Twinlocks (Dual Pistol — Gun-Fu Acrobatics & 360 Bullet Rain)
	var dp := WeaponDataRes.new()
	dp.id = &"dp_viper"
	dp.display_name = "Viper Twinlocks"
	dp.weapon_type = WeaponDataRes.WeaponType.DUAL_PISTOL
	dp.sprite_path = "res://assets/sprites/weapons/dual_pistol.png"
	dp.phys_mult = 0.70
	dp.elem_mult = 1.15
	dp.poise_mult = 0.45
	dp.speed_mult = 1.45
	dp.primary_trait = &"active_dash_reload"
	dp.secondary_modifier = &"air_stall"
	dp.counter_role = "Blink Stalker (Rapid Interrupt)"
	dp.description = "Gun-Fu mobility pistols. Slide bursts, 360-degree Equilibrium Spins, Air-Stall & Dash-Reload."
	dp.moves = [
		_mv({"move_id": &"dp_l1", "display_name": "Snap Shot", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 2, "active_frames": 2, "recovery_frames": 5, "cancel_from_frame": 3, "damage_mult": 0.72, "poise_damage": 6.0, "hitstop_frames": 1, "knockback": Vector2(45, -10), "self_impulse": Vector2(25, 0), "hitbox_offset": Vector2(16, -24), "hitbox_size": Vector2(20, 18), "swing_style": &"pistol_snap", "is_projectile": true, "projectile_speed": 580.0}),
		_mv({"move_id": &"dp_l2", "display_name": "Twin Salvo", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 2, "active_frames": 2, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 0.65, "poise_damage": 6.0, "hitstop_frames": 1, "knockback": Vector2(55, -15), "self_impulse": Vector2(30, 0), "hitbox_offset": Vector2(16, -24), "hitbox_size": Vector2(20, 18), "swing_style": &"pistol_snap", "is_projectile": true, "projectile_speed": 600.0, "projectile_count": 2}),
		_mv({"move_id": &"dp_l3", "display_name": "Gun-Fu Slide Burst", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 3, "active_frames": 3, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 0.68, "poise_damage": 7.0, "hitstop_frames": 2, "knockback": Vector2(95, -25), "self_impulse": Vector2(165, 0), "hitbox_offset": Vector2(16, -18), "hitbox_size": Vector2(24, 20), "swing_style": &"pistol_slide", "is_projectile": true, "projectile_speed": 620.0, "projectile_count": 3, "projectile_spread_deg": 10.0}),
		_mv({"move_id": &"dp_l4", "display_name": "360 Equilibrium Spin", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 3, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 0.72, "poise_damage": 8.0, "hitstop_frames": 3, "knockback": Vector2(125, -45), "self_impulse": Vector2(0, -45), "hitbox_offset": Vector2(0, -24), "hitbox_size": Vector2(28, 26), "swing_style": &"pistol_rain_spin", "is_projectile": true, "projectile_speed": 610.0, "projectile_count": 6, "projectile_spread_deg": 360.0}),
		_mv({"move_id": &"dp_dash", "display_name": "Sliding Drive-By", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 2, "active_frames": 4, "recovery_frames": 6, "cancel_from_frame": 4, "damage_mult": 0.75, "poise_damage": 8.0, "hitstop_frames": 2, "knockback": Vector2(105, -30), "self_impulse": Vector2(190, 0), "hitbox_offset": Vector2(18, -18), "hitbox_size": Vector2(24, 20), "swing_style": &"pistol_slide", "is_projectile": true, "projectile_speed": 630.0, "projectile_count": 3, "projectile_spread_deg": 12.0}),
		_mv({"move_id": &"dp_vault", "display_name": "Inverted Hover Barrage", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 2, "active_frames": 4, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 0.68, "poise_damage": 8.0, "hitstop_frames": 2, "knockback": Vector2(90, 55), "self_impulse": Vector2(-35, -105), "hitbox_offset": Vector2(16, -20), "hitbox_size": Vector2(26, 22), "swing_style": &"pistol_rain_spin", "is_projectile": true, "projectile_speed": 600.0, "projectile_count": 4, "projectile_pitch_deg": 42.0, "projectile_spread_deg": 22.0}),
		_mv({"move_id": &"dp_heavy", "display_name": "Magnum Overcharge", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 5, "active_frames": 3, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.45, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(160, -45), "self_impulse": Vector2(-60, 0), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(26, 22), "swing_style": &"pistol_snap", "is_projectile": true, "projectile_speed": 680.0, "projectile_count": 2}),
		_mv({"move_id": &"dp_heavy2", "display_name": "Gun-Kata Shock Blast", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.65, "poise_damage": 24.0, "hitstop_frames": 5, "knockback": Vector2(210, -75), "self_impulse": Vector2(-115, -55), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(64, 44), "swing_style": &"pistol_rain_spin", "aoe_ring_radius": 68.0}),
		_mv({"move_id": &"dp_up_heavy", "display_name": "Anti-Air Twin Fan", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 3, "active_frames": 3, "recovery_frames": 7, "cancel_from_frame": 5, "damage_mult": 0.78, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(65, -135), "self_impulse": Vector2(-15, 0), "hitbox_offset": Vector2(16, -28), "hitbox_size": Vector2(24, 24), "swing_style": &"pistol_up_fan", "is_projectile": true, "projectile_speed": 620.0, "projectile_count": 3, "projectile_pitch_deg": -44.0, "projectile_spread_deg": 18.0}),
		_mv({"move_id": &"dp_down_heavy", "display_name": "Low Ricochet Slide", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 3, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 0.72, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(100, -25), "self_impulse": Vector2(180, 0), "hitbox_offset": Vector2(18, -14), "hitbox_size": Vector2(24, 20), "swing_style": &"pistol_slide", "is_projectile": true, "projectile_speed": 610.0, "projectile_count": 4, "projectile_spread_deg": 12.0}),
		_mv({"move_id": &"dp_air1", "display_name": "Air-Stall Shot", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 2, "active_frames": 2, "recovery_frames": 5, "cancel_from_frame": 3, "damage_mult": 0.72, "poise_damage": 7.0, "hitstop_frames": 1, "knockback": Vector2(45, -45), "self_impulse": Vector2(-10, -85), "hitbox_offset": Vector2(16, -22), "hitbox_size": Vector2(20, 20), "swing_style": &"pistol_snap", "is_projectile": true, "projectile_speed": 580.0}),
		_mv({"move_id": &"dp_air2", "display_name": "Gun-Fu Spin", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 3, "active_frames": 3, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 0.68, "poise_damage": 7.0, "hitstop_frames": 2, "knockback": Vector2(70, -65), "self_impulse": Vector2(0, -90), "hitbox_offset": Vector2(16, -22), "hitbox_size": Vector2(24, 24), "swing_style": &"pistol_rain_spin", "is_projectile": true, "projectile_speed": 590.0, "projectile_count": 4, "projectile_spread_deg": 360.0}),
		_mv({"move_id": &"dp_air3", "display_name": "Helix Fan", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 3, "active_frames": 3, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 0.70, "poise_damage": 8.0, "hitstop_frames": 2, "knockback": Vector2(85, 50), "self_impulse": Vector2(-20, -85), "hitbox_offset": Vector2(16, -20), "hitbox_size": Vector2(24, 22), "swing_style": &"pistol_snap", "is_projectile": true, "projectile_speed": 610.0, "projectile_count": 4, "projectile_pitch_deg": 25.0, "projectile_spread_deg": 18.0}),
		_mv({"move_id": &"dp_air_heavy", "display_name": "Aerial Magnum Blast", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 5, "active_frames": 3, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.55, "poise_damage": 20.0, "hitstop_frames": 4, "knockback": Vector2(180, -40), "self_impulse": Vector2(-95, -65), "hitbox_offset": Vector2(18, -22), "hitbox_size": Vector2(26, 22), "swing_style": &"pistol_snap", "is_projectile": true, "projectile_speed": 700.0, "projectile_count": 2}),
		_mv({"move_id": &"dp_launch", "display_name": "Rising Gun-Kick", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.15, "poise_damage": 15.0, "hitstop_frames": 3, "knockback": Vector2(25, -240), "self_impulse": Vector2(20, -195), "hitbox_offset": Vector2(22, -32), "hitbox_size": Vector2(32, 44), "swing_style": &"pistol_up_fan", "is_launcher": true}),
		_mv({"move_id": &"dp_dive", "display_name": "Helix Rain", "slot_tag": &"dive", "required_level": 2, "startup_frames": 3, "active_frames": 10, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 0.85, "poise_damage": 10.0, "hitstop_frames": 3, "knockback": Vector2(85, 70), "self_impulse": Vector2(10, 290), "hitbox_offset": Vector2(8, -12), "hitbox_size": Vector2(36, 32), "swing_style": &"pistol_rain_spin", "is_dive": true, "is_projectile": true, "projectile_speed": 520.0, "projectile_count": 4, "projectile_pitch_deg": 65.0}),
		_mv({"move_id": &"dp_sig", "display_name": "Bullet Storm", "slot_tag": &"signature", "required_level": 3, "startup_frames": 4, "active_frames": 4, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 0.72, "poise_damage": 9.0, "hitstop_frames": 3, "knockback": Vector2(110, -40), "self_impulse": Vector2(-40, -60), "hitbox_offset": Vector2(16, -24), "hitbox_size": Vector2(24, 24), "swing_style": &"pistol_rain_spin", "is_signature": true, "is_projectile": true, "projectile_speed": 640.0, "projectile_count": 6, "projectile_spread_deg": 360.0, "flux_cost": 18.0}),
		_mv({"move_id": &"dp_switch", "display_name": "Slide Gun-Fu", "slot_tag": &"switch", "required_level": 4, "startup_frames": 2, "active_frames": 4, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 0.95, "poise_damage": 12.0, "hitstop_frames": 3, "knockback": Vector2(100, -30), "self_impulse": Vector2(150, 0), "hitbox_offset": Vector2(20, -22), "hitbox_size": Vector2(28, 24), "swing_style": &"pistol_slide", "is_switch_attack": true, "is_projectile": true, "projectile_speed": 620.0, "projectile_count": 3}),
		_mv({"move_id": &"dp_ult", "display_name": "Equilibrium Barrage", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 5, "active_frames": 6, "recovery_frames": 11, "cancel_from_frame": 10, "damage_mult": 1.05, "poise_damage": 14.0, "hitstop_frames": 5, "knockback": Vector2(180, -80), "self_impulse": Vector2(-25, -90), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(36, 30), "swing_style": &"pistol_rain_spin", "is_ultimate": true, "is_projectile": true, "projectile_speed": 700.0, "projectile_count": 10, "projectile_spread_deg": 360.0, "flux_cost": 40.0}),
	]
	weapons[dp.id] = dp

	weapon_order = [
		&"ls_vanguard",
		&"kt_crimson",
		&"kt_phantom",
		&"wd_aether",
		&"gs_obsidian",
		&"bw_tempest",
		&"dp_viper",
	]


func _build_crimson_katana_moves() -> Array:
	return [
		_mv({"move_id": &"kt1_l1", "display_name": "Flash Cut", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 2, "active_frames": 3, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 0.92, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(45, -15), "self_impulse": Vector2(75, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(36, 26), "swing_style": &"kt_iaido_draw"}),
		_mv({"move_id": &"kt1_l2", "display_name": "Double Draw", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 2, "active_frames": 6, "recovery_frames": 5, "cancel_from_frame": 6, "damage_mult": 0.62, "poise_damage": 7.0, "hitstop_frames": 2, "knockback": Vector2(45, -20), "self_impulse": Vector2(95, 0), "hitbox_offset": Vector2(28, -24), "hitbox_size": Vector2(42, 30), "swing_style": &"kt_double_cross", "multi_hits": 2}),
		_mv({"move_id": &"kt1_l3", "display_name": "Crimson Rain Flurry", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 3, "active_frames": 9, "recovery_frames": 6, "cancel_from_frame": 9, "damage_mult": 0.48, "poise_damage": 6.0, "hitstop_frames": 2, "knockback": Vector2(35, -15), "self_impulse": Vector2(115, 0), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(48, 30), "swing_style": &"kt_rapid_flurry", "multi_hits": 3}),
		_mv({"move_id": &"kt1_l4", "display_name": "Iaido Blood Sheathe", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 4, "active_frames": 6, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 0.95, "poise_damage": 12.0, "hitstop_frames": 4, "knockback": Vector2(165, -55), "self_impulse": Vector2(165, 0), "hitbox_offset": Vector2(22, -24), "hitbox_size": Vector2(64, 34), "swing_style": &"kt_blink_cut", "multi_hits": 2, "blink_distance": 68.0}),
		_mv({"move_id": &"kt1_dash", "display_name": "Iai Flash-Through", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 2, "active_frames": 5, "recovery_frames": 6, "cancel_from_frame": 5, "damage_mult": 1.35, "poise_damage": 14.0, "hitstop_frames": 4, "knockback": Vector2(120, -40), "self_impulse": Vector2(180, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(58, 30), "swing_style": &"kt_blink_cut", "blink_distance": 72.0}),
		_mv({"move_id": &"kt1_vault", "display_name": "Neck-Slicer Drop", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 2, "active_frames": 6, "recovery_frames": 6, "cancel_from_frame": 6, "damage_mult": 0.85, "poise_damage": 10.0, "hitstop_frames": 3, "knockback": Vector2(110, 40), "self_impulse": Vector2(45, 25), "hitbox_offset": Vector2(24, -20), "hitbox_size": Vector2(46, 36), "swing_style": &"kt_double_cross", "multi_hits": 2}),
		_mv({"move_id": &"kt1_heavy", "display_name": "Crimson Cross", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 5, "active_frames": 6, "recovery_frames": 9, "cancel_from_frame": 9, "damage_mult": 0.88, "poise_damage": 12.0, "hitstop_frames": 4, "knockback": Vector2(150, -50), "self_impulse": Vector2(150, 0), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(50, 34), "swing_style": &"kt_double_cross", "multi_hits": 2}),
		_mv({"move_id": &"kt1_heavy2", "display_name": "Sakura Whirlwind", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 4, "active_frames": 9, "recovery_frames": 9, "cancel_from_frame": 10, "damage_mult": 0.65, "poise_damage": 10.0, "hitstop_frames": 3, "knockback": Vector2(125, -75), "self_impulse": Vector2(105, -25), "hitbox_offset": Vector2(10, -24), "hitbox_size": Vector2(76, 42), "swing_style": &"kt_spin_vortex", "multi_hits": 3, "arc_angle_deg": 260.0}),
		_mv({"move_id": &"kt1_up_heavy", "display_name": "Rising Moon Fang", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 4, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.35, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(45, -245), "self_impulse": Vector2(35, -195), "hitbox_offset": Vector2(24, -34), "hitbox_size": Vector2(40, 50), "swing_style": &"kt_rising_fang", "is_launcher": true}),
		_mv({"move_id": &"kt1_down_heavy", "display_name": "Low Iaido Slide", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 3, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.30, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(130, -90), "self_impulse": Vector2(205, 0), "hitbox_offset": Vector2(28, -12), "hitbox_size": Vector2(54, 24), "swing_style": &"kt_low_slide"}),
		_mv({"move_id": &"kt1_air1", "display_name": "Swallow Cut", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 2, "active_frames": 3, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 0.92, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(45, -95), "self_impulse": Vector2(30, -65), "hitbox_offset": Vector2(24, -22), "hitbox_size": Vector2(38, 34), "swing_style": &"kt_iaido_draw"}),
		_mv({"move_id": &"kt1_air2", "display_name": "Crescent Spin", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 3, "active_frames": 6, "recovery_frames": 6, "cancel_from_frame": 7, "damage_mult": 0.72, "poise_damage": 8.0, "hitstop_frames": 3, "knockback": Vector2(85, -80), "self_impulse": Vector2(45, -60), "hitbox_offset": Vector2(10, -22), "hitbox_size": Vector2(64, 44), "swing_style": &"kt_spin_vortex", "multi_hits": 2, "arc_angle_deg": 240.0}),
		_mv({"move_id": &"kt1_air3", "display_name": "Falling Cross", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 3, "active_frames": 6, "recovery_frames": 7, "cancel_from_frame": 7, "damage_mult": 0.78, "poise_damage": 10.0, "hitstop_frames": 3, "knockback": Vector2(135, 30), "self_impulse": Vector2(75, -35), "hitbox_offset": Vector2(26, -22), "hitbox_size": Vector2(48, 38), "swing_style": &"kt_double_cross", "multi_hits": 2}),
		_mv({"move_id": &"kt1_air_heavy", "display_name": "Sky Iaido", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 4, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.65, "poise_damage": 20.0, "hitstop_frames": 5, "knockback": Vector2(165, 95), "self_impulse": Vector2(160, 0), "hitbox_offset": Vector2(24, -20), "hitbox_size": Vector2(62, 38), "swing_style": &"kt_blink_cut", "blink_distance": 62.0}),
		_mv({"move_id": &"kt1_launch", "display_name": "Lotus Ascent", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 4, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 1.15, "poise_damage": 14.0, "hitstop_frames": 3, "knockback": Vector2(30, -260), "self_impulse": Vector2(35, -220), "hitbox_offset": Vector2(22, -34), "hitbox_size": Vector2(34, 48), "swing_style": &"kt_rising_fang", "is_launcher": true}),
		_mv({"move_id": &"kt1_dive", "display_name": "Falling Sakura", "slot_tag": &"dive", "required_level": 2, "startup_frames": 3, "active_frames": 12, "recovery_frames": 8, "cancel_from_frame": 8, "damage_mult": 1.35, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(105, 110), "self_impulse": Vector2(40, 340), "hitbox_offset": Vector2(12, -10), "hitbox_size": Vector2(36, 36), "swing_style": &"kt_iaido_draw", "is_dive": true}),
		_mv({"move_id": &"kt1_sig", "display_name": "Zantetsu Dash", "slot_tag": &"signature", "required_level": 3, "startup_frames": 4, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.9, "poise_damage": 20.0, "hitstop_frames": 5, "knockback": Vector2(130, -55), "self_impulse": Vector2(240, 0), "hitbox_offset": Vector2(32, -24), "hitbox_size": Vector2(62, 34), "swing_style": &"kt_blink_cut", "blink_distance": 80.0, "is_signature": true, "flux_cost": 16.0}),
		_mv({"move_id": &"kt1_switch", "display_name": "Cross-Hand Draw", "slot_tag": &"switch", "required_level": 4, "startup_frames": 2, "active_frames": 4, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 1.35, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(120, -40), "self_impulse": Vector2(165, 0), "hitbox_offset": Vector2(28, -24), "hitbox_size": Vector2(48, 32), "swing_style": &"kt_double_cross", "is_switch_attack": true}),
		_mv({"move_id": &"kt1_ult", "display_name": "Infinite Judgement", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 5, "active_frames": 9, "recovery_frames": 11, "cancel_from_frame": 11, "damage_mult": 1.15, "poise_damage": 14.0, "hitstop_frames": 6, "knockback": Vector2(210, -135), "self_impulse": Vector2(220, -30), "hitbox_offset": Vector2(34, -28), "hitbox_size": Vector2(78, 52), "swing_style": &"kt_rapid_flurry", "multi_hits": 3, "aoe_ring_radius": 72.0, "is_ultimate": true, "flux_cost": 36.0}),
	]


func _build_phantom_katana_moves() -> Array:
	return [
		_mv({"move_id": &"kt2_l1", "display_name": "Gale Flick", "slot_tag": &"light_1", "required_level": 1, "startup_frames": 2, "active_frames": 3, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 0.90, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(40, -25), "self_impulse": Vector2(80, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(38, 28), "swing_style": &"kt_iaido_draw"}),
		_mv({"move_id": &"kt2_l2", "display_name": "Spectral Spin", "slot_tag": &"light_2", "required_level": 1, "startup_frames": 3, "active_frames": 6, "recovery_frames": 6, "cancel_from_frame": 7, "damage_mult": 0.65, "poise_damage": 8.0, "hitstop_frames": 2, "knockback": Vector2(25, -25), "self_impulse": Vector2(85, 0), "hitbox_offset": Vector2(10, -24), "hitbox_size": Vector2(68, 42), "swing_style": &"kt_spin_vortex", "multi_hits": 2, "pull_enemies": 95.0, "arc_angle_deg": 240.0}),
		_mv({"move_id": &"kt2_l3", "display_name": "Phantom Blink Flurry", "slot_tag": &"light_3", "required_level": 1, "startup_frames": 3, "active_frames": 6, "recovery_frames": 6, "cancel_from_frame": 7, "damage_mult": 0.78, "poise_damage": 9.0, "hitstop_frames": 3, "knockback": Vector2(55, -20), "self_impulse": Vector2(120, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(56, 32), "swing_style": &"kt_blink_cut", "multi_hits": 2, "blink_distance": 76.0}),
		_mv({"move_id": &"kt2_l4", "display_name": "Vortex Sever", "slot_tag": &"light_4", "required_level": 1, "startup_frames": 4, "active_frames": 6, "recovery_frames": 8, "cancel_from_frame": 8, "damage_mult": 1.05, "poise_damage": 13.0, "hitstop_frames": 4, "knockback": Vector2(140, -75), "self_impulse": Vector2(95, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(68, 44), "swing_style": &"kt_double_cross", "multi_hits": 2, "pull_enemies": 140.0, "aoe_ring_radius": 68.0}),
		_mv({"move_id": &"kt2_dash", "display_name": "Phase Step Cut", "slot_tag": &"dash_attack", "required_level": 1, "startup_frames": 2, "active_frames": 4, "recovery_frames": 6, "cancel_from_frame": 4, "damage_mult": 1.35, "poise_damage": 14.0, "hitstop_frames": 4, "knockback": Vector2(105, -45), "self_impulse": Vector2(185, 0), "hitbox_offset": Vector2(22, -24), "hitbox_size": Vector2(60, 32), "swing_style": &"kt_blink_cut", "blink_distance": 86.0}),
		_mv({"move_id": &"kt2_vault", "display_name": "Shadow Reap", "slot_tag": &"vault_attack", "required_level": 1, "startup_frames": 2, "active_frames": 6, "recovery_frames": 6, "cancel_from_frame": 6, "damage_mult": 0.90, "poise_damage": 11.0, "hitstop_frames": 3, "knockback": Vector2(70, 20), "self_impulse": Vector2(30, 15), "hitbox_offset": Vector2(10, -22), "hitbox_size": Vector2(64, 42), "swing_style": &"kt_spin_vortex", "pull_enemies": 110.0, "arc_angle_deg": 240.0}),
		_mv({"move_id": &"kt2_heavy", "display_name": "Gale Vacuum", "slot_tag": &"heavy", "required_level": 1, "startup_frames": 5, "active_frames": 6, "recovery_frames": 9, "cancel_from_frame": 9, "damage_mult": 1.45, "poise_damage": 18.0, "hitstop_frames": 4, "knockback": Vector2(30, -55), "self_impulse": Vector2(75, 0), "hitbox_offset": Vector2(18, -24), "hitbox_size": Vector2(82, 48), "swing_style": &"kt_spin_vortex", "pull_enemies": 145.0, "arc_angle_deg": 250.0}),
		_mv({"move_id": &"kt2_heavy2", "display_name": "Dimension Slash", "slot_tag": &"heavy_2", "required_level": 1, "startup_frames": 4, "active_frames": 9, "recovery_frames": 8, "cancel_from_frame": 10, "damage_mult": 0.72, "poise_damage": 9.0, "hitstop_frames": 3, "knockback": Vector2(145, -60), "self_impulse": Vector2(150, 0), "hitbox_offset": Vector2(30, -24), "hitbox_size": Vector2(64, 38), "swing_style": &"kt_rapid_flurry", "multi_hits": 3}),
		_mv({"move_id": &"kt2_up_heavy", "display_name": "Tempest Lift", "slot_tag": &"up_heavy", "required_level": 2, "startup_frames": 4, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.35, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(25, -255), "self_impulse": Vector2(20, -200), "hitbox_offset": Vector2(24, -34), "hitbox_size": Vector2(46, 52), "swing_style": &"kt_rising_fang", "pull_enemies": 90.0, "is_launcher": true}),
		_mv({"move_id": &"kt2_down_heavy", "display_name": "Shadow Sweep", "slot_tag": &"down_heavy", "required_level": 2, "startup_frames": 3, "active_frames": 5, "recovery_frames": 8, "cancel_from_frame": 6, "damage_mult": 1.28, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(115, -100), "self_impulse": Vector2(195, 0), "hitbox_offset": Vector2(28, -12), "hitbox_size": Vector2(56, 24), "swing_style": &"kt_low_slide"}),
		_mv({"move_id": &"kt2_air1", "display_name": "Wind Slice", "slot_tag": &"air_1", "required_level": 1, "startup_frames": 2, "active_frames": 3, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 0.90, "poise_damage": 9.0, "hitstop_frames": 2, "knockback": Vector2(40, -100), "self_impulse": Vector2(30, -65), "hitbox_offset": Vector2(24, -22), "hitbox_size": Vector2(40, 34), "swing_style": &"kt_iaido_draw"}),
		_mv({"move_id": &"kt2_air2", "display_name": "Vortex Wheel", "slot_tag": &"air_2", "required_level": 1, "startup_frames": 3, "active_frames": 6, "recovery_frames": 6, "cancel_from_frame": 7, "damage_mult": 0.72, "poise_damage": 8.0, "hitstop_frames": 3, "knockback": Vector2(45, -75), "self_impulse": Vector2(35, -60), "hitbox_offset": Vector2(10, -22), "hitbox_size": Vector2(68, 46), "swing_style": &"kt_spin_vortex", "multi_hits": 2, "pull_enemies": 95.0, "arc_angle_deg": 240.0}),
		_mv({"move_id": &"kt2_air3", "display_name": "Phantom Sever", "slot_tag": &"air_3", "required_level": 1, "startup_frames": 3, "active_frames": 5, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 1.30, "poise_damage": 13.0, "hitstop_frames": 4, "knockback": Vector2(125, -40), "self_impulse": Vector2(130, -35), "hitbox_offset": Vector2(26, -22), "hitbox_size": Vector2(56, 36), "swing_style": &"kt_blink_cut", "blink_distance": 62.0}),
		_mv({"move_id": &"kt2_air_heavy", "display_name": "Astral Drop", "slot_tag": &"air_heavy", "required_level": 1, "startup_frames": 4, "active_frames": 6, "recovery_frames": 8, "cancel_from_frame": 8, "damage_mult": 0.92, "poise_damage": 12.0, "hitstop_frames": 4, "knockback": Vector2(135, 110), "self_impulse": Vector2(65, 55), "hitbox_offset": Vector2(26, -18), "hitbox_size": Vector2(52, 42), "swing_style": &"kt_double_cross", "multi_hits": 2}),
		_mv({"move_id": &"kt2_launch", "display_name": "Gale Ascent", "slot_tag": &"launcher", "required_level": 2, "startup_frames": 4, "active_frames": 4, "recovery_frames": 7, "cancel_from_frame": 6, "damage_mult": 1.15, "poise_damage": 14.0, "hitstop_frames": 3, "knockback": Vector2(30, -260), "self_impulse": Vector2(35, -220), "hitbox_offset": Vector2(22, -34), "hitbox_size": Vector2(34, 48), "swing_style": &"kt_rising_fang", "is_launcher": true}),
		_mv({"move_id": &"kt2_dive", "display_name": "Phantom Plunge", "slot_tag": &"dive", "required_level": 2, "startup_frames": 3, "active_frames": 12, "recovery_frames": 8, "cancel_from_frame": 8, "damage_mult": 1.35, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(105, 110), "self_impulse": Vector2(40, 340), "hitbox_offset": Vector2(12, -10), "hitbox_size": Vector2(36, 36), "swing_style": &"kt_blink_cut", "is_dive": true}),
		_mv({"move_id": &"kt2_sig", "display_name": "Phantom Tempest", "slot_tag": &"signature", "required_level": 3, "startup_frames": 4, "active_frames": 6, "recovery_frames": 8, "cancel_from_frame": 7, "damage_mult": 1.95, "poise_damage": 22.0, "hitstop_frames": 5, "knockback": Vector2(125, -65), "self_impulse": Vector2(230, 0), "hitbox_offset": Vector2(28, -24), "hitbox_size": Vector2(72, 42), "swing_style": &"kt_blink_cut", "blink_distance": 92.0, "pull_enemies": 135.0, "is_signature": true, "flux_cost": 16.0}),
		_mv({"move_id": &"kt2_switch", "display_name": "Vortex Draw", "slot_tag": &"switch", "required_level": 4, "startup_frames": 2, "active_frames": 4, "recovery_frames": 5, "cancel_from_frame": 4, "damage_mult": 1.35, "poise_damage": 16.0, "hitstop_frames": 4, "knockback": Vector2(95, -45), "self_impulse": Vector2(165, 0), "hitbox_offset": Vector2(24, -24), "hitbox_size": Vector2(56, 36), "swing_style": &"kt_double_cross", "pull_enemies": 115.0, "is_switch_attack": true}),
		_mv({"move_id": &"kt2_ult", "display_name": "Astral Horizon", "slot_tag": &"ultimate", "required_level": 5, "startup_frames": 5, "active_frames": 9, "recovery_frames": 11, "cancel_from_frame": 11, "damage_mult": 1.20, "poise_damage": 15.0, "hitstop_frames": 6, "knockback": Vector2(195, -145), "self_impulse": Vector2(210, -30), "hitbox_offset": Vector2(28, -28), "hitbox_size": Vector2(84, 54), "swing_style": &"kt_rapid_flurry", "multi_hits": 3, "pull_enemies": 160.0, "aoe_ring_radius": 82.0, "is_ultimate": true, "flux_cost": 36.0}),
	]


func _build_equipment_and_items() -> void:
	armors = {
		&"cloak_windwalker": {
			"id": &"cloak_windwalker",
			"name": "Windwalker Cloak",
			"max_hp_bonus": 0.0,
			"move_speed_mult": 1.12,
			"dash_mult": 1.15,
			"elem_bonus": 1.05,
			"flux_gain_mult": 1.0,
			"description": "+12% Move Speed, +15% Dash velocity, +5% Element power.",
		},
		&"plate_obsidian": {
			"id": &"plate_obsidian",
			"name": "Obsidian Brigandine",
			"max_hp_bonus": 40.0,
			"move_speed_mult": 0.96,
			"dash_mult": 1.0,
			"elem_bonus": 1.0,
			"flux_gain_mult": 1.0,
			"description": "+40 Max HP and stronger poise stability against heavy blows.",
		},
		&"robe_aether": {
			"id": &"robe_aether",
			"name": "Aether Mantle",
			"max_hp_bonus": 10.0,
			"move_speed_mult": 1.03,
			"dash_mult": 1.05,
			"elem_bonus": 1.22,
			"flux_gain_mult": 1.25,
			"description": "+22% Elemental power & +25% Flux generation.",
		},
	}

	mods = {
		&"mod_afterimage_dash": {
			"id": &"mod_afterimage_dash",
			"name": "Afterimage Slash",
			"description": "Dashing leaves a delayed elemental afterimage blade behind you.",
		},
		&"mod_launcher_shock": {
			"id": &"mod_launcher_shock",
			"name": "Rising Shockwave",
			"description": "Up+Attack Launchers emit an AoE elemental wave (+25% stagger).",
		},
		&"mod_perfect_dodge_reset": {
			"id": &"mod_perfect_dodge_reset",
			"name": "Flow Evasion",
			"description": "i-frame dodging through an attack resets Air-Dash & grants +20 Flux.",
		},
		&"mod_flux_siphon": {
			"id": &"mod_flux_siphon",
			"name": "Reaction Siphon",
			"description": "Triggering any Elemental Reaction heals +8 HP & restores +15 Flux.",
		},
	}

	items = {
		&"flask_heal": {
			"id": &"flask_heal",
			"name": "Crimson Flask",
			"max_stack": 3,
			"description": "Restores 45 HP immediately.",
		},
		&"tonic_flux": {
			"id": &"tonic_flux",
			"name": "Aether Tonic",
			"max_stack": 2,
			"description": "Restores 50 Elemental Flux.",
		},
		&"oil_overdrive": {
			"id": &"oil_overdrive",
			"name": "Edge Overdrive Oil",
			"max_stack": 2,
			"description": "+35% Elemental & Attack damage for 10s.",
		},
		&"bomb_stagger": {
			"id": &"bomb_stagger",
			"name": "Concussion Orb",
			"max_stack": 3,
			"description": "Blasts nearby enemies with current Element + heavy poise break.",
		},
	}


func _build_drop_tables() -> void:
	drop_tables = {
		&"armored_sentinel": {
			"weapon_id": &"gs_obsidian",
			"base_chance": 0.40,
			"pity_step": 0.30,
			"fallback_shards": 35,
		},
		&"barrier_wraith": {
			"weapon_id": &"kt_phantom",
			"base_chance": 0.40,
			"pity_step": 0.30,
			"fallback_shards": 35,
		},
		&"sky_hawker": {
			"weapon_id": &"bw_tempest",
			"base_chance": 0.40,
			"pity_step": 0.30,
			"fallback_shards": 35,
		},
		&"blink_stalker": {
			"weapon_id": &"dp_viper",
			"base_chance": 0.40,
			"pity_step": 0.30,
			"fallback_shards": 35,
		},
		&"agile_duelist": {
			"weapon_id": &"",
			"base_chance": 0.0,
			"pity_step": 0.0,
			"fallback_shards": 30,
		},
		&"astral_phantom": {
			"weapon_id": &"",
			"base_chance": 0.0,
			"pity_step": 0.0,
			"fallback_shards": 40,
		},
	}


func get_weapon(weapon_id: StringName) -> WeaponData:
	if weapons.has(weapon_id):
		return weapons[weapon_id]
	return weapons.get(&"ls_vanguard", null)


func get_armor(armor_id: StringName) -> Dictionary:
	return armors.get(armor_id, armors[&"cloak_windwalker"])


func get_mod(mod_id: StringName) -> Dictionary:
	return mods.get(mod_id, {})


func get_item(item_id: StringName) -> Dictionary:
	return items.get(item_id, {})
