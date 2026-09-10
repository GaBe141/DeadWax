extends SceneTree
## Synthesis and real AudioStreamPlayer lifecycle; no game saves or external audio.
const AudioScript := preload("res://scripts/audio_bank.gd")
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	var original_effects := AudioServer.get_bus_effect_count(0)
	var bank := AudioScript.new()
	root.add_child(bank)
	await _frames(2)
	_check_synthesis(bank)
	await _check_playback(bank)
	bank.queue_free()
	await _frames(3)
	await create_timer(0.15, true).timeout
	_check(get_nodes_in_group("audio_bank").is_empty(), "freeing the bank leaves no audio owner")
	_check(AudioServer.get_bus_effect_count(0) == original_effects, "freeing the bank removes only its master Hood filter")
	# Configure before ready, as Main may do while building a restored room.
	var restored := AudioScript.new()
	restored.set_home_song(true)
	root.add_child(restored)
	await _frames(2)
	_check(restored.home_song_snapshot().requested and restored.home_song_snapshot().playing, "pre-ready home request starts when its audio player exists")
	restored.queue_free()
	await _frames(3)
	await create_timer(0.15, true).timeout
	_check(AudioServer.get_bus_effect_count(0) == original_effects, "recreating the bank never stacks an old Hood filter")
	if _failures.is_empty():
		print("DEAD WAX HOME SONG PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("HOME SONG FAIL: " + failure)
	quit(1)

func _check_synthesis(bank: Node) -> void:
	var song: AudioStreamWAV = bank._sounds["home_song"]
	var answer: AudioStreamWAV = bank._sounds["loft_answer"]
	_check(song.format == AudioStreamWAV.FORMAT_16_BITS and not song.stereo and song.mix_rate == AudioScript.RATE, "home song is a native mono PCM stream")
	_check(song.data.size() > AudioScript.RATE * 2 and song.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"home motif contains real samples and loops forward")
	_check(song.loop_begin == 0 and song.loop_end * 2 == song.data.size(), "loop bounds cover exactly the allocated sample frames")
	_check(is_equal_approx(song.get_length(), AudioScript.HOME_LOOP_SECONDS), "the three-note phrase retains its deliberate 6.4 second pacing")
	_check(answer.get_length() <= 0.55 and answer.get_length() >= 0.4 and answer.loop_mode == AudioStreamWAV.LOOP_DISABLED, "loft answering chord ends before the next call begins")
	var answer_stats := _stats(answer.data)
	_check(answer_stats.peak > 0.15 and answer_stats.peak < 0.5 and answer_stats.step < 0.05,
		"short answering chord keeps the warm timbre and sufficient mix headroom")
	var song_stats := _stats(song.data)
	_check(song_stats.peak > 0.15 and song_stats.peak < 0.4, "home motif is audible and has ample headroom without PCM clipping")
	_check(absf(song_stats.mean) < 0.0002 and song_stats.step < 0.05, "warm motif avoids DC bias and sharp sample discontinuities")
	_check(_silent(song.data, 0.0, 0.30) and _silent(song.data, 4.10, AudioScript.HOME_LOOP_SECONDS), "phrase leaves silence before the answer and a long rest before repeating")
	_check(_silent(song.data, 1.10, 1.40) and _silent(song.data, 2.38, 2.60), "notes are separated by real rests rather than a continuous drone")
	_check(song.data.decode_s16(0) == 0 and song.data.decode_s16(song.data.size() - 2) == 0, "loop boundary meets at silence without a click")
	var previous: Array[PackedByteArray] = []
	for index in range(3):
		var id := "loft_note_%d" % (index + 1)
		var note: AudioStreamWAV = bank._sounds[id]
		var stats := _stats(note.data)
		_check(note.loop_mode == AudioStreamWAV.LOOP_DISABLED and note.get_length() > 0.3 and note.get_length() < 0.4, id + " finishes before the next beat or answer window")
		_check(note.data not in previous and stats.peak > 0.15 and stats.peak < 0.4, id + " is distinct and cannot clip")
		_check(absf(_frequency(note.data) - float(AudioScript.HOME_NOTES[index])) < 4.0, id + " carries its matching recognizable pitch")
		_check(stats.step < 0.05 and note.data.decode_s16(0) == 0 and note.data.decode_s16(note.data.size() - 2) == 0,
			id + " has a soft attack and ends at zero")
		var offset := int(float(AudioScript.HOME_NOTE_STARTS[index]) * AudioScript.RATE) * 2
		var home_length := int(float(AudioScript.HOME_NOTE_LENGTHS[index]) * AudioScript.RATE) * 2
		var home_note := song.data.slice(offset, offset + home_length)
		_check(absf(_frequency(home_note) - _frequency(note.data)) < 5.0,
			id + " keeps its pitch when the home version has a longer envelope")
		var call_timbre := _harmonics(note.data, float(AudioScript.HOME_NOTES[index]))
		var home_timbre := _harmonics(home_note, float(AudioScript.HOME_NOTES[index]))
		_check(call_timbre.distance_to(home_timbre) < 0.02 and call_timbre.x > 0.10 and call_timbre.x < 0.22,
			id + " shares the home voice's soft harmonic balance despite its shorter release")
		previous.append(note.data)
	for id in ["strike", "onbeat", "parry", "tick", "swing", "thud", "shatter", "door", "polish", "alert", "reach", "freed", "flip", "crackle"]:
		_check(bank._sounds.has(id) and bank._sounds[id].data.size() > 0, "existing sound remains available: " + id)

func _check_playback(bank: Node) -> void:
	bank.set_process(false)
	var home: AudioStreamPlayer = bank._home_player
	var initial: Dictionary = bank.home_song_snapshot()
	_check(not initial.requested and not initial.playing and is_zero_approx(initial.gain), "unearned home motif starts silent")
	_check(bank._pool.size() == 10 and home not in bank._pool, "home song has its own player outside the bounded SFX pool")
	bank.set_home_song(true)
	_check(home.playing and is_zero_approx(bank.home_song_snapshot().gain), "enabling starts the phrase at a silent fade entrance")
	bank._process(0.3)
	_check(bank.home_song_snapshot().gain > 0.0 and bank.home_song_snapshot().gain < 1.0 and home.volume_db < AudioScript.HOME_VOLUME_DB, "home gain rises gradually before reaching its capped level")
	bank._process(3.0)
	_check(is_equal_approx(bank.home_song_snapshot().gain, 1.0) and is_equal_approx(home.volume_db, AudioScript.HOME_VOLUME_DB), "long frame cannot overshoot the music level")
	home.seek(1.8)
	await _frames(2)
	for repeat in range(30): bank.set_home_song(true)
	await _frames(2)
	_check(home.get_playback_position() >= 1.7 and bank._pool.size() == 10, "repeated room updates neither restart the phrase nor allocate SFX voices")
	bank.set_home_song(false)
	bank._process(0.25)
	var fading: Dictionary = bank.home_song_snapshot()
	_check(not fading.requested and fading.playing and fading.gain > 0.0 and fading.gain < 1.0, "leaving home fades the running phrase instead of cutting a note")
	bank.set_home_song(true)
	bank._process(0.1)
	_check(home.get_playback_position() >= 1.7 and bank.home_song_snapshot().gain > fading.gain, "returning during a fade restores gain without replaying the first note")
	bank.set_home_song(false)
	bank._process(2.0)
	_check(not home.playing and is_zero_approx(bank.home_song_snapshot().gain), "completed fade stops the loop and resets its gain")
	bank.set_home_song(true)
	bank._process(0.4)
	bank.play("loft_note_1", -9.0)
	var call: AudioStreamPlayer = bank._pool[0]
	_check(call.stream == bank._sounds["loft_note_1"] and call.playing and home.playing, "call-response note uses the existing SFX pool without interrupting home")
	home.seek(0.8)
	bank.set_process(true)
	paused = true
	# The audio mixer consumes pause commands on its next block, independently
	# of the headless renderer's process frames.
	await create_timer(0.05, true).timeout
	var held: Dictionary = bank.home_song_snapshot()
	_check(held.paused and call.stream_paused and bank._crackle_player.stream_paused, "tree pause silences music, call-response and crackle together")
	for repeat in range(5): bank.set_home_song(true)
	await create_timer(0.12, true).timeout
	var after: Dictionary = bank.home_song_snapshot()
	_check(is_equal_approx(held.gain, after.gain) and after.playback_position >= 0.7 and absf(held.playback_position - after.playback_position) <= 1024.0 / AudioScript.RATE,
		"menu time and repeated requests hold the phrase within mixer-buffer latency: %s / %s" % [held, after])
	paused = false
	await _frames(3)
	_check(not home.stream_paused and home.playing and bank.home_song_snapshot().gain >= held.gain, "leaving a menu resumes the existing home phrase")
	paused = true
	bank.set_home_song(false)
	_check(not home.playing and is_zero_approx(bank.home_song_snapshot().gain), "title or New Game can clear a suspended old phrase immediately")
	paused = false
	await _frames(2)
	_check(not home.playing, "unpausing cannot revive a cleared home song")
	bank.set_crackle(1.0)
	_check(is_equal_approx(bank._crackle_player.volume_db, -16.0), "music leaves noise-driven crackle gain unchanged")
	var cutoff: float = bank._lowpass.cutoff_hz
	bank.set_hooded(true)
	_check(bank._lowpass.cutoff_hz < cutoff, "the same Hood lowpass still covers the audible world")
	var pool_index: int = bank._pool_i
	bank.play("not_a_real_sound")
	_check(bank._pool_i == pool_index, "unknown cues remain silent without consuming a pool slot")

func _stats(bytes: PackedByteArray) -> Dictionary:
	var peak := 0.0
	var step := 0.0
	var total := 0.0
	var last := 0.0
	for frame in bytes.size() / 2:
		var sample := float(bytes.decode_s16(frame * 2)) / 32768.0
		peak = maxf(peak, absf(sample))
		step = maxf(step, absf(sample - last))
		total += sample
		last = sample
	return {"peak": peak, "step": step, "mean": total / (bytes.size() / 2)}

func _silent(bytes: PackedByteArray, begin: float, end: float) -> bool:
	for frame in range(int(begin * AudioScript.RATE), mini(int(end * AudioScript.RATE), bytes.size() / 2)):
		if bytes.decode_s16(frame * 2) != 0: return false
	return true

func _frequency(bytes: PackedByteArray) -> float:
	var start := int(0.08 * AudioScript.RATE)
	var end := mini(int(0.60 * AudioScript.RATE), bytes.size() / 2 - int(0.1 * AudioScript.RATE))
	var crossings: Array[float] = []
	for frame in range(start + 1, end):
		var previous := bytes.decode_s16((frame - 1) * 2)
		var current := bytes.decode_s16(frame * 2)
		if previous <= 0 and current > 0:
			crossings.append(float(frame - 1) - float(previous) / float(current - previous))
	if crossings.size() < 2: return 0.0
	return float(crossings.size() - 1) * AudioScript.RATE / (crossings[-1] - crossings[0])

func _harmonics(bytes: PackedByteArray, frequency: float) -> Vector2:
	var start := int(0.055 * AudioScript.RATE)
	var end := int(0.28 * AudioScript.RATE)
	var levels: Array[float] = []
	for harmonic in [1, 2, 3]:
		var real_part := 0.0
		var imaginary_part := 0.0
		for frame in range(start, end):
			var window := 0.5 - 0.5 * cos(TAU * float(frame - start) / float(end - start - 1))
			var sample := float(bytes.decode_s16(frame * 2)) / 32768.0 * window
			var phase: float = TAU * frequency * harmonic * float(frame) / AudioScript.RATE
			real_part += sample * cos(phase)
			imaginary_part += sample * sin(phase)
		levels.append(sqrt(real_part * real_part + imaginary_part * imaginary_part))
	return Vector2(levels[1], levels[2]) / maxf(levels[0], 0.0001)

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
