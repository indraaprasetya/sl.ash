class_name PixelRig
extends Node2D

## Heroic BlazBlue-proportioned (~52px tall) 60 FPS biomechanical pixel warrior rig.
## Drawn in canonical feet-grounded local coordinates (0, 0) inside a 144x112 SubViewport.

const THIGH_LEN := 11.4
const SHIN_LEN := 11.4
const SPINE_LEN := 15.2
const UPPER_ARM_LEN := 9.2
const FOREARM_LEN := 9.0
const TAIL_COUNT := 5
const TAIL_SEG_LEN := 5.8
const HAIR_COUNT := 3
const HAIR_SEG_LEN := 4.0

const COL_INK := Color(0.05, 0.06, 0.10, 1.0)
const COL_CLOAK_DARK := Color(0.09, 0.11, 0.20, 1.0)
const COL_CLOAK_MID := Color(0.16, 0.21, 0.35, 1.0)
const COL_CLOAK_TRIM := Color(0.32, 0.42, 0.64, 1.0)

const COL_LEG_BACK := Color(0.17, 0.20, 0.30, 1.0)
const COL_BOOT_BACK := Color(0.12, 0.14, 0.21, 1.0)
const COL_LEG_FRONT := Color(0.26, 0.31, 0.46, 1.0)
const COL_LEG_HI := Color(0.40, 0.48, 0.68, 1.0)
const COL_BOOT_FRONT := Color(0.19, 0.23, 0.33, 1.0)

const COL_ARM_BACK := Color(0.19, 0.23, 0.35, 1.0)
const COL_ARM_FRONT := Color(0.30, 0.37, 0.54, 1.0)
const COL_ARM_HI := Color(0.48, 0.57, 0.78, 1.0)
const COL_GAUNTLET := Color(0.42, 0.50, 0.69, 1.0)

const COL_VEST_RED := Color(0.56, 0.12, 0.20, 1.0)
const COL_TORSO_MID := Color(0.24, 0.29, 0.44, 1.0)
const COL_TORSO_HI := Color(0.38, 0.46, 0.65, 1.0)
const COL_BELT := Color(0.46, 0.29, 0.18, 1.0)
const COL_GOLD := Color(0.95, 0.78, 0.34, 1.0)

const COL_SKIN_SHADOW := Color(0.56, 0.44, 0.42, 1.0)
const COL_SKIN_LIT := Color(0.84, 0.69, 0.62, 1.0)
const COL_HAIR_DARK := Color(0.10, 0.12, 0.19, 1.0)
const COL_HAIR_MID := Color(0.17, 0.22, 0.34, 1.0)
const COL_HAIR_HI := Color(0.30, 0.38, 0.56, 1.0)

var _time: float = 0.0
var _stride_phase: float = 0.0
var _last_step_half: int = -1
var _footstep_pending: bool = false

var _facing: int = 1
var _weapon_type: int = WeaponData.WeaponType.LONGSWORD
var _dual_katana: bool = false
var _elem_col: Color = Color(0.35, 0.88, 1.0)
var _overdrive: bool = false
var _is_attacking: bool = false
var _move_phase: String = "NONE"
var _phase_t: float = 0.0
var _swing_style: StringName = &""
var _weapon_deg: float = 0.0
var _weapon_off: Vector2 = Vector2(9.0, -29.0)
var _body_spin_rad: float = 0.0

# Smoothed biomechanical joint state (in canonical +x = forward, y = 0 ground space)
var _pelvis: Vector2 = Vector2(0.0, -21.2)
var _torso_lean: float = 0.09
var _head_pitch: float = 0.0
var _foot_f: Vector2 = Vector2(6.5, 0.0)
var _foot_b: Vector2 = Vector2(-6.5, 0.0)
var _hand_f: Vector2 = Vector2(9.0, -29.0)
var _hand_b: Vector2 = Vector2(-4.0, -28.0)

# Solved world-local joint positions
var _knee_f: Vector2 = Vector2(5.0, -10.5)
var _knee_b: Vector2 = Vector2(-4.0, -10.5)
var _shoulder_f: Vector2 = Vector2(2.2, -35.0)
var _shoulder_b: Vector2 = Vector2(-2.6, -35.0)
var _elbow_f: Vector2 = Vector2(5.0, -29.5)
var _elbow_b: Vector2 = Vector2(-5.0, -29.5)
var _neck: Vector2 = Vector2(1.5, -38.5)
var _head_center: Vector2 = Vector2(2.0, -43.5)

# Dual split anime longcoat tails + wind-swept hair tail
var _tail_a: Array = []
var _tail_a_prev: Array = []
var _tail_b: Array = []
var _tail_b_prev: Array = []
var _hair_pts: Array = []
var _hair_prev: Array = []


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reset_chains()


func _reset_chains() -> void:
	_init_chain(_tail_a, _tail_a_prev, Vector2(-2.5, -21.5), TAIL_COUNT, TAIL_SEG_LEN, Vector2(-0.7, 0.85))
	_init_chain(_tail_b, _tail_b_prev, Vector2(0.5, -22.5), TAIL_COUNT, TAIL_SEG_LEN, Vector2(-0.9, 0.75))
	_init_chain(_hair_pts, _hair_prev, Vector2(-2.0, -45.0), HAIR_COUNT, HAIR_SEG_LEN, Vector2(-0.95, 0.30))


