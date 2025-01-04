extends Node2D

#Manages The Arena
#eg. regenerating enviroment
#eg. placing down boss, player, and puppets

const PUPPET = preload("res://Game/puppet.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	Plyrm.PR_PLAYER_JOIN.connect(on_player_join)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_player_join(args):
	if Plyrm.PLAYERData and args[0].id == Plyrm.PLAYERData.id: return
	var inst = PUPPET.instantiate()
	add_child(inst)
	inst.position.x = randf_range(30,60)
	inst.my_id = args[0].id
