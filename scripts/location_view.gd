@tool
class_name LocationView
extends Node2D
## Satu lokasi: latar (gambar atau placeholder), penghalang, titik interaksi, NPC,
## serta efek hidup (lampu jendela malam, spanduk, kucing, motor melintas).

const MOTOR_SCENE: PackedScene = preload("res://scenes/entities/motor.tscn")
const ANGKOT_SCENE: PackedScene = preload("res://scenes/entities/angkot.tscn")
const WALKER_SCENE: PackedScene = preload("res://scenes/entities/walker.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/entities/npc.tscn")

@export_group("Lokasi")
## Id lokasi; sama dengan nama berkas di scenes/maps/ dan dipakai di GameData.jadwal().
@export var loc_id: String = ""
@export var nama: String = ""
@export var ukuran: Vector2 = Vector2(640, 360):
	set(v):
		ukuran = v
		size_px = v
		queue_redraw()
@export var dalam_ruangan: bool = false

@export_group("Gerak pemain")
@export var y_min: float = 0.0
@export var y_max: float = 332.0
## Batas kanan area jalan. Negatif = lebar lokasi - 10.
@export var x_max: float = -1.0
## Tinggi sprite (50/62/75/100/150) yang dipakai pemain dan NPC di lokasi ini.
@export var tinggi_sprite: int = 50
@export var kecepatan_jalan: float = 1.0
## Skala pemain di tepi atas (x) dan bawah (y) area jalan untuk efek perspektif. (0,0) = tidak dipakai.
@export var depth: Vector2 = Vector2.ZERO
## Jarak interaksi dasar; 0 = otomatis dari tinggi sprite.
@export var radius_interaksi: float = 0.0

@export_group("Warna placeholder")
@export var warna_lantai: Color = Color("#888888"):
	set(v):
		warna_lantai = v
		queue_redraw()
@export var warna_dinding: Color = Color("#666666"):
	set(v):
		warna_dinding = v
		queue_redraw()

@export_group("Suasana")
## Kendaraan melintas di jalur depan (motor & angkot).
@export var lalu_lintas: bool = false
## Warga lewat di trotoar. jalur_pejalan = rentang y jalur jalan kaki.
@export var pejalan_kaki: bool = false
@export var jalur_pejalan: Vector2 = Vector2(228.0, 246.0)

@export_group("Dekorasi")
## Papan nama: [teks, x, y, lebar, tinggi, warna_latar, warna_teks]
@export var papan: Array = []
## Jendela yang menyala di malam hari: [x, y, lebar, tinggi]
@export var jendela_lampu: Array = []
@export var lampu_x: PackedFloat32Array = PackedFloat32Array()

var entities: Node2D
var blockers: Array = []
var interactables: Array = []
var npcs: Dictionary = {}
var size_px: Vector2 = Vector2(640, 360)
var spr: int = 50
var skala: float = 1.0
var kecepatan: float = 1.0
var player: Node2D = null
var _bg: Texture2D = null
var _t: float = 0.0
var _motor_timer: float = 3.0
var _walker_timer: float = 5.0


func _siapkan() -> void:
	size_px = ukuran
	spr = tinggi_sprite
	skala = radius_interaksi if radius_interaksi > 0.0 else float(spr) / 50.0
	kecepatan = kecepatan_jalan
	entities = get_node_or_null("Entities") as Node2D
	var latar := get_node_or_null("Latar") as Sprite2D
	_bg = latar.texture if latar != null else null


func _ready() -> void:
	_siapkan()
	if Engine.is_editor_hint():
		queue_redraw()
		return
	# Pemain pratinjau hanya untuk editor; pemain asli ditambahkan main.gd.
	for n in get_tree().get_nodes_in_group("preview_editor"):
		if is_ancestor_of(n):
			n.get_parent().remove_child(n)
			n.queue_free()
	refresh()


# ---------------------------------------------------------------- data lokasi dari node anak
func xmax() -> float:
	return x_max if x_max >= 0.0 else size_px.x - 10.0


func posisi_spawn(nama_spawn: String) -> Vector2:
	var sp: Node2D = get_node_or_null("Spawns/" + nama_spawn) as Node2D
	if sp == null:
		push_warning("Spawn '%s' tidak ada di lokasi %s" % [nama_spawn, loc_id])
		sp = get_node("Spawns").get_child(0) as Node2D
	return sp.position


func spawn_pertama() -> String:
	return String(get_node("Spawns").get_child(0).name)


## Data tepi lokasi ("kiri"/"kanan"): {ke, spawn, label}, atau {} bila tidak ada.
func tepi(arah: String) -> Dictionary:
	var grup: Node = get_node_or_null("Tepi")
	if grup == null:
		return {}
	for t in grup.get_children():
		if t is TepiLokasi and (t as TepiLokasi).arah == arah:
			return {"ke": t.ke, "spawn": t.spawn, "label": t.label}
	return {}


