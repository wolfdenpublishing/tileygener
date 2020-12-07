extends PanelContainer

onready var save_dialog:FileDialog = Global.controls["SaveDialog"]
var ignore_clicks:bool = false


func _input(event):
	if ignore_clicks:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var sprite:Sprite = clicked_sprite(event)
		if sprite != null:
			ignore_clicks = true
			save_image(sprite)


func clicked_sprite(event:InputEventMouseButton) -> Sprite:
	for sprite in get_children():
		var rect:Rect2 = sprite.get_rect()
		rect.position.x *= sprite.scale.x
		rect.position.y *= sprite.scale.y
		rect.size.x *= sprite.scale.x
		rect.size.y *= sprite.scale.y
		rect.position = sprite.position + rect.position
		if rect.has_point(event.position):
			return sprite
	return null


func save_image(sprite:Sprite) -> void:
	var dt = OS.get_datetime()
	save_dialog.set_meta("sprite", sprite)
	save_dialog.get_line_edit().text = "%04d%02d%02d%02d%02d%02d.png" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
	save_dialog.popup_centered()


func _on_SaveDialog_file_selected(path):
	save_dialog.get_meta("sprite").texture.get_data().save_png(path)


func _on_SaveDialog_popup_hide():
	ignore_clicks = false
