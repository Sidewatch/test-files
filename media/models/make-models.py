#!/usr/bin/env python3
"""Writes the 3D model fixtures in this folder from one description of a toy rocket.

    python3 make-models.py [folder]

Standard library only. Writes the text and binary formats it can describe itself: sample.obj and
sample.mtl, sample.stl, sample.ply, sample.gltf and sample.bin, sample.glb, sample.dae, sample.usda,
animated.usda, animated.glb, z-up-centimetres.usda and dense-torus-knot.stl. The texture
(sample-uv-checker.png) must exist first; README.md lists every step in order.
"""

import json
import math
import pathlib
import struct
import sys

TEXTURE = "sample-uv-checker.png"
HEADER = "A toy rocket, a Sidewatch test model (make-models.py)."

# Physically based materials: base colour (linear), metallic, roughness, and the one texture.
MATERIALS = {
    "Body": {"color": (1.0, 1.0, 1.0), "metallic": 0.0, "roughness": 0.5, "texture": TEXTURE},
    "Paint": {"color": (0.80, 0.12, 0.10), "metallic": 0.0, "roughness": 0.35},
    "Metal": {"color": (0.62, 0.63, 0.66), "metallic": 1.0, "roughness": 0.3},
    "Glass": {"color": (0.20, 0.50, 0.85), "metallic": 0.0, "roughness": 0.05},
    "Nozzle": {"color": (0.18, 0.18, 0.20), "metallic": 0.9, "roughness": 0.55},
}
MATERIAL_ORDER = list(MATERIALS)


# Vectors


def add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def mul(a, s):
    return (a[0] * s, a[1] * s, a[2] * s)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def unit(a):
    length = math.sqrt(dot(a, a))
    return mul(a, 1 / length) if length > 1e-12 else (0.0, 1.0, 0.0)


def f32(x):
    """`x` as the 32-bit float a binary format stores."""
    return struct.unpack("<f", struct.pack("<f", x))[0]


def num(x):
    """A short, exact-enough decimal for the text formats."""
    text = f"{x:.6g}"
    return "0" if text == "-0" else text


# Meshes


class Mesh:
    """Triangles over vertices that each carry a position, a unit normal and a texture coordinate
    (OBJ's convention: v grows up the image)."""

    def __init__(self, name, material):
        self.name, self.material = name, material
        self.points, self.normals, self.uvs, self.triangles = [], [], [], []

    def vertex(self, point, normal, uv=(0.0, 0.0)):
        self.points.append(point)
        self.normals.append(unit(normal))
        self.uvs.append(uv)
        return len(self.points) - 1

    def triangle(self, a, b, c):
        """Adds a, b, c counter-clockwise seen from outside (the side the normals face); a
        zero-area triangle (a lathe's tip) is dropped."""
        face = cross(sub(self.points[b], self.points[a]), sub(self.points[c], self.points[a]))
        if dot(face, face) < 1e-20:
            return
        if dot(face, add(add(self.normals[a], self.normals[b]), self.normals[c])) < 0:
            b, c = c, b
        self.triangles.append((a, b, c))

    def grid(self, rows):
        """Two triangles per cell of a grid of vertex indices."""
        for i in range(len(rows) - 1):
            for j in range(len(rows[i]) - 1):
                a, b, c, d = rows[i][j], rows[i][j + 1], rows[i + 1][j + 1], rows[i + 1][j]
                self.triangle(a, b, c)
                self.triangle(a, c, d)

    def transformed(self, point_map, normal_map):
        copy = Mesh(self.name, self.material)
        copy.points = [point_map(p) for p in self.points]
        copy.normals = [unit(normal_map(n)) for n in self.normals]
        copy.uvs, copy.triangles = list(self.uvs), list(self.triangles)
        return copy

    def bounds(self):
        return (
            tuple(min(p[k] for p in self.points) for k in range(3)),
            tuple(max(p[k] for p in self.points) for k in range(3)),
        )