func _objek() -> Array:
	var out: Array = []
	var grup: Node = get_node_or_null("Objek")
	if grup != null:
		for c in grup.get_children():
			if c is Interactable:
				out.append(c)
	return out


func _pintu() -> Array:
	var out: Array = []
	var grup: Node = get_node_or_null("Pintu")
	if grup != null:
		for c in grup.get_children():
			if c is Pintu:
				out.append(c)
	return out


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if player != null:
		for a in npcs.values():
			a.facing = 1 if player.position.x >= a.position.x else -1
		if depth != Vector2.ZERO:
			# efek POV: makin ke bawah (mendekati kamera) karakter makin besar
			var t: float = clampf((player.position.y - y_min) / maxf(1.0, y_max - y_min), 0.0, 1.0)
			var f: float = lerpf(depth.x, depth.y, t)
			player.scale = Vector2(f * 0.7, f * 0.7)
		else:
			player.scale = Vector2(0.7, 0.7)
	if lalu_lintas:
		_motor_timer -= delta
		if _motor_timer <= 0.0:
			_motor_timer = randf_range(5.0, 12.0)
			_spawn_vehicle()
	if pejalan_kaki:
		_walker_timer -= delta
		if _walker_timer <= 0.0:
			_walker_timer = randf_range(12.0, 26.0)
			_spawn_walker()
	queue_redraw()


func _spawn_vehicle() -> void:
	var ke_kanan: bool = randf() < 0.5
	var y_lane: float = 262.0
	var sk: float = 1.5
	if randf() < 0.3:
		var an := ANGKOT_SCENE.instantiate() as Angkot
		an.vx = randf_range(42.0, 62.0) * (1.0 if ke_kanan else -1.0)
		an.position = Vector2(-120.0 if ke_kanan else size_px.x + 120.0, y_lane)
		an.x_end = size_px.x + 160.0
		an.scale = Vector2(1.0, 1.0)
		entities.add_child(an)
		return
	var m := MOTOR_SCENE.instantiate() as Motor
	m.vx = randf_range(55.0, 95.0) * (1.0 if ke_kanan else -1.0)
	m.position = Vector2(-70.0 if ke_kanan else size_px.x + 70.0, y_lane)
	m.x_end = size_px.x + 80.0
	var warna: Array = ["#b43430", "#3c6eaa", "#d0a030", "#4a4a52", "#2e8a56"]
	var jaket: Array = ["#2e9b57", "#c0504d", "#3b7ea1", "#8a6a3a", "#2e9b57"]
	m.body = Color(warna[randi() % warna.size()])
	m.jaket = Color(jaket[randi() % jaket.size()])
	m.scale = Vector2(sk, sk)
	entities.add_child(m)


func _spawn_walker() -> void:
	var ids: Array = ["pelanggan1", "pelanggan2", "yoga"]
	var w := WALKER_SCENE.instantiate() as Walker
	w.setup(str(ids[randi() % ids.size()]), spr)
	w.show_label = false
	var ke_kanan: bool = randf() < 0.5
	w.vx = randf_range(15.0, 24.0) * (1.0 if ke_kanan else -1.0)
	w.position = Vector2(-30.0 if ke_kanan else size_px.x + 30.0, randf_range(jalur_pejalan.x, jalur_pejalan.y))
	w.x_end = size_px.x + 40.0
	entities.add_child(w)


func refresh() -> void:
	blockers.clear()
	interactables.clear()
	for o in _objek():
		var it: Interactable = o
		if not it.aktif():
			continue
		var r: Rect2 = it.rect_di(self)
		if it.solid:
			blockers.append(r)
		if it.label != "":
			interactables.append({"id": String(it.name), "kind": "objek", "rect": r, "label": it.label})
	for pn in _pintu():
		var pt: Pintu = pn
		interactables.append({
			"id": String(pt.name), "kind": "pintu", "rect": pt.rect_di(self),
			"label": pt.label_final(dalam_ruangan), "ke": pt.ke, "spawn": pt.spawn,
		})
	for a in npcs.values():
		a.queue_free()
	npcs.clear()
	for nid in GameData.NPC_LIST:
		var j: Dictionary = GameData.jadwal(nid, TimeManager.day, TimeManager.jam())
		if not j.is_empty() and j["loc"] == loc_id:
			var a := NPC_SCENE.instantiate() as Actor
			a.setup(nid, spr)
			a.position = j["pos"]
			entities.add_child(a)
			npcs[nid] = a
			interactables.append({"id": nid, "kind": "npc", "pos": j["pos"], "label": "Bicara: " + GameData.NPC[nid]["nama"]})
	queue_redraw()


