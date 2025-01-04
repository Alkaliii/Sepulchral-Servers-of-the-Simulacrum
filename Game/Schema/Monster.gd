extends Resource
class_name system_monster


@export var base_health : int = 50

#Behaviours
enum b {
	NONE,
	REST, #Rest, Stops in place and does nothing, optional chance to heal
	STUN, #Stun, Stops in place and does nothing
	CHASE, #Chase, Picks a player or puppet to follow
	POUNCE, #Pounce, Picks a player and rushes at them
	RABID, #Rabid, Moves around the arena randomly and rapidly
	ROAM, #Roam, Moves around the arena randomly
	RUN, #Run, Moves away from all players and puppets
	PUSH, #Push, Pushes players away for x seconds
	PULL, #Pull, Pulls players inward for x seconds
	BIGONE, #Big One, Moves somewhere and then covers a large part of the arena in danager zones
}

#Conditions
enum c {
	LIGHT_ONLY,
	HEAVY_ONLY,
	INVULNERABLE,
	INFLICT,
	CLUTCH,
}
#Light ONLY, heavy damage will be rejected
#Heavy ONLY, light damage will be rejected
#Invulnerable, only status damage works
#Inflict, will inflict status set on attack
#Clutch, will deal more damage
