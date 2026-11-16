extends Node
## Pooled sound effects and one music loop.

const SOUNDS := {
	"tick": "res://assets/raw/audio/click_001.ogg",
	"reelstop": "res://assets/raw/audio/metalClick.ogg",
	"lever": "res://assets/raw/audio/chips-handle-1.ogg",
	"coin": "res://assets/raw/audio/handleCoins.ogg",
	"coin_stack": "res://assets/raw/audio/chips-stack-1.ogg",
	"sword": "res://assets/raw/audio/knifeSlice2.ogg",
	"block": "res://assets/raw/audio/impactMetal_light_000.ogg",
	"hurt": "res://assets/raw/audio/impactPunch_medium_000.ogg",
	"skull": "res://assets/raw/audio/impactMetal_heavy_000.ogg",
	"boom": "res://assets/raw/audio/lowFrequency_explosion_000.ogg",
	"bell": "res://assets/raw/audio/impactBell_heavy_000.ogg",
	"click": "res://assets/raw/audio/click_001.ogg",
	"card": "res://assets/raw/audio/card-slide-1.ogg",
	"thud": "res://assets/raw/audio/impactGeneric_light_000.ogg",
}
const MUSIC := "res://assets/raw/audio/8bit_dungeon_level.ogg"

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _cursor := 0
var _music_started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SOUNDS.keys():
		var stream = load(SOUNDS[key])
		if stream != null:
			_streams[key] = stream
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -16.0
	add_child(_music)
	var m = load(MUSIC)
	if m is AudioStreamOggVorbis:
		m.loop = true
	_music.stream = m


func play_music() -> void:
	if _music_started or _music == null or _music.stream == null:
		return
	_music_started = true
	_music.play()


func play(key: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(key):
		return
	var p := _players[_cursor]
	_cursor = (_cursor + 1) % _players.size()
	p.stream = _streams[key]
	p.pitch_scale = clamp(pitch, 0.5, 2.0)
	p.volume_db = volume_db
	p.play()


func tick(strength: float = 1.0) -> void:
	play("tick", randf_range(0.92, 1.08), lerp(-16.0, -6.0, strength))


func stop_music() -> void:
	if _music:
		_music.stop()
		_music_started = false
