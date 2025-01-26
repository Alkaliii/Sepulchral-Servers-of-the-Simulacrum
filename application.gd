extends Node


var can_click : bool = true
var can_input : bool = true

signal start_boss
signal spawn_dmg #position : vector2, dmgSettings
signal reload_boss
signal purge_attacks #remove attacks
signal tutorial_click

#var saved_job : system_job
#var saved_weapon : system_weapon
var player_name : String
var job_inventory : Array[system_job] = []
var weapon_inventory : Array[system_weapon] = []

var dmg_dealt : int = 0 #click damage
var healing_performed : int = 0 #click healing
var clicks_made : int = 0 #how many times you clicked
var revolutions_made : int = 0 #how many times you spun your cursor

var performance_screen_details : Dictionary = {
	"bhp":1000,
	"time":300
}

enum gsu {
	ASSERT_STATE,
	RELOAD_STATE,
	REMOTE_MUSIC,
	REMOTE_STOP_MUSIC,
	REMOTE_SFX,
	REMOTE_LATERAL, #send messages
	REMOTE_TITLE,
	DISABLE_CLIENT_BOSS,
	ROAR_FX,
	PURGE_ATTACKS,
	STASH_METRICS,
	SHOW_PERFORMANCE,
}

func _ready():
	player_name = fTxt.playerNames.pick_random()
	print(player_name)

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

func validate_alive(count_host : bool = true) -> int:
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
