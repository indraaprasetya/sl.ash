class_name Player
extends CharacterBody2D

signal health_changed(hp: float, max_hp: float)
signal flux_changed(flux: float, max_flux: float)
signal combo_changed(combo: int, rank: String)
signal move_performed(move_name: String)
signal interact_prompt_changed(prompt: String)

enum State {
	LOCOMOTION,
	DASH,
	VAULT,
	ATTACK,
	PARRY,
	HITSTUN,
	DEAD,
}

const BASE_RUN_SPEED := 225.0
const GROUND_ACCEL := 2600.0
const GROUND_DECEL := 2800.0
const TURNAROUND_ACCEL := 3800.0
const AIR_ACCEL := 1850.0
const AIR_DRAG := 420.0
const JUMP_VEL := -348.0
const GRAVITY_UP := 980.0
const GRAVITY_DOWN := 1380.0
const MAX_FALL_SPEED := 460.0
const FAST_FALL_MAX_SPEED := 540.0
const COYOTE_TIME := 0.11
const DASH_SPEED := 440.0
const DASH_TIME := 0.15
const DASH_IFRAME_TIME := 0.12
const DASH_COOLDOWN := 0.22
const WALLRUN_SPEED := 235.0
const WALLRUN_MAX_TIME := 0.90
const BASE_DAMAGE := 20.0

var state: int = State.LOCOMOTION
var facing: int = 1
var max_hp: float = 120.0
var hp: float = 120.0
var max_flux: float = 100.0
var flux: float = 40.0
var ammo: int = 12
var max_ammo: int = 12
var overdrive_timer: float = 0.0

var hitstop_timer: float = 0.0
var coyote_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var iframe_timer: float = 0.0
var air_dash_available: bool = true
var wallrun_stamina: float = WALLRUN_MAX_TIME
var wall_jump_lock: float = 0.0

var vault_timer: float = 0.0
var vault_start: Vector2 = Vector2.ZERO
var vault_target: Vector2 = Vector2.ZERO
var vault_dir: int = 1

var parry_timer: float = 0.0
var parry_cooldown: float = 0.0
var hitstun_timer: float = 0.0

var current_move: MoveData = null
var move_frame: float = 0.0
var move_phase: String = "NONE"
var combo_step: int = 0
var heavy_step: int = 0
var combo_reset_timer: float = 0.0
var hit_confirmed: bool = false
var _attack_fired_spawn: bool = false
var _next_hit_pulse_idx: int = 0
var _hit_enemies_this_move: Dictionary = {}
var _swing_profile: Dictionary = {}
var _pistol_alt: bool = false

var combo_count: int = 0
var combo_decay_timer: float = 0.0
var debug_draw_enabled: bool = false
var _slowmo_active: bool = false

var _was_on_floor: bool = true
var _prev_vel_y: float = 0.0
var _anim_time: float = 0.0
var _run_phase: float = 0.0
var _last_run_step: int = -1
var _wallrun_dust_timer: float = 0.0
var _ledge_mantle_cooldown: float = 0.0
var _visual_scale: Vector2 = Vector2.ONE
var _scale_vel: Vector2 = Vector2.ZERO
var _visual_tilt: float = 0.0
var _swing_flash_timer: float = 0.0
var _land_impact: float = 0.0
var _prev_weapon_rot: float = 0.0
var _prev_off_rot: float = 0.0
var _trail_was_active: bool = false

var input_buffer: InputBuffer
var visual_root: Node2D
var rig_viewport: SubViewport
var pixel_rig: PixelRig
var sprite: Sprite2D
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var _hand_clasp: ColorRect
var offhand_pivot: Node2D
var offhand_weapon_sprite: Sprite2D
var body_shape: CollisionShape2D
var hurtbox: Area2D
var hitbox: Area2D
var hitbox_shape: CollisionShape2D
var wallrun_sensor: Area2D
var interact_sensor: Area2D
var _ledge_wall_ray: RayCast2D
var _ledge_clear_ray: RayCast2D

var _textures: Dictionary = {}
var _shader_mat: ShaderMaterial = null
var _weapon_shader_mat: ShaderMaterial = null
var _overlapping_wallrun: int = 0
var _nearby_interactable: Node = null
var _main_trail: BladeTrail = null
var _off_trail: BladeTrail = null
var _scarf: ScarfRibbon = null


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 0
	collision_mask = 1 | 128
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_load_textures()
	_build_nodes()
	_refresh_armor_stats()
	_refresh_visual_infusion()

	GameState.loadout_changed.connect(_on_loadout_changed)
	health_changed.emit(hp, max_hp)
	flux_changed.emit(flux, max_flux)
	combo_changed.emit(combo_count, get_style_rank())


func _load_textures() -> void:
	var pose_list := [
		"idle", "idle_0", "idle_1",
		"run", "run_0", "run_1", "run_2", "run_3",
		"air", "fall", "dash", "wallrun",
		"atk_windup", "atk_slash", "atk_up", "atk_thrust", "parry",
	]
	for pose in pose_list:
		var path := "res://assets/sprites/player/player_%s.png" % pose
		if ResourceLoader.exists(path):
			_textures[pose] = load(path)
		else:
			var img := Image.create(32, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0.3, 0.75, 0.95))
			_textures[pose] = ImageTexture.create_from_image(img)


func _build_nodes() -> void:
	body_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 44)
	body_shape.shape = rect
	body_shape.position = Vector2(0, -22)
	add_child(body_shape)

	visual_root = Node2D.new()
	add_child(visual_root)

	rig_viewport = SubViewport.new()
	rig_viewport.size = Vector2i(144, 112)
	rig_viewport.transparent_bg = true
	rig_viewport.snap_2d_transforms_to_pixel = true
	rig_viewport.snap_2d_vertices_to_pixel = true
	rig_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	rig_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	rig_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(rig_viewport)

	pixel_rig = PixelRig.new()
	pixel_rig.position = Vector2(72, 98)
	rig_viewport.add_child(pixel_rig)

	sprite = Sprite2D.new()
	sprite.texture = rig_viewport.get_texture()
	sprite.centered = false
	sprite.offset = Vector2(-72, -98)
	sprite.z_index = 1
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shader_path := "res://assets/shaders/elemental_infusion.gdshader"
	if ResourceLoader.exists(shader_path):
		var sh: Shader = load(shader_path)
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = sh
		_shader_mat.set_shader_parameter("dark_outline", true)
		sprite.material = _shader_mat
		_weapon_shader_mat = ShaderMaterial.new()
		_weapon_shader_mat.shader = sh
	visual_root.add_child(sprite)

	offhand_pivot = Node2D.new()
	offhand_pivot.position = Vector2(-6, -26)
	offhand_pivot.z_index = 0
	visual_root.add_child(offhand_pivot)

	offhand_weapon_sprite = Sprite2D.new()
	offhand_weapon_sprite.centered = false
	offhand_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	offhand_weapon_sprite.visible = false
	if _weapon_shader_mat != null:
		offhand_weapon_sprite.material = _weapon_shader_mat
	offhand_pivot.add_child(offhand_weapon_sprite)

	weapon_pivot = Node2D.new()
	weapon_pivot.position = Vector2(6, -24)
	weapon_pivot.z_index = 3
	visual_root.add_child(weapon_pivot)

	weapon_sprite = Sprite2D.new()
	weapon_sprite.centered = false
	weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _weapon_shader_mat != null:
		weapon_sprite.material = _weapon_shader_mat
	weapon_pivot.add_child(weapon_sprite)

	_hand_clasp = ColorRect.new()
	_hand_clasp.position = Vector2(-1.5, -1.5)
	_hand_clasp.size = Vector2(3.0, 3.0)
	_hand_clasp.color = Color(0.40, 0.47, 0.64, 1.0)
	_hand_clasp.z_index = 1
	weapon_pivot.add_child(_hand_clasp)

	hurtbox = Area2D.new()
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 16
	var hb_shape := CollisionShape2D.new()
	var hb_rect := RectangleShape2D.new()
	hb_rect.size = Vector2(18, 44)
	hb_shape.shape = hb_rect
	hb_shape.position = Vector2(0, -22)
	hurtbox.add_child(hb_shape)
	add_child(hurtbox)

	hitbox = Area2D.new()
	hitbox.collision_layer = 8
	hitbox.collision_mask = 4
	hitbox.monitoring = false
	hitbox_shape = CollisionShape2D.new()
	var atk_rect := RectangleShape2D.new()
	atk_rect.size = Vector2(40, 30)
	hitbox_shape.shape = atk_rect
	hitbox.add_child(hitbox_shape)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	add_child(hitbox)

	wallrun_sensor = Area2D.new()
	wallrun_sensor.collision_layer = 0
	wallrun_sensor.collision_mask = 32
	var wr_shape := CollisionShape2D.new()
	var wr_rect := RectangleShape2D.new()
	wr_rect.size = Vector2(20, 34)
	wr_shape.shape = wr_rect
	wr_shape.position = Vector2(0, -22)
	wallrun_sensor.add_child(wr_shape)
	wallrun_sensor.body_entered.connect(func(_b): _overlapping_wallrun += 1)
	wallrun_sensor.body_exited.connect(func(_b): _overlapping_wallrun = maxi(0, _overlapping_wallrun - 1))
	add_child(wallrun_sensor)

	interact_sensor = Area2D.new()
	interact_sensor.collision_layer = 0
	interact_sensor.collision_mask = 64
	var is_shape := CollisionShape2D.new()
	var is_rect := RectangleShape2D.new()
	is_rect.size = Vector2(42, 48)
	is_shape.shape = is_rect
	is_shape.position = Vector2(0, -24)
	interact_sensor.add_child(is_shape)
	interact_sensor.area_entered.connect(_on_interact_entered)
	interact_sensor.area_exited.connect(_on_interact_exited)
	add_child(interact_sensor)

	_ledge_wall_ray = RayCast2D.new()
	_ledge_wall_ray.position = Vector2(0, -22)
	_ledge_wall_ray.target_position = Vector2(15, 0)
	_ledge_wall_ray.collision_mask = 1
	add_child(_ledge_wall_ray)

	_ledge_clear_ray = RayCast2D.new()
	_ledge_clear_ray.position = Vector2(0, -40)
	_ledge_clear_ray.target_position = Vector2(15, 0)
	_ledge_clear_ray.collision_mask = 1
	add_child(_ledge_clear_ray)

	input_buffer = InputBuffer.new()
	add_child(input_buffer)


func pop_squash(target_scale: Vector2) -> void:
	_visual_scale = target_scale
	_scale_vel = Vector2.ZERO


func _ensure_trails() -> void:
	var host := get_parent()
	if host == null:
		return
	if not is_instance_valid(_main_trail) or _main_trail.get_parent() != host:
		if is_instance_valid(_main_trail):
			_main_trail.queue_free()
		_main_trail = BladeTrail.new()
		host.add_child(_main_trail)
	if not is_instance_valid(_off_trail) or _off_trail.get_parent() != host:
		if is_instance_valid(_off_trail):
			_off_trail.queue_free()
		_off_trail = BladeTrail.new()
		host.add_child(_off_trail)
	if not is_instance_valid(_scarf) or _scarf.get_parent() != host:
		if is_instance_valid(_scarf):
			_scarf.queue_free()
		_scarf = ScarfRibbon.new()
		host.add_child(_scarf)
		_scarf.reset_to(global_position + Vector2(0, -34))


func clear_trails() -> void:
	if is_instance_valid(_main_trail):
		_main_trail.clear_trail()
	if is_instance_valid(_off_trail):
		_off_trail.clear_trail()
	if is_instance_valid(_scarf):
		_scarf.reset_to(global_position + Vector2(0, -34))


