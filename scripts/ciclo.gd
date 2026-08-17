## El día y la noche. No es un efecto: es el reloj del mundo, dibujado.
##
## En el servidor un tick es un día y el cron corre uno por hora. Así que:
##
##   seis horas reales  =  un día del valle  =  una vuelta entera del sol
##
## Eso hace que el cielo signifique algo en vez de decorar. Dos personas
## conectadas al mismo tiempo ven el MISMO atardecer, porque los dos leen el
## reloj del servidor y no el de su máquina. Y la fase de la luna es el día del
## valle: mirás para arriba y sabés cuánto hace que no entrás.
##
## Y el sol es lo que te dice qué hora es del valle sin abrir ningún menú: si
## entrás y está anocheciendo, eso es información, y es la misma para todos.
class_name Ciclo
extends Node

## Cuánto dura un día del valle en segundos reales. **Es el período del cron
## del servidor**: si allá cambia, acá también, o el sol y el mundo se separan.
##
## Arrancó en una hora y se subió a seis a pedido: el mundo pasaba demasiado
## rápido — la gente se moría, las agendas se cumplían y volvías al otro día a
## un valle irreconocible.
##
## El costo de esta decisión, que conviene tener presente: en una sesión de una
## hora ya NO ves un ciclo entero. Ves un sexto de día. Entrás de mañana y te
## vas de mañana. A cambio, el día del valle se siente largo y un atardecer
## pasa a ser algo con lo que te cruzás, no algo que pasa siempre.
const DIA_REAL := 21600.0

var sol: DirectionalLight3D
var relleno: DirectionalLight3D
var entorno: Environment

## Día del valle (el tick de la región) y en qué parte del día estamos.
var dia := 0
var _fraccion := 0.35          ## 0 medianoche, 0.25 amanecer, 0.5 mediodía
var _cielo: ShaderMaterial
## Las luciérnagas del valle. Sólo emiten de noche.
var bichos_de_luz: Array[GPUParticles3D] = []
var _ultima_oscuridad := -1.0

# Los colores de la luz del sol a lo largo del día. Un solo color multiplicado
# por la altura da un día que se ve gris al mediodía y gris de noche; lo que
# hace la hora dorada es que el COLOR cambie, no sólo la intensidad.
const ALBA    := Color(1.00, 0.58, 0.36)
const MEDIODIA := Color(1.00, 0.95, 0.88)
const OCASO   := Color(1.00, 0.48, 0.24)
const LUNAR   := Color(0.52, 0.64, 0.92)


func _ready() -> void:
	if entorno != null and entorno.sky != null:
		_cielo = entorno.sky.sky_material as ShaderMaterial


## La llama el valle cuando el servidor contesta. `fraccion` sale de cuántos
## segundos pasaron desde el último tick: es la hora del valle, igual para
## todos los que estén conectados.
func sincronizar(tick_del_valle: int, segundos_en_el_dia: float) -> void:
	dia = tick_del_valle
	_fraccion = fposmod(segundos_en_el_dia / DIA_REAL, 1.0)


## Qué hora es en el valle, de 0 a 1. La lee `sonido.gd`.
##
## Existe para que nadie tenga que leer `_fraccion` por nombre: sin esto, el
## día que alguien renombre la variable el ambiente se queda mudo en silencio,
## sin error y sin que nadie se entere hasta escucharlo.
func fraccion() -> float:
	return _fraccion