func can_stand(p: Vector2) -> bool:
	if p.x < 10.0 or p.x > xmax():
		return false
	if p.y < y_min or p.y > y_max:
		return false
	var foot := Rect2(p.x - 5.0, p.y - 3.0, 10.0, 5.0)
	for b in blockers:
		if foot.intersects(b):
			return false
	return true


# ---------------------------------------------------------------- menggambar
func _draw() -> void:
	var w: float = size_px.x
	if Engine.is_editor_hint():
		if _bg == null:
			_gambar_placeholder(w, false)
		return
	if _bg != null:
		if loc_id == "gang":
			_draw_gang_fx()
		elif loc_id == "jalan":
			_draw_jalan_fx()
		else:
			_draw_decor_bg()
		return
	_gambar_placeholder(w, true)
	if loc_id == "jalan":
		_draw_jalan_fx()


## Lokasi tanpa gambar latar: lantai/dinding + objek berwarna + pintu.
func _gambar_placeholder(w: float, runtime: bool) -> void:
	if loc_id == "kampus":
		_draw_kampus(w)
	elif loc_id == "jalan" and runtime:
		_draw_jalan_bg(w)
	else:
		_draw_indoor(w)
	var font: Font = ThemeDB.fallback_font
	for o in _objek():
		if not runtime or (o as Interactable).aktif():
			_draw_obj(o, font)
	for d in _pintu():
		var rect: Rect2 = (d as Pintu).rect_di(self)
		draw_rect(rect, Color("#5b3b22"))
		draw_rect(rect, Color("#2e1d10"), false, 1.0)
		if runtime:
			draw_rect(Rect2(rect.end.x - 8.0, rect.position.y + rect.size.y * 0.5, 3, 3), Color("#e8c76a"))


func _malam() -> bool:
	return TimeManager.jam() >= 18 or TimeManager.jam() < 5


func _sign(txt: String, r: Rect2, bg: Color, fg: Color, size: int = 7) -> void:
	var f: Font = ThemeDB.fallback_font
	draw_rect(r, bg.darkened(0.45))
	draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2)), bg)
	draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2.0, 1.0)), bg.lightened(0.25))
	draw_string(f, Vector2(r.position.x, r.position.y + r.size.y - 2.0), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, fg)


