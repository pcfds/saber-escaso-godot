## La luz. Es el 80% de por qué esto se ve como un diorama vivo y no como
## 3D genérico — y no cuesta un solo asset.
##
## Cuatro decisiones que hacen el look, en orden de impacto:
##
##  1. PROFUNDIDAD DE CAMPO en vista isométrica. Es el truco central: desenfocar
##     lo lejano hace que el cerebro lea la escena como una MAQUETA, no como un
##     paisaje. Es el efecto tilt-shift, y es lo que va a hacer que la gente
##     diga "qué lindo" antes de entender qué está mirando.
##  2. NIEBLA VOLUMÉTRICA con luz atravesándola. Rayos de sol entre los árboles
##     por casi nada de costo.
##  3. SDFGI: iluminación global en tiempo real. El rebote de luz cálida en las
##     paredes es lo que separa "3D de asset store" de algo que parece pensado.
##  4. AgX como tonemapper. Filmic, no revienta los altos. Es lo que usan los
##     motores de cine; ACES quema los naranjas de la fragua.
##
## Lo que hay acá es el nivel ALTO y nada más. Quién lo baja es
## `rendimiento.gd`, al que este archivo le pasa el entorno recién armado.
## La división vale la pena: la identidad visual se define en UN lugar —éste—
## y las concesiones para que ande en cualquier máquina viven en otro, donde se
## pueden leer juntas y discutir juntas.
class_name Ambiente
extends WorldEnvironment


func _ready() -> void:
	environment = _construir_entorno()
	camera_attributes = _construir_camara()
	Rendimiento.registrar_entorno(environment, camera_attributes)
	_sonda()


# SONDA TEMPORAL — BORRAR
func _sonda() -> void:
	await get_tree().create_timer(3.4).timeout
	var soles: Array = []
	for n in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		var l := n as DirectionalLight3D
		soles.append("%s e=%.2f rotx=%.1f c=%s sh=%s" % [l.name, l.light_energy,
			rad_to_deg(l.rotation.x), l.light_color, l.shadow_enabled])
	print("SONDA cuadros=%d fps=%.1f amb=%.3f sdfgi=%s vol=%s fog=%s tone=%d sat=%.2f | %s" % [
		Engine.get_frames_drawn(), Engine.get_frames_per_second(),
		environment.ambient_light_energy, environment.sdfgi_enabled,
		environment.volumetric_fog_enabled, environment.fog_enabled,
		environment.tonemap_mode, environment.adjustment_saturation,
		", ".join(PackedStringArray(soles))])


