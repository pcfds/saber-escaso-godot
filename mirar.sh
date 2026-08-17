#!/usr/bin/env bash
# Una captura del valle, SIN abrirle una ventana encima a nadie.
#
# Godot en `--headless` no rasteriza —el shader del cielo ni se compila— así
# que para juzgar el look hay que abrir una ventana de verdad. Bajo WSLg esa
# ventana aparece en el escritorio de Windows y se roba el foco, y quien está
# jugando a otra cosa se come el salto. Pedido textual: *"cuando haces pruebas
# por favor no me pises jugando al Dota, que salga en segundo plano"*.
#
# El arreglo es `--position` bien afuera del escritorio. No hay Xvfb en esta
# máquina; si algún día lo hay, esto se reemplaza por `xvfb-run` y se borra el
# número mágico.
#
#   ./mirar.sh                        una captura de ahora
#   ./mirar.sh --hora=noche           con el reloj clavado
#   ./mirar.sh --panel=ficha          con un panel abierto
#   ./mirar.sh --calidad=bajo --hora=ocaso
#
# Deja `captura.png` en la raíz. **Borrala al terminar: no va al repo.**
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd "$(dirname "$0")"

TOKEN="${TOKEN:-$(cat /tmp/tok3d 2>/dev/null || true)}"
[ -n "$TOKEN" ] && TOKEN="--token=$TOKEN"

timeout 280 godot \
  --display-driver x11 --rendering-driver vulkan --audio-driver Dummy \
  --resolution 1600x900 --position 9000,9000 --quit-after 900 \
  -- $TOKEN --captura "$@" 2>&1 | grep -iE "SCRIPT ERROR|ERROR:" || true

[ -f captura.png ] && echo "captura.png lista ($(stat -c%s captura.png) bytes)" || echo "NO salió la captura"