func _get_weapon_geom(wtype: int) -> Dictionary:
	match wtype:
		WeaponData.WeaponType.GREATSWORD:
			return {"grip_x": 7.0, "blade_len": 41.0, "guard_x": 12.0}
		WeaponData.WeaponType.LONGSWORD:
			return {"grip_x": 6.0, "blade_len": 30.0, "guard_x": 8.0}
		WeaponData.WeaponType.KATANA:
			return {"grip_x": 6.0, "blade_len": 32.0, "guard_x": 8.0}
		WeaponData.WeaponType.BOW:
			return {"grip_x": 13.0, "blade_len": 16.0, "guard_x": 4.0}
		WeaponData.WeaponType.DUAL_PISTOL:
			return {"grip_x": 6.0, "blade_len": 18.0, "guard_x": 4.0}
		WeaponData.WeaponType.WAND:
			return {"grip_x": 3.0, "blade_len": 15.0, "guard_x": 9.0}
	return {"grip_x": 6.0, "blade_len": 28.0, "guard_x": 8.0}


func _on_interact_entered(area: Area2D) -> void:
	_nearby_interactable = area
	if area.has_meta("prompt"):
		interact_prompt_changed.emit(String(area.get_meta("prompt")))


func _on_interact_exited(area: Area2D) -> void:
	if _nearby_interactable == area:
		_nearby_interactable = null
		interact_prompt_changed.emit("")


func _on_loadout_changed() -> void:
	_refresh_armor_stats()
	_refresh_visual_infusion()


func _refresh_armor_stats() -> void:
	var armor := GameState.get_equipped_armor()
	var old_max := max_hp
	max_hp = 120.0 + float(armor.get("max_hp_bonus", 0.0))
	if max_hp > old_max:
		hp = minf(max_hp, hp + (max_hp - old_max))
	else:
		hp = minf(hp, max_hp)
	health_changed.emit(hp, max_hp)


func _refresh_visual_infusion() -> void:
	var w := GameState.get_active_weapon()
	var elem_id := GameState.get_active_element_id()
	var elem_col := ElementRegistry.get_color(elem_id)

	if w != null and ResourceLoader.exists(w.sprite_path):
		var tex: Texture2D = load(w.sprite_path)
		weapon_sprite.texture = tex
		var geom := _get_weapon_geom(w.weapon_type)
		var tex_h := tex.get_height() if tex != null else 12
		weapon_sprite.position = Vector2(-float(geom["grip_x"]), -float(tex_h) * 0.5)

	if GameState.is_dual_katana_active():
		var off := GameState.get_offhand_weapon()
		if off != null and ResourceLoader.exists(off.sprite_path):
			var off_tex: Texture2D = load(off.sprite_path)
			offhand_weapon_sprite.texture = off_tex
			var og := _get_weapon_geom(off.weapon_type)
			var oth := off_tex.get_height() if off_tex != null else 10
			offhand_weapon_sprite.position = Vector2(-float(og["grip_x"]), -float(oth) * 0.5)
			offhand_weapon_sprite.visible = true
	elif w != null and w.weapon_type == WeaponData.WeaponType.DUAL_PISTOL:
		offhand_weapon_sprite.texture = weapon_sprite.texture
		offhand_weapon_sprite.position = weapon_sprite.position
		offhand_weapon_sprite.visible = true
	else:
		offhand_weapon_sprite.visible = false

	if _shader_mat != null:
		_shader_mat.set_shader_parameter("element_color", elem_col)
		_shader_mat.set_shader_parameter("glow_strength", 1.15 if overdrive_timer > 0.0 else 0.72)
	if _weapon_shader_mat != null:
		_weapon_shader_mat.set_shader_parameter("element_color", elem_col)
		_weapon_shader_mat.set_shader_parameter("glow_strength", 1.35 if overdrive_timer > 0.0 else 0.95)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_hitbox"):
		debug_draw_enabled = not debug_draw_enabled
		HitstopManager.show_toast("Debug Hitbox Overlay: %s" % ("ON" if debug_draw_enabled else "OFF"))
	if Input.is_action_just_pressed(&"debug_slowmo"):
		_slowmo_active = not _slowmo_active
		Engine.time_scale = 0.25 if _slowmo_active else 1.0
		HitstopManager.show_toast("Audit Slow-Mo: %s" % ("0.25x" if _slowmo_active else "1.0x"))

	if Input.is_action_just_pressed(&"element_swap"):
		var new_elem := GameState.cycle_active_element()
		_refresh_visual_infusion()
		var edata := ElementRegistry.get_element(new_elem)
		SfxManager.play_sfx(&"swap", -8.0, 1.15, 1.28)
		PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 22.0, edata["color"])
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -52), String(edata["name"]).to_upper(), edata["color"], 0.9)

	if Input.is_action_just_pressed(&"interact") and _nearby_interactable != null:
		if _nearby_interactable.has_method("trigger_interact"):
			_nearby_interactable.trigger_interact(self)

	_handle_item_hotkeys()

	if debug_draw_enabled:
		queue_redraw()


func _handle_item_hotkeys() -> void:
	var item_actions := [&"item_1", &"item_2", &"item_3", &"item_4"]
	for i in range(4):
		if Input.is_action_just_pressed(item_actions[i]):
			var used_id := GameState.consume_pouch_slot(i)
			if used_id != &"":
				_apply_consumable_effect(used_id)


func _apply_consumable_effect(item_id: StringName) -> void:
	match item_id:
		&"flask_heal":
			hp = minf(max_hp, hp + 45.0)
			health_changed.emit(hp, max_hp)
			SfxManager.play_sfx(&"jump", -7.0, 1.15, 1.25)
			PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -22), 26.0, Color(0.45, 1.0, 0.55))
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -50), "+45 HP", Color(0.45, 1.0, 0.55))
		&"tonic_flux":
			_gain_flux(50.0)
			SfxManager.play_sfx(&"swing_wand", -7.0)
			PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -22), 26.0, Color(0.42, 0.88, 1.0))
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -50), "+50 FLUX", Color(0.42, 0.88, 1.0))
		&"oil_overdrive":
			overdrive_timer = 10.0
			_refresh_visual_infusion()
			SfxManager.play_sfx(&"reaction", -7.0)
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -50), "OVERDRIVE 10s!", Color(1.0, 0.72, 0.25))
		&"bomb_stagger":
			var elem_id := GameState.get_active_element_id()
			var col := ElementRegistry.get_color(elem_id)
			var aw := GameState.get_active_weapon()
			SfxManager.play_sfx(&"reaction", -4.0)
			PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -20), 92.0, col)
			HitstopManager.request_shake(0.35)
			HitstopManager.request_punch(Vector2(0, -4.0), 0.03)
			for enemy in get_tree().get_nodes_in_group(&"enemies"):
				if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= 95.0:
					enemy.take_hit({
						"damage": 28.0,
						"poise_damage": 65.0,
						"weapon_id": GameState.get_active_weapon_id(),
						"weapon_type": aw.weapon_type if aw != null else WeaponData.WeaponType.LONGSWORD,
						"element_id": elem_id,
						"secondary_element_id": &"",
						"knockback": Vector2(signf(enemy.global_position.x - global_position.x) * 180.0, -85.0),
						"attacker": self,
						"is_projectile": false,
					})


func apply_hitstop(duration: float) -> void:
	hitstop_timer = maxf(hitstop_timer, duration)


func _physics_process(delta: float) -> void:
	_anim_time += delta
	if _land_impact > 0.0:
		_land_impact = maxf(0.0, _land_impact - delta * 5.5)
	if _swing_flash_timer > 0.0:
		_swing_flash_timer = maxf(0.0, _swing_flash_timer - delta)
	if _ledge_mantle_cooldown > 0.0:
		_ledge_mantle_cooldown = maxf(0.0, _ledge_mantle_cooldown - delta)
	if overdrive_timer > 0.0:
		overdrive_timer = maxf(0.0, overdrive_timer - delta)
		if overdrive_timer == 0.0:
			_refresh_visual_infusion()
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	if parry_cooldown > 0.0:
		parry_cooldown = maxf(0.0, parry_cooldown - delta)
	if iframe_timer > 0.0:
		iframe_timer = maxf(0.0, iframe_timer - delta)
	if wall_jump_lock > 0.0:
		wall_jump_lock = maxf(0.0, wall_jump_lock - delta)
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0
			heavy_step = 0
	if combo_decay_timer > 0.0:
		combo_decay_timer -= delta
		if combo_decay_timer <= 0.0 and combo_count > 0:
			combo_count = 0
			combo_changed.emit(0, get_style_rank())

	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		visual_root.position = Vector2(randf_range(-1.6, 1.6), randf_range(-1.0, 1.0))
		return
	visual_root.position = Vector2.ZERO

	if state == State.DEAD:
		return

	if is_on_floor():
		coyote_timer = COYOTE_TIME
		air_dash_available = true
		wallrun_stamina = WALLRUN_MAX_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	match state:
		State.LOCOMOTION:
			_step_locomotion(delta)
		State.DASH:
			_step_dash(delta)
		State.VAULT:
			_step_vault(delta)
		State.ATTACK:
			_step_attack(delta)
		State.PARRY:
			_step_parry(delta)
		State.HITSTUN:
			_step_hitstun(delta)

	_prev_vel_y = velocity.y
	move_and_slide()

	if not _was_on_floor and is_on_floor() and _prev_vel_y > 110.0:
		var impact := clampf(_prev_vel_y / 420.0, 0.25, 1.0)
		_land_impact = impact
		pop_squash(Vector2(1.0 + 0.24 * impact, 1.0 - 0.20 * impact))
		PixelVfx.spawn_dust(get_parent(), global_position + Vector2(0, -1), facing, Color(0.75, 0.80, 0.90))
		SfxManager.play_sfx(&"land", -11.0 + 4.0 * impact)
	_was_on_floor = is_on_floor()

	_update_visuals(delta)
	_ensure_trails()
	if is_instance_valid(_scarf):
		var elem_col := ElementRegistry.get_color(GameState.get_active_element_id())
		var neck_world := visual_root.to_global(pixel_rig.get_neck_local()) if pixel_rig != null else (global_position + Vector2(-float(facing) * 3.0, -34.0))
		_scarf.set_anchor(neck_world, facing, elem_col, overdrive_timer > 0.0 or _swing_flash_timer > 0.0)


