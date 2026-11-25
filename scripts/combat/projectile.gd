class_name CombatProjectile
extends Area2D

var velocity: Vector2 = Vector2(450.0, 0.0)
var damage: float = 14.0
var poise_damage: float = 10.0
var weapon_id: StringName = &"bw_tempest"
var weapon_type: int = 0
var element_id: StringName = &"fire"
var secondary_element_id: StringName = &""
var pierce_left: int = 1
var aoe_radius: float = 0.0
var knockback: Vector2 = Vector2(80.0, -25.0)
var source_player: Node = null
var lifetime: float = 1.4
var is_empowered: bool = false
var _hit_ids: Dictionary = {}


func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 20

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0 if aoe_radius > 0.0 else 5.0
	shape.shape = circle
	add_child(shape)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var col := ElementRegistry.get_color(element_id)
	var dir := velocity.normalized()
	if weapon_type == WeaponData.WeaponType.BOW:
		var tail := -dir * 12.0
		var tip := dir * 6.0
		draw_line(tail, tip, col, 2.0)
		draw_line(dir * 2.0, tip, Color.WHITE, 2.0)
	elif weapon_type == WeaponData.WeaponType.DUAL_PISTOL:
		var tail := -dir * 8.0
		draw_line(tail, dir * 4.0, col, 2.5 if is_empowered else 1.5)
		draw_circle(dir * 3.0, 2.0, Color.WHITE)
	else:
		draw_circle(Vector2.ZERO, 6.0 if aoe_radius > 0.0 else 4.5, col)
		draw_circle(Vector2.ZERO, 2.5, Color.WHITE)


func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target == null or _hit_ids.has(target.get_instance_id()):
		return
	if not target.has_method("take_hit"):
		return
	_hit_ids[target.get_instance_id()] = true

	var hit_info := {
		"damage": damage,
		"poise_damage": poise_damage,
		"weapon_id": weapon_id,
		"weapon_type": weapon_type,
		"element_id": element_id,
		"secondary_element_id": secondary_element_id,
		"knockback": Vector2(signf(velocity.x) * absf(knockback.x), knockback.y),
		"attacker": source_player,
		"is_projectile": true,
		"is_weakpoint_shot": weapon_type == WeaponData.WeaponType.BOW,
	}
	target.take_hit(hit_info)
	if is_instance_valid(source_player) and source_player.has_method("on_attack_hit_confirmed"):
		source_player.on_attack_hit_confirmed(target, true)

	var col := ElementRegistry.get_color(element_id)
	if aoe_radius > 0.0:
		PixelVfx.spawn_ring(get_parent(), global_position, aoe_radius, col)
		_trigger_aoe_splash(target)
	else:
		PixelVfx.spawn_ring(get_parent(), global_position, 14.0, col)

	pierce_left -= 1
	if pierce_left <= 0:
		queue_free()


func _trigger_aoe_splash(primary_target: Node) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for enemy in tree.get_nodes_in_group(&"enemies"):
		if enemy == primary_target or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) <= aoe_radius and enemy.has_method("take_hit"):
			enemy.take_hit({
				"damage": damage * 0.65,
				"poise_damage": poise_damage * 0.6,
				"weapon_id": weapon_id,
				"weapon_type": weapon_type,
				"element_id": element_id,
				"secondary_element_id": secondary_element_id,
				"knockback": (enemy.global_position - global_position).normalized() * 110.0,
				"attacker": source_player,
				"is_projectile": true,
			})


func _on_body_entered(_body: Node) -> void:
	var col := ElementRegistry.get_color(element_id)
	PixelVfx.spawn_ring(get_parent(), global_position, aoe_radius if aoe_radius > 0.0 else 12.0, col)
	queue_free()
