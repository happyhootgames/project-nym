extends Node


# =========================================================
# CONSTANTS
# =========================================================

const DEFAULT_LOCALE := "fr"


# =========================================================
# LIFECYCLE
# =========================================================

func _ready() -> void:
	SaveManager.data_loaded.connect(load_data)


# =========================================================
# PUBLIC API
# =========================================================

# Applies the saved locale, falling back to DEFAULT_LOCALE on first launch.
func load_data() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	var locale: String = settings.get("locale", DEFAULT_LOCALE)
	TranslationServer.set_locale(locale)
	_debug()


# Changes the active locale, persists it immediately to the save file.
func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale)
	SaveManager.data["settings"]["locale"] = locale
	SaveManager.save_game()
	_debug()


# =========================================================
# DEBUG
# =========================================================

func _debug() -> void:
	print_debug("🌐 SettingsManager | locale: %s" % TranslationServer.get_locale())
