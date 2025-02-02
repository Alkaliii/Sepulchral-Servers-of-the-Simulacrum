extends Node2D

@onready var hit_detector = $HitDetector

var loot_state : bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("loot")
	loot_state = [true,true,false].pick_random()
	#await get_tree().process_frame
	#if [true,true,false].pick_random():
		#queue_free()
		#return
	
	hit_detector.CLICKED.connect(on_click)

func on_click():
	hit_detector.disabled = true
	var nw = system_weapon.new()
	nw.generate_random()
	App.weapon_inventory.append(nw)
	
	SystemUI.push_lateral({
	"speaker":"(+)", #str("(",nw.get_stats_string(),")")
	"message":str("You found a ",system_weapon.i.keys()[nw.icon],"! (",nw.get_stats_string(),")"),
	"type":LateralNotification.nt.SPECIAL,
	"duration":4.0
	})
	
	remove()

func remove():
	await create_tween().tween_property(self,"modulate:a",0.0,0.25).set_ease(Tween.EASE_IN_OUT).finished
	queue_free()
