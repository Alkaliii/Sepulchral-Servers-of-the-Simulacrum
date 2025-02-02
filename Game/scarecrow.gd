extends Node2D

@onready var hit_detector = $HitDetector

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("monster")
	hit_detector.DAMAGED.connect(on_damage)
	if Plyrm.connected: 
		Plyrm.PLAYER.state.setState("pMapSelect",false)
		Plyrm.PLAYER.state.setState("pREADY",false)
	await App.time_delay(3.0)
	App.tutorial_start.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

var rtw : Tween
func on_damage(amt,click):
	if rtw: rtw.kill()
	rtw = create_tween()
	rtw.tween_property(self,"rotation_degrees",[randf_range(-8,-4),randf_range(4,8)].pick_random(),0.062).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	rtw.tween_property(self,"rotation_degrees",0.0,0.125).set_ease(Tween.EASE_IN_OUT)
	disp_ftxt(str(amt,"!" if click == 1 else ""),global_position - Vector2(0,0),[FloatingText.a.POP,FloatingText.a.POP_SHOOT].pick_random())
	var cam = get_tree().get_first_node_in_group("camera")
	match click:
		0: 
			#flash_vfx()
			cam.add_trauma(0.4,0.9)
		1: 
			#hit_vfx()
			cam.add_trauma(1,0.8)
	App.tutorial_click.emit(click)

const FTXT = preload("res://Game/float_text.tscn")
func disp_ftxt(text : String, pos : Vector2, anim : FloatingText.a = FloatingText.a.FLOAT, outline : Dictionary = {}):
	var new = FTXT.instantiate()
	new.inital_position = pos
	new.anim = anim
	new.text = text
	if outline:
		new.outline_color = outline.color
		new.outline_size = outline.size
	get_parent().add_child(new)
