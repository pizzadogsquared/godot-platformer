extends Node2D
@onready var line: Line2D = $Line2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var killzone: Area2D = $Killzone

var d := 0.0
var radius := 50.0
var speed := 2.0

func _ready() -> void:
	line.add_point(Vector2(0,0))
	line.add_point(position)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	d += delta
	line.set_point_position(1, sprite.position)
	sprite.position = Vector2(
		sin(d * speed) * radius,
		cos(d * speed) * radius
	)
	killzone.position = sprite.position
