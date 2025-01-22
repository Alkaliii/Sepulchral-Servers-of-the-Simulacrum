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
var sync_objs : Array = []

var connected_players : Array = []
var connected : bool = false

# Keep a reference to the callback so it doesn't get garbage collected
var jsBridgeReferences = []
func bridgeToJS(cb):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback
 
func _ready():
	if OS.has_feature("pc"): $PRUI.hide()

func blog(txt : String):
	debug.text += "\n"
	debug.text += txt

# Called when the host has started the game
func onInsertCoin(args):
	register_rpc()
	connected = true
	print("Coin Inserted!")
	blog("Coin Inserted!")
	Playroom.onPlayerJoin(bridgeToJS(onPlayerJoin))
	PR_INSERT_COIN.emit()

func onSessionEnd(args):
	connected = false
	print("Session has ended, ",args)
	blog(str("Session has ended, ",args))
	PR_SESSION_END.emit()

func onDisconnect(args):
	connected = false
	print("Disconnect!", args.code," ",args.reason)
	blog(str("Disconnect!", args.code," ",args.reason))
	PR_DISCONNECT.emit(args)

# Called when a new player joins the game
func onPlayerJoin(args):
	var state = args[0]
	connected_players.append(state)
	print("new player joined: ", state.id)
	blog(str("new player joined: ", state.id))
	PR_PLAYER_JOIN.emit(args)
	# Listen to onQuit event
	state.onQuit(bridgeToJS(onPlayerQuit))
 
func onPlayerQuit(args):
	var state = args[0];
	connected_players.erase(state)
	print("player quit: ", state.id)
	blog(str("player quit: ", state.id))
	PR_PLAYER_QUIT.emit(args)

@onready var start_game = $PRUI/LobbyUI/StartGame
func _on_start_game_pressed():
	if Plyrm.Playroom.isHost():
		start_game.release_focus()
		start_game.hide()
		App.start_boss.emit()

@onready var room_input = $PRUI/LobbyUI/VBoxContainer/RoomInput
@onready var join_room = $PRUI/LobbyUI/VBoxContainer/JoinRoom
@onready var debug = $PRUI/LobbyUI/debug
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
	initOptions.maxPlayersPerRoom = 2

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
		0: pass #unreserved / test code
		6: #kill client boss
			var mnstr = get_tree().get_first_node_in_group("monster")
			if !mnstr: return
			mnstr.check_host()
		7: #roar effect [7,bool]
			if unpacked_data.size() < 2: 
				print_debug("Not enough data")
				return
			if typeof(unpacked_data[1]) != TYPE_BOOL: 
				print_debug("Wrong Type")
				return
			SystemUI.roar_effect(unpacked_data[1])
