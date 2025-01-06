extends Area2D

@export var dmg : int = 1
#bosses only deal a lot of damage on BIG ONES
@export var radius : int = 360
@export var inflict : system_status.effects

@export_group("Timing")
@export var pre_warn : float = 0.5
#time given before area activates

@export var activation_time : float = 0.25
#time it takes for hazard to grow to full size

@export var hold_time : float = 0.25
#how long the attack remains, walking into it during this time will hurt you

@export var repeat : int = 1.0
#instead of removing, it will shrink and then it will activate again for n amount of times

@export_group("Field Properties")
@export var slow : bool = false
#Reduce player speed if they are inside it

@export var prevent_attack : bool = false
#Prevent player from attacking if they are inside it

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