def lathe(mesh, strip, segments, v_range=None):
    """Turns a profile strip [(r, y), ...] around the Y axis. A strip running counter-clockwise
    round the solid's cross-section (out along the bottom, up the outside, in across the top)
    faces outwards. Angle 0 faces +Z and grows towards +X; u follows the angle, v the height."""
    rows = []
    for i, (r, y) in enumerate(strip):
        (r0, y0), (r1, y1) = strip[max(i - 1, 0)], strip[min(i + 1, len(strip) - 1)]
        nr, ny = y1 - y0, -(r1 - r0)
        v = (y - v_range[0]) / (v_range[1] - v_range[0]) if v_range else i / (len(strip) - 1)
        row = []
        for j in range(segments + 1):
            angle = 2 * math.pi * j / segments
            s, c = math.sin(angle), math.cos(angle)
            row.append(mesh.vertex((r * s, y, r * c), (nr * s, ny, nr * c), (j / segments, v)))
        rows.append(row)
    mesh.grid(rows)


def torus(mesh, centre, major, minor, segments, sides):
    """A ring in the XY plane round `centre`, facing +Z."""
    rows = []
    for i in range(segments + 1):
        u = 2 * math.pi * i / segments
        row = []
        for j in range(sides + 1):
            v = 2 * math.pi * j / sides
            normal = (math.cos(v) * math.cos(u), math.cos(v) * math.sin(u), math.sin(v))
            ring = major + minor * math.cos(v)
            point = (centre[0] + ring * math.cos(u), centre[1] + ring * math.sin(u), centre[2] + minor * math.sin(v))
            row.append(mesh.vertex(point, normal, (i / segments, j / sides)))
        rows.append(row)
    mesh.grid(rows)


def disc(mesh, centre, radius, segments):
    """A flat disc facing +Z."""
    middle = mesh.vertex(centre, (0, 0, 1), (0.5, 0.5))
    ring = []
    for k in range(segments + 1):
        a = 2 * math.pi * k / segments
        point = (centre[0] + radius * math.cos(a), centre[1] + radius * math.sin(a), centre[2])
        ring.append(mesh.vertex(point, (0, 0, 1), (0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a))))
    for k in range(segments):
        mesh.triangle(middle, ring[k], ring[k + 1])


def fin(mesh, angle, outline, thickness):
    """A flat fin standing out from the Y axis at `angle`: `outline` is a convex polygon in
    (distance from the axis, height), given the thickness, with flat faces."""
    out = (math.sin(angle), 0.0, math.cos(angle))
    side = (math.cos(angle), 0.0, -math.sin(angle))

    def at(r, y, s):
        return add(add(mul(out, r), (0.0, y, 0.0)), mul(side, s))

    half = thickness / 2
    for sign in (1, -1):
        face = [mesh.vertex(at(r, y, sign * half), mul(side, sign), (r, y)) for r, y in outline]
        for k in range(1, len(face) - 1):
            mesh.triangle(face[0], face[k], face[k + 1])
    centre = (sum(r for r, _ in outline) / len(outline), sum(y for _, y in outline) / len(outline))
    for k in range(len(outline)):
        (r0, y0), (r1, y1) = outline[k], outline[(k + 1) % len(outline)]
        nr, ny = y1 - y0, -(r1 - r0)
        if nr * ((r0 + r1) / 2 - centre[0]) + ny * ((y0 + y1) / 2 - centre[1]) < 0:
            nr, ny = -nr, -ny
        normal = add(mul(out, nr), (0.0, ny, 0.0))
        quad = [mesh.vertex(at(r, y, s), normal, (r, y)) for r, y, s in ((r0, y0, half), (r1, y1, half), (r1, y1, -half), (r0, y0, -half))]
        mesh.triangle(quad[0], quad[1], quad[2])
        mesh.triangle(quad[0], quad[2], quad[3])


