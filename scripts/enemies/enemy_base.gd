class_name EnemyBase
extends CharacterBody2D

enum AiState {
	IDLE,
	CHASE,
	WINDUP,
	ATTACK,
	STAGGERED,
	DEAD,
}

@export var archetype_id: StringName = &"agile_duelist"

var display_name: String = "Enemy"
var max_hp: float = 150.0
var hp: float = 150.0
var max_armor: float = 0.0
var armor: float = 0.0
var max_poise: float = 80.0
var poise: float = 80.0
var hit_barrier: int = 0
var max_hit_barrier: int = 0
var phys_resist: float = 0.0
var is_flying: bool = false
var hover_base_y: float = 0.0

var ai_state: int = AiState.IDLE
var facing: int = -1
var hitstop_timer: float = 0.0
var state_timer: float = 0.0
var attack_cooldown: float = 1.0
var blink_cooldown: float = 3.0
var regen_delay_timer: float = 0.0
var current_attack_parryable: bool = true
var flash_timer: float = 0.0
var micro_stun_timer: float = 0.0

var active_statuses: Dictionary = {}
var _dot_accum: float = 0.0
var _wall_splat_ready: bool = false

var sprite: Sprite2D
var hurtbox: Area2D
var _shader_mat: ShaderMaterial = null
var _sprite_scale: Vector2 = Vector2.ONE
var _anim_time: float = 0.0
var _sprite_rot: float = 0.0
var _sprite_bob_y: float = 0.0


func _ready() -> void:
	add_to_group(&"enemies")
	collision_layer = 0
	collision_mask = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anim_time = float(get_instance_id() % 100) * 0.07

	_configure_archetype()
	_build_nodes()
	hover_base_y = global_position.y


func _configure_archetype() -> void:
	match archetype_id:
		&"training_dummy":
			display_name = "Training Dummy"
			max_hp = 240.0
			max_poise = 999.0
		&"armored_sentinel":
			display_name = "Armored Sentinel"
			max_hp = 210.0
			max_armor = 120.0
			max_poise = 120.0
		&"agile_duelist":
			display_name = "Agile Duelist"
			max_hp = 155.0
			max_poise = 75.0
		&"barrier_wraith":
			display_name = "Barrier Wraith"
			max_hp = 145.0
			max_hit_barrier = 10
			hit_barrier = 10
			max_poise = 80.0
		&"sky_hawker":
			display_name = "Sky Hawker"
			max_hp = 135.0
			max_poise = 65.0
			is_flying = true
		&"blink_stalker":
			display_name = "Blink Stalker"
			max_hp = 150.0
			max_poise = 70.0
		&"astral_phantom":
			display_name = "Astral Phantom"
			max_hp = 185.0
			max_poise = 75.0
			phys_resist = 0.75
			is_flying = true

	hp = max_hp
	armor = max_armor
	poise = max_poise


func _build_nodes() -> void:
	var col_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 46)
	col_shape.shape = rect
	col_shape.position = Vector2(0, -23)
	add_child(col_shape)

	sprite = Sprite2D.new()
	var sp_path := "res://assets/sprites/enemies/%s.png" % String(archetype_id)
	if ResourceLoader.exists(sp_path):
		sprite.texture = load(sp_path)
	sprite.offset = Vector2(0, -32)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var shader_path := "res://assets/shaders/elemental_infusion.gdshader"
	if ResourceLoader.exists(shader_path):
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = load(shader_path)
		sprite.material = _shader_mat
	add_child(sprite)

	hurtbox = Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 8
	var hb := CollisionShape2D.new()
	var hbrect := RectangleShape2D.new()
	hbrect.size = Vector2(28, 48)
	hb.shape = hbrect
	hb.position = Vector2(0, -24)
	hurtbox.add_child(hb)
	add_child(hurtbox)


func is_alive() -> bool:
	return ai_state != AiState.DEAD and hp > 0.0


func apply_hitstop(duration: float) -> void:
	hitstop_timer = maxf(hitstop_timer, duration)


func apply_micro_stun(duration: float) -> void:
	micro_stun_timer = maxf(micro_stun_timer, duration)
	if ai_state == AiState.WINDUP:
		ai_state = AiState.STAGGERED
		state_timer = duration
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -56), "VAULT INTERRUPT!", Color(1.0, 0.9, 0.35), 0.9)


