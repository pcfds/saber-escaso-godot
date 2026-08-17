## Cliente del servidor. El mismo que usa la web: la base, la simulación, el
## director y el diálogo de NPCs no cambian al cambiar de motor.
##
## Ese fue el punto de escribir el cliente como descartable — esto es lo que
## sobrevivió del prototipo de navegador, que es casi todo el producto.
class_name Api
extends Node

signal mundo_recibido(datos: Dictionary)
signal dialogo_recibido(datos: Dictionary)
signal peleado(datos: Dictionary)
signal danio_recibido(datos: Dictionary)
signal levantado(datos: Dictionary)
## Lo que contestó `POST /tomar`: `{ok, health, lugar, objeto, hecho_por,
## cuenta}`. `lugar` viene igual al de antes — **tomar NO te mueve**, que es
## justamente para qué sirve.
signal tomado(datos: Dictionary)
signal cronica_recibida(texto: String)
## Lo que pasó cuando mandaste una acción. Ver `actuar()`: el servidor lo
## contesta y el cliente lo venía tirando a la basura.
signal aviso_recibido(texto: String)
## La magia. Las tres rutas ya vivían en producción y el cliente no las llamaba:
## el sistema más distintivo del juego estaba entero del lado del servidor y no
## había forma de trazar una runa desde el juego.
signal preparado(datos: Dictionary)
signal lanzado(datos: Dictionary)
signal grimorio_recibido(datos: Dictionary)

## Se sobreescriben desde la línea de comandos o el archivo de config.
var base_url := "https://saber-escaso.vercel.app"
var token := ""


func _ready() -> void:
	_leer_config()


func _leer_config() -> void:
	# 1) --token=xxx en la línea de comandos. Se miran LOS DOS arrays: en un
	#    build exportado los argumentos no siempre caen del lado de
	#    get_cmdline_user_args(), y el juego terminaba pidiendo el token con
	#    una caja de texto que además se robaba el teclado.
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg.begins_with("--token="):
			token = arg.substr(8)
		elif arg.begins_with("--url="):
			base_url = arg.substr(6)
	# 2) token.txt al lado del ejecutable: la forma más simple de repartirle
	#    su personaje a cada uno sin recompilar.
	if token == "":
		var junto := OS.get_executable_path().get_base_dir().path_join("token.txt")
		if FileAccess.file_exists(junto):
			token = FileAccess.open(junto, FileAccess.READ).get_as_text().strip_edges()
	if token != "":
		return
	# 3) usuario://config.json, para no tener que pasar el token cada vez
	if FileAccess.file_exists("user://config.json"):
		var f := FileAccess.open("user://config.json", FileAccess.READ)
		var j: Variant = JSON.parse_string(f.get_as_text())
		if j is Dictionary:
			token = j.get("token", "")
			base_url = j.get("url", base_url)