def rocket():
    """The toy rocket, Y up, 1 unit (a metre) tall, its window facing +Z."""
    segments = 64
    body = Mesh("Body", "Body")
    tail = [(0.10 + 0.05 * math.sin(t / 8 * math.pi / 2), 0.08 + 0.08 * t / 8) for t in range(9)]
    lathe(body, [(0.0, 0.08), (0.10, 0.08)], segments, v_range=(0.08, 0.62))
    lathe(body, tail + [(0.15, 0.62)], segments, v_range=(0.08, 0.62))

    nose = Mesh("Nose", "Paint")
    lathe(nose, [(0.15 * (1 - (t / 16) ** 1.6), 0.62 + 0.38 * t / 16) for t in range(17)], segments)

    fins = Mesh("Fins", "Paint")
    for k in range(4):
        fin(fins, math.pi / 4 + k * math.pi / 2, [(0.13, 0.12), (0.30, 0.03), (0.30, 0.19), (0.13, 0.42)], 0.016)

    frame = Mesh("WindowFrame", "Metal")
    torus(frame, (0.0, 0.45, 0.152), 0.055, 0.012, 48, 16)
    glass = Mesh("Window", "Glass")
    disc(glass, (0.0, 0.45, 0.153), 0.055, 48)

    nozzle = Mesh("Nozzle", "Nozzle")
    for strip in ([(0.085, 0.0), (0.10, 0.0)], [(0.10, 0.0), (0.07, 0.085)], [(0.06, 0.06), (0.085, 0.0)]):
        lathe(nozzle, strip, segments)
    return [body, nose, fins, frame, glass, nozzle]


def torus_knot(p=2, q=3, segments=720, sides=40, tube=0.35):
    """A (2, 3) torus knot lying in the XY plane, Z up, its frames parallel-transported along the
    curve with the closing twist spread over the loop so the seam meets."""
    def curve(t):
        r = 2 + math.cos(q * t)
        return (r * math.cos(p * t), r * math.sin(p * t), math.sin(q * t))

    centres = [curve(2 * math.pi * i / segments) for i in range(segments)]
    tangents = [unit(sub(centres[(i + 1) % segments], centres[i - 1])) for i in range(segments)]
    normals = [unit(cross(tangents[0], (0.0, 0.0, 1.0)))]
    for t in tangents[1:]:
        previous = normals[-1]
        normals.append(unit(sub(previous, mul(t, dot(previous, t)))))
    t0 = tangents[0]
    carried = unit(sub(normals[-1], mul(t0, dot(normals[-1], t0))))
    twist = math.atan2(dot(cross(carried, normals[0]), t0), dot(carried, normals[0]))
    mesh = Mesh("TorusKnot", "Paint")
    rows = []
    for i in range(segments + 1):
        k = i % segments
        a = twist * k / segments
        t, n = tangents[k], normals[k]
        n = add(mul(n, math.cos(a)), mul(cross(t, n), math.sin(a)))
        b = cross(t, n)
        row = []
        for j in range(sides + 1):
            angle = 2 * math.pi * j / sides
            d = add(mul(n, math.cos(angle)), mul(b, math.sin(angle)))
            row.append(mesh.vertex(add(centres[k], mul(d, tube)), d, (i / segments, j / sides)))
        rows.append(row)
    mesh.grid(rows)
    return mesh


def z_up(scale):
    """Y up to Z up (a quarter turn about X), scaled: the front (+Z) becomes -Y."""
    return (lambda p: (p[0] * scale, -p[2] * scale, p[1] * scale)), (lambda n: (n[0], -n[2], n[1]))


# OBJ and MTL


