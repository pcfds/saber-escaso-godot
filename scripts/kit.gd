extends RefCounted

class_name Kit

## El follaje y la corteza que se le imponen a las mallas del kit. Salen de la
## paleta pero aclarados: los de `Paleta` se calibraron contra conos verdes en
## una escena sin niebla, y acá hay que leerlos a cuarenta metros con AgX
## desaturando por encima.
const COPA_VIVA := Color(0.271, 0.396, 0.216)
const CORTEZA := Color(0.322, 0.243, 0.184)

# ===========================================================================
# EL KIT — las mallas hechas por alguien
#
# Hasta acá el valle era geometría primitiva generada por código: cajas,
# cápsulas y conos con buena luz. Eso tiene un techo y ya lo tocamos. El pasto
# eran conos verdes porque eran conos verdes, y no hay ajuste de material que
# arregle eso.
#
# Esto carga las mallas de Kenney (CC0, ver `assets/PROCEDENCIA.md`) y las
# entrega de dos formas:
#
#   Kit.malla("naturaleza/tree_simple")   → un Mesh, para meter en un MultiMesh
#   Kit.nodo("utiles/barrel")             → un MeshInstance3D suelto
#
# **Las dos comparten el mismo Mesh en memoria.** Un `.glb` importado es un
# PackedScene: instanciarlo por cada barril crearía un nodo nuevo cada vez, y
# el recurso Mesh de adentro es el mismo objeto para todos. Acá se instancia
# UNA vez por ruta, se le saca el Mesh, y el PackedScene se tira. De ahí en
# más es un diccionario.
#
# POR QUÉ NO HAY `material_override` EN NINGÚN LADO
#
# Las mallas de Kenney traen su propio material, y las de `pueblo/` y
# `utiles/` traen además un atlas de color compartido. Pisarlas con
# `material_override` las aplana a un solo color y tira exactamente lo que
# vinimos a buscar. Es al revés que con la geometría primitiva, donde el
# material era lo único que había.
#
# La consecuencia para `paleta.gd`: **la paleta sigue mandando sobre lo que
# generamos nosotros** —terreno, agua, cielo, luces, la ropa de la gente— y no
# manda sobre las mallas del kit, que ya vienen con una paleta coherente de
# fábrica. Mezclar las dos autoridades sobre el mismo objeto es lo que produce
# el "indeciso" que la dirección de arte nombró. Donde hace falta empujar una
# malla del kit hacia la paleta, se hace con `tinte()`, que multiplica y no
# reemplaza.
# ===========================================================================

const RAIZ := "res://assets/kenney/"

## Cache de rutas ya resueltas. Estático: vive lo que vive el proceso.
static var _mallas: Dictionary = {}
static var _fallados: Dictionary = {}


## El Mesh de un `.glb` del kit. `ruta` es relativa y sin extensión:
## `"naturaleza/tree_simple"`, `"pueblo/wall-door"`, `"utiles/barrel"`.
##
## Devuelve `null` si el archivo no está — y avisa UNA vez, no una por
## instancia, que con 1.600 coníferas es la diferencia entre un aviso y
## veinte mil líneas de consola.
static func malla(ruta: String) -> Mesh:
	if _mallas.has(ruta):
		return _mallas[ruta]

	var completa := RAIZ + ruta + ".glb"
	if not ResourceLoader.exists(completa):
		if not _fallados.has(ruta):
			_fallados[ruta] = true
			push_warning("Kit: no está %s" % completa)
		return null

	var escena := load(completa) as PackedScene
	if escena == null:
		if not _fallados.has(ruta):
			_fallados[ruta] = true
			push_warning("Kit: %s no es una escena" % completa)
		return null

	var raiz := escena.instantiate()
	var m := _primera_malla(raiz)
	raiz.queue_free()
	if m != null:
		_arreglar_color(m)

	_mallas[ruta] = m
	return m


