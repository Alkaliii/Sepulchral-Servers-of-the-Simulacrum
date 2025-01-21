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
	Playroom.RPC.register("spawn_dmg",bridgeToJS(spawn_dmg))
	Playroom.RPC.register("cam_target",bridgeToJS(cam_target))
	Playroom.RPC.register("cam_trauma",bridgeToJS(cam_trauma))
	Playroom.RPC.register()

func player_knockback():pass

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