func _process(dt: float) -> void:
	_fraccion = fposmod(_fraccion + dt / DIA_REAL, 1.0)

	# El sol sale por el este y se pone por el oeste, inclinado — un sol que
	# pasa justo por el cenit aplana todo al mediodía y no da sombras largas.
	var angulo := (_fraccion - 0.25) * TAU
	var altura := sin(angulo)
	var dir := Vector3(cos(angulo) * 0.82, altura, -0.38).normalized()

	if sol != null:
		sol.rotation = Transform3D().looking_at(-dir, Vector3.UP).basis.get_euler()

		# De día manda el sol; de noche la luz viene de la luna, fría y débil,
		# y desde otro lado. Que la dirección cambie es lo que hace que la
		# noche se sienta otra cosa y no "lo mismo pero oscuro".
		var d := clampf(remap(altura, -0.15, 0.25, 0.0, 1.0), 0.0, 1.0)
		var dorada := 1.0 - absf(clampf(remap(altura, -0.10, 0.45, 0.0, 1.0), 0.0, 1.0) * 2.0 - 1.0)
		var color := LUNAR.lerp(MEDIODIA, d)
		color = color.lerp(OCASO if cos(angulo) < 0.0 else ALBA, dorada * 0.75)
		sol.light_color = color
		sol.light_energy = lerp(0.09, 2.1, d)
		# Sombras largas y blandas cuando el sol está bajo.
		sol.light_angular_distance = lerp(2.6, 0.9, d)
		sol.shadow_blur = lerp(2.2, 1.1, d)

	if relleno != null:
		# El relleno frío es el cielo rebotando. De noche casi no hay.
		relleno.light_energy = lerp(0.05, 0.24, clampf(altura + 0.25, 0.0, 1.0))

	if _cielo != null:
		_cielo.set_shader_parameter("sol_dir", dir)
		_cielo.set_shader_parameter("altura_sol", altura)
		# El cielo gira con el día, pero mucho más lento que el sol: si girara
		# igual, las estrellas parecerían pegadas al sol.
		_cielo.set_shader_parameter("estrellas_giro", _fraccion * TAU * 0.12 + float(dia) * 0.21)
		# Ocho días del valle por vuelta de luna.
		_cielo.set_shader_parameter("fase_luna", fposmod(float(dia) / 8.0, 1.0))

	if entorno != null:
		var n := clampf(remap(altura, -0.18, 0.20, 0.0, 1.0), 0.0, 1.0)
		# Sin SDFGI no hay rebote de luz: la ambiente tiene que cubrir ese hueco
		# o el valle en calidad baja queda plano y más oscuro de lo que es.
		var sin_rebote := 1.35 if not entorno.sdfgi_enabled else 1.0
		entorno.ambient_light_energy = lerp(0.14, 0.62, n) * sin_rebote
		entorno.fog_light_color = Color(0.09, 0.12, 0.20).lerp(Color(0.52, 0.58, 0.62), n)
		entorno.fog_light_energy = lerp(0.35, 0.9, n)
		entorno.volumetric_fog_density = lerp(0.0090, 0.0055, n)
		# De noche el brillo de las ventanas y la fragua tiene que pesar más:
		# es lo único que queda encendido, y es lo que dice "hay alguien".
		entorno.glow_intensity = lerp(1.05, 0.55, n)
		# Recorrer todas las ventanas del valle en cada cuadro para mover un
		# número que cambia una vez por hora es tirar cuadros a la basura.
		var oscuridad := 1.0 - n
		if absf(oscuridad - _ultima_oscuridad) > 0.01:
			_ultima_oscuridad = oscuridad
			_aplicar_al_valle(oscuridad)


## Para la interfaz: qué hora es en el valle, en palabras.
func momento() -> String:
	if _fraccion < 0.20: return "de madrugada"
	if _fraccion < 0.30: return "al amanecer"
	if _fraccion < 0.45: return "de mañana"
	if _fraccion < 0.58: return "al mediodía"
	if _fraccion < 0.72: return "de tarde"
	if _fraccion < 0.82: return "al atardecer"
	return "de noche"


## ¿Está oscuro? Lo usan las luciérnagas y las ventanas.
func es_de_noche() -> bool:
	return _fraccion < 0.24 or _fraccion > 0.78


## Lo que cambia en el valle cuando cae el sol.
##
## Esto es la parte que importa más que el degradé del cielo: una ventana que
## se enciende dice "adentro hay alguien" mucho más fuerte que cualquier cosa
## que se pueda pintar arriba. Y las luciérnagas de día se ven a error.
func _aplicar_al_valle(oscuridad: float) -> void:
	for v in get_tree().get_nodes_in_group("ventanas"):
		var mi := v as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var m := mi.mesh.surface_get_material(0) as StandardMaterial3D
		if m != null:
			m.emission_energy_multiplier = lerp(0.15, 4.2, oscuridad)
	for b in bichos_de_luz:
		if is_instance_valid(b):
			b.emitting = oscuridad > 0.45

