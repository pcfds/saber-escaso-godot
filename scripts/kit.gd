extends RefCounted

class_name Kit

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
# LA PALETA MANDA ACÁ TAMBIÉN. Esto decía lo contrario y hay que dejarlo
# escrito, porque la frase que estaba mandó a saltearse medio kit:
#
#   > "la paleta no manda sobre las mallas del kit, que ya vienen con una
#   >  paleta coherente de fábrica"
#
# Es falso por donde se lo mire. Contradice `DISENO.md` §6.1 —*el color es una
# decisión de diseño, y eso le da a la paleta autoridad sobre todo lo demás*— y
# además el remedio que proponía es peor que la enfermedad: **dos paletas
# coherentes en un mismo cuadro no son dos aciertos, son la indecisión que se
# lee como Playmobil.** Que la de Kenney sea buena es justamente lo que la hace
# competir de igual a igual con la nuestra.
#
# Lo que sí sigue en pie: no se aplana con `material_override`. La geometría se
# respeta entera y lo único que se cambia es el color, muestra por muestra, en
# `Paleta.domar_material()`. `tinte()` sigue existiendo para lo otro: empujar
# UNA pieza suelta —una casa quemada— sin tocar a las demás.
# ===========================================================================

const RAIZ := "res://assets/kenney/"

## La otra carpeta. **Dos autores en el repo, y es una decisión, no un descuido.**
##
## Kenney cubre la vegetación de masa y no hay con qué cambiarlo: un pino suyo
## son 54 triángulos y el más barato de Quaternius son 1.576. Con ~2.500 árboles
## sembrados eso es la diferencia entre 135 mil triángulos y cuatro millones, o
## sea entre un valle y una presentación.
##
## Lo que Kenney NO cubre es un bicho vivo —no tiene animales— y ahí no hay
## empate que discutir: o entra otro autor o el valle sigue sin fauna.
##
## La costura se cierra en la aduana: las mallas de Quaternius vienen **sin
## textura**, sólo con `albedo_color`, así que pasan por el mismo
## `Paleta.domar_material()` que todo lo demás y salen en la escalera de valores
## de esta paleta. No es "el marrón de Quaternius al lado del verde de Kenney":
## es el marrón de `paleta.gd` en las dos.
const RAIZ_Q := "res://assets/quaternius/"

## Cache de rutas ya resueltas. Estático: vive lo que vive el proceso.
static var _mallas: Dictionary = {}
static var _escenas: Dictionary = {}
static var _domadas: Dictionary = {}
static var _fallados: Dictionary = {}


## Resuelve una ruta del kit a un archivo. Las rutas que arrancan con
## `quaternius/` van a la otra carpeta; el resto son las de siempre y **no hay
## que tocar un solo llamador** para que sigan andando.
##
## Prueba `.glb` y `.gltf` porque los dos packs no exportan igual.
static func archivo(ruta: String) -> String:
	var raiz := RAIZ_Q if ruta.begins_with("quaternius/") else RAIZ
	var base: String = raiz + (ruta.trim_prefix("quaternius/") if ruta.begins_with("quaternius/") else ruta)
	for ext in [".glb", ".gltf"]:
		if ResourceLoader.exists(base + ext):
			return base + ext
	return ""


## El Mesh de un `.glb` del kit. `ruta` es relativa y sin extensión:
## `"naturaleza/tree_simple"`, `"pueblo/wall-door"`, `"utiles/barrel"`.
##
## Devuelve `null` si el archivo no está — y avisa UNA vez, no una por
## instancia, que con 1.600 coníferas es la diferencia entre un aviso y
## veinte mil líneas de consola.
static func malla(ruta: String) -> Mesh:
	if _mallas.has(ruta):
		return _mallas[ruta]

	var completa := archivo(ruta)
	if completa == "":
		if not _fallados.has(ruta):
			_fallados[ruta] = true
			push_warning("Kit: no está %s" % ruta)
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
		_domar_color(m)

	_mallas[ruta] = m
	return m


