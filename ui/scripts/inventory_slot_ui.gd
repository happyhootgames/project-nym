extends PanelContainer
class_name InventorySlotUI

@export var icon_texture_rect: TextureRect
@export var quantity_label: Label

@export var normal_style: StyleBox
@export var selected_style: StyleBox

func setup(item: ItemData, quantity: int) -> void:
	if item == null:
		return
	_update_focus_visual()
	icon_texture_rect.texture = item.icon
	quantity_label.text = str(quantity)

	if quantity <= 1:
		quantity_label.visible = false
	else:
		quantity_label.visible = true

	tooltip_text = item.display_name
	if quantity > 1:
		tooltip_text += " x%s" % quantity

func _update_focus_visual() -> void:
	if has_focus():
		create_tween().tween_property(self, "scale", Vector2(1.03, 1.03), 0.05)
		add_theme_stylebox_override("panel", selected_style)
	else:
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)
		add_theme_stylebox_override("panel", normal_style)


func _on_focus_entered() -> void:
	_update_focus_visual()


func _on_focus_exited() -> void:
	_update_focus_visual()
