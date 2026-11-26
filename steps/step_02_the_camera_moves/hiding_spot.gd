extends Area3D

const OPEN_DEGREES := 10.0

@onready var view: Marker3D = $View
@onready var hinge_left: Node3D = get_node_or_null("../HingeLeft")
@onready var hinge_right: Node3D = get_node_or_null("../HingeRight")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	var hider := body.get_node_or_null("Hider")
	if hider != null:
		hider.came_near(self)

func _on_body_exited(body: Node3D) -> void:
	var hider := body.get_node_or_null("Hider")
	if hider != null:
		hider.went_away(self)

func set_open(open: bool) -> void:
	if hinge_left == null:
		return
	var angle := OPEN_DEGREES if open else 0.0
	hinge_left.rotation_degrees.y = angle
	hinge_right.rotation_degrees.y = -angle

func turn_doors(tween: Tween, open: bool, time: float) -> void:
	if hinge_left == null:
		return
	var angle := OPEN_DEGREES if open else 0.0
	tween.tween_property(hinge_left, "rotation_degrees:y", angle, time)
	tween.tween_property(hinge_right, "rotation_degrees:y", -angle, time)
