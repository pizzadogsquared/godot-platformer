extends RigidBody2D

const RUN_ACCEL = 1000.0
const RUN_DEACCEL = 9000.0
const RUN_MAX_VELOCITY = 155.0
const AIR_ACCEL = 850.0
const AIR_DEACCEL = 350.0
const JUMP_VELOCITY = 400.0
const STOP_JUMP_FORCE = 750.0
const CLIMB_UP = -100.0
const CLIMB_DOWN = 100.0
const CLIMB_UP_MAX = -100.0
const CLIMB_DOWN_MAX = 100.0
const HARD_UP_MAX = 1000.0
const HARD_DOWN_MAX = 1000.0
const MAX_FLOOR_AIRBORN_TIME = 0.15
const MAX_WALL_AIRBORN_TIME = 0.15
const MAX_JUMPS = 2

var anim := ""

var jumps_used := 0
var siding_left := false
var jumping := false
var stopping_jump := false

var floor_h_velocity: float = 0.0
var floor_v_velocity: float = 0.0
var airborn_time: float = 1e20


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D




func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var velocity := state.get_linear_velocity()
	var step := state.get_step()
	
	var new_anim := anim
	var new_siding_left := siding_left
	
	# Get player inputs
	var jump_hold := Input.is_action_pressed(&"jump")
	var jump := Input.is_action_just_pressed(&"jump")
	var move_up := Input.is_action_pressed(&"move_up")
	var crouch := Input.is_action_pressed(&"crouch")
	var move_left := Input.is_action_pressed(&"move_left")
	var move_right := Input.is_action_pressed(&"move_right")
	
	# Deapply previous floor velocity
	velocity.x -= floor_h_velocity
	floor_h_velocity = 0.0
	floor_v_velocity = 0.0
	
	# Find the floor (a contact with upwards facing collision normal).
	var found_floor := false
	var floor_index := -1
	
	for contact_index in state.get_contact_count():
		var collision_normal = state.get_contact_local_normal(contact_index)
		
		if collision_normal.dot(Vector2(0, -1)) > 0.6:
			found_floor = true
			floor_index = contact_index
			

	
	var found_wall := false
	var wall_index := -1
	var climb_momentum := velocity.y
	
	for contact_index in state.get_contact_count():
		var collision_normal = state.get_contact_local_normal(contact_index)
		
		# Check left wall collision
		if collision_normal.dot(Vector2(-1, 0)) > 0.6:
			if move_right:
				found_wall = true
				wall_index = contact_index
				
		# Check right wall collision
		if collision_normal.dot(Vector2(1, 0)) > 0.6:
			if move_left:
				found_wall = true
				wall_index = contact_index
				
	if found_floor:
		airborn_time = 0.0
	else:
		# Add to the time spent in the air
		airborn_time += step
		
	var on_floor := airborn_time < MAX_FLOOR_AIRBORN_TIME
				
	# Do general jump logic
	if jumping:
		# Falling logic
		if velocity.y > 0:
			# Turn off jumping flag because velocity goes down
			jumping = false

		# If the player releases jump input
		elif not jump_hold and not jump:
			stopping_jump = true
		
		# If the player releases jump input, accelerate falling
		if stopping_jump:
			velocity.y += STOP_JUMP_FORCE * step
	
	if jumps_used + 1 < MAX_JUMPS and jump and jump_hold:
		# Check if player wants to jump
		velocity.y = -JUMP_VELOCITY
		jumping = true
		stopping_jump = false
		jumps_used += 1
		if jumps_used >= 2:
			velocity.x = 0
			
		
	if found_wall:
		# Climbing down logic.
		var yv := velocity.y
		# a positive y value indicates downward movement
		if crouch and not move_up:
			if yv >= HARD_DOWN_MAX:
				climb_momentum = HARD_DOWN_MAX
				velocity.y = climb_momentum
			if velocity.y <= CLIMB_DOWN_MAX:
				velocity.y = climb_momentum + CLIMB_DOWN
		# a negative y value indicates upward movement
		elif move_up and not crouch:
			if velocity.y >= CLIMB_UP_MAX:
				velocity.y += CLIMB_UP
		# if not moving upward or downward
		else:
			velocity.y = 0
			
	# Do checks for character on floor for gen movement
	if on_floor and not found_wall:
		jumps_used = 0
		# If character is just moving left
		if move_left and not move_right:
			if velocity.x > -RUN_MAX_VELOCITY:
				velocity.x -= RUN_ACCEL * step
		# If character is just moving right
		elif move_right and not move_left:
			if velocity.x < RUN_MAX_VELOCITY:
				velocity.x += RUN_ACCEL * step
		# If previous checks failed (no L/R input or player
		# velocity is too small)
		else:
			# Get absolute value of current velocity
			var xv := absf(velocity.x)
			# Decrease that velocity until xv is 0.
			xv -= RUN_DEACCEL * step
			if xv < 0:
				xv = 0
			# Set velocity to direction times slowing velocity
			velocity.x = signf(velocity.x) * xv
			
		if velocity.x < 0 and move_left:
			new_siding_left = true
		elif velocity.x > 0 and move_right:
			new_siding_left = false
		if jumping:
			new_anim = "jump"
		elif absf(velocity.x) < 0.1:
			new_anim = "idle"
		else:
			new_anim = "run"
		
	# Do general airborn logic
	else:
		# If player is moving left in the air
		if move_left and not move_right:
			if velocity.x > -RUN_MAX_VELOCITY:
				velocity.x -= AIR_ACCEL * step
		# If the player is moving right in the air
		elif move_right and not move_left:
			if velocity.x < RUN_MAX_VELOCITY:
				velocity.x += AIR_ACCEL * step
		else:
			var xv := absf(velocity.x)
			xv -= AIR_DEACCEL * step
			
			if xv < 0:
				xv = 0
			velocity.x = signf(velocity.x) * xv
			
		if absf(velocity.y) < 0.1:
			new_anim = "jump"
		
	# Flip character if moving new direction
	if new_siding_left != siding_left:
		if new_siding_left:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
			
		siding_left = new_siding_left
	
	# Set animation if it is new
	if new_anim != anim:
		anim = new_anim
		animated_sprite.play(anim)
		
		
	# Do general floor velocity
	if found_floor:
		floor_h_velocity = state.get_contact_collider_velocity_at_position(floor_index).x
		velocity.x += floor_h_velocity
	if found_wall:
		floor_v_velocity = state.get_contact_collider_velocity_at_position(wall_index).y
		velocity.y += floor_v_velocity
		
	# Do gravity and apply the new calculated velocity back to state
	if found_wall:
		pass
	else:
		velocity += state.get_total_gravity() * step
	
	state.set_linear_velocity(velocity)
	