func _physics_process(delta: float) -> void:
	_anim_time += delta
	if flash_timer > 0.0:
		flash_timer = maxf(0.0, flash_timer - delta)
	_process_statuses(delta)

	if hitstop_timer > 0.0:
		hitstop_timer -= delta
		if sprite != null:
			sprite.position = Vector2(randf_range(-2.2, 2.2), randf_range(-1.2, 1.2) + _sprite_bob_y)
		return

	if ai_state == AiState.DEAD:
		return

	if regen_delay_timer > 0.0:
		regen_delay_timer -= delta
	elif archetype_id == &"blink_stalker" and hp < max_hp:
		hp = minf(max_hp, hp + 8.0 * delta)

	if micro_stun_timer > 0.0:
		micro_stun_timer -= delta

	var player := _find_player()
	if archetype_id == &"training_dummy":
		velocity.x = move_toward(velocity.x, 0.0, 750.0 * delta)
		velocity.y = minf(420.0, velocity.y + 1150.0 * delta)
		move_and_slide()
		queue_redraw()
		return

	if not is_flying:
		velocity.y = minf(440.0, velocity.y + 1180.0 * delta)
	else:
		var target_y := hover_base_y + sin(Time.get_ticks_msec() * 0.004) * 10.0
		velocity.y = move_toward(velocity.y, (target_y - global_position.y) * 3.5, 420.0 * delta)

	var chill_mult := 0.62 if active_statuses.has(&"ice") else 1.0

	match ai_state:
		AiState.IDLE, AiState.CHASE:
			if player != null:
				var dx := player.global_position.x - global_position.x
				facing = 1 if dx >= 0.0 else -1
				var dist := global_position.distance_to(player.global_position)
				if archetype_id == &"blink_stalker":
					blink_cooldown -= delta
					if blink_cooldown <= 0.0 and dist < 210.0:
						_do_blink_away(player)
				attack_cooldown -= delta * chill_mult
				var attack_range := 145.0 if is_flying else 56.0
				if dist > attack_range and dist < 340.0:
					var spd := 95.0 if archetype_id != &"armored_sentinel" else 60.0
					velocity.x = move_toward(velocity.x, facing * spd * chill_mult, 600.0 * delta)
				else:
					velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
				if dist <= attack_range + 12.0 and attack_cooldown <= 0.0:
					_begin_windup()
			else:
				velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		AiState.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			state_timer -= delta * chill_mult
			if state_timer <= 0.0:
				_execute_enemy_attack(player)
		AiState.ATTACK:
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta)
			if state_timer <= 0.0:
				ai_state = AiState.CHASE
				attack_cooldown = 1.25
		AiState.STAGGERED:
			state_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 520.0 * delta)
			if _wall_splat_ready and is_on_wall() and absf(velocity.x) > 85.0:
				_trigger_wall_splat()
			if state_timer <= 0.0:
				_wall_splat_ready = false
				poise = max_poise
				if archetype_id == &"barrier_wraith" and hit_barrier <= 0:
					hit_barrier = max_hit_barrier
				ai_state = AiState.CHASE

	move_and_slide()
	_update_enemy_pose(delta)
	_update_shader()
	queue_redraw()


func _update_enemy_pose(delta: float) -> void:
	if sprite == null:
		return
	sprite.flip_h = facing > 0
	var target_scale := Vector2.ONE
	var target_rot := 0.0
	var target_bob := 0.0
	var tremor_x := 0.0

	if ai_state == AiState.WINDUP:
		target_rot = -float(facing) * 0.16
		target_scale = Vector2(0.88, 1.12)
		if state_timer < 0.14:
			tremor_x = randf_range(-1.2, 1.2)
	elif ai_state == AiState.ATTACK:
		target_rot = float(facing) * 0.22
		target_scale = Vector2(1.18, 0.86)
	elif ai_state == AiState.STAGGERED:
		target_rot = sin(_anim_time * 18.0) * 0.14
		target_scale = Vector2(1.06, 0.92)
		target_bob = 2.0
	elif absf(velocity.x) > 15.0 and not is_flying:
		target_rot = float(facing) * 0.08
		target_bob = -absf(sin(_anim_time * 10.5)) * 2.4
		target_scale = Vector2(1.0 + cos(_anim_time * 21.0) * 0.04, 1.0 - cos(_anim_time * 21.0) * 0.04)
	else:
		var breath := sin(_anim_time * 2.8) * 0.035
		target_scale = Vector2(1.0 - breath, 1.0 + breath)

	var k := clampf(delta * 14.0, 0.0, 1.0)
	_sprite_scale = _sprite_scale.lerp(target_scale, k)
	_sprite_rot = lerpf(_sprite_rot, target_rot, k)
	_sprite_bob_y = lerpf(_sprite_bob_y, target_bob, k)
	sprite.scale = _sprite_scale
	sprite.rotation = _sprite_rot
	sprite.position = Vector2(tremor_x, _sprite_bob_y)


