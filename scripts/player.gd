extends CharacterBody3D
## Camera-relative movement; NavigationAgent3D is used only for optional click movement.
@export var model_scene: PackedScene
@export var speed := 2.8
var camera: Camera3D
var navigation: NavigationAgent3D
var visual: Node3D
var moving_to_click := false
var enabled := true
var clock := 0.0
var limbs: Array[Node3D] = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	navigation = NavigationAgent3D.new()
	navigation.path_desired_distance = 0.15
	navigation.target_desired_distance = 0.2
	add_child(navigation)
	visual = Node3D.new()
	add_child(visual)
	if model_scene:
		visual.add_child(model_scene.instantiate())
	else:
		_build_test_rig()

func piece(size: Vector3, at: Vector3, color: Color, parent: Node3D = visual) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	part.material_override = mat
	part.position = at
	parent.add_child(part)
	return part

func _build_test_rig() -> void:
	piece(Vector3(.42,.53,.25),Vector3(0,1.15,0),Color('#303d49'))
	piece(Vector3(.22,.25,.22),Vector3(0,1.57,0),Color('#ac9181'))
	piece(Vector3(.24,.08,.23),Vector3(0,1.72,0),Color('#161c22'))
	piece(Vector3(.34,.17,.26),Vector3(0,.81,0),Color('#202733'))
	for side in [-1,1]:
		var arm := Node3D.new()
		arm.position = Vector3(side*.29,1.35,0)
		visual.add_child(arm)
		piece(Vector3(.13,.56,.14),Vector3(0,-.24,0),Color('#37444e'),arm)
		limbs.append(arm)
		var leg := Node3D.new()
		leg.position = Vector3(side*.11,.78,0)
		visual.add_child(leg)
		piece(Vector3(.17,.65,.18),Vector3(0,-.32,0),Color('#1a222c'),leg)
		piece(Vector3(.19,.12,.31),Vector3(0,-.71,-.05),Color('#11171c'),leg)
		limbs.append(leg)

func walk_to(point: Vector3) -> void:
	navigation.target_position = point
	moving_to_click = true

func _physics_process(delta: float) -> void:
	if not enabled or not camera:
		velocity = Vector3.ZERO
		return
	var stick := Input.get_vector('move_left','move_right','move_up','move_down',0.22)
	var right := camera.global_basis.x
	var forward := -camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var direction := right * stick.x - forward * stick.y
	if stick.length() > 0.05:
		moving_to_click = false
	elif moving_to_click and not navigation.is_navigation_finished():
		direction = navigation.get_next_path_position() - global_position
		direction.y = 0
		if direction.length() > 0.05:
			direction = direction.normalized()
	else:
		moving_to_click = false
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= 18.0 * delta
	move_and_slide()
	if direction.length() > .05:
		visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),delta*12.)
		clock += delta * 9.0
		for i in limbs.size():
			limbs[i].rotation.x = sin(clock + float(i % 2) * PI) * .35
	else:
		for limb in limbs:
			limb.rotation.x = lerp(limb.rotation.x,0.,delta*12.)
