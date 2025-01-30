@tool
extends Area2D

@export var settings : DamageRadiusSettings
@export var test : bool = false : 
	set(v):
		test = v
		match test:
			true: warn()
			false: reset_dr()
@export var test_outline : bool = false :
	set(v):
		test_outline = false
		draw_outline()
@export var test_rad : bool = false :
	set(v):
		test_rad = false
		set_radius()

var rad : int = 180

signal finished

# Called when the node enters the scene tree for the first time.
func _ready():
	set_radius()
	if Engine.is_editor_hint(): return
	body_entered.connect(damage_body)
	App.purge_attacks.connect(fast_destroy)
	#while true:
		#reset_dr()
		#await warn()
		#await get_tree().create_timer(0.5).timeout

func damage_body(body : Node2D):
	var dmg_amt = 1
	var inflict = system_status.effects.NONE
	#print(body.name)
	if settings: 
		dmg_amt = settings.dmg
		inflict = settings.inflict
		#print("set inflict ", settings.inflict)
	if body is system_controller:
		body.on_damage(dmg_amt)
		if inflict != system_status.effects.NONE:
			#print("start inflict")
			body.on_afflict(inflict,[3.0,4.0,5.0].pick_random())
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
var move = false
func _process(delta):
	if move: process_dr_movement(delta)

var orb_rad
var orb_accum
var pp_dir
var wiggle_dir
var wiggle_dirB
var wiggle_accum := 0.0
func process_dr_movement(delta):
	if !settings: return
	match settings.movement_type:
		DamageRadiusSettings.mt.ORBIT:
			if !orb_rad: orb_rad = settings.movement_radius#(settings.movement_origin - global_position).length()
			if !orb_accum: 
				var ip = (global_position - settings.movement_origin)
				ip.y *= 2.0
				orb_accum = ip.normalized().angle()#
				if settings.movement_offset_additional != 0.0:
					orb_accum -= ((1.0/settings.movement_offset_additional) * 2.0*PI)
				#orb_accum = settings.movement_offset
			global_position = lerp(global_position,settings.movement_origin + Vector2(
				cos(orb_accum),
				sin(orb_accum) / 2.0
			) * orb_rad,1.0)
			#global_position = settings.movement_origin + Vector2(
				#cos(orb_accum),
				#sin(orb_accum) / 2.0
			#) * orb_rad
			orb_accum += delta * settings.movement_speed
		DamageRadiusSettings.mt.PUSH:
			if !pp_dir: pp_dir = (global_position - settings.movement_origin).normalized()
			global_position = lerp(global_position,global_position + (pp_dir * (settings.movement_speed * delta)),0.5)
		DamageRadiusSettings.mt.PULL:
			if !pp_dir: pp_dir = (global_position - settings.movement_origin).normalized()
			global_position = lerp(global_position,global_position - (pp_dir * (settings.movement_speed * delta)),0.5)
		DamageRadiusSettings.mt.ORTHO_WIGGLE:
			if wiggle_dir == null: 
				wiggle_dir = (global_position - settings.movement_origin).rotated(deg_to_rad(90)).normalized()
				wiggle_dir.y /= 2.0
				wiggle_dir *= (settings.radius/5.0)
				#print(wiggle_dir)
			global_position = lerp(global_position,global_position + (wiggle_dir * cos(wiggle_accum)),0.5)
			wiggle_accum += delta * settings.movement_speed
		DamageRadiusSettings.mt.LATERAL_WIGGLE:
			if wiggle_dir == null: 
				wiggle_dir = (global_position - settings.movement_origin).normalized()
				wiggle_dir.y /= 2.0
				wiggle_dir *= (settings.radius/5.0)
				#print(wiggle_dir)
			global_position = lerp(global_position,global_position + (wiggle_dir * cos(wiggle_accum)),0.5)
			wiggle_accum += delta * settings.movement_speed
		DamageRadiusSettings.mt.DIAXIS_WIGGLE:
			if wiggle_dir == null: 
				wiggle_dir = (global_position - settings.movement_origin).rotated(deg_to_rad(90)).normalized()
				wiggle_dir.y /= 2.0
				wiggle_dir *= (settings.radius/5.0)
				#print(wiggle_dir)
			if wiggle_dirB == null: 
				wiggle_dirB = (global_position - settings.movement_origin).normalized()
				wiggle_dirB.y /= 2.0
				wiggle_dirB *= (settings.radius/5.0)
				#print(wiggle_dirB)
			global_position = lerp(global_position,global_position + (wiggle_dir * sin(wiggle_accum)) + (wiggle_dirB * cos(wiggle_accum)),0.5)
			wiggle_accum += delta * settings.movement_speed

func reset_dr():
	sosv(0.0)
	swsp(0.0)
	sdsp(0.0)
	dmg_shape.call_deferred("set_disabled",true)