func _step_locomotion(delta: float) -> void:
	var armor := GameState.get_equipped_armor()
	var move_mult := float(armor.get("move_speed_mult", 1.0))
	var input_x := Input.get_axis(&"move_left", &"move_right")
	var target_speed := input_x * BASE_RUN_SPEED * move_mult

	if wall_jump_lock <= 0.0:
		if absf(input_x) > 0.1:
			var new_dir := 1 if input_x > 0.0 else -1
			var is_turning := (signf(input_x) != signf(velocity.x)) and absf(velocity.x) > 130.0
			if is_on_floor() and is_turning:
				pop_squash(Vector2(0.76, 1.12))
				PixelVfx.spawn_dust(get_parent(), global_position + Vector2(0, -1), new_dir, Color(0.72, 0.76, 0.86))
			facing = new_dir
			if is_on_floor():
				var accel := TURNAROUND_ACCEL if is_turning else GROUND_ACCEL
				if signf(velocity.x) == signf(target_speed) and absf(velocity.x) > absf(target_speed):
					velocity.x = move_toward(velocity.x, target_speed, 850.0 * delta)
				else:
					velocity.x = move_toward(velocity.x, target_speed, accel * delta)
			else:
				var in_apex := absf(velocity.y) < 60.0
				var air_a := AIR_ACCEL * (1.35 if in_apex else 1.0)
				if signf(velocity.x) == signf(target_speed) and absf(velocity.x) > absf(target_speed):
					velocity.x = move_toward(velocity.x, target_speed, AIR_DRAG * delta)
				else:
					velocity.x = move_toward(velocity.x, target_speed, air_a * delta)
		else:
			var decel := GROUND_DECEL if is_on_floor() else AIR_DRAG
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# Fluid 8-Way Background Wall-Run (Prince of Persia flow) & Wall-Slide
	var wr_input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var can_wallrun := _overlapping_wallrun > 0 and not is_on_floor() and wallrun_stamina > 0.0
	if can_wallrun and wr_input.length() > 0.12:
		wallrun_stamina = maxf(0.0, wallrun_stamina - delta)
		var target_wr_vel := wr_input.normalized() * WALLRUN_SPEED
		velocity = velocity.move_toward(target_wr_vel, 1650.0 * delta)
		if absf(wr_input.x) > 0.1:
			facing = 1 if wr_input.x > 0.0 else -1
		_wallrun_dust_timer -= delta
		if _wallrun_dust_timer <= 0.0:
			_wallrun_dust_timer = 0.08
			PixelVfx.spawn_dust(get_parent(), global_position + Vector2(0, -14), facing, Color(0.45, 0.90, 1.0))
		if input_buffer.consume(&"jump"):
			velocity.y = JUMP_VEL * 0.96
			velocity.x = (-facing * 240.0) if is_on_wall() else (facing * 235.0)
			wall_jump_lock = 0.10
			pop_squash(Vector2(0.78, 1.24))
			SfxManager.play_sfx(&"jump", -7.0)
			PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -16), 16.0, Color(0.5, 0.92, 1.0))
	else:
		# Gravity with Apex Hang Time & Fast-Fall
		var grav := GRAVITY_UP if velocity.y < 0.0 else GRAVITY_DOWN
		var max_fall := MAX_FALL_SPEED
		if not is_on_floor() and absf(velocity.y) < 60.0:
			grav *= 0.54
		elif velocity.y > 0.0 and Input.is_action_pressed(&"move_down"):
			grav *= 1.38
			max_fall = FAST_FALL_MAX_SPEED
		velocity.y = minf(max_fall, velocity.y + grav * delta)

		if is_on_wall() and velocity.y > 0.0 and not is_on_floor():
			velocity.y = minf(velocity.y, 92.0)
			if input_buffer.consume(&"jump"):
				var wall_n := get_wall_normal()
				velocity.y = JUMP_VEL * 0.96
				velocity.x = wall_n.x * 248.0
				facing = 1 if wall_n.x > 0.0 else -1
				wall_jump_lock = 0.11
				pop_squash(Vector2(0.78, 1.24))
				SfxManager.play_sfx(&"jump", -7.0)

	# Auto Ledge Mantle / Forgiveness
	_try_ledge_mantle(input_x)

	# Standard & Coyote Jump
	if coyote_timer > 0.0 and input_buffer.consume(&"jump"):
		velocity.y = JUMP_VEL
		coyote_timer = 0.0
		pop_squash(Vector2(0.80, 1.24))
		PixelVfx.spawn_dust(get_parent(), global_position + Vector2(0, -2), facing, Color(0.75, 0.80, 0.92))
		SfxManager.play_sfx(&"jump", -8.0)
	elif not Input.is_action_pressed(&"jump") and velocity.y < -120.0:
		velocity.y *= 0.65

	if _try_consume_combat_transitions(false):
		return


func _try_ledge_mantle(input_x: float) -> void:
	if is_on_floor() or _ledge_mantle_cooldown > 0.0:
		return
	if velocity.y < -80.0 or absf(input_x) < 0.1 or signf(input_x) != float(facing):
		return
	_ledge_wall_ray.target_position = Vector2(float(facing) * 15.0, 0.0)
	_ledge_clear_ray.target_position = Vector2(float(facing) * 15.0, 0.0)
	_ledge_wall_ray.force_raycast_update()
	_ledge_clear_ray.force_raycast_update()
	if _ledge_wall_ray.is_colliding() and not _ledge_clear_ray.is_colliding():
		_ledge_mantle_cooldown = 0.25
		velocity.y = -225.0
		velocity.x = float(facing) * 140.0
		pop_squash(Vector2(0.84, 1.18))
		PixelVfx.spawn_dust(get_parent(), global_position + Vector2(facing * 8.0, -16.0), facing, Color(0.78, 0.84, 0.94))
		SfxManager.play_sfx(&"jump", -11.0, 1.15, 1.25)


func _try_consume_combat_transitions(is_cancel: bool) -> bool:
	if input_buffer.peek(&"vault") and _try_start_vault():
		input_buffer.consume(&"vault")
		return true

	if input_buffer.peek(&"dash") and _can_dash():
		input_buffer.consume(&"dash")
		_start_dash()
		return true

	if input_buffer.peek(&"parry") and parry_cooldown <= 0.0:
		input_buffer.consume(&"parry")
		_start_parry()
		return true

	if input_buffer.peek(&"weapon_swap"):
		input_buffer.consume(&"weapon_swap")
		var new_slot := GameState.swap_active_weapon_slot()
		_refresh_visual_infusion()
		SfxManager.play_sfx(&"swap", -7.0)
		pop_squash(Vector2(1.12, 0.90))
		if is_cancel and hit_confirmed:
			_start_weapon_move(&"switch", true)
			return true
		var sw_wep := GameState.get_active_weapon()
		if GameState.is_dual_katana_active():
			GameState.cycle_active_element()
			_refresh_visual_infusion()
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -54), "HAND SWAP + ELEM!", ElementRegistry.get_color(GameState.get_active_element_id()), 0.85)
			if is_cancel:
				_start_weapon_move(&"switch", true)
				return true
		else:
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -50), "SWAP -> %s" % sw_wep.get_type_name().to_upper(), Color(0.85, 0.92, 1.0), 0.8)
		var _unused := new_slot

	if input_buffer.consume(&"skill"):
		var tag := &"ultimate" if Input.is_action_pressed(&"move_down") else &"signature"
		if GameState.is_dual_katana_active() and not Input.is_action_pressed(&"move_down"):
			tag = &"signature"
		if _start_weapon_move(tag):
			return true

	if input_buffer.consume(&"heavy"):
		if _start_weapon_move(_pick_heavy_tag()):
			return true

	if input_buffer.consume(&"attack"):
		var tag := _pick_attack_tag()
		if _start_weapon_move(tag):
			return true

	return false


func _pick_attack_tag() -> StringName:
	if Input.is_action_pressed(&"move_up"):
		return &"launcher"
	if Input.is_action_pressed(&"move_down") and not is_on_floor():
		return &"dive"
	if not is_on_floor():
		var air_step := combo_step % 3
		if air_step == 1:
			return &"air_2"
		elif air_step == 2:
			return &"air_3"
		return &"air_1"
	var step := combo_step % 4
	if step == 1:
		return &"light_2"
	elif step == 2:
		return &"light_3"
	elif step == 3:
		return &"light_4"
	return &"light_1"


func _pick_heavy_tag() -> StringName:
	if not is_on_floor():
		return &"air_heavy"
	if Input.is_action_pressed(&"move_up"):
		return &"up_heavy"
	if Input.is_action_pressed(&"move_down"):
		return &"down_heavy"
	if heavy_step >= 1 or (combo_step >= 2 and combo_reset_timer > 0.0):
		return &"heavy_2"
	return &"heavy"


func _can_dash() -> bool:
	if dash_cooldown_timer > 0.0:
		return false
	if is_on_floor() or _overlapping_wallrun > 0:
		return true
	return air_dash_available


func _start_dash() -> void:
	hitbox.monitoring = false
	current_move = null
	if not is_on_floor() and _overlapping_wallrun == 0:
		air_dash_available = false
	var input_x := Input.get_axis(&"move_left", &"move_right")
	if absf(input_x) > 0.1:
		facing = 1 if input_x > 0.0 else -1
	state = State.DASH
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN
	iframe_timer = DASH_IFRAME_TIME
	var dash_mult := float(GameState.get_equipped_armor().get("dash_mult", 1.0))
	velocity = Vector2(facing * DASH_SPEED * dash_mult, 0.0)
	pop_squash(Vector2(1.28, 0.78))
	SfxManager.play_sfx(&"dash", -6.5)
	PixelVfx.spawn_dust(get_parent(), global_position + Vector2(-facing * 8.0, -4.0), facing, Color(0.82, 0.88, 0.96))

	var active_w := GameState.get_active_weapon()
	if active_w != null and active_w.weapon_type == WeaponData.WeaponType.DUAL_PISTOL:
		ammo = max_ammo
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -52), "ACTIVE RELOAD!", Color(0.55, 0.95, 1.0), 0.85)

	var elem_col := ElementRegistry.get_color(GameState.get_active_element_id())
	var after_tex: Texture2D = _textures.get("dash", null)
	if after_tex != null:
		PixelVfx.spawn_afterimage(get_parent(), global_position, after_tex, facing < 0, elem_col)

	if GameState.has_mod(&"mod_afterimage_dash"):
		_trigger_afterimage_slash(elem_col)


func _trigger_afterimage_slash(elem_col: Color) -> void:
	var origin := global_position + Vector2(0, -24)
	var aw := GameState.get_active_weapon()
	PixelVfx.spawn_slash(get_parent(), origin, facing, 32.0, 100.0, elem_col, false, Color.WHITE, 1, 0.0)
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= 44.0:
			enemy.take_hit({
				"damage": 14.0,
				"poise_damage": 12.0,
				"weapon_id": GameState.get_active_weapon_id(),
				"weapon_type": aw.weapon_type if aw != null else WeaponData.WeaponType.LONGSWORD,
				"element_id": GameState.get_active_element_id(),
				"secondary_element_id": &"",
				"knockback": Vector2(facing * 75.0, -30.0),
				"attacker": self,
				"is_projectile": false,
			})


func _step_dash(delta: float) -> void:
	dash_timer -= delta
	var dash_elapsed := DASH_TIME - dash_timer

	# Dash-Jump (Wavedash) preserves boosted horizontal launch
	if input_buffer.consume(&"jump"):
		state = State.LOCOMOTION
		velocity = Vector2(float(facing) * BASE_RUN_SPEED * 1.48, JUMP_VEL * 0.96)
		coyote_timer = 0.0
		pop_squash(Vector2(0.78, 1.26))
		PixelVfx.spawn_dust(get_parent(), global_position + Vector2(0, -2), facing, Color(0.85, 0.90, 0.98))
		SfxManager.play_sfx(&"jump", -7.5)
		return

	# Dash-Slash cancel after initial 40ms burst
	if dash_elapsed >= 0.04:
		if input_buffer.consume(&"heavy") and _start_weapon_move(_pick_heavy_tag()):
			return
		if input_buffer.consume(&"attack") and _start_weapon_move(&"dash_attack"):
			return

	if int(dash_timer * 60.0) % 3 == 0:
		PixelVfx.spawn_afterimage(get_parent(), global_position, _textures["dash"], facing < 0, ElementRegistry.get_color(GameState.get_active_element_id()))

	if dash_timer <= 0.0:
		state = State.LOCOMOTION
		var ix := Input.get_axis(&"move_left", &"move_right")
		if absf(ix) > 0.1 and signf(ix) == float(facing):
			velocity.x = float(facing) * BASE_RUN_SPEED * 1.24
		else:
			velocity.x *= 0.65