func _init_chain(pts: Array, prev: Array, anchor: Vector2, cnt: int, seg_len: float, dir_bias: Vector2) -> void:
	pts.clear()
	prev.clear()
	for i in range(cnt):
		var p := anchor + dir_bias * (float(i) * seg_len)
		pts.append(p)
		prev.append(p)


func consume_footstep_event() -> bool:
	if _footstep_pending:
		_footstep_pending = false
		return true
	return false


func get_main_hand_local() -> Vector2:
	var p := _apply_spin(_hand_f)
	return Vector2(p.x * float(_facing), p.y)


func get_off_hand_local() -> Vector2:
	var p := _apply_spin(_hand_b)
	return Vector2(p.x * float(_facing), p.y)


func get_neck_local() -> Vector2:
	var p := _apply_spin(_neck)
	return Vector2(p.x * float(_facing), p.y)


func update_pose(delta: float, params: Dictionary) -> void:
	var dt := clampf(delta, 0.001, 0.05)
	_time += dt

	_facing = int(params.get("facing", 1))
	_weapon_type = int(params.get("weapon_type", WeaponData.WeaponType.LONGSWORD))
	_dual_katana = bool(params.get("dual_katana", false))
	_elem_col = params.get("elem_col", Color(0.35, 0.88, 1.0)) as Color
	_overdrive = bool(params.get("overdrive", false))
	var p_state := int(params.get("state", 0))
	var vel: Vector2 = params.get("vel", Vector2.ZERO) as Vector2
	var on_floor := bool(params.get("on_floor", true))
	var wallrunning := bool(params.get("wallrunning", false))
	var land_impact := float(params.get("land_impact", 0.0))
	_move_phase = String(params.get("move_phase", "NONE"))
	_phase_t = clampf(float(params.get("phase_t", 0.0)), 0.0, 1.0)
	_swing_style = StringName(params.get("swing_style", &""))
	_weapon_deg = float(params.get("weapon_deg", 16.0))
	_weapon_off = params.get("weapon_off", Vector2(9.0, -29.0)) as Vector2
	var off_deg := float(params.get("off_deg", -128.0))
	var off_pos: Vector2 = params.get("off_pos", Vector2(-6.0, -32.0)) as Vector2
	_body_spin_rad = float(params.get("body_spin_rad", 0.0))
	_is_attacking = (p_state == 3)

	var t_pelvis := Vector2(0.0, -21.2)
	var t_lean := 0.09
	var t_head := 0.0
	var t_foot_f := Vector2(6.5, 0.0)
	var t_foot_b := Vector2(-6.5, 0.0)
	var t_hand_f := Vector2(9.0, -29.5)
	var t_hand_b := Vector2(-4.5, -28.0)
	var damp_rate := 20.0

	if p_state == 1:
		# DASH: explosive low anime sprint lunge
		damp_rate = 34.0
		t_pelvis = Vector2(4.5, -17.0)
		t_lean = 0.66
		t_head = -0.36
		t_foot_f = Vector2(13.0, -4.0)
		t_foot_b = Vector2(-17.0, -5.5)
		t_hand_f = Vector2(-7.0, -22.5)
		t_hand_b = Vector2(-12.5, -25.0)
	elif p_state == 2:
		# VAULT: tucked acrobatic parkour somersault
		damp_rate = 34.0
		t_pelvis = Vector2(0.0, -24.0)
		t_lean = 0.48
		t_head = 0.34
		t_foot_f = Vector2(7.0, -13.5)
		t_foot_b = Vector2(-4.5, -12.0)
		t_hand_f = Vector2(6.0, -26.0)
		t_hand_b = Vector2(-3.0, -24.5)
	elif p_state == 4:
		# PARRY: wide duelist guard deflect stance
		damp_rate = 32.0
		t_pelvis = Vector2(-2.0, -18.5)
		t_lean = -0.06
		t_head = 0.04
		t_foot_f = Vector2(9.5, 0.0)
		t_foot_b = Vector2(-9.5, 0.0)
		t_hand_f = Vector2(10.0, -33.0)
		t_hand_b = Vector2(5.5, -30.5)
	elif p_state == 5 or p_state == 6:
		# HITSTUN / DEAD: arched backward stagger
		damp_rate = 28.0
		t_pelvis = Vector2(-4.0, -18.2)
		t_lean = -0.45
		t_head = -0.30
		t_foot_f = Vector2(6.5, -1.0)
		t_foot_b = Vector2(-10.0, 0.0)
		t_hand_f = Vector2(7.0, -37.0)
		t_hand_b = Vector2(-11.0, -31.0)
	elif _is_attacking:
		damp_rate = 40.0
		var lunge := _compute_attack_pose(_swing_style, _move_phase, _phase_t, off_pos, off_deg)
		t_pelvis = lunge["pelvis"] as Vector2
		t_lean = float(lunge["lean"])
		t_head = float(lunge["head"])
		t_foot_f = lunge["foot_f"] as Vector2
		t_foot_b = lunge["foot_b"] as Vector2
		t_hand_f = lunge["hand_f"] as Vector2
		t_hand_b = lunge["hand_b"] as Vector2
	elif wallrunning:
		damp_rate = 28.0
		_stride_phase += maxf(150.0, vel.length()) * dt * 0.068
		var p0 := _stride_phase
		var p1 := _stride_phase + PI
		t_pelvis = Vector2(2.0, -20.5 + absf(sin(p0)) * 2.4)
		t_lean = 0.44 + clampf(vel.y / 500.0, -0.24, 0.24)
		t_head = -0.18
		t_foot_f = Vector2(sin(p0) * 11.0 + 2.0, -3.0 - maxf(0.0, cos(p0)) * 8.5)
		t_foot_b = Vector2(sin(p1) * 11.0 - 2.0, -3.0 - maxf(0.0, cos(p1)) * 8.5)
		t_hand_f = Vector2(sin(p1) * 8.0 + 5.0, -29.5 + cos(p1) * 3.0)
		t_hand_b = Vector2(sin(p0) * 8.0 - 3.0, -29.5 + cos(p0) * 3.0)
	elif not on_floor:
		damp_rate = 24.0
		var vy := vel.y
		var fwd_spd := absf(vel.x) / 225.0
		if vy < -70.0:
			t_pelvis = Vector2(1.5, -20.0)
			t_lean = 0.18 * fwd_spd + 0.08
			t_head = -0.10
			t_foot_f = Vector2(9.0, -6.8)
			t_foot_b = Vector2(-7.0, -2.0)
			t_hand_f = Vector2(10.0, -34.0)
			t_hand_b = Vector2(-7.0, -31.0)
		elif absf(vy) <= 70.0:
			t_pelvis = Vector2(0.8, -21.0)
			t_lean = 0.12
			t_head = 0.02
			t_foot_f = Vector2(8.5, -4.5)
			t_foot_b = Vector2(-8.5, -4.0)
			t_hand_f = Vector2(11.5, -32.0)
			t_hand_b = Vector2(-7.5, -32.5)
		else:
			t_pelvis = Vector2(0.0, -19.8)
			t_lean = 0.24
			t_head = 0.14
			t_foot_f = Vector2(7.0, -2.0)
			t_foot_b = Vector2(-8.0, -4.5)
			t_hand_f = Vector2(9.5, -29.0)
			t_hand_b = Vector2(-8.5, -34.0)
	elif absf(vel.x) > 16.0:
		# Grounded distance-locked athletic BlazBlue run gait
		damp_rate = 28.0
		var speed_ratio := clampf(absf(vel.x) / 225.0, 0.25, 1.55)
		_stride_phase += absf(vel.x) * dt * 0.062
		var half_step := int(floor(_stride_phase / PI))
		if half_step != _last_step_half:
			_last_step_half = half_step
			_footstep_pending = true

		var pf := _stride_phase
		var pb := _stride_phase + PI
		var lift_f := maxf(0.0, cos(pf)) * 8.4
		var lift_b := maxf(0.0, cos(pb)) * 8.4
		var bounce := cos(_stride_phase * 2.0) * 1.8
		t_pelvis = Vector2(2.8 * speed_ratio, -20.2 + bounce - land_impact * 3.4)
		t_lean = 0.28 * speed_ratio
		t_head = -0.12 * speed_ratio
		t_foot_f = Vector2(sin(pf) * 12.2 + 1.5, -lift_f)
		t_foot_b = Vector2(sin(pb) * 12.2 - 1.5, -lift_b)

		if _weapon_type == WeaponData.WeaponType.GREATSWORD:
			t_hand_f = Vector2(5.5, -31.5 + bounce * 0.6)
			t_hand_b = Vector2(-1.5, -32.0 + bounce * 0.6)
		elif _weapon_type == WeaponData.WeaponType.BOW:
			t_hand_f = Vector2(10.5, -29.5 + bounce * 0.5)
			t_hand_b = Vector2(2.0, -29.0 + bounce * 0.5)
		elif _weapon_type == WeaponData.WeaponType.KATANA:
			t_hand_f = Vector2(-5.5, -22.5 + bounce * 0.6)
			t_hand_b = Vector2(7.0, -29.5 + cos(pf) * 2.5)
		else:
			t_hand_f = Vector2(sin(pb) * 8.0 + 7.0, -29.5 + cos(pb) * 2.8)
			t_hand_b = Vector2(sin(pf) * 8.0 - 3.0, -29.5 + cos(pf) * 2.8)
	else:
		# Weapon-distinct BlazBlue idle guard stances
		damp_rate = 18.0
		_last_step_half = -1
		var breath := sin(_time * 3.1)
		var drop := land_impact * 5.2
		t_pelvis = Vector2(0.0, -21.0 + breath * 0.65 + drop)
		t_lean = 0.08 + land_impact * 0.24
		t_head = -0.02 + breath * 0.04
		t_foot_f = Vector2(7.5 + land_impact * 2.2, 0.0)
		t_foot_b = Vector2(-7.0 - land_impact * 1.8, 0.0)

		if _weapon_type == WeaponData.WeaponType.GREATSWORD:
			t_lean = 0.04
			t_hand_f = Vector2(6.0, -32.0 + breath * 0.7)
			t_hand_b = Vector2(1.0, -34.0 + breath * 0.7)
		elif _weapon_type == WeaponData.WeaponType.KATANA:
			# Low crouched Iaido stance near hip scabbard
			t_lean = 0.20 + land_impact * 0.22
			t_pelvis.y += 1.8
			t_foot_f = Vector2(9.0, 0.0)
			t_foot_b = Vector2(-8.2, 0.0)
			if _dual_katana:
				t_hand_f = Vector2(8.5, -26.5 + breath * 0.5)
				t_hand_b = Vector2(-6.5, -28.0 - breath * 0.5)
			else:
				t_hand_f = Vector2(-4.0, -22.5 + breath * 0.4)
				t_hand_b = Vector2(3.5, -24.5 + breath * 0.5)
		elif _weapon_type == WeaponData.WeaponType.BOW:
			t_lean = 0.05
			t_hand_f = Vector2(11.0, -30.5 + breath * 0.5)
			t_hand_b = Vector2(3.0, -30.5 + breath * 0.5)
		elif _weapon_type == WeaponData.WeaponType.DUAL_PISTOL:
			t_hand_f = Vector2(11.5, -30.0 + breath * 0.5)
			t_hand_b = Vector2(4.0, -31.0 - breath * 0.5)
		elif _weapon_type == WeaponData.WeaponType.WAND:
			# Harry Potter wizard duelist poise: wand raised ready at chest/shoulder
			t_lean = 0.04
			t_hand_f = Vector2(10.5, -31.0 + breath * 0.6)
			t_hand_b = Vector2(-4.5, -29.0 + cos(_time * 3.1) * 1.0)
		else:
			# Longsword technical fencing en-garde
			t_hand_f = Vector2(9.5, -29.5 + breath * 0.6)
			t_hand_b = Vector2(-5.5, -30.5 - breath * 0.5)

	var k := 1.0 - exp(-damp_rate * dt)
	_pelvis = _pelvis.lerp(t_pelvis, k)
	_torso_lean = lerpf(_torso_lean, t_lean, k)
	_head_pitch = lerpf(_head_pitch, t_head, k)
	_foot_f = _foot_f.lerp(t_foot_f, k)
	_foot_b = _foot_b.lerp(t_foot_b, k)
	_hand_f = _hand_f.lerp(t_hand_f, k)
	_hand_b = _hand_b.lerp(t_hand_b, k)

	_solve_skeleton()
	_step_chain(_tail_a, _tail_a_prev, _pelvis + Vector2(-2.8, 0.5), TAIL_COUNT, TAIL_SEG_LEN, dt, vel, 1.0)
	_step_chain(_tail_b, _tail_b_prev, _pelvis + Vector2(0.8, 1.0), TAIL_COUNT, TAIL_SEG_LEN, dt, vel, 0.72)
	_step_chain(_hair_pts, _hair_prev, _head_center + Vector2(-2.2, -1.0), HAIR_COUNT, HAIR_SEG_LEN, dt, vel, 1.25)
	queue_redraw()


