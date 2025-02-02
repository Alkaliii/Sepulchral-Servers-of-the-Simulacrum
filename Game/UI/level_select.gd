extends Control

var floor_data : Array = [
	"Instructional programs",
	"Low complexity programs",
	"Semi-complex programs",
	"Pretty complex programs",
	"High complexity programs"
]

var floor_size : Array = [
	0,
	1,
	0,
	0,
	0,
]

var select_idx : int = 0

@onready var upbtn = $LevelSelect/mcTwr/hbc/Selector/UP
@onready var downbtn = $LevelSelect/mcTwr/hbc/Selector/DOWN
@onready var startbtn = $LevelSelect/Details/START

@onready var floor_icns = [$LevelSelect/mcTwr/hbc/Tower/Floor0, $LevelSelect/mcTwr/hbc/Tower/Floor1, $LevelSelect/mcTwr/hbc/Tower/Floor2, $LevelSelect/mcTwr/hbc/Tower/Floor3, $LevelSelect/mcTwr/hbc/Tower/Floor4]
@onready var floorlbl = $LevelSelect/Details/Floor
@onready var description = $LevelSelect/Details/Description


# Called when the node enters the scene tree for the first time.
func _ready():
	focus_idx(false,false)
	upbtn.pressed.connect(_on_up_pressed)
	downbtn.pressed.connect(_on_down_pressed)
	startbtn.pressed.connect(_on_start_pressed)

var atw : Tween
func appear(state:bool):
	if atw: atw.kill()
	
	match state:
		true: #show
			App.can_input = false
			SystemUI.display_room_code("")
			if Plyrm.connected: Plyrm.PLAYER.state.setState("pREADY",false)
			var music = [SoundLib.music_files.TOWER_OF_THE_ARCHMAGE, SoundLib.music_files.MYTHICAL_TOWN].pick_random()
			SystemAudio.play_music(SoundLib.get_file(music))
			await SystemUI.set_title(false)
			await SystemUI.set_background(true,Color("#e34262"))
			remove_boss()
			position.y = get_viewport().size.y
			show()
			atw = create_tween()
			atw.tween_property(self,"position:y",0.0,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			atw.parallel().tween_property(self,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
		false: #put some sorta loader up?
			App.can_input = true
			SystemAudio.stop_music()
			atw = create_tween()
			atw.tween_property(self,"position:y",-get_viewport().size.y,0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			atw.parallel().tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT)
			await atw.finished
			hide()
			position.y = get_viewport().size.y

func remove_boss():
	var m = get_tree().get_first_node_in_group("monster")
	if m:
		m.get_parent().remove_child(m)
		m.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if visible:
		if Input.is_action_just_pressed("MUP"): _on_up_pressed()
		if Input.is_action_just_pressed("MDOWN"): _on_down_pressed()

func focus_sfx():
	#for i in randi_range(3,4):
		#var sound = [SoundLib.sound_files.IMPACT_A,SoundLib.sound_files.IMPACT_B]
		#SystemAudio.play(SoundLib.get_file_sfx(sound.pick_random()),0.5,"sfx",randf_range(0.9,1.1))
		#await App.time_delay(randf_range(0.1,0.2))
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.DOOR),0.5,"sfx",randf_range(0.9,1.1))

