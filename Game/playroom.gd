extends Node

#I do all the playroom stuff!
#Fetch Playroom
var Playroom = JavaScriptBridge.get_interface("Playroom")

signal PR_PLAYER_JOIN 
signal PR_PLAYER_QUIT
signal PR_INSERT_COIN
signal PR_SESSION_END
signal PR_DISCONNECT

var PLAYERData : Dictionary = {}
var sync_objs : Array = []

var players : Array = []

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
	print("Coin Inserted!")
	blog("Coin Inserted!")
	Playroom.onPlayerJoin(bridgeToJS(onPlayerJoin))
	PR_INSERT_COIN.emit()

func onSessionEnd(args):
	print("Session has ended, ",args)
	blog(str("Session has ended, ",args))
	PR_SESSION_END.emit()

func onDisconnect(args):
	print("Disconnect!", args.code," ",args.reason)
	blog(str("Disconnect!", args.code," ",args.reason))
	PR_DISCONNECT.emit(args)

# Called when a new player joins the game
func onPlayerJoin(args):
	var state = args[0]
	players.append(state)
	print("new player joined: ", state.id)
	blog(str("new player joined: ", state.id))
	PR_PLAYER_JOIN.emit(args)
	# Listen to onQuit event
	state.onQuit(bridgeToJS(onPlayerQuit))
 
func onPlayerQuit(args):
	var state = args[0];
	players.erase(state)
	print("player quit: ", state.id)
	blog(str("player quit: ", state.id))
	PR_PLAYER_QUIT.emit(args)

@onready var room_input = $PRUI/LobbyUI/VBoxContainer/RoomInput
@onready var join_room = $PRUI/LobbyUI/VBoxContainer/JoinRoom
@onready var debug = $PRUI/LobbyUI/debug
func _on_join_room_pressed():
	join_room.release_focus()
	join_room.disabled = true
	JavaScriptBridge.eval("")
	var initOptions = JavaScriptBridge.create_object("Object");
	
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
	Playroom.insertCoin(initOptions, bridgeToJS(onInsertCoin), bridgeToJS(onSessionEnd));
	
	$PRUI/LobbyUI/VBoxContainer.hide()
	await PR_INSERT_COIN
	#await get_tree().create_timer(1.0).timeout
	room_input.text = Playroom.getRoomCode()
	room_input.editable = false
	
	var player = Playroom.me()
	var pd : Dictionary = {
		"id":player.id,
		"host":Playroom.isHost()
	}
	PLAYERData = pd
	Playroom.onDisconnect(bridgeToJS(onDisconnect))
	blog(str(pd))