func _compute_attack_pose(style: StringName, phase: String, pt: float, off_pos: Vector2, _off_deg: float) -> Dictionary:
	var pelvis := Vector2(2.5, -19.2)
	var lean := 0.24
	var head := -0.08
	var foot_f := Vector2(10.5, 0.0)
	var foot_b := Vector2(-9.0, 0.0)
	var hand_f := _weapon_off
	var hand_b := Vector2(-6.0, -28.5)

	if phase == "STARTUP":
		var coil := sin(pt * PI * 0.5)
		pelvis = Vector2(-3.0 * coil, -20.0 + 1.8 * coil)
		lean = lerpf(0.08, -0.22, coil)
		head = 0.10 * coil
		foot_f = Vector2(7.5 - 2.0 * coil, 0.0)
		foot_b = Vector2(-8.0 - 2.5 * coil, 0.0)
	elif phase == "ACTIVE":
		var snap := 1.0 - pow(1.0 - pt, 2.5)
		pelvis = Vector2(5.0 * snap, -17.8)
		lean = lerpf(-0.12, 0.40, snap)
		head = -0.14
		foot_f = Vector2(13.5, 0.0)
		foot_b = Vector2(-12.0, 0.0)
	else:
		var rec := 1.0 - pt
		pelvis = Vector2(3.4 * rec, -19.0)
		lean = 0.26 * rec + 0.08
		head = -0.05 * rec
		foot_f = Vector2(11.0 * rec + 7.5 * pt, 0.0)
		foot_b = Vector2(-10.0 * rec - 7.0 * pt, 0.0)

	# Weapon-specific martial choreography per swing_style
	match style:
		&"ls_lunge_thrust", &"ls_rapier_flurry":
			if phase == "STARTUP":
				pelvis = Vector2(-3.5, -19.5)
				lean = -0.14
			else:
				pelvis = Vector2(6.5, -17.2)
				lean = 0.46
				foot_f = Vector2(15.0, 0.0)
				foot_b = Vector2(-13.5, 0.0)
				hand_b = Vector2(-9.5, -28.0)
		&"ls_dragon_spiral", &"kt_rising_fang", &"gs_upward_rend", &"wand_sky_raise":
			if phase == "STARTUP":
				pelvis.y = -17.5
				lean = 0.30
			elif phase == "ACTIVE":
				pelvis = Vector2(3.5, -22.2)
				lean = -0.20
				head = -0.24
				foot_f = Vector2(9.0, -3.0)
		&"ls_ankle_sweep", &"kt_low_slide", &"bow_slide_shot", &"pistol_slide":
			pelvis = Vector2(5.2, -13.8)
			lean = 0.48
			foot_f = Vector2(15.5, -1.5)
			foot_b = Vector2(-13.0, 0.0)
		&"kt_iaido_draw", &"kt_blink_cut", &"kt_double_cross", &"kt_rapid_flurry":
			if phase == "STARTUP":
				# Deep crouched Iaido hand-on-scabbard coil
				pelvis = Vector2(-2.5, -17.2)
				lean = 0.34
				foot_f = Vector2(9.5, 0.0)
				foot_b = Vector2(-10.5, 0.0)
				if not _dual_katana:
					hand_f = Vector2(-4.5, -21.5)
					hand_b = Vector2(1.5, -21.5)
			elif phase == "ACTIVE":
				pelvis = Vector2(6.8, -16.8)
				lean = 0.52
				foot_f = Vector2(15.0, 0.0)
				foot_b = Vector2(-13.5, 0.0)
		&"gs_heavy_cleave", &"gs_earth_slam":
			if phase == "STARTUP":
				pelvis = Vector2(-3.5, -19.5)
				lean = -0.32
			elif phase == "ACTIVE":
				pelvis = Vector2(5.5, -16.8)
				lean = 0.52
				foot_f = Vector2(14.5, 0.0)
				foot_b = Vector2(-12.5, 0.0)
		&"wand_jab", &"wand_whip_arc", &"wand_circle_cast", &"wand_ground_point":
			# Elegant Harry Potter wizard duelist wand lunges & circular flourishing
			if phase == "STARTUP":
				pelvis = Vector2(-1.5, -20.5)
				lean = -0.06
				hand_b = Vector2(3.5, -29.0)
			elif phase == "ACTIVE":
				pelvis = Vector2(3.2, -19.5)
				lean = 0.22
				foot_f = Vector2(11.5, 0.0)
				foot_b = Vector2(-9.5, 0.0)
				hand_b = Vector2(-7.5, -31.5) if style == &"wand_jab" else Vector2(3.0, -32.0)
		&"bow_draw", &"bow_flip_shot", &"bow_anti_air":
			pelvis = Vector2(-1.5, -20.0)
			lean = -0.05 if phase == "STARTUP" else 0.14
			foot_f = Vector2(10.0, 0.0)
			foot_b = Vector2(-9.5, 0.0)
			hand_f = _weapon_off
			var pull_y := -34.5 if style == &"bow_anti_air" else -31.5
			if phase == "STARTUP":
				hand_b = Vector2(lerpf(9.5, -1.5, pt), pull_y)
			elif phase == "ACTIVE":
				hand_b = Vector2(-8.0, pull_y + 1.0)
			else:
				hand_b = Vector2(-3.5, -30.5)
			return {
				"pelvis": pelvis,
				"lean": lean,
				"head": head,
				"foot_f": foot_f,
				"foot_b": foot_b,
				"hand_f": hand_f,
				"hand_b": hand_b,
			}

	var two_handed := (_weapon_type == WeaponData.WeaponType.GREATSWORD) or (
		style in [&"ls_cross_cleave", &"ls_dragon_spiral"]
	)
	if two_handed:
		var back_grip_dir := Vector2(-cos(deg_to_rad(_weapon_deg)), -sin(deg_to_rad(_weapon_deg)))
		hand_b = hand_f + back_grip_dir * 4.2
	elif _dual_katana or _weapon_type == WeaponData.WeaponType.DUAL_PISTOL:
		hand_b = Vector2(off_pos.x, off_pos.y)
	elif _weapon_type == WeaponData.WeaponType.WAND:
		pass
	else:
		hand_b = Vector2(-9.0, -27.5) if phase == "ACTIVE" else Vector2(2.0, -27.5)

	return {
		"pelvis": pelvis,
		"lean": lean,
		"head": head,
		"foot_f": foot_f,
		"foot_b": foot_b,
		"hand_f": hand_f,
		"hand_b": hand_b,
	}


