extends Control
var rooms: Array = []
var current := 0
var visited: Dictionary = {}
func _draw() -> void:
	if rooms.is_empty():
		return
	var font := ThemeDB.fallback_font
	for room in rooms:
		var at := Vector2(room.map[0],room.map[1])+Vector2(0,25)
		for exit in room.exits:
			if int(exit.target)>int(room.id):
				var dest: Dictionary = rooms[int(exit.target)]
				draw_line(at+Vector2(100,26),Vector2(dest.map[0],dest.map[1])+Vector2(100,51),Color('#507a79'),2.)
	for room in rooms:
		var at := Vector2(room.map[0],room.map[1])+Vector2(0,25)
		var color := Color('#2d5650') if int(room.id)==current else Color('#203335') if visited.has(int(room.id)) else Color('#151e24')
		draw_style_box(_box(color),Rect2(at,Vector2(200,65)))
		draw_string(font,at+Vector2(8,25),room.name,HORIZONTAL_ALIGNMENT_LEFT,190,16,Color('#cce4df'))
		draw_string(font,at+Vector2(8,49),'YOU ARE HERE' if int(room.id)==current else 'VISITED' if visited.has(int(room.id)) else 'UNEXPLORED',HORIZONTAL_ALIGNMENT_LEFT,190,12,Color('#87b8ad'))
func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color('#658e87')
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	return box