func _draw_gang_fx() -> void:
	var hjam: int = TimeManager.jam()
	_draw_papan()
	# lampu jendela saat malam & cahaya warung Madura (24 jam)
	if _malam():
		for wr in jendela_lampu:
			var r := Rect2(float(wr[0]), float(wr[1]), float(wr[2]), float(wr[3]))
			draw_rect(r.grow(1.0), Color(1.0, 0.82, 0.4, 0.18))
			draw_rect(r, Color(1.0, 0.85, 0.45, 0.55))
	draw_rect(Rect2(497, 139, 88, 82), Color(1.0, 0.9, 0.6, 0.12 if _malam() else 0.0))
	# kabut pagi Bandung Timur (turun dari arah Manglayang)
	if hjam >= 5 and hjam < 9:
		for i in range(8):
			var fx: float = fmod(float(i) * 173.0 + _t * 5.0, size_px.x + 400.0) - 200.0
			draw_rect(Rect2(fx, 120.0 + float(i) * 13.0, 280.0, 11.0), Color(1, 1, 1, 0.075))
			draw_rect(Rect2(fx + 30.0, 124.0 + float(i) * 13.0, 220.0, 5.0), Color(1, 1, 1, 0.06))
	# burung beterbangan (siang)
	if hjam >= 6 and hjam < 17 and not TimeManager.raining:
		for i in range(4):
			var bx: float = fmod(float(i) * 311.0 + _t * (14.0 + float(i) * 3.0), size_px.x + 160.0) - 80.0
			var by: float = 22.0 + float(i) * 12.0 + sin(_t * 1.3 + float(i)) * 5.0
			var fl: float = sin(_t * 9.0 + float(i) * 2.0) * 2.5
			draw_line(Vector2(bx - 4, by + fl), Vector2(bx, by), Color(0.14, 0.1, 0.1), 1.0)
			draw_line(Vector2(bx, by), Vector2(bx + 4, by + fl), Color(0.14, 0.1, 0.1), 1.0)
	# lampu jalan baru
	if GameState.has_flag("lampu_jalan"):
		for lx in lampu_x:
			var x: float = float(lx)
			draw_rect(Rect2(x, 150, 2, 72), Color("#2e2a2a"))
			draw_rect(Rect2(x - 5, 146, 12, 5), Color("#ffe9a0"))
			if _malam():
				draw_circle(Vector2(x + 1, 150), 42.0, Color(1, 0.9, 0.5, 0.13))
				draw_circle(Vector2(x + 1, 150), 22.0, Color(1, 0.9, 0.5, 0.16))
	# meja nasi kotak / Jumat Berkah di depan masjid
	var jam_f: float = TimeManager.minutes / 60.0
	var jumat_on: bool = GameState.has_flag("jumat_berkah_aktif") and jam_f >= 12.25 and jam_f < 13.75
	var kotak_on: bool = GameState.has_flag("nasi_kotak_hari") and jam_f >= 9.0 and jam_f < 12.0
	if jumat_on or kotak_on:
		draw_rect(Rect2(160, 214, 46, 4), Color("#f1ece0"))
		draw_rect(Rect2(162, 218, 2, 8), Color("#6a4a2a")); draw_rect(Rect2(202, 218, 2, 8), Color("#6a4a2a"))
		for i in range(6):
			draw_rect(Rect2(163 + i * 6, 208, 5, 6), Color("#e8d6a0") if i % 2 == 0 else Color("#d6b676"))
		if jumat_on:
			_sign("JUMAT BERKAH", Rect2(160, 196, 46, 9), Color("#2f7a4f"), Color("#f6f0d0"), 6)
	# tempat wudu: ember & keran
	draw_rect(Rect2(66, 204, 12, 14), Color("#8a98a0")); draw_rect(Rect2(66, 204, 12, 3), Color("#b6c4cc"))
	draw_rect(Rect2(70, 196, 2, 8), Color("#6a7a80")); draw_rect(Rect2(70, 196, 6, 2), Color("#6a7a80")); draw_rect(Rect2(75, 198, 1, 4), Color("#6aa8d8"))
	# kucing kampung (ekor bergoyang)
	var tail: float = sin(_t * 2.5) * 2.0
	draw_rect(Rect2(378, 228, 12, 6), Color("#d89a4e")); draw_rect(Rect2(388, 225, 6, 6), Color("#d89a4e"))
	draw_rect(Rect2(388, 223, 2, 3), Color("#d89a4e")); draw_rect(Rect2(392, 223, 2, 3), Color("#d89a4e"))
	draw_rect(Rect2(376, 226 + tail, 3, 5), Color("#b87a36"))
	draw_rect(Rect2(390, 227, 1, 1), Color("#1a1a1a"))
	_kunang_kunang(14, Rect2(30, 170, size_px.x - 60, 70))
	_uap(1030.0, 176.0, 3)
	# genangan saat hujan
	if TimeManager.raining:
		for pp in [Vector2(120, 252), Vector2(420, 256), Vector2(700, 250), Vector2(980, 257)]:
			draw_rect(Rect2(pp.x, pp.y, 40, 5), Color(0.62, 0.72, 0.85, 0.35))
			draw_rect(Rect2(pp.x + 4, pp.y + 1, 16, 1), Color(0.9, 0.95, 1.0, 0.35))


func _draw_jalan_bg(w: float) -> void:
	var hujan: bool = TimeManager.raining
	var bands: Array = ["#7fb0d6", "#8fbbdc", "#a2c6dc", "#b6d0d8", "#c8d8d4", "#d6dcc8"]
	if hujan:
		bands = ["#6c7a88", "#76848f", "#828e96", "#8c979c", "#969fa0", "#a0a6a2"]
	for i in range(bands.size()):
		draw_rect(Rect2(0, i * 20.0, w, 20.0), Color(bands[i]))
	# bukit jauh (Manglayang) & perbukitan
	var far := PackedVector2Array([Vector2(0, 130), Vector2(120, 82), Vector2(260, 100), Vector2(420, 60), Vector2(600, 96), Vector2(760, 70), Vector2(940, 104), Vector2(1100, 76), Vector2(1280, 110), Vector2(1280, 160), Vector2(0, 160)])
	draw_colored_polygon(far, Color("#6e8a96") if not hujan else Color("#5c707a"))
	var near := PackedVector2Array([Vector2(0, 150), Vector2(180, 122), Vector2(360, 140), Vector2(560, 118), Vector2(760, 142), Vector2(980, 120), Vector2(1280, 144), Vector2(1280, 180), Vector2(0, 180)])
	draw_colored_polygon(near, Color("#58786a") if not hujan else Color("#4a6258"))
	draw_rect(Rect2(0, 176, w, 24), Color("#5a6e55") if not hujan else Color("#4a5a48"))   # lahan/pekarangan di balik bangunan
	# trotoar & jalan
	draw_rect(Rect2(0, 198, w, 8), Color("#aaa292"))
	draw_rect(Rect2(0, 198, w, 2), Color("#c4bca8"))
	draw_rect(Rect2(0, 206, w, 2), Color("#6a665c"))
	draw_rect(Rect2(0, 208, w, 62), Color("#3a3f46") if hujan else Color("#4a4d52"))
	for i in range(160):
		var px: float = float((i * 97) % int(w))
		var py: float = 212.0 + float((i * 53) % 54)
		draw_rect(Rect2(px, py, 1, 1), Color(0.58, 0.54, 0.5, 0.35) if i % 2 == 0 else Color(0.2, 0.2, 0.22, 0.5))
	for x in range(0, int(w), 40):
		draw_rect(Rect2(float(x) + 6.0, 240, 22, 2), Color("#e6e0c0"))


