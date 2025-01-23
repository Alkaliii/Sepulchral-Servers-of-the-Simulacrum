extends Node


var can_click : bool = true
var can_input : bool = true

signal start_boss
signal spawn_dmg #position : vector2, dmgSettings
signal reload_boss

#var saved_job : system_job
#var saved_weapon : system_weapon
var job_inventory : Array[system_job] = []
var weapon_inventory : Array[system_weapon] = []

var dmg_dealt : int = 0 #click damage
var healing_performed : int = 0 #click healing
var clicks_made : int = 0 #how many times you clicked

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
	if count_host: in_game += get_tree().get_nodes_in_group("player").size()
	in_game += get_tree().get_nodes_in_group("puppet").size()
	return in_game

func reload_game():
	reload_boss.emit()
	#reload player states also
	var plyr = get_tree().get_first_node_in_group("player")
	plyr.set_job()

func reset_performace_metrics():
	dmg_dealt = 0
	healing_performed = 0
	clicks_made = 0
