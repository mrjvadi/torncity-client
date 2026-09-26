#!/usr/bin/env python3
"""Build the runtime asset set for the CDN: dist-assets/ + manifest.json.

    python3 tools/build_assets/build.py [--out dist-assets] [--base-url https://cdn.example.com/torncity/]

Inputs
  * the asset library, art_src/cdn/library.json: content keys -> model parts
    (Kenney meshes), badge glyphs (game-icons.net) and tints;
  * the Kenney kits and the game-icons.net archive, downloaded into
    tools/kenney/ by tools/build_assets/fetch_sources.sh;
  * drop-in files, art_src/cdn/<category>/<name>.<ext>, published under the
    content key "<category>:<name>" (sub-folders become more ":" parts), e.g.
    art_src/cdn/company/bakery.glb -> "company:bakery".

What it does
  * GLB: every external texture is embedded as WebP (EXT_texture_webp, which
    Godot 4 loads at runtime); JSON is minified. Geometry is left as is: Godot
    4.7's runtime glTF loader does not read KHR_mesh_quantization,
    EXT_meshopt_compression or Draco, so those would break loading.
  * SVG glyphs: whitespace-minified.
  * PNG/JPG textures: converted to WebP (lossless for flat-colour art).
  * Every file is content-addressed: <dir>/<sha256[:16]>-<name>.<ext>, so it
    can be cached forever (Cache-Control: immutable).
  * manifest.json: {version, base_url, generated, assets: {key: {path, type,
    sha256, bytes, fallback?}}}. Only the manifest changes between builds.
"""
import argparse
import datetime
import gzip
import hashlib
import io
import json
import os
import re
import shutil
import struct
import sys
import zipfile

from PIL import Image

try:
    import brotli  # optional: pip install brotli
except ImportError:
    brotli = None

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "tools", "kenney")
CDN_SRC = os.path.join(ROOT, "art_src", "cdn")

KITS = {
    "city-kit-commercial": "kenney_city-kit-commercial_2.1.zip",
    "city-kit-industrial": "kenney_city-kit-industrial_2.0.zip",
    "city-kit-roads": "kenney_city-kit-roads.zip",
    "city-kit-suburban": "kenney_city-kit-suburban_20.zip",
    "car-kit": "kenney_car-kit.zip",
    "train-kit": "kenney_train-kit.zip",
    "factory-kit": "kenney_factory-kit_3.0.zip",
    "pirate-kit": "kenney_pirate-kit.zip",
    "blaster-kit": "kenney_blaster-kit_2.1.zip",
    "food-kit": "kenney_food-kit.zip",
    "racing-kit": "kenney_racing-kit.zip",
}
GAME_ICONS = "game-icons.net.svg.zip"
GLYPH_AUTHORS = {  # preferred author when several drew the same name
    "key": "lorc", "castle": "lorc", "bowie-knife": "lorc", "smartphone": "delapouite",
}


# -- GLB ------------------------------------------------------------------------------------------
def glb_read(data: bytes):
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise ValueError("not a GLB")
    off = 12
    js, binc = None, b""
    while off < length:
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            binc = bytes(chunk)
        off += 8 + clen
    return js, binc


def glb_write(js: dict, binc: bytes) -> bytes:
    j = json.dumps(js, separators=(",", ":")).encode("utf-8")
    j += b" " * ((4 - len(j) % 4) % 4)
    binc += b"\0" * ((4 - len(binc) % 4) % 4)
    total = 12 + 8 + len(j) + (8 + len(binc) if binc else 0)
    out = struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(j), 0x4E4F534A) + j
    if binc:
        out += struct.pack("<II", len(binc), 0x004E4942) + binc
    return out


def to_webp(png_bytes: bytes) -> bytes:
    im = Image.open(io.BytesIO(png_bytes))
    im = im.convert("RGBA") if im.mode in ("P", "LA", "RGBA") else im.convert("RGB")
    buf = io.BytesIO()
    im.save(buf, "WEBP", lossless=True, method=6)
    return buf.getvalue()


