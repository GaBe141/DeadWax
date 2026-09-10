extends Node
## DEAD WAX first audio pass — every sound synthesized at boot, no assets.
## Square-wave-era chip plucks + vinyl crackle. The crackle bed IS the noise
## meter made audible; the hood pulls a lowpass over the whole world.

const RATE := 22050
const HOME_NOTES := [220.0, 261.6256, 246.9417]
const HOME_NOTE_LENGTHS := [0.72, 0.88, 1.35]
const HOME_NOTE_STARTS := [0.35, 1.45, 2.65]
const HOME_LOOP_SECONDS := 6.4
const HOME_VOLUME_DB := -14.0
const HOME_FADE_IN := 1.1
const HOME_FADE_OUT := 0.8
const LOFT_CALL_SECONDS := 0.36

var _sounds := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _crackle_player: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter
var _home_player: AudioStreamPlayer
var _home_requested := false
var _home_gain := 0.0
var _home_started := false

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
	# This phrase belongs to the returning voice, not to the SFX voice pool.
	_home_player = AudioStreamPlayer.new()
	_home_player.name = "HomeSong"
	_home_player.stream = _sounds["home_song"]
	_home_player.volume_db = -80.0
	add_child(_home_player)
	if _home_requested:
		_home_player.play()
		_home_started = true
	# the hood filter on the master bus
	_lowpass = AudioEffectLowPassFilter.new()
	_lowpass.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(0, _lowpass)

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused or _home_player == null:
		return
	var target := 1.0 if _home_requested else 0.0
	var fade := HOME_FADE_IN if _home_requested else HOME_FADE_OUT
	_home_gain = move_toward(_home_gain, target, delta / fade)
	_home_player.volume_db = HOME_VOLUME_DB + linear_to_db(maxf(_home_gain, 0.0001))
	if not _home_requested and is_zero_approx(_home_gain) and _home_started:
		_home_player.stop()
		_home_started = false

## Main supplies whether this room has a voice to come home to. Repeated calls
## keep the same playing phrase; returning during a fade simply raises it again.
func set_home_song(enabled: bool) -> void:
	_home_requested = enabled
	if _home_player == null:
		return
	if enabled and not _home_started:
		_home_player.play()
		_home_started = true
	elif not enabled and is_inside_tree() and get_tree().paused:
		# Title/New Game may change the request while processing is suspended.
		# Discard that old phrase instead of letting it fade into the next game.
		_home_gain = 0.0
		_home_player.volume_db = -80.0
		_home_player.stop()
		_home_started = false

func home_song_snapshot() -> Dictionary:
	return {"requested": _home_requested, "playing": _home_player != null and _home_player.playing,
		"paused": _home_player != null and _home_player.stream_paused, "gain": _home_gain,
		"playback_position": _home_player.get_playback_position() if _home_player != null else 0.0}

func _exit_tree() -> void:
	# Release both loops and one-shot playbacks before their bank leaves the tree.
	# Remove only this bank's filter; another active bank can own its own effect.
	for player in _pool + [_crackle_player, _home_player]:
		if is_instance_valid(player):
			# Finish a looping WAV itself before releasing the player's mixer
			# handle; stop() alone can leave its loop pending until another mix.
			if player.has_stream_playback():
				player.get_stream_playback().stop()
			player.stop()
			player.stream = null
	for index in range(AudioServer.get_bus_effect_count(0) - 1, -1, -1):
		if AudioServer.get_bus_effect(0, index) == _lowpass:
			AudioServer.remove_bus_effect(0, index)
	_pool.clear()
	_sounds.clear()
	_lowpass = null

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
	var home := _home_phrase()
	_sounds["home_song"] = _wav(home, true)
	_sounds["loft_answer"] = _wav(_home_answer())
	for note in HOME_NOTES.size():
		_sounds["loft_note_%d" % (note + 1)] = _wav(_home_note(HOME_NOTES[note], LOFT_CALL_SECONDS))

func _home_note(frequency: float, duration: float) -> PackedFloat32Array:
	var count := int(duration * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	for index in count:
		var seconds := float(index) / RATE
		var remaining := float(count - 1 - index) / RATE
		var attack := smoothstep(0.0, 0.045, seconds)
		var release := smoothstep(0.0, 0.24, remaining)
		var envelope := attack * release * exp(-1.8 * seconds / duration)
		var phase := TAU * frequency * seconds
		# A round reed/bell voice, without the square edge of action sounds.
		var tone := sin(phase) + 0.16 * sin(phase * 2.0) + 0.045 * sin(phase * 3.0)
		out[index] = tone * envelope * 0.30
	return out

func _home_phrase() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(HOME_LOOP_SECONDS * RATE))
	for note in HOME_NOTES.size():
		var samples := _home_note(HOME_NOTES[note], HOME_NOTE_LENGTHS[note])
		var start := int(HOME_NOTE_STARTS[note] * RATE)
		for index in samples.size():
			out[start + index] += samples[index]
	return out

func _home_answer() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(0.52 * RATE))
	# A small returning chord leaves the next call clear. The fifth supplies
	# warmth beneath the first two notes of the motif.
	for frequency in [HOME_NOTES[0], HOME_NOTES[1], HOME_NOTES[0] * 1.5]:
		var samples := _home_note(frequency, 0.52)
		for index in samples.size():
			out[index] += samples[index] * 0.45
	return out

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
