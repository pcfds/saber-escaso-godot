## Cliente del servidor. El mismo que usa la web: la base, la simulación, el
## director y el diálogo de NPCs no cambian al cambiar de motor.
##
## Ese fue el punto de escribir el cliente como descartable — esto es lo que
## sobrevivió del prototipo de navegador, que es casi todo el producto.
class_name Api
extends Node

signal mundo_recibido(datos: Dictionary)
signal dialogo_recibido(datos: Dictionary)
signal cronica_recibida(texto: String)

## Se sobreescriben desde la línea de comandos o el archivo de config.
var base_url := "https://saber-escaso.vercel.app"
var token := ""


func _ready() -> void:
	_leer_config()


func _leer_config() -> void:
	# 1) --token=xxx en la línea de comandos
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--token="):
			token = arg.substr(8)
		elif arg.begins_with("--url="):
			base_url = arg.substr(6)
	if token != "":
		return
	# 2) usuario://config.json, para no tener que pasar el token cada vez
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


func hablar(npc: String) -> void:
	_hacer_post("/j/%s/hablar" % token, "npc=" + npc.uri_encode(),
		func(d: Dictionary) -> void: dialogo_recibido.emit(d))


func actuar(verbo: String, objetivo: String = "") -> void:
	var cuerpo := "verb=" + verbo
	if objetivo != "":
		cuerpo += "&target=" + objetivo.uri_encode()
	_hacer_post("/j/%s/act" % token, cuerpo, func(_d: Dictionary) -> void: pedir_mundo())


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
