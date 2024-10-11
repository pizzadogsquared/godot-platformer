extends CharacterBody2D


#const SPEED = 230.0
const JUMP_VELOCITY = -500.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var motion = Vector2()
var acc = 10
var speed = 250
const UP = Vector2(0, -1)
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 1.45 * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	# Get the input direction: -1 left, 0 not moving, 1 right.
	var direction := Input.get_axis("move_left", "move_right")
	
	#Flip the sprite
	if direction > 0:
		animated_sprite.flip_h = false
	
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
	if Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		motion.x = min(motion.x + acc, speed)
	elif Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		motion.x = max(motion.x - acc, -speed)
	if not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		motion.x = lerpf(motion.x, 0, 0.45)
	
	# If moving right but pressing left+
	if velocity.x > 0 and Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		motion.x = lerpf(motion.x, 0.0, 0.30)
		
	elif velocity.x < 0 and Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		motion.x = lerpf(motion.x, 0.0, 0.30)
		
	if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
		if velocity.x > 0.0:
			motion.x = max(lerpf(motion.x, 0.0, 0.30), 0)	
		if velocity.x < 0.0:
			motion.x = min(lerpf(motion.x, 0.0, 0.30), 0)
	
	velocity.x = motion.x
	move_and_slide()
