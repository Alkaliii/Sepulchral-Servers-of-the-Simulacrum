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

@onready var health_bar = $UI/Stats/MarginContainer/stats/HealthBar
@onready var under_bar = $UI/Stats/MarginContainer/stats/HealthBar/UnderBar
@onready var s_cache_lbl = $UI/Stats/MarginContainer/VBoxContainer/sCache
@onready var charge_bar = $UI/Stats/MarginContainer/VBoxContainer/Charge
@onready var p_cache_bar = $UI/Stats/MarginContainer/stats/pCacheBar#$UI/Stats/pCacheBar
@onready var cooldown = $UI/Stats/MarginContainer/VBoxContainer/Cooldown
@onready var p_cooldown_bar = $UI/Stats/MarginContainer/stats/pCooldownBar#$UI/Stats/pCooldownBar

const FTXT = preload("res://Game/float_text.tscn")

var dash_cooldown := 0.0
var dash_cooldown_length := 2.0
#var last_direction : Vector2 = Vector2.ZERO

var canDealDamage : bool = true
var invertControls : bool = false

func _ready():
	#App.knock_plyr.connect(knockback)
	random_start_position()
	add_to_group("player")
	add_to_group("player_persistant")
	tspin_vfx.play("topSPIN")
	bspin_vfx.play("bottomSPIN")
	gesture.circle_drawn.connect(s_charge)
	
	set_job()

func set_job():
	dead = false
	App.can_click = true
	add_to_group("player")
	await create_tween().tween_property(self,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).finished
	if job:
		job.setup()
		#HEALTH = job.final_health
		if !status: status = system_status.new()
		status.setup(job.final_health)
		MAX_PCACHE = job.final_m_pc
		CHARGE_AMOUNT = job.final_pc_c
		BDMG = job.final_base_dmg
	health_bar.max_value = status.max_health
	under_bar.max_value = status.max_health
	health_bar.value = status.health
	under_bar.value = status.health
	
	CURRENT_PCACHE = 0
	SCACHE = 0
	dash_cooldown = 0.0
	p_cooldown_bar.value = p_cooldown_bar.max_value
	charge_bar.max_value = MAX_PCACHE
	p_cache_bar.max_value = MAX_PCACHE
	charge_bar.value = CURRENT_PCACHE
	p_cache_bar.value = CURRENT_PCACHE
	update_s_charge()

func random_start_position():
	var rand = randf_range(0,2*PI)
	var pos : Vector2 = Vector2(
		cos(rand),
		sin(rand)
	)
	pos.y *= 0.5
	pos *= 200
	global_position = pos

func on_afflict(c : Array):
	#TODO
	pass

var dead : bool = false
func on_damage(amt : int):
	if dead: return
	status._damage(amt)
	disp_ftxt(str("[color=#e34262]",amt),global_position + Vector2(0,25),FloatingText.a.POP)
	#health_bar.value = status.health
	tween_health(status.health)
	#print(status.health)
	if status.health == 1:
		SystemUI.push_lateral({
		"speaker":"nme",
		"message":"Low Health!",
		"type":LateralNotification.nt.DANGER,
		"duration":8.0
		})
	
	if status.health == 0:
		dead = true
		SystemUI.sync_lateral({
		"speaker":"nme",
		"message":str("[color=e34262]",App.player_name,"[/color] has fallen!"),
		"type":LateralNotification.nt.DANGER,
		"duration":4.0
		})
		App.can_click = false
		await create_tween().tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK).finished
		App.purge_attacks.emit()
		SystemAudio.stop_music(1.0)
		remove_from_group("player")
		#remove puppets from other machines (auto)
		#check if there are 0 puppets on host
		#If so reload boss
		var death_back_col = Color.BLACK
		if Plyrm.connected: death_back_col.a = 0.5
		SystemAudio.play(SoundLib.get_file_sfx(SoundLib.sound_files.NOTIFICATION_B))
		await SystemUI.set_title(true,2,str("[color=red]",fTxt.defeattitle),fTxt.defeatSubtitles.pick_random(),Color("#a89f94"))
		SystemUI.push_title(Vector2(0,-80))
		await SystemUI.set_background(true,death_back_col)
		#await App.time_delay(2.0)
		
		App.assert_game_state()

