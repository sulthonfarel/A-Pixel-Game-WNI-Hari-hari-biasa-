extends Node
## Jam, hari, dan cuaca. 1 detik nyata = 2 menit dalam game (1 hari ≈ 9 menit nyata).

const MENIT_PER_DETIK := 2.0

var day: int = 1
var minutes: int = 360   # 06:00
var raining: bool = false
var running: bool = false
var _acc: float = 0.0


func reset() -> void:
	day = 1
	minutes = 360
	raining = false
	running = false
	_acc = 0.0


func jam() -> int:
	return floori(minutes / 60.0)


func menit() -> int:
	return minutes % 60


func jam_str() -> String:
	return "%02d:%02d" % [jam(), menit()]


func nama_hari(d: int = -1) -> String:
	if d < 0:
		d = day
	return GameData.HARI[(d - 1) % 7]


func hari_kerja(d: int = -1) -> bool:
	if d < 0:
		d = day
	return ((d - 1) % 7) < 5


func _process(delta: float) -> void:
	if not running or GameState.ui_open:
		return
	_acc += delta * MENIT_PER_DETIK
	while _acc >= 1.0:
		_acc -= 1.0
		advance(1)


func advance(mins: int) -> void:
	var awal: int = minutes
	for i in range(mins):
		if minutes >= 1440:
			break
		minutes += 1
		if minutes % 60 == 0:
			_on_hour()
	if minutes != awal:
		EventBus.waktu_maju.emit(awal, minutes)
	EventBus.stats_changed.emit()


func _on_hour() -> void:
	var h: int = jam()
	GameState.energi = clampi(GameState.energi - 3, 0, 100)
	GameState.kenyang = clampi(GameState.kenyang - 5, 0, 100)
	if GameState.kenyang < 20:
		GameState.mood = clampi(GameState.mood - 2, 0, 100)
	if GameState.kenyang <= 0:
		GameState.energi = clampi(GameState.energi - 3, 0, 100)
	_update_rain(h)
	EventBus.hour_changed.emit(h)


func _update_rain(h: int) -> void:
	var r: bool = false
	if h >= 15 and h < 18 and ((day * 7 + 3) % 10) < 6:
		r = true
	if h >= 19 and h < 21 and (day % 5) == 2:
		r = true
	if r != raining:
		raining = r
		EventBus.rain_changed.emit(r)


func new_day() -> void:
	day += 1
	minutes = 360
	_acc = 0.0
	if raining:
		raining = false
		EventBus.rain_changed.emit(false)
