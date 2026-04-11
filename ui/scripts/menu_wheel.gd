extends Control

var is_open: bool = false
var old_index: int = -1
var selected_index: int = -1

var options: Array[String]= [
	"map",
	"inventory",
	"collections",
	"journal"
]

@export var label: Label

func _ready() -> void:
	UIEvents.show_menu_wheel.connect(update_wheel_visibility)
	UIEvents.confirm_choice_in_menu_wheel.connect(confirm_selection)

func _process(_delta: float) -> void:
	if PlayerStateManager.is_in_menu_wheel():
		update_selection()
	#if Input.is_action_just_pressed("wheel_trigger"):
		#open_wheel()
#
	#if is_open:
		#update_selection()
#
	#if Input.is_action_just_released("wheel_trigger"):
		#confirm_selection()
		#close_wheel()

func update_selection() -> void:
	var dir := Input.get_vector("wheel_left", "wheel_right", "wheel_up", "wheel_down")
	
	old_index = selected_index
	# Ignore tiny stick movement
	if dir.length() < 0.6:
		selected_index = -1
		return

	# Compare horizontal / vertical strength
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			selected_index = 1 # right
		else:
			selected_index = 3 # left
	else:
		if dir.y > 0:
			selected_index = 2 # down
		else:
			selected_index = 0 # up
	
	if old_index != selected_index:
		if selected_index == -1:
			label.text = "..."
		else:
			label.text = options[selected_index]
	
func confirm_selection() -> void:
	print("FINAL SELECTED INDEX: ",selected_index)
	if selected_index == -1:
		return

	var action_name := options[selected_index]
	print("✅ ACTION = ",action_name)
	if action_name == "inventory":
		PlayerStateManager.set_state(PlayerStateManager.State.INVENTORY)
	#match action_name:
		#"map":
			#open_map()
		#"inventory":
			#open_inventory()
		#"collections":
			#open_collections()
		#"journal":
			#open_journal()
	close_wheel()

func update_wheel_visibility(show: bool) -> void:
	if show:
		open_wheel()
	else:
		close_wheel()

func open_wheel() -> void:
	#visible = true
	is_open = true
	selected_index = -1
	PlayerStateManager.set_state(PlayerStateManager.State.MENU_WHEEL)


func close_wheel() -> void:
	#visible = false
	is_open = false
	selected_index = -1
	if PlayerStateManager.is_in_menu_wheel():
		PlayerStateManager.reset()
