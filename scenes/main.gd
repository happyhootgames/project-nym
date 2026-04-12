extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TranslationServer.set_locale("fr")
	print("Locale : ", TranslationServer.get_locale())
	print("Test : ", tr("DIALOGUE_VIVI_FIRST_MEETING_1"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