def write_obj(meshes, folder):
    lines = [f"# {HEADER} Y up, metres.", "mtllib sample.mtl"]
    base = 1
    for m in meshes:
        lines.append(f"o {m.name}")
        lines += [f"v {num(p[0])} {num(p[1])} {num(p[2])}" for p in m.points]
        lines += [f"vt {num(uv[0])} {num(uv[1])}" for uv in m.uvs]
        lines += [f"vn {num(n[0])} {num(n[1])} {num(n[2])}" for n in m.normals]
        lines.append(f"usemtl {m.material}")
        lines += ["f " + " ".join(f"{i + base}/{i + base}/{i + base}" for i in tri) for tri in m.triangles]
        base += len(m.points)
    (folder / "sample.obj").write_text("\n".join(lines) + "\n")
    mtl = [f"# Materials for sample.obj. {HEADER}"]
    for name, mat in MATERIALS.items():
        r, g, b = mat["color"]
        specular = mat["color"] if mat["metallic"] > 0.5 else (0.5, 0.5, 0.5)
        mtl += [
            "",
            f"newmtl {name}",
            f"Kd {num(r)} {num(g)} {num(b)}",
            f"Ks {num(specular[0])} {num(specular[1])} {num(specular[2])}",
            f"Ns {num(round((1 - mat['roughness']) ** 2 * 900 + 10))}",
            "d 1",
            "illum 2",
        ]
        if "texture" in mat:
            mtl.append(f"map_Kd {mat['texture']}")
    (folder / "sample.mtl").write_text("\n".join(mtl) + "\n")


# STL (binary) and PLY (binary, vertex colours)


def write_stl(meshes, path, header):
    triangles = [(m, tri) for m in meshes for tri in m.triangles]
    data = bytearray(header.encode("ascii").ljust(80, b" ")[:80])
    assert not data.startswith(b"solid"), "a binary STL must not look like an ASCII one"
    data += struct.pack("<I", len(triangles))
    for m, (a, b, c) in triangles:
        pa, pb, pc = m.points[a], m.points[b], m.points[c]
        normal = unit(cross(sub(pb, pa), sub(pc, pa)))
        data += struct.pack("<12fH", *normal, *pa, *pb, *pc, 0)
    path.write_bytes(bytes(data))


def write_ply(meshes, path):
    vertices = sum(len(m.points) for m in meshes)
    faces = sum(len(m.triangles) for m in meshes)
    header = "\n".join(
        [
            "ply",
            "format binary_little_endian 1.0",
            f"comment {HEADER} Y up, metres, a colour per vertex.",
            f"element vertex {vertices}",
            "property float x", "property float y", "property float z",
            "property float nx", "property float ny", "property float nz",
            "property uchar red", "property uchar green", "property uchar blue",
            f"element face {faces}",
            "property list uchar uint vertex_indices",
            "end_header",
        ]
    ) + "\n"
    data = bytearray(header.encode("ascii"))
    for m in meshes:
        colour = (0.92, 0.92, 0.92) if m.material == "Body" else MATERIALS[m.material]["color"]
        rgb = tuple(round(255 * c) for c in colour)
        for p, n in zip(m.points, m.normals):
            data += struct.pack("<6f3B", *p, *n, *rgb)
    base = 0
    for m in meshes:
        for a, b, c in m.triangles:
            data += struct.pack("<B3I", 3, a + base, b + base, c + base)
        base += len(m.points)
    path.write_bytes(bytes(data))


# glTF 2.0 and GLB


