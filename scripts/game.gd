extends Node3D
const Player = preload('res://scripts/player.gd')
const Door = preload('res://scripts/normal_door.gd')
@export var player_model: PackedScene
var rooms: Array
var room_id := 0
var camera: Camera3D
var player: CharacterBody3D
var room_root: Node3D
var doors: Array[Node3D] = []
var floor_points := PackedVector3Array()
var backdrop: TextureRect
var foreground: TextureRect
var effects: Node2D
var info: Label
var prompt: Label
var fade: ColorRect
var map_panel: PanelContainer
var map_text: Label
var map_graph: Control
var visited := {0: true}
var busy := false
var camera_zone := 0
var zoom := 1.0
var effects_on := true
const SIZE := Vector2(1280,720)

func _ready() -> void:
	_setup_inputs()
	rooms = JSON.parse_string(FileAccess.get_file_as_string('res://data/rooms.json'))
	camera = Camera3D.new()
	camera.position = Vector3(0,7,12)
	add_child(camera)
	camera.look_at(Vector3(0,0,-1))
	camera.fov = 52
	camera.current = true
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color('#a9bccc')
	env.ambient_light_energy = .7
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-30,0)
	sun.light_energy = 1.1
	add_child(sun)
	_make_ui()
	player = Player.new()
	player.model_scene = player_model
	player.camera = camera
	add_child(player)
	load_room(0)

