extends SceneTree
## The Yard remembers a finite phrase through ordinary world audio. No saves.
const AudioScript := preload("res://scripts/audio_bank.gd")
const CUES := ["yard_note_1", "yard_note_2", "yard_answer", "yard_memory"]
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
	_check_synthesis(bank)
	await _check_playback(bank)
	var resources: Array[int] = []
	for name in CUES: resources.append(bank._sounds[name].get_instance_id())
	bank.play("yard_memory", -12.0)
	bank.queue_free()
	await _frames(3)
	await create_timer(0.25, true).timeout
	var released := true
	for id in resources: released = released and not is_instance_id_valid(id)
	_check(released, "bank teardown releases every Yard recording after the mixer finishes")
	_check(AudioServer.get_bus_effect_count(0) == original_effects and get_nodes_in_group("audio_bank").is_empty(),
		"Yard audio leaves no bank or added master effect")
	if _failures.is_empty():
		print("DEAD WAX YARD AUDIO PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("YARD AUDIO FAIL: " + failure)
	quit(1)

func _check_synthesis(bank: Node) -> void:
	var expected_seconds := [0.40, 0.40, 1.30, 2.30]
	var previous: Array[PackedByteArray] = []
	for index in CUES.size():
		var id: String = CUES[index]
		var stream: AudioStreamWAV = bank._sounds[id]
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == AudioScript.RATE and not stream.stereo,
			id + " uses native mono PCM")
		_check(is_equal_approx(stream.get_length(), expected_seconds[index]) and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			id + " has its finite authored duration and never loops")
		var stats := _stats(stream.data)
		_check(stats.peak > 0.10 and stats.peak < 0.40 and absf(stats.mean) < 0.0005,
			id + " has audible headroom without clipping or DC offset")
		_check(stats.step < 0.05 and stream.data.decode_s16(0) == 0 and stream.data.decode_s16(stream.data.size() - 2) == 0,
			id + " has warm sample continuity and silent endpoints")
		_check(stream.data not in previous and stream.data != bank._sounds["loft_answer"].data,
			id + " is its own Yard recording")
		previous.append(stream.data)
	var first: PackedByteArray = bank._sounds["yard_note_1"].data
	var second: PackedByteArray = bank._sounds["yard_note_2"].data
	_check(absf(_frequency(first, 0.07, 0.30) - 195.9977) < 2.0, "first hesitant call carries G3")
	_check(absf(_frequency(second, 0.07, 0.30) - 220.0) < 2.0, "second hesitant call carries A3")
	var answer: PackedByteArray = bank._sounds["yard_answer"].data
	var memory: PackedByteArray = bank._sounds["yard_memory"].data
	for check_note in [[0.075, 0.27, 0.21, 0.51, 195.9977], [0.45, 0.64, 0.94, 1.27, 220.0], [0.82, 1.15, 1.58, 2.10, 261.6256]]:
		var answer_pitch := _frequency(answer, check_note[0], check_note[1])
		var memory_pitch := _frequency(memory, check_note[2], check_note[3])
		_check(absf(answer_pitch - float(check_note[4])) < 2.0 and absf(memory_pitch - answer_pitch) < 2.0,
			"answer and remembered phrase share pitch %.2f while leaving different rests" % float(check_note[4]))
	_check(_stats(memory).peak < _stats(answer).peak, "the remembered phrase is gentler at the same player volume")
	_check(_silent(memory, 0.0, 0.12) and _silent(memory, 0.70, 0.80) and _silent(memory, 1.40, 1.48) and _silent(memory, 2.28, 2.30),
		"memory includes deliberate rests and a quiet final tail")
	_check(first != bank._sounds["loft_note_1"].data and second != bank._sounds["loft_note_2"].data,
		"Yard calls remain distinct from the loft's three-note discovery")

