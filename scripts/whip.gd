extends Node2D
## Chained Blade: multi-link physics chain on a hand-tuned verlet
## integrator, built to feel like a WHIP, not a rope.
##
## What makes it a whip:
## - Per-link MASS TAPER (heavy at the hand, light at the tip): constraint
##   corrections move the light tip more than the heavy base, so energy
##   travels down the chain and the tip accelerates, overshoots and cracks.
## - Per-link DAMPING (tip keeps energy longer than the base).
## - CENTRIFUGAL force proportional to angular velocity squared extends
##   the chain with spin; a gentle DROOP curls it in when spin dies.
## - The anchor pulls only the first links, so the chain LAGS, curves and
##   trails the orbit instead of rotating as a stiff rod.
## - apply_impact() lets a hit deflect the chain: the "bite".
##
## Why hand-tuned verlet instead of the Almios Rope2D addon: Rope2D is a
## paid pack and a general-purpose rope sim (uniform links, no mass taper,
## no whip-crack tuning). A whip needs the taper and the tip-biased
## damping above; a generic rope sim cannot be tuned into that.

const BASE_LINKS := 12
const SEG_LEN := 16.0
const BASE_ORBIT := 150.0
const ORBIT_GROW := 45.0
const CENTRIFUGAL_K := 3.0
const DROOP_K := 55.0
const FOLLOW_K := 26.0
const RELAX_ITERS := 6
const TRAIL_LEN := 14

var core_pos: Vector2 = Vector2(360, 640)
var link_count: int = BASE_LINKS
var damage_mult: float = 1.0
var max_ang_vel: float = 9.0
var anchor_angle: float = -PI * 0.5
var angular_vel: float = 0.0
var spin_ratio: float = 0.0
var visible_weapon: bool = true
var sim_active: bool = true

var _points: Array[Vector2] = []
var _prev: Array[Vector2] = []
var _mass: Array[float] = []
var _damp: Array[float] = []
var _trail: Array[Vector2] = []
var _last_angle: float = -PI * 0.5
var _angle_init: bool = false
var _time: float = 0.0
var _blade_tex: Texture2D = null
var _link_tex: Texture2D = null

func _ready() -> void:
	_rebuild_chain()
	_blade_tex = _load_tex("res://assets/art/weapons/blade.png")
	_link_tex = _load_tex("res://assets/art/weapons/chain_link.png")

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t := load(path)
		if t is Texture2D:
			return t
	return null

func _rebuild_chain() -> void:
	_points.clear()
	_prev.clear()
	_mass.clear()
	_damp.clear()
	_trail.clear()
	var a := anchor_angle
	for i in link_count + 1:
		var t := float(i) / float(maxi(link_count, 1))
		_mass.append(lerpf(1.0, 0.32, t))
		_damp.append(lerpf(0.982, 0.996, t))
		var p := _anchor_pos(a) + Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * float(i) * SEG_LEN * 0.4
		_points.append(p)
		_prev.append(p)

func set_link_count(n: int) -> void:
	link_count = n
	_rebuild_chain()

func orbit_radius() -> float:
	return BASE_ORBIT + spin_ratio * ORBIT_GROW

func _anchor_pos(a: float) -> Vector2:
	return core_pos + Vector2(cos(a), sin(a)) * orbit_radius()

func anchor_pos() -> Vector2:
	return _anchor_pos(anchor_angle)

func tip_pos() -> Vector2:
	return _points[_points.size() - 1]

func tip_speed() -> float:
	var last := _points.size() - 1
	return _points[last].distance_to(_prev[last]) / maxf(get_physics_process_delta_time(), 0.001)

func spin_percent() -> float:
	return spin_ratio * 100.0

func update_spin(target_angle: float, dragging: bool, delta: float) -> void:
	if not _angle_init:
		_last_angle = target_angle
		_angle_init = true
	var d := wrapf(target_angle - _last_angle, -PI, PI)
	_last_angle = target_angle
	if dragging:
		var inst := d / maxf(delta, 0.001)
		angular_vel = lerpf(angular_vel, inst, 1.0 - exp(-14.0 * delta))
		anchor_angle = target_angle
	else:
		angular_vel = lerpf(angular_vel, 0.0, 1.0 - exp(-1.6 * delta))
		anchor_angle += angular_vel * delta
	spin_ratio = clampf(absf(angular_vel) / max_ang_vel, 0.0, 1.0)

## A hit deflects the chain: points near the impact get their velocity
## kicked opposite the blade's motion, so the chain visibly bites.
func apply_impact(pos: Vector2, dir: Vector2, power: float) -> void:
	for i in range(1, _points.size()):
		var d := _points[i].distance_to(pos)
		if d < 110.0:
			var w := (1.0 - d / 110.0) * power
			_prev[i] += dir * w

