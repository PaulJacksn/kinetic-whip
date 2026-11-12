extends Node2D
## Neural core: the glowing orb the player defends. Integrity 0..100.
## Integrity visibly affects the weapons (see main: weapon_condition).

const RADIUS := 46.0

var integrity: float = 100.0
var max_integrity: float = 100.0
var _time: float = 0.0
var _hit_flash: float = 0.0
var _ring_rot: float = 0.0
var _orb_tex: Texture2D = null
var _glow_tex: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/art/core/orb.png"):
		_orb_tex = load("res://assets/art/core/orb.png")
	if ResourceLoader.exists("res://assets/art/core/glow.png"):
		_glow_tex = load("res://assets/art/core/glow.png")

func reset() -> void:
	integrity = max_integrity
	_hit_flash = 0.0

func condition() -> float:
	return clampf(integrity / max_integrity, 0.0, 1.0)

func damage(amount: float) -> void:
	integrity = maxf(0.0, integrity - amount)
	_hit_flash = 1.0

func repair(amount: float) -> void:
	integrity = minf(max_integrity, integrity + amount)

func _process(delta: float) -> void:
	_time += delta
	_ring_rot += delta * 0.35
	_hit_flash = maxf(0.0, _hit_flash - delta * 2.5)
	queue_redraw()

func _draw() -> void:
	var cond := condition()
	var pulse := 1.0 + 0.06 * sin(_time * 2.2)
	# Outer glow (layered, additive feel)
	var glow_col := Color(0.25, 0.85, 1.0)
	if cond < 0.3:
		glow_col = Color(1.0, 0.25, 0.2).lerp(Color(0.25, 0.85, 1.0), cond / 0.3)
	if _glow_tex != null:
		var gs := RADIUS * 6.0 * pulse
		draw_texture_rect(_glow_tex, Rect2(-gs * 0.5, -gs * 0.5, gs, gs), false, Color(glow_col, 0.75))
	else:
		for i in range(5, 0, -1):
			var c := glow_col
			c.a = 0.05 + 0.03 * float(i)
			draw_circle(Vector2.ZERO, RADIUS * pulse * (1.0 + float(i) * 0.28), c)
	# Body
	if _orb_tex != null:
		var os := RADIUS * 2.0 * pulse
		draw_texture_rect(_orb_tex, Rect2(-os * 0.5, -os * 0.5, os, os), false, Color(1, 1, 1, 0.65 + cond * 0.35))
	else:
		var body := Color(0.1, 0.55, 0.85).lerp(Color(0.55, 0.12, 0.1), 1.0 - cond)
		draw_circle(Vector2.ZERO, RADIUS * pulse, body)
		# Inner bright core
		var inner := Color(0.85, 0.98, 1.0)
		if cond < 0.3:
			inner = Color(1.0, 0.6, 0.5)
		draw_circle(Vector2.ZERO, RADIUS * 0.55 * pulse, inner)
		draw_circle(Vector2.ZERO, RADIUS * 0.28 * pulse, Color(1, 1, 1, 0.95))
	# Rotating rune ring
	var ring_col := Color(0.6, 0.95, 1.0, 0.85)
	for i in 12:
		var a := _ring_rot + float(i) * TAU / 12.0
		var p := Vector2(cos(a), sin(a)) * (RADIUS + 14.0)
		draw_circle(p, 3.0, ring_col)
	# Cracks as integrity drops (deterministic angles)
	if cond < 0.75:
		_draw_crack(0.6, cond)
	if cond < 0.5:
		_draw_crack(2.4, cond)
	if cond < 0.3:
		_draw_crack(4.1, cond)
	# Hit flash
	if _hit_flash > 0.0:
		draw_circle(Vector2.ZERO, (RADIUS + 8.0) * pulse, Color(1, 0.3, 0.2, _hit_flash * 0.5))
	# Low integrity flicker
	if cond < 0.3 and int(_time * 8.0) % 2 == 0:
		draw_arc(Vector2.ZERO, RADIUS + 22.0, 0.0, TAU, 48, Color(1, 0.2, 0.15, 0.6), 2.0)

func _draw_crack(angle: float, _cond: float) -> void:
	var pts := PackedVector2Array()
	var dir := Vector2(cos(angle), sin(angle))
	var p := dir * 10.0
	pts.append(p)
	p += dir * 14.0 + Vector2(-dir.y, dir.x) * 6.0
	pts.append(p)
	p += dir * 12.0 + Vector2(dir.y, -dir.x) * 7.0
	pts.append(p)
	draw_polyline(pts, Color(0.05, 0.05, 0.08, 0.9), 2.5)
