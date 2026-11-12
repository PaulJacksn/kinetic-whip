extends Node2D
## Robot enemy, built from distinct mechanical parts. Hits dismantle it
## part by part; death shatters it. Blue-shielded robots deflect any
## impact below 65% spin speed; above that, the shield shatters.

enum Kind { STANDARD, SHIELDED, RANGED, BOSS }

const SHIELD_BREAK_SPIN := 0.65

var kind: int = Kind.STANDARD
var radius: float = 26.0
var speed: float = 70.0
var damage_to_core: float = 8.0
var parts: Array = []
var shield_on: bool = false
var hit_cooldown: float = 0.0
var shoot_timer: float = 2.0
var want_shoot: bool = false
var minion_timer: float = 5.0
var want_minions: bool = false
var dead: bool = false
var core_pos: Vector2 = Vector2(360, 640)

var _wobble: float = 0.0
var _rng := RandomNumberGenerator.new()
var _flash: float = 0.0
var _shield_flash: float = 0.0
var _boss_max_hp: int = 12
var _body_tex: Texture2D = null
var _hurt_tex: Texture2D = null
var _body_aspect: float = 1.0
var _has_tex_parts: bool = false

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path)
		if t is Texture2D:
			return t
	return null

func setup(p_kind: int, p_pos: Vector2, p_core: Vector2, rng: RandomNumberGenerator) -> void:
	kind = p_kind
	position = p_pos
	core_pos = p_core
	_rng = rng
	_wobble = rng.randf_range(0.0, TAU)
	hit_cooldown = 0.0
	dead = false
	want_shoot = false
	want_minions = false
	_flash = 0.0
	_shield_flash = 0.0
	match kind:
		Kind.STANDARD:
			radius = 26.0
			speed = 70.0
			damage_to_core = 8.0
			shield_on = false
		Kind.SHIELDED:
			radius = 28.0
			speed = 55.0
			damage_to_core = 10.0
			shield_on = true
		Kind.RANGED:
			radius = 26.0
			speed = 62.0
			damage_to_core = 5.0
			shield_on = false
			shoot_timer = rng.randf_range(1.6, 2.6)
		Kind.BOSS:
			radius = 64.0
			speed = 28.0
			damage_to_core = 25.0
			shield_on = true
			_boss_max_hp = 12
			minion_timer = 5.0
	_build_parts()
	queue_redraw()

func _accent() -> Color:
	match kind:
		Kind.SHIELDED:
			return Color(0.35, 0.6, 1.0)
		Kind.RANGED:
			return Color(1.0, 0.5, 0.25)
		Kind.BOSS:
			return Color(1.0, 0.25, 0.3)
	return Color(0.35, 0.95, 1.0)

func _metal() -> Color:
	return Color(0.75, 0.8, 0.88)

func _part(poly: PackedVector2Array, off: Vector2, col: Color, pname: String, tex: Texture2D = null, tex_size: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> Dictionary:
	return {"poly": poly, "off": off, "col": col, "name": pname, "tex": tex, "tex_size": tex_size, "tint": tint}

func _rect_poly(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w / 2, -h / 2), Vector2(w / 2, -h / 2), Vector2(w / 2, h / 2), Vector2(-w / 2, h / 2)])