func _try_start_vault() -> bool:
	var nearest: Node2D = null
	var best_dist := 64.0
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d <= best_dist:
			best_dist = d
			nearest = enemy
	if nearest == null:
		return false

	hitbox.monitoring = false
	current_move = null
	state = State.VAULT
	vault_timer = 0.0
	vault_start = global_position
	vault_dir = 1 if nearest.global_position.x >= global_position.x else -1
	vault_target = nearest.global_position + Vector2(vault_dir * 34.0, 0.0)
	facing = -vault_dir
	iframe_timer = 0.22
	air_dash_available = true
	wallrun_stamina = WALLRUN_MAX_TIME
	ammo = max_ammo
	SfxManager.play_sfx(&"vault", -6.5)
	if nearest.has_method("apply_micro_stun"):
		nearest.apply_micro_stun(0.55)
	PixelVfx.spawn_ring(get_parent(), nearest.global_position + Vector2(0, -24), 24.0, Color(1.0, 0.88, 0.35))
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -54), "VAULT RESET!", Color(1.0, 0.9, 0.35), 0.9)
	return true


func _step_vault(delta: float) -> void:
	vault_timer += delta
	var t := clampf(vault_timer / 0.18, 0.0, 1.0)
	var pos := vault_start.lerp(vault_target, t)
	pos.y -= sin(t * PI) * 34.0
	velocity = (pos - global_position) / maxf(delta, 0.001)

	# Early Vault Cancel past 45% arc for aggressive air follow-ups
	if t >= 0.45:
		if input_buffer.consume(&"jump"):
			state = State.LOCOMOTION
			sprite.rotation = 0.0
			velocity = Vector2(-float(vault_dir) * 80.0, JUMP_VEL * 0.90)
			pop_squash(Vector2(0.80, 1.24))
			SfxManager.play_sfx(&"jump", -7.5)
			return
		if input_buffer.consume(&"attack") and _start_weapon_move(&"vault_attack"):
			sprite.rotation = 0.0
			return
		if input_buffer.consume(&"heavy") and _start_weapon_move(&"vault_attack"):
			sprite.rotation = 0.0
			return
		if _try_consume_combat_transitions(false):
			sprite.rotation = 0.0
			return

	if t >= 1.0:
		state = State.LOCOMOTION
		sprite.rotation = 0.0
		velocity = Vector2(-vault_dir * 65.0, -50.0)


func _start_parry() -> void:
	if GameState.is_dual_katana_active():
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -52), "DUAL KATANA: DODGE/VAULT ONLY", Color(1.0, 0.55, 0.45), 0.8)
		parry_cooldown = 0.25
		return
	hitbox.monitoring = false
	current_move = null
	state = State.PARRY
	parry_timer = 0.24
	parry_cooldown = 0.45
	velocity.x *= 0.25
	pop_squash(Vector2(0.92, 1.08))
	SfxManager.play_sfx(&"swap", -8.0, 1.2, 1.35)
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 22.0, Color(1.0, 0.92, 0.45))


func _step_parry(delta: float) -> void:
	parry_timer -= delta
	velocity.y = minf(MAX_FALL_SPEED, velocity.y + GRAVITY_DOWN * delta)
	if parry_timer <= 0.0:
		state = State.LOCOMOTION


func _build_swing_profile(weapon: WeaponData, mv: MoveData) -> Dictionary:
	var wtype := weapon.weapon_type
	var style := mv.swing_style
	var is_thrust := false
	var is_double_cross := false
	var is_flurry := false
	var body_spin_dir := 0
	var windup_deg := -130.0
	var sweep_end_deg := 70.0
	var overshoot_deg := 14.0
	var sweep_dir := 1
	var tilt_deg := 0.0
	var thrust_dist := 0.0
	var windup_off := Vector2(-7.0, -33.0)
	var active_off := Vector2(15.0, -29.0)
	var vfx_kind := &"slash"

	match style:
		# --- Longsword (Fencing Duelist) ---
		&"ls_fencing_slash":
			windup_deg = -132.0
			sweep_end_deg = 68.0
			overshoot_deg = 14.0
			sweep_dir = 1
			windup_off = Vector2(-6.0, -34.0)
			active_off = Vector2(16.0, -29.0)
			vfx_kind = &"slash"
		&"ls_reverse_cut":
			windup_deg = 115.0
			sweep_end_deg = -104.0
			overshoot_deg = -14.0
			sweep_dir = -1
			windup_off = Vector2(-4.0, -24.0)
			active_off = Vector2(16.0, -36.0)
			vfx_kind = &"slash"
		&"ls_rapier_flurry":
			is_thrust = true
			is_flurry = true
			windup_deg = -18.0
			sweep_end_deg = 14.0
			overshoot_deg = 4.0
			thrust_dist = 15.0
			windup_off = Vector2(-8.0, -30.0)
			active_off = Vector2(19.0, -29.0)
			vfx_kind = &"thrust"
		&"ls_cross_cleave":
			is_double_cross = true
			windup_deg = -135.0
			sweep_end_deg = 75.0
			overshoot_deg = -16.0
			sweep_dir = 1
			windup_off = Vector2(-8.0, -34.0)
			active_off = Vector2(17.0, -29.0)
			vfx_kind = &"slash"
		&"ls_lunge_thrust":
			is_thrust = true
			windup_deg = -8.0
			sweep_end_deg = 2.0
			overshoot_deg = 0.0
			thrust_dist = 20.0
			windup_off = Vector2(-11.0, -30.0)
			active_off = Vector2(20.0, -29.0)
			vfx_kind = &"thrust"
		&"ls_dragon_spiral":
			windup_deg = -180.0
			sweep_end_deg = 180.0
			overshoot_deg = 18.0
			sweep_dir = -1
			tilt_deg = -18.0
			body_spin_dir = 1
			windup_off = Vector2(-4.0, -24.0)
			active_off = Vector2(15.0, -38.0)
			vfx_kind = &"slash"
		&"ls_ankle_sweep":
			windup_deg = 112.0
			sweep_end_deg = 18.0
			overshoot_deg = 10.0
			sweep_dir = 1
			windup_off = Vector2(-6.0, -20.0)
			active_off = Vector2(18.0, -14.0)
			vfx_kind = &"slash"

		# --- Katana (Iaido & BlazBlue Razor Lines) ---
		&"kt_iaido_draw":
			windup_deg = 160.0
			sweep_end_deg = -32.0
			overshoot_deg = -12.0
			sweep_dir = -1
			tilt_deg = -10.0
			windup_off = Vector2(-5.0, -22.0)
			active_off = Vector2(17.0, -31.0)
			vfx_kind = &"razor"
		&"kt_double_cross":
			is_double_cross = true
			windup_deg = -142.0
			sweep_end_deg = 78.0
			overshoot_deg = -18.0
			sweep_dir = 1
			tilt_deg = 16.0
			windup_off = Vector2(-8.0, -33.0)
			active_off = Vector2(18.0, -29.0)
			vfx_kind = &"razor"
		&"kt_rapid_flurry":
			is_thrust = true
			is_flurry = true
			windup_deg = -26.0
			sweep_end_deg = 22.0
			overshoot_deg = 6.0
			thrust_dist = 16.0
			windup_off = Vector2(-9.0, -30.0)
			active_off = Vector2(19.0, -29.0)
			vfx_kind = &"razor"
		&"kt_blink_cut":
			is_thrust = true
			windup_deg = -148.0
			sweep_end_deg = 22.0
			overshoot_deg = 8.0
			thrust_dist = 18.0
			tilt_deg = 6.0
			windup_off = Vector2(-10.0, -30.0)
			active_off = Vector2(19.0, -29.0)
			vfx_kind = &"razor"
		&"kt_spin_vortex":
			windup_deg = -195.0
			sweep_end_deg = 165.0
			overshoot_deg = 18.0
			sweep_dir = 1
			body_spin_dir = 1
			windup_off = Vector2(-5.0, -30.0)
			active_off = Vector2(15.0, -31.0)
			vfx_kind = &"razor"
		&"kt_rising_fang":
			windup_deg = 132.0
			sweep_end_deg = -114.0
			overshoot_deg = -16.0
			sweep_dir = -1
			tilt_deg = -24.0
			windup_off = Vector2(0.0, -21.0)
			active_off = Vector2(16.0, -40.0)
			vfx_kind = &"razor"
		&"kt_low_slide":
			windup_deg = 128.0
			sweep_end_deg = 14.0
			overshoot_deg = 10.0
			sweep_dir = 1
			windup_off = Vector2(-7.0, -20.0)
			active_off = Vector2(19.0, -14.0)
			vfx_kind = &"razor"

		# --- Greatsword (Colossal Heavy Momentum) ---
		&"gs_heavy_cleave":
			windup_deg = -168.0
			sweep_end_deg = 98.0
			overshoot_deg = 28.0
			sweep_dir = 1
			tilt_deg = 14.0
			windup_off = Vector2(-11.0, -38.0)
			active_off = Vector2(18.0, -26.0)
			vfx_kind = &"heavy_cleave"
		&"gs_upward_rend":
			windup_deg = 138.0
			sweep_end_deg = -120.0
			overshoot_deg = -22.0
			sweep_dir = -1
			tilt_deg = -20.0
			windup_off = Vector2(-3.0, -20.0)
			active_off = Vector2(17.0, -41.0)
			vfx_kind = &"heavy_cleave"
		&"gs_whirlwind":
			windup_deg = -180.0
			sweep_end_deg = 180.0
			overshoot_deg = 24.0
			sweep_dir = 1
			body_spin_dir = 1
			windup_off = Vector2(-6.0, -30.0)
			active_off = Vector2(15.0, -30.0)
			vfx_kind = &"heavy_cleave"
		&"gs_earth_slam":
			windup_deg = -176.0
			sweep_end_deg = 92.0
			overshoot_deg = 26.0
			sweep_dir = 1
			windup_off = Vector2(-8.0, -41.0)
			active_off = Vector2(18.0, -16.0)
			vfx_kind = &"heavy_cleave"

		# --- Bow (Acrobatic Archer) ---
		&"bow_draw":
			windup_deg = -12.0
			sweep_end_deg = -22.0
			overshoot_deg = -6.0
			windup_off = Vector2(11.0, -31.0)
			active_off = Vector2(12.0, -31.0)
			vfx_kind = &"bow_shot"
		&"bow_anti_air":
			windup_deg = -44.0
			sweep_end_deg = -52.0
			overshoot_deg = -8.0
			windup_off = Vector2(10.0, -34.0)
			active_off = Vector2(11.0, -35.0)
			vfx_kind = &"bow_shot"
		&"bow_slide_shot":
			windup_deg = -8.0
			sweep_end_deg = -18.0
			overshoot_deg = -6.0
			windup_off = Vector2(12.0, -20.0)
			active_off = Vector2(14.0, -18.0)
			vfx_kind = &"bow_shot"
		&"bow_flip_shot":
			windup_deg = -18.0
			sweep_end_deg = -35.0
			overshoot_deg = -8.0
			body_spin_dir = -1
			windup_off = Vector2(10.0, -31.0)
			active_off = Vector2(9.0, -31.0)
			vfx_kind = &"bow_shot"

		# --- Dual Pistol (Gun-Kata) ---
		&"pistol_snap":
			_pistol_alt = not _pistol_alt
			windup_deg = -6.0
			sweep_end_deg = -34.0
			overshoot_deg = -6.0
			windup_off = Vector2(12.0, -30.0)
			active_off = Vector2(9.0, -31.0)
			vfx_kind = &"pistol_shot"
		&"pistol_slide":
			_pistol_alt = not _pistol_alt
			windup_deg = -6.0
			sweep_end_deg = -22.0
			overshoot_deg = -4.0
			windup_off = Vector2(11.0, -20.0)
			active_off = Vector2(14.0, -17.0)
			vfx_kind = &"pistol_shot"
		&"pistol_up_fan":
			_pistol_alt = not _pistol_alt
			windup_deg = -32.0
			sweep_end_deg = -56.0
			overshoot_deg = -8.0
			windup_off = Vector2(11.0, -32.0)
			active_off = Vector2(10.0, -36.0)
			vfx_kind = &"pistol_shot"
		&"pistol_rain_spin":
			_pistol_alt = not _pistol_alt
			windup_deg = 0.0
			sweep_end_deg = 360.0
			overshoot_deg = 12.0
			body_spin_dir = 1
			windup_off = Vector2(10.0, -30.0)
			active_off = Vector2(10.0, -30.0)
			vfx_kind = &"pistol_shot"

		# --- Wand (Harry Potter Slender Wooden Wand) ---
		&"wand_jab":
			windup_deg = -68.0
			sweep_end_deg = 8.0
			overshoot_deg = 8.0
			thrust_dist = 8.0
			windup_off = Vector2(3.0, -33.0)
			active_off = Vector2(16.0, -31.0)
			vfx_kind = &"wand_sigil"
		&"wand_whip_arc":
			windup_deg = -138.0
			sweep_end_deg = 48.0
			overshoot_deg = 12.0
			sweep_dir = 1
			windup_off = Vector2(1.0, -35.0)
			active_off = Vector2(16.0, -29.0)
			vfx_kind = &"wand_sigil"
		&"wand_circle_cast":
			windup_deg = -210.0
			sweep_end_deg = 150.0
			overshoot_deg = 16.0
			sweep_dir = 1
			windup_off = Vector2(4.0, -34.0)
			active_off = Vector2(15.0, -32.0)
			vfx_kind = &"wand_sigil"
		&"wand_sky_raise":
			windup_deg = 55.0
			sweep_end_deg = -78.0
			overshoot_deg = -10.0
			sweep_dir = -1
			tilt_deg = -20.0
			windup_off = Vector2(5.0, -27.0)
			active_off = Vector2(14.0, -39.0)
			vfx_kind = &"wand_sigil"
		&"wand_ground_point":
			windup_deg = -115.0
			sweep_end_deg = 62.0
			overshoot_deg = 12.0
			sweep_dir = 1
			windup_off = Vector2(2.0, -37.0)
			active_off = Vector2(16.0, -22.0)
			vfx_kind = &"wand_sigil"

	if wtype == WeaponData.WeaponType.GREATSWORD:
		overshoot_deg *= 1.35

	return {
		"windup_deg": windup_deg,
		"sweep_end_deg": sweep_end_deg,
		"overshoot_deg": overshoot_deg,
		"sweep_dir": sweep_dir,
		"tilt_deg": tilt_deg,
		"thrust_dist": thrust_dist,
		"is_thrust": is_thrust,
		"is_double_cross": is_double_cross,
		"is_flurry": is_flurry,
		"body_spin_dir": body_spin_dir,
		"windup_off": windup_off,
		"active_off": active_off,
		"vfx_kind": vfx_kind,
	}


