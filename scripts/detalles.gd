## Lo que hace que un blockout parezca un lugar habitado.
##
## Ninguna de estas cosas es "arte" — son primitivas y partículas. Pero son
## las señales que el ojo usa para decidir si mira una maqueta de cajas o un
## pueblo donde vive gente, y cuestan casi nada:
##
##  · VENTANAS QUE BRILLAN. La señal número uno de "acá adentro hay alguien".
##    Una caja con una ventana encendida deja de ser una caja.
##  · HUMO DE CHIMENEA. Movimiento vertical lento = alguien está cocinando.
##  · PASTO Y PIEDRAS. Rompen el plano liso, que es lo que grita "sin terminar".
##  · BICHOS DE LUZ. Movimiento chico y disperso: el cerebro lo lee como vida.
##
## Todo esto es barato POR UNIDAD, y ahí está la trampa: hay 26.000 unidades.
## Lo que sigue está armado para que el motor pueda tirar a la basura lo que no
## se ve, que es la única optimización que no le saca nada al que sí mira. Las
## cantidades y los alcances los ajusta `rendimiento.gd` por los grupos
## "pasto", "piedras", "humo" y "bichos".
class_name Detalles
extends RefCounted

## De cuánto es la baldosa con que se corta el pasto y las piedras. 34 metros
## es más chico que la distancia de dibujado más corta (55 m en calidad baja),
## que es la condición para que ralear por distancia haga algo.
const BALDOSA := 34.0


static func ventanas_y_puerta(casa: MeshInstance3D, ancho: float, alto: float) -> void:
	var luz_mat := StandardMaterial3D.new()
	luz_mat.albedo_color = Color(1.0, 0.78, 0.42)
	luz_mat.emission_enabled = true
	luz_mat.emission = Color(1.0, 0.72, 0.34)
	luz_mat.emission_energy_multiplier = 3.4

	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.16, 0.10, 0.07)
	madera.roughness = 0.95

	# Dos ventanas al frente, apenas salidas de la pared para que capten luz.
	for lado: float in [-0.26, 0.26]:
		var v := BoxMesh.new()
		v.size = Vector3(ancho * 0.20, alto * 0.20, 0.06)
		v.material = luz_mat
		var mi := MeshInstance3D.new()
		mi.mesh = v
		mi.position = Vector3(ancho * lado, alto * 0.12, ancho * 0.46)
		# Al grupo: el ciclo del día las enciende de noche y las baja de día.
		mi.add_to_group("ventanas")
		casa.add_child(mi)

	var p := BoxMesh.new()
	p.size = Vector3(ancho * 0.26, alto * 0.46, 0.07)
	p.material = madera
	var puerta := MeshInstance3D.new()
	puerta.mesh = p
	puerta.position = Vector3(0, -alto * 0.27, ancho * 0.46)
	casa.add_child(puerta)


static func chimenea(padre: Node3D, pos: Vector3, ancho: float) -> void:
	var ladrillo := StandardMaterial3D.new()
	ladrillo.albedo_color = Color(0.24, 0.16, 0.13)
	ladrillo.roughness = 0.98
	var c := BoxMesh.new()
	c.size = Vector3(ancho * 0.22, ancho * 0.55, ancho * 0.22)
	c.material = ladrillo
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = pos
	padre.add_child(mi)

	padre.add_child(_humo(pos + Vector3(0, ancho * 0.4, 0)))


