extends Node3D

# ===========================================================================
# LA BANQUINA DE LOS BICHOS. Ver `escenas/prueba_fauna.tscn`.
#
# Siete especies en fila con una vara de 1,70 m al lado de cada una. No hay
# valle, no hay servidor y no hay hora: el sol está fijo en el alba, que es
# como se juzga una silueta a contraluz.
# ===========================================================================

## Distancia de la cámara. El piso de zoom del juego son 40 m y el techo 68;
## acá se mira a 22 porque lo que se está juzgando es si la MALLA sirve, no si
## la escena compone. Con `--lejos` se pone a 55, que es donde se juega.
const CERCA := 22.0
const LEJOS := 55.0

## La vara. Una persona de 1,70 m al lado de cada bicho — sin esto no hay forma
## de saber si la alzada de `fauna.gd` está bien puesta.
const VARA := 1.70

const PASO := 4.5


func _ready() -> void:
	_ambiente()
	_suelo()
	var especies := Fauna.ESPECIES.keys()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260817

	var ancho := (especies.size() - 1) * PASO
	for i in especies.size():
		var e: String = especies[i]
		var x := -ancho * 0.5 + i * PASO
		_bicho(e, Vector3(x, 0, 0), rng)
		_vara(Vector3(x - 1.6, 0, 0))

	_encuadrar(ancho)
	_captura()


func _bicho(especie: String, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var n := Kit.escena("quaternius/animales/" + especie)
	if n == null:
		push_warning("PruebaFauna: falta " + especie)
		return
	var alto := 0.0
	for m in _mallas(n):
		if m.mesh != null:
			alto = maxf(alto, m.mesh.get_aabb().size.y)
	var s: float = float(Fauna.ESPECIES[especie]["alzada"]) / maxf(alto, 0.001)
	n.position = pos
	n.scale = Vector3.ONE * s
	n.rotation.y = -PI / 2.0 + 0.35
	add_child(n)

	var ap := _reproductor(n)
	if ap != null and ap.has_animation("Idle"):
		ap.play("Idle")
		ap.advance(rng.randf() * 2.0)

	var etiqueta := Label3D.new()
	etiqueta.text = "%s  %.2f m" % [especie, alto * s]
	etiqueta.position = pos + Vector3(0, VARA + 0.5, 0)
	etiqueta.pixel_size = 0.006
	etiqueta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etiqueta.no_depth_test = true
	add_child(etiqueta)


## Un poste de 1,70 m: la altura de una persona. Es la única referencia que
## importa acá.
func _vara(pos: Vector3) -> void:
	var m := BoxMesh.new()
	m.size = Vector3(0.09, VARA, 0.09)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Paleta.domar(Color(0.86, 0.84, 0.80))
	mat.roughness = 1.0
	m.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos + Vector3(0, VARA * 0.5, 0)
	add_child(mi)


## Lo mínimo: un cielo liso para que haya contraluz y ambiente para que las
## sombras no sean negras. Sin desenfoque y sin niebla — ver el comentario del
## .tscn.
func _ambiente() -> void:
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Paleta.NIEBLA_DIA
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Paleta.LUZ_CIELO
	e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)


func _suelo() -> void:
	var p := PlaneMesh.new()
	p.size = Vector2(160, 160)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Paleta.PASTO
	mat.roughness = 1.0
	p.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = p
	add_child(mi)


func _encuadrar(ancho: float) -> void:
	var d := LEJOS if OS.get_cmdline_user_args().has("--lejos") else CERCA
	var cam := get_node_or_null(^"Camara") as Camera3D
	if cam != null:
		cam.position = Vector3(0, 2.2, d)
		cam.look_at(Vector3(0, 1.0, 0))
	var sol := get_node_or_null(^"Sol") as DirectionalLight3D
	if sol != null:
		sol.position = Vector3(28, 22, 26)
		sol.look_at(Vector3(-6, 0, -8))
		sol.light_color = Paleta.LUZ_ALBA
	var relleno := get_node_or_null(^"Relleno") as DirectionalLight3D
	if relleno != null:
		relleno.position = Vector3(-30, 24, -26)
		relleno.look_at(Vector3(6, 0, 8))
		relleno.light_color = Paleta.LUZ_CIELO
	print("fila de %.1f m, cámara a %.0f m" % [ancho, d])


func _mallas(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for h in n.get_children():
		out.append_array(_mallas(h))
	return out


func _reproductor(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for h in n.get_children():
		var a := _reproductor(h)
		if a != null:
			return a
	return null


func _captura() -> void:
	if not OS.get_cmdline_user_args().has("--captura"):
		return
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://captura.png")
	print("captura guardada")
	get_tree().quit()
