extends CharacterBody2D
class_name system_controller

#CLICK ON ENEMY TO DEAL DAMAGE
#DEAL MORE DAMAGE DEPENDING ON CHARGE
#GAIN CHARGE BY DODGING
#CAN USE CHARGE TO DODGE MORE
#CLASS CONTROLS MAX CHARGE AND HEALTH
#WEAPON CONTROLS DAMAGE

@export var job : system_job
@export var weapon : system_weapon
var status : system_status

const SPEED = 100.0
var SPEED_MULTIPLIER := 1.0
var DASH_STRENGTH := 20.0
var FRICTION := 0.2
var ACCELERATION := 0.3
var DIRECTION : Vector2 = Vector2.ZERO

var MAX_PCACHE : int = 3
var CURRENT_PCACHE : int = 0
var CHARGE_AMOUNT : int = 1
var SCACHE : float = 0.0
var decay : bool = true

#var HEALTH : int = 5
var BDMG : int = 2

@onready var sprite = $Sprite
@onready var tspin_vfx = $topSpinVFX
@onready var bspin_vfx = $bottomSpinVFX
@onready var gesture = $Gesture

@onready var s_cache_lbl = $UI/Stats/MarginContainer/VBoxContainer/sCache
@onready var charge_bar = $UI/Stats/MarginContainer/VBoxContainer/Charge
@onready var p_cache_bar = $UI/Stats/pCacheBar
@onready var cooldown = $UI/Stats/MarginContainer/VBoxContainer/Cooldown
@onready var p_cooldown_bar = $UI/Stats/pCooldownBar

const FTXT = preload("res://Game/float_text.tscn")

var dash_cooldown := 0.0
var dash_cooldown_length := 2.0
#var last_direction : Vector2 = Vector2.ZERO

func _ready():
	#App.knock_plyr.connect(knockback)
	add_to_group("player")
	tspin_vfx.play("topSPIN")
	bspin_vfx.play("bottomSPIN")
	gesture.circle_drawn.connect(s_charge)
	
	set_job()
	charge_bar.max_value = MAX_PCACHE
	p_cache_bar.max_value = MAX_PCACHE
	charge_bar.value = CURRENT_PCACHE
	p_cache_bar.value = CURRENT_PCACHE

func set_job():
	if job:
		job.setup()
		#HEALTH = job.final_health
		if !status: status = system_status.new()
		status.setup(job.final_health)
		MAX_PCACHE = job.final_m_pc
		CHARGE_AMOUNT = job.final_pc_c
		BDMG = job.final_base_dmg

func on_damage(amt : int):
	status._damage(amt)
	disp_ftxt(str("[color=#e34262]",amt),global_position + Vector2(0,25),FloatingText.a.POP)
	#set health bar here
	#print(status.health)

func disp_ftxt(text : String, pos : Vector2, anim : FloatingText.a = FloatingText.a.FLOAT, outline : Dictionary = {}):
	var new = FTXT.instantiate()
	new.inital_position = pos
	new.anim = anim
	new.text = text
	if outline:
		new.outline_color = outline.color
		new.outline_size = outline.size
	add_child(new)

func calc_light_dmg() -> int:
	var d : int = BDMG
	if weapon: d = weapon.calc_damage(BDMG)
	#disp_ftxt(str(d),get_global_mouse_position(),FloatingText.a.FLOAT)
	return d

func calc_heavy_dmg(s : float) -> int:
	var d : int = int(floor((float(BDMG) + s) * s))
	if weapon: d = weapon.calc_heavy_damage(BDMG,s)
	#disp_ftxt(str(d),get_global_mouse_position(),FloatingText.a.POP_SHOOT)
	return d

func calc_heal() -> int:
	var h = BDMG
	if weapon: h = weapon.calc_heal(BDMG)
	return h

func calc_inflict(c : int) -> Array:
	if weapon: return weapon.calc_inflict(BDMG,c)
	return [system_status.effects.NONE,0.0]

@onready var sight = $Sight
func can_see(sub : Node2D) -> bool:
	sight.target_position = sub.global_position - sight.global_position
	#await get_tree().process_frame
	if sight.is_colliding() and sight.get_collider() != sub:
		print_rich("[color=red]can't see!")
		return false
	else: 
		#print("can see!")
		return true

var knocked : bool = false
func knockback(from : Vector2, strr : float = 10):
	knocked = true
	var kbdir = global_position - from
	velocity += kbdir.normalized() * strr
	await get_tree().create_timer(0.7).timeout
	knocked = false

func drag(to : Vector2, strr : float = 10):
	var drgdir = to - global_position
	velocity += drgdir.normalized() * strr

func _process(delta):
	if SCACHE > 0.0 and decay:
		SCACHE -= 0.001
		update_s_charge()