class GLTFBuilder:
    """One glTF document over one binary buffer."""

    def __init__(self):
        self.binary = bytearray()
        self.doc = {
            "asset": {"version": "2.0", "generator": "Sidewatch test files, make-models.py"},
            "scene": 0,
            "scenes": [{"name": "Rocket", "nodes": [0]}],
            "nodes": [],
            "meshes": [],
            "materials": [],
            "accessors": [],
            "bufferViews": [],
        }

    def view(self, data, target=None):
        while len(self.binary) % 4:
            self.binary.append(0)
        view = {"buffer": 0, "byteOffset": len(self.binary), "byteLength": len(data)}
        if target:
            view["target"] = target
        self.binary += data
        self.doc["bufferViews"].append(view)
        return len(self.doc["bufferViews"]) - 1

    def accessor(self, values, kind, width, target=None, bounds=False, component=5126):
        code = {5126: "f", 5123: "H", 5125: "I"}[component]
        flat = [x for v in values for x in v] if width > 1 else list(values)
        accessor = {
            "bufferView": self.view(struct.pack(f"<{len(flat)}{code}", *flat), target),
            "componentType": component,
            "count": len(values),
            "type": kind,
        }
        if bounds:
            columns = [[f32(v[k]) if width > 1 else f32(v) for v in values] for k in range(width)]
            accessor["min"] = [min(c) for c in columns]
            accessor["max"] = [max(c) for c in columns]
        self.doc["accessors"].append(accessor)
        return len(self.doc["accessors"]) - 1

    def add_materials(self, image):
        self.doc["materials"] = []
        for name, mat in MATERIALS.items():
            pbr = {"baseColorFactor": [*mat["color"], 1.0], "metallicFactor": mat["metallic"], "roughnessFactor": mat["roughness"]}
            if "texture" in mat:
                pbr["baseColorTexture"] = {"index": 0}
            self.doc["materials"].append({"name": name, "pbrMetallicRoughness": pbr})
        self.doc["samplers"] = [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}]
        self.doc["textures"] = [{"sampler": 0, "source": 0}]
        self.doc["images"] = [image]

    def add_meshes(self, meshes):
        self.doc["nodes"] = [{"name": "Rocket", "children": list(range(1, len(meshes) + 1))}]
        for m in meshes:
            # glTF's texture coordinates start at the image's top: v is flipped.
            attributes = {
                "POSITION": self.accessor(m.points, "VEC3", 3, 34962, bounds=True),
                "NORMAL": self.accessor(m.normals, "VEC3", 3, 34962),
                "TEXCOORD_0": self.accessor([(u, 1 - v) for u, v in m.uvs], "VEC2", 2, 34962),
            }
            component = 5123 if len(m.points) < 65536 else 5125
            indices = self.accessor([i for tri in m.triangles for i in tri], "SCALAR", 1, 34963, component=component)
            primitive = {"attributes": attributes, "indices": indices, "material": MATERIAL_ORDER.index(m.material)}
            self.doc["meshes"].append({"name": m.name, "primitives": [primitive]})
            self.doc["nodes"].append({"name": m.name, "mesh": len(self.doc["meshes"]) - 1})

    def add_spin(self, seconds=4.0, keys=8):
        """Turns the root node once about Y over `seconds`, looping."""
        times = [seconds * k / keys for k in range(keys + 1)]
        turns = [(0.0, math.sin(math.pi * k / keys), 0.0, math.cos(math.pi * k / keys)) for k in range(keys + 1)]
        sampler = {"input": self.accessor(times, "SCALAR", 1, bounds=True), "output": self.accessor(turns, "VEC4", 4), "interpolation": "LINEAR"}
        self.doc["animations"] = [{"name": "Spin", "samplers": [sampler], "channels": [{"sampler": 0, "target": {"node": 0, "path": "rotation"}}]}]

    def gltf(self, folder, name):
        self.doc["buffers"] = [{"uri": f"{name}.bin", "byteLength": len(self.binary)}]
        (folder / f"{name}.bin").write_bytes(bytes(self.binary))
        (folder / f"{name}.gltf").write_text(json.dumps(self.doc, indent=2) + "\n")

    def glb(self, path):
        self.doc["buffers"] = [{"byteLength": len(self.binary)}]
        text = json.dumps(self.doc, separators=(",", ":")).encode()
        text += b" " * (-len(text) % 4)
        binary = bytes(self.binary) + b"\0" * (-len(self.binary) % 4)
        total = 12 + 8 + len(text) + 8 + len(binary)
        path.write_bytes(
            struct.pack("<3I", 0x46546C67, 2, total)
            + struct.pack("<2I", len(text), 0x4E4F534A) + text
            + struct.pack("<2I", len(binary), 0x004E4942) + binary
        )


