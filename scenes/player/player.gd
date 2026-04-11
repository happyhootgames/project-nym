class_name Player
extends CharacterBody2D

# =========================================================
# REFERENCES
# =========================================================

@export var animated_sprite: AnimatedSprite2D
@export var climb_detector: Area2D


# =========================================================
# UNLOCKS
# Enable or disable abilities during the game.
# =========================================================

@export var can_sprint: bool = false
@export var can_double_jump: bool = true
@export var can_dash: bool = true
@export var can_glide: bool = true


# =========================================================
# MOVE
# Horizontal movement speeds.
# =========================================================

@export var move_speed: float = 400.0
@export var sprint_speed: float = 500.0


# =========================================================
# MOVE FEEL
# Ground and air responsiveness.
# =========================================================

@export var acceleration: float = 1200.0
@export var deceleration: float = 2200.0
@export var air_acceleration: float = 900.0
@export var air_deceleration: float = 700.0


# =========================================================
# GRAVITY
# =========================================================

@export var gravity: float = 1200.0
@export var fall_gravity_multiplier: float = 1.15
@export var glide_gravity_multiplier: float = 0.25
@export var max_glide_fall_speed: float = 200.0


# =========================================================
# JUMP
# =========================================================

@export var jump_force: float = -600.0
@export var jump_cut_multiplier: float = 0.45
@export var extra_jumps: int = 1

# Jump assist
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12


# =========================================================
# DASH
# =========================================================

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.30
@export var max_dashes: int = 2
@export var dash_recharge_time: float = 3.0


# =========================================================
# DROP-THROUGH
# One-way platforms.
# =========================================================

@export var one_way_platform_mask_bit: int = 5
@export var drop_through_time: float = 0.18
@export var drop_through_input_threshold: float = 0.7


# =========================================================
# CLIMB
# =========================================================

@export var climb_speed: float = 240.0
@export var climb_sprint_speed: float = 220.0
@export var climb_detach_time: float = 0.15


# =========================================================
# RUNTIME - MOVEMENT
# Values updated during gameplay.
# =========================================================

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var drop_through_timer: float = 0.0

var remaining_jumps: int = 0
var remaining_dashes: int = 0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 1.0

# One timer per used dash charge
var dash_recharge_timers: Array[float] = []

var can_climb: bool = false
var is_climbing: bool = false
var climb_contacts: int = 0
var climb_detach_timer: float = 0.0

# Floor state from previous physics step
var was_on_floor: bool = false


# =========================================================
# RUNTIME - INTERACTION
# =========================================================

var all_nearby_interactables: Array[Node2D] = []
var closest_interactable: Node2D = null
var previous_closest_interactable: Node2D = null


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	# Connect game systems
	InputRouterManager.player_interact.connect(interact)
	SaveManager.data_loaded.connect(load_data)
	SaveManager.register_player(self)

	# Init movement resources
	remaining_jumps = extra_jumps
	remaining_dashes = max_dashes
	dash_recharge_timers.clear()

	# Load saved player position
	load_data()


func _physics_process(delta: float) -> void:
	# Store floor state from previous frame
	was_on_floor = is_on_floor()

	# Only allow gameplay actions while exploring
	if PlayerStateManager.get_state() != PlayerStateManager.State.EXPLORING:
		velocity.x = 0.0
		update_animations()
		move_and_slide()
		return

	# Read inputs once
	var input_dir := Input.get_axis("move_left", "move_right")
	var vertical_input := Input.get_axis("move_up", "move_down")
	var is_sprinting := can_sprint and Input.is_action_pressed("sprint") and input_dir != 0

	# Update timers
	update_timers(delta)

	# Try entering climb mode
	try_start_climb(vertical_input)

	# Handle climb first
	if is_climbing:
		handle_climb()
		move_and_slide()
		update_animations()

		if is_climbing:
			return

	# Try starting dash
	try_start_dash(input_dir)

	# Handle dash state
	if is_dashing:
		update_dash(delta)
		move_and_slide()
		update_animations()
		return

	# Handle normal movement
	apply_gravity(delta)
	apply_horizontal_movement(delta, input_dir, is_sprinting)
	handle_jump()
	handle_jump_cut()

	move_and_slide()
	update_animations()


# =========================================================
# CORE UPDATE
# =========================================================