def pack_glb(data: bytes, read_external) -> bytes:
    """Embed external images as WebP buffer views (EXT_texture_webp)."""
    js, binc = glb_read(data)
    binc = bytearray(binc)
    if "buffers" not in js or not js["buffers"]:
        js["buffers"] = [{"byteLength": 0}]
    webp_images = set()
    for i, img in enumerate(js.get("images", [])):
        raw = None
        if "uri" in img and not img["uri"].startswith("data:"):
            raw = read_external(img["uri"])
        elif "bufferView" in img and img.get("mimeType") == "image/png":
            bv = js["bufferViews"][img["bufferView"]]
            s = bv.get("byteOffset", 0)
            raw = bytes(binc[s:s + bv["byteLength"]])
        if raw is None:
            continue
        webp = to_webp(raw)
        while len(binc) % 4:
            binc.append(0)
        js.setdefault("bufferViews", []).append({"buffer": 0, "byteOffset": len(binc), "byteLength": len(webp)})
        binc += webp
        js["images"][i] = {"bufferView": len(js["bufferViews"]) - 1, "mimeType": "image/webp"}
        webp_images.add(i)
    if webp_images:
        for t in js.get("textures", []):
            src = t.get("source")
            if src in webp_images:
                t.pop("source", None)
                t.setdefault("extensions", {})["EXT_texture_webp"] = {"source": src}
        for k in ("extensionsUsed", "extensionsRequired"):
            if "EXT_texture_webp" not in js.setdefault(k, []):
                js[k].append("EXT_texture_webp")
    js["buffers"][0]["byteLength"] = len(binc)
    js["buffers"][0].pop("uri", None)
    return glb_write(js, bytes(binc))


# -- output ---------------------------------------------------------------------------------------
class Out:
    def __init__(self, root, base_url):
        self.root = root
        self.base_url = base_url
        self.assets = {}

    def put(self, key, data: bytes, kind: str, name: str, sub: str, fallback=None):
        sha = hashlib.sha256(data).hexdigest()
        rel = "%s/%s-%s.%s" % (sub, sha[:16], re.sub(r"[^a-z0-9_.-]+", "-", name.lower()), kind)
        path = os.path.join(self.root, rel)
        if not os.path.exists(path):
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "wb") as fh:
                fh.write(data)
            # precompressed siblings for nginx gzip_static / brotli_static
            gz = gzip.compress(data, 9)
            if len(gz) < len(data) * 0.9:
                with open(path + ".gz", "wb") as fh:
                    fh.write(gz)
                if brotli:
                    with open(path + ".br", "wb") as fh:
                        fh.write(brotli.compress(data, quality=11))
        e = {"path": rel, "type": kind, "sha256": sha, "bytes": len(data)}
        if fallback:
            e["fallback"] = fallback
        self.assets[key] = e

    def manifest(self, version):
        m = {"version": version, "base_url": self.base_url,
             "generated": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
             "assets": dict(sorted(self.assets.items()))}
        with open(os.path.join(self.root, "manifest.json"), "w") as fh:
            json.dump(m, fh, indent=1)
        return m