func _physics_process(delta):
	#WACKY
	if App.can_input and !knocked:
		DIRECTION = isometrize(Input.get_vector("MLEFT", "MRIGHT", "MUP", "MDOWN").rotated(deg_to_rad(-45))).normalized()
	#DON"T ROTATE FOR NORMAL
	
	#if Input.is_action_just_pressed("ACTIONB"):
		#shoot()
		#if DIRECTION: last_direction = DIRECTION
		#DIRECTION = last_direction
		#SPEED_MULTIPLIER = 10.0
	#if Input.is_action_just_released("ACTIONB"):
		#SPEED_MULTIPLIER = 1.0
	
	manage_animation(DIRECTION)
	if DIRECTION:
		velocity = lerp(velocity,DIRECTION * (SPEED * SPEED_MULTIPLIER),ACCELERATION)
		#last_direction = DIRECTION
	else:
		velocity = lerp(velocity,Vector2.ZERO,FRICTION)
	
	if Input.is_action_just_pressed("ACTIONA") and DIRECTION:
		if dash_cooldown <= 0.0 or CURRENT_PCACHE != 0:
			velocity *= DASH_STRENGTH
			var new_cooldown = dash_cooldown_length
			if dash_cooldown <= dash_cooldown_length * 0.2: charge()
			else:
				new_cooldown += dash_cooldown 
				discharge()
			dash_cooldown = new_cooldown
			cooldown.max_value = dash_cooldown
			p_cooldown_bar.max_value = dash_cooldown
			kill_spin()
		else:
			print("on cooldown ", dash_cooldown)
	elif dash_cooldown > 0.0:
		cooldown.value = dash_cooldown
		p_cooldown_bar.value = dash_cooldown
		dash_cooldown -= delta
	if dash_cooldown <= 0.0 and (tspin_vfx.modulate.a == 0.0 or bspin_vfx.modulate.a == 0.0):
		stw = create_tween()
		stw.tween_property(tspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
		stw.parallel().tween_property(bspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	
	move_and_slide()
	sync_state()

func sync_state():
	var state = {
		"pos_x":global_position.x,
		"pos_y":global_position.y,
		"on_cooldown": !(dash_cooldown <= 0.0),
		"direction":var_to_str(DIRECTION)
	}
	if Plyrm.PLAYER: 
		#Plyrm.Playroom.setState(str("pState_",Plyrm.PLAYERData.id),JSON.stringify(state))
		Plyrm.PLAYER.state.setState("pState",JSON.stringify(state))

func charge():
	if CURRENT_PCACHE >= 0 and CURRENT_PCACHE < MAX_PCACHE:
		CURRENT_PCACHE += CHARGE_AMOUNT
		CURRENT_PCACHE = clamp(CURRENT_PCACHE,0,MAX_PCACHE)
		print(CURRENT_PCACHE)
		disp_ftxt(str("+"),global_position + Vector2(0,25),FloatingText.a.POP)
	else:
		disp_ftxt("MAX!",global_position + Vector2(0,25),FloatingText.a.POP)
		print(CURRENT_PCACHE," MAX!")
	charge_bar.value = CURRENT_PCACHE
	p_cache_bar.value = CURRENT_PCACHE

func s_charge():
	if !decay: return
	var minc = 0.1 * pow(2.718,-0.9 * (SCACHE - 2.0))
	var maxc = 0.45 * pow(2.718,-0.9 * (SCACHE - 2.0))
	var val = randf_range(minc,maxc)
	SCACHE += val
	s_cache_lbl.text = str(snappedf(SCACHE,0.01),"[b]ghz")
	disp_ftxt(str("[font_size=10][shake]!!!"),global_position + Vector2(0,45),FloatingText.a.POP)
	#print(min,"/",max,"->",val)

func update_s_charge():
	s_cache_lbl.text = str(snappedf(SCACHE,0.01),"[b]ghz")

func s_discharge() -> float:
	if !decay: return 0.0
	if !discharge(): return 0.0
	var amt = SCACHE
	if amt != 0.0:
		decrease_s_cache()
	return amt

func decrease_s_cache():
	decay = false
	var tw = create_tween()
	tw.tween_method(tw_sc_cnt,SCACHE,0.0,3.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	await tw.finished
	#while SCACHE > 0.0:
		#SCACHE -= 0.1
		#if SCACHE < 0.0: SCACHE = 0.0
		#update_s_charge()
		#await get_tree().process_frame
	SCACHE = 0.0
	decay = true
	update_s_charge()

func tw_sc_cnt(nv : float):
	SCACHE = nv
	update_s_charge()

func discharge() -> bool:
	if CURRENT_PCACHE > 0:
		CURRENT_PCACHE -= 1
		charge_bar.value = CURRENT_PCACHE
		p_cache_bar.value = CURRENT_PCACHE
		#disp_ftxt(str("[font_size=10][color=orange]-1!"),global_position + Vector2(0,25),FloatingText.a.POP)
		return true
	print("EMPTY!")
	disp_ftxt("[color=orange]!",global_position + Vector2(0,25),FloatingText.a.POP)
	return false

#func shoot():
	#if !discharge(): return
	#var shoot_dir = camera.get_global_mouse_position() - global_position
	#
	##Knockback
	#velocity -= (shoot_dir.normalized() * SPEED) * 6.0
	#
	#var pro = preload("res://Game/projectile.tscn")
	#var new = pro.instantiate()
	#add_child(new)
	#new.apply_central_impulse(shoot_dir.normalized() * 300.0)
	#new.position = global_position
	#await get_tree().create_timer(2.0).timeout
	#remove_child(new)
	#new.queue_free()

var stw : Tween
func kill_spin():
	if stw: stw.kill()
	#var tw = create_tween()
	#tw.tween_property(tspin_vfx,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
	#tw.parallel().tween_property(bspin_vfx,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
	tspin_vfx.modulate.a = 0.0
	bspin_vfx.modulate.a = 0.0
	tspin_vfx.frame = 0
	bspin_vfx.frame = 0
	tspin_vfx.flip_h = !tspin_vfx.flip_h
	bspin_vfx.flip_h = !bspin_vfx.flip_h
	#await get_tree().create_timer(0.25).timeout
	#tw = create_tween()
	#tw.tween_property(tspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	#tw.parallel().tween_property(bspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	#await tw.finished

func isometrize(v : Vector2) -> Vector2:
	var new : Vector2 = Vector2()
	new.x = v.x - v.y
	new.y = (v.x + v.y) / 2.0
	return new

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