func _start_weapon_move(tag: StringName, force_switch: bool = false) -> bool:
	var weapon := GameState.get_active_weapon()
	if weapon == null:
		return false
	var wlevel := GameState.get_weapon_level(weapon.id)
	var mv := weapon.get_move(tag, wlevel)

	if mv == null:
		if tag == &"launcher" or tag == &"dive" or tag == &"up_heavy" or tag == &"down_heavy":
			HitstopManager.show_toast("%s Lv.2 required for Directional Arts!" % weapon.display_name, Color(1.0, 0.78, 0.4))
			mv = weapon.get_move(&"light_1", wlevel)
		elif tag == &"signature":
			HitstopManager.show_toast("%s Lv.3 required for Signature Art!" % weapon.display_name, Color(1.0, 0.78, 0.4))
			return false
		elif tag == &"ultimate":
			HitstopManager.show_toast("%s Lv.5 required for Mastery Ultimate!" % weapon.display_name, Color(1.0, 0.78, 0.4))
			return false
		elif tag == &"switch" and force_switch:
			mv = weapon.get_move(&"light_1", wlevel)
		else:
			mv = weapon.get_move(&"light_1", wlevel)
			if mv == null:
				return false

	if mv.flux_cost > 0.0 and flux < mv.flux_cost:
		HitstopManager.show_toast("Need %d Flux!" % int(mv.flux_cost), Color(0.55, 0.88, 1.0))
		return false

	if mv.flux_cost > 0.0:
		flux = maxf(0.0, flux - mv.flux_cost)
		flux_changed.emit(flux, max_flux)

	var ix := Input.get_axis(&"move_left", &"move_right")
	if absf(ix) > 0.2:
		facing = 1 if ix > 0.0 else -1

	current_move = mv
	_swing_profile = _build_swing_profile(weapon, mv)
	state = State.ATTACK
	move_frame = 0.0
	move_phase = "STARTUP"
	hit_confirmed = false
	_attack_fired_spawn = false
	_next_hit_pulse_idx = 0
	_hit_enemies_this_move.clear()
	hitbox.monitoring = false

	pop_squash(Vector2(1.08, 0.90))
	move_performed.emit(mv.display_name)

	if mv.slot_tag in [&"light_1", &"light_2", &"light_3", &"light_4", &"air_1", &"air_2", &"air_3"]:
		combo_step += 1
		heavy_step = 0
		combo_reset_timer = 0.85
	elif mv.slot_tag == &"heavy":
		heavy_step = 1
		combo_reset_timer = 0.90
	else:
		combo_step = 0
		heavy_step = 0

	# Preserve forward sprint/dash momentum when swinging into a strike
	var imp_x := float(facing) * mv.self_impulse.x
	var out_vx := imp_x
	if signf(velocity.x) == float(facing) and absf(velocity.x) > absf(imp_x):
		out_vx = velocity.x * 0.82
	var out_vy := mv.self_impulse.y if mv.self_impulse.y != 0.0 else velocity.y * 0.55
	velocity = Vector2(out_vx, out_vy)

	if mv.is_signature and GameState.is_dual_katana_active():
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -58), "DUAL COMBINE ART!", Color(1.0, 0.85, 0.35), 1.05)

	return true


func _step_attack(delta: float) -> void:
	if current_move == null:
		state = State.LOCOMOTION
		return

	var weapon := GameState.get_active_weapon()
	var speed := weapon.speed_mult * (1.2 if overdrive_timer > 0.0 else 1.0)
	if GameState.is_dual_katana_active():
		speed *= 1.12
	move_frame += delta * 60.0 * speed

	var ix := Input.get_axis(&"move_left", &"move_right")
	var is_pistol := weapon.weapon_type == WeaponData.WeaponType.DUAL_PISTOL

	if current_move.is_dive:
		velocity.y = maxf(velocity.y, 320.0)
		velocity.x = move_toward(velocity.x, ix * 120.0, 600.0 * delta)
		if is_on_floor():
			_spawn_dive_shockwave()
			hitbox.monitoring = false
			state = State.LOCOMOTION
			current_move = null
			return
	elif not is_on_floor():
		var g := (GRAVITY_UP * 0.28) if is_pistol else (GRAVITY_DOWN * 0.72)
		velocity.y = minf(MAX_FALL_SPEED, velocity.y + g * delta)
		if absf(ix) > 0.1:
			velocity.x = move_toward(velocity.x, ix * BASE_RUN_SPEED * 0.9, 850.0 * delta)
	elif is_pistol and current_move.slot_tag in [&"light_1", &"light_2", &"light_3", &"light_4", &"dash_attack"]:
		# Gun-Fu run-and-gun gliding on ground
		velocity.x = move_toward(velocity.x, ix * BASE_RUN_SPEED * 0.85, 1600.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)

	var start_end := float(current_move.startup_frames)
	var active_end := start_end + float(current_move.active_frames)
	var total_end := float(current_move.total_frames())

	if move_frame < start_end:
		move_phase = "STARTUP"
		hitbox.monitoring = false
	elif move_frame < active_end:
		move_phase = "ACTIVE"
		if not _attack_fired_spawn:
			_attack_fired_spawn = true
			_next_hit_pulse_idx = 1
			_enter_active_frames(weapon)
		elif current_move.multi_hits > 1 and _next_hit_pulse_idx < current_move.multi_hits:
			var pulse_frac := float(_next_hit_pulse_idx) / float(current_move.multi_hits)
			var pulse_frame := start_end + pulse_frac * float(current_move.active_frames)
			if move_frame >= pulse_frame:
				_next_hit_pulse_idx += 1
				_trigger_multi_hit_pulse(weapon)
	elif move_frame < total_end:
		move_phase = "RECOVERY"
		hitbox.monitoring = false
	else:
		hitbox.monitoring = false
		current_move = null
		state = State.LOCOMOTION
		return

	var cancel_ready := hit_confirmed or (move_frame >= float(current_move.cancel_from_frame))
	if cancel_ready:
		if _try_consume_combat_transitions(true):
			return
		if (current_move.is_launcher or not is_on_floor()) and input_buffer.consume(&"jump"):
			hitbox.monitoring = false
			current_move = null
			state = State.LOCOMOTION
			velocity.y = JUMP_VEL * 0.92
			pop_squash(Vector2(0.80, 1.24))
			SfxManager.play_sfx(&"jump", -7.5)
			return


func _trigger_multi_hit_pulse(weapon: WeaponData) -> void:
	if current_move == null:
		return
	var elem_id := GameState.get_active_element_id()
	var elem_col := ElementRegistry.get_color(elem_id)
	var dual := GameState.is_dual_katana_active()
	var off_col := ElementRegistry.get_color(GameState.get_off_element_id()) if dual else Color.WHITE
	_swing_flash_timer = 0.07
	SfxManager.play_weapon_swing(weapon.weapon_type, false)

	_hit_enemies_this_move.clear()
	var vfx_kind := StringName(_swing_profile.get("vfx_kind", &"slash"))
	if current_move.is_projectile:
		_fire_projectiles(weapon, elem_id, GameState.get_off_element_id() if dual else &"")
		var tip_world := weapon_pivot.to_global(Vector2(float(_get_weapon_geom(weapon.weapon_type)["blade_len"]), 0.0))
		if vfx_kind == &"wand_sigil":
			PixelVfx.spawn_magic_sigil(get_parent(), tip_world, facing, 15.0, elem_col)
		elif vfx_kind == &"pistol_shot":
			PixelVfx.spawn_muzzle_flash(get_parent(), tip_world, facing, elem_col, 13.0)
			PixelVfx.spawn_shell_casing(get_parent(), weapon_pivot.global_position, facing)
		else:
			PixelVfx.spawn_muzzle_flash(get_parent(), tip_world, facing, elem_col, 13.0)
		return

	var arc_rad := maxf(current_move.hitbox_size.x, current_move.hitbox_size.y) * 0.68
	var is_thrust := bool(_swing_profile.get("is_thrust", false))
	if vfx_kind == &"razor":
		var cut_deg := float(((_next_hit_pulse_idx % 3) - 1) * 26)
		PixelVfx.spawn_razor_line(get_parent(), global_position + Vector2(facing * 26.0, -28.0 + randf_range(-5.0, 5.0)), facing, arc_rad * 1.45, cut_deg, elem_col)
	elif vfx_kind == &"wand_sigil":
		PixelVfx.spawn_magic_sigil(get_parent(), weapon_pivot.to_global(Vector2(15.0, 0.0)), facing, 18.0, elem_col)
	elif is_thrust:
		PixelVfx.spawn_thrust(get_parent(), global_position + Vector2(facing * 20.0, -28.0 + randf_range(-4.0, 4.0)), facing, arc_rad * 1.25, elem_col)
	else:
		var alt_dir := -1 if (_next_hit_pulse_idx % 2 == 0) else 1
		PixelVfx.spawn_slash(get_parent(), global_position + Vector2(facing * 20, -28), facing, arc_rad, current_move.arc_angle_deg, elem_col, dual, off_col, alt_dir, 0.0)

	for area in hitbox.get_overlapping_areas():
		_on_hitbox_area_entered(area)