func _solve_skeleton() -> void:
	var spine_vec := Vector2(sin(_torso_lean), -cos(_torso_lean)) * SPINE_LEN
	var chest := _pelvis + spine_vec
	_neck = chest + Vector2(sin(_torso_lean) * 2.0, -2.2)
	_head_center = _neck + Vector2(sin(_torso_lean + _head_pitch) * 4.2, -4.8)

	_shoulder_f = chest + Vector2(2.0, 0.8)
	_shoulder_b = chest + Vector2(-2.6, 0.4)

	_foot_f = _clamp_reach(_pelvis + Vector2(1.5, 0.5), _foot_f, THIGH_LEN + SHIN_LEN - 0.35)
	_foot_b = _clamp_reach(_pelvis + Vector2(-1.5, 0.5), _foot_b, THIGH_LEN + SHIN_LEN - 0.35)
	_hand_f = _clamp_reach(_shoulder_f, _hand_f, UPPER_ARM_LEN + FOREARM_LEN - 0.25)
	_hand_b = _clamp_reach(_shoulder_b, _hand_b, UPPER_ARM_LEN + FOREARM_LEN - 0.25)

	_knee_f = _solve_2bone_ik(_pelvis + Vector2(1.5, 0.5), _foot_f, THIGH_LEN, SHIN_LEN, 1.0)
	_knee_b = _solve_2bone_ik(_pelvis + Vector2(-1.5, 0.5), _foot_b, THIGH_LEN, SHIN_LEN, 1.0)
	_elbow_f = _solve_2bone_ik(_shoulder_f, _hand_f, UPPER_ARM_LEN, FOREARM_LEN, -1.0)
	_elbow_b = _solve_2bone_ik(_shoulder_b, _hand_b, UPPER_ARM_LEN, FOREARM_LEN, -1.0)


