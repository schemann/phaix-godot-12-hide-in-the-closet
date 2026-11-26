extends Area3D
## A spot on the floor that hurts whoever stands in it: one hit when a body steps in,
## then one more every interval for as long as it stays.

const Health := preload("health.gd")

@export var cause := "Live Wire" ## What the hit is called.
@export var damage := 25 ## Points per hit.
@export var interval := 0.5 ## Seconds between two hits while a body stays in.

var inside: Array[Health] = [] ## The health of every body that stands in it right now.

@onready var timer: Timer = $Timer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	timer.wait_time = interval
	timer.timeout.connect(_hit_everyone)

## Only a body with a Health child can be hurt. The hazard never asks what the body is.
func _on_body_entered(body: Node3D) -> void:
	var health := body.get_node_or_null("Health") as Health
	if health == null:
		return
	inside.append(health)
	health.hurt(damage, cause)
	if timer.is_stopped():
		timer.start()

func _on_body_exited(body: Node3D) -> void:
	inside.erase(body.get_node_or_null("Health"))
	if inside.is_empty():
		timer.stop()

func _hit_everyone() -> void:
	for health in inside:
		health.hurt(damage, cause)