func _enter_active_frames(weapon: WeaponData) -> void:
	var elem_id := GameState.get_active_element_id()
	var elem_col := ElementRegistry.get_color(elem_id)
	var dual := GameState.is_dual_katana_active()
	var off_elem := GameState.get_off_element_id() if dual else &""
	var off_col := ElementRegistry.get_color(off_elem) if dual else Color.WHITE
	var is_heavy_swing := current_move.slot_tag in [&"heavy", &"heavy_2", &"signature", &"ultimate", &"light_4"]

	_swing_flash_timer = 0.09
	SfxManager.play_weapon_swing(weapon.weapon_type, is_heavy_swing)

	# Wall-safe phase blink (Phantom Katana, Crimson Iaido, Wand Phase Surge)
	if current_move.blink_distance > 0.0:
		var step_x := float(facing) * current_move.blink_distance
		for g in range(3):
			PixelVfx.spawn_afterimage(get_parent(), global_position + Vector2(step_x * (float(g) / 3.0), 0.0), _textures["dash"], facing < 0, elem_col)
		move_and_collide(Vector2(step_x, 0.0))
		SfxManager.play_sfx(&"dash", -7.0, 1.2, 1.35)

	# Inward enemy vortex pull (Phantom Gale, Wand Gravity Well / Vortex Twirl)
	if current_move.pull_enemies > 0.0:
		var pull_center := global_position + Vector2(float(facing) * 34.0, -20.0)
		PixelVfx.spawn_ring(get_parent(), pull_center, 74.0, elem_col)
		for enemy in get_tree().get_nodes_in_group(&"enemies"):
			var e2d := enemy as Node2D
			if is_instance_valid(e2d) and e2d.global_position.distance_to(pull_center) <= 145.0:
				var pull_dir: Vector2 = (pull_center - e2d.global_position).normalized()
				e2d.velocity += pull_dir * current_move.pull_enemies

	if current_move.is_launcher:
		pop_squash(Vector2(0.84, 1.22))
		HitstopManager.request_punch(Vector2(facing * 2.5, -3.5), 0.02)
	elif weapon.weapon_type == WeaponData.WeaponType.GREATSWORD:
		pop_squash(Vector2(1.22, 0.84))
		HitstopManager.request_punch(Vector2(facing * 5.0, 2.0), 0.025)
		if is_on_floor():
			PixelVfx.spawn_dust(get_parent(), global_position + Vector2(facing * 18.0, -2.0), facing, Color(0.82, 0.78, 0.75))
	else:
		pop_squash(Vector2(1.16, 0.88))
		HitstopManager.request_punch(Vector2(facing * 2.5, 0.0), 0.0)

	var vfx_kind := StringName(_swing_profile.get("vfx_kind", &"slash"))
	var tip_world := weapon_pivot.to_global(Vector2(float(_get_weapon_geom(weapon.weapon_type)["blade_len"]), 0.0))

	if current_move.is_projectile:
		_fire_projectiles(weapon, elem_id, off_elem if (dual or current_move.is_dual_combine) else &"")
		if vfx_kind == &"wand_sigil":
			PixelVfx.spawn_magic_sigil(get_parent(), tip_world, facing, 17.0, elem_col)
		elif vfx_kind == &"pistol_shot":
			PixelVfx.spawn_muzzle_flash(get_parent(), tip_world, facing, elem_col, 15.0)
			PixelVfx.spawn_shell_casing(get_parent(), weapon_pivot.global_position, facing)
		else:
			PixelVfx.spawn_muzzle_flash(get_parent(), tip_world, facing, elem_col, 15.0)
		return

	var rect := hitbox_shape.shape as RectangleShape2D
	rect.size = current_move.hitbox_size
	hitbox_shape.position = Vector2(facing * current_move.hitbox_offset.x, current_move.hitbox_offset.y)
	hitbox.monitoring = true

	var is_thrust := bool(_swing_profile.get("is_thrust", false))
	var arc_rad := maxf(current_move.hitbox_size.x, current_move.hitbox_size.y) * 0.72
	var sw_dir := int(_swing_profile.get("sweep_dir", 1))
	var tilt := float(_swing_profile.get("tilt_deg", 0.0))
	if vfx_kind == &"razor":
		PixelVfx.spawn_razor_line(get_parent(), global_position + Vector2(facing * 28.0, -28.0), facing, arc_rad * 1.55, tilt * float(facing) - 18.0 * float(facing), elem_col)
		PixelVfx.spawn_slash(get_parent(), global_position + Vector2(facing * 20, -28), facing, arc_rad * 0.88, current_move.arc_angle_deg, elem_col, dual, off_col, sw_dir, tilt)
	elif vfx_kind == &"wand_sigil":
		PixelVfx.spawn_magic_sigil(get_parent(), tip_world, facing, 22.0, elem_col)
		PixelVfx.spawn_slash(get_parent(), global_position + Vector2(facing * 20, -28), facing, arc_rad * 0.85, current_move.arc_angle_deg, elem_col, false, Color.WHITE, sw_dir, tilt)
	elif is_thrust:
		PixelVfx.spawn_thrust(get_parent(), global_position + Vector2(facing * 20.0, -28.0), facing, arc_rad * 1.45, elem_col)
		if dual:
			PixelVfx.spawn_slash(get_parent(), global_position + Vector2(facing * 20, -28), facing, arc_rad * 0.85, 85.0, off_col, false, Color.WHITE, -1, 0.0)
	else:
		PixelVfx.spawn_slash(get_parent(), global_position + Vector2(facing * 20, -28), facing, arc_rad, current_move.arc_angle_deg, elem_col, dual, off_col, sw_dir, tilt)

	# Radial elemental shockwave burst for slams, whirlwinds & novas
	if current_move.aoe_ring_radius > 0.0:
		var ring_center := global_position + Vector2(facing * current_move.hitbox_offset.x * 0.65, -20.0)
		PixelVfx.spawn_ring(get_parent(), ring_center, current_move.aoe_ring_radius, elem_col, dual, off_col)
		if is_on_floor():
			PixelVfx.spawn_dust(get_parent(), global_position + Vector2(facing * 16.0, -2.0), facing, elem_col.lerp(Color.WHITE, 0.45))
		for enemy in get_tree().get_nodes_in_group(&"enemies"):
			if is_instance_valid(enemy) and enemy.global_position.distance_to(ring_center) <= current_move.aoe_ring_radius:
				enemy.take_hit({
					"damage": _compute_base_damage(weapon, current_move) * 0.48,
					"poise_damage": current_move.poise_damage * weapon.poise_mult * 0.6,
					"weapon_id": weapon.id,
					"weapon_type": weapon.weapon_type,
					"element_id": elem_id,
					"secondary_element_id": off_elem,
					"knockback": Vector2(signf(enemy.global_position.x - ring_center.x) * 145.0, -75.0),
					"attacker": self,
					"is_projectile": false,
				})

	if (current_move.is_signature or current_move.slot_tag == &"heavy_2") and weapon.weapon_type == WeaponData.WeaponType.WAND:
		_trigger_wand_detonate(elem_col)


func _fire_projectiles(weapon: WeaponData, elem_id: StringName, sec_elem: StringName) -> void:
	var count := maxi(1, current_move.projectile_count)
	var is_radial := current_move.projectile_spread_deg >= 359.0
	var spread_step := current_move.projectile_spread_deg if count > 1 else 0.0
	var base_dir := Vector2(float(facing), 0.0)
	if Input.is_action_pressed(&"move_up"):
		base_dir = Vector2(float(facing) * 0.78, -0.62).normalized()
	elif Input.is_action_pressed(&"move_down") and not is_on_floor():
		base_dir = Vector2(float(facing) * 0.65, 0.76).normalized()
	elif absf(current_move.projectile_pitch_deg) > 0.1:
		base_dir = Vector2(float(facing), 0.0).rotated(deg_to_rad(current_move.projectile_pitch_deg * float(facing)))

	var is_pistol := weapon.weapon_type == WeaponData.WeaponType.DUAL_PISTOL
	if is_pistol:
		ammo = maxi(0, ammo - 1)

	var dmg := _compute_base_damage(weapon, current_move)
	if is_pistol and ammo == 0:
		dmg *= 0.6
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -48), "DASH TO RELOAD!", Color(1.0, 0.65, 0.35), 0.75)

	var proj_aoe := maxf(current_move.aoe_ring_radius, 48.0 if (weapon.weapon_type == WeaponData.WeaponType.WAND or current_move.is_ultimate) else 0.0)

	for i in range(count):
		var angle_offset := 0.0
		if is_radial and count > 1:
			angle_offset = (float(i) / float(count)) * TAU
		else:
			angle_offset = deg_to_rad((float(i) - float(count - 1) * 0.5) * spread_step)
		var dir := base_dir.rotated(angle_offset)
		var p := CombatProjectile.new()
		p.global_position = global_position + Vector2(facing * 18.0, -24.0)
		p.velocity = dir * current_move.projectile_speed
		p.damage = dmg
		p.poise_damage = current_move.poise_damage * weapon.poise_mult
		p.weapon_id = weapon.id
		p.weapon_type = weapon.weapon_type
		p.element_id = elem_id
		p.secondary_element_id = sec_elem
		p.pierce_left = 3 if weapon.weapon_type == WeaponData.WeaponType.BOW else 1
		p.aoe_radius = proj_aoe
		p.knockback = current_move.knockback
		p.source_player = self
		p.is_empowered = overdrive_timer > 0.0
		get_parent().add_child(p)


func _spawn_dive_shockwave() -> void:
	var elem_id := GameState.get_active_element_id()
	var col := ElementRegistry.get_color(elem_id)
	pop_squash(Vector2(1.32, 0.72))
	SfxManager.play_sfx(&"hit_heavy", -4.0)
	PixelVfx.spawn_ring(get_parent(), global_position, 58.0, col)
	PixelVfx.spawn_dust(get_parent(), global_position, facing, Color(0.85, 0.85, 0.92))
	HitstopManager.request_shake(0.28)
	HitstopManager.request_punch(Vector2(0, 6.0), 0.03)
	var weapon := GameState.get_active_weapon()
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(global_position) <= 62.0:
			enemy.take_hit({
				"damage": _compute_base_damage(weapon, current_move) * 0.85,
				"poise_damage": current_move.poise_damage * weapon.poise_mult,
				"weapon_id": weapon.id,
				"weapon_type": weapon.weapon_type,
				"element_id": elem_id,
				"secondary_element_id": &"",
				"knockback": Vector2(signf(enemy.global_position.x - global_position.x) * 140.0, -110.0),
				"attacker": self,
				"is_projectile": false,
			})


