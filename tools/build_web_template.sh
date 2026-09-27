#!/usr/bin/env bash
# Builds a trimmed single-threaded Web release template for Godot 4.7.2 and
# installs it as web_nothreads_release.zip. Cuts the download from ~8.0 MB to
# ~5.9 MB (brotli). Needs emsdk 4.0.11 activated and a Godot 4.7.2-stable
# source checkout:
#   source /path/to/emsdk/emsdk_env.sh
#   GODOT_SRC=/path/to/godot tools/build_web_template.sh
set -euo pipefail

GODOT_SRC=${GODOT_SRC:?set GODOT_SRC to a godot 4.7.2-stable checkout}
DEST=${DEST:-$HOME/.local/share/godot/export_templates/4.7.2.stable}

# Kept on purpose: text_server_adv (Persian shaping), freetype, gdscript, gltf
# (city models), svg, webp, websocket, mbedtls (Crypto in api.gd), ogg/vorbis
# (AudioStreamOggVorbis in asset_service.gd).
OFF=(csg gridmap enet webrtc upnp theora jsonrpc regex noise openxr webxr
  mobile_vr camera lightmapper_rd xatlas_unwrap vhacd raycast meshoptimizer
  text_server_fb msdfgen mp3 interactive_music tga hdr bmp dds ktx tinyexr jpg
  multiplayer zip fbx visual_shader basis_universal objectdb_profiler
  godot_physics_2d godot_physics_3d jolt_physics)

args=()
for m in "${OFF[@]}"; do args+=("module_${m}_enabled=no"); done

cd "$GODOT_SRC"
scons -j"$(nproc)" platform=web target=template_release threads=no \
  production=yes optimize=size_extra lto=full \
  disable_physics_2d=yes disable_physics_3d=yes \
  disable_navigation_2d=yes disable_navigation_3d=yes disable_xr=yes \
  "${args[@]}"

mkdir -p "$DEST"
cp bin/godot.web.template_release.wasm32.nothreads.zip "$DEST/web_nothreads_release.zip"
echo "installed $DEST/web_nothreads_release.zip"
