extends Resource
class_name QuestCondition

enum Type {
	FRIENDSHIP_AT_LEAST,
	FRIENDSHIP_UNDER,
	#MAJOR_SPIRIT_AWAKENED,   # débloquer quête après avoir réveillé Rivel
	#HAS_ITEM,                # "apporte-moi une recette de soupe"
	#QUEST_COMPLETED,         # chaîne de quêtes
	#TIME_OF_DAY,             # quête disponible seulement la nuit (pour Moute)
}

@export var type: Type
@export var friendship_value: int = 0