func _setup_inputs() -> void:
	var bindings := {'move_left':[KEY_A,KEY_LEFT], 'move_right':[KEY_D,KEY_RIGHT], 'move_up':[KEY_W,KEY_UP], 'move_down':[KEY_S,KEY_DOWN], 'interact':[KEY_E], 'map':[KEY_M], 'effects':[KEY_F], 'cancel':[KEY_ESCAPE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action,.22)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	for mapping in [['move_left',JOY_AXIS_LEFT_X,-1.],['move_right',JOY_AXIS_LEFT_X,1.],['move_up',JOY_AXIS_LEFT_Y,-1.],['move_down',JOY_AXIS_LEFT_Y,1.]]:
		var event := InputEventJoypadMotion.new()
		event.axis = mapping[1]
		event.axis_value = mapping[2]
		InputMap.action_add_event(mapping[0],event)
	for mapping in [['interact',JOY_BUTTON_A],['map',JOY_BUTTON_BACK],['cancel',JOY_BUTTON_B]]:
		var event := InputEventJoypadButton.new()
		event.button_index = mapping[1]
		InputMap.action_add_event(mapping[0],event)
	# Reserved independent actions for later combat / crafting.
	for action in ['attack','aim','craft','inventory']:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

func _make_ui() -> void:
	var back := CanvasLayer.new()
	back.layer = -10
	add_child(back)
	backdrop = TextureRect.new()
	backdrop.size = SIZE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(backdrop)
	var overlay := CanvasLayer.new()
	overlay.layer = 1
	add_child(overlay)
	foreground = TextureRect.new()
	foreground.size = SIZE
	foreground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(foreground)
	effects = Node2D.new()
	overlay.add_child(effects)
	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	info = Label.new()
	info.position = Vector2(25,22)
	info.add_theme_font_size_override('font_size',23)
	hud.add_child(info)
	prompt = Label.new()
	prompt.position = Vector2(25,635)
	hud.add_child(prompt)
	var controls := Label.new()
	controls.text = 'WASD / arrows / left stick: move   •   Click floor: walk   •   E / A: open door   •   M / Back: map   •   F: effects'
	controls.position = Vector2(25,687)
	hud.add_child(controls)
	map_panel = PanelContainer.new()
	map_panel.position = Vector2(210,100)
	map_panel.size = Vector2(860,510)
	map_panel.visible = false
	hud.add_child(map_panel)
	map_text = Label.new()
	map_text.add_theme_font_size_override('font_size',21)
	map_panel.add_child(map_text)
	map_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	map_graph = preload("res://scripts/area_map.gd").new()
	map_graph.custom_minimum_size = Vector2(850,510)
	map_panel.add_child(map_graph)
	fade = ColorRect.new()
	fade.color = Color(0,0,0,0)
	fade.size = SIZE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(fade)

func ground_from_screen(screen: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	return origin + direction * (-origin.y / direction.y)

func normalized_floor(point: Array) -> Vector3:
	return ground_from_screen(Vector2(point[0],point[1])*SIZE)

func load_room(id: int) -> void:
	if room_root:
		remove_child(room_root)
		room_root.queue_free()
	room_id = id
	camera.fov = 52
	zoom = 1.
	camera_zone = 0
	_scale_plates(1.)
	room_root = Node3D.new()
	room_root.name = 'Room_%02d' % id
	add_child(room_root)
	doors.clear()
	var r: Dictionary = rooms[id]
	backdrop.texture = load(r.plate)
	foreground.texture = load(r.foreground)
	floor_points.clear()
	for point in r.floor:
		floor_points.append(normalized_floor(point))
	_build_floor()
	for exit in r.exits:
		var door := Door.new()
		door.target_room = int(exit.target)
		door.label = exit.label
		room_root.add_child(door)
		door.position = normalized_floor(exit.foot)
		door.entered.connect(_travel)
		doors.append(door)
	player.position = normalized_floor([.50,.88])+Vector3(0,.03,0)
	player.velocity = Vector3.ZERO
	player.moving_to_click = false
	visited[id] = true
	_build_effects(r)
	info.text = 'NIGHTMARE FREQUENCY\n' + r.name

func _build_floor() -> void:
	var shape_2d := PackedVector2Array()
	for point in floor_points:
		shape_2d.append(Vector2(point.x,point.z))
	var indices := Geometry2D.triangulate_polygon(shape_2d)
	var faces := PackedVector3Array()
	var nav := NavigationMesh.new()
	nav.vertices = floor_points
	for i in range(0,indices.size(),3):
		var a := indices[i]
		var b := indices[i+1]
		var c := indices[i+2]
		if (floor_points[b]-floor_points[a]).cross(floor_points[c]-floor_points[a]).y < 0:
			var tmp := b
			b = c
			c = tmp
		faces.append_array(PackedVector3Array([floor_points[a],floor_points[b],floor_points[c]]))
		nav.add_polygon(PackedInt32Array([a,b,c]))
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)
	room_root.add_child(body)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	room_root.add_child(region)
	for i in floor_points.size():
		var a := floor_points[i]
		var b := floor_points[(i+1)%floor_points.size()]
		var wall := StaticBody3D.new()
		var hit := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(.12,2.8,a.distance_to(b))
		hit.shape = box
		wall.add_child(hit)
		room_root.add_child(wall)
		wall.position = (a+b)*.5+Vector3(0,1.4,0)
		wall.look_at(Vector3(b.x,1.4,b.z))

func _build_effects(r: Dictionary) -> void:
	for child in effects.get_children():
		effects.remove_child(child)
		child.queue_free()
	var color := Color('#'+r.color)
	for screen in r.screens:
		var poly := Polygon2D.new()
		var points := PackedVector2Array()
		for p in screen:
			points.append(Vector2(p[0],p[1])*SIZE)
		poly.polygon = points
		var bounds := Rect2(points[0],Vector2.ZERO)
		for p in points:
			bounds = bounds.expand(p)
		var uvs := PackedVector2Array()
		for p in points:
			uvs.append((p-bounds.position)/bounds.size*256.)
		poly.uv = uvs
		var screen_image := Image.create(256,256,false,Image.FORMAT_RGBA8)
		screen_image.fill(Color.WHITE)
		poly.texture = ImageTexture.create_from_image(screen_image)
		var mat := ShaderMaterial.new()
		mat.shader = load('res://shaders/screen_rain.gdshader')
		mat.set_shader_parameter('tint',color)
		poly.material = mat
		effects.add_child(poly)
	var mist := ColorRect.new()
	mist.size = SIZE
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load('res://shaders/mist.gdshader')
	material.set_shader_parameter('tint',color.lerp(Color('#b3c6ce'),.8))
	mist.material = material
	effects.add_child(mist)
	for pos in [Vector2(.18,.22),Vector2(.72,.35)]:
		var light := ColorRect.new()
		light.size = Vector2(210,180)
		light.position = pos*SIZE-light.size*.5
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load('res://shaders/light.gdshader')
		mat.set_shader_parameter('tint',color)
		mat.set_shader_parameter('seed',pos.x*29.)
		light.material = mat
		effects.add_child(light)
	effects.visible = effects_on

func _scale_plates(value: float) -> void:
	for node in [backdrop,foreground,effects]:
		if node:
			node.scale = Vector2.ONE*value
			node.position = SIZE*(1.-value)*.5

func _process(_delta: float) -> void:
	if not player or busy:
		return
	var nearest: Node3D = _nearest_door()
	prompt.text = 'E / A: Open normal door → '+nearest.label if nearest else ''
	if rooms[room_id].hallway:
		# Crop-only camera zones preserve projection; no invented perspective from a still plate.
		var base_fov := camera.fov
		camera.fov = 52
		var screen := camera.unproject_position(player.position)
		camera.fov = base_fov
		if camera_zone == 0 and screen.y < 490:
			_set_zone(1)
		elif camera_zone == 1 and screen.y > 535:
			_set_zone(0)

func _set_zone(zone: int) -> void:
	camera_zone = zone
	zoom = 1.22 if zone == 1 else 1.
	camera.fov = rad_to_deg(2.*atan(tan(deg_to_rad(52.)*.5)/zoom))
	_scale_plates(zoom)

func _nearest_door() -> Node3D:
	var nearest: Node3D = null
	var distance := 2.1
	for door in doors:
		var d := player.position.distance_to(door.position)
		if d < distance:
			distance = d
			nearest = door
	return nearest

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed('cancel'):
		map_panel.hide()
		player.enabled = not busy
	if event.is_action_pressed('map') and not busy:
		map_panel.visible = not map_panel.visible
		player.enabled = not map_panel.visible
		_update_map()
	if busy or map_panel.visible:
		return
	if event.is_action_pressed('effects'):
		effects_on = not effects_on
		effects.visible = effects_on
	if event.is_action_pressed('interact'):
		var door := _nearest_door()
		if door:
			player.enabled = false
			door.interact()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point := ground_from_screen(event.position)
		var shape := PackedVector2Array()
		for p in floor_points:
			shape.append(Vector2(p.x,p.z))
		if Geometry2D.is_point_in_polygon(Vector2(point.x,point.z),shape):
			player.walk_to(point)

func _travel(target: int) -> void:
	if busy:
		return
	busy = true
	player.enabled = false
	var tween := create_tween()
	tween.tween_property(fade,'color:a',1.,.3)
	await tween.finished
	load_room(target)
	await get_tree().physics_frame
	await get_tree().physics_frame
	tween = create_tween()
	tween.tween_property(fade,'color:a',0.,.3)
	await tween.finished
	player.enabled = true
	busy = false

func _update_map() -> void:
	map_text.text = 'MORTALIS CENTRAL / CONNECTED AREA MAP'
	map_graph.rooms = rooms
	map_graph.current = room_id
	map_graph.visited = visited
	map_graph.queue_redraw()
