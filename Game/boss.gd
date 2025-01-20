extends CharacterBody2D
class_name system_monster_controller

@export var monster_data : system_monster
@export var monster_weapon : system_weapon
@export var phases : Array[Phase] = []

@export var SPEED = 80.0
@export var SPEED_MULTIPLIER := 1.0
@export var DASH_STRENGTH := 20.0
@export var FRICTION := 0.2
@export var ACCELERATION := 0.3
var DIRECTION : Vector2 = Vector2.ZERO

@onready var hit_detector = $HitDetector
@onready var healthbar = $CanvasLayer/stats/MarginContainer/VBoxContainer/healthbar

#behaviours are processed on host

const FTXT = preload("res://Game/float_text.tscn")

var halfway_dead := false
var dead := false

# On host, phase is selected, this is propagated via RPC to client bosses
# During phase an attack is called, this is also propagated via RPC to client bosses
# The RPC call may send additional data about the attack so the one performed on the client side is similar to host
# Using the phase movement, the host will move, clients will sync using state

func _ready():
	add_to_group("monster")
	monster_data.status.setup(monster_data.base_health)
	healthbar.max_value = monster_data.base_health
	healthbar.value = monster_data.status.health
	hit_detector.DAMAGED.connect(on_damage)
	#hit_detector.AFFLICTED.connect()
	
	await get_tree().create_timer(3.0).timeout
	roar(str("You encounter [shake]",monster_data.name))
	test_phase()

func test_phase():
	if phases.is_empty(): return
	
	for i in phases:
		i.setup()
	
	while true:
		phases[0].ATTACK_OPTIONS[0].attack(self)
		await phases[0].ATTACK_OPTIONS[0].attack_complete
		phases[0].MOVEMENT_OPTIONS[0].move(self)
		await phases[0].MOVEMENT_OPTIONS[0].movement_complete

@onready var sight = $Sight
func check_position(pos : Vector2) -> Vector2:
	sight.target_position = pos - sight.global_position
	if sight.is_colliding():
		return sight.get_collision_point()
	else:
		return pos

func on_damage(amt : int, click : int): #send player data in
	#check condition before validating
	monster_data.status._damage(amt)
	disp_ftxt(str(amt,"!" if click == 1 else ""),global_position - Vector2(0,45),[FloatingText.a.POP,FloatingText.a.POP_SHOOT].pick_random())
	healthbar.value = monster_data.status.health
	
	var cam = get_tree().get_first_node_in_group("camera")
	match click:
		0: cam.add_trauma(0.4,0.9)
		1: cam.add_trauma(1,0.8)
	
	check_progress()

func check_progress():
	if monster_data.status.health <= 0 and !dead:
		dead = true
		roar()
	elif monster_data.status.health < (monster_data.status.max_health * .5) and !halfway_dead:
		halfway_dead = true
		roar(str(monster_data.name," is weak!"))

func roar(msg : String = "!!!"):
	SystemUI.play_message(msg,6)
	App.can_click = false
	var cam = get_tree().get_first_node_in_group("camera")
	cam.set_target($Sprite,Vector2(0,-45))
	await get_tree().create_timer(0.5).timeout
	cam.add_trauma(10)
	await get_tree().create_timer(2.5).timeout
	cam.set_target(get_tree().get_first_node_in_group("player"))
	App.can_click = true

func disp_ftxt(text : String, pos : Vector2, anim : FloatingText.a = FloatingText.a.FLOAT, outline : Dictionary = {}):
	var new = FTXT.instantiate()
	new.inital_position = pos
	new.anim = anim
	new.text = text
	if outline:
		new.outline_color = outline.color
		new.outline_size = outline.size
	add_child(new)

func _physics_process(delta):
	if Plyrm.PLAYER and !Plyrm.Playroom.isHost():
		set_physics_process(false)
		return
	#chase(delta)

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
