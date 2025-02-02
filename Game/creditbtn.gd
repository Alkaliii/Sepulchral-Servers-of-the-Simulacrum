extends Button

var content : String
const SOKO = preload("res://Assets/Materials/Soko.tres")
# Called when the node enters the scene tree for the first time.
func _ready():
	content = text
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)

var btntw : Tween
func _on_hover():
	material = SOKO
	if btntw: btntw.kill()
	btntw = create_tween()
	pivot_offset = size / 2.0
	await App.process_frame()
	btntw.tween_property(self,"scale",Vector2(1.1,1.1),0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)

func _on_exit():
	material = null
	if btntw: btntw.kill()
	btntw = create_tween()
	pivot_offset = size / 2.0
	await App.process_frame()
	btntw.tween_property(self,"scale",Vector2.ONE,0.125).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
