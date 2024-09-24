extends RigidBody2D

const RUN_ACCEL = 1000.0
const RUN_DEACCEL = 3000.0
const RUN_MAX_VELOCITY = 155.0
const AIR_ACCEL = 850.0
const AIR_DEACCEL = 350.0
const JUMP_VELOCITY = 400.0
const STOP_JUMP_FORCE = 750.0
const CLIMB_FORCE = 400.0
const CLIMB_MAX = 200.0
const CLIMB_HMAX = 1700.0
const HARD_Y_MAX = 500.0
const HARD_X_MAX = 350.0
const MAX_FLOOR_AIRBORN_TIME = 0.15
const MAX_WALL_AIRBORN_TIME = 0.15
const MAX_JUMPS = 2
const CHAIN_PULL = 27

var chain_velocity := Vector2(0,0)
var anim := ""

var jumps_used := 0
var siding_left := false
var jumping := false
var stopping_jump := false
var up_limit := false
var down_limit := false
var wall_state := 0
# var grapple_off := false
var mouse_position = null
var grappling := false

var floor_h_velocity: float = 0.0
var floor_v_velocity: float = 0.0
var airborn_time: float = 1e20

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var speed = 10
@export var hook: StaticBody2D#@export var pinjoint : PinJoint2D
@onready var line = $Line2D
var hooked = false
#@onready var line_end = hook.get_node("Marker2D")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

"""
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("grapple"):
		mouse_position = get_global_mouse_position()
		$Chain.shoot()
	elif event.is_action_released("grapple"):
		grappling = false
		mouse_position = null
"""

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print(floor(to_local(event.position)))
		print(floor(position))
		if event.pressed and Input.is_action_pressed(&"grapple"):
			# We clicked the mouse -> shoot()
			$Chain.shoot(event.position - get_viewport().size * 0.5)
		else:
			# We released the mouse -> release()
			$Chain.release()

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
	var grapple := Input.is_action_just_pressed(&"grapple")
	var grapple_off := !(Input.is_action_pressed(&"grapple"))
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
	wall_state = 0
	
	
	for contact_index in state.get_contact_count():
		var collision_normal = state.get_contact_local_normal(contact_index)
		
		# Check left wall collision
		if collision_normal.dot(Vector2(-1, 0)) > 0.6:
			if move_right:
				found_wall = true
				wall_index = contact_index
				wall_state = -1
				
		# Check right wall collision
		if collision_normal.dot(Vector2(1, 0)) > 0.6:
			if move_left:
				found_wall = true
				wall_index = contact_index
				wall_state = 1
				
	if found_floor or found_wall:
		airborn_time = 0.0
	else:
		# Add to the time spent in the air
		airborn_time += step
		
	var on_floor := airborn_time < MAX_FLOOR_AIRBORN_TIME
	

	# Hook physics
	if $Chain.hooked:
		print(found_wall)
		# `to_local($Chain.tip).normalized()` is the direction that the chain is pulling
		chain_velocity = to_local($Chain.tip).normalized() * CHAIN_PULL
		if chain_velocity.y > 0:
			# Pulling down isn't as strong
			chain_velocity.y *= 0.55
		else:
			# Pulling up is stronger
			chain_velocity.y *= 1.65
		if sign(chain_velocity.x) != sign(velocity.x):
			# if we are trying to walk in a different
			# direction than the chain is pulling
			# reduce its pull
			chain_velocity.x *= 0.7
		if crouch:
			chain_velocity.y += CHAIN_PULL
		if jump or move_up:
			chain_velocity.y -= CHAIN_PULL
		chain_velocity
	else:
		# Not hooked -> no chain velocity
		chain_velocity = Vector2(0,0)
	velocity += chain_velocity


