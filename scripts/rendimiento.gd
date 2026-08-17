## Que el juego ande en la máquina de cualquiera.
##
## El pedido fue textual: "no puede matarte la PC más que el Dota 2". Y tiene
## razón: esto es un valle de cajas visto desde veintisiete metros. No hay
## ninguna razón física para que pese. Lo que pesaba no era la geometría —
## eran seis efectos de pantalla completa prendidos todos juntos, un atlas de
## sombras de 8192 (268 MB de textura de profundidad, más de lo que tiene
## entera una placa integrada) y veintiséis mil matas de pasto que se dibujaban
## aunque estuvieran atrás tuyo.
##
## Por qué un ajuste de calidad y no una sola configuración "buena": porque no
## existe una sola. La misma escena tiene que correr en una placa dedicada y en
## el Intel integrado de una notebook de oficina, y entre esas dos hay un factor
## de veinte. Un juego que quiere correr en cualquier lado elige; no promedia.
##
## LA REGLA PARA REPARTIR. La identidad visual no es negociable, así que
## sobrevive en los tres niveles; lo que se cae es lo que cuesta más de lo que
## aporta.
##
##   en los TRES  · sol cálido y sombras largas
##                · brillo de la fragua y de las ventanas encendidas
##                · niebla de distancia y la cordillera azulada del fondo
##                · humo de chimenea y luciérnagas
##   se cae en MEDIO · oclusión ambiental, reflejos del río, la sombra que
##                     proyecta la fragua
##   se cae en BAJO  · iluminación global (SDFGI) y niebla volumétrica, que son
##                     los dos efectos más caros que tiene Godot
##
## En BAJO se pierde el rebote de luz cálida. Es una pérdida real y se
## compensa a medias subiendo la exposición: no es lo mismo, y por eso BAJO es
## el último recurso y no el default.
##
## F1 cambia de nivel · F3 muestra el contador (F2 ya es la captura de
## pantalla, ver jugador.gd) · `--calidad=alto|medio|bajo`
## desde la línea de comandos · `--censo` imprime el inventario de la escena y
## sale.
##
## Es un autoload (ver project.godot). Por eso NO tiene `class_name`: un
## autoload y una clase global con el mismo nombre chocan al parsear.
extends Node

const BAJO := 0
const MEDIO := 1
const ALTO := 2
const NOMBRES: Array[String] = ["bajo", "medio", "alto"]

const ARCHIVO := "user://rendimiento.json"

## El nivel activo. Lo leen `ambiente.gd` y `detalles.gd`.
var nivel := ALTO

var _entorno: Environment
var _camara: CameraAttributesPractical
var _capa: CanvasLayer
var _cartel: Label
var _contador: Label
var _reloj := 0.0
var _atlas := 4096


func _ready() -> void:
	_esconder_la_ventana()
	_elegir_nivel()
	_armar_cartel()
	_aplicar_global()
	# La escena principal todavía no existe: los autoloads entran al árbol
	# antes. Lo que hay que tocar nodo por nodo —el sol, la fragua, el pasto—
	# se retoca cuando el valle ya está armado.
	await get_tree().process_frame
	_aplicar_escena()
	if _pidieron("--censo"):
		await get_tree().create_timer(2.0).timeout
		censo()
		get_tree().quit()


# ---------------------------------------------------------------------------
# Qué nivel corre
# ---------------------------------------------------------------------------

