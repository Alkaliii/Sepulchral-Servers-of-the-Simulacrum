extends Node
class_name AudioManager

var num_players := 8

var available : Array[AudioStreamPlayer] = []
var queue_sound = []
var queue_bus = []
var queue_volume = []

var music_player_a : AudioStreamPlayer
var music_player_b : AudioStreamPlayer

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	AudioServer.set_bus_volume_db(0,linear_to_db(0.6))
	
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.finished.connect(_stream_finished.bind(p))
	
	music_player_a = AudioStreamPlayer.new()
	add_child(music_player_a)
	music_player_a.bus = "Music"
	
	music_player_b = AudioStreamPlayer.new()
	add_child(music_player_b)
	music_player_b.bus = "Music"
	set_music_volume(0.0)

func _stream_finished(stream):
	available.append(stream)

func set_music_volume(nv : float):
	if music_player_a:
		music_player_a.set_volume_db(remap(nv,0.0,1.0,-80,0))
	if music_player_b:
		music_player_b.set_volume_db(remap(nv,0.0,1.0,-80,0))

func set_music_volume_a(nv : float):
	if music_player_a:
		music_player_a.set_volume_db(remap(nv,0.0,1.0,-80,0))

func set_music_volume_b(nv : float):
	if music_player_b:
		music_player_b.set_volume_db(remap(nv,0.0,1.0,-80,0))

func fade_music_b(state : bool,duration : float = 1.0):
	match state:
		false:
			await create_tween().tween_property(music_player_b,"volume_db",-100.0,duration).from_current().finished#.set_ease(Tween.EASE_OUT).finished
			music_player_b.stop()
		true:
			await create_tween().tween_property(music_player_b,"volume_db",0.0,duration).from_current().finished#.set_ease(Tween.EASE_IN).finished

func fade_music_a(state : bool,duration : float = 1.0):
	match state:
		false:
			await create_tween().tween_property(music_player_a,"volume_db",-100.0,duration).from_current().finished#.set_ease(Tween.EASE_OUT).finished
			music_player_a.stop()
		true:
			await create_tween().tween_property(music_player_a,"volume_db",0.0,duration).from_current().finished#.set_ease(Tween.EASE_IN).finished

var mtw : Tween
func play_music(sound_path,fade : Vector2 = Vector2(2.0,2.0)):
	print("play: ",sound_path)
	var cross_to : int = 1 #0 is A, 1 is B
	if music_player_a.playing:
		cross_to = 1
		music_player_b.stream = load(sound_path)
		await App.process_frame()
		music_player_b.play()
	elif music_player_b.playing:
		cross_to = 0
		music_player_a.stream = load(sound_path)
		await App.process_frame()
		music_player_a.play()
	else:
		cross_to = 0
		music_player_a.stream = load(sound_path)
		await App.process_frame()
		music_player_a.play()
	
	#if mtw: mtw.kill()
	#mtw = create_tween()
	
	if cross_to == 1: #fade B in, fade A out
		fade_music_a(false,fade.y)
		fade_music_b(true,fade.y * .8)
		#mtw.tween_method(set_music_volume_a,music_player_a.volume_db,0.0,fade.y).set_ease(Tween.EASE_IN_OUT).finished
		#mtw.tween_method(set_music_volume_b,music_player_b.volume_db,1.0,fade.y).set_ease(Tween.EASE_IN_OUT).finished
		#await mtw.finished
		#music_player_a.stop()
	
	elif cross_to == 0: #fade A in, fade B out
		fade_music_a(true,fade.y * .8)
		fade_music_b(false,fade.y)
		#mtw.tween_method(set_music_volume_a,music_player_a.volume_db,1.0,fade.y).set_ease(Tween.EASE_IN_OUT).finished
		#mtw.tween_method(set_music_volume_b,music_player_b.volume_db,0.0,fade.y).set_ease(Tween.EASE_IN_OUT).finished
		#await mtw.finished
		#music_player_b.stop()
	
	#create_tween().tween_property(music_player,"volume_db",linear_to_db(1.0),fade.x).set_ease(Tween.EASE_IN_OUT)
	#create_tween().tween_method(set_music_volume,music_player_a.volume_db,1.0,fade.x).set_ease(Tween.EASE_IN_OUT)

func stop_music(fade : float = 1.0):
	if music_player_a.playing:
		fade_music_a(false,fade)
	if music_player_b.playing:
		fade_music_b(false,fade)

func sync_and_play_music(sound_path,fade : Vector2 = Vector2(2.0,2.0)):
	var data = {
		"sound_path":sound_path,
		"fade":var_to_str(fade)
	}
	var pack = JSON.stringify(data)
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_MUSIC,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)
	play_music(sound_path,fade)

func sync_and_stop_music(fade : float = 1.0):
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_STOP_MUSIC,fade]),Plyrm.Playroom.RPC.Mode.OTHERS)
	stop_music(fade)

func play(sound_path, vol = 1.0, bus = "sfx"):
	print("queue: ",sound_path)
	if sound_path == "":
		printerr(('Bad sound'))
		return
	queue_sound.append(sound_path)
	queue_bus.append(bus)
	queue_volume.append(1.0)

func sync_and_play(sound_path, vol = 1.0,bus = "sfx"):
	var data = {
		"sound_path":sound_path,
		"volume":vol,
		"bus":bus
	}
	var pack = JSON.stringify(data)
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.REMOTE_SFX,pack]),Plyrm.Playroom.RPC.Mode.OTHERS)
	play(sound_path,vol,bus)

func clean_players():
	if available.size() > num_players:
		var kill = available.pop_back()
		remove_child(kill)
		kill.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#play sound
	if !queue_sound.is_empty() and !available.is_empty():
		available[0].stream = load(queue_sound.pop_front())
		available[0].bus = queue_bus.pop_front()
		available[0].volume_db = linear_to_db(queue_volume.pop_front())
		available[0].play()
		available.pop_front()
	#play sound on a temp new
	elif !queue_sound.is_empty() and available.is_empty():
		var np = AudioStreamPlayer.new()
		add_child(np)
		np.finished.connect(_stream_finished.bind(np))
		np.stream = load(queue_sound.pop_front())
		np.bus = queue_bus.pop_front()
		np.volume_db = linear_to_db(queue_volume.pop_front())
		np.play()
	elif queue_sound.is_empty() and !available.is_empty():
		clean_players()
