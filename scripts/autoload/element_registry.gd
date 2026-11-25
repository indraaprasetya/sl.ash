extends Node

const ELEMENT_ORDER: Array = [&"fire", &"ice", &"lightning", &"wind", &"void"]

var elements: Dictionary = {}


func _ready() -> void:
	elements = {
		&"fire": {
			"id": &"fire",
			"name": "Fire",
			"short": "FIR",
			"color": Color(1.0, 0.40, 0.22, 1.0),
			"glow_color": Color(1.0, 0.56, 0.20, 1.0),
			"status": &"burn",
			"dot_dps": 8.0,
			"speed_mult": 1.0,
			"resist_shred": 0.0,
			"description": "Applies Burn DoT and explodes into Thermal Shatter with Ice.",
		},
		&"ice": {
			"id": &"ice",
			"name": "Ice",
			"short": "ICE",
			"color": Color(0.40, 0.88, 1.0, 1.0),
			"glow_color": Color(0.55, 0.94, 1.0, 1.0),
			"status": &"chill",
			"dot_dps": 2.0,
			"speed_mult": 0.62,
			"resist_shred": 0.0,
			"description": "Chills & slows enemies; triggers Thermal Shatter with Fire.",
		},
		&"lightning": {
			"id": &"lightning",
			"name": "Lightning",
			"short": "LTN",
			"color": Color(1.0, 0.86, 0.28, 1.0),
			"glow_color": Color(1.0, 0.92, 0.45, 1.0),
			"status": &"shock",
			"dot_dps": 4.5,
			"speed_mult": 0.90,
			"resist_shred": 0.0,
			"description": "Chains shock hits and interrupts enemy casts.",
		},
		&"wind": {
			"id": &"wind",
			"name": "Wind",
			"short": "WND",
			"color": Color(0.45, 0.96, 0.66, 1.0),
			"glow_color": Color(0.58, 1.0, 0.76, 1.0),
			"status": &"gale",
			"dot_dps": 3.0,
			"speed_mult": 1.0,
			"resist_shred": 0.0,
			"description": "Lifts enemies for aerial juggles; triggers Storm Pull with Lightning.",
		},
		&"void": {
			"id": &"void",
			"name": "Void",
			"short": "VOD",
			"color": Color(0.76, 0.42, 1.0, 1.0),
			"glow_color": Color(0.84, 0.56, 1.0, 1.0),
			"status": &"corrosion",
			"dot_dps": 6.0,
			"speed_mult": 0.88,
			"resist_shred": 0.30,
			"description": "Shreds armor & blocks regen; triggers Astral Implosion with any element.",
		},
	}


func get_element(elem_id: StringName) -> Dictionary:
	if elements.has(elem_id):
		return elements[elem_id]
	return elements[&"fire"]


func get_color(elem_id: StringName) -> Color:
	var data: Dictionary = get_element(elem_id)
	return data.get("color", Color.WHITE)


func resolve_reaction(elem_a: StringName, elem_b: StringName) -> Dictionary:
	if elem_a == elem_b or elem_a == &"" or elem_b == &"":
		return {}
	var pair: Array[String] = [String(elem_a), String(elem_b)]
	pair.sort()
	var key: String = pair[0] + "+" + pair[1]
	if elem_a == &"void" or elem_b == &"void":
		return {
			"id": &"astral_implosion",
			"name": "ASTRAL IMPLOSION",
			"color": Color(0.86, 0.48, 1.0, 1.0),
			"bonus_damage": 38.0,
			"aoe_radius": 76.0,
			"stagger_bonus": 34.0,
			"pull_strength": 150.0,
		}
	match key:
		"fire+ice":
			return {
				"id": &"thermal_shatter",
				"name": "THERMAL SHATTER",
				"color": Color(1.0, 0.68, 0.38, 1.0),
				"bonus_damage": 46.0,
				"aoe_radius": 72.0,
				"stagger_bonus": 30.0,
				"pull_strength": 0.0,
			}
		"lightning+wind":
			return {
				"id": &"storm_pull",
				"name": "STORM PULL",
				"color": Color(0.62, 1.0, 0.84, 1.0),
				"bonus_damage": 34.0,
				"aoe_radius": 96.0,
				"stagger_bonus": 26.0,
				"pull_strength": 210.0,
			}
		"fire+lightning":
			return {
				"id": &"overload",
				"name": "OVERLOAD BLAST",
				"color": Color(1.0, 0.56, 0.22, 1.0),
				"bonus_damage": 42.0,
				"aoe_radius": 84.0,
				"stagger_bonus": 38.0,
				"pull_strength": -140.0,
			}
		"ice+wind":
			return {
				"id": &"frost_nova",
				"name": "FROST NOVA",
				"color": Color(0.55, 0.94, 1.0, 1.0),
				"bonus_damage": 32.0,
				"aoe_radius": 88.0,
				"stagger_bonus": 24.0,
				"pull_strength": 0.0,
			}
		"fire+wind":
			return {
				"id": &"blazing_gale",
				"name": "BLAZING GALE",
				"color": Color(1.0, 0.54, 0.32, 1.0),
				"bonus_damage": 36.0,
				"aoe_radius": 82.0,
				"stagger_bonus": 22.0,
				"pull_strength": 95.0,
			}
		"ice+lightning":
			return {
				"id": &"superconduct",
				"name": "SUPERCONDUCT",
				"color": Color(0.75, 0.90, 1.0, 1.0),
				"bonus_damage": 35.0,
				"aoe_radius": 78.0,
				"stagger_bonus": 32.0,
				"pull_strength": 0.0,
			}
	return {}
