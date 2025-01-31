extends Node


var can_click : bool = true
var can_input : bool = true
var can_job_change : bool = false

signal load_boss
signal load_misc
signal load_complete
signal start_boss
signal spawn_dmg #position : vector2, dmgSettings
signal reload_boss
signal purge_attacks #remove attacks
signal tutorial_start
signal tutorial_click
signal tutorial_end

signal debug_line

#var saved_job : system_job
#var saved_weapon : system_weapon
var player_name : String
var job_inventory : Array[system_job.j] = [system_job.j.JOBLESS,system_job.j.MAGE,system_job.j.KNIGHT,system_job.j.SAINT]
var weapon_inventory : Array[system_weapon] = []

var dmg_dealt : int = 0 #click damage
var healing_performed : int = 0 #click healing
var clicks_made : int = 0 #how many times you clicked
var revolutions_made : int = 0 #how many times you spun your cursor

var performance_screen_details : Dictionary = {
	"bhp":1000,
	"time":300,
	"total_time":300,
}

var current_floor : int = 0
var floors_completed : Dictionary = {}

enum gsu {
	ASSERT_STATE,
	RELOAD_STATE,
	REMOTE_MUSIC,
	REMOTE_MUSIC_INTRO,
	REMOTE_STOP_MUSIC,
	REMOTE_SFX,
	REMOTE_LATERAL, #send messages
	REMOTE_TITLE,
	REMOTE_TITLE_PUSH,
	REMOTE_BACKGROUND,
	DISABLE_CLIENT_BOSS,
	ROAR_FX,
	PURGE_ATTACKS,
	STASH_METRICS,
	SHOW_PERFORMANCE,
	HIDE_LEVEL_SELECT,
	SYNC_LEVEL,
}

var uptime : float = 0.0


func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	player_name = fTxt.playerNames.pick_random()
	print(player_name)

