class_name Player
extends CharacterBody2D


# =========================================================
# FUTURE SYSTEMS — hooks ready, managers not yet implemented
# =========================================================
# StaminaManager.has_stamina(dash_stamina_cost)     → try_start_dash()
# StaminaManager.consume(sprint_stamina_per_second)  → apply_horizontal_movement()
# WeatherManager.weather_changed                     → _on_weather_changed()
# FoodBuffManager                                    → apply_horizontal_movement()


# =========================================================
# REFERENCES
# =========================================================

@export var animated_sprite: AnimatedSprite2D
@export var climb_detector: Area2D


# =========================================================
# UNLOCKS
# Toggled by major spirits as the story progresses.
# =========================================================

@export var can_sprint: bool = false
@export var can_double_jump: bool = true
@export var can_dash: bool = true
@export var can_glide: bool = true


# =========================================================
# MOVEMENT — SPEEDS
# =========================================================

@export var move_speed: float = 400.0
@export var sprint_speed: float = 500.0


# =========================================================
# MOVEMENT — FEEL
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

# Assist — forgiveness windows for jump input.
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
@export var climb_sprint_speed: float = 400.0
@export var climb_detach_time: float = 0.15


# =========================================================
# RUNTIME — WEATHER
# Multiplier applied to movement speed. Set by WeatherManager.
# =========================================================

var movement_speed_multiplier: float = 1.0


# =========================================================
# RUNTIME — MOVEMENT
# Values updated each physics frame.
# =========================================================

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var drop_through_timer: float = 0.0

var remaining_jumps: int = 0
var remaining_dashes: int = 0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 1.0

# One entry per consumed dash charge — each tracks its own recharge countdown.
var dash_recharge_timers: Array[float] = []

var can_climb: bool = false
var is_climbing: bool = false
var climb_contacts: int = 0
var climb_detach_timer: float = 0.0

# Cached from the previous physics step — read before move_and_slide().
var was_on_floor: bool = false


# =========================================================
# RUNTIME — INTERACTION
# =========================================================

var all_nearby_interactables: Array[Interactable] = []
var closest_interactable: Interactable = null
var previous_closest_interactable: Interactable = null


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	InputRouterManager.player_interact.connect(interact)
	SaveManager.data_loaded.connect(load_data)
	SaveManager.register_player(self)
	# WeatherManager.weather_changed.connect(_on_weather_changed)

	remaining_jumps = extra_jumps
	remaining_dashes = max_dashes
	dash_recharge_timers.clear()


# =========================================================
# PHYSICS LOOP
# =========================================================

func _physics_process(delta: float) -> void:
	# Cache floor state before move_and_slide() runs.
	was_on_floor = is_on_floor()

	# Any non-exploration state — freeze horizontal movement entirely.
	if not PlayerStateManager.is_exploring():
		velocity.x = 0.0
		move_and_slide()
		update_animations()
		return

	# Read inputs once per frame.
	var input_dir := Input.get_axis("move_left", "move_right")
	var vertical_input := Input.get_axis("move_up", "move_down")
	var is_sprinting := can_sprint and Input.is_action_pressed("sprint") and input_dir != 0

	update_timers(delta)
	try_start_climb(vertical_input)

	if is_climbing:
		handle_climb()
		move_and_slide()
		update_animations()
		if is_climbing:
			return

	try_start_dash(input_dir)

	if is_dashing:
		update_dash(delta)
		move_and_slide()
		update_animations()
		return

	apply_gravity(delta)
	apply_horizontal_movement(delta, input_dir, is_sprinting)
	handle_jump()
	handle_jump_cut()
	move_and_slide()
	update_animations()

# =========================================================
# TIMERS
# =========================================================

func update_timers(delta: float) -> void:
	climb_detach_timer = max(climb_detach_timer - delta, 0.0)
	update_jump_buffer(delta)
	update_floor_state(delta)
	update_drop_through(delta)
	update_dash_recharge(delta)
	try_start_drop_through()


# =========================================================
# INPUT MEMORY
# =========================================================

