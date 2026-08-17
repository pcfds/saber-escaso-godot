# De dónde salió cada malla, y con qué permiso

Este archivo es la **evidencia de licencia**. Los dos repos son públicos y el
juego se distribuye como `.exe`, así que acá no entra nada sin licencia clara
que permita uso comercial y redistribución. Si algún día se agrega un asset,
se agrega también su fila acá con la URL donde lo dice. **Ante la duda, no
entra.**

## Resumen

Todo el arte 3D importado es de **Kenney** (Kenney Vleugels, kenney.nl) y está
bajo **CC0 1.0 Universal** — dominio público. No exige atribución. Por eso
**no hace falta `CREDITOS.md`**; el crédito de abajo es voluntario y lo
dejamos porque corresponde.

> Kenney · https://kenney.nl · CC0 1.0

**Un solo autor a propósito.** Mezclar packs de artistas distintos se lee como
error; un solo autor se lee como decisión. Los tres kits usados son de la misma
serie "Kit" de Kenney: misma escala (celda de 1 m), misma paleta, mismo
sombreado plano. Si falta una pieza, se resuelve con geometría primitiva o no
se hace — **no se trae un cuarto estilo.**

## Los packs

| Pack | Versión | Página (dice la licencia) | Zip descargado | md5 del zip |
|---|---|---|---|---|
| Nature Kit | 2.1 | https://kenney.nl/assets/nature-kit | `kenney_nature-kit.zip` | `76777290568bf80e1ba928a23c73a441` |
| Fantasy Town Kit | 2.0 | https://kenney.nl/assets/fantasy-town-kit | `kenney_fantasy-town-kit_2.0.zip` | `d151edd416f769b77cc9f4eba29afafe` |
| Survival Kit | 2.0 | https://kenney.nl/assets/survival-kit | `kenney_survival-kit.zip` | `74cd74157b58339340085802ff9c8c0a` |

### Dónde dice CC0, textualmente

1. **En la página de cada pack** (`kenney.nl/assets/<pack>`), fila "License":

   ```html
   <td class='title text-muted'>License</td>
   <a href='https://creativecommons.org/publicdomain/zero/1.0/'>Creative Commons CC0</a>
   ```

2. **En `kenney.nl/support`**:

   > […] are public domain licensed (CC0). You're free to use them, even in
   > commercial projects.

3. **Adentro de cada zip**, en `License.txt` — copiado a este repo como
   `assets/kenney/LICENSE-<pack>.txt`:

   > License: (Creative Commons Zero, CC0)
   > http://creativecommons.org/publicdomain/zero/1.0/
   > You can use this content for personal, educational, and commercial purposes.
   > Support by crediting 'Kenney' or 'www.kenney.nl' (this is not a requirement)

El texto de licencia viaja **en el repo**, no de memoria: los tres
`LICENSE-*.txt` son los archivos originales de Kenney sin tocar.

## Qué se bajó y cómo

Bajado por consola con `curl` directo desde `kenney.nl`, sin intermediarios ni
espejos. El link del zip **no está en un `href`** de la página —por eso "no
aparece en el HTML plano"—, pero sí está en el HTML, en texto plano, con esta
forma:

```
https://kenney.nl/media/pages/assets/<slug>/<hash>-<epoch>/<archivo>.zip
```

Se saca con:

```sh
curl -s -A "Mozilla/5.0" "https://kenney.nl/assets/nature-kit" \
  | grep -oE "media/pages/assets/nature-kit/[^\"' )]*\.zip"
```

El `<hash>` cambia cuando Kenney republica el pack, así que **no lo hardcodees**:
sacalo de la página cada vez.

> **Nota sobre Quaternius.** También es CC0 y también servía, pero sus links de
> descarga apuntan a carpetas de Google Drive, que no se bajan con `curl`. No
> hizo falta: Kenney cubrió las cuatro categorías (casas, vegetación, gente,
> props) y **traer los dos hubiera roto la regla de un solo estilo.**

## Qué se importó, exactamente

Sólo las mallas que se usan — no los packs enteros. 652 modelos disponibles,
**80 importados**, 1,4 MB en disco.

- `assets/kenney/naturaleza/` — Nature Kit. Árboles, arbustos, tocones, rocas,
  flores, hongos, cercas, cultivos. **Sin texturas**: el color va en el
  material, que es justo lo que hace falta para un look estilizado plano.
- `assets/kenney/pueblo/` — Fantasy Town Kit. Muros y techos modulares (las
  casas se arman con estas piezas), carro, puesto, farol, molino, fuente.
- `assets/kenney/utiles/` — Survival Kit. Barriles, cajones, cofre, balde,
  herramientas, yunque, banco de trabajo, fogón, carteles, carpa.

`pueblo/` y `utiles/` comparten un atlas de color (`Textures/colormap.png`,
11 KB y 7 KB). Es **una textura por carpeta**, referenciada por todos los `.glb`
de esa carpeta — por eso la carpeta `Textures/` tiene que quedar al lado de los
`.glb` o Godot importa las mallas sin color.

Formato **glTF binario (`.glb`)** en los tres casos. Los packs también traen FBX,
OBJ, DAE y STL; se descartaron: FBX es problemático en Godot y glTF entra sin
configurar nada.