func _clamp_reach(root: Vector2, target: Vector2, max_reach: float) -> Vector2:
	var d := target - root
	var dist := d.length()
	if dist > max_reach and dist > 0.001:
		return root + (d / dist) * max_reach
	return target


func _solve_2bone_ik(root: Vector2, target: Vector2, l1: float, l2: float, bend_sign: float) -> Vector2:
	var diff := target - root
	var dist := clampf(diff.length(), 0.2, l1 + l2 - 0.05)
	var base_ang := diff.angle()
	var cos_a := clampf((l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist), -1.0, 1.0)
	var ang := base_ang - bend_sign * acos(cos_a)
	return root + Vector2(cos(ang), sin(ang)) * l1


func _step_chain(pts: Array, prev: Array, anchor: Vector2, cnt: int, seg_len: float, dt: float, vel: Vector2, flutter_scale: float) -> void:
	if pts.size() < cnt:
		return
	var wind_x := -34.0 - clampf(vel.x * float(_facing), -160.0, 260.0) * 0.42
	var flutter := sin(_time * 12.0 + flutter_scale * 2.0) * (16.0 * flutter_scale)
	var grav := Vector2(wind_x, 96.0 + flutter)

	pts[0] = anchor
	prev[0] = anchor

	for i in range(1, cnt):
		var cur: Vector2 = pts[i] as Vector2
		var p_old: Vector2 = prev[i] as Vector2
		var v := (cur - p_old) * 0.78
		prev[i] = cur
		pts[i] = cur + v + grav * (dt * dt * 16.0)

	for _iter in range(3):
		pts[0] = anchor
		for i in range(1, cnt):
			var p0: Vector2 = pts[i - 1] as Vector2
			var p1: Vector2 = pts[i] as Vector2
			var d := p1 - p0
			var len_d := d.length()
			if len_d > 0.001:
				var corr := d * ((len_d - seg_len) / len_d)
				pts[i] = p1 - corr


