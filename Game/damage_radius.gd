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
	#while true:
		#reset_dr()
		#await warn()
		#await get_tree().create_timer(0.5).timeout

func damage_body(body : Node2D):
	var dmg_amt = 1
	#print(body.name)
	if settings: dmg_amt = settings.dmg
	if body is system_controller:
		body.on_damage(dmg_amt)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func reset_dr():
	sosv(0.0)
	swsp(0.0)
	sdsp(0.0)
	dmg_shape.call_deferred("set_disabled",true)

func warn():
	var wtw : Tween = create_tween()
	var activation_time = 1.0
	if settings: activation_time = settings.warn_activation_time
	wtw.tween_method(sosv,0.0,1.0,activation_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	wtw.parallel().tween_method(swsp,0.0,1.0,activation_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await wtw.finished
	
	var pre_warn_time = 0.5
	if settings: pre_warn_time = settings.pre_warn
	await get_tree().create_timer(pre_warn_time).timeout
	await damage()

func damage():
	var dtw : Tween = create_tween()
	var dtwb : Tween = create_tween()
	var activation_time = 0.5
	if settings: activation_time = settings.dmg_activation_time
	dtw.tween_method(sdsp,0.0,1.0,activation_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	dtwb.tween_property(outline_poly,"scale",Vector2(1.05,1.05),0.125).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO).set_delay(activation_time * 0.3)
	dtwb.tween_property(outline_poly,"scale",Vector2.ONE,0.125).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	await dtwb.finished
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
