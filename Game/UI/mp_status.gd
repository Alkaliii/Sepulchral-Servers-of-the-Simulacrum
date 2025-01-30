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
	var ratio = hv.x/hv.y
	if ratio == 1.0: stw.tween_property(health,"tint_progress",Color("#b4ba46"),0.125).set_ease(Tween.EASE_IN_OUT)
	elif ratio > 0.5: stw.tween_property(health,"tint_progress",Color("#f2b63d"),0.125).set_ease(Tween.EASE_IN_OUT)
	else: stw.tween_property(health,"tint_progress",Color("#e34262"),0.125).set_ease(Tween.EASE_IN_OUT)

func set_plyr_name(namee : String):
	plyr_name.text = str("[wave]",namee)