func _begin_windup() -> void:
	ai_state = AiState.WINDUP
	if archetype_id == &"armored_sentinel":
		current_attack_parryable = false
		state_timer = 0.62
	elif archetype_id == &"agile_duelist":
		current_attack_parryable = true
		state_timer = 0.36
	else:
		current_attack_parryable = (randf() > 0.35)
		state_timer = 0.48


func _execute_enemy_attack(player: Node2D) -> void:
	ai_state = AiState.ATTACK
	state_timer = 0.25
	if player == null:
		return

	if is_flying:
		# Sky Hawker / Astral Phantom dive or bolt reach
		velocity.x = facing * 130.0
	else:
		velocity.x = facing * 145.0

	var dist := global_position.distance_to(player.global_position)
	if (dist <= 68.0 or (is_flying and dist <= 135.0)) and player.has_method("take_enemy_hit"):
		var dmg := 18.0 if archetype_id == &"armored_sentinel" else 13.0
		player.take_enemy_hit(dmg, self, current_attack_parryable, Vector2(facing * 140.0, -75.0))


func _do_blink_away(player: Node2D) -> void:
	blink_cooldown = 3.2
	var away := -signf(player.global_position.x - global_position.x)
	if away == 0.0:
		away = 1.0
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 22.0, Color(0.78, 0.42, 1.0))
	global_position.x += away * 88.0
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 22.0, Color(0.78, 0.42, 1.0))


func _trigger_wall_splat() -> void:
	_wall_splat_ready = false
	state_timer += 0.75
	hp = maxf(1.0, hp - 28.0)
	_sprite_scale = Vector2(0.72, 1.32)
	SfxManager.play_sfx(&"reaction", -4.0)
	HitstopManager.request_shake(0.32)
	HitstopManager.request_punch(Vector2(signf(velocity.x) * 6.0, 0.0), 0.03)
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 38.0, Color(1.0, 0.65, 0.28))
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -56), "WALL-SPLAT! -28", Color(1.0, 0.72, 0.25), 1.05)


func _process_statuses(delta: float) -> void:
	if active_statuses.is_empty():
		return
	var expired: Array = []
	_dot_accum += delta
	for k in active_statuses.keys():
		active_statuses[k] = float(active_statuses[k]) - delta
		if float(active_statuses[k]) <= 0.0:
			expired.append(k)
	for k in expired:
		active_statuses.erase(k)

	if _dot_accum >= 0.5:
		_dot_accum = 0.0
		var dot := 0.0
		for k in active_statuses.keys():
			dot += float(ElementRegistry.get_element(k).get("dot_dps", 0.0)) * 0.5
		if dot > 0.0 and archetype_id != &"training_dummy":
			hp = maxf(1.0, hp - dot)