func update_timers(delta: float) -> void:
	# Detach timer used after leaving climb
	climb_detach_timer = max(climb_detach_timer - delta, 0.0)

	# Jump input memory
	update_jump_buffer(delta)

	# Floor state and coyote time
	update_floor_state(delta)

	# One-way platform timer
	update_drop_through(delta)

	# Dash recharge timers
	update_dash_recharge(delta)

	# Down + jump to drop through
	try_start_drop_through()


# =========================================================
# INPUT MEMORY
# =========================================================

func update_jump_buffer(delta: float) -> void:
	# Store jump input for a short time
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)


func update_floor_state(delta: float) -> void:
	# Use previous floor state before current move_and_slide()
	if was_on_floor:
		coyote_timer = coyote_time
		remaining_jumps = extra_jumps
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)


# =========================================================
# DROP-THROUGH
# =========================================================

func try_start_drop_through() -> void:
	var vertical_input := Input.get_axis("move_up", "move_down")

	# Require a strong downward input
	if vertical_input > drop_through_input_threshold \
	and Input.is_action_just_pressed("jump") \
	and was_on_floor:
		drop_through_timer = drop_through_time

		# Ignore one-way platforms for a short time
		set_collision_mask_value(one_way_platform_mask_bit, false)

		# Push player slightly downward
		velocity.y = 100.0

		# Cancel jump on this frame
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


func update_drop_through(delta: float) -> void:
	if drop_through_timer > 0.0:
		drop_through_timer = max(drop_through_timer - delta, 0.0)

		# Restore collisions when done
		if drop_through_timer <= 0.0:
			set_collision_mask_value(one_way_platform_mask_bit, true)


# =========================================================
# DASH
# =========================================================

func update_dash_recharge(delta: float) -> void:
	if not can_dash:
		return

	# Update all active recharge timers
	for i in range(dash_recharge_timers.size() - 1, -1, -1):
		dash_recharge_timers[i] -= delta

		# Restore one dash when timer ends
		if dash_recharge_timers[i] <= 0.0:
			dash_recharge_timers.remove_at(i)
			remaining_dashes = min(remaining_dashes + 1, max_dashes)


func try_start_dash(input_dir: float) -> void:
	if not can_dash or is_climbing:
		return

	if Input.is_action_just_pressed("dash") and remaining_dashes > 0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		remaining_dashes -= 1

		# Start recharge for the used dash
		dash_recharge_timers.append(dash_recharge_time)

		# Use current direction if available
		if input_dir != 0:
			dash_direction = input_dir


func update_dash(delta: float) -> void:
	# Ignore normal movement during dash
	dash_timer -= delta
	velocity.x = dash_direction * dash_speed
	velocity.y = 0.0

	if dash_timer <= 0.0:
		is_dashing = false


# =========================================================
# CLIMB
# =========================================================

func try_start_climb(vertical_input: float) -> void:
	# Start climbing only in valid conditions
	if can_climb and vertical_input != 0 and climb_detach_timer <= 0.0 and not was_on_floor:
		is_climbing = true


func handle_climb() -> void:
	var horizontal_input := Input.get_axis("move_left", "move_right")
	var vertical_input := Input.get_axis("move_up", "move_down")
	var is_sprinting := can_sprint and Input.is_action_pressed("sprint") and (horizontal_input != 0 or vertical_input != 0)

	# Auto leave climb if player is no longer inside a climbable zone
	if not can_climb:
		stop_climbing()
		return

	# Jump leaves climb
	if Input.is_action_just_pressed("jump"):
		stop_climbing()
		velocity.y = jump_force
		return

	# Move in climb state
	var current_climb_speed := climb_sprint_speed if is_sprinting else climb_speed
	velocity.x = horizontal_input * current_climb_speed
	velocity.y = vertical_input * current_climb_speed


func stop_climbing() -> void:
	is_climbing = false
	climb_detach_timer = climb_detach_time


# =========================================================
# NORMAL MOVEMENT
# =========================================================

func apply_gravity(delta: float) -> void:
	if not was_on_floor:
		var current_gravity := gravity

		if can_glide and is_gliding():
			current_gravity *= glide_gravity_multiplier
		elif velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier

		velocity.y += current_gravity * delta

		# Limit fall speed while gliding
		if can_glide and is_gliding():
			velocity.y = min(velocity.y, max_glide_fall_speed)


func apply_horizontal_movement(delta: float, input_dir: float, is_sprinting: bool) -> void:
	var current_speed := sprint_speed if is_sprinting else move_speed
	var target_velocity_x := input_dir * current_speed

	var current_acceleration := acceleration if was_on_floor else air_acceleration
	var current_deceleration := deceleration if was_on_floor else air_deceleration

	# Smooth move toward target speed
	if input_dir != 0:
		velocity.x = move_toward(velocity.x, target_velocity_x, current_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_deceleration * delta)