func _apply_spin(p: Vector2) -> Vector2:
	if absf(_body_spin_rad) <= 0.001:
		return p
	return _pelvis + (p - _pelvis).rotated(_body_spin_rad)


func _xf(p: Vector2) -> Vector2:
	var q := _apply_spin(p)
	return Vector2(roundf(q.x * float(_facing)), roundf(q.y))


func _draw() -> void:
	# 1. Dual split BlazBlue longcoat tails behind silhouette
	_draw_tail_ribbon(_tail_a, COL_CLOAK_DARK, COL_CLOAK_MID)
	_draw_tail_ribbon(_tail_b, COL_CLOAK_MID, COL_CLOAK_TRIM)

	# 2. Back arm (dark shaded upper arm + forearm + gauntlet)
	_draw_limb_seg(_xf(_shoulder_b), _xf(_elbow_b), 2.2, 1.9, COL_ARM_BACK, COL_ARM_BACK.lightened(0.14))
	_draw_limb_seg(_xf(_elbow_b), _xf(_hand_b), 1.9, 1.7, COL_ARM_BACK, COL_ARM_BACK.lightened(0.18))
	draw_circle(_xf(_hand_b), 1.9, COL_ARM_BACK.lightened(0.22))

	# 3. Back leg (thigh + knee + shin + tall boot)
	_draw_limb_seg(_xf(_pelvis + Vector2(-1.5, 0.5)), _xf(_knee_b), 2.8, 2.1, COL_LEG_BACK, COL_LEG_BACK.lightened(0.15))
	_draw_limb_seg(_xf(_knee_b), _xf(_foot_b + Vector2(0.0, -2.5)), 2.1, 1.8, COL_LEG_BACK, COL_LEG_BACK.lightened(0.15))
	_draw_boot(_xf(_foot_b), COL_BOOT_BACK, COL_LEG_BACK)

	# 4. Sculpted heroic V-taper torso, vest, lapels & katana hip scabbard
	_draw_torso()

	# 5. Realistic anime head, fluttering hair tail & piercing visor eye
	_draw_head()

	# 6. Front leg with dark interior separation line so thigh stays crisp over hip/coat
	var hip_f := _xf(_pelvis + Vector2(1.5, 0.5))
	var kf := _xf(_knee_f)
	var ank_f := _xf(_foot_f + Vector2(0.0, -2.5))
	_draw_limb_ink(hip_f, kf, 3.6, 2.9)
	_draw_limb_ink(kf, ank_f, 2.9, 2.5)
	_draw_limb_seg(hip_f, kf, 2.9, 2.2, COL_LEG_FRONT, COL_LEG_HI)
	_draw_limb_seg(kf, ank_f, 2.2, 1.9, COL_LEG_FRONT, COL_LEG_HI)
	draw_circle(kf, 2.1, COL_ARM_HI)
	_draw_boot(_xf(_foot_f), COL_BOOT_FRONT, COL_LEG_HI)

	# 7. Front arm with dark interior separation line over chest
	var sf := _xf(_shoulder_f)
	var ef := _xf(_elbow_f)
	var hf := _xf(_hand_f)
	_draw_limb_ink(sf, ef, 3.0, 2.6)
	_draw_limb_ink(ef, hf, 2.6, 2.3)
	_draw_limb_seg(sf, ef, 2.3, 2.0, COL_ARM_FRONT, COL_ARM_HI)
	_draw_limb_seg(ef, hf, 2.0, 1.7, COL_ARM_FRONT, COL_ARM_HI)
	draw_circle(sf, 3.0, COL_TORSO_HI)
	draw_circle(hf, 2.0, COL_GAUNTLET)

	# 8. Contextual weapon-rig extras (bowstring + arrow, subtle wand spell spark)
	_draw_weapon_extras(hf, _xf(_hand_b))


