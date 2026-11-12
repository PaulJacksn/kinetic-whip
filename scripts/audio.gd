extends Node
## Kinetic Whip audio: procedural cinematic music loop + synthesized SFX.
## Everything is generated in code at startup, no audio files.
## Real Sonniss GDC SFX can replace the procedural SFX later; the API
## (play_hit, play_shatter, ...) stays the same.
## NOTE: the web build is single-threaded, so Thread is unavailable there.
## Music is generated synchronously in _ready using lookup tables.

const MIX_RATE := 22050
const BPM := 84.0
const BARS := 4
const BEAT_LEN := 60.0 / BPM
const BAR_LEN := BEAT_LEN * 4.0
const LOOP_LEN := BAR_LEN * BARS
const SINE_STEPS := 2048
const SINE_SCALE := 325.94932335706835 # SINE_STEPS / TAU

var music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var music_ready: bool = false
var _sine_table: PackedFloat32Array
var _exp_table: PackedFloat32Array

var _hit_stream: AudioStreamWAV
var _shatter_stream: AudioStreamWAV
var _shield_stream: AudioStreamWAV
var _orb_stream: AudioStreamWAV
var _alarm_stream: AudioStreamWAV
var _upgrade_stream: AudioStreamWAV
var _corehit_stream: AudioStreamWAV
var _unlock_stream: AudioStreamWAV
var _wave_stream: AudioStreamWAV

func _ready() -> void:
	_build_tables()
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -11.0
	add_child(music_player)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_generate_sfx()
	_generate_music()

func _build_tables() -> void:
	_sine_table = PackedFloat32Array()
	_sine_table.resize(SINE_STEPS)
	for i in SINE_STEPS:
		_sine_table[i] = sin(TAU * float(i) / SINE_STEPS)
	_exp_table = PackedFloat32Array()
	_exp_table.resize(1024)
	for i in 1024:
		_exp_table[i] = exp(-20.0 * float(i) / 1023.0)

func _exp(x: float) -> float:
	return _exp_table[clampi(int(x * 51.15), 0, 1023)]

func _sin(phase: float) -> float:
	return _sine_table[int(phase * SINE_SCALE) & 2047]

# ---------------------------------------------------------------- music loop

