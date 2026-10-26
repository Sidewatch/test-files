# 3D models

One toy rocket in every format a 3D preview meets, plus the cases that trip previews up: an animated
copy, a Z-up copy in centimetres and a dense mesh. Sidewatch's `--selftest-models` opens every one in a
real tab and its gallery, and `--selftest-corrupt-input` damages each and opens the copies; open them in
Finder too, where Quick Look shows the formats macOS reads and Sidewatch's extension shows glTF and GLB.

The rocket is 6 meshes (body, nose, fins, window frame, window, nozzle), 3,254 vertices and 5,216
triangles, 1 unit (a metre) tall, Y up, the window facing +Z. Its five materials are physically based:
red paint, brushed metal, glass, a dark nozzle and the textured body.

| File | Format | What it checks |
|---|---|---|
| `sample.usdz` | USD, packaged (binary layer and texture) | The format AR Quick Look takes; passes `usdchecker --arkit` |
| `sample.usda` | USD, text | `UsdPreviewSurface` materials, the texture beside it |
| `sample.usdc` | USD, binary | The same stage as `sample.usda` |
| `sample.obj`, `sample.mtl` | Wavefront OBJ | Six objects, materials by name, the texture by `map_Kd` |
| `sample.stl` | STL, binary | No colour; Z up and in millimetres, as 3D-printing files are, so a preview that assumes Y up shows it lying down |
| `sample.ply` | PLY, binary | A colour per vertex, as scans carry |
| `sample.abc` | Alembic | Geometry only: Model I/O writes no materials |
| `sample.dae` | Collada 1.4.1 | Phong materials, the texture beside it |
| `sample.scn` | SceneKit archive | The texture embedded |
| `sample.gltf`, `sample.bin` | glTF 2.0, JSON and a separate buffer | Metallic-roughness materials, the texture beside it |
| `sample.glb` | glTF 2.0, binary | Everything in one file, the texture embedded |
| `animated.usdz` | USD, packaged | Turns once every 4 seconds (time samples on the root) |
| `animated.glb` | glTF 2.0, binary | The same turn as a glTF animation |
| `z-up-centimetres.usda` | USD, text | `upAxis = "Z"` and `metersPerUnit = 0.01`: a preview should still stand it up at the same size |
| `dense-torus-knot.stl` | STL, binary | 57,600 smooth triangles, for load time and frame rate |
| `sample-uv-checker.png` | PNG | The body's texture: columns A–P round the body, rows 1–8 up it, so a flipped or mirrored texture coordinate shows at a glance |

There is no FBX: nothing on a Mac writes or reads one without a third-party library, so one could not be
checked here.

## What macOS does with them

Measured on macOS 27 when they were made:

- SceneKit opens every file here except the glTF and GLB files. Model I/O opens the USD, OBJ, STL, PLY and
  Alembic files.
- Finder's Quick Look previews 3D files through SceneKit's extension, which claims `public.3d-content`.
  macOS types glTF and GLB as 3D content too, but SceneKit cannot read them.
- `/usr/bin/usdcat` converts glTF and GLB to USD in 35–70 ms. SceneKit then shows the converted geometry,
  materials and animation, but not the glTF texture: the converter flips it through a `UsdTransform2d` node,
  which SceneKit does not follow.
- SceneKit ignores a USD file's `upAxis`.

## Regenerating

Run these in this folder, in order:

1. `swift make-models.swift texture` draws `sample-uv-checker.png` in `../fonts/sample.ttf`.
2. `python3 make-models.py` writes the OBJ and MTL, STL, PLY, glTF and BIN, GLB, Collada and USD text files.
3. `usdcat sample.usda -o sample.usdc && usdzip sample.usdz sample.usdc sample-uv-checker.png`
4. `usdcat animated.usda -o animated.usdc && usdzip animated.usdz animated.usdc sample-uv-checker.png && rm animated.usda animated.usdc`
5. `swift make-models.swift convert` writes `sample.scn` (SceneKit) and `sample.abc` (Model I/O) from `sample.usda`.
6. `usdchecker --arkit sample.usdz && usdchecker --arkit animated.usdz`
