extends CharacterBody2D


@export var SPEED = 80.0
@export var SPEED_MULTIPLIER := 1.0
@export var DASH_STRENGTH := 20.0
@export var FRICTION := 0.2
@export var ACCELERATION := 0.3
var DIRECTION : Vector2 = Vector2.ZERO

#behaviours are processed on host

func _physics_process(delta):
	if Plyrm.PLAYERData and !Plyrm.Playroom.isHost():
		set_physics_process(false)
		return
	chase(delta)

func set_behaviour_time(new_dura : float):
	behaviour_time_elapse = 0.0
	behaviour_duration = new_dura

var behaviour_time_elapse : float = 0.0
var behaviour_duration : float = 10.0
var chase_target : Node2D
func chase(delta):
	#Set target
	if !chase_target or (behaviour_time_elapse >= behaviour_duration):
		set_behaviour_time(randf_range(10,20))
		var possible_target : Array = get_tree().get_nodes_in_group("puppet")
		possible_target.append(get_tree().get_first_node_in_group("player"))
		chase_target = possible_target.pick_random()
	
	#run away sorta DIRECTION = (global_position - chase_target.global_position).normalized()
	DIRECTION = (chase_target.global_position - global_position).normalized()
	if DIRECTION:
		velocity = lerp(velocity,DIRECTION * (SPEED * SPEED_MULTIPLIER),ACCELERATION)
		#last_direction = DIRECTION
	else:
		velocity = lerp(velocity,Vector2.ZERO,FRICTION)
	
	behaviour_time_elapse += delta
	move_and_slide()
