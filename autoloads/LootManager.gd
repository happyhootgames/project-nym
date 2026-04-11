extends Node

var loot_tables: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	#load_loot_tables("res://data/loot/loot_tables.json")

func roll(loot_table_id: StringName) -> Array:
	var results: Array = []

	if not loot_tables.has(loot_table_id):
		push_warning("Loot table inconnue: %s" % loot_table_id)
		return results

	var entries: Array = loot_tables[loot_table_id]

	for entry in entries:
		var chance: float = entry["chance"]
		if rng.randf() > chance:
			continue

		var amount: int = rng.randi_range(entry["min_amount"], entry["max_amount"])
		if amount <= 0:
			continue

		#var item: ItemData = ItemDatabase.get_item(entry["item_id"])
		#if item == null:
			#push_warning("Item introuvable dans loot table %s: %s" % [loot_table_id, entry["item_id"]])
			#continue

		#results.append({
			#"item": item,
			#"amount": amount
		#})

	return results

func load_loot_tables(path: String) -> void:
	loot_tables.clear()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir le fichier de loot: %s" % path)
		return

	var json_text := file.get_as_text()
	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Le JSON de loot doit contenir un dictionnaire racine")
		return

	for loot_table_id in parsed.keys():
		var raw_entries = parsed[loot_table_id]
		if typeof(raw_entries) != TYPE_ARRAY:
			push_warning("Loot table '%s' ignorée: ce n'est pas un tableau" % loot_table_id)
			continue

		var validated_entries: Array = []

		for raw_entry in raw_entries:
			if typeof(raw_entry) != TYPE_DICTIONARY:
				continue

			if not raw_entry.has("item_id"):
				continue

			var entry := {
				"item_id": StringName(raw_entry.get("item_id", "")),
				"chance": clamp(float(raw_entry.get("chance", 1.0)), 0.0, 1.0),
				"min_amount": int(raw_entry.get("min_amount", 1)),
				"max_amount": int(raw_entry.get("max_amount", 1))
			}

			if entry.min_amount > entry.max_amount:
				var tmp = entry.min_amount
				entry.min_amount = entry.max_amount
				entry.max_amount = tmp

			validated_entries.append(entry)

		loot_tables[StringName(loot_table_id)] = validated_entries