func _draw_jalan_fx() -> void:
	if _bg == null:
		_draw_papan()
		# Procedural fallback for locations without the road background asset.
		draw_rect(Rect2(500, 150, 118, 8), Color("#46628a")); draw_rect(Rect2(500, 158, 118, 2), Color("#2e4262"))
		draw_rect(Rect2(504, 160, 3, 40), Color("#7a7a82")); draw_rect(Rect2(611, 160, 3, 40), Color("#7a7a82"))
		draw_rect(Rect2(508, 162, 102, 32), Color("#c4ceca"))
		draw_rect(Rect2(516, 184, 88, 5), Color("#7a563a")); draw_rect(Rect2(518, 189, 3, 10), Color("#5a3e28")); draw_rect(Rect2(599, 189, 3, 10), Color("#5a3e28"))
		_sign("HALTE ANGKOT & OJOL", Rect2(518, 140, 84, 9), Color("#2a4668"), Color("#e8f0f8"), 6)
		draw_rect(Rect2(522, 168, 30, 14), Color("#efe6d0")); draw_rect(Rect2(522, 168, 30, 3), Color("#c8382f"))
		draw_rect(Rect2(660, 190, 64, 14), Color("#8a95a0")); draw_rect(Rect2(660, 190, 64, 2), Color("#b4bec6"))
		draw_rect(Rect2(660, 174, 64, 6), Color("#2f8f5a")); draw_rect(Rect2(660, 180, 64, 3), Color("#e8dcb0"))
		draw_rect(Rect2(662, 183, 2, 8), Color("#5a4a3a")); draw_rect(Rect2(720, 183, 2, 8), Color("#5a4a3a"))
		draw_circle(Vector2(670, 206), 6.0, Color("#1c1c20")); draw_circle(Vector2(714, 206), 6.0, Color("#1c1c20"))
		_sign("BATAGOR", Rect2(670, 160, 44, 9), Color("#2f6f4f"), Color("#f6f0d0"), 6)
	_uap(690.0, 172.0, 3)
	if _malam():
		for wr in jendela_lampu:
			var r := Rect2(float(wr[0]), float(wr[1]), float(wr[2]), float(wr[3]))
			draw_rect(r.grow(1.0), Color(1.0, 0.82, 0.4, 0.18))
			draw_rect(r, Color(1.0, 0.85, 0.45, 0.55))
	if GameState.has_flag("lampu_jalan"):
		_draw_lampu_jalan(150.0, 50.0)
	# barikade perbaikan jalan
	if GameState.has_flag("jalan_ditutup"):
		for i in range(0, 100, 14):
			draw_rect(Rect2(760 + i, 238, 7, 22), Color("#e0a030"))
			draw_rect(Rect2(767 + i, 238, 7, 22), Color("#222222"))
		draw_rect(Rect2(756, 234, 108, 4), Color("#c8382f"))
	if TimeManager.raining:
		for pp in [Vector2(120, 248), Vector2(420, 256), Vector2(640, 250), Vector2(860, 257)]:
			draw_rect(Rect2(pp.x, pp.y, 44, 5), Color(0.62, 0.72, 0.85, 0.35))


func _draw_lampu_jalan(y_top: float, tinggi: float) -> void:
	for lx in lampu_x:
		var x: float = float(lx)
		draw_rect(Rect2(x, y_top, 2, tinggi), Color("#2e2a2a"))
		draw_rect(Rect2(x - 5, y_top - 4, 12, 5), Color("#ffe9a0"))
		if _malam():
			draw_circle(Vector2(x + 1, y_top), 42.0, Color(1, 0.9, 0.5, 0.13))
			draw_circle(Vector2(x + 1, y_top), 22.0, Color(1, 0.9, 0.5, 0.16))


