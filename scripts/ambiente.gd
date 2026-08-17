## La luz. Es el 80% de por qué esto se ve como un diorama vivo y no como
## 3D genérico — y no cuesta un solo asset.
##
## Cuatro decisiones que hacen el look, en orden de impacto:
##
##  1. ~~PROFUNDIDAD DE CAMPO~~. **Dado de baja el 17 de agosto y el renglón se
##     deja tachado a propósito**, porque el argumento por el que estuvo acá
##     meses era bueno y hay que saber por qué se cayó: buscaba que la escena se
##     leyera como una MAQUETA, y una maqueta es un juguete. Es el reclamo, no
##     el look. Ver el bloque largo en `_construir_camara()`, con números.
##  2. NIEBLA VOLUMÉTRICA con luz atravesándola. Rayos de sol entre los árboles
##     por casi nada de costo. **Y la niebla de DISTANCIA, que ahora no toca el
##     cielo** — ver `fog_sky_affect`, que era por qué no había cielo.
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
##
## ===========================================================================
## TRES DE LAS SEIS PROPIEDADES QUE NO LLEGABAN A LA PANTALLA YA LLEGAN.
## ===========================================================================
##
## La frase de arriba —"la identidad visual se define en UN lugar, éste"— era
## una intención y no lo que pasaba. `_ready()` termina llamando a
## `Rendimiento.registrar_entorno()`, y `rendimiento.gd::_aplicar_entorno()`
## volvía a escribir varias de estas propiedades **en los tres niveles de
## calidad, sin preguntar**. Aparte, `ciclo.gd::_process()` reescribe otras
## **en cada cuadro**.
##
## Estado al 17 de agosto, tarde:
##
##   | propiedad                | dice este archivo | llega | quién |
##   |--------------------------|-------------------|-------|-------|
##   | `adjustment_enabled`     | `true`            | SÍ ahora, salvo en BAJO | — |
##   | `tonemap_exposure`       | 1.02              | SÍ ahora, salvo en BAJO | — |
##   | `dof_blur_far_enabled`   | `false`           | SÍ ahora              | — |
##   | `ambient_light_energy`   | 0.62              | lo pisa el ciclo      | ciclo |
##   | `ssao_enabled`           | true              | lo redecide           | rendimiento |
##   | `ssr_enabled`            | true              | lo redecide           | rendimiento |
##   | `volumetric_fog_enabled` | true              | lo redecide           | rendimiento |
##
## Las tres primeras se arreglaron aplicando la regla que ya estaba escrita:
## **`rendimiento.gd` decide CÓMO se calcula un efecto, no si existe.** Ahora
## esas tres van condicionadas a `nivel == BAJO`, que es el único nivel donde
## hay un costo que justifique la excepción.
##
## Las cuatro que quedan son legítimas y conviene decir por qué: SSAO, SSR y la
## niebla volumétrica se apagan **por presupuesto de máquina**, que es
## exactamente para lo que existe ese archivo. La luz ambiente la pisa el ciclo
## porque cambia con la hora del valle, que la manda el servidor.
##
## Y una trampa de método que sobrevive: **apagar algo desde acá no lo apaga si
## `rendimiento.gd` lo vuelve a prender.** Para medir si la niebla volumétrica
## hacía algo hubo que ir por `volumetric_fog_density = 0.0`, que sí es de este
## archivo; `volumetric_fog_enabled = false` lo revierte rendimiento y el
## experimento da un falso "no cambia nada" por el motivo equivocado.
##
## ===========================================================================
## QUÉ SE MIDIÓ Y NO ERA LA CAUSA (17 de agosto)
## ===========================================================================
##
## La pregunta era por qué el valle vivía en una banda de gris angosta y la
## aldea no se separaba del suelo. Con el sol congelado y cambiando UNA cosa por
## vez sobre la misma escena, ninguna de estas cuatro movió la aguja:
##
##   · `sdfgi_energy = 0.0` (o sea, la GI sin aportar luz): las trece zonas
##     dieron el mismo número ±1. Ojo: es una medición **bajo llvmpipe**, donde
##     SDFGI ya sale basura — no es motivo para apagarlo en el `.exe`.
##   · `volumetric_fog_density = 0.0`: sin cambio.
##   · `fog_enabled = false`: sin cambio, y tiene sentido — la niebla de
##     distancia arranca a 210 m y la aldea está a 40.
##   · El tonemapper: AgX / Filmic / Lineal dieron un rango p5–p95 de 81, 81 y
##     78. **AgX no es el que comprime.** Y de paso quedó medido a favor de AgX:
##     con Lineal la saturación de los muros salta de 0,46 a 0,57, o sea que
##     Lineal empeora el otro problema.
##
## La causa estaba en los materiales del kit de Kenney, que no pasaban por la
## paleta. Está resuelto en `paleta.gd`, sección "LA ADUANA".
class_name Ambiente
extends WorldEnvironment


