extends Node
## DEAD WAX first audio pass — every sound synthesized at boot, no assets.
## Square-wave-era chip plucks + vinyl crackle. The crackle bed IS the noise
## meter made audible; the hood pulls a lowpass over the whole world.

const RATE := 22050

var _sounds := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _crackle_player: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter

func _ready() -> void:
	add_to_group("audio_bank")
	_build_sounds()
	for i in range(10):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	# crackle bed (loops forever, volume driven by player noise)
	_crackle_player = AudioStreamPlayer.new()
	_crackle_player.stream = _sounds["crackle"]
	_crackle_player.volume_db = -60.0
	add_child(_crackle_player)
	_crackle_player.play()
	# the hood filter on the master bus
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(0, _lowpass)

func play(sound_name: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not _sounds.has(sound_name):
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _sounds[sound_name]
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()

func set_crackle(noise: float) -> void:
	# 0 -> silent-ish hiss, 1 -> full campfire
	_crackle_player.volume_db = lerpf(-52.0, -16.0, clampf(noise, 0.0, 1.0))

func set_hooded(hooded: bool) -> void:
	var target := 700.0 if hooded else 20000.0
	_lowpass.cutoff_hz = lerpf(_lowpass.cutoff_hz, target, 0.25)

# -- synthesis ----------------------------------------------------------------

func _build_sounds() -> void:
	_sounds["strike"] = _mix([_pluck(150.0, 0.22, 0.9), _pluck(310.0, 0.14, 0.5)])
	_sounds["onbeat"] = _mix([_pluck(660.0, 0.30, 0.7), _pluck(990.0, 0.26, 0.5), _pluck(1320.0, 0.18, 0.3)])
	_sounds["parry"] = _mix([_pluck(880.0, 0.34, 0.8), _pluck(2370.0, 0.20, 0.35)])
	_sounds["tick"] = _wav(_pluck(1750.0, 0.055, 0.8))
	_sounds["swing"] = _wav(_noise_burst(0.14, 0.8, 1500.0))
	_sounds["thud"] = _mix([_pluck(95.0, 0.24, 1.0), _noise_burst(0.10, 0.5, 900.0)])
	_sounds["shatter"] = _mix([_noise_burst(0.42, 0.9, 4200.0), _pluck(520.0, 0.36, 0.5), _pluck(392.0, 0.42, 0.4)])
	_sounds["door"] = _sequence([[392.0, 0.14], [523.0, 0.14], [659.0, 0.26]])
	_sounds["polish"] = _mix([_pluck(1319.0, 0.24, 0.55), _pluck(1976.0, 0.20, 0.3)])
	_sounds["alert"] = _wav(_pluck(340.0, 0.16, 0.6))
	_sounds["reach"] = _sequence([[311.0, 0.16], [370.0, 0.16], [415.0, 0.24]])
	_sounds["freed"] = _mix([_pluck(523.0, 0.5, 0.5), _pluck(659.0, 0.5, 0.4), _pluck(784.0, 0.55, 0.35)])
	# the needle lifting and coming back down on the other face
	_sounds["flip"] = _mix([
		_noise_burst(0.20, 0.55, 2600.0),
		_pluck(196.0, 0.30, 0.5),
		_pluck(147.0, 0.40, 0.4),
	])
	_sounds["crackle"] = _crackle_loop(2.0)

func _wav(samples: PackedFloat32Array, looped := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if looped:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s

func _pluck(freq: float, dur: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var env := pow(1.0 - t, 2.2)
		# square-ish with a soft corner: chip warmth, not chip pain
		var sq := signf(sin(phase)) * 0.6 + sin(phase) * 0.4
		out[i] = sq * env * amp * 0.5
		phase += TAU * freq / RATE
	return out

func _noise_burst(dur: float, amp: float, tone: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var last := 0.0
	var k := clampf(tone / float(RATE), 0.01, 0.9)
	for i in n:
		var t := float(i) / float(n)
		var env := pow(1.0 - t, 1.6)
		last = lerpf(last, randf_range(-1.0, 1.0), k)
		out[i] = last * env * amp * 0.6
	return out

func _mix(parts: Array) -> AudioStreamWAV:
	var n := 0
	for p in parts:
		n = maxi(n, (p as PackedFloat32Array).size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		var pf := p as PackedFloat32Array
		for i in pf.size():
			out[i] += pf[i]
	return _wav(out)

func _sequence(notes: Array) -> AudioStreamWAV:
	var total := 0.0
	for nd in notes:
		total += nd[1]
	var out := PackedFloat32Array()
	out.resize(int(total * RATE) + 1)
	var at := 0
	for nd in notes:
		var p := _pluck(nd[0], nd[1] * 1.6, 0.6)  # let notes ring past their slot
		for i in p.size():
			var idx: int = at + i
			if idx < out.size():
				out[idx] += p[i]
		at += int(nd[1] * RATE)
	return _wav(out)

func _crackle_loop(dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var hiss := 0.0
	for i in n:
		hiss = lerpf(hiss, randf_range(-1.0, 1.0), 0.12)
		var v := hiss * 0.05
		# pops: sparse, vinyl-true
		if randf() < 0.0012:
			v += randf_range(-0.9, 0.9)
		out[i] = v
	return _wav(out, true)
