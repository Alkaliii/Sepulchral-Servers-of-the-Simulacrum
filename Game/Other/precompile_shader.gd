extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	await App.time_delay(0.5)
	await create_tween().tween_property(self,"modulate:a",0.0,0.25).finished
	hide()
	get_parent().remove_child(self)
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