func warn():
	var wtw : Tween = create_tween()
	var activation_time = 1.0
	if settings: activation_time = settings.warn_activation_time
	sfx(randf_range(0.2,0.5))
	move = true
	wtw.tween_method(sosv,0.0,1.0,activation_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	wtw.parallel().tween_method(swsp,0.0,1.0,activation_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await wtw.finished
	
	var pre_warn_time = 0.5
	if settings: pre_warn_time = settings.pre_warn
	await get_tree().create_timer(pre_warn_time).timeout
	await damage()

func sfx(vol = 1.0):
	var sp = DamageRadiusSettings.sfx.ACID
	if settings: sp = settings.spawn_sound
	
	if sp == DamageRadiusSettings.sfx.NONE or [true,false].pick_random(): return
	
	var ssfx : Array = []
	match sp:
		DamageRadiusSettings.sfx.ACID:
			ssfx.append(SoundLib.sound_files.ATTACK_ACID_A)
			ssfx.append(SoundLib.sound_files.ATTACK_ACID_B)
		DamageRadiusSettings.sfx.ICE:
			ssfx.append(SoundLib.sound_files.ATTACK_ICE_A)
			ssfx.append(SoundLib.sound_files.ATTACK_ICE_B)
		DamageRadiusSettings.sfx.LIGHTNING:
			ssfx.append(SoundLib.sound_files.ATTACK_LIGHTNING_A)
			ssfx.append(SoundLib.sound_files.ATTACK_LIGHTNING_B)
		DamageRadiusSettings.sfx.FIRE:
			ssfx.append(SoundLib.sound_files.ATTACK_FIRE_A)
			ssfx.append(SoundLib.sound_files.ATTACK_FIRE_B)
	SystemAudio.play(SoundLib.get_file_sfx(ssfx.pick_random()),vol)

func damage():
	var dtw : Tween = create_tween()
	var dtwb : Tween = create_tween()
	var activation_time = 0.5
	if settings: activation_time = settings.dmg_activation_time
	dtw.tween_method(sdsp,0.0,1.0,activation_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	dtwb.tween_property(outline_poly,"scale",Vector2(1.05,1.05),0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_delay(activation_time * 0.3)
	dtwb.tween_property(outline_poly,"scale",Vector2.ONE,0.125).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await dtwb.finished
	#sfx()
	dmg_shape.call_deferred("set_disabled",false)
	await dtw.finished
	
	var hold_time = 0.1
	if settings: hold_time = settings.hold_time
	await get_tree().create_timer(hold_time).timeout
	dmg_shape.call_deferred("set_disabled",true)
	await clear()

func clear():
	var ctw : Tween = create_tween()
	ctw.tween_method(sdsp,1.0,0.0,1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	ctw.parallel().tween_method(swsp,1.0,0.0,1.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	ctw.parallel().tween_method(sosv,1.0,0.0,1.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await ctw.finished
	on_fin()

var repetitions := 0
func on_fin():
	reset_dr()
	if repetitions != (settings.repeat - 1): 
		repetitions += 1
		warn()
	else:
		destroy()

func destroy():
	if Engine.is_editor_hint(): return
	finished.emit(self)
	if get_parent():
		get_parent().remove_child(self)
	queue_free()

func fast_destroy():
	if Engine.is_editor_hint(): return
	print("fast destory")
	if get_parent():
		get_parent().remove_child(self)
	queue_free()

func swsp(nv : float): #set warning shader progress
	warning.material.set_shader_parameter("progress",nv)

func sdsp(nv : float): #set damage shader progress
	dmg.material.set_shader_parameter("progress",nv)

func sosv(nv : float): #set outline shader value
	outline_poly.material.set_shader_parameter("value",nv)

@onready var warning = $Warning
@onready var dmg = $Damage
@onready var dmg_shape = $dmgShape
@onready var detect_shape = $PlayerDetector/detectShape
func set_radius():
	if settings: rad = settings.radius
	else: rad = 180
	var txt = ImageTexture.new()
	var img = Image.new().create_empty(rad * 2,rad * 2,true,Image.FORMAT_L8)
	img.fill(Color("#ffffff"))
	txt.set_image(img)
	warning.texture = txt
	dmg.texture = txt
	#dmg_shape.shape.radius = rad
	#detect_shape.shape.radius = rad
	draw_outline()

@onready var outline_poly = $Outline
func draw_outline():
	var r = rad / 2.0
	var points : int = 30
	var poly : PackedVector2Array = []
	for i in points:
		var new = Vector2(1,-1).rotated(deg_to_rad(360) * (i+1)/float(points)) * r
		poly.append(isometrize(new))
	outline_poly.points = poly
	dmg_shape.polygon = poly
	detect_shape.polygon = poly

func isometrize(v : Vector2) -> Vector2:
	var new : Vector2 = Vector2()
	new.x = v.x - v.y
	new.y = (v.x + v.y) / 2.0
	return new


func _on_player_detector_body_entered(body):
	if body is system_controller:
		if settings.prevent_attack: 
			print("Attack Nullified")
			body.canDealDamage = false
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"Attack Nullified",
			"type":LateralNotification.nt.WARN,
			"duration":2.0
			})
		if settings.slow:
			print("Speed Reduced")
			body.SPEED_MULTIPLIER = 0.5
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"Speed Reduced",
			"type":LateralNotification.nt.WARN,
			"duration":2.0
			})
		if settings.invert_controls:
			print("Controls Inverted")
			body.invertControls = true
			SystemUI.push_lateral({
			"speaker":"nme",
			"message":"Controls Twisted",
			"type":LateralNotification.nt.WARN,
			"duration":2.0
			})


func _on_player_detector_body_exited(body):
	if body is system_controller:
		if settings.prevent_attack: 
			print("Attack Restored")
			body.canDealDamage = true
		if settings.slow:
			print("Speed Restored")
			body.SPEED_MULTIPLIER = 1.0
		if settings.invert_controls:
			print("Controls Restored")
			body.invertControls = false