func _oct_poly(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := float(i) * TAU / 8.0 + PI / 8.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _build_parts() -> void:
	parts.clear()
	_body_tex = null
	_hurt_tex = null
	_body_aspect = 1.0
	_has_tex_parts = false
	var m := _metal()
	var a := _accent()
	var r := radius
	if kind == Kind.STANDARD or kind == Kind.SHIELDED:
		# Real sliced sprites (ArtManOil). Offsets measured on the 48x48
		# frame (robot center 23,23), drawn at 2x. Shielded reuses the same
		# parts with a blue tint; the shield ring marks it.
		var tint := Color(0.72, 0.85, 1.5) if kind == Kind.SHIELDED else Color.WHITE
		parts.append(_part(_rect_poly(r * 1.31, r * 0.54), Vector2(0, r * 0.27), m, "torso", _load_tex("res://assets/art/robots/standard_torso.png"), Vector2(r * 1.31, r * 0.54), tint))
		parts.append(_part(_oct_poly(r * 0.38), Vector2(0, -r * 0.54), a, "head", _load_tex("res://assets/art/robots/standard_head.png"), Vector2(r * 1.15, r * 1.08), tint))
		parts.append(_part(_rect_poly(r * 0.23, r * 0.85), Vector2(-r * 0.58, r * 0.42), m, "arm_l", _load_tex("res://assets/art/robots/standard_arm_l.png"), Vector2(r * 0.23, r * 0.85), tint))
		parts.append(_part(_rect_poly(r * 0.23, r * 0.85), Vector2(r * 0.65, r * 0.42), m, "arm_r", _load_tex("res://assets/art/robots/standard_arm_r.png"), Vector2(r * 0.23, r * 0.85), tint))
		parts.append(_part(_rect_poly(r * 0.69, r * 0.69), Vector2(-r * 0.35, r * 0.88), Color(0.5, 0.55, 0.65), "leg_l", _load_tex("res://assets/art/robots/standard_leg_l.png"), Vector2(r * 0.69, r * 0.69), tint))
		parts.append(_part(_rect_poly(r * 0.69, r * 0.69), Vector2(r * 0.42, r * 0.88), Color(0.5, 0.55, 0.65), "leg_r", _load_tex("res://assets/art/robots/standard_leg_r.png"), Vector2(r * 0.69, r * 0.69), tint))
		_has_tex_parts = true
		return
	if kind == Kind.RANGED:
		# Rigid hover drone (Sova): one whole-body sprite, no separable
		# limbs. Parts exist for HP only; their debris uses the body texture.
		_body_tex = _load_tex("res://assets/art/robots/ranged_idle.png")
		_hurt_tex = _load_tex("res://assets/art/robots/ranged_hurt.png")
		_body_aspect = 128.0 / 148.0
		var chunk := Vector2(r * 0.7, r * 0.7)
		parts.append(_part(_rect_poly(r * 0.95, r * 0.85), Vector2(0, 0), m, "torso", _body_tex, chunk))
		parts.append(_part(_oct_poly(r * 0.38), Vector2(0, -r * 0.58), a, "head", _body_tex, chunk))
		parts.append(_part(_rect_poly(r * 0.2, r * 0.7), Vector2(-r * 0.52, r * 0.1), m, "arm_l", _body_tex, chunk))
		parts.append(_part(_rect_poly(r * 0.2, r * 0.7), Vector2(r * 0.52, r * 0.1), m, "arm_r", _body_tex, chunk))
		parts.append(_part(_rect_poly(r * 0.26, r * 0.42), Vector2(-r * 0.26, r * 0.58), Color(0.5, 0.55, 0.65), "leg_l", _body_tex, chunk))
		parts.append(_part(_rect_poly(r * 0.26, r * 0.42), Vector2(r * 0.26, r * 0.58), Color(0.5, 0.55, 0.65), "leg_r", _body_tex, chunk))
		parts.append(_part(_rect_poly(r * 0.5, r * 0.16), Vector2(0, -r * 0.28), Color(1.0, 0.5, 0.25), "cannon", _body_tex, chunk))
		return
	# BOSS: whole-body red drone sprite + a real crown icon on top.
	_body_tex = _load_tex("res://assets/art/robots/boss_idle.png")
	_body_aspect = 192.0 / 222.0
	var crown_tex := _load_tex("res://assets/art/robots/boss_crown.png")
	var bchunk := Vector2(r * 0.7, r * 0.7)
	parts.append(_part(_rect_poly(r * 1.1, r * 0.9), Vector2(0, 0), m, "torso", _body_tex, bchunk))
	parts.append(_part(_oct_poly(r * 0.42), Vector2(0, -r * 0.62), a, "head", _body_tex, bchunk))
	parts.append(_part(_rect_poly(r * 0.5, r * 0.28), Vector2(-r * 0.62, -r * 0.35), m, "shoulder_l", _body_tex, bchunk))
	parts.append(_part(_rect_poly(r * 0.5, r * 0.28), Vector2(r * 0.62, -r * 0.35), m, "shoulder_r", _body_tex, bchunk))
	parts.append(_part(_rect_poly(r * 0.22, r * 0.8), Vector2(-r * 0.55, r * 0.15), m, "arm_l", _body_tex, bchunk))
	parts.append(_part(_rect_poly(r * 0.22, r * 0.8), Vector2(r * 0.55, r * 0.15), m, "arm_r", _body_tex, bchunk))
	parts.append(_part(_rect_poly(r * 0.3, r * 0.4), Vector2(-r * 0.3, r * 0.62), Color(0.5, 0.55, 0.65), "leg_l", _body_tex, bchunk))
	parts.append(_part(_rect_poly(r * 0.3, r * 0.4), Vector2(r * 0.3, r * 0.62), Color(0.5, 0.55, 0.65), "leg_r", _body_tex, bchunk))
	parts.append(_part(_oct_poly(r * 0.2), Vector2(0, -r * 1.05), Color(1.0, 0.8, 0.2), "crown", crown_tex, Vector2(r * 0.62, r * 0.62)))
	parts.append(_part(_rect_poly(r * 0.9, r * 0.18), Vector2(0, r * 0.28), a, "chestplate", _body_tex, bchunk))
	parts.append(_part(_oct_poly(r * 0.14), Vector2(-r * 0.25, -r * 0.62), Color(1, 1, 1), "eye_l", _body_tex, Vector2(r * 0.5, r * 0.5)))
	parts.append(_part(_oct_poly(r * 0.14), Vector2(r * 0.25, -r * 0.62), Color(1, 1, 1), "eye_r", _body_tex, Vector2(r * 0.5, r * 0.5)))

func hp() -> int:
	return parts.size()

func max_hp() -> int:
	if kind == Kind.BOSS:
		return _boss_max_hp
	if kind == Kind.RANGED:
		return 7
	return 6

## Returns {deflected, shield_broken, died, lost: Array of part dicts}
func take_hit(dmg_parts: int, spin_ratio: float, hit_dir: Vector2) -> Dictionary:
	var res := {"deflected": false, "shield_broken": false, "died": false, "lost": []}
	if dead:
		return res
	if hit_cooldown > 0.0:
		return res
	if shield_on:
		if spin_ratio < SHIELD_BREAK_SPIN:
			_shield_flash = 1.0
			res["deflected"] = true
			hit_cooldown = 0.18
			return res
		shield_on = false
		_shield_flash = 1.0
		res["shield_broken"] = true
		# A shield-breaking hit still deals damage below.
	hit_cooldown = 0.22
	_flash = 1.0
	var lost: Array = []
	var n := mini(dmg_parts, parts.size())
	for i in n:
		lost.append(parts.pop_back())
	res["lost"] = lost
	if parts.is_empty():
		dead = true
		res["died"] = true
	# Boss shield phases: shield returns at 66% and 33% hp.
	if kind == Kind.BOSS and not dead:
		var frac := float(parts.size()) / float(_boss_max_hp)
		if (frac <= 0.66 and frac > 0.5) or frac <= 0.33:
			if not shield_on and _rng.randf() < 1.0:
				shield_on = true
	return res

func update(delta: float) -> void:
	_wobble += delta * 3.0
	_flash = maxf(0.0, _flash - delta * 4.0)
	_shield_flash = maxf(0.0, _shield_flash - delta * 3.0)
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	if dead:
		return
	var to_core := core_pos - position
	var dist := to_core.length()
	var dir := to_core / maxf(dist, 0.001)
	var strafe := Vector2(-dir.y, dir.x) * sin(_wobble * 0.7) * 0.4
	if kind == Kind.RANGED and dist < 330.0:
		# Hold range, strafe, shoot.
		position += strafe * speed * delta
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = 2.4
			want_shoot = true
	else:
		position += (dir + strafe * 0.5) * speed * delta
	if kind == Kind.BOSS:
		minion_timer -= delta
		if minion_timer <= 0.0:
			minion_timer = 6.0
			want_minions = true
	queue_redraw()

func _draw() -> void:
	if dead:
		return
	# Glow under the robot
	var ac := _accent()
	draw_circle(Vector2.ZERO, radius * 1.15, Color(ac, 0.14))
	var mod := Color(1, 1, 1)
	if _flash > 0.0:
		mod = Color(1, 1, 1).lerp(Color(2, 2, 2), _flash * 0.7)
	if _body_tex != null:
		# Whole-body sprite (rigid drone / boss). Hurt frame when half gone.
		var btex: Texture2D = _body_tex
		if _hurt_tex != null and parts.size() <= max_hp() / 2:
			btex = _hurt_tex
		var bsize := Vector2(radius * 2.0, radius * 2.0 * _body_aspect)
		draw_texture_rect(btex, Rect2(-bsize * 0.5, bsize), false, mod)
		# The crown is the only separately drawn part on a body sprite.
		for part in parts:
			if String(part["name"]) == "crown" and part["tex"] != null:
				var cts: Vector2 = part["tex_size"]
				var coff: Vector2 = part["off"]
				draw_texture_rect(part["tex"], Rect2(coff - cts * 0.5, cts), false, mod)
	else:
		# Parts: real sliced sprites for standard/shielded, polygons fallback.
		for part in parts:
			var off: Vector2 = part["off"]
			if part["tex"] != null:
				var ts: Vector2 = part["tex_size"]
				var tint: Color = part["tint"]
				draw_texture_rect(part["tex"], Rect2(off - ts * 0.5, ts), false, mod * tint)
			else:
				var poly: PackedVector2Array = part["poly"]
				var moved := PackedVector2Array()
				for p in poly:
					moved.append(p + off)
				var col: Color = part["col"]
				if _flash > 0.0:
					col = col.lerp(Color(1, 1, 1), _flash * 0.7)
				draw_colored_polygon(moved, col)
				var outline := PackedVector2Array(moved)
				outline.append(moved[0])
				draw_polyline(outline, Color(0.05, 0.06, 0.1, 0.9), 1.5)
	# Eye glow (only for polygon-drawn robots; sprite heads have eyes).
	if not _has_tex_parts and _body_tex == null and not parts.is_empty():
		draw_circle(Vector2(0, -radius * 0.58), 3.0, Color(1, 1, 1, 0.9))
	# Shield ring
	if shield_on:
		var sc := Color(0.35, 0.65, 1.0, 0.75 + _shield_flash * 0.25)
		draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 40, sc, 3.0)
		draw_arc(Vector2.ZERO, radius + 16.0, 0.0, TAU, 40, Color(sc, 0.3), 6.0)
		# Shield hex facets
		for i in 6:
			var a := float(i) * TAU / 6.0 + _wobble * 0.2
			var p := Vector2(cos(a), sin(a)) * (radius + 10.0)
			draw_circle(p, 2.5, Color(0.7, 0.85, 1.0, 0.8))
	# Boss HP bar
	if kind == Kind.BOSS:
		var w := 110.0
		var frac := float(parts.size()) / float(_boss_max_hp)
		draw_rect(Rect2(-w / 2, -radius - 34.0, w, 7.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, -radius - 34.0, w * frac, 7.0), Color(1.0, 0.25, 0.3))
