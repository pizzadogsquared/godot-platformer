extends CharacterBody2D


#const SPEED = 230
const JUMP_VELOCITY = -500.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var motion = Vector2()
var acc = 10
var speed = 250
var air_jumps_used = 0
var wall_timer = 0
var jump_timer = 0
var start_jump_timing = false
var start_wall_timing = false
const UP = Vector2(0, -1)



func _physics_process(delta: float) -> void:
	# Timer to handle forgiving controls
	print(jump_timer)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 1.45 * delta
	if is_on_wall():
		if Input.is_action_pressed("move_up") and not Input.is_action_pressed("crouch"):
			motion.y = max(motion.y - acc, -speed)
			velocity.y = motion.y
		if Input.is_action_pressed("crouch") and not Input.is_action_pressed("move_up"):
			motion.y = min(motion.y + acc, speed)
			velocity.y = motion.y
		if (not Input.is_action_pressed("crouch") and not Input.is_action_pressed("move_up")) or (Input.is_action_pressed("move_up") and Input.is_action_pressed("crouch")):
			motion.y = lerpf(motion.y, 0, 0.35)
			velocity.y = motion.y
			
	if is_on_wall():
		# Jumping to the right
		if(get_wall_normal().x > 0):
			if Input.is_action_pressed("jump"):
				motion.y = JUMP_VELOCITY
				motion.x = -JUMP_VELOCITY
				velocity = motion
		elif(get_wall_normal().x < 0):
			if Input.is_action_pressed("jump"):
				motion.y = JUMP_VELOCITY
				motion.x = JUMP_VELOCITY
				velocity = motion
	
	# Handle cool experimental puff jump
	if Input.is_action_pressed("grapple"):
		motion.x = -((get_local_mouse_position().x)) * speed * delta
		motion.y = -((get_local_mouse_position().y)) * speed * delta
		print(motion)
		velocity = motion
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		motion.y = JUMP_VELOCITY
		velocity.y = motion.y
		start_jump_timing = true
	
	if start_jump_timing:
		jump_timer += 1
	
	# Handle air jump.
	if Input.is_action_just_pressed("jump") and not is_on_floor() and not is_on_wall():
		if jump_timer > 5:
			if air_jumps_used < 1:
				motion.y = JUMP_VELOCITY
				velocity.y = motion.y
				air_jumps_used += 1
	
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
	
	# Handle coyote timer for jumping
	if is_on_floor() and not Input.is_action_pressed("jump"):
		start_jump_timing = false
		jump_timer = 0
	
	# Handle left/right floor movement acceleration & reset jumps
	if is_on_floor():
		air_jumps_used = 0
		if Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			motion.x = min(motion.x + acc, speed)
		elif Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
			motion.x = max(motion.x - acc, -speed)
		if not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			motion.x = lerpf(motion.x, 0, 0.45)
	# Handle aerial left/right movement acceleration
	else:
		if Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			motion.x = min(motion.x + acc, speed)
		elif Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
			motion.x = max(motion.x - acc, -speed)
		if not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
			motion.x = lerpf(motion.x, 0, 0.05)
	
	# If moving right but pressing left
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
