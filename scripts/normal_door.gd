extends Node3D
signal entered(target: int)
var target_room := 0
var label := ''
var hinge: Node3D
var opened := false
var busy := false

func block(size: Vector3, at: Vector3, color: Color, parent: Node3D) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .9
	m.material_override = mat
	m.position = at
	parent.add_child(m)

func _ready() -> void:
	# Conventional rectangular frame and solid hinged leaf. No portals or sci-fi strips.
	block(Vector3(.12,2.25,.18),Vector3(-.64,1.12,0),Color('#292b2b'),self)
	block(Vector3(.12,2.25,.18),Vector3(.64,1.12,0),Color('#292b2b'),self)
	block(Vector3(1.4,.12,.18),Vector3(0,2.25,0),Color('#292b2b'),self)
	hinge = Node3D.new()
	hinge.position.x = -.56
	add_child(hinge)
	block(Vector3(1.12,2.14,.09),Vector3(.56,1.07,0),Color('#4d4338'),hinge)
	block(Vector3(.76,.66,.035),Vector3(.56,1.57,-.06),Color('#39342e'),hinge)
	block(Vector3(.76,.72,.035),Vector3(.56,.64,-.06),Color('#39342e'),hinge)
	block(Vector3(.12,.035,.07),Vector3(.96,1.02,-.10),Color('#c4b492'),hinge)
	var body := StaticBody3D.new()
	body.name = 'ClosedCollision'
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.12,2.14,.12)
	collision.shape = box
	collision.position = Vector3(0,1.07,0)
	body.add_child(collision)
	add_child(body)

func interact() -> void:
	if busy:
		return
	busy = true
	var tween := create_tween()
	tween.tween_property(hinge,'rotation:y',-PI*.52,.6).set_trans(Tween.TRANS_SINE)
	await tween.finished
	opened = true
	get_node('ClosedCollision').queue_free()
	await get_tree().create_timer(.2).timeout
	entered.emit(target_room)
