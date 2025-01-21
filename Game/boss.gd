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
	App.start_boss.connect(test_start)
	Plyrm.PR_PLAYER_JOIN.connect(check_host)
	Plyrm.PR_PLAYER_QUIT.connect(check_host)
	Plyrm.PR_SESSION_END.connect(check_host)
	Plyrm.PR_DISCONNECT.connect(check_host)
	
	add_to_group("monster")
	monster_data.status.setup(monster_data.base_health)
	healthbar.max_value = monster_data.base_health
	healthbar.value = monster_data.status.health
	hit_detector.DAMAGED.connect(on_damage)
	#hit_detector.AFFLICTED.connect()
	
	if OS.has_feature("pc"): test_start()

func test_start():
	await get_tree().create_timer(3.0).timeout
	await roar(str("You encounter [shake]",monster_data.name))
	test_phase()

func check_host(args = null):
	if Plyrm.PLAYER and !Plyrm.Playroom.isHost():
		print("kys")
		set_physics_process(false)
		kill_phase()
		return
	else:
		set_physics_process(true)
		#restart the game...?

func test_phase():
	if phases.is_empty(): return
	
	for i in phases:
		i.setup(self)
	
	await App.process_frame()
	
	phases[0].is_active = true
	phases[0].play_phase()
	
	#while true:
		#phases[0].ATTACK_OPTIONS[0].attack(self)
		#await phases[0].ATTACK_OPTIONS[0].attack_complete
		#phases[0].SPECIAL_OPTIONS[0].perfrom_special(self)
		#await phases[0].SPECIAL_OPTIONS[0].special_complete
		#phases[0].MOVEMENT_OPTIONS[0].move(self)
		#await phases[0].MOVEMENT_OPTIONS[0].movement_complete

func change_phase(new_phase : int = -1):
	print("CHANGING PHASE!"," RANDOM" if new_phase == -1 else new_phase)
	var phs : Phase
	if new_phase and new_phase != -1: phs = phases[new_phase]
	else: phs = phases.pick_random()
	
	start_phase(phs)

func start_phase(phs : Phase):
	phs.clean_actions()
	phs.is_active = true
	phs.cancel = false
	phs.last_phase_action = false
	phs.phase_idx = 0
	phs.play_phase()

func kill_phase():
	for phs in phases: phs.kill_phase()

#@onready var boss_sprite = $Sprite
var dtw : Tween
func disappear(state : bool):
	if dtw: dtw.kill()
	dtw = create_tween()
	match state:
		true:
			set_collision_layer_value(1,false)
			hit_detector.disabled = true
			dtw.tween_property(self,"scale",Vector2.ZERO,0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			await dtw.finished
			hide()
		false:
			show()
			dtw.tween_property(self,"scale",Vector2.ONE,0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			await dtw.finished
			set_collision_layer_value(1,true)
			hit_detector.disabled = false

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
		1: 
			cam.add_trauma(1,0.8)
			for p in phases:
				p.on_heavy_received()
	
	check_progress()

func check_progress():
	if monster_data.status.health <= 0 and !dead:
		kill_phase()
		dead = true
		await roar()
	elif monster_data.status.health < (monster_data.status.max_health * .5) and !halfway_dead:
		kill_phase()
		halfway_dead = true
		await roar(str(monster_data.name," is weak!"))
		start_phase(phases.pick_random())

func roar(msg : String = "!!!"):
	SystemUI.play_message(msg,6)
	App.can_click = false
	var cam = get_tree().get_first_node_in_group("camera")
	cam.set_target($Sprite,Vector2(0,-45))
	if Plyrm.connected: cam.sync_target()
	await get_tree().create_timer(0.5).timeout
	cam.add_trauma(10)
	if Plyrm.connected: cam.sync_trauma(10)
	await get_tree().create_timer(2.5).timeout
	cam.set_target(get_tree().get_first_node_in_group("player"))
	if Plyrm.connected: cam.sync_target()
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
	sync_state()
	check_host()
	#chase(delta)

func _process(delta):
	if Plyrm.PLAYER and !is_physics_processing():
		var data
		var boss_state = Plyrm.Playroom.getState("bState")
		if boss_state: data = JSON.parse_string(boss_state)
		else: return
		
		var pos = Vector2(data.pos_x,data.pos_y)
		create_tween().tween_property(self,"global_position",pos,0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

func sync_state():
	var state = {
		"pos_x":global_position.x,
		"pos_y":global_position.y,
		#"on_cooldown": !(dash_cooldown <= 0.0),
		#"direction":var_to_str(DIRECTION)
	}
	if Plyrm.PLAYER: 
		#Plyrm.Playroom.setState(str("pState_",Plyrm.PLAYERData.id),JSON.stringify(state))
		Plyrm.Playroom.setState("bState",JSON.stringify(state))

#func set_behaviour_time(new_dura : float):
	#behaviour_time_elapse = 0.0
	#behaviour_duration = new_dura
#
#var behaviour_time_elapse : float = 0.0
#var behaviour_duration : float = 10.0
#var chase_target : Node2D
#func chase(delta):
	##Set target
	#if !chase_target or (behaviour_time_elapse >= behaviour_duration):
		#set_behaviour_time(randf_range(10,20))
		#var possible_target : Array = get_tree().get_nodes_in_group("puppet")
		#possible_target.append(get_tree().get_first_node_in_group("player"))
		#chase_target = possible_target.pick_random()
	#
	##run away sorta DIRECTION = (global_position - chase_target.global_position).normalized()
	#DIRECTION = (chase_target.global_position - global_position).normalized()
	#if DIRECTION:
		#velocity = lerp(velocity,DIRECTION * (SPEED * SPEED_MULTIPLIER),ACCELERATION)
		##last_direction = DIRECTION
	#else:
		#velocity = lerp(velocity,Vector2.ZERO,FRICTION)
	#
	#behaviour_time_elapse += delta
	#move_and_slide()