func guardar_config() -> void:
	var f := FileAccess.open("user://config.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"token": token, "url": base_url}))


func pedir_mundo() -> void:
	_hacer_get("/j/%s/mundo" % token, func(d: Dictionary) -> void: mundo_recibido.emit(d))


func hablar(npc: String, dice: String = "") -> void:
	var cuerpo := "npc=" + npc.uri_encode()
	if dice.strip_edges() != "":
		cuerpo += "&dice=" + dice.uri_encode()
	_hacer_post("/j/%s/hablar" % token, cuerpo,
		func(d: Dictionary) -> void: dialogo_recibido.emit(d))


## Avisar dónde estamos parados.
##
## En el 3D caminás libre y el servidor no se enteraba: para el mundo seguías
## donde entraste. Eso rompía aprender, enseñar, y que los bichos te
## encuentren. Se manda sólo cuando CAMBIA de lugar, no cada cuadro.
func estoy_en(slug: String) -> void:
	_hacer_post("/j/%s/estoy" % token, "lugar=" + slug.uri_encode(),
		func(_d: Dictionary) -> void: pass)


## Pegarle a una amenaza del servidor. Se resuelve en el momento, no en el
## tick: un golpe que tarda una hora no es un golpe.
func pelear(id: String) -> void:
	_hacer_post("/j/%s/pelear" % token, "id=" + id.uri_encode(),
		func(d: Dictionary) -> void: peleado.emit(d))


## El golpe al revés: te pegaron a vos. El cliente avisa el impacto, el mundo
## decide cuánto duele.
##
## Fijate lo que NO viaja: cuánta vida te queda. Si el cliente mandara el
## número, cada máquina tendría su propia verdad y estaríamos donde estábamos
## —una vida local que bajaba en tiempo real y se curaba sola—. Acá sólo se
## dice quién pegó; la vida vuelve en la respuesta y esa es la que vale.
##
## Sin `id` el servidor agarra la primera amenaza viva del lugar donde estás
## parado, que es lo correcto cuando no sabemos a qué fila de `threats`
## corresponde el bicho de la escena.
func danio(id: String = "") -> void:
	var cuerpo := ""
	if id != "":
		cuerpo = "de=" + id.uri_encode()
	_hacer_post("/j/%s/danio" % token, cuerpo,
		func(d: Dictionary) -> void: danio_recibido.emit(d))


## Levantarse del piso. Devuelve el **slug** del lugar donde quedaste —el mismo
## vocabulario que viaja en /estoy—, que es la aldea y no donde caíste: el
## costo de caer es la caminata de vuelta. Si estabas entero contesta ok=false,
## porque si no levantarse sería una cura gratis y un viaje instantáneo.
func levantarse() -> void:
	_hacer_post("/j/%s/levantarse" % token, "",
		func(d: Dictionary) -> void: levantado.emit(d))


## Tomarse algo. Hoy sólo hay una cosa que se toma, el cuenco de cuajada, y lo
## que compra no es vida: es **posición**. Levantarse te deja entero pero en la
## aldea; el cuenco te deja a medias donde caíste.
##
## Que sean dos botones distintos y no uno mejor es el punto: es la primera
## decisión de este juego donde lo que ganás y lo que perdés no son la misma
## moneda.
func tomar(que := "") -> void:
	_hacer_post("/j/%s/tomar" % token, "que=" + que.uri_encode(),
		func(d: Dictionary) -> void: tomado.emit(d))


## Mandar una acción del mundo: `buscar`, `aprender`, `trabajar`, `encargarse`,
## `dar`, `ensenar`, `ir`.
##
## MEDIDO CONTRA PRODUCCIÓN EL 17 DE AGOSTO, y da vuelta lo que se creía:
## **`/act` NO espera al tick.** El servidor llama a `resolverAcciones()` en el
## acto (`lib/web.ts`) y contesta un **303** cuyo `Location` trae el resultado
## en el parámetro `aviso`:
##
##   POST /j/<token>/act   verb=buscar
##   → 303  location: /j/<token>?aviso=encontr%C3%B3%20rama%20de%20roble%20en%20El%20Sotobosque
##
## Es la respuesta pensada para el formulario de la web, y el cliente la venía
## perdiendo entera: `HTTPRequest` sigue los redirects solo, así que traía el
## HTML de la página del jugador, `JSON.parse_string()` devolvía null, y el
## callback —el que hacía `pedir_mundo()`— **no se llamaba nunca**. Por eso
## apretar una opción del diálogo no decía nada ni refrescaba la bolsa: desde
## adentro del juego se veía idéntico a un botón roto.
##
## Por eso acá el redirect no se sigue: el 303 **es** la respuesta.
##
## Un verbo que el servidor no conoce igual contesta 303, con el aviso "Lo
## mandaste. Se resuelve cuando cierre el día del valle." Es la única forma de
## distinguir "pasó" de "quedó encolado", y quedó encolado significa hasta seis
## horas reales. No inventes verbos.
func actuar(verbo: String, objetivo: String = "") -> void:
	var cuerpo := "verb=" + verbo.uri_encode()
	if objetivo != "":
		cuerpo += "&target=" + objetivo.uri_encode()
	var r := HTTPRequest.new()
	# El 303 es el dato, no un desvío.
	r.max_redirects = 0
	add_child(r)
	r.request_completed.connect(_accion_completada.bind(r))
	var err := r.request(
		base_url + "/j/%s/act" % token,
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST,
		cuerpo,
	)
	if err != OK:
		push_error("no pude mandar la acción %s: %s" % [verbo, err])
		r.queue_free()
		aviso_recibido.emit("No salió el pedido.")


func _accion_completada(
	_res: int, codigo: int, headers: PackedStringArray, _cuerpo: PackedByteArray,
	nodo: HTTPRequest
) -> void:
	nodo.queue_free()
	var texto := _aviso_de(headers)
	if texto == "" and (codigo < 200 or codigo >= 400):
		# Se vio un 504 real: la acción tardó más que el límite de la función.
		# Decirlo es mejor que quedarse mudo, que es lo que se leía como "el
		# juego no hace nada".
		texto = "El valle tardó demasiado en contestar. Prueba de nuevo."
	if texto != "":
		aviso_recibido.emit(texto)
	# El mundo YA cambió: la bolsa, los vínculos, el lugar. Sin este pedido el
	# objeto que acabás de encontrar no aparece hasta vaya a saber cuándo.
	pedir_mundo()


## El resultado viaja en el `Location` del 303, no en el cuerpo.
static func _aviso_de(headers: PackedStringArray) -> String:
	for h in headers:
		if not h.to_lower().begins_with("location:"):
			continue
		var loc := h.substr(9).strip_edges()
		var i := loc.find("aviso=")
		if i < 0:
			return ""
		return loc.substr(i + 6).split("&")[0].uri_decode()
	return ""


## ─────────────────────────────────────────────────────────────
## La magia
## ─────────────────────────────────────────────────────────────
##
## Tres rutas y ninguna encolada: `preparar` y `lanzar` se resuelven en el acto,
## igual que `pelear` y por el mismo motivo — un hechizo que tarda seis horas no
## es un hechizo. **No pasan por `/act`**: `resolveAction()` del tick no conoce
## esos verbos y encolarlos los dejaría pendientes para siempre.
##
## Las tres contestan JSON con 200 aunque salga mal: el "no" viene como
## `{ok:false, porque:"..."}` y ese `porque` está escrito para leerse en
## pantalla ("no sabe el calor", "hoy no trae el calor encima"). No lo
## reescribas: la razón específica es lo que le enseña la gramática al jugador.

## Colgarse las runas del día. Van EN ORDEN y separadas por espacio; el orden es
## sólo cómo se te van a mostrar, la mezcla se elige al trazar.
func preparar(runas: PackedStringArray) -> void:
	_hacer_post("/j/%s/preparar" % token,
		"runas=" + " ".join(runas).uri_encode(),
		func(d: Dictionary) -> void: preparado.emit(d))


## Trazar. `runas` EN ORDEN — el orden ES la mezcla: `brasa aliento` es fuego
## que se esparce y `aliento brasa` es un empujón que quema.
##
## `blanco` es el cauce y son cuatro: `amenaza`, `persona`, `jugador`, `lugar`.
## El cauce no es una runa a propósito — si lo fuera, cada hechizo gastaría una
## pieza de las tres que llevás sólo para decir "a ése".
##
## Sin `id` el servidor agarra lo que haya donde estás parado: la primera
## amenaza viva, vos mismo, o el lugar. Para `persona` acepta el nombre además
## del uuid.
func lanzar(runas: PackedStringArray, blanco: String, id: String = "") -> void:
	var cuerpo := "runas=" + " ".join(runas).uri_encode() + "&blanco=" + blanco.uri_encode()
	if id != "":
		cuerpo += "&id=" + id.uri_encode()
	_hacer_post("/j/%s/lanzar" % token, cuerpo,
		func(d: Dictionary) -> void: lanzado.emit(d))


## El grimorio: las runas que te enseñaron, lo que llevás hoy, y **sólo las
## mezclas que te salieron a vos**. Nunca la lista de lo posible — un menú con
## todo convierte el saber en información y mata el sistema entero.
func pedir_grimorio() -> void:
	_hacer_get("/j/%s/grimorio" % token,
		func(d: Dictionary) -> void: grimorio_recibido.emit(d))


func pedir_cronica() -> void:
	_hacer_post("/j/%s/cronica" % token, "",
		func(d: Dictionary) -> void: cronica_recibida.emit(d.get("text", "")))


func _hacer_get(ruta: String, alTerminar: Callable) -> void:
	var r := HTTPRequest.new()
	add_child(r)
	r.request_completed.connect(_completado.bind(r, alTerminar))
	var err := r.request(base_url + ruta)
	if err != OK:
		push_error("no pude pedir %s: %s" % [ruta, err])
		r.queue_free()


func _hacer_post(ruta: String, cuerpo: String, alTerminar: Callable) -> void:
	var r := HTTPRequest.new()
	add_child(r)
	r.request_completed.connect(_completado.bind(r, alTerminar))
	var err := r.request(
		base_url + ruta,
		["Content-Type: application/x-www-form-urlencoded"],
		HTTPClient.METHOD_POST,
		cuerpo,
	)
	if err != OK:
		push_error("no pude postear %s: %s" % [ruta, err])
		r.queue_free()


func _completado(
	_res: int, codigo: int, _headers: PackedStringArray, cuerpo: PackedByteArray,
	nodo: HTTPRequest, alTerminar: Callable
) -> void:
	nodo.queue_free()
	if codigo < 200 or codigo >= 400:
		push_warning("el servidor respondió %s" % codigo)
		return
	var j: Variant = JSON.parse_string(cuerpo.get_string_from_utf8())
	if j is Dictionary:
		alTerminar.call(j as Dictionary)