func _generate_music() -> void:
	var total := int(LOOP_LEN * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	# Cm - Ab - Eb - Bb progression, roots + chord tones
	var roots := PackedFloat32Array([65.41, 51.91, 77.78, 58.27])
	var chords := PackedFloat32Array([
		130.81, 155.56, 196.0,
		103.83, 130.81, 155.56,
		155.56, 196.0, 233.08,
		116.54, 146.83, 174.61,
	])
	var prev_noise := 0.0
	var peak := 0.001
	var sine := _sine_table
	var expt := _exp_table
	for i in total:
		var t := float(i) / MIX_RATE
		var bar := int(t / BAR_LEN) % BARS
		var bar_t := fmod(t, BAR_LEN)
		var beat_phase := fmod(t, BEAT_LEN)
		var s := 0.0
		# Soft cinematic pulse on beats 1 and 3: low sine drop
		if beat_phase < 0.22 and int(t / BEAT_LEN) % 2 == 0:
			var kp := beat_phase
			var kphase := TAU * (36.0 * kp + 60.0 * (1.0 - expt[clampi(int(kp * 10.0 * 51.15), 0, 1023)]) / 10.0)
			s += sine[int(kphase * SINE_SCALE) & 2047] * expt[clampi(int(kp * 12.0 * 51.15), 0, 1023)] * 0.7
		# Sub bass: root on each beat, slow envelope
		var root: float = roots[bar]
		var benv: float = expt[clampi(int(beat_phase * 2.2 * 51.15), 0, 1023)]
		s += (sine[int(TAU * root * beat_phase * SINE_SCALE) & 2047] + 0.3 * sine[int(TAU * 2.0 * root * beat_phase * SINE_SCALE) & 2047]) * benv * 0.30
		# Cinematic pad: detuned chord tones, slow swell per bar
		var pad_env := minf(1.0, bar_t * 0.8) * 0.055
		var c0: float = chords[bar * 3]
		var c1: float = chords[bar * 3 + 1]
		var c2: float = chords[bar * 3 + 2]
		s += (sine[int(TAU * c0 * t * SINE_SCALE) & 2047] + sine[int(TAU * c0 * 1.004 * t * SINE_SCALE) & 2047]) * pad_env
		s += (sine[int(TAU * c1 * t * SINE_SCALE) & 2047] + sine[int(TAU * c1 * 1.004 * t * SINE_SCALE) & 2047]) * pad_env
		s += (sine[int(TAU * c2 * t * SINE_SCALE) & 2047] + sine[int(TAU * c2 * 1.004 * t * SINE_SCALE) & 2047]) * pad_env
		# High shimmer: octave-up pad tone, very quiet
		s += sine[int(TAU * c2 * 2.0 * t * SINE_SCALE) & 2047] * pad_env * 0.35
		# Sparse arp: 8th-note pluck on the last two beats of each bar
		if bar_t > BAR_LEN * 0.5:
			var eighth := int(t / (BEAT_LEN * 0.5))
			var ephase := fmod(t, BEAT_LEN * 0.5)
			var tone: float = chords[bar * 3 + eighth % 3] * 2.0
			s += sine[int(TAU * tone * ephase * SINE_SCALE) & 2047] * expt[clampi(int(ephase * 8.0 * 51.15), 0, 1023)] * 0.10
		# Air: soft noise swell at bar starts
		var noise := randf_range(-1.0, 1.0)
		var hp := noise - prev_noise
		prev_noise = noise
		if bar_t < 0.4:
			s += hp * expt[clampi(int(bar_t * 8.0 * 51.15), 0, 1023)] * 0.05
		s = s / (1.0 + absf(s) * 0.6)
		samples[i] = s
		if absf(s) > peak:
			peak = absf(s)
	var scale := 0.85 / peak
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var v := int(clampf(samples[i] * scale, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total
	music_player.stream = stream
	music_ready = true

# ---------------------------------------------------------------- SFX

func _make_tone_stream(duration: float, fn: Callable) -> AudioStreamWAV:
	var total := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var t := float(i) / MIX_RATE
		var v := int(clampf(float(fn.call(t, i)), -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

func _generate_sfx() -> void:
	# Whip hit: metallic clink (2 kHz ping + noise tick)
	_hit_stream = _make_tone_stream(0.18, func(t: float, _i: int) -> float:
		var s := _sin(TAU * 2093.0 * t) * _exp(t * 30.0) * 0.5
		s += _sin(TAU * 2637.0 * t) * _exp(t * 36.0) * 0.3
		s += randf_range(-1.0, 1.0) * _exp(t * 60.0) * 0.25
		return s
	)
	# Shatter: noise burst + descending tones
	_shatter_stream = _make_tone_stream(0.45, func(t: float, _i: int) -> float:
		var s := randf_range(-1.0, 1.0) * _exp(t * 9.0) * 0.55
		s += _sin(TAU * (880.0 - 1400.0 * t) * t) * _exp(t * 10.0) * 0.35
		s += _sin(TAU * (1320.0 - 1800.0 * t) * t) * _exp(t * 12.0) * 0.2
		return s
	)
	# Shield break: glassy high ping
	_shield_stream = _make_tone_stream(0.4, func(t: float, _i: int) -> float:
		var s := _sin(TAU * 1760.0 * t) * _exp(t * 8.0) * 0.5
		s += _sin(TAU * 2349.0 * t) * _exp(t * 9.0) * 0.35
		s += randf_range(-1.0, 1.0) * _exp(t * 25.0) * 0.2
		return s
	)
	# Orb pickup: rising blip
	_orb_stream = _make_tone_stream(0.16, func(t: float, _i: int) -> float:
		return _sin(TAU * (1046.0 + 1200.0 * t) * t) * _exp(t * 18.0) * 0.5
	)
	# Boss alarm: low horn swell
	_alarm_stream = _make_tone_stream(0.9, func(t: float, _i: int) -> float:
		var env := sin(PI * clampf(t / 0.9, 0.0, 1.0))
		var s := _sin(TAU * 110.0 * t) * env * 0.5
		s += _sin(TAU * 164.81 * t) * env * 0.35
		return s
	)
	# Upgrade: rising chime arpeggio
	_upgrade_stream = _make_tone_stream(0.6, func(t: float, _i: int) -> float:
		var s := 0.0
		var notes := [523.25, 659.25, 783.99, 1046.5]
		for n in 4:
			var nt := t - float(n) * 0.09
			if nt > 0.0:
				s += _sin(TAU * notes[n] * nt) * _exp(nt * 9.0) * 0.35
		return s
	)
	# Core hit: low thud
	_corehit_stream = _make_tone_stream(0.5, func(t: float, _i: int) -> float:
		var phase := TAU * (40.0 * t + 60.0 * (1.0 - _exp(t * 9.0)) / 9.0)
		var s := _sin(phase) * _exp(t * 7.0) * 0.9
		s += randf_range(-1.0, 1.0) * _exp(t * 20.0) * 0.3
		return s
	)
	# Unlock: bright fanfare
	_unlock_stream = _make_tone_stream(0.8, func(t: float, _i: int) -> float:
		var s := 0.0
		var notes := [392.0, 523.25, 659.25, 783.99]
		for n in 4:
			var nt := t - float(n) * 0.12
			if nt > 0.0:
				s += _sin(TAU * notes[n] * nt) * _exp(nt * 7.0) * 0.4
		return s
	)
	# Wave clear: soft major chime
	_wave_stream = _make_tone_stream(0.7, func(t: float, _i: int) -> float:
		var s := _sin(TAU * 659.25 * t) * _exp(t * 6.0) * 0.4
		if t > 0.12:
			s += _sin(TAU * 987.77 * (t - 0.12)) * _exp((t - 0.12) * 6.0) * 0.35
		return s
	)

# ---------------------------------------------------------------- public API

func start_music() -> void:
	if music_ready and not music_player.playing:
		music_player.play()

func music_position() -> float:
	if music_player.playing:
		return music_player.get_playback_position()
	return -1.0

func duck_music(ducked: bool) -> void:
	music_player.volume_db = -22.0 if ducked else -11.0

func _play(stream: AudioStreamWAV, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var p := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

func play_hit(spin: float) -> void:
	_play(_hit_stream, 0.9 + spin * 0.35, -5.0)

func play_shatter() -> void:
	_play(_shatter_stream, randf_range(0.9, 1.1), -2.0)

func play_shield_break() -> void:
	_play(_shield_stream, 1.0, -3.0)

func play_deflect() -> void:
	_play(_shield_stream, 1.6, -9.0)

func play_orb(combo: int) -> void:
	_play(_orb_stream, 1.0 + minf(combo, 16) * 0.03, -8.0)

func play_alarm() -> void:
	_play(_alarm_stream, 1.0, -2.0)

func play_upgrade() -> void:
	_play(_upgrade_stream, 1.0, -4.0)

func play_core_hit() -> void:
	_play(_corehit_stream, 1.0, 0.0)

func play_unlock() -> void:
	_play(_unlock_stream, 1.0, -3.0)

func play_wave_clear() -> void:
	_play(_wave_stream, 1.0, -4.0)