def check_gltf(doc, binary):
    """The glTF rules a hand-written file most easily breaks."""
    views = doc["bufferViews"]
    for view in views:
        assert view["byteOffset"] % 4 == 0 and view["byteOffset"] + view["byteLength"] <= len(binary)
    sizes = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
    for accessor in doc["accessors"]:
        view = views[accessor["bufferView"]]
        width = {5126: 4, 5123: 2, 5125: 4}[accessor["componentType"]]
        assert accessor["count"] * sizes[accessor["type"]] * width <= view["byteLength"]
    for mesh in doc["meshes"]:
        for primitive in mesh["primitives"]:
            position = doc["accessors"][primitive["attributes"]["POSITION"]]
            assert "min" in position and "max" in position
            indices = doc["accessors"][primitive["indices"]]
            view = views[indices["bufferView"]]
            code = {5123: "H", 5125: "I"}[indices["componentType"]]
            values = struct.unpack_from(f"<{indices['count']}{code}", binary, view["byteOffset"])
            assert max(values) < position["count"] and indices["count"] % 3 == 0


def write_gltf_files(meshes, folder):
    png = (folder / TEXTURE).read_bytes()
    separate = GLTFBuilder()
    separate.add_meshes(meshes)
    separate.add_materials({"uri": TEXTURE, "mimeType": "image/png"})
    check_gltf(separate.doc, separate.binary)
    separate.gltf(folder, "sample")
    for name, animated in (("sample.glb", False), ("animated.glb", True)):
        packed = GLTFBuilder()
        packed.add_meshes(meshes)
        packed.add_materials({"bufferView": packed.view(png), "mimeType": "image/png"})
        if animated:
            packed.add_spin()
        check_gltf(packed.doc, packed.binary)
        packed.glb(folder / name)


# USD (text)


def usd_array(kind, values, per_line, fmt):
    rows = [", ".join(fmt(v) for v in values[i : i + per_line]) for i in range(0, len(values), per_line)]
    return f"{kind} = [\n            " + ",\n            ".join(rows) + "\n        ]"


def usd_mesh(m):
    triple = lambda v: f"({num(v[0])}, {num(v[1])}, {num(v[2])})"
    low, high = m.bounds()
    return f"""
    def Mesh "{m.name}" (
        prepend apiSchemas = ["MaterialBindingAPI"]
    )
    {{
        float3[] extent = [{triple(low)}, {triple(high)}]
        {usd_array("int[] faceVertexCounts", [3] * len(m.triangles), 40, str)}
        {usd_array("int[] faceVertexIndices", [i for tri in m.triangles for i in tri], 30, str)}
        rel material:binding = </Rocket/Materials/{m.material}>
        {usd_array("normal3f[] normals", m.normals, 4, triple)} (
            interpolation = "vertex"
        )
        {usd_array("point3f[] points", m.points, 4, triple)}
        {usd_array("texCoord2f[] primvars:st", m.uvs, 6, lambda v: f"({num(v[0])}, {num(v[1])})")} (
            interpolation = "vertex"
        )
        uniform token subdivisionScheme = "none"
    }}
"""


def usd_material(name, mat):
    path = f"/Rocket/Materials/{name}"
    r, g, b = mat["color"]
    if "texture" in mat:
        colour = f"color3f inputs:diffuseColor.connect = <{path}/Texture.outputs:rgb>"
        texture = f"""
            def Shader "Texture"
            {{
                uniform token info:id = "UsdUVTexture"
                asset inputs:file = @{mat["texture"]}@
                token inputs:sourceColorSpace = "sRGB"
                float2 inputs:st.connect = <{path}/TexCoords.outputs:result>
                token inputs:wrapS = "repeat"
                token inputs:wrapT = "repeat"
                float3 outputs:rgb
            }}

            def Shader "TexCoords"
            {{
                uniform token info:id = "UsdPrimvarReader_float2"
                string inputs:varname = "st"
                float2 outputs:result
            }}"""
    else:
        colour = f"color3f inputs:diffuseColor = ({num(r)}, {num(g)}, {num(b)})"
        texture = ""
    return f"""
        def Material "{name}"
        {{
            token outputs:surface.connect = <{path}/Surface.outputs:surface>

            def Shader "Surface"
            {{
                uniform token info:id = "UsdPreviewSurface"
                {colour}
                float inputs:metallic = {num(mat["metallic"])}
                float inputs:roughness = {num(mat["roughness"])}
                token outputs:surface
            }}{texture}
        }}
"""