func _construir_entorno() -> Environment:
	var e := Environment.new()

	# Cielo propio con shader (ver cielo.gd). El ProceduralSkyMaterial de Godot
	# no tiene noche: da un degradé y listo, así que a las tres de la mañana el
	# mundo queda adentro de una caja azul. Acá hay estrellas, dos lunas y un
	# planeta, y los mueve el reloj del valle (ciclo.gd).
	var s := Sky.new()
	s.sky_material = Cielo.material()
	s.radiance_size = Sky.RADIANCE_SIZE_128
	s.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	e.background_mode = Environment.BG_SKY
	e.sky = s
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# 1,0 significa que TODA la luz ambiente sale del cielo, y el cielo es azul.
	# Resultado: cualquier cosa que no reciba sol directo se pinta de celeste —
	# se vio en una captura del juego real, con árboles cian y techos rosa. Se
	# baja a 0,45 y el resto lo pone un ambiente propio, cálido, que es la luz
	# que rebota del suelo. Un valle no está iluminado sólo por el cielo.
	e.ambient_light_sky_contribution = 0.45
	e.ambient_light_color = Color(0.42, 0.38, 0.31)
	e.ambient_light_energy = 0.62
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	# (3) Iluminación global. La luz rebota: la pared iluminada tiñe el piso.
	#
	# Es el efecto más caro que tiene Godot, así que está afinado y no puesto
	# por default:
	#
	#  · DOS cascadas de 0,7 m de celda llegan a 90 metros (0,7 × 64 × 2). Con
	#    el desenfoque de lejanía arrancando a los 40, todo lo que pasa de ahí
	#    ya es puré: las cuatro cascadas de antes compraban doce metros más de
	#    alcance por el doble de trabajo.
	#  · SIN oclusión. La doc de Godot la recomienda para interiores con
	#    paredes finas donde se filtra luz de un cuarto a otro. Esto es un
	#    valle a cielo abierto: paga y no se ve.
	#  · Escala Y al 50%: el valle es plano y ancho. Achatando la cascada, los
	#    mismos vóxeles cubren más suelo, que es donde está todo.
	#  · El rebote se queda. ES la luz cálida en las paredes, o sea el punto.
	e.sdfgi_enabled = true
	e.sdfgi_use_occlusion = false
	e.sdfgi_cascades = 2
	e.sdfgi_min_cell_size = 0.7
	e.sdfgi_y_scale = Environment.SDFGI_Y_SCALE_50_PERCENT
	e.sdfgi_energy = 1.1
	e.sdfgi_bounce_feedback = 0.5

	# (2) Niebla volumétrica. Lo que convierte una luz direccional en rayos.
	#
	# Llega hasta los 130 metros, que es exactamente donde arranca la niebla de
	# distancia. Antes llegaba a 190 y los últimos sesenta metros los pintaban
	# las dos nieblas encima: se pagaba dos veces por el mismo gris.
	e.volumetric_fog_enabled = true
	# 0,0055 llenaba de bruma los 130 metros que la cámara está mirando: con la
	# cámara a 40-68 m, TODO el valle queda adentro del volumen y sale blanco
	# lavado. La niebla volumétrica sirve para los rayos de sol entre los
	# árboles, no para velar la escena. Un sexto de lo que era.
	e.volumetric_fog_density = 0.0009
	# Y el albedo casi blanco era la otra mitad del problema: la bruma sumaba
	# luz clara encima de todo. Más oscuro y más frío, para que reste contraste
	# sólo donde debe.
	e.volumetric_fog_albedo = Color(0.46, 0.48, 0.52)
	e.volumetric_fog_emission = Color(0.05, 0.06, 0.08)
	# Inyectar la GI en la niebla es una lectura de SDFGI por vóxel de humo. A
	# 1,0 el rayo de sol sigue estando; de 1,0 a 1,4 no se distinguía.
	e.volumetric_fog_gi_inject = 1.0
	e.volumetric_fog_length = 130.0
	e.volumetric_fog_detail_spread = 2.0
	e.volumetric_fog_ambient_inject = 0.25

	# Niebla de distancia: da profundidad y esconde el borde del mundo, que es
	# el problema clásico de un valle chico. Es de las cosas más baratas que
	# hay —un lerp en el shader de superficie— y se queda en los tres niveles.
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.52, 0.58, 0.62)
	e.fog_light_energy = 0.55
	e.fog_sun_scatter = 0.35
	e.fog_density = 0.0
	# Llega hasta la cordillera: las montañas tienen que verse como siluetas
	# azuladas, no desaparecer en una pared de niebla a los 190 metros.
	e.fog_depth_begin = 210.0
	e.fog_depth_end = 780.0
	e.fog_depth_curve = 1.4

	# Brillo: sólo lo que de verdad emite (la fragua, las brasas).
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_bloom = 0.08
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.glow_hdr_threshold = 1.05

	# Oclusión ambiental: la mugre en los rincones. Se queda sólo en ALTO —a 27
	# metros con FOV 42° un radio de 1,4 m son tres píxeles— y encima el rebote
	# de SDFGI ya oscurece esos mismos rincones.
	e.ssao_enabled = true
	e.ssao_radius = 1.4
	e.ssao_intensity = 1.6
	e.ssao_power = 1.8
	e.ssao_detail = 0.5

	# Reflejos en el río sin pagar raytracing. 24 pasos y no 48: el reflejo
	# útil son quince metros de agua vistos de lejos, no un espejo de pared a
	# pared, y el costo es lineal en la cantidad de pasos.
	e.ssr_enabled = true
	e.ssr_max_steps = 24
	e.ssr_fade_in = 0.3

	# (4) AgX: no quema los naranjas de la fragua como haría ACES.
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 1.02
	e.tonemap_white = 6.0

	# Los ajustes de color estaban en +2% de saturación y +4% de contraste. Eso
	# está por debajo de lo que el ojo distingue y prende una variante más del
	# shader de tonemapping. Si algún día hace falta una corrección de color,
	# que sea una que se vea.
	# La corrección de color estaba APAGADA, y AgX desatura fuerte por diseño:
	# es un tonemapper filmic, pensado para material fotográfico que después se
	# colorea. Sin nada que lo compense, un mundo estilizado sale pastel — que
	# es exactamente lo que pasó. Acá el color es una decisión de diseño, no una
	# aproximación a lo real, así que se recupera a mano.
	e.adjustment_enabled = true
	# 1,38 fue una sobrecorrección mía y se vio en la primera captura: techos
	# rosa chicle, árboles cian, suelo rosado. AgX desatura y hay que compensar,
	# pero la compensación tiene que devolver color, no inventarlo.
	e.adjustment_saturation = 1.10
	e.adjustment_contrast = 1.12
	e.adjustment_brightness = 1.0
	return e


func _construir_camara() -> CameraAttributesPractical:
	# (1) El truco del diorama. El desenfoque arranca justo detrás de donde
	# está el jugador, así lo que te importa está nítido y el resto del valle
	# se lee como maqueta.
	#
	# El costo lo baja `rendimiento.gd` cambiando la FORMA del bokeh a caja
	# (un blur separable de dos pasadas) en vez de círculo. Con un blur de
	# 0,09 la forma no se distingue ni con lupa, así que el efecto queda
	# intacto y la pasada cuesta una fracción.
	var c := CameraAttributesPractical.new()
	c.dof_blur_far_enabled = true
	# 40 metros era el desenfoque de cuando la cámara estaba a 27. Ahora la
	# cámara ARRANCA en 40 y llega a 68, así que el mundo entero caía detrás
	# del corte y salía borroso de punta a punta — el efecto maqueta se había
	# convertido en una mancha. Empieza más allá de donde la cámara puede
	# llegar, y así vuelve a desenfocar sólo la lejanía de verdad.
	c.dof_blur_far_distance = 95.0
	c.dof_blur_far_transition = 55.0
	# El desenfoque de cerca se apaga: con la cámara a 40 metros no hay nada
	# entre ella y el jugador que valga la pena desenfocar, y lo único que hacía
	# era ensuciar los árboles que quedan en el borde de la pantalla.
	c.dof_blur_near_enabled = false
	c.dof_blur_amount = 0.09
	c.auto_exposure_enabled = false
	return c
