## Un cuerpo articulado que se anima solo, sin un solo archivo de animación.
##
## Todo sale de senos y cosenos manejados por la velocidad real del personaje.
## Es el enfoque de juegos como Wobbly Life o Human Fall Flat: con formas
## simples y movimiento bien temporizado, el cerebro completa el resto — y se
## ve más vivo que un esqueleto mal riggeado.
##
## Cuatro cosas hacen que se lea como caminar y no como sacudirse:
##  1. Brazos y piernas en CONTRAFASE cruzada (brazo derecho con pierna
##     izquierda). Si van en fase parece que trota un pato.
##  2. El torso sube y baja al DOBLE de frecuencia que los pasos: hay un
##     rebote por pisada, no por ciclo.
##  3. El cuerpo se inclina hacia adelante en proporción a la velocidad.
##  4. Al frenar, la fase se apaga suave en vez de cortarse.
class_name Figura
extends Node3D

var altura := 1.85
var color := Color(0.30, 0.72, 0.62)
var color_piel := Color(0.82, 0.70, 0.56)
var brilla := false

var _torso: Node3D
var _cabeza: Node3D
var _brazo_i: Node3D
var _brazo_d: Node3D
var _pierna_i: Node3D
var _pierna_d: Node3D
var _raiz: Node3D

var _fase := 0.0
var _intensidad := 0.0     ## 0 quieto, 1 caminando: suaviza el arranque y el freno
var _golpe := 0.0          ## 0..1 mientras dura el swing
var _dolor := 0.0


func construir() -> void:
	_raiz = Node3D.new()
	add_child(_raiz)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.72
	if brilla:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3

	var piel := StandardMaterial3D.new()
	piel.albedo_color = color_piel
	piel.roughness = 0.86

	_torso = Node3D.new()
	_torso.position.y = altura * 0.52
	_raiz.add_child(_torso)
	_torso.add_child(_pieza(CapsuleMesh, mat, 0.30, altura * 0.42, Vector3.ZERO))

	_cabeza = Node3D.new()
	_cabeza.position.y = altura * 0.30
	_torso.add_child(_cabeza)
	var esf := SphereMesh.new()
	esf.radius = 0.24
	esf.height = 0.48
	esf.material = piel
	var mc := MeshInstance3D.new()
	mc.mesh = esf
	mc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_cabeza.add_child(mc)

	# Los miembros cuelgan de un pivote en el hombro/cadera, no del centro:
	# así rotan como articulaciones y no como hélices.
	_brazo_i = _miembro(mat, -0.34, altura * 0.16, altura * 0.30, 0.085)
	_brazo_d = _miembro(mat, 0.34, altura * 0.16, altura * 0.30, 0.085)
	_torso.add_child(_brazo_i)
	_torso.add_child(_brazo_d)

	_pierna_i = _miembro(mat, -0.15, -altura * 0.20, altura * 0.32, 0.105)
	_pierna_d = _miembro(mat, 0.15, -altura * 0.20, altura * 0.32, 0.105)
	_torso.add_child(_pierna_i)
	_torso.add_child(_pierna_d)


func _pieza(tipo: Variant, mat: Material, radio: float, alto: float, pos: Vector3) -> MeshInstance3D:
	var m: Mesh
	if tipo == CapsuleMesh:
		var c := CapsuleMesh.new()
		c.radius = radio
		c.height = alto
		c.material = mat
		m = c
	else:
		var b := BoxMesh.new()
		b.size = Vector3(radio * 2, alto, radio * 2)
		b.material = mat
		m = b
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mi


func _miembro(mat: Material, x: float, y: float, largo: float, grosor: float) -> Node3D:
	var pivote := Node3D.new()
	pivote.position = Vector3(x, y, 0)
	var c := CapsuleMesh.new()
	c.radius = grosor
	c.height = largo
	c.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position.y = -largo * 0.5   # cuelga del pivote
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	pivote.add_child(mi)
	return pivote


## Se llama cada cuadro con la velocidad horizontal real del personaje.
func animar(dt: float, velocidad: float, en_piso: bool) -> void:
	if _torso == null:
		return

	var v := clampf(velocidad / 7.5, 0.0, 1.4)
	_intensidad = lerp(_intensidad, v, 9.0 * dt)          # (4) arranque y freno suaves
	_fase += dt * (5.6 + v * 3.4) * clampf(v, 0.15, 1.4)

	var amplitud := _intensidad * 0.85
	var s := sin(_fase)
	var s2 := sin(_fase * 2.0)

	# (1) contrafase cruzada
	_brazo_i.rotation.x = s * amplitud * 0.75
	_brazo_d.rotation.x = -s * amplitud * 0.75
	_pierna_i.rotation.x = -s * amplitud
	_pierna_d.rotation.x = s * amplitud

	# (2) un rebote por pisada, no por ciclo
	_torso.position.y = altura * 0.52 + abs(s2) * 0.055 * _intensidad
	_torso.rotation.z = s * 0.05 * _intensidad

	# (3) inclinación proporcional a la velocidad
	_torso.rotation.x = lerp(_torso.rotation.x, _intensidad * 0.16, 8.0 * dt)

	# La cabeza se estabiliza: mira al frente aunque el torso rebote. Es el
	# detalle que más aporta a que parezca un ser vivo.
	_cabeza.rotation.x = -_torso.rotation.x * 0.7 + sin(_fase * 0.7) * 0.02

	if not en_piso:
		# En el aire: piernas recogidas, brazos arriba.
		_pierna_i.rotation.x = lerp(_pierna_i.rotation.x, -0.7, 10.0 * dt)
		_pierna_d.rotation.x = lerp(_pierna_d.rotation.x, -0.35, 10.0 * dt)
		_brazo_i.rotation.x = lerp(_brazo_i.rotation.x, -1.9, 10.0 * dt)
		_brazo_d.rotation.x = lerp(_brazo_d.rotation.x, -1.9, 10.0 * dt)

	if _golpe > 0.0:
		_golpe = maxf(0.0, _golpe - dt * 3.6)
		# Curva de swing: sube rápido, baja lento. Un seno simple se ve blando.
		var t := 1.0 - _golpe
		var arco: float = sin(t * PI) * (1.0 - t * 0.35)
		_brazo_d.rotation.x = -2.4 * arco
		_torso.rotation.y = -arco * 0.5

	if _dolor > 0.0:
		_dolor = maxf(0.0, _dolor - dt * 4.0)
		_raiz.position.x = sin(_dolor * 55.0) * _dolor * 0.13
		_torso.rotation.x -= _dolor * 0.3
	else:
		_raiz.position.x = 0.0


func atacar() -> void:
	_golpe = 1.0


func doler() -> void:
	_dolor = 1.0


## Se desarma hacia adelante. Sin ragdoll: una caída bien temporizada alcanza.
func caer() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_raiz, "rotation:x", -PI / 2.0 + 0.15, 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(_raiz, "position:y", -0.35, 0.55)
	t.tween_property(_brazo_i, "rotation:x", 1.2, 0.4)
	t.tween_property(_brazo_d, "rotation:x", 0.9, 0.4)
