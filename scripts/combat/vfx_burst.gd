class_name PixelVfx
extends Node2D

enum Mode {
	SLASH_ARC,
	RING,
	AFTERIMAGE,
	FLOAT_TEXT,
	THRUST_LANCE,
	HIT_SPARK,
	MUZZLE_FLASH,
	DUST_PUFF,
	RAZOR_LINE,
	MAGIC_SIGIL,
	SHELL_CASING,
}

var mode: int = Mode.RING
var life: float = 0.0
var max_life: float = 0.2
var color_main: Color = Color.WHITE
var color_sub: Color = Color.CYAN
var radius: float = 28.0
var facing: int = 1
var arc_deg: float = 100.0
var sweep_dir: int = 1
var tilt_deg: float = 0.0
var dual_arc: bool = false
var label_text: String = ""
var text_scale: float = 1.0
var velocity: Vector2 = Vector2.ZERO
var ghost_texture: Texture2D = null
var ghost_flip_h: bool = false
var _particles: Array = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 25
	if mode == Mode.HIT_SPARK:
		var base_dir := Vector2(float(facing), -0.25).normalized()
		for i in range(9):
			var spread := randf_range(-0.95, 0.95)
			var spd := randf_range(95.0, 240.0)
			_particles.append({
				"pos": Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)),
				"vel": base_dir.rotated(spread) * spd,
				"size": randf_range(2.0, 3.8),
			})
	elif mode == Mode.DUST_PUFF:
		for i in range(5):
			_particles.append({
				"pos": Vector2(randf_range(-6.0, 6.0), randf_range(-3.0, 1.0)),
				"vel": Vector2(randf_range(-42.0, 42.0) - float(facing) * 18.0, randf_range(-34.0, -8.0)),
				"size": randf_range(3.0, 5.5),
			})
	elif mode == Mode.MUZZLE_FLASH:
		for i in range(4):
			var d := Vector2(float(facing), 0.0).rotated(randf_range(-0.55, 0.55))
			_particles.append({
				"pos": Vector2.ZERO,
				"vel": d * randf_range(120.0, 210.0),
				"size": randf_range(2.0, 3.2),
			})
	elif mode == Mode.MAGIC_SIGIL:
		for i in range(6):
			var a := float(i) * (TAU / 6.0)
			_particles.append({
				"pos": Vector2.from_angle(a) * (radius * 0.35),
				"vel": Vector2.from_angle(a) * randf_range(28.0, 56.0),
				"size": randf_range(1.6, 2.6),
			})
	elif mode == Mode.SHELL_CASING:
		velocity = Vector2(-float(facing) * randf_range(38.0, 68.0), randf_range(-115.0, -75.0))


func _process(delta: float) -> void:
	life += delta
	if mode == Mode.SHELL_CASING:
		velocity.y += 380.0 * delta
	position += velocity * delta
	for p in _particles:
		var entry: Dictionary = p
		var pvel: Vector2 = entry["vel"]
		if mode == Mode.HIT_SPARK:
			pvel.y += 320.0 * delta
		elif mode == Mode.DUST_PUFF:
			pvel *= maxf(0.0, 1.0 - delta * 3.8)
		entry["vel"] = pvel
		var ppos: Vector2 = entry["pos"]
		entry["pos"] = ppos + pvel * delta

	if life >= max_life:
		queue_free()
		return
	queue_redraw()


func _draw_tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	if absf((b - a).cross(c - a)) <= 0.5:
		return
	draw_primitive(
		PackedVector2Array([a, b, c]),
		PackedColorArray([col, col, col]),
		PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	)


