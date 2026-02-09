extends Node
## Plays BGM and SFX. Placeholder for Phase 1 - real audio integration later.

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

const SFX_POOL_SIZE := 4


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)


func play_bgm(_track_name: String, _crossfade: float = 1.0) -> void:
	# TODO: Load and play BGM tracks once audio is extracted
	pass


func stop_bgm(_fade_out: float = 0.5) -> void:
	_bgm_player.stop()


func play_sfx(_sfx_name: String) -> void:
	# TODO: Load and play SFX once audio is extracted
	pass