func _elegir_nivel() -> void:
	# 1) La línea de comandos gana siempre. Es lo que hace que una captura de
	#    verificación muestre el look de verdad y no lo que adivinó la máquina.
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--calidad="):
			var n := NOMBRES.find(arg.substr(10).strip_edges().to_lower())
			if n >= 0:
				nivel = n
				print("[rendimiento] nivel %s (pedido por línea de comandos)" % NOMBRES[nivel])
				return
	# 2) `--captura` es la verificación visual del proyecto: siempre en alto, o
	#    estaríamos juzgando el look por una captura degradada.
	if _pidieron("--captura"):
		nivel = ALTO
		return
	# 3) Lo que eligió el jugador la última vez.
	if FileAccess.file_exists(ARCHIVO):
		var f := FileAccess.open(ARCHIVO, FileAccess.READ)
		var j: Variant = JSON.parse_string(f.get_as_text())
		if j is Dictionary and (j as Dictionary).has("nivel"):
			nivel = clampi(int((j as Dictionary)["nivel"]), BAJO, ALTO)
			return
	# 4) Primera vez: se mira qué placa hay.
	#
	#    Ojo con confundir esto con "apagar SDFGI porque en WSL se ve mal", que
	#    es una trampa ya pisada y anotada en CLAUDE.md. No es eso. Acá lo que
	#    se detecta es que NO HAY PLACA: llvmpipe rasteriza en el procesador y
	#    SDFGI ahí no se ve mal, tarda segundos por cuadro. En una máquina con
	#    GPU de verdad esta rama nunca se toma y el default es alto.
	var tipo := RenderingServer.get_video_adapter_type()
	if tipo == RenderingDevice.DEVICE_TYPE_CPU:
		nivel = BAJO
	elif tipo == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU or tipo == RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU:
		nivel = MEDIO
	else:
		nivel = ALTO
	print("[rendimiento] primera vez: %s en %s — F1 lo cambia" % [
		NOMBRES[nivel], RenderingServer.get_video_adapter_name()])


## Con `--captura`, la ventana se va fuera de la pantalla.
##
## **Esto está en código y no en una convención porque una convención no
## alcanzó.** Godot en `--headless` no rasteriza —el shader del cielo ni se
## compila—, así que para juzgar el look hay que abrir una ventana de verdad, y
## bajo WSLg esa ventana aparece en el escritorio de Windows y se roba el foco.
## Quien está jugando a otra cosa se come el salto, y pasó: *"me seguís
## pisando"*, con una captura del juego encima de una partida.
##
## Hay un `mirar.sh` que ya lo hacía con `--position`, pero cualquiera que corra
## `godot --display-driver x11 ... --captura` a mano —y son cuatro agentes en
## paralelo— vuelve a abrir la ventana encima. Acá no hay forma de olvidarse.
##
## No hay Xvfb en esta máquina; el día que lo haya, esto se reemplaza por
## `xvfb-run` y el número mágico se borra.
func _esconder_la_ventana() -> void:
	if not _pidieron("--captura"):
		return
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_position(Vector2i(9000, 9000))


func _pidieron(bandera: String) -> bool:
	return OS.get_cmdline_user_args().has(bandera) or OS.get_cmdline_args().has(bandera)


func _guardar() -> void:
	var f := FileAccess.open(ARCHIVO, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"nivel": nivel}))


func ciclar() -> void:
	nivel = (nivel + 1) % 3
	_guardar()
	_aplicar_global()
	_aplicar_escena()
	_aplicar_entorno()
	_avisar("calidad: %s" % NOMBRES[nivel])


# ---------------------------------------------------------------------------
# El entorno. Lo registra ambiente.gd apenas lo construye.
# ---------------------------------------------------------------------------

## `ambiente.gd` arma el entorno con el look de ALTO —esa es su identidad y
## tiene que estar escrita en un solo lugar— y después pasa por acá, que es
## quien lo baja si hace falta.
func registrar_entorno(e: Environment, c: CameraAttributesPractical) -> void:
	_entorno = e
	_camara = c
	_aplicar_entorno()