func _trigger_wand_detonate(elem_col: Color) -> void:
	var center := global_position + Vector2(facing * 32, -24)
	SfxManager.play_sfx(&"reaction", -4.5)
	PixelVfx.spawn_ring(get_parent(), center, 96.0, elem_col, true, Color.WHITE)
	HitstopManager.request_shake(0.42)
	HitstopManager.request_punch(Vector2(facing * 5.0, -2.0), 0.04)
	for enemy in get_tree().get_nodes_in_group(&"enemies"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(center) <= 102.0 and enemy.has_method("detonate_statuses"):
			enemy.detonate_statuses(self, GameState.get_active_element_id())


func _compute_base_damage(weapon: WeaponData, mv: MoveData) -> float:
	var wlevel := GameState.get_weapon_level(weapon.id)
	var level_scale := 1.0 + float(wlevel - 1) * 0.12
	var dual_scale := 1.24 if GameState.is_dual_katana_active() else 1.0
	var armor_elem := float(GameState.get_equipped_armor().get("elem_bonus", 1.0))
	var buff := 1.35 if overdrive_timer > 0.0 else 1.0
	var power := BASE_DAMAGE * mv.damage_mult * level_scale * buff
	var phys_part := power * weapon.phys_mult * 0.55 * dual_scale
	var elem_part := power * weapon.elem_mult * armor_elem * 0.45 * (1.25 if wlevel >= 5 else 1.0)
	return phys_part + elem_part


func _on_hitbox_area_entered(area: Area2D) -> void:
	if current_move == null:
		return
	var target := area.get_parent()
	if target == null or not target.has_method("take_hit"):
		return
	var tid := target.get_instance_id()
	if _hit_enemies_this_move.has(tid):
		return
	_hit_enemies_this_move[tid] = true

	var weapon := GameState.get_active_weapon()
	var elem_id := GameState.get_active_element_id()
	var elem_col := ElementRegistry.get_color(elem_id)
	var sec_elem := &""
	var is_dual_combine := false
	if GameState.is_dual_katana_active() and (current_move.is_signature or current_move.is_ultimate):
		sec_elem = GameState.get_off_element_id()
		is_dual_combine = true

	var dmg := _compute_base_damage(weapon, current_move)
	var poise := current_move.poise_damage * weapon.poise_mult
	if GameState.is_dual_katana_active():
		poise *= 0.65

	if current_move.is_launcher and GameState.has_mod(&"mod_launcher_shock"):
		poise *= 1.25
		PixelVfx.spawn_ring(get_parent(), target.global_position + Vector2(0, -24), 48.0, elem_col)

	var hit_info := {
		"damage": dmg,
		"poise_damage": poise,
		"weapon_id": weapon.id,
		"weapon_type": weapon.weapon_type,
		"element_id": elem_id,
		"secondary_element_id": sec_elem,
		"is_dual_combine": is_dual_combine,
		"is_dual_katana": GameState.is_dual_katana_active(),
		"knockback": Vector2(facing * current_move.knockback.x, current_move.knockback.y),
		"attacker": self,
		"is_projectile": false,
	}
	target.take_hit(hit_info)
	on_attack_hit_confirmed(target, false)

	var is_heavy_hit := current_move.hitstop_frames >= 5
	SfxManager.play_sfx(&"hit_heavy" if is_heavy_hit else &"hit_light", -5.0 if is_heavy_hit else -7.5)
	HitstopManager.request_punch(Vector2(facing * (6.5 if is_heavy_hit else 3.5), -1.0), 0.03 if current_move.is_ultimate else 0.0)

	if GameState.is_dual_katana_active() and is_instance_valid(target) and target.has_method("take_hit"):
		var off_w := GameState.get_offhand_weapon()
		var off_elem := GameState.get_off_element_id()
		if off_w != null:
			var echo_dmg := dmg * 0.42
			target.take_hit({
				"damage": echo_dmg,
				"poise_damage": poise * 0.4,
				"weapon_id": off_w.id,
				"weapon_type": off_w.weapon_type,
				"element_id": off_elem if is_dual_combine else elem_id,
				"secondary_element_id": elem_id if is_dual_combine else &"",
				"is_dual_katana": true,
				"knockback": Vector2(facing * 25.0, -20.0),
				"attacker": self,
				"is_projectile": false,
			})
			if off_w.secondary_modifier == &"vortex_pull":
				for other in get_tree().get_nodes_in_group(&"enemies"):
					if other != target and is_instance_valid(other) and other.global_position.distance_to(target.global_position) <= 92.0:
						other.velocity.x += signf(target.global_position.x - other.global_position.x) * 110.0

	HitstopManager.apply_hitstop([self, target], current_move.hitstop_frames)
	HitstopManager.request_shake(0.18 if not current_move.is_ultimate else 0.45)


func on_attack_hit_confirmed(target: Node, is_proj: bool) -> void:
	hit_confirmed = true
	combo_count += 1
	combo_decay_timer = 2.8
	combo_changed.emit(combo_count, get_style_rank())

	if is_proj:
		SfxManager.play_sfx(&"hit_light", -8.0, 1.0, 1.15)

	var gain := current_move.flux_gain if current_move != null else 8.0
	if is_proj:
		gain = maxf(gain, 6.0)
	_gain_flux(gain)

	var weapon := GameState.get_active_weapon()
	if weapon != null:
		GameState.add_weapon_exp(weapon.id, 12 if not is_proj else 8)
		if GameState.is_dual_katana_active():
			GameState.add_weapon_exp(GameState.get_offhand_weapon_id(), 8)
	var _unused := target


func on_elemental_reaction_triggered() -> void:
	if GameState.has_mod(&"mod_flux_siphon"):
		hp = minf(max_hp, hp + 8.0)
		health_changed.emit(hp, max_hp)
		_gain_flux(15.0)


func _gain_flux(amount: float) -> void:
	var armor_mult := float(GameState.get_equipped_armor().get("flux_gain_mult", 1.0))
	flux = minf(max_flux, flux + amount * armor_mult)
	flux_changed.emit(flux, max_flux)


func get_style_rank() -> String:
	if combo_count >= 25:
		return "S"
	if combo_count >= 16:
		return "A"
	if combo_count >= 9:
		return "B"
	if combo_count >= 4:
		return "C"
	return "D"


func take_enemy_hit(dmg: float, attacker: Node, parryable: bool, knockback: Vector2) -> void:
	if state == State.DEAD:
		return

	if state == State.PARRY and parryable:
		_execute_parry_riposte(attacker)
		return

	if iframe_timer > 0.0:
		if GameState.has_mod(&"mod_perfect_dodge_reset"):
			air_dash_available = true
			dash_cooldown_timer = 0.0
			_gain_flux(20.0)
			SfxManager.play_sfx(&"swap", -6.0, 1.3, 1.45)
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -56), "PERFECT DODGE! +20 FLUX", Color(0.55, 0.95, 1.0), 0.95)
		else:
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -50), "DODGE!", Color(0.75, 0.92, 1.0), 0.85)
		return

	if state == State.ATTACK and current_move != null and current_move.has_hyper_armor:
		hp = maxf(1.0, hp - dmg * 0.55)
		health_changed.emit(hp, max_hp)
		SfxManager.play_sfx(&"hit_light", -8.0, 0.7, 0.85)
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -48), "HYPER ARMOR!", Color(1.0, 0.72, 0.35), 0.85)
		return

	hp = maxf(0.0, hp - dmg)
	health_changed.emit(hp, max_hp)
	combo_count = 0
	combo_changed.emit(0, "D")
	hitbox.monitoring = false
	current_move = null
	iframe_timer = 0.45
	pop_squash(Vector2(1.22, 0.82))
	SfxManager.play_sfx(&"hit_heavy", -5.0, 0.75, 0.88)
	HitstopManager.request_shake(0.32)
	HitstopManager.request_punch(Vector2(-facing * 6.0, 2.0), -0.02)
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -44), "-%d" % int(round(dmg)), Color(1.0, 0.35, 0.35), 1.0)

	if hp <= 0.0:
		state = State.DEAD
		HitstopManager.show_toast("Defeated! Respawning at Sanctuary (All Weapons & Progress Kept)...", Color(1.0, 0.52, 0.45))
		get_tree().call_group(&"game_controller", &"on_player_defeated")
		return

	state = State.HITSTUN
	hitstun_timer = 0.24
	velocity = knockback


func _execute_parry_riposte(attacker: Node) -> void:
	parry_cooldown = 0.05
	iframe_timer = 0.35
	state = State.LOCOMOTION
	_gain_flux(25.0)
	combo_count += 3
	combo_changed.emit(combo_count, get_style_rank())
	pop_squash(Vector2(1.20, 0.85))
	SfxManager.play_sfx(&"parry", -3.0)

	var w := GameState.get_active_weapon()
	var elem_id := GameState.get_active_element_id()
	var elem_col := ElementRegistry.get_color(elem_id)
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 44.0, Color(1.0, 0.92, 0.35), true, elem_col)
	PixelVfx.spawn_hit_spark(get_parent(), global_position + Vector2(facing * 14.0, -24.0), facing, Color(1.0, 0.92, 0.35), 22.0)
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -58), "PARRY RIPOSTE!", Color(1.0, 0.92, 0.35), 1.1)
	HitstopManager.request_punch(Vector2(facing * 8.0, -2.0), 0.055)

	if is_instance_valid(attacker) and attacker.has_method("take_hit"):
		var riposte_mult := 2.4 if (w != null and w.weapon_type == WeaponData.WeaponType.LONGSWORD) else 1.5
		attacker.take_hit({
			"damage": 26.0 * riposte_mult,
			"poise_damage": 65.0 * riposte_mult,
			"weapon_id": w.id if w != null else &"ls_vanguard",
			"weapon_type": w.weapon_type if w != null else WeaponData.WeaponType.LONGSWORD,
			"element_id": elem_id,
			"secondary_element_id": &"",
			"is_parry_riposte": true,
			"knockback": Vector2(facing * 120.0, -45.0),
			"attacker": self,
			"is_projectile": false,
		})
		HitstopManager.apply_hitstop([self, attacker], 7)
		HitstopManager.request_shake(0.38)


func _step_hitstun(delta: float) -> void:
	hitstun_timer -= delta
	velocity.y = minf(MAX_FALL_SPEED, velocity.y + GRAVITY_DOWN * delta)
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if hitstun_timer <= 0.0:
		state = State.LOCOMOTION


func revive_at_sanctuary() -> void:
	state = State.LOCOMOTION
	hp = max_hp
	flux = 50.0
	ammo = max_ammo
	velocity = Vector2.ZERO
	_visual_scale = Vector2.ONE
	_scale_vel = Vector2.ZERO
	_visual_tilt = 0.0
	_land_impact = 0.0
	clear_trails()
	GameState.refill_pouch_at_shrine()
	health_changed.emit(hp, max_hp)
	flux_changed.emit(flux, max_flux)


func _update_visuals(delta: float) -> void:
	# Damped harmonic spring for organic squash-and-stretch
	var spring_force := (Vector2.ONE - _visual_scale) * 320.0
	_scale_vel = (_scale_vel + spring_force * delta) * maxf(0.0, 1.0 - 22.0 * delta)
	_visual_scale += _scale_vel * delta

	var w := GameState.get_active_weapon()
	var wtype := w.weapon_type if w != null else WeaponData.WeaponType.LONGSWORD
	var dual := GameState.is_dual_katana_active()
	var dual_pistol := wtype == WeaponData.WeaponType.DUAL_PISTOL
	var elem_id := GameState.get_active_element_id()
	var elem_col := ElementRegistry.get_color(elem_id)

	var is_wallrunning := (_overlapping_wallrun > 0 and not is_on_floor() and Vector2(velocity.x, velocity.y).length() > 30.0)
	if absf(velocity.x) > 18.0 and is_on_floor() and state == State.LOCOMOTION:
		var run_fps := clampf(absf(velocity.x) / BASE_RUN_SPEED, 0.45, 1.60) * 12.0
		_run_phase += delta * run_fps
	else:
		_last_run_step = -1

	var body_spin_rad := 0.0
	var vault_t := 0.0
	if state == State.VAULT:
		vault_t = clampf(vault_timer / 0.18, 0.0, 1.0)
		body_spin_rad = float(vault_dir * facing) * vault_t * TAU
	elif state == State.ATTACK and current_move != null:
		var spin_dir := int(_swing_profile.get("body_spin_dir", 0))
		if spin_dir != 0 and move_phase == "ACTIVE":
			var p_spin := clampf((move_frame - float(current_move.startup_frames)) / maxf(1.0, float(current_move.active_frames)), 0.0, 1.0)
			body_spin_rad = float(spin_dir) * p_spin * TAU

	sprite.rotation = 0.0
	sprite.flip_h = false
	sprite.position = Vector2.ZERO
	visual_root.scale = _visual_scale
	visual_root.rotation = 0.0

	var pose_info := _compute_weapon_swing_targets(wtype, dual, dual_pistol)
	var local_deg := float(pose_info["local_deg"])
	var local_off := pose_info["local_off"] as Vector2
	var off_deg := float(pose_info["off_deg"])
	var off_off := pose_info["off_off"] as Vector2
	var phase_t := float(pose_info["phase_t"])
	var emit_trail := bool(pose_info["emit_trail"])

	if pixel_rig != null:
		pixel_rig.update_pose(delta, {
			"state": state,
			"facing": facing,
			"vel": velocity,
			"on_floor": is_on_floor(),
			"wallrunning": is_wallrunning,
			"vault_t": vault_t,
			"land_impact": _land_impact,
			"weapon_type": wtype,
			"dual_katana": dual,
			"move_phase": move_phase,
			"phase_t": phase_t,
			"swing_style": current_move.swing_style if current_move != null else &"",
			"weapon_deg": local_deg,
			"weapon_off": local_off,
			"off_deg": off_deg,
			"off_pos": off_off,
			"body_spin_rad": body_spin_rad,
			"elem_col": elem_col,
			"overdrive": overdrive_timer > 0.0,
		})
		if pixel_rig.consume_footstep_event() and is_on_floor():
			PixelVfx.spawn_dust(get_parent(), global_position + Vector2(-facing * 4.0, -1.0), facing, Color(0.62, 0.66, 0.76))

	_apply_weapon_pivots(wtype, dual, dual_pistol, local_deg, local_off, off_deg, off_off, elem_col, emit_trail)

	var invul_flash := 0.7 if iframe_timer > 0.0 and int(Time.get_ticks_msec() / 40) % 2 == 0 else 0.0
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("flash_amount", invul_flash)
		_shader_mat.set_shader_parameter("element_color", elem_col)
		_shader_mat.set_shader_parameter("glow_strength", 1.35 if overdrive_timer > 0.0 else 0.78)
	if _weapon_shader_mat != null:
		var swing_glow := 1.85 if _swing_flash_timer > 0.0 else (1.35 if overdrive_timer > 0.0 else 0.95)
		_weapon_shader_mat.set_shader_parameter("glow_strength", swing_glow)
		_weapon_shader_mat.set_shader_parameter("flash_amount", 0.55 if _swing_flash_timer > 0.0 else 0.0)


