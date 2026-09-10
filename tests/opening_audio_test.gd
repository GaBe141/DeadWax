extends SceneTree
## Native PCM and playback lifecycle only; this fixture never loads user saves.
const AudioScript := preload("res://scripts/audio_bank.gd")
const SHOT_SECONDS := [5.5, 6.0, 5.5, 6.0]
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
	_check(bank._opening_tracks.is_empty(), "ordinary boot does not synthesize unused opening tracks")
	_check_synthesis(bank)
	await _check_playback(bank)
	var stream_ids: Array[int] = []
	for stream in bank._opening_tracks.values(): stream_ids.append(stream.get_instance_id())
	bank.play_opening_shot(2)
	var playback_id: int = bank._opening_player.get_stream_playback().get_instance_id()
	bank.queue_free()
	await _frames(3)
	await create_timer(0.25, true).timeout
	var released := not is_instance_id_valid(playback_id)
	for id in stream_ids: released = released and not is_instance_id_valid(id)
	_check(released, "freeing an active opening releases its playback and all cached tracks after the mixer block")
	_check(AudioServer.get_bus_effect_count(0) == original_effects, "opening cleanup preserves the original master effects")
	# Pre-ready requests and cancellation must also work while Main is paused.
	var next := AudioScript.new()
	next.play_opening_shot(1)
	next.stop_opening()
	paused = true
	root.add_child(next)
	await _frames(2)
	_check(not next.opening_audio_snapshot().playing and next.opening_audio_snapshot().shot == -1,
		"cancelling before ready cannot launch a delayed opening")
	next.play_opening_shot(0)
	await create_timer(0.10, true).timeout
	_check(next.opening_audio_snapshot().playing and not next.opening_audio_snapshot().paused,
		"a new opening can start after the world is already paused")
	next.stop_opening()
	next.queue_free()
	await _frames(3)
	await create_timer(0.25, true).timeout
	paused = false
	_check(get_nodes_in_group("audio_bank").is_empty() and AudioServer.get_bus_effect_count(0) == original_effects,
		"opening recreation leaves no bank or extra filter")
	if _failures.is_empty():
		print("DEAD WAX OPENING AUDIO PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("OPENING AUDIO FAIL: " + failure)
	quit(1)

func _check_synthesis(bank: Node) -> void:
	var existing_home: PackedByteArray = bank._sounds["home_song"].data.duplicate()
	var previous: Array[PackedByteArray] = []
	for shot in range(4):
		var stream: AudioStreamWAV = bank._opening_track(shot)
		_check(stream.mix_rate == AudioScript.RATE and stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo,
			"shot %d is supported mono PCM" % shot)
		_check(is_equal_approx(stream.get_length(), SHOT_SECONDS[shot]) and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			"shot %d lasts exactly its authored screen time without looping" % shot)
		var stats := _stats(stream.data)
		_check(stats.peak > 0.07 and stats.peak < 0.4, "shot %d is audible with ample unclipped sample headroom" % shot)
		_check(absf(stats.mean) < 0.001 and stats.step < 0.06, "shot %d avoids DC offset and harsh sample discontinuities" % shot)
		_check(stream.data.decode_s16(0) == 0 and stream.data.decode_s16(stream.data.size() - 2) == 0,
			"shot %d begins and ends at zero" % shot)
		_check(_edge_peak(stream.data, false) < 0.01 and _edge_peak(stream.data, true) < 0.01,
			"shot %d gently fades its first and last 50ms" % shot)
		_check(stream.data not in previous and stream.data != existing_home,
			"shot %d has its own introduction rather than the earned home recording" % shot)
		_check(bank._opening_track(shot) == stream, "shot %d reuses its finite cached recording" % shot)
		previous.append(stream.data)
	_check(bank._opening_tracks.size() == 4 and bank._sounds["home_song"].data == existing_home,
		"opening generation stays bounded and leaves the earned melody unchanged")
	# Identical requests must not change the game-wide random sequence used by
	# existing effects. The papery texture owns a deterministic local generator.
	seed(987654)
	var expected := randf()
	seed(987654)
	var isolated := AudioScript.new()
	isolated._opening_track(0)
	var actual := randf()
	isolated.free()
	_check(actual == expected, "opening texture generation does not consume gameplay randomness")

func _check_playback(bank: Node) -> void:
	var player: AudioStreamPlayer = bank._opening_player
	_check(player.process_mode == Node.PROCESS_MODE_ALWAYS and player not in bank._pool and bank._pool.size() == 10,
		"opening owns one independent always-processing player and preserves ten SFX voices")
	_check(not bank.opening_audio_snapshot().playing and bank.opening_audio_snapshot().shot == -1,
		"ready does not start an unrequested opening")
	bank.set_home_song(true)
	await create_timer(0.08, true).timeout
	paused = true
	for update in range(24): bank.set_hooded(true)
	_check(bank._lowpass.cutoff_hz < 800.0, "fixture retains the Hood lowpass when gameplay is paused")
	bank.play_opening_shot(0)
	_check(is_equal_approx(bank._lowpass.cutoff_hz, 20000.0),
		"opening immediately restores full bandwidth without waiting for paused Main updates")
	await create_timer(0.08, true).timeout
	var started: Dictionary = bank.opening_audio_snapshot()
	_check(started.playing and not started.paused and started.shot == 0,
		"intro music starts while the paused world remains suspended")
	_check(bank._home_player.stream_paused and bank._crackle_player.stream_paused,
		"opening playback does not unpause home music or crackle")
	var first_position: float = started.playback_position
	await create_timer(0.16, true).timeout
	_check(player.get_playback_position() > first_position + 0.06,
		"opening audio time advances during world pause")
	player.seek(1.8)
	for repeat in range(8): bank.play_opening_shot(0)
	await create_timer(0.08, true).timeout
	_check(player.get_playback_position() >= 1.7, "duplicate shot requests do not restart the current cue")
	var prior: AudioStreamPlayback = player.get_stream_playback()
	bank.play_opening_shot(1)
	_check(not prior.is_playing() and player.stream == bank._opening_tracks[1] and bank.opening_audio_snapshot().shot == 1,
		"next shot stops its prior playback before replacing the one player")
	for invalid in [-1, 4, 99]: bank.play_opening_shot(invalid)
	_check(player.stream == bank._opening_tracks[1] and bank.opening_audio_snapshot().shot == 1,
		"invalid shot indices cannot replace or stop a valid cue")
	var original_mute := AudioServer.is_bus_mute(0)
	var original_volume := AudioServer.get_bus_volume_db(0)
	AudioServer.set_bus_mute(0, true)
	AudioServer.set_bus_volume_db(0, -18.0)
	bank.play_opening_shot(2)
	_check(player.bus == &"Master" and AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_db(0), -18.0),
		"opening remains under existing master mute and volume settings")
	_check(player.volume_db <= -12.0, "opening player cannot exceed its authored safe gain")
	bank.stop_opening()
	_check(not player.playing and player.stream == null and bank.opening_audio_snapshot().shot == -1,
		"skip clears the playing cue and stream immediately during pause")
	await create_timer(0.08, true).timeout
	_check(not player.playing and bank.home_song_snapshot().requested,
		"a stopped opening never revives or alters the independent home request")
	AudioServer.set_bus_mute(0, original_mute)
	AudioServer.set_bus_volume_db(0, original_volume)
	bank.play_opening_shot(3)
	player.seek(SHOT_SECONDS[3] - 0.15)
	await create_timer(0.35, true).timeout
	_check(not player.playing, "the final cue ends naturally without an audio loop or callback restart")
	bank.play_opening_shot(3)
	_check(not player.playing, "a duplicate finished-shot event cannot play the cue again")
	bank.stop_opening()
	bank.play_opening_shot(3)
	_check(player.playing, "explicit stop permits a genuinely new opening to play the same shot")
	bank.stop_opening()
	paused = false
	await _frames(3)
	_check(not player.playing and not bank._home_player.stream_paused,
		"returning to gameplay resumes world audio without reviving the opening")

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

func _edge_peak(bytes: PackedByteArray, tail: bool) -> float:
	var count := int(0.05 * AudioScript.RATE)
	var first := bytes.size() / 2 - count if tail else 0
	var peak := 0.0
	for frame in range(first, first + count):
		peak = maxf(peak, absf(float(bytes.decode_s16(frame * 2)) / 32768.0))
	return peak

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