func _aplicar_entorno() -> void:
	if _entorno == null:
		return
	var e := _entorno

	# ILUMINACIÓN GLOBAL. Es lo más caro de Godot y es también lo que separa
	# "3D de asset store" de esto, así que no se apaga: se pone a dieta.
	#
	#  · Dos cascadas en vez de cuatro. Con celdas de 0,7 m la segunda cascada
	#    llega a 90 metros (0,7 × 64 × 2), que es donde el desenfoque de
	#    lejanía ya volvió todo puré. Las cuatro cascadas de antes llegaban a
	#    102 m: doce metros más de alcance por el doble de trabajo.
	#  · Sin oclusión. La documentación de Godot dice que sirve para interiores
	#    con paredes finas donde se filtra la luz; esto es un valle a cielo
	#    abierto.
	#  · Escala Y al 50%: el valle es plano y ancho, así que achatar la
	#    cascada le hace cubrir más suelo con los mismos vóxeles.
	#  · El rebote (bounce_feedback) se queda. ES la luz cálida en las paredes.
	e.sdfgi_enabled = nivel >= MEDIO
	e.sdfgi_use_occlusion = false
	e.sdfgi_cascades = 2
	e.sdfgi_min_cell_size = 0.7 if nivel == ALTO else 1.0
	e.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_50_PERCENT
	e.sdfgi_bounce_feedback = 0.5

	# NIEBLA VOLUMÉTRICA. Los rayos de sol entre los árboles se quedan, pero
	# recortados hasta donde arranca la niebla de distancia (130 m): más allá
	# de ahí las dos se pisaban y sólo pagábamos la volumétrica dos veces.
	e.volumetric_fog_enabled = nivel >= MEDIO
	e.volumetric_fog_length = 130.0 if nivel == ALTO else 100.0
	# Inyectar la GI en la niebla es una lectura de SDFGI por vóxel de humo.
	# A 1,0 el rayo de sol sigue estando; a 1,4 casi no se distinguía.
	e.volumetric_fog_gi_inject = 1.0 if nivel == ALTO else 0.0

	# OCLUSIÓN AMBIENTAL. La primera en caerse, y no por capricho: a 27 metros
	# con FOV 42° un radio de 1,4 m son tres píxeles de sombra en un rincón, y
	# el rebote de SDFGI ya oscurece esos mismos rincones.
	e.ssao_enabled = nivel == ALTO

	# REFLEJOS EN PANTALLA. Sirven para una sola superficie del juego —el río—
	# pero el motor los calcula sobre la pantalla entera. 24 pasos alcanzan de
	# sobra para un reflejo de 15 metros de ancho visto de lejos.
	e.ssr_enabled = nivel == ALTO
	e.ssr_max_steps = 24

	# LA CORRECCIÓN DE COLOR NO SE DECIDE ACÁ. Este renglón decía
	# `e.adjustment_enabled = false` en los tres niveles, con el argumento de
	# que el grade era +2% de saturación y +4% de contraste, o sea nada.
	#
	# El argumento era razonable y la línea igual estaba mal, por la regla de
	# abajo: **quién decide si un efecto existe es `ambiente.gd`.** El costo de
	# tenerla acá no fue el 2%: fue que el bloque de grade de `ambiente.gd` pasó
	# a ser código muerto sin que lo dijera nada, y alguien perdió una tarde
	# moviendo la saturación de 1,38 a 0,85 y midiendo capturas idénticas píxel
	# a píxel. **Una propiedad que un archivo escribe y otro pisa en silencio no
	# cuesta el efecto, cuesta la próxima medición.**
	#
	# Lo que sí es de este archivo es el COSTO: el grade prende una variante más
	# de shader, y en BAJO no se paga.
	if nivel == BAJO:
		e.adjustment_enabled = false

	# En BAJO se fue el rebote de luz. Sin compensar, el valle queda plano y
	# más oscuro de lo que era. Se sube la exposición un 8%: no reemplaza la
	# luz indirecta, pero evita que apagar SDFGI se lea como "se rompió algo".
	# Va por exposición y no por luz ambiente porque ciclo.gd reescribe la luz
	# ambiente en cada cuadro y pisaría el ajuste.
	#
	# **Y va sólo en BAJO.** Estaba escrito sin condición, así que los tres
	# niveles corrían a 0,95 y la exposición de `ambiente.gd` —1,02— no llegaba
	# a la pantalla nunca. La compensación de una cosa que sólo pasa en BAJO no
	# puede aplicarse en ALTO: ahí no hay nada que compensar.
	if nivel == BAJO:
		e.tonemap_exposure = 0.95

	# EL DESENFOQUE DE LEJOS TAMPOCO SE DECIDE ACÁ, y esta línea era la
	# tercera del mismo error. Decía `_camara.dof_blur_far_enabled = true`
	# en los tres niveles, con el argumento de que el efecto maqueta es la
	# identidad del juego.
	#
	# Ese argumento se cayó entero: el efecto maqueta ES el reclamo. El
	# dueño del proyecto viene diciendo *"parece de juguete"*, *"muy de
	# torta"*, y una maqueta es literalmente un juguete. Lo apaga
	# `ambiente.gd`, con la medición al lado; acá lo único que queda es
	# CÓMO se calcularía si estuviera prendido (forma de bokeh y calidad,
	# en `_aplicar_global`), que es lo que este archivo sí decide.
	#
	# El de CERCA no se toca desde acá, y este renglón es la corrección de
	# un bug que borroneaba el juego entero.
	#
	# Decía `= true`, con el argumento de que un tilt-shift sin desenfoque
	# de cerca deja de leerse como maqueta. `ambiente.gd` lo había apagado
	# a propósito, con su motivo escrito al lado: con la cámara a cuarenta
	# metros no hay NADA entre ella y el jugador que valga la pena
	# desenfocar. Dos archivos opinando distinto sobre la misma propiedad,
	# y ganaba éste por correr último.
	#
	# El resultado no era una diferencia de gusto: **la escena entera salía
	# borrosa**, casas a cuarenta metros incluidas. Se aisló con dos
	# capturas y una sola variable —prendido: mancha; apagado: nítido— y
	# antes se habían descartado con el mismo método el nivel de calidad y
	# el desenfoque de lejos, que empieza a 95 m cuando la cámara llega a
	# 68 y por lo tanto no podía ser.
	#
	# La regla que sale de acá: **un archivo de rendimiento decide CÓMO se
	# calcula un efecto, no si existe.** El qué es de `ambiente.gd`.


