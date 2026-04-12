extends Node

# =============================================================================
# TimeManager — Autoload singleton
# Manages the in-game clock and emits signals when time or phase changes.
#
# ⏱ Time scale: 1 real second = 1 in-game minute
#               1 real minute = 1 in-game hour
#               1 full day    = 24 real minutes
# =============================================================================


## Emitted every time the phase changes (morning → day → evening → night)
signal day_phase_changed(new_phase: DayPhase)

## Emitted every in-game hour (every 60 real seconds)
signal hour_changed(hour: int)

## Emitted when midnight passes (a new day begins)
signal day_changed(day: int)


# -----------------------------------------------------------------------------
# Day phases — the four moments of the day used throughout the game
# -----------------------------------------------------------------------------
enum DayPhase {
	MORNING,  # 06:00 → 11:59  warm start, diurnal spawns appear
	DAY,      # 12:00 → 17:59  neutral light, most activity
	EVENING,  # 18:00 → 21:59  golden hour, some nocturnal spawns start
	NIGHT,    # 22:00 → 05:59  dark, nocturnal spirits active (Moute!)
}

# -----------------------------------------------------------------------------
# Time configuration
# -----------------------------------------------------------------------------

## How many real seconds make one in-game minute (tweak to speed up/slow down)
const REAL_SECONDS_PER_GAME_MINUTE: float = 0.05

## Starting hour when a new game begins
const START_HOUR: int = 8

# Phase boundaries: the hour at which each phase BEGINS
const PHASE_START_HOURS := {
	DayPhase.MORNING: 6,
	DayPhase.DAY:     10,
	DayPhase.EVENING: 18,
	DayPhase.NIGHT:   22,
}

# -----------------------------------------------------------------------------
# State
# -----------------------------------------------------------------------------
var current_day:    int      = 1
var current_hour:   int      = START_HOUR
var current_minute: int      = 0
var current_phase:  DayPhase = DayPhase.MORNING

## Accumulator: real seconds elapsed since last in-game minute tick
var _seconds_accumulator: float = 0.0

## Previous hour stored to detect hour changes without redundant signals
var _last_hour: int = START_HOUR


# =============================================================================
# CORE LOOP
# =============================================================================

func _process(delta: float) -> void:
	_seconds_accumulator += delta

	# Advance one in-game minute each time we cross the threshold
	while _seconds_accumulator >= REAL_SECONDS_PER_GAME_MINUTE:
		_seconds_accumulator -= REAL_SECONDS_PER_GAME_MINUTE
		_tick_minute()


func _tick_minute() -> void:
	current_minute += 1

	# Wrap minutes → advance hour
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1

		# Wrap hours → advance day
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			day_changed.emit(current_day)

		# Emit hour signal once per in-game hour
		hour_changed.emit(current_hour)
		if current_hour == 9:
			WeatherManager.force_weather(WeatherManager.WeatherType.RAIN, 24)
			

		# Check if the phase needs to change
		_evaluate_phase()


# =============================================================================
# PHASE MANAGEMENT
# =============================================================================

func _evaluate_phase() -> void:
	var new_phase := _phase_for_hour(current_hour)
	if new_phase != current_phase:
		current_phase = new_phase
		day_phase_changed.emit(current_phase)


## Returns the correct DayPhase for a given hour (0-23)
func _phase_for_hour(hour: int) -> DayPhase:
	if hour >= PHASE_START_HOURS[DayPhase.MORNING] and hour < PHASE_START_HOURS[DayPhase.DAY]:
		return DayPhase.MORNING
	elif hour >= PHASE_START_HOURS[DayPhase.DAY] and hour < PHASE_START_HOURS[DayPhase.EVENING]:
		return DayPhase.DAY
	elif hour >= PHASE_START_HOURS[DayPhase.EVENING] and hour < PHASE_START_HOURS[DayPhase.NIGHT]:
		return DayPhase.EVENING
	else:
		return DayPhase.NIGHT  # 22:00 → 05:59


# =============================================================================
# PUBLIC HELPERS
# =============================================================================

## Returns time progression within the current day as a 0.0 → 1.0 value.
## Useful for smooth shader / lighting interpolation.
func get_normalized_day_time() -> float:
	var total_minutes := current_hour * 60 + current_minute
	return total_minutes / float(24 * 60)


## Returns a human-readable time string, e.g. "08:30"
func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


## Force the clock to a specific hour (useful for debug or story triggers)
func set_time(hour: int, minute: int = 0) -> void:
	current_hour   = clamp(hour, 0, 23)
	current_minute = clamp(minute, 0, 59)
	_evaluate_phase()
	hour_changed.emit(current_hour)
