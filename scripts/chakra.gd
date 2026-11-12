extends Node2D
## Chakra: a spinning energy disc that stores RPM. Continuous circular
## swiping revs it up; RPM decays when the player stops. The disc stays
## deadly while RPM is maintained. Locked until unlocked with energy.

const ORBIT_RADIUS := 205.0
const DISC_RADIUS := 36.0

var core_pos: Vector2 = Vector2(360, 640)
var rpm: float = 0.0
var max_ang_vel: float = 9.0
var unlocked: bool = false
var visible_weapon: bool = false

var disc_angle: float = -PI * 0.5
var _last_angle: float = -PI * 0.5
var _angle_init: bool = false
var _spin_visual: float = 0.0
var _time: float = 0.0
var _disc_tex: Texture2D = null

func _ready() -> void:
	if ResourceLoader.exists("res://assets/art/weapons/chakra.png"):
		_disc_tex = load("res://assets/art/weapons/chakra.png")

func disc_pos() -> Vector2:
	return core_pos + Vector2(cos(disc_angle), sin(disc_angle)) * ORBIT_RADIUS

func rpm_percent() -> float:
	return rpm * 100.0

func update_spin(target_angle: float, dragging: bool, delta: float) -> void:
	if not _angle_init:
		_last_angle = target_angle
		_angle_init = true
	var d := wrapf(target_angle - _last_angle, -PI, PI)
	_last_angle = target_angle
	if dragging:
		var inst := absf(d) / maxf(delta, 0.001)
		var target_rpm := clampf(inst / max_ang_vel, 0.0, 1.0)
		rpm = lerpf(rpm, target_rpm, 1.0 - exp(-6.0 * delta))
		disc_angle = target_angle
	else:
		rpm = maxf(0.0, rpm - delta * 0.30)
		disc_angle += (0.6 + rpm * 6.0) * delta

func _process(delta: float) -> void:
	_time += delta
	_spin_visual += (0.5 + rpm * 22.0) * delta
	queue_redraw()

func _draw() -> void:
	if not visible_weapon or not unlocked:
		return
	var cond := 1.0
	if get_parent() != null and get_parent().has_method("weapon_condition"):
		cond = get_parent().weapon_condition()
	var p := disc_pos()
	# The chakra node sits at (0,0) in Main, so draw in world coords.
	var heat := Color(1.0, 0.55, 0.2).lerp(Color(0.35, 0.9, 1.0), 1.0 - rpm)
	heat = heat.lerp(Color(0.5, 0.5, 0.55), 1.0 - cond)
	# Glow
	draw_circle(p, DISC_RADIUS + 18.0 + rpm * 10.0, Color(heat, 0.18))
	draw_circle(p, DISC_RADIUS + 8.0, Color(heat, 0.30))
	# Disc body: real sprite when available, drawn disc otherwise.
	if _disc_tex != null:
		draw_set_transform(p, _spin_visual, Vector2(0.75, 0.75))
		draw_texture(_disc_tex, -_disc_tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(p, DISC_RADIUS, Color(0.08, 0.1, 0.16, 0.95))
		draw_arc(p, DISC_RADIUS, 0.0, TAU, 40, Color(heat, 0.95), 3.0)
		draw_arc(p, DISC_RADIUS * 0.55, 0.0, TAU, 32, Color(heat, 0.6), 2.0)
		# Spokes, spinning
		for i in 6:
			var a := _spin_visual + float(i) * TAU / 6.0
			var p1 := p + Vector2(cos(a), sin(a)) * (DISC_RADIUS * 0.55)
			var p2 := p + Vector2(cos(a), sin(a)) * (DISC_RADIUS * 0.92)
			draw_line(p1, p2, Color(heat, 0.85), 3.0, true)
		# Hub
		draw_circle(p, 7.0, Color(1, 1, 1, 0.9))
	# RPM ring around the disc
	if rpm > 0.05:
		draw_arc(p, DISC_RADIUS + 26.0, -PI * 0.5, -PI * 0.5 + TAU * rpm, 40, Color(heat, 0.8), 3.0)
