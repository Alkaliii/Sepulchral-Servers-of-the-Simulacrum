extends CharacterBody2D


var my_id
var state

func _ready():
	add_to_group("puppet")
	Plyrm.PR_PLAYER_QUIT.connect(on_quit)
	tspin_vfx.play("topSPIN")
	bspin_vfx.play("bottomSPIN")

func on_quit(args):
	await create_tween().tween_property(self,"scale",Vector2.ZERO,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).finished
	if args[0].id == my_id:
		my_id = null
		get_parent().remove_child(self)
		queue_free()

func knockback(from : Vector2, strr : float = 10):
	pass #to client?

func _process(delta):
	if state:
		var data
		var puppet_state = state.getState("pState")
		if puppet_state: data = JSON.parse_string(puppet_state)
		else: return
		
		var pos = Vector2(data.pos_x,data.pos_y)
		manage_animation(str_to_var(data.direction))
		manage_spin(data.on_cooldown)
		create_tween().tween_property(self,"global_position",pos,0.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

var stw : Tween
func manage_spin(state : bool):
	if !state and (tspin_vfx.modulate.a == 0.0 or bspin_vfx.modulate.a == 0.0):
		stw = create_tween()
		stw.tween_property(tspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
		stw.parallel().tween_property(bspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	elif state and (tspin_vfx.modulate.a != 0.0 or bspin_vfx.modulate.a != 0.0):
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
