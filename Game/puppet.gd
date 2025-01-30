extends CharacterBody2D
class_name system_player_puppet

var my_id
var state
@onready var mp_status = $mpStatus
@onready var hit_detector = $HitDetector

func _ready():
	add_to_group("puppet")
	Plyrm.PR_PLAYER_QUIT.connect(on_quit)
	tspin_vfx.play("topSPIN")
	bspin_vfx.play("bottomSPIN")
	
	hit_detector.HEALED.connect(on_heal)
	hit_detector.CLEARED.connect(on_clear)
	hit_detector.GUARDED.connect(on_guard)
	
	while true:
		var pname
		if state: pname = state.getState("name")
		if pname: 
			mp_status.set_plyr_name(pname)
			break
		await App.time_delay(1.0)

func on_heal(amt:int):
	var data : Array = []
	data.append(my_id)
	data.append(0) #0 means heal here
	data.append(App.player_name)
	data.append(amt)
	
	Plyrm.Playroom.RPC.call("player_aid",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func on_clear():
	var data : Array = []
	data.append(my_id)
	data.append(1) #0 means clear here
	data.append(App.player_name)
	
	Plyrm.Playroom.RPC.call("player_aid",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func on_guard():
	var data : Array = []
	data.append(my_id)
	data.append(2) #0 means guard here
	data.append(App.player_name)
	
	Plyrm.Playroom.RPC.call("player_aid",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func on_quit(args):
	await create_tween().tween_property(self,"scale",Vector2.ZERO,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).finished
	if args[0].id == my_id:
		my_id = null
		get_parent().remove_child(self)
		queue_free()

var dead : bool = false
func sync_dead(dstate:bool):
	dead = dstate
	match dstate:
		true:
			#turn on off hit detection here (for aid)
			#make request to check game state (auto)
			remove_from_group("puppet")
			await create_tween().tween_property(self,"scale",Vector2.ZERO,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).finished
		false:
			add_to_group("puppet")
			await create_tween().tween_property(self,"scale",Vector2.ONE,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).finished

func knockback(from : Vector2, strr : float = 10):
	#Boss on host calls knockback on puppet on host
	#Puppet passes call to client via RPC
	
	print("puppet knockback")
	var data : Array = []
	data.append(my_id) #This is used to determine which client actually listens?
	data.append(from)
	data.append(strr)
	
	Plyrm.Playroom.RPC.call("player_knockback",var_to_str(data),Plyrm.Playroom.RPC.Mode.OTHERS)

func _process(_delta):
	if state:
		var data
		var puppet_state = state.getState("pState")
		if puppet_state: data = JSON.parse_string(puppet_state)
		else: return
		
		var pos = Vector2(data.pos_x,data.pos_y)
		manage_animation(str_to_var(data.direction))
		manage_spin(data.on_cooldown)
		if data.dead != dead: sync_dead(data.dead)
		if str_to_var(data.health) != mp_status.cur: mp_status.set_status(str_to_var(data.health))
		create_tween().tween_property(self,"global_position",pos,0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

var stw : Tween
func manage_spin(sstate : bool):
	if !sstate and (tspin_vfx.modulate.a == 0.0 or bspin_vfx.modulate.a == 0.0):
		stw = create_tween()
		stw.tween_property(tspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
		stw.parallel().tween_property(bspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	elif sstate and (tspin_vfx.modulate.a != 0.0 or bspin_vfx.modulate.a != 0.0):
		tspin_vfx.modulate.a = 0.0
		bspin_vfx.modulate.a = 0.0

@onready var sprite = $Sprite
@onready var tspin_vfx = $topSpinVFX
@onready var bspin_vfx = $bottomSpinVFX
var CURRENT_ANIMATION : String = "NA_NA"
func manage_animation(v : Vector2):
	if v == Vector2.ZERO:
		match CURRENT_ANIMATION.split("_")[1]:
			"right":
				sprite.play("IdleSide")
				sprite.flip_h = true
			"left":
				sprite.play("IdleSide")
				sprite.flip_h = false
			"up":
				sprite.play("IdleForward")
				sprite.flip_h = false
			"down":
				sprite.play("IdleForward")
				sprite.flip_h = false
			"north":
				sprite.play("IdleTilt")
				sprite.flip_h = false
			"east":
				sprite.play("IdleTilt")
				sprite.flip_h = true
			"south":
				sprite.play("IdleTilt")
				sprite.flip_h = false
			"west":
				sprite.play("IdleTilt")
				sprite.flip_h = true
		CURRENT_ANIMATION = "IDLE_IDLE"
		return
	
	#RIGHT
	if (v.x < 0.0 and v.y == 0.0) and !CURRENT_ANIMATION.contains("_right"):
		sprite.play("MoveSide")
		sprite.flip_h = true
		CURRENT_ANIMATION = str(sprite.animation,"_right")
	
	#LEFT
	if (v.x > 0.0 and v.y == 0.0) and !CURRENT_ANIMATION.contains("_left"):
		sprite.play("MoveSide")
		sprite.flip_h = false
		CURRENT_ANIMATION = str(sprite.animation,"_left")
	
	#UP
	if (v.x == 0.0 and v.y < 0.0) and !CURRENT_ANIMATION.contains("_up"):
		sprite.play("MoveForward")
		sprite.flip_h = false
		CURRENT_ANIMATION = str(sprite.animation,"_up")
	
	#DOWN
	if (v.x == 0.0 and v.y > 0.0) and !CURRENT_ANIMATION.contains("_down"):
		sprite.play("MoveForward")
		sprite.flip_h = false
		CURRENT_ANIMATION = str(sprite.animation,"_down")
	
	#NORTH
	if (v.x > 0.0 and v.y < 0.0) and !CURRENT_ANIMATION.contains("_north"):
		sprite.play("MoveTilt")
		sprite.flip_h = false
		CURRENT_ANIMATION = str(sprite.animation,"_north")
	
	#EAST
	if (v.x > 0.0 and v.y > 0.0) and !CURRENT_ANIMATION.contains("_east"):
		sprite.play("MoveTilt")
		sprite.flip_h = true
		CURRENT_ANIMATION = str(sprite.animation,"_east")
	
	#SOUTH
	if (v.x < 0.0 and v.y > 0.0) and !CURRENT_ANIMATION.contains("_south"):
		sprite.play("MoveTilt")
		sprite.flip_h = false
		CURRENT_ANIMATION = str(sprite.animation,"_south")
	
	#WEST
	if (v.x < 0.0 and v.y < 0.0) and !CURRENT_ANIMATION.contains("_west"):
		sprite.play("MoveTilt")
		sprite.flip_h = true
		CURRENT_ANIMATION = str(sprite.animation,"_west")