# Stores jump input for a short window to allow early presses.
func update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)


# Resets jumps and coyote timer when landing. Counts down coyote time in the air.
func update_floor_state(delta: float) -> void:
	if was_on_floor:
		coyote_timer = coyote_time
		remaining_jumps = extra_jumps
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)


# =========================================================
# DROP-THROUGH
# =========================================================

# Initiates a drop-through when the player presses down + jump on a one-way platform.
func try_start_drop_through() -> void:
	var vertical_input := Input.get_axis("move_up", "move_down")

	if vertical_input > drop_through_input_threshold \
	and Input.is_action_just_pressed("jump") \
	and was_on_floor:
		drop_through_timer = drop_through_time
		set_collision_mask_value(one_way_platform_mask_bit, false)
		velocity.y = 100.0
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


# Restores one-way platform collision once the drop-through window expires.
func update_drop_through(delta: float) -> void:
	if drop_through_timer <= 0.0:
		return

	drop_through_timer = max(drop_through_timer - delta, 0.0)

	if drop_through_timer <= 0.0:
		set_collision_mask_value(one_way_platform_mask_bit, true)


# =========================================================
# DASH
# =========================================================

# Ticks down each recharge timer and restores a dash charge when one completes.
func update_dash_recharge(delta: float) -> void:
	if not can_dash:
		return

	# Iterate in reverse so removing an element doesn't skip the next.
	for i in range(dash_recharge_timers.size() - 1, -1, -1):
		dash_recharge_timers[i] -= delta

		if dash_recharge_timers[i] <= 0.0:
			dash_recharge_timers.remove_at(i)
			remaining_dashes = min(remaining_dashes + 1, max_dashes)


func try_start_dash(input_dir: float) -> void:
	if not can_dash or is_climbing:
		return

	# Future: if not StaminaManager.has_stamina(dash_stamina_cost): return

	if Input.is_action_just_pressed("dash") and remaining_dashes > 0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		remaining_dashes -= 1
		dash_recharge_timers.append(dash_recharge_time)

		if input_dir != 0:
			dash_direction = input_dir


func update_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.x = dash_direction * dash_speed
	velocity.y = 0.0

	if dash_timer <= 0.0:
		is_dashing = false


# =========================================================
# CLIMB
# =========================================================

func try_start_climb(vertical_input: float) -> void:
	if can_climb and vertical_input != 0 and climb_detach_timer <= 0.0 and not was_on_floor:
		is_climbing = true


func handle_climb() -> void:
	var horizontal_input := Input.get_axis("move_left", "move_right")
	var vertical_input := Input.get_axis("move_up", "move_down")
	var is_sprinting := can_sprint \
		and Input.is_action_pressed("sprint") \
		and (horizontal_input != 0 or vertical_input != 0)

	if not can_climb:
		stop_climbing()
		return

	if Input.is_action_just_pressed("jump"):
		stop_climbing()
		velocity.y = jump_force
		return

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
	if was_on_floor:
		return

	var current_gravity := gravity

	if can_glide and is_gliding():
		current_gravity *= glide_gravity_multiplier
	elif velocity.y > 0.0:
		current_gravity *= fall_gravity_multiplier

	velocity.y += current_gravity * delta

	# Cap fall speed while gliding.
	if can_glide and is_gliding():
		velocity.y = min(velocity.y, max_glide_fall_speed)


func apply_horizontal_movement(delta: float, input_dir: float, is_sprinting: bool) -> void:
	var current_speed := sprint_speed if is_sprinting else move_speed
	# Future: multiply by FoodBuffManager speed modifier here too.
	current_speed *= movement_speed_multiplier

	# Future: if is_sprinting: StaminaManager.consume(sprint_stamina_per_second * delta)

	var target_velocity_x := input_dir * current_speed
	var current_acceleration := acceleration if was_on_floor else air_acceleration
	var current_deceleration := deceleration if was_on_floor else air_deceleration

	if input_dir != 0:
		velocity.x = move_toward(velocity.x, target_velocity_x, current_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_deceleration * delta)


