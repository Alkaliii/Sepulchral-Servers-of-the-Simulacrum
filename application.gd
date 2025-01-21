extends Node


var can_click : bool = true
var can_input : bool = true

signal start_boss
signal spawn_dmg #position : vector2, dmgSettings

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
