extends Timer

const Health := preload("health.gd")
const Hider := preload("hider.gd")

@export var damage := 30
@export var cause := "The Lodger"

@onready var hider: Hider = get_parent()
@onready var health: Health = hider.get_parent().get_node("Health")

func _ready() -> void:
	hider.changed.connect(_on_hider_changed)
	timeout.connect(_on_timeout)

func _on_hider_changed() -> void:
	if hider.state == Hider.State.HIDDEN:
		start()
	else:
		stop()

func _on_timeout() -> void:
	hider.push_out()
	health.hurt(damage, cause)