# ---------------------------------------------------------------------------
# Lo global: viewport, sombras, resolución. No depende de ningún nodo.
# ---------------------------------------------------------------------------

func _aplicar_global() -> void:
	var vp := get_viewport()
	if vp != null:
		# Resolución interna. En BAJO se renderiza el 3D al 75% y lo reescala
		# FSR; la interfaz sigue nítida porque scaling_3d no la toca. Es la
		# palanca más grande que existe y la única que da un 2x de una.
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if nivel == BAJO else Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = 0.75 if nivel == BAJO else 1.0
		vp.fsr_sharpness = 0.25
		# MSAA 4x costaba ancho de banda y un resolve de profundidad por cuadro
		# para SSAO, SSR y SDFGI. Con FXAA encima, la diferencia entre 4x y 2x
		# en una escena de cajas planas no se ve.
		vp.msaa_3d = Viewport.MSAA_2X if nivel == ALTO else Viewport.MSAA_DISABLED
		vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	# SOMBRAS DIRECCIONALES. Estaban en 8192: son 268 MB de textura de
	# profundidad, más VRAM de la que tiene entera una placa integrada, y con
	# cuatro divisiones cada una usaba 4096². A 4096 el sol sigue dando 8 cm
	# por téxel cerca del jugador, que es más fino que cualquier cosa que haya
	# en la escena.
	_atlas = int([1024, 2048, 4096][nivel])
	RenderingServer.directional_shadow_atlas_set_size(_atlas, true)
	RenderingServer.directional_soft_shadow_filter_set_quality([
		RenderingServer.SHADOW_QUALITY_HARD,
		RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM,
	][nivel])
	RenderingServer.positional_soft_shadow_filter_set_quality([
		RenderingServer.SHADOW_QUALITY_HARD,
		RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		RenderingServer.SHADOW_QUALITY_SOFT_LOW,
	][nivel])

	# GI a media resolución: la luz indirecta es de baja frecuencia por
	# naturaleza, no hay detalle que perder, y el buffer pasa a costar un
	# cuarto.
	RenderingServer.gi_set_use_half_resolution(true)
	RenderingServer.environment_set_sdfgi_ray_count(
		RenderingServer.ENV_SDFGI_RAY_COUNT_32 if nivel == ALTO
		else RenderingServer.ENV_SDFGI_RAY_COUNT_16)
	# Esto es regalado en ESTE juego en particular: el sol da una vuelta cada
	# seis horas reales, o sea 0,017 grados por segundo. Refrescar la luz de
	# SDFGI cada 16 cuadros en vez de cada 4 divide su costo por cuatro y es
	# literalmente imposible de notar con un sol que se mueve así de despacio.
	RenderingServer.environment_set_sdfgi_frames_to_update_light(
		RenderingServer.ENV_SDFGI_UPDATE_LIGHT_IN_16_FRAMES)
	RenderingServer.environment_set_sdfgi_frames_to_converge(
		RenderingServer.ENV_SDFGI_CONVERGE_IN_30_FRAMES)

	# La rejilla de la niebla volumétrica estaba en 128×128×96: un millón y
	# medio de vóxeles, seis veces el default de Godot, para una niebla suave
	# sin un solo borde duro. 64³ es un sexto del trabajo y se ve igual.
	RenderingServer.environment_set_volumetric_fog_volume_size(
		64 if nivel == ALTO else 48, 64 if nivel == ALTO else 48)

	# El desenfoque de lejanía con bokeh de CAJA es un blur separable de dos
	# pasadas; con bokeh CIRCULAR (el default) es un muestreo radial mucho más
	# caro. Con un blur de 0,09 —el que usa el juego— la forma del bokeh no se
	# distingue ni con lupa. Es el ejemplo más limpio de esta pasada: el mismo
	# efecto, la misma identidad, una fracción del costo.
	RenderingServer.camera_attributes_set_dof_blur_bokeh_shape(
		RenderingServer.DOF_BOKEH_BOX)
	RenderingServer.camera_attributes_set_dof_blur_quality(
		RenderingServer.DOF_BLUR_QUALITY_LOW if nivel == ALTO
		else RenderingServer.DOF_BLUR_QUALITY_VERY_LOW, false)