var htw : Tween
func tween_health(nv : float):
	if htw: htw.kill()
	htw = create_tween()
	htw.tween_property(health_bar,"value",nv,0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	htw.parallel().tween_property(under_bar,"value",nv,0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE).set_delay(0.1)

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
	await get_tree().create_timer(1.2).timeout
	knocked = false

func drag(to : Vector2, strr : float = 10):
	var drgdir = to - global_position
	velocity += drgdir.normalized() * strr

var rd_target : Array #[Node,Path]
func remote_drag():
	#Boss Drag
	var boss_drag_data
	var boss_drag_state = Plyrm.Playroom.getState("bDrag")
	if boss_drag_state: 
		boss_drag_data = JSON.parse_string(boss_drag_state)
		if boss_drag_data["is_drag"]:
			if !rd_target or rd_target[1] != boss_drag_data["to"]:
				rd_target = []
				rd_target.append(get_node_or_null(boss_drag_data["to"]))
				rd_target.append(boss_drag_data["to"])
			drag(rd_target[0].global_position,boss_drag_data["strr"])
		else: rd_target.clear()

func _process(_delta):
	#if SCACHE > 0.0 and decay:
		#SCACHE -= 0.001
		#update_s_charge()
	pass

func _physics_process(delta):
	#WACKY
	if Input.is_action_just_pressed("recognize_gesture"):
		var nw = system_weapon.new()
		nw.generate_random()
		App.weapon_inventory.append(nw)
	if App.can_input and !knocked and !dead:
		DIRECTION = isometrize(Input.get_vector("MLEFT", "MRIGHT", "MUP", "MDOWN").rotated(deg_to_rad(-45))).normalized()
		if invertControls:
			DIRECTION = isometrize(Input.get_vector("MUP", "MDOWN", "MLEFT", "MRIGHT").rotated(deg_to_rad(-45))).normalized()
	else: DIRECTION = Vector2.ZERO
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
			velocity += (DIRECTION * abs(velocity)) * DASH_STRENGTH
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
		cooldown.value = cooldown.max_value - dash_cooldown
		p_cooldown_bar.value = p_cooldown_bar.max_value - dash_cooldown
		dash_cooldown -= delta
	if dash_cooldown <= 0.0 and (tspin_vfx.modulate.a == 0.0 or bspin_vfx.modulate.a == 0.0):
		stw = create_tween()
		stw.tween_property(tspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
		stw.parallel().tween_property(bspin_vfx,"modulate:a",1.0,0.25).set_ease(Tween.EASE_IN_OUT)
	
	move_and_slide()
	sync_state()
	if Plyrm.PLAYER and !Plyrm.PLAYER.host: remote_drag()

func sync_state():
	var state = {
		"pos_x":global_position.x,
		"pos_y":global_position.y,
		"on_cooldown": !(dash_cooldown <= 0.0),
		"direction":var_to_str(DIRECTION),
		"health":var_to_str(Vector2(status.health,status.max_health)) if status else var_to_str(Vector2.ZERO),
		"dead":dead
	}
	
	if Plyrm.PLAYER: 
		#Plyrm.Playroom.setState(str("pState_",Plyrm.PLAYERData.id),JSON.stringify(state))
		Plyrm.PLAYER.state.setState("pState",JSON.stringify(state))

func charge(ca = CHARGE_AMOUNT):
	if CURRENT_PCACHE >= 0 and CURRENT_PCACHE < MAX_PCACHE:
		CURRENT_PCACHE += ca
		CURRENT_PCACHE = clamp(CURRENT_PCACHE,0,MAX_PCACHE)
		print(CURRENT_PCACHE)
		disp_ftxt(str("+"),global_position + Vector2(0,25),FloatingText.a.POP)
	else:
		disp_ftxt("MAX!",global_position + Vector2(0,25),FloatingText.a.POP)
		print(CURRENT_PCACHE," MAX!")
	charge_bar.value = CURRENT_PCACHE
	p_cache_bar.value = CURRENT_PCACHE

var scfxtw : Tween
func s_charge():
	if !decay: return
	#var minc = 0.1 * pow(2.718,-0.9 * (SCACHE - 2.0))
	#var maxc = 0.45 * pow(2.718,-0.9 * (SCACHE - 2.0))
	disp_ftxt(str("[font_size=10][shake]!!!"),global_position + Vector2(0,45),FloatingText.a.POP)
	#if s_charge_fx.material.get_shader_parameter("progress") in [1.0,0.0]:
		#scfxtw.tween_method(scfxpv,0.0,1.0,0.5).set_ease(Tween.EASE_IN_OUT)
	App.revolutions_made += 1
	if SCACHE >= 5.0:
		if scfxtw: scfxtw.kill()
		scfxtw = create_tween()
		scfxtw.tween_property(s_chrg_emphasis,"modulate:a",1.0,0.125).set_ease(Tween.EASE_IN_OUT)
		charge(1)
		return
	var val = 5.0 / 3.0#randf_range(minc,maxc)
	SCACHE += val
	#s_cache_lbl.text = str(snappedf(SCACHE,0.01),"[b]ghz")
	var wve = "[wave]" if SCACHE >= 5.0 else ""
	s_cache_lbl.text = str(wve,"%.2f" % SCACHE,"[b]ghz")
	#print(min,"/",max,"->",val)

@onready var s_chrg_emphasis = $UI/Stats/MarginContainer/VBoxContainer/sCache/emphasis
@onready var s_charge_fx = $UI/Stats/MarginContainer/VBoxContainer/sCache/charge_fx
func scfxpv(nv : float): #set charge fx progress value
	s_charge_fx.material.set_shader_parameter("progress",nv)

func update_s_charge():
	#s_cache_lbl.text = str(snappedf(SCACHE,0.01),"[b]ghz")
	s_cache_lbl.text = str("%.2f" % SCACHE,"[b]ghz")

func s_discharge() -> float:
	if !decay: return 0.0
	if SCACHE == 0.0: 
		disp_ftxt("@",global_position + Vector2(0,25),FloatingText.a.POP)
		return 0.0
	if !discharge(): return 0.0
	create_tween().tween_property(s_chrg_emphasis,"modulate:a",0.0,0.125).set_ease(Tween.EASE_IN_OUT)
	
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