func handle_jump() -> void:
	# Ignore jump while dropping through
	if drop_through_timer > 0.0:
		return

	# Ground jump with coyote time
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return

	# Extra air jump
	if jump_buffer_timer > 0.0 and not was_on_floor and remaining_jumps > 0 and can_double_jump:
		velocity.y = jump_force
		remaining_jumps -= 1
		jump_buffer_timer = 0.0


func handle_jump_cut() -> void:
	# Release jump early for short hop
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


func is_gliding() -> bool:
	if not can_glide:
		return false

	return Input.is_action_pressed("jump") \
		and not was_on_floor \
		and velocity.y > -20.0 \
		and not is_dashing \
		and not is_climbing


# =========================================================
# ANIMATIONS
# =========================================================

func update_animations() -> void:
	if animated_sprite == null:
		return

	var new_animation := "idle"

	# Animation priority
	if is_dashing:
		new_animation = "dash"
	elif is_climbing:
		new_animation = "climb"
	elif not is_on_floor():
		if can_glide and is_gliding():
			new_animation = "glide"
		elif velocity.y < 0.0:
			new_animation = "jump"
		else:
			new_animation = "fall"
	elif abs(velocity.x) > 10.0:
		new_animation = "walk"

	# Change only when needed
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)

	# Pause climb animation when not moving
	if is_climbing:
		if abs(velocity.y) > 5.0:
			animated_sprite.play()
		else:
			animated_sprite.pause()

	# Flip sprite with horizontal movement
	if velocity.x < 0.0:
		animated_sprite.flip_h = true
	elif velocity.x > 0.0:
		animated_sprite.flip_h = false


# =========================================================
# INTERACTION
# =========================================================

func interact() -> void:
	if PlayerStateManager.get_state() != PlayerStateManager.State.EXPLORING:
		return

	if closest_interactable == null:
		return
	
	closest_interactable.interact()
	
	#var interaction_component := _find_interaction_component(closest_interactable)
	#if interaction_component != null:
		#interaction_component.interact()


#func _find_interaction_component(body: Node2D) -> InteractionComponent:
	#for child in body.get_children():
		#if child is InteractionComponent:
			#return child
	#return null


func _find_closest_interactable() -> void:
	if all_nearby_interactables.is_empty():
		UIEvents.hide_input_helper.emit()
		previous_closest_interactable = closest_interactable
		closest_interactable = null
		return

	var best: Node2D = null
	var best_dist: float = INF

	for interactable in all_nearby_interactables:
		var dist := global_position.distance_squared_to(interactable.global_position)

		if dist < best_dist:
			best_dist = dist
			best = interactable

	previous_closest_interactable = closest_interactable
	closest_interactable = best

	if closest_interactable != null:
		UIEvents.show_input_helper.emit(
			"Press",
			InputBindingsManager.get_action_keyboard_label("interact")
		)


# =========================================================
# INTERACTION DETECTION
# =========================================================

func _on_interactable_detection_area_2d_body_entered(body: Node2D) -> void:
	if not body.has_method("interact"):
		return
	all_nearby_interactables.append(body)
	_find_closest_interactable()


func _on_interactable_detection_area_2d_body_exited(body: Node2D) -> void:
	all_nearby_interactables.erase(body)
	_find_closest_interactable()


# =========================================================
# CLIMB DETECTION
# =========================================================

func _on_climb_detector_area_2d_body_entered(body: Node2D) -> void:
	climb_contacts += 1
	can_climb = climb_contacts > 0


func _on_climb_detector_area_2d_body_exited(body: Node2D) -> void:
	climb_contacts = max(climb_contacts - 1, 0)
	can_climb = climb_contacts > 0

	# Auto leave climb when no climbable zone remains
	if not can_climb and is_climbing:
		stop_climbing()
		velocity.y = 0.0


# =========================================================
# SAVE / LOAD
# =========================================================

func save_data() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y
	}


func load_data() -> void:
	if not SaveManager.data.has("player"):
		return

	var player_data: Dictionary = SaveManager.data["player"]

	if player_data.has("position_x") and player_data.has("position_y"):
		var x = player_data["position_x"]
		var y = player_data["position_y"]

		if not (x == 0 and y == 0):
			global_position = Vector2(x, y)

	print("============================================")
	print("PLAYER POSITION: ", global_position)
