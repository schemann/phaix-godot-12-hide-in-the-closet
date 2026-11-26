extends Node
## The health of the node it is a child of. It only counts: whatever hurts calls hurt(),
## and whoever cares listens to the signals. It never asks what it belongs to.

signal changed(health: int) ## After every hit and after reset().
signal died(cause: String) ## The hit that took the last point. cause names what dealt it.

@export var max_health := 100
@export var grace := 1.0 ## Seconds after protect() in which no hit counts.
var safe_left := 0.0 ## Seconds of grace left. protect() fills it, every physics frame takes the frame time off it.

var health := 0
var dead := false ## From the last hit until reset(): a dead body takes no more hits.

func _ready() -> void:
	reset()

func _physics_process(delta: float) -> void:
	safe_left = maxf(safe_left - delta, 0.0)

## Takes amount off, never below 0. The hit that reaches 0 sends died() once, with its cause.
## During the grace after protect() no hit counts.
func hurt(amount: int, cause: String) -> void:
	if dead or amount <= 0 or safe_left > 0.0:
		return
	health = maxi(health - amount, 0)
	changed.emit(health)
	if health == 0:
		dead = true
		died.emit(cause)

## Full health again: a new run.
func reset() -> void:
	health = max_health
	dead = false
	changed.emit(health)

## For the next grace seconds no hit counts: after a revive, the hazards notice the move one physics step late,
## and the player needs a moment to see where they are.
func protect() -> void:
	safe_left = grace
