extends Node

#I do all the playroom stuff!
#Fetch Playroom
var Playroom = JavaScriptBridge.get_interface("Playroom")

signal PR_PLAYER_JOIN 
signal PR_PLAYER_QUIT
signal PR_INSERT_COIN
signal PR_SESSION_END
signal PR_DISCONNECT

var PLAYER : Dictionary = {}
#var sync_objs : Array = []

var connected_players : Array = []
var connected : bool = false

var debug_blog := true

# Keep a reference to the callback so it doesn't get garbage collected
var jsBridgeReferences = []
func bridgeToJS(cb):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback
 
func _ready():
	if OS.has_feature("pc"): $PRUI.hide()

func blog(txt : String):
	if !debug_blog: return
	SystemUI.push_lateral({
	"speaker":"nme",
	"message":txt,
	"type":LateralNotification.nt.SYSTEM,
	"duration":10
	})

# Called when the host has started the game
func onInsertCoin(args):
	register_rpc()
	connected = true
	print("Coin Inserted! ",Playroom.getRoomCode())
	blog(str("Coin Inserted! ",Playroom.getRoomCode()))
	Playroom.onPlayerJoin(bridgeToJS(onPlayerJoin))
	PR_INSERT_COIN.emit()
	
	#set name and other things
	Plyrm.PLAYER.state.setState("name",App.player_name)
	Plyrm.PLAYER.state.setState("pMapSelect",false)
	Plyrm.PLAYER.state.setState("pREADY",false)
	SystemUI.sync_lateral({
	"speaker":"nme",
	"message":str("[color=b4ba46]",App.player_name,"[/color] has joined the server"),
	"type":LateralNotification.nt.SYSTEM,
	"duration":4.0
	})

func onSessionEnd(args):
	connected = false
	clear_playroom_data()
	print("Session has ended, ",args)
	blog(str("Session has ended, ",args))
	PR_SESSION_END.emit()

func onDisconnect(args):
	connected = false
	clear_playroom_data()
	print("Disconnect!", args.code," ",args.reason)
	blog(str("Disconnect!", args.code," ",args.reason))
	PR_DISCONNECT.emit(args)

func clear_playroom_data():
	PLAYER.clear()
	connected_players.clear()

# Called when a new player joins the game
func onPlayerJoin(args):
	var state = args[0]
	var replace = false
	for p in connected_players:
		if p.id == state.id: 
			connected_players.insert(connected_players.find(p),state)
			replace = true
	if !replace: 
		connected_players.append(state)
		blog(str("new npc joined: ", state.id))
		PR_PLAYER_JOIN.emit(args)
	print("new npc joined: ", state.id)
	# Listen to onQuit event
	state.onQuit(bridgeToJS(onPlayerQuit))
 
func onPlayerQuit(args):
	var state = args[0];
	connected_players.erase(state)
	for p in connected_players:
		if p.id == state.id: connected_players.erase(p)
	print("npc quit: ", state.id)
	blog(str("npc quit: ", state.id))
	PR_PLAYER_QUIT.emit(args)

@onready var start_game = $PRUI/LobbyUI/StartGame
func _on_start_game_pressed():
	if Plyrm.Playroom.isHost():
		start_game.release_focus()
		start_game.hide()
		App.start_boss.emit()

@onready var room_input = $PRUI/LobbyUI/VBoxContainer/RoomInput
@onready var join_room = $PRUI/LobbyUI/VBoxContainer/JoinRoom
func _on_join_room_pressed():
	join_room.release_focus()
	join_room.disabled = true
	JavaScriptBridge.eval("")
	var initOptions = JavaScriptBridge.create_object("Object")
	
	var config = ConfigFile.new()
	var err = config.load("res://.env")
	
	if err != OK:
		printerr("err: couldn't access gameId from enviroment. Load Failed")
		blog("err: couldn't access gameId from enviroment. Load failed")
		return
	
	#Init Options
	if room_input.text:
		initOptions.roomCode = room_input.text
	initOptions.gameId = config.get_value("playroom/enviroment_variables","gameId")
	initOptions.skipLobby = true
	initOptions.maxPlayersPerRoom = 4

	#Insert Coin
	Playroom.insertCoin(initOptions, bridgeToJS(onInsertCoin), bridgeToJS(onSessionEnd))
	
	$PRUI/LobbyUI/VBoxContainer.hide()
	await PR_INSERT_COIN
	#await get_tree().create_timer(1.0).timeout
	room_input.text = Playroom.getRoomCode()
	room_input.editable = false
	
	var player = Playroom.me()
	var pd : Dictionary = {
		"id":player.id,
		"host":Playroom.isHost(),
		"state":player
	}
	PLAYER = pd
	Playroom.onDisconnect(bridgeToJS(onDisconnect))
	blog(str(pd))