func _compute_weapon_swing_targets(wtype: int, dual: bool, dual_pistol: bool) -> Dictionary:
	var ready_deg := -118.0 if wtype == WeaponData.WeaponType.GREATSWORD else 16.0
	var ready_off := Vector2(9.5, -29.5)
	if wtype == WeaponData.WeaponType.GREATSWORD:
		ready_off = Vector2(6.0, -32.0)
	elif wtype == WeaponData.WeaponType.KATANA and not dual:
		ready_deg = 165.0
		ready_off = Vector2(-4.0, -22.5)
	elif wtype == WeaponData.WeaponType.BOW:
		ready_deg = -10.0
		ready_off = Vector2(11.0, -30.5)
	elif dual_pistol:
		ready_deg = 8.0
		ready_off = Vector2(11.5, -30.0)
	elif wtype == WeaponData.WeaponType.WAND:
		ready_deg = -24.0
		ready_off = Vector2(10.5, -31.0)

	if state == State.PARRY:
		return {
			"local_deg": -72.0,
			"local_off": Vector2(10.0, -33.0),
			"off_deg": -72.0,
			"off_off": Vector2(5.5, -30.5),
			"phase_t": 0.0,
			"emit_trail": false,
		}

	if state != State.ATTACK or current_move == null:
		var off_d := -128.0 if dual else (14.0 if dual_pistol else 12.0)
		var off_p := Vector2(-6.5, -28.0) if dual else (Vector2(4.0, -31.0) if dual_pistol else Vector2(-5.5, -30.5))
		if state == State.DASH:
			ready_deg = 152.0 if wtype != WeaponData.WeaponType.GREATSWORD else -145.0
			ready_off = Vector2(-7.0, -22.5)
		return {
			"local_deg": ready_deg,
			"local_off": ready_off,
			"off_deg": off_d,
			"off_off": off_p,
			"phase_t": 0.0,
			"emit_trail": false,
		}

	var start_f := maxf(1.0, float(current_move.startup_frames))
	var act_f := maxf(1.0, float(current_move.active_frames))
	var rec_f := maxf(1.0, float(current_move.recovery_frames))
	var start_end := start_f
	var act_end := start_end + act_f

	var windup_deg := float(_swing_profile.get("windup_deg", -130.0))
	var sweep_end_deg := float(_swing_profile.get("sweep_end_deg", 70.0))
	var overshoot_deg := float(_swing_profile.get("overshoot_deg", 14.0))
	var thrust_dist := float(_swing_profile.get("thrust_dist", 0.0))
	var windup_off: Vector2 = _swing_profile.get("windup_off", Vector2(-7.0, -33.0))
	var active_off: Vector2 = _swing_profile.get("active_off", Vector2(15.0, -29.0))

	var local_deg := ready_deg
	var local_off := active_off
	var phase_t := 0.0
	var emit_trail := false
	var allow_trail := (not current_move.is_projectile) or (wtype == WeaponData.WeaponType.WAND)

	if move_frame < start_end:
		phase_t = clampf(move_frame / start_f, 0.0, 1.0)
		var eased_s := 1.0 - pow(1.0 - phase_t, 2.0)
		local_deg = lerpf(ready_deg, windup_deg, eased_s)
		local_off = ready_off.lerp(windup_off, eased_s)
		if wtype == WeaponData.WeaponType.GREATSWORD or current_move.is_ultimate:
			local_off += Vector2(randf_range(-0.9, 0.9), randf_range(-0.7, 0.7))
	elif move_frame < act_end:
		phase_t = clampf((move_frame - start_end) / act_f, 0.0, 1.0)
		var eased_a := 1.0 - pow(1.0 - phase_t, 3.0)
		var is_dbl := bool(_swing_profile.get("is_double_cross", false))
		var is_flu := bool(_swing_profile.get("is_flurry", false))
		if is_dbl:
			if phase_t < 0.5:
				var sub1 := 1.0 - pow(1.0 - (phase_t * 2.0), 3.0)
				local_deg = lerpf(windup_deg, sweep_end_deg, sub1)
			else:
				var sub2 := 1.0 - pow(1.0 - ((phase_t - 0.5) * 2.0), 3.0)
				local_deg = lerpf(sweep_end_deg, -108.0, sub2)
		elif is_flu:
			local_deg = sin(phase_t * TAU * 3.0) * 26.0
			local_off = active_off + Vector2(sin(phase_t * TAU * 3.0) * thrust_dist, cos(phase_t * TAU * 2.0) * 4.0)
		else:
			local_deg = lerpf(windup_deg, sweep_end_deg, eased_a)
			local_off = windup_off.lerp(active_off, eased_a)
			local_off.x += thrust_dist * sin(phase_t * PI)
		emit_trail = allow_trail
	else:
		phase_t = clampf((move_frame - act_end) / rec_f, 0.0, 1.0)
		var end_deg := -108.0 if bool(_swing_profile.get("is_double_cross", false)) else sweep_end_deg
		var over_angle := end_deg + overshoot_deg
		if phase_t < 0.30:
			var sub_p := phase_t / 0.30
			local_deg = lerpf(end_deg, over_angle, sub_p)
			local_off = active_off
			emit_trail = allow_trail
		else:
			var settle_p := (phase_t - 0.30) / 0.70
			var eased_r := settle_p * settle_p
			local_deg = lerpf(over_angle, ready_deg, eased_r)
			local_off = active_off.lerp(ready_off, eased_r)

	var off_deg := -128.0
	var off_off := Vector2(local_off.x - 6.0, local_off.y - 4.0)
	if dual:
		off_deg = -local_deg * 0.88
		if current_move.is_signature or current_move.is_ultimate:
			off_deg = -local_deg
	elif dual_pistol:
		off_deg = -26.0 if (_pistol_alt and move_phase == "ACTIVE") else 6.0
		off_off = Vector2(5.0, -31.0)

	return {
		"local_deg": local_deg,
		"local_off": local_off,
		"off_deg": off_deg,
		"off_off": off_off,
		"phase_t": phase_t,
		"emit_trail": emit_trail,
	}


func _apply_weapon_pivots(
	wtype: int,
	dual: bool,
	dual_pistol: bool,
	local_deg: float,
	local_off: Vector2,
	off_deg: float,
	_off_off: Vector2,
	elem_col: Color,
	emit_trail: bool
) -> void:
	weapon_pivot.scale = Vector2(float(facing), 1.0)
	offhand_pivot.scale = Vector2(float(facing), 1.0)
	weapon_sprite.flip_h = false
	offhand_weapon_sprite.flip_h = false

	# Lock weapon pivot directly onto the animated PixelRig wrist joint
	weapon_pivot.position = pixel_rig.get_main_hand_local() if pixel_rig != null else Vector2(local_off.x * float(facing), local_off.y)
	weapon_pivot.rotation = deg_to_rad(local_deg * float(facing))

	if dual or dual_pistol:
		offhand_pivot.position = pixel_rig.get_off_hand_local() if pixel_rig != null else Vector2(facing * 5.0, -31.0)
		offhand_pivot.rotation = deg_to_rad(off_deg * float(facing))

	if emit_trail:
		_ensure_trails()
		var geom := _get_weapon_geom(wtype)
		var blade_len := float(geom["blade_len"])
		var guard_x := float(geom["guard_x"])
		if wtype == WeaponData.WeaponType.WAND:
			guard_x = 12.0
			blade_len = 16.0
		if is_instance_valid(_main_trail):
			if _trail_was_active:
				_main_trail.add_arc_samples(weapon_pivot.global_position, guard_x, blade_len, _prev_weapon_rot, weapon_pivot.rotation, facing, elem_col, 4)
			else:
				_main_trail.add_sample(
					weapon_pivot.to_global(Vector2(guard_x, 0.0)),
					weapon_pivot.to_global(Vector2(blade_len, 0.0)),
					elem_col
				)
		if dual and is_instance_valid(_off_trail):
			var off_col := ElementRegistry.get_color(GameState.get_off_element_id())
			if _trail_was_active:
				_off_trail.add_arc_samples(offhand_pivot.global_position, guard_x, blade_len, _prev_off_rot, offhand_pivot.rotation, facing, off_col, 4)
			else:
				_off_trail.add_sample(
					offhand_pivot.to_global(Vector2(guard_x, 0.0)),
					offhand_pivot.to_global(Vector2(blade_len, 0.0)),
					off_col
				)

	_prev_weapon_rot = weapon_pivot.rotation
	_prev_off_rot = offhand_pivot.rotation
	_trail_was_active = emit_trail


func _draw() -> void:
	if not debug_draw_enabled:
		return
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(-8, -41, 16, 40), Color(0.2, 1.0, 0.35, 0.28), true)
	draw_rect(Rect2(-8, -41, 16, 40), Color(0.2, 1.0, 0.35, 0.9), false, 1.0)
	draw_rect(Rect2(-10, -39, 20, 34), Color(1.0, 0.65, 0.15, 0.6), false, 1.0)
	if hitbox.monitoring and hitbox_shape != null and hitbox_shape.shape is RectangleShape2D:
		var r := (hitbox_shape.shape as RectangleShape2D).size
		var box := Rect2(hitbox_shape.position - r * 0.5, r)
		draw_rect(box, Color(1.0, 0.25, 0.25, 0.35), true)
		draw_rect(box, Color(1.0, 0.85, 0.2, 0.95), false, 1.5)
	if font != null:
		var st := "%s | %s F:%d%s" % [State.keys()[state], move_phase, int(move_frame), " [CANCEL]" if hit_confirmed else ""]
		draw_string(font, Vector2(-50, -56), st, HORIZONTAL_ALIGNMENT_CENTER, 160, 8, Color.YELLOW)