func _draw_tail_ribbon(pts: Array, col_base: Color, col_edge: Color) -> void:
	if pts.size() < 2:
		return
	for i in range(pts.size() - 1):
		var a := _xf(pts[i] as Vector2)
		var b := _xf(pts[i + 1] as Vector2)
		var frac := float(i) / float(TAIL_COUNT - 1)
		var w0 := lerpf(3.4, 1.6, frac)
		var w1 := lerpf(2.6, 0.9, frac)
		_draw_limb_seg(a, b, w0, w1, col_base, col_edge)


func _draw_torso() -> void:
	var p_pelv := _xf(_pelvis)
	var p_neck := _xf(_neck)
	var axis := (p_neck - p_pelv)
	if axis.length() < 1.0:
		return
	var dir := axis.normalized()
	var nrm := Vector2(-dir.y, dir.x) * float(_facing)

	# Slim heroic waist -> broad anime coat shoulders
	var w_bot := 3.2
	var w_top := 5.6
	var b0 := p_pelv - nrm * w_bot
	var b1 := p_pelv + nrm * w_bot
	var t0 := p_neck - nrm * w_top
	var t1 := p_neck + nrm * w_top
	_draw_quad_tri(b0, b1, t1, t0, COL_TORSO_MID)

	# Inner crimson vest triangle + shoulder lapel highlight
	var chest_mid := p_pelv + dir * (SPINE_LEN * 0.55)
	_draw_tri(chest_mid, p_neck + nrm * 2.2, p_neck - nrm * 1.4, COL_VEST_RED)
	_draw_quad_tri(p_pelv, b1, t1, p_neck, COL_TORSO_HI)

	# Belt & gold buckle
	var waist := p_pelv + dir * 2.4
	_draw_quad_tri(p_pelv - nrm * 3.5, p_pelv + nrm * 3.5, waist + nrm * 3.5, waist - nrm * 3.5, COL_BELT)
	draw_rect(Rect2(waist.x + float(_facing) * 0.8 - 1.5, waist.y - 1.5, 3.0, 3.0), COL_GOLD)

	# Katana hip scabbard when wielding Katana
	if _weapon_type == WeaponData.WeaponType.KATANA:
		var sc_a := _xf(_pelvis + Vector2(-4.0, 2.0))
		var sc_b := _xf(_pelvis + Vector2(11.0, -3.5))
		draw_line(sc_a, sc_b, COL_INK, 3.2)
		var sc_col := Color(0.55, 0.14, 0.22) if not _dual_katana else Color(0.24, 0.65, 0.82)
		draw_line(sc_a, sc_b, sc_col, 1.8)

	# High crimson anime collar scarf wrap
	draw_line(p_neck - nrm * 4.2, p_neck + nrm * 4.2, Color(0.86, 0.20, 0.28, 1.0), 2.8)


