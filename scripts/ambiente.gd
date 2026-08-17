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
class_name Ambiente
extends WorldEnvironment


func _ready() -> void:
	environment = _construir_entorno()
	camera_attributes = _construir_camara()


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
	e.ambient_light_sky_contribution = 1.0
	e.ambient_light_energy = 0.62
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	# (3) Iluminación global. La luz rebota: la pared iluminada tiñe el piso.
	e.sdfgi_enabled = true
	e.sdfgi_use_occlusion = true
	e.sdfgi_cascades = 4
	e.sdfgi_min_cell_size = 0.2
	e.sdfgi_energy = 1.1
	e.sdfgi_bounce_feedback = 0.6

	# (2) Niebla volumétrica. Lo que convierte una luz direccional en rayos.
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.0055
	e.volumetric_fog_albedo = Color(0.78, 0.72, 0.66)
	e.volumetric_fog_emission = Color(0.05, 0.06, 0.08)
	e.volumetric_fog_gi_inject = 1.4
	e.volumetric_fog_length = 130.0
	e.volumetric_fog_detail_spread = 2.0
	e.volumetric_fog_ambient_inject = 0.7

	# Niebla de distancia: da profundidad y esconde el borde del mundo, que es
	# el problema clásico de un valle chico.
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_DEPTH
	e.fog_light_color = Color(0.52, 0.58, 0.62)
	e.fog_light_energy = 0.9
	e.fog_sun_scatter = 0.35
	e.fog_density = 0.0
	# Llega hasta la cordillera: las montañas tienen que verse como siluetas
	# azuladas, no desaparecer en una pared de niebla a los 190 metros.
	e.fog_depth_begin = 95.0
	e.fog_depth_end = 440.0
	e.fog_depth_curve = 1.4

	# Brillo: sólo lo que de verdad emite (la fragua, las brasas).
	e.glow_enabled = true
	e.glow_intensity = 0.55
	e.glow_bloom = 0.08
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	e.glow_hdr_threshold = 1.05

	# Oclusión ambiental: la mugre en los rincones. Barata y se nota.
	e.ssao_enabled = true
	e.ssao_radius = 1.4
	e.ssao_intensity = 1.6
	e.ssao_power = 1.8
	e.ssao_detail = 0.5

	# Reflejos en el río sin pagar raytracing.
	e.ssr_enabled = true
	e.ssr_max_steps = 48
	e.ssr_fade_in = 0.3

	# (4) AgX: no quema los naranjas de la fragua como haría ACES.
	e.tonemap_mode = Environment.TONE_MAPPER_AGX
	e.tonemap_exposure = 0.95
	e.tonemap_white = 6.0

	e.adjustment_enabled = true
	e.adjustment_saturation = 1.02
	e.adjustment_contrast = 1.04

	return e


func _construir_camara() -> CameraAttributesPractical:
	# (1) El truco del diorama. El desenfoque arranca justo detrás de donde
	# está el jugador, así lo que te importa está nítido y el resto del valle
	# se lee como maqueta.
	var c := CameraAttributesPractical.new()
	c.dof_blur_far_enabled = true
	c.dof_blur_far_distance = 40.0
	c.dof_blur_far_transition = 26.0
	c.dof_blur_near_enabled = true
	c.dof_blur_near_distance = 11.0
	c.dof_blur_near_transition = 7.0
	c.dof_blur_amount = 0.09
	c.auto_exposure_enabled = false
	return c