# Do general jump logic
	if jumping:
		up_limit = false
		# Falling logic
		if velocity.y > 0:
			# Turn off jumping flag because velocity goes down
			jumping = false
			down_limit = false

		# If the player releases jump input
		elif not jump_hold and not jump:
			stopping_jump = true
		
		# If the player releases jump input, accelerate falling
		if stopping_jump:
			velocity.y += STOP_JUMP_FORCE * step
	
	if jumps_used + 1 < MAX_JUMPS and jump and jump_hold:
		# Check if player wants to jump
		velocity.y = -JUMP_VELOCITY
		up_limit = false
		jumping = true
		stopping_jump = false
		if not found_wall:
			jumps_used += 1
		if jumps_used >= 2:
			velocity.x = 0
			
		
	if found_wall and not on_floor:
		velocity = wall_movement(velocity, move_up, crouch, step)
		if jump:
			velocity = wall_jump(velocity, step, wall_state, airborn_time)
			
	# Do checks for character on floor for gen movement
	if on_floor:
		if found_wall:
			if move_up and not crouch:
				velocity.y = climb_up(velocity, step)
		jumps_used = 0
		down_limit = false
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
		if not jumping:
			down_limit = false
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
	
	# Handle grappling movement
	if grappling:
		velocity = grapple_movement(mouse_position, velocity, step)
	
	if grapple_off:
		mouse_position = null

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
	if found_floor and grapple_off:
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
	
	if HARD_X_MAX < abs(velocity.x):
		velocity.x = HARD_X_MAX * sign(velocity.x)
	if HARD_Y_MAX < abs(velocity.y):
		velocity.y = HARD_Y_MAX * sign(velocity.y)
	state.set_linear_velocity(velocity)
	
func climb_up(velocity, step):
	if velocity.y < -CLIMB_FORCE:
		velocity.y -= CLIMB_FORCE * step
		return velocity.y
	if velocity.y < -CLIMB_MAX:
		# Get absolute value of current velocity
		var yv := absf(velocity.y)
		# Decrease that velocity until xv is 0.
		yv -= RUN_DEACCEL * step
		if yv < CLIMB_MAX:
			yv = CLIMB_MAX
		# Set velocity to direction times slowing velocity
		velocity.y = signf(velocity.y) * yv
		return velocity.y
	velocity.y -= CLIMB_FORCE * step * 4
	return velocity.y
	
func climb_down(velocity, step):
	
	velocity.y += CLIMB_FORCE * step
	if velocity.y > CLIMB_MAX:
		velocity.y = CLIMB_MAX
	return velocity.y
	
func wall_jump(velocity, step, wall_s, aerial):
	# Jump while clinging to a wall on your left
	if (wall_s == -1) and (airborn_time < MAX_FLOOR_AIRBORN_TIME):
		if (abs(velocity.y) > JUMP_VELOCITY / sqrt(2)):
			velocity.y = -abs(velocity.y)
			velocity.x = -abs(velocity.y)
		else:
			velocity.y = -JUMP_VELOCITY / sqrt(2)
			velocity.x = -JUMP_VELOCITY / sqrt(2)
	# Jump while clinging to a wall on your right
	if (wall_s == 1) and (airborn_time < MAX_FLOOR_AIRBORN_TIME):
		if (abs(velocity.y) > JUMP_VELOCITY / sqrt(2)):
			velocity.y = -abs(velocity.y)
			velocity.x = abs(velocity.y)
		else:
			velocity.y = -JUMP_VELOCITY / sqrt(2)
			velocity.x = JUMP_VELOCITY / sqrt(2)
	return velocity
	
func wall_movement(velocity, move_up, crouch, step):
	if move_up and not crouch:
		velocity.y = climb_up(velocity, step)
		return velocity
	if crouch and not move_up:
		velocity.y = climb_down(velocity, step)
		return velocity
	if (not crouch and not move_up) or (move_up and crouch):
		var yv := absf(velocity.y)
		# Decrease that velocity until xv is 0.
		yv -= STOP_JUMP_FORCE * step
		if yv < 0:
			yv = 0
		# Set velocity to direction times slowing velocity
		velocity.y = signf(velocity.y) * yv
		return velocity

func grapple_movement(mouse_position, velocity, step):
	var direction = (mouse_position - position).normalized()  # Direction to hook
	var distance_to_hook = position.distance_to(mouse_position)  # Distance

	# Pull towards hook with proportional strength
	var pull_strength = clamp(distance_to_hook / 100, 0, 1) * RUN_ACCEL * 30
	var pull_velocity = direction * pull_strength * step

	# Stop when close to hook
	if distance_to_hook < 10:
		return Vector2.ZERO

	return pull_velocity
