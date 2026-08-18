## La antorcha que se lleva en la mano.
##
## ===========================================================================
## PARA QUÉ EXISTE
##
## Pedido de la dirección, textual: *"de noche tener cosas, fuego, linternas
## cuando se avance, por lo menos antorchas"*.
##
## Y el motivo es concreto, no ambiental. **El pueblo de noche está iluminado**
## —cuatro faroles en la plaza, el fogón, las ventanas encendidas— y afuera del
## pueblo no hay nada. Ir a La Fragua o a la Casa Quemada de noche es caminar
## por una pantalla negra, y como la noche duraba la mitad del ciclo, la mitad
## del juego era esperar a que se hiciera de día. La noche pasó a durar un
## tercio (`ciclo.gd`), y esto es la otra mitad del arreglo: **con qué salir.**
##
## ===========================================================================
## SE PRENDE EN UN FUEGO QUE EXISTE, Y SE APAGA SOLA
##
## Las dos reglas son la misma decisión: que la antorcha sea un recurso y no un
## interruptor. `CLAUDE.md` manda —*todo tiene vida o tiene algún sentido; antes
## de agregar algo a la escena, decí qué significa*—, y una luz que se prende
## desde cualquier lado y dura para siempre no significa nada: es el brillo de
## la pantalla con otro nombre.
##
##   · **Se prende en un fuego.** El fogón de la plaza o el hogar de una casa.
##     Eso le da un para qué al fogón que hasta hoy no tenía: era donde te
##     sentabas, ahora también es de donde sale la luz con la que salís.
##   · **Dura `DURA` y se apaga.** Con `DURA` en minutos reales, una salida de
##     noche tiene principio y fin, y volver al fuego es parte de salir.
##
## ===========================================================================
## ES PRESENTACIÓN, Y ESO ESTÁ DECIDIDO
##
## No viaja al servidor y **no es una violación del invariante 4**. La regla es
## que lo que pasa en el cliente tiene que llegar al servidor *o no pasó*, y lo
## que dice es que no puede haber estado del MUNDO viviendo en una máquina: la
## vida, el combate y la muerte se rompieron una vez exactamente así.
##
## Una antorcha no cambia el mundo. No la ve otro jugador, no la recuerda nadie,
## no abre ningún verbo, y si cerrás el juego con ella prendida no pasa nada.
## Es del mismo tipo que la hoja de la puerta y que la banqueta que se corre de
## una patada: **dónde está tu antorcha no lo tiene que saber nadie más.**
##
## El día que la antorcha se pueda FABRICAR, o se pueda dar, o se gaste en algo
## que otro vea, deja de ser esto y pasa a ser una fila en `objects` — y ahí sí
## va con `made_by`, con `left_by` y con todo lo demás.
class_name Antorcha
extends Node3D

## Cuánto dura prendida, en segundos reales. Cinco minutos: alcanza para ir
## hasta La Fragua y volver, que son los 62 metros que separan los dos lugares
## más lejanos que se caminan seguido, y **no alcanza para pasar la noche
## entera** — que es de lo que se trata. La noche dura dos horas reales.
const DURA := 300.0

## Desde dónde se puede prender en un fuego. Corto por el mismo motivo que el
## puesto de trabajo: un fuego que enciende desde la puerta hace que el cuarto
## entero sea un botón.
const CERCA_DEL_FUEGO := 3.0

## La luz. Menos que el fogón (4,6 a 15 m) y bastante más que nada: lo justo
## para ver dónde pisás y para que se te vea venir de lejos, que es la mitad de
## la gracia en un juego con otros jugadores adentro.
const LUZ := 3.1
const ALCANCE := 9.5

## Cuando le queda menos que esto, titila feo y se muere. No es un aviso de
## sistema: **es la llama diciéndolo.** Treinta segundos alcanzan para volver.
const AGONIA := 30.0

signal se_apago
signal se_prendio

var _luz: OmniLight3D
var _llama: MeshInstance3D
var _resto := 0.0
var _reloj := 0.0


