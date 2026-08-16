#!/usr/bin/env bash
# Exporta el juego y lo instala en el Escritorio. Siempre la MISMA carpeta.
#
# Windows bloquea un .exe mientras corre, así que copiar encima falla con
# "Permission denied". Por eso acá se cierra el juego primero. Es la razón por
# la que en algún momento aparecieron carpetas SaberEscaso2 — no vuelve a pasar.
#
# El token.txt NO se toca: es de cada persona y sobrevive a las
# actualizaciones.
set -euo pipefail

PROYECTO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESTINO="${DESTINO:-/mnt/c/Users/PEDRO/Desktop/SaberEscaso}"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
TASKKILL=/mnt/c/Windows/System32/taskkill.exe

cd "$PROYECTO"

echo "==> Revisando que el proyecto corra sin errores"
# Correrlo de verdad antes de exportar. Un --import limpio no prueba nada: los
# errores de orden de inicialización sólo aparecen ejecutando _ready().
salida=$("$GODOT" --headless --quit-after 400 2>&1 || true)
if grep -q "SCRIPT ERROR" <<<"$salida"; then
	grep -A3 "SCRIPT ERROR" <<<"$salida" | head -20
	echo "==> Hay errores de script. No exporto." >&2
	exit 1
fi

echo "==> Exportando"
"$GODOT" --headless --export-release "Windows" >/dev/null

echo "==> Cerrando el juego si está abierto"
"$TASKKILL" /IM SaberEscaso.exe /F >/dev/null 2>&1 || true
sleep 1

echo "==> Instalando en $DESTINO"
mkdir -p "$DESTINO"
cp "$PROYECTO/../saber-escaso-win/SaberEscaso.exe" "$DESTINO/"
printf '@echo off\r\nstart "" "%%~dp0SaberEscaso.exe"\r\n' > "$DESTINO/JUGAR.bat"
if [[ ! -s "$DESTINO/token.txt" ]]; then
	echo "==> OJO: falta $DESTINO/token.txt — el juego va a pedir el link al abrir."
fi

echo "==> Listo. Abrí JUGAR.bat  ($(date +%H:%M))"