func _process(_delta):
	uptime += _delta
	if Input.is_action_just_pressed("debug_reload"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("debug_shader_precomp"):
		SystemAudio.play_intro_then_loop(SoundLib.get_file(SoundLib.music_files.BATTLE_ARIADNE_INTRO),SoundLib.get_file(SoundLib.music_files.BATTLE_ARIADNE))
		#load_misc.emit("res://Game/Other/precompile_shader.tscn")

func isometrize(v : Vector2) -> Vector2:
	var new : Vector2 = Vector2()
	new.x = v.x - v.y
	new.y = (v.x + v.y) / 2.0
	return new

func process_frame():
	await get_tree().process_frame
	return

func time_delay(time_sec : float = 1.0, process_always : bool = true,process_in_physics : bool = false,ignore_time_scale : bool = false):
	await get_tree().create_timer(time_sec,process_always,process_in_physics,ignore_time_scale).timeout
	return

func determine_boss_health(mod : float = 1.0, clamp_health : int = 0) -> int:
	var boss_health : float = 100
	#boss should take 200 light attacks, or 6 max heavy attacks
	#this is determined using the average damage of your best weapon, assuming base 3 (HOST)
	#you best weapon is the weapon with the highest damage when all of it's damaged is summed
	#this value is increased by player count / HP + ((HP * .8) * Player count - 1)
	
	var best_weapon : system_weapon
	if weapon_inventory.is_empty(): best_weapon = preload("res://Game/Content/DefaultWeapons/OldBlade.tres")
	for w in weapon_inventory:
		if !best_weapon or w.dmg_rating() > best_weapon.dmg_rating(): 
			best_weapon = w
	
	var heavy = best_weapon.get_heavy_average()
	boss_health = (heavy * (6.0 + randf_range(0.0,3.0))) * mod
	
	match clamp_health:
		1: boss_health = clampf(boss_health,0.0,555.0)
		2: boss_health = clampf(boss_health,0.0,1111.0)
		3: boss_health = clampf(boss_health,0.0,1555.0)
		4: boss_health = clampf(boss_health,0.0,2222.0)
	
	if Plyrm.connected:
		boss_health += ((boss_health * .8) * (Plyrm.connected_players.size() - 1))
	
	
	print("New health: ",int(round(boss_health))," HP")
	return int(round(boss_health))

func validate_alive() -> int:
	#check for players and puppets and return the number
	var in_game : int = 0
	in_game += get_tree().get_nodes_in_group("player").size()
	in_game += get_tree().get_nodes_in_group("puppet").size()
	return in_game

func validate_players() -> int:
	if !Plyrm.connected: return 1
	else:
		return Plyrm.connected_players.size()

func assert_game_state():
	var game_state
	if Plyrm.connected:
		if !Plyrm.Playroom.isHost():
			#get host to validate, stay dead until reload or victory
			Plyrm.Playroom.RPC.call("game_state_update",var_to_str([gsu.ASSERT_STATE]),Plyrm.Playroom.RPC.Mode.OTHERS)
			return
		else:
			game_state = App.validate_alive()
	else:
		game_state = App.validate_alive()
	
	if game_state == 0:
		#Game over
		if Plyrm.connected: 
			Plyrm.Playroom.RPC.call("game_state_update",var_to_str([gsu.RELOAD_STATE]),Plyrm.Playroom.RPC.Mode.OTHERS)
		await App.reload_game()
	
		if !Plyrm.connected or Plyrm.Playroom.isHost():
			App.start_boss.emit()

var reloading := false
func reload_game():
	if reloading: return
	reloading = true
	reload_boss.emit()
	#reload player states also
	reset_performace_metrics()
	var plyr = get_tree().get_first_node_in_group("player_persistant")
	plyr.set_job()
	plyr.random_start_position()
	await App.time_delay(2.0)
	SystemUI.set_title(false)
	await SystemUI.set_background(false)
	reloading = false

func reset_performace_metrics():
	dmg_dealt = 0
	healing_performed = 0
	clicks_made = 0
	revolutions_made = 0

var well_apperance : int = 0
func set_floor_complete(flr : int):
	well_apperance += 1
	if floors_completed.has(flr): 
		floors_completed[flr].amount += 1
		floors_completed[flr].times.append(performance_screen_details.time)
		floors_completed[flr].playtime += performance_screen_details.total_time
	else:
		floors_completed[flr] = {
			"amount":1,
			"times":[performance_screen_details.time],
			"playtime":performance_screen_details.total_time
		}

func sync_level(level : int,boss : int = 0):
	if Plyrm.connected: Plyrm.Playroom.RPC.call("game_state_update",var_to_str([App.gsu.SYNC_LEVEL,level,boss]),Plyrm.Playroom.RPC.Mode.OTHERS)
	load_level(level,boss)

func remove_boss():
	var m = get_tree().get_first_node_in_group("monster")
	if m:
		m.get_parent().remove_child(m)
		m.queue_free()

func remove_environment():
	var e = get_tree().get_first_node_in_group("environment")
	if e:
		e.get_parent().remove_child(e)
		e.queue_free()

func load_level(level : int,boss : int = 0):
	remove_boss()
	if level != -2: remove_environment()
	var plyr = get_tree().get_first_node_in_group("player_persistant")
	plyr.set_job()
	plyr.random_start_position()
	reset_performace_metrics()
	current_floor = level
	match level:
		-2:
			load_misc.emit("res://Game/Content/Props/wishing_well.tscn")
		0:
			load_misc.emit("res://Game/Content/ArenaEnvironment/Field.tscn")
			await App.load_complete
			load_boss.emit("res://Game/scarecrow.tscn")
		1:
			load_misc.emit("res://Game/Content/ArenaEnvironment/Forest.tscn")
			await App.load_complete
			match boss:
				0: load_boss.emit("res://Game/Content/Bosses/boss_L1L.tscn")#load_boss.emit("res://Game/boss.tscn")
				1: load_boss.emit("res://Game/Content/Bosses/boss_L1C.tscn")
		_:
			load_boss.emit("res://Game/scarecrow.tscn")
	await App.load_complete
	
	await time_delay(0.5)
	if Plyrm.connected: Plyrm.PLAYER.state.setState("pREADY",true)
	else: SystemUI.set_background(false)

func to_config():
	SystemUI.sync_and_push_lateral({
	"speaker":"nme",
	"message":fTxt.tips.pick_random(),#"Please wait...",
	"type":LateralNotification.nt.SYSTEM,
	"duration":6.0
	})
	
	await _load("res://Game/arena.tscn")
	SystemUI.open_config(true)

func _load(file : String):
	if !file.is_absolute_path(): 
		printerr("What the fuck is, ",file,"?")
		return
	var rldr = ResourceLoader
	rldr.load_threaded_request(file)
	
	var load_file #= load(file)
	var progress : Array = []
	var status
	while true:
		await App.process_frame()
		status = rldr.load_threaded_get_status(file,progress)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			load_file = rldr.load_threaded_get(file)
			await App.time_delay(0.2)
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			printerr("load failed")
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"err: Background loading failed",
			"type":LateralNotification.nt.DANGER,
			"duration":18.0
			})
			break
	
	if load_file and load_file is PackedScene:
		get_tree().change_scene_to_packed(load_file)
		#var new = load_file.instantiate()
		#add_child(new)