func _draw() -> void:
	var t := clampf(life / maxf(max_life, 0.001), 0.0, 1.0)
	var alpha := 1.0 - t * t
	match mode:
		Mode.SLASH_ARC:
			_draw_tapered_crescent(t, alpha, radius, color_main, 1.0)
			if dual_arc:
				_draw_tapered_crescent(t, alpha * 0.9, radius * 1.14, color_sub, -1.0)
		Mode.THRUST_LANCE:
			var len_x := radius * (0.9 + 0.55 * t) * float(facing)
			var half_w := maxf(2.0, 9.0 * (1.0 - t))
			var col_outer := Color(color_main.r, color_main.g, color_main.b, alpha * 0.85)
			var back_top := Vector2(-float(facing) * 10.0, -half_w * 0.45)
			var tip_top := Vector2(len_x * 0.68, -half_w)
			var tip := Vector2(len_x, 0.0)
			var tip_bot := Vector2(len_x * 0.68, half_w)
			var back_bot := Vector2(-float(facing) * 10.0, half_w * 0.45)
			_draw_tri(back_top, tip_top, tip, col_outer)
			_draw_tri(back_top, tip, tip_bot, col_outer)
			_draw_tri(back_top, tip_bot, back_bot, col_outer)
			draw_line(Vector2(-float(facing) * 4.0, 0.0), Vector2(len_x * 0.94, 0.0), Color(1, 1, 1, alpha), maxf(1.5, 3.2 * (1.0 - t)))
		Mode.HIT_SPARK:
			if t < 0.45:
				var star_r := radius * (0.55 + t * 1.3)
				var sa := (1.0 - t / 0.45)
				draw_line(Vector2(-star_r, 0), Vector2(star_r, 0), Color(1, 1, 1, sa), 3.0 * sa)
				draw_line(Vector2(0, -star_r * 0.7), Vector2(0, star_r * 0.7), Color(color_main.r, color_main.g, color_main.b, sa), 2.5 * sa)
				draw_circle(Vector2.ZERO, 4.5 * sa, Color(1, 1, 1, sa))
			for p in _particles:
				var entry: Dictionary = p
				var pos: Vector2 = entry["pos"]
				var sz: float = float(entry["size"]) * (1.0 - t * 0.5)
				draw_rect(Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(color_main.r, color_main.g, color_main.b, alpha))
				draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, alpha * 0.8))
		Mode.MUZZLE_FLASH:
			var mr := radius * (0.65 + 0.55 * t)
			var tip := Vector2(float(facing) * mr * 1.35, 0.0)
			var col_m := Color(color_main.r, color_main.g, color_main.b, alpha)
			draw_line(Vector2.ZERO, tip, col_m, 3.0 * (1.0 - t))
			draw_line(Vector2(0, -mr * 0.5), Vector2(0, mr * 0.5), Color(1, 1, 1, alpha), 2.0)
			draw_circle(Vector2(float(facing) * 3.0, 0.0), 4.0 * (1.0 - t), Color(1, 1, 1, alpha))
			for p in _particles:
				var entry: Dictionary = p
				var pos: Vector2 = entry["pos"]
				var sz: float = float(entry["size"])
				draw_rect(Rect2(pos, Vector2(sz, sz)), col_m)
		Mode.DUST_PUFF:
			for p in _particles:
				var entry: Dictionary = p
				var pos: Vector2 = entry["pos"]
				var sz: float = float(entry["size"]) * (0.85 + 0.5 * t)
				draw_rect(Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(color_main.r, color_main.g, color_main.b, alpha * 0.7))
		Mode.RING:
			var rr := radius * (0.25 + 0.85 * t)
			var col := Color(color_main.r, color_main.g, color_main.b, alpha)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 20, col, maxf(1.5, 4.0 * (1.0 - t)))
			if dual_arc:
				draw_arc(Vector2.ZERO, rr * 0.65, 0.0, TAU, 16, Color(color_sub.r, color_sub.g, color_sub.b, alpha), 2.0)
		Mode.AFTERIMAGE:
			if ghost_texture != null:
				var sz := ghost_texture.get_size()
				var rect := Rect2(-sz.x * 0.5, -sz.y, sz.x, sz.y)
				if ghost_flip_h:
					draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
				draw_texture_rect(ghost_texture, rect, false, Color(color_main.r, color_main.g, color_main.b, alpha * 0.65))
				if ghost_flip_h:
					draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))
		Mode.FLOAT_TEXT:
			var font := ThemeDB.fallback_font
			if font != null:
				var fsize := int(round(10.0 * text_scale))
				var col := Color(color_main.r, color_main.g, color_main.b, alpha)
				var shadow := Color(0.05, 0.05, 0.09, alpha)
				draw_string(font, Vector2(-24, 1), label_text, HORIZONTAL_ALIGNMENT_CENTER, 120, fsize, shadow)
				draw_string(font, Vector2(-25, 0), label_text, HORIZONTAL_ALIGNMENT_CENTER, 120, fsize, col)
		Mode.RAZOR_LINE:
			var ang := deg_to_rad(tilt_deg)
			var dir_v := Vector2.from_angle(ang)
			var nrm_v := Vector2(-dir_v.y, dir_v.x)
			var cur_len := radius * (0.72 + 0.52 * sin(t * PI * 0.65))
			var half_thick := maxf(0.8, 5.2 * (1.0 - t) * (1.0 - t))
			var p_a := -dir_v * (cur_len * 0.5)
			var p_b := dir_v * (cur_len * 0.5)
			var p_top := nrm_v * (half_thick + 1.2)
			var p_bot := -nrm_v * (half_thick + 1.2)
			var ink_r := Color(0.05, 0.06, 0.12, alpha * 0.8)
			_draw_tri(p_a, p_top, p_b, ink_r)
			_draw_tri(p_a, p_b, p_bot, ink_r)
			var f_top := nrm_v * half_thick
			var f_bot := -nrm_v * half_thick
			var elem_r := Color(color_main.r, color_main.g, color_main.b, alpha * 0.88)
			_draw_tri(p_a, f_top, p_b, elem_r)
			_draw_tri(p_a, p_b, f_bot, elem_r)
			draw_line(p_a * 0.92, p_b * 0.92, Color(1.0, 1.0, 1.0, alpha), maxf(1.2, half_thick * 0.72))
		Mode.MAGIC_SIGIL:
			var sig_r := radius * (0.35 + 0.72 * t)
			var spin := t * 2.4 * float(facing)
			var ring_col := Color(color_main.r, color_main.g, color_main.b, alpha * 0.92)
			draw_arc(Vector2.ZERO, sig_r, 0.0, TAU, 18, Color(0.05, 0.06, 0.12, alpha * 0.65), 2.4)
			draw_arc(Vector2.ZERO, sig_r, 0.0, TAU, 18, ring_col, 1.5)
			draw_arc(Vector2.ZERO, sig_r * 0.62, spin, spin + TAU, 12, Color(1.0, 1.0, 1.0, alpha * 0.85), 1.1)
			# Inscribed 4-point arcane rune diamond
			for k in range(4):
				var a0 := spin + float(k) * (PI * 0.5)
				var a1 := spin + float(k + 1) * (PI * 0.5)
				draw_line(Vector2.from_angle(a0) * sig_r * 0.85, Vector2.from_angle(a1) * sig_r * 0.85, ring_col, 1.2)
			for p in _particles:
				var entry: Dictionary = p
				var pos: Vector2 = entry["pos"]
				var sz: float = float(entry["size"]) * (1.0 - t * 0.4)
				draw_rect(Rect2(pos - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(1.0, 1.0, 1.0, alpha))
		Mode.SHELL_CASING:
			var shell_col := Color(0.95, 0.78, 0.28, alpha)
			var rot_a := life * 24.0 * float(facing)
			var p0 := Vector2(-1.5, 0.0).rotated(rot_a)
			var p1 := Vector2(1.5, 0.0).rotated(rot_a)
			draw_line(p0, p1, Color(0.08, 0.06, 0.04, alpha), 2.6)
			draw_line(p0, p1, shell_col, 1.6)


func _draw_tapered_crescent(t: float, alpha: float, rad: float, col: Color, dir_flip: float) -> void:
	var r_outer := rad * (0.82 + 0.30 * t)
	var base_angle := (0.0 if facing > 0 else PI) + deg_to_rad(tilt_deg * float(facing))
	var half_rad := deg_to_rad(arc_deg * 0.5)
	var steps := 10
	var start_a := base_angle - half_rad * float(sweep_dir) * dir_flip
	var end_a := base_angle + half_rad * float(sweep_dir) * dir_flip

	var outer_pts: Array = []
	var inner_pts: Array = []
	var ecc_offset := Vector2.from_angle(base_angle) * (-r_outer * 0.16)
	for i in range(steps + 1):
		var frac := float(i) / float(steps)
		var ang := lerpf(start_a, end_a, frac)
		# Thickness peaks near leading edge (~0.7) and tapers to zero at both tips
		var bell := sin(frac * PI)
		var thickness := r_outer * (0.34 - 0.12 * t) * bell
		var p_out := Vector2.from_angle(ang) * r_outer
		var p_in := Vector2.from_angle(ang) * maxf(4.0, r_outer - thickness) + ecc_offset * (1.0 - bell)
		outer_pts.append(p_out)
		inner_pts.append(p_in)

	var fill := Color(col.r, col.g, col.b, alpha * 0.82)
	for i in range(steps):
		var o0: Vector2 = outer_pts[i]
		var o1: Vector2 = outer_pts[i + 1]
		var in1: Vector2 = inner_pts[i + 1]
		var in0: Vector2 = inner_pts[i]
		_draw_tri(o0, o1, in1, fill)
		_draw_tri(o0, in1, in0, fill)

	# Crisp dark outer anime border + razor-sharp hot white leading rim
	draw_arc(Vector2.ZERO, r_outer * 1.01, minf(start_a, end_a), maxf(start_a, end_a), 14, Color(0.05, 0.06, 0.12, alpha * 0.75), maxf(2.0, 3.6 * (1.0 - t)))
	draw_arc(Vector2.ZERO, r_outer * 0.96, minf(start_a, end_a), maxf(start_a, end_a), 14, Color(1, 1, 1, alpha * 0.95), maxf(1.4, 2.8 * (1.0 - t)))


static func spawn_slash(parent: Node, pos: Vector2, dir: int, rad: float, deg: float, col1: Color, is_dual: bool = false, col2: Color = Color.WHITE, p_sweep_dir: int = 1, p_tilt_deg: float = 0.0) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.SLASH_ARC
	v.position = pos
	v.facing = dir
	v.radius = rad
	v.arc_deg = deg
	v.sweep_dir = p_sweep_dir
	v.tilt_deg = p_tilt_deg
	v.color_main = col1
	v.color_sub = col2
	v.dual_arc = is_dual
	v.max_life = 0.17
	parent.add_child(v)


static func spawn_thrust(parent: Node, pos: Vector2, dir: int, length: float, col1: Color) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.THRUST_LANCE
	v.position = pos
	v.facing = dir
	v.radius = length
	v.color_main = col1
	v.max_life = 0.14
	parent.add_child(v)


static func spawn_hit_spark(parent: Node, pos: Vector2, dir: int, col1: Color, rad: float = 16.0) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.HIT_SPARK
	v.position = pos
	v.facing = dir
	v.radius = rad
	v.color_main = col1
	v.max_life = 0.22
	v.z_index = 32
	parent.add_child(v)


static func spawn_muzzle_flash(parent: Node, pos: Vector2, dir: int, col1: Color, rad: float = 14.0) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.MUZZLE_FLASH
	v.position = pos
	v.facing = dir
	v.radius = rad
	v.color_main = col1
	v.max_life = 0.12
	v.z_index = 28
	parent.add_child(v)


static func spawn_dust(parent: Node, pos: Vector2, dir: int = 1, col1: Color = Color(0.72, 0.76, 0.85, 1.0)) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.DUST_PUFF
	v.position = pos
	v.facing = dir
	v.color_main = col1
	v.max_life = 0.26
	v.z_index = 12
	parent.add_child(v)


static func spawn_ring(parent: Node, pos: Vector2, rad: float, col1: Color, is_dual: bool = false, col2: Color = Color.WHITE) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.RING
	v.position = pos
	v.radius = rad
	v.color_main = col1
	v.color_sub = col2
	v.dual_arc = is_dual
	v.max_life = 0.24
	parent.add_child(v)


static func spawn_afterimage(parent: Node, pos: Vector2, tex: Texture2D, flip_h: bool, col: Color) -> void:
	if parent == null or tex == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.AFTERIMAGE
	v.position = pos
	v.ghost_texture = tex
	v.ghost_flip_h = flip_h
	v.color_main = col
	v.max_life = 0.22
	v.z_index = 8
	parent.add_child(v)


static func spawn_razor_line(parent: Node, pos: Vector2, dir: int, length: float, angle_deg: float, col1: Color) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.RAZOR_LINE
	v.position = pos
	v.facing = dir
	v.radius = length
	v.tilt_deg = angle_deg
	v.color_main = col1
	v.max_life = 0.19
	v.z_index = 30
	parent.add_child(v)


static func spawn_magic_sigil(parent: Node, pos: Vector2, dir: int, rad: float, col1: Color) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.MAGIC_SIGIL
	v.position = pos
	v.facing = dir
	v.radius = rad
	v.color_main = col1
	v.max_life = 0.24
	v.z_index = 29
	parent.add_child(v)


static func spawn_shell_casing(parent: Node, pos: Vector2, dir: int) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.SHELL_CASING
	v.position = pos
	v.facing = dir
	v.max_life = 0.34
	v.z_index = 18
	parent.add_child(v)


static func spawn_text(parent: Node, pos: Vector2, text: String, col: Color, scale_mult: float = 1.0) -> void:
	if parent == null:
		return
	var v := PixelVfx.new()
	v.mode = Mode.FLOAT_TEXT
	v.position = pos
	v.label_text = text
	v.color_main = col
	v.text_scale = scale_mult
	v.velocity = Vector2(randf_range(-12.0, 12.0), -34.0)
	v.max_life = 0.65
	v.z_index = 40
	parent.add_child(v)
