extends Node
class_name TimeSystem

## Time system for Persona-like day management

# Time periods (like Persona)
enum TimePeriod { EARLY_MORNING, MORNING, AFTERNOON, EVENING, NIGHT }

# Calendar
var current_day: int = 1
var current_month: int = 4  # April - start of school year
var current_year: int = 1   # Year 1 at Duel Academy
var current_period: TimePeriod = TimePeriod.MORNING
var day_of_week: int = 1    # 1 = Monday

# Time period names
const PERIOD_NAMES = {
	TimePeriod.EARLY_MORNING: "Early Morning",
	TimePeriod.MORNING: "Morning",
	TimePeriod.AFTERNOON: "Afternoon",
	TimePeriod.EVENING: "Evening",
	TimePeriod.NIGHT: "Night"
}

const WEEKDAY_NAMES = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const MONTH_NAMES = ["", "January", "February", "March", "April", "May", "June",
					  "July", "August", "September", "October", "November", "December"]

# Signals
signal time_advanced(new_period: TimePeriod)
signal day_changed(new_day: int, new_month: int)
signal deadline_warning(event_name: String, days_left: int)

# Story deadlines (like Persona's palace deadlines)
var active_deadlines: Array[Dictionary] = []


func _ready() -> void:
	print("[TimeSystem] Initialized: %s, %s %d, Year %d" % [
		WEEKDAY_NAMES[day_of_week],
		MONTH_NAMES[current_month],
		current_day,
		current_year
	])


## Advance time by one period
func advance_time() -> void:
	var old_period = current_period

	match current_period:
		TimePeriod.EARLY_MORNING:
			current_period = TimePeriod.MORNING
		TimePeriod.MORNING:
			current_period = TimePeriod.AFTERNOON
		TimePeriod.AFTERNOON:
			current_period = TimePeriod.EVENING
		TimePeriod.EVENING:
			current_period = TimePeriod.NIGHT
		TimePeriod.NIGHT:
			# Move to next day
			_advance_day()
			current_period = TimePeriod.EARLY_MORNING

	time_advanced.emit(current_period)
	print("[TimeSystem] Time advanced: %s -> %s" % [PERIOD_NAMES[old_period], PERIOD_NAMES[current_period]])

	_check_deadlines()


## Advance to next day (skip to early morning)
func advance_to_next_day() -> void:
	_advance_day()
	current_period = TimePeriod.EARLY_MORNING
	time_advanced.emit(current_period)


func _advance_day() -> void:
	current_day += 1
	day_of_week = (day_of_week % 7) + 1

	# Handle month transitions (simplified - 30 days per month)
	if current_day > 30:
		current_day = 1
		current_month += 1

		# Handle year transition
		if current_month > 12:
			current_month = 1
			current_year += 1
			print("[TimeSystem] === YEAR %d BEGINS ===" % current_year)

	day_changed.emit(current_day, current_month)
	print("[TimeSystem] New day: %s, %s %d" % [WEEKDAY_NAMES[day_of_week], MONTH_NAMES[current_month], current_day])


## Check if it's a school day
func is_school_day() -> bool:
	return day_of_week >= 1 and day_of_week <= 5  # Monday-Friday


## Get formatted date string
func get_date_string() -> String:
	return "%s, %s %d" % [WEEKDAY_NAMES[day_of_week], MONTH_NAMES[current_month], current_day]


## Get current period name
func get_period_name() -> String:
	return PERIOD_NAMES[current_period]


## Add a story deadline
func add_deadline(event_name: String, target_month: int, target_day: int) -> void:
	active_deadlines.append({
		"name": event_name,
		"month": target_month,
		"day": target_day
	})
	print("[TimeSystem] Deadline added: %s on %s %d" % [event_name, MONTH_NAMES[target_month], target_day])


func _check_deadlines() -> void:
	for deadline in active_deadlines:
		var days_left = _days_until(deadline.month, deadline.day)
		if days_left <= 7 and days_left > 0:
			deadline_warning.emit(deadline.name, days_left)
		elif days_left <= 0:
			print("[TimeSystem] DEADLINE REACHED: %s" % deadline.name)


func _days_until(target_month: int, target_day: int) -> int:
	# Simplified calculation
	var current_total = current_month * 30 + current_day
	var target_total = target_month * 30 + target_day
	return target_total - current_total