var ftw : Tween
func focus_idx(reverse_list := false, with_sound := true):
	if ftw: ftw.kill()
	ftw = create_tween()
	
	floorlbl.text = str("[code]floor-[/code][wave]",select_idx)
	if with_sound: focus_sfx()
	
	ftw.tween_property(description,"visible_ratio",0.0,0.125).set_ease(Tween.EASE_IN_OUT)
	var loop : Array = floor_icns.duplicate()
	if reverse_list: loop.reverse()
	for i in loop:
		if floor_icns.find(i) <= select_idx:
			if i.modulate.a == 1.0: continue
			ftw.tween_property(i,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
		else:
			if i.modulate.a == 0.0: continue
			ftw.tween_property(i,"modulate:a",0.0,0.125).set_ease(Tween.EASE_IN_OUT)
	await ftw.finished
	description.text = floor_data[select_idx]
	ftw = create_tween()
	ftw.tween_property(description,"visible_ratio",1.0,0.125).set_ease(Tween.EASE_IN_OUT)

func _on_up_pressed():
	upbtn.release_focus()
	var old_idx = select_idx
	select_idx = (select_idx + 1) % floor_data.size()
	focus_idx(true if old_idx == (floor_data.size() - 1) else false)

func _on_down_pressed():
	downbtn.release_focus()
	if select_idx == 0: select_idx = floor_data.size() - 1
	else:
		select_idx = (select_idx - 1) % floor_data.size()
	focus_idx()

func _on_start_pressed():
	startbtn.release_focus()
	
	#how map selection works in MP
	#after results player must press a button to navigate to map selection
	#map selection is client side but after the host makes a selection clients have 30seconds to do the same
	#If they don't press START, the game will choose for them at the end of the 30 seconds
	#system is democratic with no bias (other than time pressure)
	
	SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.DOOR_SHUT),1.0)
	
	appear(false)
	if Plyrm.connected:
		Plyrm.PLAYER.state.setState("pMapSelect",select_idx)
		SystemUI.set_background(false)
		await App.process_frame()
		
		#message to self about waiting for host or others
		if Plyrm.get_all_player_state("pMapSelect").count(false) > 0:
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"Waiting on others...",
			"type":LateralNotification.nt.SYSTEM,
			"duration":4.0
			})
		#message to others about selection ready
		SystemUI.sync_lateral({
		"speaker":"nme",
		"message":str("[color=b4ba46]",App.player_name,"[/color] selected f-",select_idx),
		"type":LateralNotification.nt.SYSTEM,
		"duration":4.0
		})
		await App.time_delay(1.0)
		
		
		#step one, start timer if host
		if Plyrm.Playroom.isHost():
			if Plyrm.get_all_player_state("pMapSelect").count(false) > 0:
				SystemUI.sync_and_push_lateral({
				"speaker":"nme",
				"message":"Voting will end in 30 seconds!",
				"type":LateralNotification.nt.WARN,
				"duration":25.0
				})
			var timer = 30.0
			var second_warning := false
			while true:
				timer -= get_process_delta_time()
				await App.process_frame()
				if timer <= 0.0: break
				elif timer <= 5.0 and !second_warning:
					second_warning = true
					SystemUI.sync_and_push_lateral({
					"speaker":"nme",
					"message":"Voting will end in 5 seconds!",
					"type":LateralNotification.nt.DANGER,
					"duration":5.0
					})
				if !false in Plyrm.get_all_player_state("pMapSelect"):
					break
			
			#step 2 tabulate results and exit everyone out of the level select
			Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.HIDE_LEVEL_SELECT]),Plyrm.Playroom.RPC.Mode.OTHERS)
			SystemUI.sync_and_push_lateral({
			"speaker":"nme",
			"message":fTxt.tips.pick_random(),#"Please wait...",
			"type":LateralNotification.nt.SYSTEM,
			"duration":6.0
			})
			
			var results = Plyrm.get_all_player_state("pMapSelect")
			print(results)
			var count : Dictionary = {}
			for r in results:
				if r == null or typeof(r) == TYPE_BOOL:
					print("didn't vote [",r,"]:",typeof(r))
					r = randi_range(0,floor_data.size() - 1)
				if count.has(r): continue
				else: count[int(r)] = results.count(r)
			
			var max_idx = -1
			var max_count = -1
			for c in count:
				if count[c] > max_count:
					max_idx = c
					max_count = count[c]
			print("IDX:",max_idx," VOTE:",max_count," SRC:",count)
			await App.time_delay(2.0)
			
			#announce and load new map
			SystemUI.sync_and_set_background(true)
			await App.time_delay(2.0)
			if App.well_apperance >= [2,3].pick_random():
				App.well_apperance = 0
				App.sync_level(-2)
			else:
				SystemUI.sync_and_push_lateral({
				"speaker":"nme",
				"message":str("f-",max_idx," was selected! (",max_count," votes)"),
				"type":LateralNotification.nt.SYSTEM,
				"duration":6.0
				})
				App.sync_level(max_idx,randi_range(0,floor_size[max_idx]))
			
			var timeout = 50.0
			while true:
				timeout -= get_process_delta_time()
				await App.process_frame()
				if !false in Plyrm.get_all_player_state("pREADY"):
					break
				if timeout <= 0.0:
					App._log_err(["Timeout"])
					#SystemUI.sync_and_push_lateral({
					#"speaker":"nme",
					#"message":"Timeout",
					#"type":LateralNotification.nt.WARN,
					#"duration":4.0
					#})
					break
			
			SystemUI.sync_and_set_background(false)
			await App.time_delay(1.0)
			App.start_boss.emit()
	else:
		#skip directly to loading new map
		if App.well_apperance >= [2,3].pick_random():
			App.well_apperance = 0
			App.load_level(-2)
		else:
			App.load_level(select_idx,randi_range(0,floor_size[select_idx]))
		pass
	