# ---------------------------------------------------------------------------
# Lo que hay que ir a buscar al árbol
# ---------------------------------------------------------------------------

func _aplicar_escena() -> void:
	var raiz := get_tree().current_scene
	if raiz == null:
		return

	# El sol. No lo busco por nombre porque valle.gd lo arma por código sin
	# ponerle uno; lo reconozco por ser la direccional que proyecta sombra (la
	# otra, el relleno frío, tiene shadow_enabled en false).
	for luz in _buscar(raiz, "DirectionalLight3D"):
		var d := luz as DirectionalLight3D
		if not d.has_meta("sombra_original"):
			d.set_meta("sombra_original", d.shadow_enabled)
			d.set_meta("distancia_original", d.directional_shadow_max_distance)
		if not bool(d.get_meta("sombra_original")):
			continue
		# Cuatro divisiones son cuatro dibujados de todo lo que hace sombra.
		# Dos alcanzan cuando el desenfoque empieza a los 40 metros.
		d.directional_shadow_mode = (DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			if nivel == ALTO else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS)
		# Menos distancia no es sólo menos objetos: es más téxeles por metro
		# cerca del jugador, que es donde se miran las sombras.
		d.directional_shadow_max_distance = float([110.0, 170.0,
			float(d.get_meta("distancia_original"))][nivel])

	# La fragua. Una omni con sombra es un cubemap: seis dibujados de todo lo
	# que haya en 26 metros, y encima parpadea. Es la mejor postal del juego,
	# así que se queda en ALTO y se cae abajo — la luz naranja titilando sigue
	# estando, lo que se pierde es la sombra que proyecta.
	for luz in _buscar(raiz, "OmniLight3D") + _buscar(raiz, "SpotLight3D"):
		var o := luz as Light3D
		if not o.has_meta("sombra_original"):
			o.set_meta("sombra_original", o.shadow_enabled)
		o.shadow_enabled = bool(o.get_meta("sombra_original")) and nivel == ALTO

	# El pasto. No se rehace la geometría: `visible_instance_count` dibuja las
	# primeras N matas del buffer y el buffer se generó en orden aleatorio
	# uniforme, así que quedarse con la mitad es exactamente ralear el campo a
	# la mitad, sin huecos ni parches.
	var f_pasto: float = [0.30, 0.60, 1.0][nivel]
	var d_pasto: float = [55.0, 80.0, 100.0][nivel]
	for n in get_tree().get_nodes_in_group("pasto"):
		var mmi := n as MultiMeshInstance3D
		mmi.multimesh.visible_instance_count = maxi(1,
			int(mmi.multimesh.instance_count * f_pasto))
		_alcance(mmi, d_pasto, 30.0)

	var d_piedra: float = [90.0, 120.0, 150.0][nivel]
	for n in get_tree().get_nodes_in_group("piedras"):
		var mmi := n as MultiMeshInstance3D
		# Una piedra de medio metro a treinta de distancia proyecta una sombra
		# de dos píxeles. En ALTO se paga porque asienta las piedras en el
		# suelo; abajo no vale 320 objetos más en cada división del atlas.
		mmi.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_ON if nivel == ALTO
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		_alcance(mmi, d_piedra, 40.0)

	# El humo. Es transparente y superpuesto, o sea sobredibujado puro: cada
	# píxel de humo se pinta tantas veces como partículas haya apiladas ahí.
	# Bajar de 22 a 8 por chimenea no cambia la lectura ("alguien está
	# cocinando") y divide el sobredibujado por tres.
	var humo: int = [8, 14, 22][nivel]
	var d_humo: float = [70.0, 100.0, 130.0][nivel]
	for n in get_tree().get_nodes_in_group("humo"):
		var p := n as GPUParticles3D
		if p.amount != humo:
			p.amount = humo
		_alcance(p, d_humo, 25.0)

	var f_bichos: float = [0.45, 0.70, 1.0][nivel]
	for n in get_tree().get_nodes_in_group("bichos"):
		var p := n as GPUParticles3D
		var base := int(p.get_meta("cantidad_original", p.amount))
		p.set_meta("cantidad_original", base)
		var q := maxi(6, int(base * f_bichos))
		if p.amount != q:
			p.amount = q
		_alcance(p, float([70.0, 100.0, 140.0][nivel]), 25.0)