func _draw_head() -> void:
	var hc := _xf(_head_center)
	var look := float(_facing)

	# Fluttering anime hair strands at back of head
	for i in range(_hair_pts.size() - 1):
		var a := _xf(_hair_pts[i] as Vector2)
		var b := _xf(_hair_pts[i + 1] as Vector2)
		_draw_limb_seg(a, b, 2.1, 1.0, COL_HAIR_DARK, COL_HAIR_MID)

	# Skin face & defined jawline (sleek heroic head, not cartoonishly oversized)
	draw_circle(hc + Vector2(look * 0.4, 0.5), 3.6, COL_SKIN_SHADOW)
	draw_rect(Rect2(hc.x + (0.2 if _facing > 0 else -3.4), hc.y - 1.2, 3.2, 3.8), COL_SKIN_LIT)

	# Sculpted dark hair crown + sharp anime bangs over forehead
	var crest := hc + Vector2(-look * 1.5, -2.5)
	draw_circle(crest, 3.7, COL_HAIR_MID)
	var spike_back := hc + Vector2(-look * 5.2, -1.8)
	var spike_top := hc + Vector2(-look * 0.5, -5.2)
	var bang_tip := hc + Vector2(look * 4.2, -1.6)
	_draw_tri(spike_top, spike_back, hc + Vector2(-look * 2.0, 1.2), COL_HAIR_DARK)
	_draw_tri(hc + Vector2(-look * 0.5, -4.4), bang_tip, hc + Vector2(look * 1.0, -0.8), COL_HAIR_HI)

	# Piercing glowing cyan eye streak
	var eye_col := Color(0.36, 0.94, 1.0, 1.0).lerp(_elem_col, 0.40 if _overdrive else 0.18)
	draw_rect(Rect2(hc.x + (1.2 if _facing > 0 else -3.6), hc.y - 0.6, 2.4, 1.2), eye_col)


func _draw_boot(foot_local: Vector2, boot_col: Color, trim_col: Color) -> void:
	var toe_x := foot_local.x + float(_facing) * 3.4
	var heel_x := foot_local.x - float(_facing) * 2.0
	var x_min := minf(toe_x, heel_x)
	var w := absf(toe_x - heel_x)
	draw_rect(Rect2(x_min, foot_local.y - 2.8, w, 3.0), boot_col)
	draw_rect(Rect2(x_min + 0.5, foot_local.y - 3.4, w - 1.0, 1.0), trim_col)


func _draw_weapon_extras(hf: Vector2, hb: Vector2) -> void:
	if _weapon_type == WeaponData.WeaponType.BOW and _is_attacking and (_swing_style == &"bow_draw" or _swing_style == &"bow_flip_shot" or _swing_style == &"bow_anti_air" or _swing_style == &"bow_slide_shot"):
		var bow_rot := deg_to_rad(_weapon_deg * float(_facing))
		var bow_dir := Vector2(cos(bow_rot) * float(_facing), sin(bow_rot))
		var limb_nrm := Vector2(-bow_dir.y, bow_dir.x)
		var tip_top := hf - bow_dir * 7.0 + limb_nrm * 13.0
		var tip_bot := hf - bow_dir * 7.0 - limb_nrm * 13.0
		var str_col := Color(0.86, 0.94, 1.0, 0.95)
		draw_line(tip_top, hb, str_col, 1.0)
		draw_line(hb, tip_bot, str_col, 1.0)
		if _move_phase == "STARTUP":
			var arrow_tip := hb + bow_dir * 18.0
			draw_line(hb, arrow_tip, Color.WHITE, 1.3)
			draw_circle(arrow_tip, 1.8, _elem_col)
	elif _weapon_type == WeaponData.WeaponType.WAND:
		# Slender wand focus tip glow (no bulky orb)
		var wand_rot := deg_to_rad(_weapon_deg * float(_facing))
		var wand_dir := Vector2(cos(wand_rot) * float(_facing), sin(wand_rot))
		var tip_pos := hf + wand_dir * 13.5
		var spark_r := 2.2 if _is_attacking else (1.3 + 0.35 * sin(_time * 8.0))
		draw_circle(tip_pos, spark_r, Color(_elem_col.r, _elem_col.g, _elem_col.b, 0.85))
		draw_circle(tip_pos, spark_r * 0.45, Color.WHITE)


func _draw_limb_ink(a: Vector2, b: Vector2, r_a: float, r_b: float) -> void:
	_draw_limb_seg(a, b, r_a, r_b, COL_INK, COL_INK)


func _draw_limb_seg(a: Vector2, b: Vector2, r_a: float, r_b: float, base_col: Color, hi_col: Color) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.4:
		draw_circle(a, maxf(r_a, r_b), base_col)
		return
	var dir := d / l
	var nrm := Vector2(-dir.y, dir.x)
	var p0 := a - nrm * r_a
	var p1 := a + nrm * r_a
	var p2 := b + nrm * r_b
	var p3 := b - nrm * r_b
	_draw_quad_tri(p0, p1, p2, p3, base_col)
	if hi_col != base_col:
		draw_line(a + nrm * (r_a * 0.45), b + nrm * (r_b * 0.45), hi_col, maxf(1.0, r_b * 0.65))
	draw_circle(a, r_a * 0.90, base_col)
	draw_circle(b, r_b * 0.90, base_col)


func _draw_quad_tri(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, col: Color) -> void:
	_draw_tri(p0, p1, p2, col)
	_draw_tri(p0, p2, p3, col)


func _draw_tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	if absf((b - a).cross(c - a)) <= 0.15:
		return
	var pts := PackedVector2Array([a, b, c])
	var cols := PackedColorArray([col, col, col])
	draw_primitive(pts, cols, PackedVector2Array())