func _draw_lapangan_fx() -> void:
	var hjam: int = TimeManager.jam()
	_uap(204.0, 198.0, 3)
	_uap(268.0, 200.0, 2)
	_kunang_kunang(10, Rect2(20, 170, size_px.x - 40, 80))
	_kedip_meteran(7.0, 148.0)
	# spanduk program di tembok belakang lapangan
	if GameState.has_flag("spanduk"):
		_sign("PROGRAM KAMPUNG NYAMAN", Rect2(362, 140, 102, 12), Color("#c8382f"), Color("#fff4e0"), 6)
	# cahaya hangat warteg saat sore-malam & aula Balai RW saat jam kerja / rapat
	var rapat: bool = TimeManager.day == GameData.HARI_RAPAT and hjam >= 19 and hjam < 22
	if _malam() or TimeManager.raining:
		draw_rect(Rect2(172, 160, 140, 90), Color(1.0, 0.86, 0.5, 0.10))
		draw_rect(Rect2(186, 150, 118, 40), Color(1.0, 0.86, 0.5, 0.14))
	if rapat:
		draw_rect(Rect2(654, 139, 66, 68), Color(1.0, 0.88, 0.5, 0.30))
		draw_rect(Rect2(540, 170, 200, 80), Color(1.0, 0.88, 0.5, 0.08))
	elif hjam >= 8 and hjam < 15 and TimeManager.hari_kerja():
		draw_rect(Rect2(654, 139, 66, 68), Color(1.0, 0.92, 0.6, 0.10))
	if GameState.has_flag("lampu_jalan"):
		_draw_lampu_jalan(150.0, 100.0)
	# kabut pagi & burung (sama seperti gang)
	if hjam >= 5 and hjam < 9:
		for i in range(7):
			var fx: float = fmod(float(i) * 173.0 + _t * 5.0, size_px.x + 400.0) - 200.0
			draw_rect(Rect2(fx, 140.0 + float(i) * 11.0, 260.0, 9.0), Color(1, 1, 1, 0.06))
	if hjam >= 6 and hjam < 17 and not TimeManager.raining:
		for i in range(3):
			var bx: float = fmod(float(i) * 297.0 + _t * (13.0 + float(i) * 3.0), size_px.x + 160.0) - 80.0
			var by: float = 20.0 + float(i) * 13.0 + sin(_t * 1.3 + float(i)) * 5.0
			var fl: float = sin(_t * 9.0 + float(i) * 2.0) * 2.5
			draw_line(Vector2(bx - 4, by + fl), Vector2(bx, by), Color(0.14, 0.1, 0.1), 1.0)
			draw_line(Vector2(bx, by), Vector2(bx + 4, by + fl), Color(0.14, 0.1, 0.1), 1.0)
	if TimeManager.raining:
		for pp in [Vector2(80, 262), Vector2(380, 258), Vector2(560, 262), Vector2(760, 260)]:
			draw_rect(Rect2(pp.x, pp.y, 44, 4), Color(0.62, 0.72, 0.85, 0.35))


func _draw_papan() -> void:
	for p in papan:
		_sign(str(p[0]), Rect2(float(p[1]), float(p[2]), float(p[3]), float(p[4])), Color(str(p[5])), Color(str(p[6])))


func _draw_decor_bg() -> void:
	if loc_id == "lapangan":
		_draw_lapangan_fx()
		return
	if loc_id == "koridor":
		_fx_koridor()
		return
	if loc_id == "masjid":
		_fx_masjid()
		return
	if loc_id == "kos_room":
		_fx_kos()
		if GameState.has_flag("lampu"):
			draw_rect(Rect2(16, 186, 8, 3), Color("#3a3a3a"))
			draw_rect(Rect2(19, 170, 2, 16), Color("#3a3a3a"))
			draw_rect(Rect2(12, 164, 14, 6), Color("#ffe27a"))
			draw_circle(Vector2(19, 172), 14.0, Color(1, 0.9, 0.5, 0.12))
		if GameState.has_flag("poster"):
			draw_rect(Rect2(212, 104, 32, 44), Color("#f4ede0"))
			draw_rect(Rect2(215, 107, 26, 38), Color("#e07a5f"))
			draw_rect(Rect2(221, 118, 14, 14), Color("#f2cc8f"))
			draw_rect(Rect2(212, 104, 32, 44), Color("#3a2a20"), false, 1.0)


func _draw_kampus(w: float) -> void:
	draw_rect(Rect2(0, 0, w, 360), warna_lantai)
	draw_rect(Rect2(240, 150, 160, 210), Color("#cfc8b4"))


func _draw_indoor(w: float) -> void:
	draw_rect(Rect2(0, 0, w, 360), warna_lantai)
	for x in range(0, int(w), 32):
		draw_line(Vector2(x, 62), Vector2(x, 360), Color(0, 0, 0, 0.06))
	draw_rect(Rect2(0, 0, w, 60), warna_dinding)
	draw_rect(Rect2(0, 56, w, 6), warna_dinding.darkened(0.25))