func _check_playback(bank: Node) -> void:
	var initial_children := bank.get_child_count()
	var world_players := true
	for player in bank._pool:
		world_players = world_players and player.process_mode != Node.PROCESS_MODE_ALWAYS
	_check(bank._pool.size() == 10 and world_players, "Yard cues use the bounded existing pausable SFX pool")
	for name in CUES:
		var index: int = bank._pool_i
		bank.play(name, -8.0)
		var player: AudioStreamPlayer = bank._pool[index]
		_check(player.stream == bank._sounds[name] and player.playing and is_equal_approx(player.volume_db, -8.0),
			"ordinary play dispatches " + name)
		if name != "yard_memory": player.stop()
	var memory_player: AudioStreamPlayer = bank._pool[3]
	memory_player.seek(0.4)
	paused = true
	await create_timer(0.08, true).timeout
	var held := memory_player.get_playback_position()
	_check(memory_player.stream_paused and bank._crackle_player.stream_paused, "pause suspends the remembered phrase with world crackle")
	await create_timer(0.16, true).timeout
	_check(absf(memory_player.get_playback_position() - held) <= 1024.0 / AudioScript.RATE,
		"paused memory cannot advance beyond a pending mixer buffer")
	paused = false
	await create_timer(0.16, true).timeout
	_check(not memory_player.stream_paused and memory_player.get_playback_position() > held + 0.06,
		"unpause continues the same remembered phrase")
	var original_mute := AudioServer.is_bus_mute(0)
	var original_volume := AudioServer.get_bus_volume_db(0)
	AudioServer.set_bus_mute(0, true)
	AudioServer.set_bus_volume_db(0, -20.0)
	for update in range(24): bank.set_hooded(true)
	var hood_cutoff: float = bank._lowpass.cutoff_hz
	var next_index: int = bank._pool_i
	bank.play("yard_answer", -8.0)
	_check(bank._pool[next_index].bus == &"Master" and AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_db(0), -20.0),
		"Yard sound stays under the existing master volume and mute")
	_check(hood_cutoff < 800.0 and is_equal_approx(bank._lowpass.cutoff_hz, hood_cutoff),
		"playing a Yard cue preserves the current Hood filter")
	AudioServer.set_bus_mute(0, original_mute)
	AudioServer.set_bus_volume_db(0, original_volume)
	for repeat in range(24): bank.play("yard_memory", -24.0)
	_check(bank.get_child_count() == initial_children and bank._pool.size() == 10,
		"even repeated memory requests cannot create extra players")
	_check(not bank.home_song_snapshot().requested and bank.opening_audio_snapshot().shot == -1,
		"Yard cues neither unlock the home melody nor start an opening player")
	for player in bank._pool: player.seek(player.stream.get_length() - 0.08)
	await create_timer(0.30, true).timeout
	var silent := true
	for player in bank._pool: silent = silent and not player.playing
	_check(silent, "all finite Yard tails finish without scheduling another memory")
	var index_before: int = bank._pool_i
	await create_timer(0.10, true).timeout
	_check(bank._pool_i == index_before, "future memory timing belongs to the room rather than the audio bank")

func _stats(bytes: PackedByteArray) -> Dictionary:
	var peak := 0.0
	var step := 0.0
	var total := 0.0
	var previous := 0.0
	for frame in bytes.size() / 2:
		var value := float(bytes.decode_s16(frame * 2)) / 32768.0
		peak = maxf(peak, absf(value))
		step = maxf(step, absf(value - previous))
		total += value
		previous = value
	return {"peak": peak, "step": step, "mean": total / float(bytes.size() / 2)}

func _frequency(bytes: PackedByteArray, begin: float, end: float) -> float:
	var crossings: Array[float] = []
	for frame in range(int(begin * AudioScript.RATE) + 1, int(end * AudioScript.RATE)):
		var previous := bytes.decode_s16((frame - 1) * 2)
		var current := bytes.decode_s16(frame * 2)
		if previous <= 0 and current > 0:
			crossings.append(float(frame - 1) - float(previous) / float(current - previous))
	if crossings.size() < 2: return 0.0
	return float(crossings.size() - 1) * AudioScript.RATE / (crossings[-1] - crossings[0])

func _silent(bytes: PackedByteArray, begin: float, end: float) -> bool:
	for frame in range(int(begin * AudioScript.RATE), mini(int(end * AudioScript.RATE), bytes.size() / 2)):
		if bytes.decode_s16(frame * 2) != 0: return false
	return true

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