func _ready() -> void:
	environment = _construir_entorno()
	camera_attributes = _construir_camara()
	Rendimiento.registrar_entorno(environment, camera_attributes)


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
	# Y EL ALBEDO SALE DE LA PALETA, QUE ES QUIEN DECIDE UN COLOR. Estaba a mano
	# en (0.46, 0.48, 0.52) —gris frío— y `paleta.gd` tiene el suyo escrito con
	# el motivo al lado: **`NIEBLA_VOL` es cálida** (h32 s0.15 v0.78). No es un
	# detalle de coherencia: la bruma volumétrica es lo que se ve atravesada por
	# el sol al amanecer y al anochecer, o sea el rayo de luz, y un rayo de luz
	# gris azulado a las siete de la mañana es lo contrario del amanecer. Con la
	# cálida, la misma niebla que de día resta contraste, de mañana y de tarde
	# suma oro.
	e.volumetric_fog_albedo = Paleta.NIEBLA_VOL
	e.volumetric_fog_emission = Paleta.NIEBLA_VOL_EMISION
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
	# ==========================================================================
	# ESTA LÍNEA ES POR QUÉ NO HABÍA CIELO. Medido, no deducido.
	# ==========================================================================
	#
	# El jugador dijo *"no hay eso de estrellas, un sol, un cielo azul"*, y tenía
	# razón literal: **el cielo se dibujaba y después la niebla lo tapaba
	# entero.** `fog_sky_affect` vale 1,0 por defecto en Godot y este archivo
	# nunca lo escribió; en `FOG_MODE_DEPTH` el cielo cuenta como si estuviera en
	# el plano lejano, así que le entra el 100% de la niebla y queda pintado de
	# `fog_light_color` de punta a punta.
	#
	# Aislado con una sonda que arma este mismo Environment y saca capturas
	# mirando arriba, una variable por corrida, el sol congelado a mediodía:
	#
	#   | corrida                     | cenit RGB       | saturación |
	#   |-----------------------------|-----------------|------------|
	#   | como estaba                 | (133, 140, 145) | **0,08**   |
	#   | `fog_sky_affect = 0`        | (139, 165, 189) | **0,26**   |
	#   | `fog_enabled = false`       | (139, 165, 189) | 0,26       |
	#   | `volumetric_fog_density=0`  | (135, 142, 146) | 0,08       |
	#
	# O sea: el gris era de la niebla de DISTANCIA, no de la volumétrica, y no
	# del tonemapper. Y de noche era peor — la sonda a medianoche daba un cielo
	# **plano en luma 104,0 exacto, mínimo igual a máximo**: cero estrellas, cero
	# vía láctea, cero lunas. La luna en fase y la vía láctea que dice tener
	# `cielo.gd` **existen y están bien hechas**; se las estaba comiendo esto.
	#
	# Va en 0,0 y no en un valor chico: la perspectiva aérea del horizonte ya la
	# hace el propio degradé de `cielo.gd`, que va de `horiz_dia` claro a
	# `cenit_dia` oscuro. Y la niebla sigue actuando entera sobre la GEOMETRÍA
	# —la cordillera se sigue lavando con la distancia, que es para lo que está—
	# porque esta propiedad sólo habla del cielo.
	e.fog_sky_affect = 0.0
	e.fog_light_color = Paleta.NIEBLA_DIA
	e.fog_light_energy = 0.55
	e.fog_sun_scatter = 0.35
	e.fog_density = 0.0
	# Llega hasta la cordillera: las montañas tienen que verse como siluetas
	# azuladas, no desaparecer en una pared de niebla a los 190 metros.
	#
	# ESTOS TRES NÚMEROS SE INTENTARON MOVER Y SE VOLVIERON ATRÁS. Queda escrito
	# porque el que venga va a tener la misma idea.
	#
	# El síntoma era real: en una captura del juego, el horizonte tenía una
	# franja pálida de borde duro cruzando la cordillera de lado a lado, y ahí
	# la montaña medía **luma 196 contra un cielo de 184** — la cosa más lejana
	# del cuadro más clara que el cielo, o sea la perspectiva aérea al revés. El
	# diagnóstico obvio era éste: poca niebla a esa distancia. Se bajó el final
	# de 780 a 560 m, que lleva a un pico de 400 m del 22% al 50% de niebla.
	#
	# **No cambió nada, y estaba midiendo la cosa equivocada.** La franja no era
	# la niebla: era el `floor()` de los escalones de luz de `dibujado.gd`
	# posterizando el degradé del cielo (arreglado allá). Con eso corregido, la
	# cordillera ya mide **22,9 de luma POR DEBAJO del cielo**, que es lo que
	# tiene que ser, y las dos corridas —560 y 780— dan el mismo número con una
	# décima de diferencia. El final vuelve a 780.
	#
	# Y el principio arranca en 210 y no se mueve por otro motivo: La Puerta
	# (`hitos.gd`) está a 162 m y se ve desde la aldea a ~206. Acercar el
	# principio de la niebla lavaría justo el hito que existe para dar escala.
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

	# CORRECCIÓN DE COLOR — YA CORRE. Antes era código muerto: `rendimiento.gd`
	# hacía `adjustment_enabled = false` en los tres niveles después de que este
	# archivo lo prendía, y alguien perdió una tarde moviendo la saturación de
	# 1,38 a 0,85 y midiendo capturas idénticas píxel a píxel. Hoy esa línea de
	# allá sólo corre en BAJO.
	#
	# El razonamiento por el que existe: AgX desatura fuerte por diseño —es un
	# tonemapper filmic, pensado para material fotográfico que después se
	# colorea— y un mundo estilizado sin nada que lo compense sale pastel.
	#
	# **La saturación se queda en 1,0 y eso es una decisión, no una omisión.**
	# Los techos de saturación de `paleta.gd` se miden DESPUÉS del grade, así que
	# cualquier número arriba de 1,0 empuja al valle entero por encima del techo
	# de 0,35 que fija la paleta, y ésa es la autoridad. Lo que se corrige acá es
	# el CONTRASTE, que es el eje donde el problema estaba medido: el valle vivía
	# en una banda de gris angosta. Contraste sí, saturación no — que es la misma
	# frase que el proyecto viene repitiendo, "el valor antes que el matiz".
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.0
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
	# ==========================================================================
	# EL DESENFOQUE DE LEJANÍA SE APAGA, Y NO ES UN AJUSTE: ES DAR DE BAJA (1).
	# ==========================================================================
	#
	# Este archivo lo tenía como "el truco central" y decía, con todas las
	# letras, que servía para que **el cerebro lea la escena como una MAQUETA**.
	# Ése era el objetivo y se cumplía. El problema es que ése es exactamente el
	# reclamo más viejo y más repetido del proyecto:
	#
	#   > *"parece un mundo de disney"*, *"muy de torta o de bebés"*,
	#   > *"falta escala, mapas grandes, castillos"*
	#
	# **Una maqueta es literalmente un juguete.** El tilt-shift es la técnica que
	# la fotografía usa para hacer que una ciudad de verdad parezca de plástico;
	# acá se estaba aplicando a un valle que necesita parecer grande y viejo.
	# No se puede pedir escala épica y desenfocar la distancia: la nitidez EN la
	# distancia es la señal con la que el ojo mide que algo está lejos y por lo
	# tanto que es grande.
	#
	# Y el costo estaba medido, con una variable por corrida sobre la misma
	# escena y el sol congelado (sonda `hitos.gd` en `modo_prueba`, un peñón de
	# 62 m a 160 metros de la cámara):
	#
	#   | corrida        | gradiente medio en el hito | p99  |
	#   |----------------|----------------------------|------|
	#   | como estaba    | 0,43                       |  4,9 |
	#   | apagado        | **0,77**                   | 10,9 |
	#
	# O sea que el desenfoque se estaba comiendo **el 44% del detalle** de lo
	# único grande que hay en el encuadre.
	#
	# Y (2): el cielo está en el plano lejano, así que le entraba el desenfoque
	# entero. Contando puntos con un filtro de paso alto sobre el cielo nocturno,
	# los puntos nítidos (hp>25) pasan de **196 a CERO** con el desenfoque
	# prendido. Las estrellas de `cielo.gd` no se veían en parte por esto.
	#
	# Lo que hacía el desenfoque de verdad —separar el plano del jugador del
	# fondo— ya lo hace mejor y más barato la niebla de distancia, que arranca a
	# 210 m y es honesta: eso es aire, no una lente.
	c.dof_blur_far_enabled = false
	# La distancia queda escrita igual, con el mismo criterio que el desenfoque
	# de cerca dos bloques más abajo: un efecto apagado sin número deja el
	# default del motor esperando al próximo que lo prenda. Si algún día se
	# quiere una bruma de lente en el horizonte de verdad, que arranque más allá
	# de la cordillera cercana (300 m) y no a 95, que es dentro del valle.
	c.dof_blur_far_distance = 340.0
	c.dof_blur_far_transition = 220.0
	# El desenfoque de cerca se apaga: con la cámara a 40 metros no hay nada
	# entre ella y el jugador que valga la pena desenfocar, y lo único que hacía
	# era ensuciar los árboles que quedan en el borde de la pantalla.
	c.dof_blur_near_enabled = false
	# Y la distancia queda escrita aunque el efecto esté apagado, que es el
	# arreglo de verdad: `rendimiento.gd` lo prendía sin ponerle distancia, y
	# un desenfoque de cerca prendido sin decir DÓNDE empieza borroneaba el
	# valle entero. Si algún día se prende a propósito, que ya tenga un número
	# defendible en vez del que venga por defecto.
	c.dof_blur_near_distance = 1.5
	c.dof_blur_near_transition = 1.0
	c.dof_blur_amount = 0.09
	c.auto_exposure_enabled = false
	return c
