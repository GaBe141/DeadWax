extends SceneTree
## The spool keeps a recognizable phrase without adding a music system.
const AudioScript := preload("res://scripts/audio_bank.gd")
const CUES := ["echo_collect", "echo_record", "echo_play", "echo_complete"]
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	var effects := AudioServer.get_bus_effect_count(0)
	var bank := AudioScript.new()
	root.add_child(bank)
	var children := bank.get_child_count()
	for cue in CUES:
		_check(not bank._sounds.has(cue), cue + " is not synthesized before discovery")
	var seconds := [0.26, 2.0, 2.0, 1.45]
	for index in CUES.size():
		var cue: String = CUES[index]
		var pool_index: int = bank._pool_i
		bank.play(cue, -8.0)
		var stream: AudioStreamWAV = bank._sounds[cue]
		var player: AudioStreamPlayer = bank._pool[pool_index]
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == AudioScript.RATE and not stream.stereo,
			cue + " is native mono PCM")
		_check(absf(stream.get_length() - seconds[index]) <= 1.0 / AudioScript.RATE and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			cue + " has its finite duration and cannot loop")
		var stats := _stats(stream.data)
		_check(stats.peak > 0.08 and stats.peak < 0.50 and absf(stats.mean) < 0.0005,
			cue + " remains audible with headroom and no DC offset")
		_check(stats.step < 0.08 and stream.data.decode_s16(0) == 0 and stream.data.decode_s16(stream.data.size() - 2) == 0,
			cue + " has rounded sample transitions and silent endpoints")
		_check(player.stream == stream and player.playing and is_equal_approx(player.volume_db, -8.0), cue + " uses ordinary world playback")
		var cached_id := stream.get_instance_id()
		bank.play(cue, -12.0)
		_check(bank._sounds[cue].get_instance_id() == cached_id, cue + " reuses its synthesized recording")
		for voice in bank._pool: voice.stop()
	var recording: PackedByteArray = bank._sounds["echo_record"].data
	var playback: PackedByteArray = bank._sounds["echo_play"].data
	_check(recording != playback, "playback has its own wax timbre")
	for note in [[0.18, 0.40, 293.6648], [0.73, 0.98, 440.0], [1.34, 1.76, 349.2282]]:
		_check(absf(_frequency(recording, note[0], note[1]) - note[2]) < 2.0
			and absf(_frequency(playback, note[0], note[1]) - note[2]) < 2.0,
			"source and playback share pitch %.2f at the same time" % note[2])
	for rest in [[0.0, 0.10], [0.55, 0.65], [1.10, 1.23], [1.94, 2.0]]:
		_check(_silent(recording, rest[0], rest[1]) and _silent(playback, rest[0], rest[1]),
			"source and playback retain the same breath at %.2f" % rest[0])
	var voice_index: int = bank._pool_i
	bank.play("echo_record", -24.0)
	var phrase: AudioStreamPlayer = bank._pool[voice_index]
	phrase.seek(0.30)
	paused = true
	await create_timer(0.08, true).timeout
	var held := phrase.get_playback_position()
	await create_timer(0.16, true).timeout
	_check(phrase.stream_paused and absf(phrase.get_playback_position() - held) <= 1024.0 / AudioScript.RATE,
		"pausing holds the phrase with gameplay")
	paused = false
	await create_timer(0.16, true).timeout
	_check(not phrase.stream_paused and phrase.get_playback_position() > held + 0.06,
		"unpausing continues the same phrase")
	_check(bank._pool.size() == 10 and bank.get_child_count() == children,
		"spool cues create no extra audio players")
	_check(not bank.home_song_snapshot().requested and bank.opening_audio_snapshot().shot == -1,
		"spool audio cannot start home or opening music")
	phrase.seek(1.92)
	await create_timer(0.30, true).timeout
	_check(not phrase.playing, "a completed phrase ends without replaying itself")
	var ordinary_index: int = bank._pool_i
	bank.play("freed", -24.0)
	var ordinary: AudioStreamPlayer = bank._pool[ordinary_index]
	var echo_players: Array[AudioStreamPlayer] = []
	for cue in CUES:
		echo_players.append(bank._pool[bank._pool_i])
		bank.play(cue, -24.0)
	bank.stop_echo_cues()
	var echo_stopped := true
	for player in echo_players: echo_stopped = echo_stopped and not player.playing and player.stream == null
	_check(echo_stopped, "cancelling the station stops and releases every active spool cue")
	_check(ordinary.playing and ordinary.stream == bank._sounds["freed"] and bank._crackle_player.playing,
		"spool cancellation leaves unrelated world voices and crackle playing")
	var resources := bank._sounds.size()
	bank.stop_echo_cues()
	_check(bank._sounds.size() == resources and ordinary.playing,
		"repeated cancellation preserves cached cues and unrelated playback")
	bank.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.25, true).timeout
	_check(AudioServer.get_bus_effect_count(0) == effects, "spool bank teardown leaves no master effect")
	if _failures.is_empty():
		print("DEAD WAX ECHO AUDIO PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("ECHO AUDIO FAIL: " + failure)
	quit(1)

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

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