func _alcance(g: GeometryInstance3D, hasta: float, margen: float) -> void:
	g.visibility_range_end = hasta
	g.visibility_range_end_margin = margen
	# Se desvanece en vez de aparecer de golpe: una baldosa de pasto de 34
	# metros apareciendo entera se ve, aunque esté detrás del desenfoque.
	g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


func _buscar(desde: Node, clase: String) -> Array[Node]:
	var salida: Array[Node] = []
	var pila: Array[Node] = [desde]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		if n.is_class(clase):
			salida.append(n)
		for c in n.get_children():
			pila.append(c)
	return salida


# ---------------------------------------------------------------------------
# Teclas y cartel
# ---------------------------------------------------------------------------

func _armar_cartel() -> void:
	_capa = CanvasLayer.new()
	_capa.layer = 100
	add_child(_capa)

	_cartel = Label.new()
	_cartel.anchor_left = 0.5; _cartel.anchor_right = 0.5
	_cartel.anchor_top = 1.0; _cartel.anchor_bottom = 1.0
	_cartel.offset_left = -200; _cartel.offset_right = 200; _cartel.offset_top = -120
	_cartel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cartel.add_theme_font_size_override("font_size", 16)
	_cartel.add_theme_color_override("font_color", Color(0.72, 0.80, 0.76))
	_cartel.modulate.a = 0.0
	_capa.add_child(_cartel)

	# El contador. Existe para poder contestar "¿mejoró?" con un número y no
	# con una sensación — que es justo lo que no se puede hacer desde WSL.
	_contador = Label.new()
	_contador.anchor_left = 1.0; _contador.anchor_right = 1.0
	_contador.offset_left = -300; _contador.offset_right = -16; _contador.offset_top = 16
	_contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_contador.add_theme_font_size_override("font_size", 13)
	_contador.add_theme_color_override("font_color", Color(0.55, 0.85, 0.72))
	_contador.visible = false
	_capa.add_child(_contador)


func _avisar(texto: String) -> void:
	_cartel.text = texto
	_cartel.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(_cartel, "modulate:a", 0.0, 0.7)


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento is InputEventKey) or not evento.is_pressed() or evento.is_echo():
		return
	match (evento as InputEventKey).keycode:
		KEY_F1:
			ciclar()
			get_viewport().set_input_as_handled()
		KEY_F3:
			_contador.visible = not _contador.visible
			get_viewport().set_input_as_handled()


