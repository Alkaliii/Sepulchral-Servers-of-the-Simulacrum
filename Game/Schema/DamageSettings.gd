extends Resource
class_name DamageRadiusSettings

@export var dmg : int = 1
#bosses only deal a lot of damage on BIG ONES
@export var radius : int = 180
@export var inflict : system_status.effects

@export_group("Timing")
@export var pre_warn : float = 0.5
#time given before area activates

@export var warn_activation_time : float = 1.0
@export var dmg_activation_time : float = 0.5
#time it takes for hazard to grow to full size

@export var hold_time : float = 0.1
#how long the attack remains, walking into it during this time will hurt you

@export var repeat : int = 1.0
#instead of removing, it will shrink and then it will activate again for n amount of times

@export_group("Field Properties")
@export var slow : bool = false
#Reduce player speed if they are inside it

@export var prevent_attack : bool = false
#Prevent player from attacking if they are inside it
