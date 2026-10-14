extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred('run')
func run() -> void:
	var scene = load('res://scenes/main.tscn').instantiate()
	root.add_child(scene)
	await physics_frame
	await physics_frame
	check(scene.rooms.size()==9,'Nine rooms required')
	for id in range(9):
		scene.load_room(id)
		await physics_frame
		await physics_frame
		check(scene.backdrop.texture != null,'Missing plate %d'%id)
		check(scene.foreground.texture != null,'Missing foreground %d'%id)
		check(scene.doors.size()==scene.rooms[id].exits.size(),'Door count mismatch')
		for exit in scene.rooms[id].exits:
			var reverse := false
			for back in scene.rooms[int(exit.target)].exits:
				if int(back.target)==id:
					reverse = true
			check(reverse,'Connection must have a return door')
		var map: RID = scene.player.navigation.get_navigation_map()
		check(NavigationServer3D.map_get_regions(map).size()>0,'No walkable navigation region')
		var before: Vector3 = scene.player.position
		Input.action_press('move_right')
		for tick in range(12):
			await physics_frame
		Input.action_release('move_right')
		check(scene.player.position.x>before.x,'Keyboard movement failed')
		var click_target: Vector3 = scene.normalized_floor([.5,.82])
		var click_distance: float = scene.player.position.distance_to(click_target)
		scene.player.walk_to(click_target)
		for tick in range(30):
			await physics_frame
		check(scene.player.position.y > -.3,'Player fell through floor')
		check(scene.player.position.distance_to(click_target)<click_distance,'Click navigation did not approach its target')
		scene._set_zone(1)
		var center := Vector3.ZERO
		for p in scene.floor_points:
			center += p
		center /= float(scene.floor_points.size())
		check(scene.ground_from_screen(scene.camera.unproject_position(center)).distance_to(center)<.01,'Camera floor projection mismatch')
	scene.load_room(0)
	await physics_frame
	var door = scene.doors[0]
	door.interact()
	await create_timer(1.7).timeout
	check(scene.room_id==1 and not scene.busy,'Normal door transition failed')
	check(scene.player.enabled,'Player not restored after transition')
	scene._update_map()
	check(scene.map_graph.rooms.size()==9,'Area map missing rooms')
	print('GODOT SMOKE: %d failures; 9 rooms, navigation, movement, camera projection, doors and map checked'%failures)
	quit(0 if failures==0 else 1)
