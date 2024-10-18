extends CharacterBody2D


#const SPEED = 230.0
const JUMP_VELOCITY = -500.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var motion = Vector2()
var acc = 10
var speed = 250
var air_jumps_used = 0
var aerial_timer = 0
var start_aerial_timer = false
var last_wall_normal = Vector2.ZERO
var wall_falling = false
const UP = Vector2(0, -1)



func _physics_process(delta: float) -> void:
	# Timer to handle coyote time
	if not is_on_floor() and not is_on_wall():
		aerial_timer += 1
	else:
		aerial_timer = 0
	
	# Add the gravity
	if not is_on_floor() and not is_on_wall():
		motion.y += get_gravity().y * 1.35 * delta
		velocity.y = motion.y
	if is_on_floor():
		motion.y = 0
	
	# Wall climb movement
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
	
	# Get info for wall-jumping logic
	if is_on_wall():
		last_wall_normal = get_wall_normal()
		wall_falling = true
	
	# Failsafe to avoid unintentional wall-jumping
	if aerial_timer >= 8:
		wall_falling = false
	
	# If our last known vector for a wall was a left wall, and we're falling
	#from that wall:
	if(last_wall_normal.x > 0) and wall_falling:
		# Jumping to the right
		if Input.is_action_just_pressed("jump") and aerial_timer < 8:
			motion.y = JUMP_VELOCITY
			motion.x = -JUMP_VELOCITY
			velocity = motion
	# If last known vector for wall was for right wall, and we're falling
	#from that wall:
	elif(last_wall_normal.x < 0) and wall_falling:
		# Jumping to the left
		if Input.is_action_just_pressed("jump") and aerial_timer < 8:
			motion.y = JUMP_VELOCITY
			motion.x = JUMP_VELOCITY
			velocity = motion
	
	# Handle cool experimental puff jump
	if Input.is_action_just_pressed("grapple"):
		motion.x = -((get_local_mouse_position().x)) * speed * delta
		motion.y = -((get_local_mouse_position().y)) * speed * delta
		velocity = motion
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and aerial_timer < 8:
		motion.y = JUMP_VELOCITY
		velocity.y = motion.y
	
	# Handle air jump.
	if Input.is_action_just_pressed("jump") and not is_on_floor() and not is_on_wall():
		if aerial_timer >= 8:
			if air_jumps_used < 1:
				motion.y = JUMP_VELOCITY
				velocity.y = motion.y
				air_jumps_used += 1
	
	# Get our input direction for animations
	var direction := Input.get_axis("move_left", "move_right")

	#Flip the sprite depending on direction
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
	
	# Handle left/right floor movement acceleration & reset jumps
	if is_on_floor():
		air_jumps_used = 0
		wall_falling = false
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
	
	# If right momentum but pressing left
	if velocity.x > 0 and Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"):
		motion.x = lerpf(motion.x, 0.0, 0.30)
	# If left momentum but pressing right
	elif velocity.x < 0 and Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"):
		motion.x = lerpf(motion.x, 0.0, 0.30)
	
	if Input.is_action_pressed("move_left") and Input.is_action_pressed("move_right"):
		if velocity.x > 0.0:
			motion.x = max(lerpf(motion.x, 0.0, 0.30), 0)	
		if velocity.x < 0.0:
			motion.x = min(lerpf(motion.x, 0.0, 0.30), 0)
	
	
	velocity.x = motion.x
	
	
	move_and_slide()