func _draw_obj(it: Interactable, font: Font) -> void:
	var r: Rect2 = it.rect_di(self)
	var c: Color = it.warna
	var oid: String = String(it.name)
	if c == Color("#000000") or oid == "jalan_tutup":
		return   # titik interaksi/penghalang tak kasatmata (digambar oleh efek)
	if oid.begins_with("b_"):
		draw_rect(Rect2(r.position.x - 6.0, r.position.y - 8.0, r.size.x + 12.0, 16.0), c.darkened(0.5))
		draw_rect(Rect2(r.position.x - 6.0, r.position.y - 8.0, r.size.x + 12.0, 3.0), c.darkened(0.3))
		draw_rect(r, c)
		draw_rect(Rect2(r.position.x, r.end.y - 6.0, r.size.x, 6.0), c.darkened(0.3))
		for wx in [20.0, 118.0]:
			var wr := Rect2(r.position.x + wx, r.position.y + 48.0, 36, 36)
			draw_rect(wr, Color("#cfe6f2")); draw_rect(wr, c.darkened(0.55), false, 2.0)
			draw_line(Vector2(wr.position.x + 18, wr.position.y), Vector2(wr.position.x + 18, wr.end.y), c.darkened(0.55), 1.0)
		return
	draw_rect(r, c)
	draw_rect(Rect2(r.position, Vector2(r.size.x, 2.0)), c.lightened(0.25))
	draw_rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), c.darkened(0.3))
	draw_rect(r, c.darkened(0.5), false, 1.0)
	if it.teks != "" and r.size.x >= 56.0:
		draw_string(font, Vector2(r.position.x, r.position.y + 12.0), it.teks, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 9, Color(1, 1, 1, 0.95))


# ---------------------------------------------------------------- efek ambient
func _jam_f() -> float:
	return float(TimeManager.minutes) / 60.0


## Cahaya lembut berlapis (lingkaran konsentris bening).
func _glow(c: Vector2, r: float, col: Color, lapis: int = 4) -> void:
	for i in range(lapis):
		var rr: float = r * (1.0 - float(i) / float(lapis) * 0.7)
		draw_circle(c, rr, col)


## Uap naik dari warung/gerobak (hanya terlihat saat dingin: pagi, sore-malam, atau hujan).
func _uap(x: float, y: float, n: int) -> void:
	var jam: int = TimeManager.jam()
	if not (jam < 10 or jam >= 16 or TimeManager.raining):
		return
	for i in range(n):
		var ph: float = fmod(_t * 0.45 + float(i) / float(n), 1.0)
		var px: float = x + sin(_t * 1.3 + float(i) * 2.1) * 3.0 + float(i - 1) * 4.0
		var py: float = y - ph * 28.0
		draw_circle(Vector2(px, py), 1.5 + ph * 3.0, Color(1, 1, 1, (1.0 - ph) * 0.3))


func _kunang_kunang(n: int, area: Rect2) -> void:
	var jam: int = TimeManager.jam()
	if not (jam >= 19 or jam < 5) or TimeManager.raining:
		return
	for i in range(n):
		var fi: float = float(i)
		var bx: float = area.position.x + fmod(fi * 137.0, area.size.x)
		var by: float = area.position.y + fmod(fi * 53.0, area.size.y)
		var x: float = bx + sin(_t * 0.7 + fi * 1.9) * 14.0
		var y: float = by + cos(_t * 0.9 + fi * 2.3) * 8.0
		var a: float = clampf(sin(_t * 2.1 + fi * 1.7) * 0.8 + 0.2, 0.0, 1.0)
		draw_circle(Vector2(x, y), 3.0, Color(0.8, 1.0, 0.4, a * 0.16))
		draw_rect(Rect2(x, y, 1.0, 1.0), Color(0.95, 1.0, 0.6, a))


func _kedip_meteran(x: float, y: float) -> void:
	var l: int = Daily.listrik_hari()
	if l <= 2:
		var on: bool = fmod(_t, 1.0 if l > 0 else 0.5) < 0.25
		if on:
			draw_rect(Rect2(x + 4.0, y + 6.0, 2.0, 2.0), Color("#ff3a2a"))
			_glow(Vector2(x + 5.0, y + 7.0), 7.0, Color(1.0, 0.2, 0.1, 0.07), 3)