def write_usda(meshes, path, doc, up="Y", meters_per_unit=1, spin_frames=0):
    timing = ""
    spin = ""
    if spin_frames:
        timing = f"\n    startTimeCode = 0\n    endTimeCode = {spin_frames}\n    timeCodesPerSecond = 24"
        samples = ",\n            ".join(f"{f}: {num(360 * f / spin_frames)}" for f in range(0, spin_frames + 1, 4))
        spin = f"""    float xformOp:rotateY.timeSamples = {{
            {samples},
        }}
    uniform token[] xformOpOrder = ["xformOp:rotateY"]
"""
    materials = "".join(usd_material(name, mat) for name, mat in MATERIALS.items())
    text = f"""#usda 1.0
(
    defaultPrim = "Rocket"
    doc = "{doc}"
    metersPerUnit = {num(meters_per_unit)}
    upAxis = "{up}"{timing}
)

def Xform "Rocket" (
    kind = "component"
)
{{
{spin}    def Scope "Materials"
    {{{materials}    }}
{"".join(usd_mesh(m) for m in meshes)}}}
"""
    path.write_text(text)


# Collada 1.4.1


def write_dae(meshes, path):
    """Collada with one effect per material (the texture on the body), Y up, metres."""
    def floats(values):
        return " ".join(num(x) for v in values for x in v)

    effects, materials, geometries, nodes = [], [], [], []
    for name, mat in MATERIALS.items():
        r, g, b = mat["color"]
        if "texture" in mat:
            diffuse = '<texture texture="checker-sampler" texcoord="UVMap"/>'
            params = f"""
          <newparam sid="checker-surface"><surface type="2D"><init_from>checker-image</init_from></surface></newparam>
          <newparam sid="checker-sampler"><sampler2D><source>checker-surface</source></sampler2D></newparam>"""
        else:
            diffuse = f"<color>{num(r)} {num(g)} {num(b)} 1</color>"
            params = ""
        shininess = num(round((1 - mat["roughness"]) ** 2 * 90 + 2))
        effects.append(f"""    <effect id="{name}-effect">
      <profile_COMMON>{params}
        <technique sid="common">
          <phong>
            <diffuse>{diffuse}</diffuse>
            <specular><color>0.5 0.5 0.5 1</color></specular>
            <shininess><float>{shininess}</float></shininess>
          </phong>
        </technique>
      </profile_COMMON>
    </effect>""")
        materials.append(f'    <material id="{name}-material" name="{name}"><instance_effect url="#{name}-effect"/></material>')
    for m in meshes:
        gid = f"{m.name}-mesh"
        count = len(m.points)
        indices = " ".join(str(i) for tri in m.triangles for i in tri)
        geometries.append(f"""    <geometry id="{gid}" name="{m.name}">
      <mesh>
        <source id="{gid}-positions">
          <float_array id="{gid}-positions-array" count="{count * 3}">{floats(m.points)}</float_array>
          <technique_common><accessor source="#{gid}-positions-array" count="{count}" stride="3"><param name="X" type="float"/><param name="Y" type="float"/><param name="Z" type="float"/></accessor></technique_common>
        </source>
        <source id="{gid}-normals">
          <float_array id="{gid}-normals-array" count="{count * 3}">{floats(m.normals)}</float_array>
          <technique_common><accessor source="#{gid}-normals-array" count="{count}" stride="3"><param name="X" type="float"/><param name="Y" type="float"/><param name="Z" type="float"/></accessor></technique_common>
        </source>
        <source id="{gid}-map">
          <float_array id="{gid}-map-array" count="{count * 2}">{floats(m.uvs)}</float_array>
          <technique_common><accessor source="#{gid}-map-array" count="{count}" stride="2"><param name="S" type="float"/><param name="T" type="float"/></accessor></technique_common>
        </source>
        <vertices id="{gid}-vertices"><input semantic="POSITION" source="#{gid}-positions"/></vertices>
        <triangles material="{m.material}-material" count="{len(m.triangles)}">
          <input semantic="VERTEX" source="#{gid}-vertices" offset="0"/>
          <input semantic="NORMAL" source="#{gid}-normals" offset="0"/>
          <input semantic="TEXCOORD" source="#{gid}-map" offset="0" set="0"/>
          <p>{indices}</p>
        </triangles>
      </mesh>
    </geometry>""")
        nodes.append(f"""        <node id="{m.name}" name="{m.name}" type="NODE">
          <instance_geometry url="#{gid}">
            <bind_material><technique_common><instance_material symbol="{m.material}-material" target="#{m.material}-material"><bind_vertex_input semantic="UVMap" input_semantic="TEXCOORD" input_set="0"/></instance_material></technique_common></bind_material>
          </instance_geometry>
        </node>""")
    newline = "\n"
    path.write_text(f"""<?xml version="1.0" encoding="utf-8"?>
<!-- {HEADER} -->
<COLLADA xmlns="http://www.collada.org/2005/11/COLLADASchema" version="1.4.1">
  <asset>
    <contributor><authoring_tool>Sidewatch test files, make-models.py</authoring_tool></contributor>
    <created>2026-10-26T00:00:00Z</created>
    <modified>2026-10-26T00:00:00Z</modified>
    <unit name="meter" meter="1"/>
    <up_axis>Y_UP</up_axis>
  </asset>
  <library_images>
    <image id="checker-image" name="checker"><init_from>{TEXTURE}</init_from></image>
  </library_images>
  <library_effects>
{newline.join(effects)}
  </library_effects>
  <library_materials>
{newline.join(materials)}
  </library_materials>
  <library_geometries>
{newline.join(geometries)}
  </library_geometries>
  <library_visual_scenes>
    <visual_scene id="Scene" name="Scene">
      <node id="Rocket" name="Rocket" type="NODE">
{newline.join(nodes)}
      </node>
    </visual_scene>
  </library_visual_scenes>
  <scene><instance_visual_scene url="#Scene"/></scene>
</COLLADA>
""")


