# Tooling

Everything under `tools/` is downloaded, not committed (`.gitignore`).

## Godot (pinned)

- Version: **Godot 4.7.2-stable**, standard (GDScript) build, Linux x86_64.
- Source: `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`
- SHA-512 (from the release's `SHA512-SUMS.txt`):
  `9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65`
- Installed as `tools/godot`.

```sh
mkdir -p tools && cd tools
curl -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
curl -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt
grep linux.x86_64.zip SHA512-SUMS.txt | sha512sum -c
unzip Godot_v4.7.2-stable_linux.x86_64.zip && mv Godot_v4.7.2-stable_linux.x86_64 godot
```

### Export templates (not installed here)

Exporting needs `Godot_v4.7.2-stable_export_templates.tpz` (about 1 GB) from
the same release, installed with the editor (Editor → Manage Export Templates)
or unpacked to `~/.local/share/godot/export_templates/4.7.2.stable/`. The
presets are ready (`export_presets.cfg`):

```sh
godot --headless --path . --export-release "Web" build/web/index.html
godot --headless --path . --export-release "Android" build/android/torncity.apk   # needs the Android SDK + a keystore
godot --headless --path . --export-release "Linux" build/linux/torncity.x86_64
```

Without templates the command stops with "No export template found", after
the preset itself has been read — that much is verified.

The Web build is single-threaded (`variant/thread_support=false`), so it needs
no cross-origin-isolation headers and runs in Telegram's WebView. Serve
`build/web/` over HTTPS with `.wasm` as `application/wasm` and gzip/brotli
compression; set the Mini App URL in BotFather to that page. For an even
smaller download, build custom web templates with 3D and unused modules
disabled (`scons platform=web target=template_release disable_3d=yes
module_text_server_fb_enabled=no` keeps the advanced text server Persian
needs).

## Headless checks

```sh
tools/godot --headless --path . --import            # import all assets; must print no errors
tools/godot --headless --path . -s dev/compile_all.gd   # compile every script and scene
tools/godot --headless --path . -s tests/run_tests.gd   # the tests (exit code = failures)
```

## Screenshots

`dev/screenshots.sh` renders `docs/screenshots/{fa,en}/*.png` with the real
renderer. It needs an X display: it starts `Xvfb` from the system, or from
`tools/xvfb/root/usr/bin/Xvfb` (the Ubuntu `xvfb` package unpacked without
installing: `apt-get download xvfb && dpkg -x xvfb_*.deb tools/xvfb/root`).
`dev/sheet.py` tiles shots side by side for review.

## Blender (art renders)

- Version: **Blender 4.5.14 LTS**, Linux x64 portable tarball.
- Source: `https://download.blender.org/release/Blender4.5/blender-4.5.14-linux-x64.tar.xz`
- SHA-256 (from `blender-4.5.14.sha256`):
  `9ba871ff2ecd36526b77432745980b7e6664ecd0c7ca11c48849073dcfe06da3`
- Unpacked to `tools/blender/app/`. The GPU kernels (`cycles/lib`) can be left
  out: renders use Cycles on the CPU.

```sh
tools/blender/app/blender -b --factory-startup -P art_src/blender/render_places.py -- --size 512 --samples 48
tools/blender/app/blender -b --factory-startup -P art_src/blender/render_character.py
```

## Vector art

```sh
python3 art_src/gen_art.py            # all SVGs (Python 3, standard library only)
tools/godot --headless -s dev/contact_sheet.gd -- sheet.png 128 assets/art/icons/*.svg
```