func _fx_kos() -> void:
	var jam: float = _jam_f()
	var malam: bool = jam >= 19.0 or jam < 5.0
	var senja: float = clampf((jam - 17.0) / 2.0, 0.0, 1.0)
	# langit di jendela menggelap saat senja & malam
	var win := Rect2(17, 20, 95, 150)
	if jam >= 17.0 or jam < 5.0:
		var a: float = 0.6 if malam else 0.55 * senja
		draw_rect(win, Color(0.04, 0.07, 0.22, a))
		if malam:
			for i in range(12):
				var sx: float = win.position.x + 6.0 + fmod(float(i) * 37.0, win.size.x - 12.0)
				var sy: float = win.position.y + 6.0 + fmod(float(i) * 23.0, 64.0)
				var tw: float = 0.4 + 0.6 * absf(sin(_t * 1.5 + float(i)))
				draw_rect(Rect2(sx, sy, 1, 1), Color(1, 1, 0.85, tw))
			for i in range(7):
				draw_rect(Rect2(win.position.x + 8.0 + float(i) * 13.0, win.position.y + 118.0 + fmod(float(i) * 17.0, 24.0), 2, 2), Color(1.0, 0.85, 0.4, 0.75))
	# sinar matahari yang "tertanam" di gambar ikut meredup saat senja & malam
	if jam >= 17.0 or jam < 6.0:
		var g: float = 0.42 if malam or jam < 6.0 else 0.42 * senja
		draw_colored_polygon(PackedVector2Array([Vector2(138, 266), Vector2(335, 266), Vector2(305, 202), Vector2(168, 202)]), Color(0.04, 0.05, 0.16, g))
	# butir debu di sinar matahari (pagi-sore)
	if jam >= 7.0 and jam < 16.5 and not TimeManager.raining:
		for i in range(18):
			var fi: float = float(i)
			var x: float = 150.0 + fmod(fi * 47.0, 150.0) + sin(_t * 0.4 + fi) * 6.0
			var y: float = 205.0 + fmod(fi * 29.0, 55.0) - fmod(_t * 3.0 + fi * 7.0, 55.0)
			if y < 195.0:
				y += 55.0
			draw_rect(Rect2(x, y, 1, 1), Color(1.0, 0.95, 0.75, 0.35 + 0.25 * sin(_t * 2.0 + fi)))
	# hujan di kaca jendela
	if TimeManager.raining:
		for i in range(16):
			var fi: float = float(i)
			var x: float = win.position.x + 4.0 + fmod(fi * 29.0, win.size.x - 8.0)
			var y: float = win.position.y + fmod(_t * (40.0 + fmod(fi * 7.0, 20.0)) + fi * 31.0, win.size.y)
			draw_line(Vector2(x, y), Vector2(x - 1.0, y + 5.0), Color(0.8, 0.9, 1.0, 0.45), 1.0)
	# cahaya lampu belajar
	if GameState.has_flag("lampu") and (malam or jam < 6.5) and Daily.listrik_ada():
		_glow(Vector2(19, 172), 46.0, Color(1.0, 0.88, 0.5, 0.05), 5)
	# listrik padam: kamar jadi gelap (ditangani juga lewat pewarnaan global)
	if not Daily.listrik_ada() and malam:
		draw_rect(Rect2(0, 0, size_px.x, size_px.y), Color(0.0, 0.0, 0.08, 0.25))


func _fx_koridor() -> void:
	var jam: float = _jam_f()
	# langit senja di gambar berubah jadi malam
	var langit: float = clampf((jam - 18.0) / 1.5, 0.0, 1.0) if jam >= 12.0 else clampf((6.0 - jam) / 1.0, 0.0, 1.0)
	if langit > 0.0:
		draw_rect(Rect2(0, 0, size_px.x, 76), Color(0.03, 0.05, 0.18, 0.62 * langit))
	if jam >= 17.5 or jam < 5.5:
		for cx in [37.0, 134.0, 216.0, 298.0, 381.0]:
			draw_rect(Rect2(cx - 2.0, 158.0, 4, 3), Color(1.0, 0.92, 0.6))
			_glow(Vector2(cx, 162.0), 30.0, Color(1.0, 0.85, 0.45, 0.045), 5)
			# ngengat mengitari lampu
			var a: float = _t * 2.2 + cx
			draw_rect(Rect2(cx + cos(a) * 9.0, 160.0 + sin(a * 1.3) * 5.0, 1, 1), Color(0.95, 0.9, 0.8, 0.9))
	_kedip_meteran(78.0, 163.0)
	if TimeManager.raining:
		draw_rect(Rect2(0, 262, size_px.x, 8), Color(0.62, 0.72, 0.85, 0.12))


func _fx_masjid() -> void:
	# kipas langit-langit berputar
	for fx in [150.0, 340.0]:
		var w: float = 18.0 * absf(cos(_t * 7.0 + fx))
		draw_line(Vector2(fx - w, 43.0), Vector2(fx + w, 43.0), Color(0.15, 0.15, 0.2, 0.9), 2.0)
		draw_line(Vector2(fx - w * 0.5, 41.0), Vector2(fx + w * 0.5, 45.0), Color(0.15, 0.15, 0.2, 0.5), 1.0)
	# lampu gantung utama
	var jam: float = _jam_f()
	var malam: bool = jam >= 18.0 or jam < 5.0
	_glow(Vector2(240, 44), 70.0 if malam else 40.0, Color(1.0, 0.9, 0.55, 0.05 if malam else 0.03), 5)
	if malam:
		draw_rect(Rect2(0, 0, size_px.x, size_px.y), Color(0.0, 0.0, 0.1, 0.12))