func take_hit(hit_info: Dictionary) -> void:
	if ai_state == AiState.DEAD:
		return

	var dmg := float(hit_info.get("damage", 15.0))
	var poise_dmg := float(hit_info.get("poise_damage", 12.0))
	var wtype := int(hit_info.get("weapon_type", -1))
	var elem_id := StringName(hit_info.get("element_id", &""))
	var sec_elem := StringName(hit_info.get("secondary_element_id", &""))
	var attacker = hit_info.get("attacker", null)
	var is_parry_riposte := bool(hit_info.get("is_parry_riposte", false))

	regen_delay_timer = 2.6
	flash_timer = 0.12
	_sprite_scale = Vector2(0.78, 1.24)

	# 1. Soft-Counter Archetype Interactions
	var counter_badge := ""
	var badge_col := Color.WHITE

	if archetype_id == &"armored_sentinel" and armor > 0.0:
		var arm_break := poise_dmg * (2.8 if wtype == WeaponData.WeaponType.GREATSWORD else 0.75)
		armor = maxf(0.0, armor - arm_break)
		dmg *= 0.85 if wtype == WeaponData.WeaponType.GREATSWORD else 0.55
		if armor <= 0.0:
			counter_badge = "ARMOR SHATTERED!"
			badge_col = Color(1.0, 0.78, 0.25)
			ai_state = AiState.STAGGERED
			state_timer = 1.6
	elif archetype_id == &"barrier_wraith" and hit_barrier > 0:
		hit_barrier = maxi(0, hit_barrier - 1)
		dmg *= 0.38
		if hit_barrier <= 0:
			counter_badge = "BARRIER BROKEN!"
			badge_col = Color(0.55, 0.95, 1.0)
			ai_state = AiState.STAGGERED
			state_timer = 1.8
	elif archetype_id == &"sky_hawker" and wtype == WeaponData.WeaponType.BOW:
		dmg *= 2.6
		poise_dmg *= 2.0
		counter_badge = "WEAKPOINT 2.6x!"
		badge_col = Color(1.0, 0.92, 0.35)
	elif archetype_id == &"blink_stalker" and wtype == WeaponData.WeaponType.DUAL_PISTOL:
		dmg *= 1.85
		blink_cooldown = maxf(blink_cooldown, 2.8)
		counter_badge = "BLINK SUPPRESSED!"
		badge_col = Color(0.75, 0.95, 1.0)
	elif archetype_id == &"astral_phantom":
		if wtype == WeaponData.WeaponType.WAND:
			dmg *= 2.35
			counter_badge = "ELEMENTAL WEAKNESS!"
			badge_col = Color(0.55, 0.92, 1.0)
		else:
			dmg *= (1.0 - phys_resist) + 0.35
	elif archetype_id == &"agile_duelist" and is_parry_riposte:
		dmg *= 2.8
		counter_badge = "DUELIST BROKEN!"
		badge_col = Color(1.0, 0.92, 0.35)

	if active_statuses.has(&"void"):
		dmg *= 1.30

	# 2. Elemental Application & Cross-Element Reaction
	var elem_col := ElementRegistry.get_color(elem_id)
	var reaction_triggered := false
	if elem_id != &"":
		for existing in active_statuses.keys():
			if existing != elem_id:
				var react := ElementRegistry.resolve_reaction(existing, elem_id)
				if not react.is_empty():
					reaction_triggered = true
					_apply_reaction(react, attacker)
					active_statuses.erase(existing)
					break
		active_statuses[elem_id] = 4.5

	if sec_elem != &"" and sec_elem != elem_id:
		var dual_react := ElementRegistry.resolve_reaction(elem_id, sec_elem)
		if not dual_react.is_empty() and not reaction_triggered:
			_apply_reaction(dual_react, attacker)

	# 3. Apply HP, Poise, Knockback & Wall-Splat setup
	hp = maxf(0.0, hp - dmg)
	var kb: Vector2 = hit_info.get("knockback", Vector2(80.0, -30.0))
	if armor <= 0.0 and hit_barrier <= 0:
		poise -= poise_dmg
		velocity = kb
		if absf(kb.x) >= 180.0:
			_wall_splat_ready = true
		if poise <= 0.0 and archetype_id != &"training_dummy":
			ai_state = AiState.STAGGERED
			state_timer = 1.15
	else:
		velocity.x = kb.x * 0.25

	var dmg_txt := "%d" % int(round(dmg))
	var hit_dir := 1 if kb.x >= 0.0 else -1
	PixelVfx.spawn_hit_spark(get_parent(), global_position + Vector2(0, -24), hit_dir, elem_col, 16.0)
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(randf_range(-10, 10), -46), dmg_txt, elem_col, 1.05 if counter_badge != "" else 0.9)
	if counter_badge != "":
		SfxManager.play_sfx(&"hit_counter", -4.5)
		PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -64), counter_badge, badge_col, 0.95)

	if hp <= 0.0:
		if archetype_id == &"training_dummy":
			hp = max_hp
			PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -64), "DUMMY RESET", Color(0.65, 1.0, 0.65), 0.9)
		else:
			_die()