func handle_jump() -> void:
	# Skip jump input during drop-through to avoid an accidental ground jump.
	if drop_through_timer > 0.0:
		return

	# Ground jump — coyote time extends the window slightly after leaving a ledge.
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return

	# Extra air jump (double jump).
	if jump_buffer_timer > 0.0 and not was_on_floor and remaining_jumps > 0 and can_double_jump:
		velocity.y = jump_force
		remaining_jumps -= 1
		jump_buffer_timer = 0.0


# Cuts upward velocity when jump is released early — enables variable jump height.
func handle_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier


# Returns true when the player is actively gliding (holding jump while falling).
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

	# Only call play() when the animation actually changes.
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)

	# Pause climb animation when stationary on a ladder.
	if is_climbing:
		if abs(velocity.y) > 5.0:
			animated_sprite.play()
		else:
			animated_sprite.pause()

	if velocity.x < 0.0:
		animated_sprite.flip_h = true
	elif velocity.x > 0.0:
		animated_sprite.flip_h = false


# =========================================================
# INTERACTION
# =========================================================

# Triggers the closest interactable when the player presses interact.
func interact() -> void:
	if not PlayerStateManager.is_exploring():
		return
	if closest_interactable == null:
		return
	closest_interactable.interact()


# Finds the nearest Interactable in range and updates the prompt accordingly.
func _find_closest_interactable() -> void:
	if all_nearby_interactables.is_empty():
		GameEventBus.hide_input_helper.emit()
		previous_closest_interactable = closest_interactable
		closest_interactable = null
		return

	var best: Interactable = null
	var best_dist: float = INF

	for interactable in all_nearby_interactables:
		var dist := global_position.distance_squared_to(interactable.global_position)
		if dist < best_dist:
			best_dist = dist
			best = interactable

	previous_closest_interactable = closest_interactable
	closest_interactable = best
	if closest_interactable != previous_closest_interactable:
		closest_interactable.highlight()
		if previous_closest_interactable != null:
			previous_closest_interactable.unhighlight()

	if closest_interactable != null:
		# UI resolves the label from the action name — player stays decoupled.
		GameEventBus.show_input_helper.emit("interact")


# =========================================================
# INTERACTION DETECTION
# =========================================================

func _on_interactable_detection_area_2d_area_entered(area: Area2D) -> void:
	if area is Interactable:
		all_nearby_interactables.append(area as Interactable)
		_find_closest_interactable()


func _on_interactable_detection_area_2d_area_exited(area: Area2D) -> void:
	all_nearby_interactables.erase(area)
	_find_closest_interactable()


# =========================================================
# CLIMB DETECTION
# =========================================================

func _on_climb_detector_area_2d_body_entered(_body: Node2D) -> void:
	climb_contacts += 1
	can_climb = climb_contacts > 0


func _on_climb_detector_area_2d_body_exited(_body: Node2D) -> void:
	climb_contacts = max(climb_contacts - 1, 0)
	can_climb = climb_contacts > 0

	if not can_climb and is_climbing:
		stop_climbing()
		velocity.y = 0.0


# =========================================================
# WEATHER
# =========================================================

# Called by WeatherManager when weather changes.
# Adjusts movement speed multiplier based on hostile conditions.
#func _on_weather_changed(new_weather: StringName) -> void:
#	movement_speed_multiplier = WeatherManager.get_speed_multiplier(new_weather)


# =========================================================
# SAVE / LOAD
# =========================================================

func save_data() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
	}


func load_data() -> void:
	var player_data: Dictionary = SaveManager.data.get("player", {})

	var x = player_data.get("position_x", 0.0)
	var y = player_data.get("position_y", 0.0)

	if not (x == 0.0 and y == 0.0):
		global_position = Vector2(x, y)

	_debug()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("🧍 Player | pos: %s | state: %s | dashes: %d/%d | jumps: %d" % [
		global_position,
		PlayerStateManager.get_state_as_string(),
		remaining_dashes,
		max_dashes,
		remaining_jumps,
	])