func _physics_process(delta: float) -> void:
	_time += delta
	if _points.is_empty():
		return
	if not sim_active:
		queue_redraw()
		return
	var anchor := _anchor_pos(anchor_angle)
	var spin2 := angular_vel * angular_vel
	var droop := DROOP_K * (1.0 - spin_ratio)
	for i in range(1, _points.size()):
		var p := _points[i]
		var vel := (p - _prev[i]) * _damp[i]
		_prev[i] = p
		var to_core := p - core_pos
		var dist := to_core.length()
		var dir_out := to_core / maxf(dist, 0.001)
		# Centrifugal: outward from the core, proportional to spin squared.
		var acc := dir_out * spin2 * CENTRIFUGAL_K
		# Droop: gentle pull toward the core when spin dies, so the chain
		# curls in instead of floating straight.
		acc += -dir_out * droop
		# Follow: only the first links feel the anchor, so the rest lags.
		if i <= 3:
			var to_anchor := anchor - p
			var ad := to_anchor.length()
			if ad > 0.001:
				acc += to_anchor / ad * FOLLOW_K
		_points[i] = p + vel + acc * delta * delta * 60.0
	# Pin the first point to the anchor.
	_points[0] = anchor
	_prev[0] = anchor
	# Relax constraints, mass-weighted: light tip links move more.
	for _it in RELAX_ITERS:
		_points[0] = anchor
		for i in range(_points.size() - 1):
			var a := _points[i]
			var b := _points[i + 1]
			var d := b - a
			var dist := d.length()
			if dist < 0.001:
				continue
			var diff := (dist - SEG_LEN) / dist
			if i == 0:
				_points[i + 1] = b - d * diff
			else:
				var w0 := 1.0 / _mass[i]
				var w1 := 1.0 / _mass[i + 1]
				var s := w0 + w1
				_points[i] = a + d * diff * (w0 / s)
				_points[i + 1] = b - d * diff * (w1 / s)
	# Tip trail (for the speed streak).
	_trail.push_front(_points[_points.size() - 1])
	if _trail.size() > TRAIL_LEN:
		_trail.pop_back()
	queue_redraw()

## Collision samples: blade tip (strong) plus every second link.
## Each sample carries its motion direction (the hit direction).
func hit_samples() -> Array:
	var out: Array = []
	var n := _points.size()
	for i in range(1, n, 2):
		var speed := _points[i].distance_to(_prev[i]) / maxf(get_physics_process_delta_time(), 0.001)
		var dir := _points[i] - _prev[i]
		if dir.length() < 0.5:
			dir = (_points[i] - core_pos).normalized()
		else:
			dir = dir.normalized()
		out.append({"pos": _points[i], "speed": speed, "tip": i == n - 1, "dir": dir})
	return out

func _draw() -> void:
	if not visible_weapon or _points.size() < 2:
		return
	var cond := 1.0
	if get_parent() != null and get_parent().has_method("weapon_condition"):
		cond = get_parent().weapon_condition()
	var flicker := 1.0
	if cond < 0.3 and int(_time * 10.0) % 3 == 0:
		flicker = 0.45
	var base_col := Color(0.5, 1.0, 1.0).lerp(Color(0.7, 0.7, 0.7), 1.0 - cond)
	# Tip speed streak (fading trail behind the tip).
	if spin_ratio > 0.3 and _trail.size() > 2:
		for i in range(_trail.size() - 1):
			var a := (1.0 - float(i) / float(_trail.size())) * 0.35 * spin_ratio * flicker
			draw_line(_trail[i], _trail[i + 1], Color(base_col, a), 6.0 * (1.0 - float(i) / float(_trail.size())), true)
	# Chain: tapered width toward the tip, glow underlay + bright core.
	for pass_i in 2:
		var w0 := 10.0 if pass_i == 0 else 4.5
		var col := base_col
		col.a = (0.4 if pass_i == 0 else 1.0) * flicker
		for i in range(_points.size() - 1):
			var t := float(i) / float(_points.size() - 1)
			var ww := w0 * (1.0 - t * 0.6)
			draw_line(_points[i], _points[i + 1], col, ww, true)
	# Chain links: real texture when available, rings otherwise.
	for i in range(1, _points.size() - 1, 2):
		if _link_tex != null:
			var seg_dir := (_points[i + 1] - _points[i - 1]).normalized()
			var rot := seg_dir.angle() + PI * 0.5
			draw_set_transform(_points[i], rot, Vector2.ONE)
			draw_texture(_link_tex, -_link_tex.get_size() * 0.5)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_arc(_points[i], 4.5, 0.0, TAU, 10, Color(base_col, 0.8 * flicker), 1.5)
	# Blade at the tip, oriented along the last segment.
	var last := _points.size() - 1
	var dir := (_points[last] - _points[last - 1]).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tip := _points[last]
	if _blade_tex != null:
		draw_set_transform(tip, dir.angle() + PI * 0.5, Vector2.ONE)
		draw_texture(_blade_tex, -_blade_tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var blade_col := Color(0.9, 1.0, 1.0).lerp(Color(0.7, 0.55, 0.5), 1.0 - cond)
		var poly := PackedVector2Array([
			tip + dir * 26.0,
			tip - dir * 6.0 + perp * 9.0,
			tip - dir * 12.0,
			tip - dir * 6.0 - perp * 9.0,
		])
		draw_colored_polygon(poly, Color(blade_col, 0.95 * flicker))
		draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(0.4, 0.9, 1.0, 0.8 * flicker), 1.5)
	# Spin-speed glow at the tip
	var glow_a := 0.25 + spin_ratio * 0.5
	draw_circle(tip, 14.0 + spin_ratio * 12.0, Color(base_col, glow_a * 0.5 * flicker))