func register_rpc():
	Playroom.RPC.register("game_state_update",bridgeToJS(game_state_update))
	Playroom.RPC.register("spawn_dmg",bridgeToJS(spawn_dmg))
	Playroom.RPC.register("cam_target",bridgeToJS(cam_target))
	Playroom.RPC.register("cam_trauma",bridgeToJS(cam_trauma))
	Playroom.RPC.register("player_knockback",bridgeToJS(player_knockback))
	Playroom.RPC.register("player_aid",bridgeToJS(player_aid))
	Playroom.RPC.register("dmg_boss",bridgeToJS(dmg_boss))
	Playroom.RPC.register("hide_boss",bridgeToJS(hide_boss))

func hide_boss(data):
	#data = var_to_str(bool)
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in hide_boss()")
		return
	if !data.size() > 0:
		printerr("No Data in hide_boss()")
		return
	
	var unpacked_data = str_to_var(data[0])
	
	var mnstr = get_tree().get_first_node_in_group("monster")
	if !mnstr: return
	mnstr.disappear(unpacked_data)

func dmg_boss(data):
	#data = var_to_str([amt, click])
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in dmg_boss()")
		return
	if !data.size() > 0:
		printerr("No Data in dmg_boss()")
		return
	
	var unpacked_data = str_to_var(data[0])
	var mnstr = get_tree().get_first_node_in_group("monster")
	if !mnstr: return
	mnstr.remote_damage(unpacked_data[0],unpacked_data[1])

func player_aid(data):
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in player_aid()")
		return
	if !data.size() > 0:
		printerr("No Data in player_aid()")
		return
	
	#id,aid_type,source,additional
	var unpacked_data = str_to_var(data[0])
	if PLAYER and PLAYER.id != unpacked_data[0]:
		printerr("Not for me! player_aid call ignored")
		return
	
	var plyr = get_tree().get_first_node_in_group("player")
	if !plyr: return
	
	if unpacked_data.size() < 3:
		printerr("not enough data")
		print_debug("here: ",unpacked_data)
		return
	match unpacked_data[1]:
		0: #HEAL
			if plyr.status and plyr.status.current_effects.has(system_status.effects.SICK): return
			if unpacked_data.size() < 4:
				printerr("not enough data")
				print_debug("here: ",unpacked_data)
				return
			plyr.on_heal(unpacked_data[3])
			SystemUI.push_lateral({
			"speaker":"(+)",
			"message":str("[color=b4ba46]",unpacked_data[2],"[/color] healed you!"),
			"type":LateralNotification.nt.SYSTEM,
			"duration":4.0
			})
		1: #CLEAR
			plyr.on_clear()
			SystemUI.push_lateral({
			"speaker":"(+)",
			"message":str("[color=b4ba46]",unpacked_data[2],"[/color] cured you!"),
			"type":LateralNotification.nt.SYSTEM,
			"duration":4.0
			})
		2: #GUARD
			if plyr.status and plyr.status.current_effects.has(system_status.effects.SICK): return
			plyr.on_guard()
			SystemUI.push_lateral({
			"speaker":"(+)",
			"message":str("[color=b4ba46]",unpacked_data[2],"[/color] guarded you!"),
			"type":LateralNotification.nt.SYSTEM,
			"duration":4.0
			})


func player_knockback(data):
	#data = var_to_str([id,Vector2,float*])
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in player_knockback()")
		return
	if !data.size() > 0:
		printerr("No Data in player_knockback()")
		return
	
	var unpacked_data = str_to_var(data[0])
	if PLAYER and PLAYER.id != unpacked_data[0]: 
		printerr("Not for me! player_knockback call ignored")
		return
	
	var plyr = get_tree().get_first_node_in_group("player")
	if !plyr: return
	await App.time_delay(0.063) #setting to turn this off?
	if unpacked_data.size() > 2:
		plyr.knockback(unpacked_data[1],unpacked_data[2])
	else:
		plyr.knockback(unpacked_data[1])

func cam_target(data):
	#print(get_node($Sprite.get_path()))
	#data = var_to_str([$Sprite.get_path()],Vector2*)
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in cam_target()")
		return
	if !data.size() > 0:
		printerr("No Data in cam_target()")
		return
	
	var unpacked_data = str_to_var(data[0])
	var node = get_node(unpacked_data[0])
	
	var cam = get_tree().get_first_node_in_group("camera")
	if !cam: return
	if unpacked_data.size() > 1:
		cam.set_target(node,unpacked_data[1])
	else:
		cam.set_target(node)