static func _humo(pos: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = 22
	p.lifetime = 5.5
	p.explosiveness = 0.0
	p.randomness = 0.55
	# Por vida y no por profundidad de vista. El orden por profundidad obliga a
	# reordenar las partículas contra la cámara en cada cuadro; el humo sube
	# siempre y su rampa de color termina en transparente, así que el orden de
	# nacimiento ya es el orden correcto y se ve igual.
	p.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	# La caja de visibilidad por default de las partículas es de 8 metros de
	# lado alrededor del emisor. Este humo sube diez metros y el viento lo
	# corre otros diez, así que con la caja por default el motor lo descartaba
	# justo cuando todavía se veía. Declarada bien, el descarte funciona en los
	# dos sentidos: no parpadea, y una chimenea fuera de cámara deja de
	# simularse.
	p.visibility_aabb = AABB(Vector3(-4, -2, -5), Vector3(16, 16, 12))
	p.add_to_group("humo")

	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(0.25, 1, 0.1)
	m.spread = 12.0
	m.initial_velocity_min = 0.5
	m.initial_velocity_max = 1.1
	m.gravity = Vector3(0.35, 0.28, 0)      # el humo sube y lo lleva el viento
	m.scale_min = 0.35
	m.scale_max = 0.8
	# Crece y se disuelve: humo que mantiene el tamaño se ve a pelotas.
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.25))
	curva.add_point(Vector2(0.4, 1.0))
	curva.add_point(Vector2(1, 1.7))
	var ct := CurveTexture.new()
	ct.curve = curva
	m.scale_curve = ct

	var g := Gradient.new()
	g.set_color(0, Color(0.72, 0.70, 0.66, 0.55))
	g.set_color(1, Color(0.80, 0.80, 0.80, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m

	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	var qm := StandardMaterial3D.new()
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	qm.albedo_color = Color(0.75, 0.73, 0.70, 0.5)
	# El humo no recibe sombra. Está arriba del techo, nunca hay nada que se la
	# proyecte, y recibirla cuesta una búsqueda en el atlas por cada píxel de
	# humo — o sea justo donde más sobredibujado hay.
	qm.disable_receive_shadows = true
	q.material = qm
	p.draw_pass_1 = q
	return p


## Pasto en MultiMesh: miles de matas en muy pocas llamadas de dibujo.
##
## Un MultiMesh es una sola caja para el motor: o lo dibuja entero o no lo
## dibuja. Con las 26.000 matas repartidas en 260 metros de diámetro en un solo
## MultiMesh, mirando al norte se dibujaban igual las trece mil que tenías
## atrás. Cortado en baldosas de 34 metros, el descarte por cámara y por
## distancia hace ese trabajo solo — y sesenta y pico de llamadas de dibujo no
## las siente nadie, era mil veces más barato de lo que costaba el problema.
static func pasto(padre: Node3D, alturas: Callable, cantidad: int, radio: float) -> void:
	var hoja := PrismMesh.new()
	hoja.size = Vector3(0.09, 0.42, 0.04)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.40, 0.55, 0.26)
	mat.roughness = 1.0
	# Sin descarte de caras traseras se rasterizaban las 208.000 caras del
	# pasto DOS veces. Eso tiene sentido en un pasto de cartelitos planos, que
	# no tienen "adentro"; acá cada mata es un prisma cerrado y las caras de
	# atrás siempre las tapa la de adelante. Era el doble de trabajo por
	# exactamente el mismo píxel.
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	hoja.material = mat

	var rng := RandomNumberGenerator.new()
	rng.seed = 20260816
	var por_baldosa := _repartir(rng, cantidad, radio, alturas,
		func(t: Transform3D, r: RandomNumberGenerator) -> Transform3D:
			t.origin.y += 0.18
			return t.rotated_local(Vector3.UP, r.randf() * TAU) \
				.scaled_local(Vector3.ONE * r.randf_range(0.7, 1.9)))

	for celda: Vector2i in por_baldosa:
		var lista: Array = por_baldosa[celda]
		var centro := _centro(celda, alturas)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = hoja
		mm.instance_count = lista.size()
		for i in lista.size():
			var t: Transform3D = lista[i]
			t.origin -= centro
			mm.set_instance_transform(i, t)
			# Variar el color mata la sensación de estampado.
			mm.set_instance_color(i,
				Color(0.34, 0.48, 0.22).lerp(Color(0.62, 0.66, 0.32), rng.randf()))

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.add_to_group("pasto")
		padre.add_child(mmi)


static func piedras(padre: Node3D, alturas: Callable, cantidad: int, radio: float) -> void:
	var roca := SphereMesh.new()
	roca.radius = 0.5
	roca.height = 0.7
	roca.radial_segments = 6
	roca.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.34, 0.32)
	mat.roughness = 1.0
	roca.material = mat

	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var por_baldosa := _repartir(rng, cantidad, radio, alturas,
		func(t: Transform3D, r: RandomNumberGenerator) -> Transform3D:
			t.origin.y -= 0.1
			return t.rotated_local(Vector3.UP, r.randf() * TAU).scaled_local(Vector3(
				r.randf_range(0.4, 1.5), r.randf_range(0.3, 0.8), r.randf_range(0.4, 1.5))))

	for celda: Vector2i in por_baldosa:
		var lista: Array = por_baldosa[celda]
		var centro := _centro(celda, alturas)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = roca
		mm.instance_count = lista.size()
		for i in lista.size():
			var t: Transform3D = lista[i]
			t.origin -= centro
			mm.set_instance_transform(i, t)

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.position = centro
		mmi.add_to_group("piedras")
		padre.add_child(mmi)


