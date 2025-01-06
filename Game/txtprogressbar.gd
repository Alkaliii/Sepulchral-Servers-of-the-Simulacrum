@tool
extends PanelContainer

@onready var fill = $fill

@export var invert : bool = false
@export var min_value := 0.0
@export var max_value := 100.0
	#set(v):
		#max_value = v
		#ssv(value / max_value)
		#tween_value()
@export var value := 0.0 :
	set(v):
		value = clamp(v,min_value,max_value)
		tween_value()
@export var p_transition : Tween.TransitionType = Tween.TRANS_BACK
@export var p_ease : Tween.EaseType = Tween.EASE_OUT
@export var p_transition_time : float = 0.15

var old_value := 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#if value != old_value:
		#tween_value()

var tw : Tween
func tween_value():
	#print("hi")
	if tw: tw.kill()
	tw = create_tween()
	tw.tween_method(ssv,old_value / max_value,value / max_value,p_transition_time).set_ease(p_ease).set_trans(p_transition)
	await tw.finished
	old_value = value

func ssv(nv : float):
	if invert:
		fill.material.set_shader_parameter("value",1.0 - nv)
	else: fill.material.set_shader_parameter("value",nv)