func _process(dt: float) -> void:
	if not _contador.visible:
		return
	# Cuatro veces por segundo: un contador que se refresca cada cuadro es
	# ilegible y encima miente sobre su propio costo.
	_reloj += dt
	if _reloj < 0.25:
		return
	_reloj = 0.0
	_contador.text = "%s · %d fps · %d llamadas · %d k prim · %d objetos" % [
		NOMBRES[nivel],
		Engine.get_frames_per_second(),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	]


# ---------------------------------------------------------------------------
# El censo
# ---------------------------------------------------------------------------

## Cuenta lo que hay en la escena. Se corre con `--censo` y sirve para lo que
## en WSL no se puede hacer de otra forma: comparar un antes y un después con
## números en vez de con impresiones, porque acá no hay GPU y los cuadros por
## segundo que se midan son basura.
func censo() -> void:
	var raiz := get_tree().current_scene
	if raiz == null:
		return
	var mi := 0; var tris := 0
	var mmi := 0; var mm_total := 0; var mm_vis := 0; var mm_tris := 0
	var par := 0; var par_amt := 0
	var luces := 0; var sombras := 0; var nodos := 0
	var pila: Array[Node] = [raiz]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		nodos += 1
		for c in n.get_children():
			pila.append(c)
		if n is MultiMeshInstance3D:
			mmi += 1
			var m := (n as MultiMeshInstance3D).multimesh
			if m == null:
				continue
			var v: int = m.instance_count if m.visible_instance_count < 0 else m.visible_instance_count
			mm_total += m.instance_count
			mm_vis += v
			mm_tris += _triangulos(m.mesh) * v
		elif n is MeshInstance3D:
			mi += 1
			tris += _triangulos((n as MeshInstance3D).mesh)
		elif n is GPUParticles3D:
			par += 1
			par_amt += (n as GPUParticles3D).amount
		elif n is Light3D:
			luces += 1
			if (n as Light3D).shadow_enabled:
				sombras += 1

	var e := _entorno
	var prendidos: Array[String] = []
	if e != null:
		if e.sdfgi_enabled: prendidos.append("SDFGI(%d casc)" % e.sdfgi_cascades)
		if e.volumetric_fog_enabled: prendidos.append("niebla volum.")
		if e.ssao_enabled: prendidos.append("SSAO")
		if e.ssr_enabled: prendidos.append("SSR(%d)" % e.ssr_max_steps)
		if e.glow_enabled: prendidos.append("glow")
		if e.fog_enabled: prendidos.append("niebla dist.")
		if e.adjustment_enabled: prendidos.append("ajustes de color")
	if _camara != null and _camara.dof_blur_far_enabled:
		prendidos.append("desenfoque")

	print("=== CENSO (%s) ===" % NOMBRES[nivel])
	print("nodos                  %d" % nodos)
	print("MeshInstance3D         %d  (%d triángulos)" % [mi, tris])
	print("MultiMeshInstance3D    %d  (%d instancias, %d visibles, %d triángulos)"
		% [mmi, mm_total, mm_vis, mm_tris])
	for grupo: String in ["pasto", "piedras", "humo", "bichos"]:
		var nodos_g := get_tree().get_nodes_in_group(grupo)
		if nodos_g.is_empty():
			continue
		print("  %-8s             %d nodos, se dibuja hasta %.0f m"
			% [grupo, nodos_g.size(), (nodos_g[0] as GeometryInstance3D).visibility_range_end])
	print("GPUParticles3D         %d  (%d partículas)" % [par, par_amt])
	print("luces                  %d  (con sombra %d)" % [luces, sombras])
	print("triángulos dibujables  %d" % (tris + mm_tris))
	print("efectos prendidos      %s" % ", ".join(prendidos))
	print("atlas de sombra        %d · escala 3D %.2f · MSAA %dx"
		% [_atlas, get_viewport().scaling_3d_scale, [1, 2, 4, 8][get_viewport().msaa_3d]])
	print("=== FIN ===")


func _triangulos(m: Mesh) -> int:
	if m == null:
		return 0
	var t := 0
	for s in m.get_surface_count():
		var a := m.surface_get_arrays(s)
		if a.is_empty():
			continue
		var idx: Variant = a[Mesh.ARRAY_INDEX]
		if idx != null and (idx as PackedInt32Array).size() > 0:
			t += (idx as PackedInt32Array).size() / 3
		else:
			t += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t