def library_refs(lib):
    meshes, glyphs = set(), set()
    for m in lib.get("models", {}).values():
        for p in m.get("parts", []):
            if p.get("mesh"):
                meshes.add(p["mesh"])
    for v in lib.get("roads", {}).values():
        meshes.add(v)
    for m in lib.get("dressing", {}).values():
        meshes.add(m)
    for v in lib.get("icons", {}).values():
        if isinstance(v, dict) and v.get("glyph"):
            glyphs.add(v["glyph"])
    for g in lib.get("extra_glyphs", []):
        glyphs.add(g)
    return meshes, glyphs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(ROOT, "dist-assets"))
    ap.add_argument("--base-url", default="")
    ap.add_argument("--clean", action="store_true")
    a = ap.parse_args()
    if a.clean and os.path.isdir(a.out):
        shutil.rmtree(a.out)
    os.makedirs(a.out, exist_ok=True)
    # inside the Godot project folder: keep the editor from importing it
    open(os.path.join(a.out, ".gdignore"), "w").close()
    out = Out(a.out, a.base_url)
    with open(os.path.join(CDN_SRC, "library.json"), encoding="utf-8") as fh:
        lib = json.load(fh)
    meshes, glyphs = library_refs(lib)

    # Kenney meshes the library uses
    zips = {k: zipfile.ZipFile(os.path.join(SRC, z)) for k, z in KITS.items() if os.path.exists(os.path.join(SRC, z))}
    missing = []
    for mesh in sorted(meshes):
        kit, name = mesh.split("/", 1)
        z = zips.get(kit)
        if z is None:
            missing.append(mesh)
            continue
        names = z.namelist()
        cand = [n for n in names if n.endswith("/" + name + ".glb") and ("GLB" in n or "GLTF" in n)]
        if not cand:
            missing.append(mesh)
            continue
        src = cand[0]
        folder = src.rsplit("/", 1)[0]

        def ext(uri, folder=folder, z=z):
            return z.read(folder + "/" + uri)
        out.put("mesh:" + mesh, pack_glb(z.read(src), ext), "glb", name, "m")
    # game-icons.net glyphs (CC BY 3.0: credits recorded per glyph)
    credits = []
    gz = zipfile.ZipFile(os.path.join(SRC, GAME_ICONS))
    found = {}
    for n in gz.namelist():
        if n.endswith(".svg"):
            found.setdefault(os.path.basename(n)[:-4], {})[n.split("/")[-2]] = n
    for g in sorted(glyphs):
        if g not in found:
            missing.append("glyph:" + g)
            continue
        author = GLYPH_AUTHORS.get(g) if GLYPH_AUTHORS.get(g) in found[g] else sorted(found[g])[0]
        svg = re.sub(r">\s+<", "><", gz.read(found[g][author]).decode("utf-8")).strip().encode("utf-8")
        out.put("glyph:" + g, svg, "svg", g, "i")
        credits.append({"icon": g, "author": author, "url": "https://game-icons.net/1x1/%s/%s.html" % (author, g)})
    out.put("data:icon-credits", json.dumps({"source": "https://game-icons.net", "license": "CC BY 3.0",
                                             "icons": credits}, ensure_ascii=False).encode("utf-8"), "json", "icon-credits", "d")
    # drop-in files: art_src/cdn/<category>/<name>.<ext> -> "<category>:<name>"
    for root, _, files in os.walk(CDN_SRC):
        for f in files:
            if f == "library.json" or f.startswith(".") or f.endswith(".md"):
                continue
            rel = os.path.relpath(os.path.join(root, f), CDN_SRC)
            stem, ext = os.path.splitext(rel)
            ext = ext.lower().lstrip(".")
            key = stem.replace(os.sep, ":")
            data = open(os.path.join(root, f), "rb").read()
            if ext == "glb":
                data = pack_glb(data, lambda uri, root=root: open(os.path.join(root, uri), "rb").read())
            elif ext in ("png", "jpg", "jpeg"):
                data, ext = to_webp(data), "webp"
            elif ext == "svg":
                data = re.sub(rb">\s+<", b"><", data).strip()
            elif ext not in ("webp", "ttf", "otf", "ogg", "json"):
                print("skipped (type):", rel)
                continue
            cat = key.split(":")[0]
            out.put(key, data, ext, os.path.basename(stem), "x", fallback=cat + ":*")
    # the library itself, so the owner can remap keys without a client release
    out.put("data:library", json.dumps(lib, ensure_ascii=False, separators=(",", ":")).encode("utf-8"), "json", "library", "d")
    version = hashlib.sha256(json.dumps({k: v["sha256"] for k, v in out.assets.items()}, sort_keys=True).encode()).hexdigest()[:12]
    m = out.manifest(version)
    total = sum(e["bytes"] for e in m["assets"].values())
    print("%d assets, %.2f MB, version %s -> %s" % (len(m["assets"]), total / 1e6, version, a.out))
    if missing:
        print("missing:", ", ".join(missing))
        sys.exit(1)


if __name__ == "__main__":
    main()
