extends Node2D
class_name FloatingText

enum a {
	POP, #moves up a bit then stops trans back
	FLOAT, #moves up endlessly
	POP_SHOOT,
	SHOOT, #moves endlessly very quickly in a random direction
}

var anim : a = a.FLOAT
var inital_position : Vector2 = Vector2.ZERO #global
var text : String = ""
var outline_color : Color = Color("#2b2b26") 
var outline_size : int = 15

@onready var txt = $TEXT
@onready var on_screen = $ON_SCREEN


# Called when the node enters the scene tree for the first time.
func _ready():
	on_screen.screen_exited.connect(off_screen)
	
	if text.contains("[outline"):
		txt.text = text
	else:
		txt.text = str("[center][wave][outline_color=",outline_color.to_html(),"][outline_size=",outline_size,"]",text)
	on_screen.rect = txt.get_rect()
	global_position = inital_position + (Vector2(randf_range(-1,1),randf_range(-0.25,0.25)) * 15)
	play_anim()

func off_screen():
	await get_tree().create_timer(0.125).timeout
	if !on_screen.is_on_screen():
		rmv()

func rmv():
	await create_tween().tween_property(self,"modulate:a",0.0,0.25).finished
	get_parent().remove_child(self)
	queue_free()

func play_anim():
	var tw = create_tween()
	match anim:
		a.POP:
			tw.tween_property(self,"global_position:y",global_position.y - 50,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await get_tree().create_timer(1.0).timeout
			rmv()
		a.FLOAT:
			tw.tween_property(self,"global_position:y",global_position.y + 50,0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(self,"global_position:y",global_position.y - 5000,10.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		a.POP_SHOOT:
			tw.tween_property(self,"global_position",global_position + (Vector2(randf_range(-1,1),randf_range(-1,1)) * 50),0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			await get_tree().create_timer(1.0).timeout
			rmv()
		a.SHOOT:
			var dir : Vector2 = Vector2(randf_range(-1,1),randf_range(-1,1))
			tw.tween_property(self,"global_position",global_position + (dir * 50),0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			tw.tween_property(self,"global_position",global_position + (dir * 5000),5.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