func _ready() -> void:
	# Un omni SIN sombra, igual que los faroles de la plaza y por el mismo
	# motivo que dice `detalles.gd`: una omni con sombra es un cubemap, o sea
	# seis dibujados de todo lo que haya alrededor, y ésta se mueve con el
	# jugador — o sea que se redibujarían los seis en cada cuadro. El hogar de
	# un cuarto sí la paga porque está quieto y adentro de una caja.
	_luz = OmniLight3D.new()
	_luz.light_energy = 0.0
	_luz.omni_range = ALCANCE
	# Excepción 1 de la paleta: el fuego. Ningún script inventa un color.
	_luz.light_color = Paleta.VENTANA_EMISION
	_luz.shadow_enabled = false
	_luz.position = Vector3(0.0, 1.55, 0.0)
	add_child(_luz)

	# El palo y la llama. El farol del kit ya está en el repo y es la silueta
	# correcta a la distancia a la que se juega: a veintisiete metros lo que se
	# lee es que llevás algo en alto y que ese algo brilla.
	var cuerpo := Kit.nodo("pueblo/lantern")
	if cuerpo != null:
		cuerpo.scale = Vector3.ONE * 0.9
		cuerpo.position = Vector3(0.0, 1.25, 0.0)
		add_child(cuerpo)

	_llama = MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.13
	m.height = 0.34
	m.radial_segments = 6
	m.rings = 3
	_llama.mesh = m
	_llama.position = Vector3(0.0, 1.62, 0.0)
	# Excepción 1 de la paleta: el fuego es donde se gasta toda la saturación
	# que el resto del valle no tiene.
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Paleta.BRASA_EMISION
	_llama.material_override = mat
	_llama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_llama)

	visible = false


## ¿Está prendida?
func prendida() -> bool:
	return _resto > 0.0


## Cuánto le queda, de 0 a 1. Lo lee la interfaz para dibujar la mecha.
func resto() -> float:
	return clampf(_resto / DURA, 0.0, 1.0)


## Prenderla. Devuelve falso si no había fuego cerca, que es el único motivo
## por el que puede fallar.
##
## `fuegos` son los puntos de fuego del valle en coordenadas del mundo. Los
## junta `valle.gd`, que es el único que sabe dónde está el fogón y dónde los
## hogares: acá no se lee la escena.
func prender(desde: Vector3, fuegos: Array) -> bool:
	for f: Vector3 in fuegos:
		if Vector2(f.x, f.z).distance_to(Vector2(desde.x, desde.z)) <= CERCA_DEL_FUEGO:
			_resto = DURA
			visible = true
			se_prendio.emit()
			return true
	return false


## Apagarla a mano. Se puede, y tiene sentido: la que apagás te dura para
## después.
func apagar() -> void:
	if _resto <= 0.0:
		return
	_resto = 0.0
	visible = false
	se_apago.emit()


func _process(dt: float) -> void:
	if _resto <= 0.0:
		return
	_resto -= dt
	if _resto <= 0.0:
		_resto = 0.0
		visible = false
		se_apago.emit()
		return

	_reloj += dt
	# El titileo. Dos frecuencias que no encajan, igual que la sacudida de la
	# cámara y por el mismo motivo: un seno solo se lee como un péndulo y una
	# llama no es un péndulo.
	var t := 1.0 + sin(_reloj * 11.3) * 0.10 + sin(_reloj * 7.1 + 1.9) * 0.06
	# Y cuando se está por morir, titila FEO: la caída es al cuadrado y el
	# temblor se duplica. El aviso lo da la llama, no un cartel.
	var muriendo := 1.0
	if _resto < AGONIA:
		var q := _resto / AGONIA
		muriendo = q * q
		t += sin(_reloj * 23.0) * 0.35 * (1.0 - q)
	_luz.light_energy = maxf(0.0, LUZ * t * muriendo)
	_llama.scale = Vector3.ONE * clampf(t * (0.55 + 0.45 * muriendo), 0.15, 1.4)