def main():
    folder = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else pathlib.Path(__file__).parent)
    if not (folder / TEXTURE).exists():
        sys.exit(f"{TEXTURE} is missing: draw it first (README.md)")
    meshes = rocket()
    write_obj(meshes, folder)
    write_stl([m.transformed(*z_up(100)) for m in meshes], folder / "sample.stl", "Toy rocket, Sidewatch test model. Z up, millimetres.")
    write_ply(meshes, folder / "sample.ply")
    write_gltf_files(meshes, folder)
    write_dae(meshes, folder / "sample.dae")
    write_usda(meshes, folder / "sample.usda", HEADER)
    write_usda(meshes, folder / "animated.usda", f"{HEADER} Turns once every 4 seconds.", spin_frames=96)
    write_usda(
        [m.transformed(*z_up(100)) for m in meshes], folder / "z-up-centimetres.usda", f"{HEADER} Z up, centimetres.",
        up="Z", meters_per_unit=0.01,
    )
    knot = torus_knot().transformed(lambda p: mul(p, 12), lambda n: n)
    write_stl([knot], folder / "dense-torus-knot.stl", "Torus knot, Sidewatch test model. Z up, millimetres.")
    triangles = sum(len(m.triangles) for m in meshes)
    vertices = sum(len(m.points) for m in meshes)
    print(f"rocket: {len(meshes)} meshes, {vertices:,} vertices, {triangles:,} triangles; knot: {len(knot.triangles):,} triangles")


if __name__ == "__main__":
    main()