## Le pone a la malla los colores de la paleta cuando no trae textura.
##
## **Los colores del Nature Kit llegan corrompidos.** Se consultaron las mallas
## directo, sin pasar por nuestro código: todas las copas salen en
## (0.44, 0.90, 0.84) y todos los troncos en (0.95, 0.74, 0.62) — cian y
## salmón. En pantalla el bosque era turquesa y no había ajuste de luz que lo
## arreglara, porque el color estaba en el archivo. Kenney no vende árboles
## cian; se rompe en la importación, y el zip no trae textura, así que no hay
## mapa de color que recuperar.
##
## Los packs de pueblo y útiles SÍ traen textura y se ven bien: por eso sólo se
## tocan las superficies sin textura.
##
## Y no es un parche: es la decisión que ya estaba escrita —**el color lo
## decide la paleta, no lo imita el material**— aplicada donde hacía falta.
## Copa y tronco se distinguen por cuál de las dos es más verde: aunque el
## color esté corrido, el orden entre ellos se mantiene.
static func _arreglar_color(m: Mesh) -> void:
	for i in m.get_surface_count():
		var base := m.surface_get_material(i) as StandardMaterial3D
		if base == null or base.albedo_texture != null:
			continue
		var c := base.albedo_color
		var nuevo := base.duplicate() as StandardMaterial3D
		# No se usa Paleta.COPA directo: ese color se eligió para la mancha
		# oscura del Sotobosque hecha con conos, y aplicado a TODOS los árboles
		# del valle deja siluetas negras. Se aclara para el follaje suelto y el
		# Sotobosque vuelve a oscurecerse por su cuenta, con la variación por
		# instancia que ya hace `vegetacion.gd`.
		nuevo.albedo_color = COPA_VIVA if c.g > c.r * 1.15 else CORTEZA
		nuevo.roughness = 0.97
		m.surface_set_material(i, nuevo)


## Busca el primer MeshInstance3D del árbol importado. Los `.glb` de Kenney
## traen un nodo raíz con uno o dos hijos; no hay que ir más hondo, pero se
## recorre igual porque el exportador cambió de forma entre packs.
static func _primera_malla(n: Node) -> Mesh:
	if n is MeshInstance3D:
		return (n as MeshInstance3D).mesh
	for h in n.get_children():
		var m := _primera_malla(h)
		if m != null:
			return m
	return null


## Un MeshInstance3D suelto con la malla del kit, listo para colgar de la
## escena. Sin material_override: se ve con el material que trae.
static func nodo(ruta: String) -> MeshInstance3D:
	var m := malla(ruta)
	if m == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = m
	return mi


## Un nodo del kit ya colocado. Es el atajo que usan `valle.gd` y
## `detalles.gd`: sin esto, cada prop son cinco líneas iguales.
##
## `giro` en radianes sobre Y. `escala` uniforme salvo que se pase un Vector3.
static func poner(padre: Node3D, ruta: String, pos: Vector3, giro: float = 0.0,
		escala: Variant = 1.0) -> MeshInstance3D:
	var mi := nodo(ruta)
	if mi == null:
		return null
	mi.position = pos
	mi.rotation.y = giro
	mi.scale = escala if escala is Vector3 else Vector3.ONE * (escala as float)
	padre.add_child(mi)
	return mi


## Cuántos triángulos tiene una malla del kit. Para el censo: el costo del arte
## nuevo hay que poder decirlo, no estimarlo.
static func triangulos(m: Mesh) -> int:
	if m == null:
		return 0
	var t := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if idx.size() > 0:
			t += idx.size() / 3
		else:
			t += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t


## Multiplica el albedo de una malla del kit por un color, sin tocar la malla
## original ni las demás instancias que la comparten.
##
## Se usa poco y a propósito: es para empujar una pieza hacia la paleta —una
## casa quemada, un muro de un pueblo distinto—, no para recolorear el kit.
## Devuelve los materiales nuevos para que el llamador los ponga por superficie.
static func tinte(mi: MeshInstance3D, c: Color) -> void:
	if mi == null or mi.mesh == null:
		return
	for s in mi.mesh.get_surface_count():
		var base := mi.mesh.surface_get_material(s)
		var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D
			else StandardMaterial3D.new())
		m.albedo_color = m.albedo_color * c
		mi.set_surface_override_material(s, m)