## Tira `cantidad` puntos en un disco de `radio` y los agrupa por baldosa.
##
## El orden de generación es aleatorio uniforme y NO se altera. Eso es lo que
## después le permite a `rendimiento.gd` ralear el campo con
## `visible_instance_count`: quedarse con las primeras N instancias de cada
## baldosa es quedarse con una muestra uniforme, o sea un pasto más ralo, y no
## con media baldosa pelada.
static func _repartir(rng: RandomNumberGenerator, cantidad: int, radio: float,
		alturas: Callable, armar: Callable) -> Dictionary:
	var salida := {}
	for i in cantidad:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * radio
		var x := cos(a) * r
		var z := sin(a) * r
		var t := Transform3D()
		t.origin = Vector3(x, alturas.call(x, z), z)
		t = armar.call(t, rng)
		var celda := Vector2i(floori(x / BALDOSA), floori(z / BALDOSA))
		if not salida.has(celda):
			salida[celda] = []
		salida[celda].append(t)
	return salida


## El centro de la baldosa, apoyado en el terreno. Que el nodo esté ahí y no en
## el origen del valle es la mitad del asunto: la distancia de dibujado se mide
## contra la posición del nodo, y un nodo en (0,0,0) que abarca 260 metros
## nunca está lejos de la cámara.
static func _centro(celda: Vector2i, alturas: Callable) -> Vector3:
	var x := (float(celda.x) + 0.5) * BALDOSA
	var z := (float(celda.y) + 0.5) * BALDOSA
	return Vector3(x, alturas.call(x, z), z)


## Bichos de luz. Movimiento chico y disperso: es lo que el ojo lee como
## "acá pasa algo" incluso cuando no pasa nada.
static func luciernagas(padre: Node3D, pos: Vector3, cantidad: int, radio: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = cantidad
	p.lifetime = 7.0
	p.randomness = 1.0
	# Cuatro segundos de simulación adelantada al nacer, para que no aparezcan
	# todas juntas en el mismo punto. Se paga una sola vez, al arrancar.
	p.preprocess = 4.0
	# Igual que con el humo: sin declarar la caja, el motor usa 8 metros de
	# lado y estas nubes miden hasta 26. Declarada, una nube en el Sotobosque
	# deja de simularse cuando estás en la aldea.
	p.visibility_aabb = AABB(Vector3.ONE * -(radio + 4.0), Vector3.ONE * (radio + 4.0) * 2.0)
	p.add_to_group("bichos")

	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = radio
	m.direction = Vector3(0, 1, 0)
	m.spread = 180.0
	m.initial_velocity_min = 0.15
	m.initial_velocity_max = 0.55
	m.gravity = Vector3.ZERO
	m.damping_min = 0.2
	m.damping_max = 0.6
	m.scale_min = 0.5
	m.scale_max = 1.3

	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.35, 0.0))
	g.add_point(0.3, Color(1.0, 0.88, 0.45, 1.0))
	g.add_point(0.7, Color(1.0, 0.80, 0.35, 1.0))
	g.set_color(1, Color(1.0, 0.75, 0.30, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m

	var q := QuadMesh.new()
	q.size = Vector2(0.11, 0.11)
	var qm := StandardMaterial3D.new()
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.vertex_color_use_as_albedo = true
	qm.emission_enabled = true
	qm.emission = Color(1.0, 0.82, 0.38)
	qm.emission_energy_multiplier = 6.0
	q.material = qm
	p.draw_pass_1 = q
	padre.add_child(p)
	return p
