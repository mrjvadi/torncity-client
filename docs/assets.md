# Runtime assets (CDN)

The Godot build carries no game art. It bundles only the UI theme, the fonts,
the splash, the UI chrome icons and 13 fallback glyphs (`assets/core/`). Every
model, icon and avatar is downloaded at runtime from a CDN and cached.

| | Before | After |
|---|---|---|
| Art in the `.pck` | ~18.3 MB (Kenney 16.3, icons 0.7, 2D art 0.9, fonts 0.4) | ~0.36 MB (fonts 0.21, UI kit 0.03, chrome icons 0.08, core 0.04) |
| Whole pack payload (imported + scripts/scenes/data) | ~18.7 MB | **~0.87 MB** |
| CDN set (all assets) | — | 7.2 MB raw, **1.45 MB gzip / 1.03 MB brotli** on the wire, fetched on demand |

## Pieces

- `tools/build_assets/fetch_sources.sh`: downloads the sources (Kenney kits, CC0;
  game-icons.net, CC BY 3.0) into `tools/kenney/` (`sources.txt` lists the URLs).
- `tools/build_assets/build.py`: builds `dist-assets/` — the files and `manifest.json`.
- `tools/build_assets/serve.py`: serves `dist-assets/` in development with the CDN's headers.
- `art_src/cdn/library.json`: the asset library (see below); also published as `data:library`.
- `art_src/cdn/<category>/<name>.<ext>`: drop-in files, published as `<category>:<name>`.
- `src/autoload/asset_service.gd`: download, verify, cache, decode.
- `src/autoload/asset_lib.gd`: turns content keys into models and icons, with fallbacks.

## Manifest

`GET <cdn>/manifest.json`:

```json
{
  "version": "e55ceae25834",
  "base_url": "",
  "generated": "2026-09-26T08:10:00+00:00",
  "assets": {
    "mesh:city-kit-commercial/building-a": {"path": "m/5a1f…-building-a.glb", "type": "glb", "sha256": "5a1f…", "bytes": 88321},
    "glyph:pistol-gun": {"path": "i/9c2e…-pistol-gun.svg", "type": "svg", "sha256": "9c2e…", "bytes": 2210},
    "avatar:fox": {"path": "x/0b7d…-fox.svg", "type": "svg", "sha256": "0b7d…", "bytes": 5120, "fallback": "avatar:*", "scale": 1.0},
    "company:bakery": {"path": "x/…-bakery.glb", "type": "glb", "sha256": "…", "bytes": 60412, "fallback": "company:*"},
    "data:library": {"path": "d/…-library.json", "type": "json", "sha256": "…", "bytes": 21000},
    "data:icon-credits": {"path": "d/…-icon-credits.json", "type": "json", "sha256": "…", "bytes": 9000}
  }
}
```

- `type`: `glb | svg | webp | png | ttf | otf | ogg | json`.
- `base_url`: empty means "the folder the manifest came from" (`cdn_url`).
- Keys: content keys (`company:factory`, `item:pistol`, `avatar:fox`), plus
  `mesh:<kit>/<model>` and `glyph:<name>` that the library composes, and `data:*`.

## Client behaviour (AssetService)

- Fetches the manifest at start (and keeps the last one in `user://assets/manifest.json`,
  so art works offline and paints before the network answers).
- Downloads on demand: `get_asset(key)` returns the asset or null and queues it.
  Priority: visible first, prefetch after; at most 4 parallel downloads.
- Verifies SHA-256, stores the file as `user://assets/<sha256>` (content-addressed:
  a changed file has a new hash, so there is nothing to invalidate).
- Retries after 1 s, 3 s and 9 s, then gives up for the session.
- Meanwhile: 3D parts are procedural stand-ins (a block shaped by the key's
  category), icons are the category's bundled glyph with a shimmer; both swap in
  when the asset lands.
- Decoding at runtime, per the Godot 4.7 API (checked against the 4.7.2 source and
  class reference): `GLTFDocument.append_from_buffer` + `generate_scene` for GLB,
  `Image.load_svg_from_buffer / load_webp_from_buffer / load_png_from_buffer` for
  images, `FontFile.data` for fonts, `AudioStreamOggVorbis.load_from_buffer` for audio.

### glTF compression: what Godot 4.7 can load at runtime

Checked in `modules/gltf` of 4.7.2-stable: supported extensions are
`KHR_texture_transform`, `KHR_materials_*` (unlit, emissive_strength,
pbrSpecularGlossiness), `KHR_lights_punctual`, `KHR_node_visibility`,
`KHR_animation_pointer`, `EXT_texture_webp` and `KHR_texture_basisu` (KTX2).
**Not** supported: `KHR_draco_mesh_compression`, `EXT_meshopt_compression`,
`KHR_mesh_quantization`. So the pipeline keeps geometry as plain float GLB,
embeds textures as WebP (`EXT_texture_webp`), and relies on transport
compression (brotli/gzip), which shrinks the set about 5–7×.

## Adding or replacing a model (the owner's workflow)

1. Drop the file in: `art_src/cdn/company/bakery.glb` (textures next to it, or embedded).
   An icon: `art_src/cdn/icon/item/pistol.svg` → key `icon:item:pistol`.
2. Run `python3 tools/build_assets/build.py` (add `--base-url https://cdn…/torncity/` if
   the files live elsewhere than the manifest).
3. Upload `dist-assets/` to the CDN (new hashed files + the new `manifest.json`).
4. In the server's content YAML, point the entry at it: `asset: {model: company:bakery}`.

No client release. To reuse Kenney parts instead, add a composition under the
key in `art_src/cdn/library.json` (`parts: [{mesh, at, rotate, size}]`), rebuild, upload.

## CDN requirements

- HTTPS, serving the `dist-assets/` tree as static files.
- `manifest.json`: `Cache-Control: no-cache` (it is the only file that changes).
- Everything else: `Cache-Control: public, max-age=31536000, immutable` (paths are hashed).
- `Access-Control-Allow-Origin: <the Mini App's origin>` (the web build fetches
  cross-origin), `Access-Control-Allow-Methods: GET, HEAD, OPTIONS`, answer `OPTIONS`.
- Compression: serve the precompressed siblings (`.br`, `.gz`, written by the
  build) with `Content-Encoding` and `Vary: Accept-Encoding` — nginx:
  `brotli_static on; gzip_static on;`.
- MIME types: `.glb model/gltf-binary`, `.webp image/webp`, `.svg image/svg+xml`,
  `.json application/json`, `.ogg audio/ogg`, `.ttf font/ttf`.
- The client finds it through `cdn_url` (config `[server] cdn_url`, `--cdn=URL`,
  or `?cdn=URL` on the web page).
