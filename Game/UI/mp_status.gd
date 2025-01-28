extends HBoxContainer

@onready var health = $health
@onready var plyr_name = $name

var cur : Vector2 = Vector2.ZERO

var stw : Tween
func set_status(hv : Vector2):
	if stw: stw.kill()
	stw = create_tween()
	
	cur = hv
	health.max_value = hv.y
	stw.tween_property(health,"value",hv.x,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func set_plyr_name(namee : String):
	plyr_name.text = str("[wave]",namee)