## Pasa la malla por la aduana de `paleta.gd`. Es el ÚNICO lugar donde el color
## del kit se decide, y por eso no hay ramas acá: las dos clases de material del
## kit las distingue `Paleta.domar_material()`, que es donde vive el criterio.
##
## **Los colores del Nature Kit llegan corrompidos.** Se leyeron los `.glb`
## directo, sin pasar por nuestro código: todas las copas salen en
## (0.44, 0.90, 0.84) y todos los troncos en (0.95, 0.74, 0.62) — cian y salmón.
## En pantalla el bosque era turquesa y no había ajuste de luz que lo arreglara,
## porque el color estaba en el archivo.
##
## **Y los packs con textura NO "se ven bien".** Esto decía que sí, y esa frase
## es la que hizo que se saltearan la mitad de las mallas del valle: el filtro
## era `if base.albedo_texture != null: continue`. Está medido sobre píxeles de
## una captura, luma 0–255 y saturación HSV:
##
##   · Los dos atlas de `pueblo/` y `utiles/` son 24 muestras planas entre
##     s0,17 y s0,73 — una paleta de dibujo animado, ajena a la nuestra.
##   · Los techos salían a luma 122, 105, 145 y 153 contra un suelo de 122.
##     O sea que **la tapa era más clara que la caja y que el prado**, que es
##     exactamente al revés de lo que la escalera de `paleta.gd` construye.
##   · Y con saturación 0,49 · 0,56 · 0,36 · 0,30, contra un techo de 0,35.
##
## Con la aduana puesta, esos cuatro techos dan 34, 26, 33 y 36, y su saturación
## 0,29 · 0,19 · 0,26 · 0,22. Se ven bien AHORA.
##
## Se trabaja sobre una copia del material: el recurso importado no se toca, así
## que reimportar el `.glb` no arrastra nada nuestro.
static func _domar_color(m: Mesh, techo: float = Paleta.SATURACION_MUNDO) -> void:
	for i in m.get_surface_count():
		var base := m.surface_get_material(i) as StandardMaterial3D
		if base == null:
			continue
		var nuevo := base.duplicate() as StandardMaterial3D
		Paleta.domar_material(nuevo, techo)
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


## Una ESCENA entera del kit, instanciada, con sus materiales ya domados.
##
## `malla()` no sirve para todo. Un animal es un `MeshInstance3D` con
## `Skeleton3D` y `AnimationPlayer` al lado: si le sacás la malla y tirás el
## resto te queda una estatua en pose de reposo, con los brazos abiertos.
## Para eso está esto — devuelve el árbol completo.
##
## **El PackedScene se cachea, la instancia no.** Cada llamada es un `Node3D`
## nuevo, pero el `Mesh` de adentro es el MISMO recurso para todos: eso es lo
## que hace que domarlo cueste una vez y no una por bicho. `_domadas` lleva la
## cuenta para no volver a pasar la aduana por una malla ya pasada.
## `techo` es el tope de saturación de la aduana; ver `Paleta.domar_material()`.
## Los animales entran con `SATURACION_GENTE` porque un pelaje es cuero.
static func escena(ruta: String, techo: float = Paleta.SATURACION_MUNDO) -> Node3D:
	var e: PackedScene = _escenas.get(ruta)
	if e == null:
		if _fallados.has(ruta):
			return null
		var completa := archivo(ruta)
		if completa == "":
			_fallados[ruta] = true
			push_warning("Kit: no está %s" % ruta)
			return null
		e = load(completa) as PackedScene
		if e == null:
			_fallados[ruta] = true
			push_warning("Kit: %s no es una escena" % completa)
			return null
		_escenas[ruta] = e

	var n := e.instantiate() as Node3D
	if n != null:
		_domar_arbol(n, techo)
	return n


## Pasa por la aduana todas las mallas de un árbol de nodos. Ver `escena()`.
static func _domar_arbol(n: Node, techo: float) -> void:
	if n is MeshInstance3D:
		var m := (n as MeshInstance3D).mesh
		if m != null and not _domadas.has(m.get_instance_id()):
			_domadas[m.get_instance_id()] = true
			_domar_color(m, techo)
	for h in n.get_children():
		_domar_arbol(h, techo)


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