func detonate_statuses(attacker: Node, trigger_elem: StringName) -> void:
	var count := active_statuses.size()
	if count == 0:
		return
	var burst := 42.0 * float(count)
	var first_elem := StringName(active_statuses.keys()[0])
	var react := ElementRegistry.resolve_reaction(first_elem, trigger_elem)
	active_statuses.clear()
	hp = maxf(0.0, hp - burst)
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 56.0, ElementRegistry.get_color(trigger_elem))
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -60), "DETONATE -%d!" % int(burst), Color(0.55, 0.95, 1.0), 1.1)
	if not react.is_empty():
		_apply_reaction(react, attacker)
	if hp <= 0.0 and archetype_id != &"training_dummy":
		_die()


func _apply_reaction(react: Dictionary, attacker: Node) -> void:
	var bonus := float(react.get("bonus_damage", 32.0))
	if archetype_id == &"astral_phantom":
		bonus *= 2.0
	hp = maxf(0.0, hp - bonus)
	poise -= float(react.get("stagger_bonus", 24.0))
	var col: Color = react.get("color", Color.WHITE)
	var rname: String = react.get("name", "REACTION")
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), float(react.get("aoe_radius", 68.0)), col, true, Color.WHITE)
	PixelVfx.spawn_text(get_parent(), global_position + Vector2(0, -72), "%s! -%d" % [rname, int(bonus)], col, 1.05)
	SfxManager.play_sfx(&"reaction", -4.5)
	HitstopManager.request_shake(0.32)
	HitstopManager.request_punch(Vector2(0.0, -3.5), 0.035)

	if is_instance_valid(attacker) and attacker.has_method("on_elemental_reaction_triggered"):
		attacker.on_elemental_reaction_triggered()


func _die() -> void:
	ai_state = AiState.DEAD
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	PixelVfx.spawn_ring(get_parent(), global_position + Vector2(0, -24), 48.0, Color(1.0, 0.85, 0.38))
	GameState.roll_enemy_drop(archetype_id)
	queue_free()


func _find_player() -> Node2D:
	var players := get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return null
	return players[0] as Node2D


func _update_shader() -> void:
	if _shader_mat == null:
		return
	var col := Color.WHITE
	var glow := 0.0
	if not active_statuses.is_empty():
		var first := StringName(active_statuses.keys()[0])
		col = ElementRegistry.get_color(first)
		glow = 0.85
	_shader_mat.set_shader_parameter("element_color", col)
	_shader_mat.set_shader_parameter("glow_strength", glow)
	_shader_mat.set_shader_parameter("flash_amount", 0.85 if flash_timer > 0.0 else 0.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	# HP Bar above enemy
	var bar_w := 36.0
	var hp_ratio := clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0)
	draw_rect(Rect2(-bar_w * 0.5, -52, bar_w, 4), Color(0.08, 0.08, 0.12, 0.9))
	draw_rect(Rect2(-bar_w * 0.5, -52, bar_w * hp_ratio, 4), Color(0.92, 0.28, 0.34, 1.0))

	if armor > 0.0:
		var ar_ratio := clampf(armor / maxf(max_armor, 1.0), 0.0, 1.0)
		draw_rect(Rect2(-bar_w * 0.5, -57, bar_w * ar_ratio, 3), Color(0.95, 0.72, 0.25, 1.0))
	elif hit_barrier > 0:
		var br_ratio := float(hit_barrier) / float(max_hit_barrier)
		draw_rect(Rect2(-bar_w * 0.5, -57, bar_w * br_ratio, 3), Color(0.45, 0.92, 1.0, 1.0))

	# Colored Telegraph Ring during WINDUP
	if ai_state == AiState.WINDUP:
		var tcol := Color(1.0, 0.9, 0.22, 0.92) if current_attack_parryable else Color(1.0, 0.22, 0.24, 0.92)
		draw_arc(Vector2(0, -24), 24.0, 0.0, TAU, 18, tcol, 2.5)
		if font != null:
			var tlbl := "PARRY [I]" if current_attack_parryable else "DODGE/VAULT!"
			draw_string(font, Vector2(-32, -64), tlbl, HORIZONTAL_ALIGNMENT_CENTER, 76, 8, tcol)

	if font != null and archetype_id != &"training_dummy":
		var hint := display_name
		if hit_barrier > 0:
			hint += " [%d hits]" % hit_barrier
		draw_string(font, Vector2(-55, -60 if ai_state != AiState.WINDUP else -73), hint, HORIZONTAL_ALIGNMENT_CENTER, 110, 8, Color(0.86, 0.9, 0.98, 0.9))
