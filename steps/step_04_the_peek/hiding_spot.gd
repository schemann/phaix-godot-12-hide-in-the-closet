extends Area3D

const OPEN_DEGREES := 10.0
const PEEK_TIME := 0.8
const PEEK_DEGREES := 20.0

var peeking := false

var can_peek: bool:
	get:
		return peek_eyes != null

@onready var view: Marker3D = $View
@onready var hinge_left: Node3D = get_node_or_null("../HingeLeft")
@onready var hinge_right: Node3D = get_node_or_null("../HingeRight")
@onready var peek_eyes: Node3D = get_node_or_null("Peek")

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

func peek() -> void:
	peeking = true
	hinge_left.rotation_degrees.y = PEEK_DEGREES
	hinge_right.rotation_degrees.y = -PEEK_DEGREES
	peek_eyes.visible = true
	var tween := create_tween()
	tween.tween_interval(PEEK_TIME)
	tween.tween_callback(_stop_peek)

func _stop_peek() -> void:
	peek_eyes.visible = false
	set_open(false)
	peeking = false
