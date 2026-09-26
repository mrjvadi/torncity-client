extends "res://tests/test_case.gd"
## Runtime assets: decoding what tools/build_assets produces, checksums, fallbacks.

const DIST := "res://dist-assets"


func _dist_entry(prefix: String) -> Array:
	var path := ProjectSettings.globalize_path(DIST + "/manifest.json")
	if not FileAccess.file_exists(path):
		return []
	var m = JSON.parse_string(FileAccess.get_file_as_string(path))
	for k in m["assets"]:
		if str(k).begins_with(prefix):
			return [k, m["assets"][k], FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(DIST + "/" + m["assets"][k]["path"]))]
	return []


func test_sha256() -> void:
	eq(AssetService._sha256("abc".to_utf8_buffer()), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")


func test_decode_built_glb_and_svg() -> void:
	var g := _dist_entry("mesh:city-kit-commercial/")
	if g.is_empty():
		print("   (skipped: run tools/build_assets/build.py first)")
		return
	eq(AssetService._sha256(g[2]), g[1]["sha256"], "file matches its manifest hash")
	check(AssetService._decode(g[0], g[1], g[2]), "glb decodes (EXT_texture_webp)")
	var ps = AssetService.get_asset(g[0])
	check(ps is PackedScene, "a PackedScene")
	var n: Node = ps.instantiate()
	var meshes := n.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() > 0, "has meshes")
	var mat: Material = (meshes[0] as MeshInstance3D).mesh.surface_get_material(0)
	check(mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_texture != null, "the embedded WebP colormap loaded")
	n.free()
	var s := _dist_entry("glyph:")
	check(AssetService._decode(s[0], s[1], s[2]), "svg decodes")
	check(AssetService.get_asset(s[0]) is Texture2D, "a texture")


func test_fallbacks_without_cdn() -> void:
	# a key nobody published: a stand-in model and the category's bundled glyph
	var n := AssetLib.instantiate("spaceship:zeppelin")
	check(n.get_child_count() > 0, "stand-in model")
	n.free()
	var g := AssetLib.glyph("item:never_made")
	check(g["texture"] is Texture2D, "category glyph bundled")