func cam_trauma(data):
	#data = var_to_str([float,float*])
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in cam_trauma()")
		return
	if !data.size() > 0:
		printerr("No Data in cam_trauma()")
		return
	
	var unpacked_data = str_to_var(data[0])
	var cam = get_tree().get_first_node_in_group("camera")
	if !cam: return
	if unpacked_data.size() > 1:
		cam.add_trauma(unpacked_data[0],unpacked_data[1])
	else:
		cam.add_trauma(unpacked_data[0])

func spawn_dmg(data):
	#data = var_to_str([Vector2(),serialized_dictionary])
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in spawn_dmg()")
		return
	if !data.size() > 0:
		printerr("No Data in spawn_dmg()")
		return
	
	var unpacked_data = str_to_var(data[0])
	var position = unpacked_data[0]
	var settings = DamageRadiusSettings.new()
	
	if unpacked_data.size() > 1:
		settings.deserialize(JSON.parse_string(unpacked_data[1]))
	
	App.spawn_dmg.emit(position,settings)

func get_all_player_state(state := "") -> Array:
	var all_state : Array = []
	for p in connected_players:
		all_state.append(p.getState(state))
	
	return all_state

func game_state_update(data):
	#data = var_to_str([int,...])
	
	if typeof(data) != TYPE_ARRAY: 
		printerr("Bad Data in game_state_update()")
		return
	if !data.size() > 0:
		printerr("No Data in game_state_update()")
		return
	
	var unpacked_data = str_to_var(data[0])
	
	match unpacked_data[0]:
		#0: pass #unreserved / test code
		App.gsu.ASSERT_STATE:
			App.assert_game_state()
		App.gsu.RELOAD_STATE:
			App.reload_game()
		App.gsu.REMOTE_MUSIC:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var play_music_data = JSON.parse_string(unpacked_data[1])
			SystemAudio.play_music(play_music_data["sound_path"],str_to_var(play_music_data["fade"]))
		App.gsu.REMOTE_MUSIC_INTRO:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var play_intro_data = JSON.parse_string(unpacked_data[1])
			SystemAudio.play_intro_then_loop(play_intro_data["intro_sound_path"],play_intro_data["loop_sound_path"],str_to_var(play_intro_data["fade_in"]))
		App.gsu.REMOTE_STOP_MUSIC:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_FLOAT: 
				print_debug("Wrong Type")
				return
			SystemAudio.stop_music(unpacked_data[1])
		App.gsu.REMOTE_SFX:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var play_data = JSON.parse_string(unpacked_data[1])
			SystemAudio.play(play_data["sound_path"],play_data["volume"],play_data["bus"],play_data["pitch"])
		App.gsu.REMOTE_LATERAL:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var push_lateral_data = JSON.parse_string(unpacked_data[1])
			SystemUI.push_lateral(push_lateral_data)
		App.gsu.REMOTE_TITLE:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var set_title_data = JSON.parse_string(unpacked_data[1])
			SystemUI.set_title(set_title_data["state"],set_title_data["shake"],set_title_data["title"],set_title_data["subtitle"],Color(set_title_data["s_colr"]))
		App.gsu.REMOTE_TITLE_PUSH:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var push_title_data = str_to_var(unpacked_data[1])
			SystemUI.push_title(push_title_data)
		App.gsu.REMOTE_BACKGROUND:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_STRING: 
				print_debug("Wrong Type")
				return
			var set_background_data = JSON.parse_string(unpacked_data[1])
			SystemUI.set_background(set_background_data["state"],set_background_data["colr"])
		App.gsu.DISABLE_CLIENT_BOSS: #kill client boss
			var mnstr = get_tree().get_first_node_in_group("monster")
			if !mnstr: return
			mnstr.check_host()
		App.gsu.ROAR_FX: #roar effect [7,bool]
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_BOOL: 
				print_debug("Wrong Type")
				return
			SystemUI.roar_effect(unpacked_data[1])
		App.gsu.PURGE_ATTACKS:
			App.purge_attacks.emit()
		App.gsu.STASH_METRICS:
			var metrics = {
				"name":App.player_name,
				"dmg":App.dmg_dealt,
				"heal":App.healing_performed,
				"rev":App.revolutions_made,
				"click":App.clicks_made
			}
			Plyrm.PLAYER.state.setState("pMetrics",JSON.stringify(metrics))
		App.gsu.SHOW_PERFORMANCE:
			SystemUI.remote_perf()
		App.gsu.HIDE_LEVEL_SELECT:
			SystemUI.open_level_select(false)
			SystemUI.force_close_perf()
			SystemUI.close_obj()
			App.tutorial_end.emit()
		App.gsu.SYNC_LEVEL:
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_INT: 
				print_debug("Wrong Type")
				return
			App.load_level(unpacked_data[1])
