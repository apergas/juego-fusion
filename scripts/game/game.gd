class_name Game extends Node
## One play session, created by TitleScreen (setup() before add_child); run on its own
## (res://scenes/game/game.tscn) it loads the save and makes its own AudioDirector. A coordinator:
## it owns the round's GameState, the current Jar (a new one each round), the game's clock (the
## round's time, the wait after a drop, the combo's clock and the danger's count, all on the
## physics frame) and the profile's record, bestiary and kept round, which it saves at the end of
## each round, at each discovery and whenever the player leaves a round still going
## (keep_round()). The Jar only reports (released, merge_found); the rules (Chain, Spawner,
## Scoring, Danger, Bestiary, RoundSnapshot, PowerUps) decide; Game plays it back through the Jar,
## the Hud and the windows. Its pieces: the Hud, the PauseWindow, the OptionsWindow over it and the
## EndWindow (created when needed), the BreakPicker and GameAutoplay (only with --autoplay). Esc,
## the HUD's button and losing the focus (FOCUS_LOST, never on autoplay) open the pause; a kept
## round comes back in the pause (resume_round()). The HUD's Cambiar swaps the waiting creature
## with «Siguiente» (swap_waiting()). Its Romper pauses the tree while its piece BreakPicker takes
## the tap (toggle_break(), break_creature()). Salir and Salir al título go back to the title
## (quit_to_title).

signal quit_to_title

## Losing the focus: another app, another tab, another window, the phone's home screen.
const FOCUS_LOST := [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT,
	NOTIFICATION_APPLICATION_PAUSED]

var state: GameState
var _audio: AudioDirector
var _options: GameOptions
var _profile: Profile
var _jar: Jar
var _hud: Hud
var _end: EndWindow
var _pause: PauseWindow
var _options_window: OptionsWindow
var _autopilot: GameAutoplay
var _picker: BreakPicker
## How many rounds this session has started: the seed of each is --seed=<n> plus it.
var _round := 0
## The session starts from the profile's kept round (the title's Seguir).
var _resume := false


## audio, options and profile come from the title screen; resume is its Seguir.
func setup(audio: AudioDirector, options: GameOptions, profile: Profile,
		resume := false) -> void:
	_audio = audio
	_options = options
	_profile = profile
	_resume = resume


func _ready() -> void:
	if _options == null:
		_options = GameOptions.new()
		_profile = Profile.new()
		SaveStore.load_into(_profile, _options)
		DisplaySettings.apply(get_window(), _options)
	if _audio == null:
		_audio = AudioDirector.new()
		add_child(_audio)
		_audio.set_volume(_options.sfx_volume)
	_hud = Hud.new()
	_hud.pause_requested.connect(open_pause)
	_hud.swap_requested.connect(swap_waiting)
	_hud.break_requested.connect(toggle_break)
	_picker = BreakPicker.new()
	_picker.picked.connect(_on_picked)
	_picker.cancelled.connect(_stop_picking)
	add_child(_picker)
	add_child(_hud)
	if RunFlags.autoplay():
		_autopilot = GameAutoplay.new()
		_autopilot.setup(func() -> GameState: return state, func() -> Jar: return _jar,
			RunFlags.autoplay_games(), RunFlags.autoplay_save(), RunFlags.autoplay_resume())
		_autopilot.drop = drop_at
		_autopilot.restart = _restart
		_autopilot.open_pause = open_pause
		_autopilot.close_pause = close_pause
		_autopilot.open_options = _open_options
		_autopilot.close_options = _close_options
		_autopilot.keep_round = keep_round
		_autopilot.resume_round = resume_round
		_autopilot.quit_requested.connect(_quit)
		add_child(_autopilot)
	if _resume and not _profile.saved_round.is_empty():
		resume_round(_profile.saved_round)
	else:
		_start_round()
	if _autopilot and RunFlags.autoplay_menu():
		_autopilot.start_menu_tour()


func _physics_process(delta: float) -> void:
	if not state.over:
		_tick(delta)
	if _autopilot:
		_autopilot.step(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		open_pause()


## Closing the window keeps the round; losing the focus opens the pause (which keeps it too),
## never on autoplay (its windows are recorded without the focus).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		keep_round()
	elif what in FOCUS_LOST and _autopilot == null:
		open_pause()


## Drops the waiting creature at x (kept inside the jar). The Jar's released and the autoplay
## call it; it does nothing while nothing waits.
func drop_at(x: float) -> void:
	if state.over or not state.can_drop:
		return
	var data := Chain.data(state.current)
	var body := _jar.drop(data, x)
	state.can_drop = false
	state.wait_left = Spawner.DROP_WAIT
	_audio.play_sfx(SfxLibrary.DROP)
	if _autopilot:
		_autopilot.on_dropped(data.id, body.position.x)
	_note_creature(data)
	Spawner.advance(state)
	_hud.set_next(Chain.data(state.next))
	_show_power_ups()


## The pause window over a stopped jar (the whole tree pauses; the window keeps running). Not
## once the round is over. Opening it keeps the round (keep_round()).
func open_pause() -> void:
	if state == null or state.over or _pause:
		return
	_stop_picking()
	keep_round()
	get_tree().paused = true
	_pause = PauseWindow.new()
	_pause.set_audio(_audio)
	_pause.resume_requested.connect(close_pause)
	_pause.options_requested.connect(_open_options)
	_pause.restart_requested.connect(func() -> void:
		close_pause()
		_restart())
	_pause.quit_requested.connect(func() -> void:
		close_pause()
		_quit())
	add_child(_pause)


func close_pause() -> void:
	if _pause == null:
		return
	_close_options()
	_pause.queue_free()
	_pause = null
	get_tree().paused = false


## The round still going into the profile (RoundSnapshot) and the save, so the title can offer
## Seguir: when the pause opens and when the window closes. Returns what was kept ({} if
## nothing: no round, or a lost one).
func keep_round() -> Dictionary:
	if state == null or state.over or _jar == null:
		return {}
	_profile.saved_round = RoundSnapshot.from(state, _jar.snapshot(), _jar.aim_x())
	SaveStore.save(_profile, _options)
	return _profile.saved_round


## A kept round (a valid RoundSnapshot) in place of the current one: its state, its creatures,
## the waiting one and its x. It opens in the pause (not on autoplay), so the player comes back
## ready.
func resume_round(data: Dictionary) -> void:
	state = RoundSnapshot.state_of(data)
	_new_jar()
	_jar.rebuild(RoundSnapshot.creatures_of(data))
	_show_round()
	if state.can_drop:
		_present()
	_jar.set_aim_x(RoundSnapshot.aim_x_of(data))
	_show_power_ups()
	if _autopilot == null:
		open_pause()


## Cambiar: the waiting creature and «Siguiente» change places (PowerUps), with its sound (the
## figure on top is replaced only if one is shown; in the drop wait the next one to appear is the
## swapped one); false (nothing changed) if it can't be used now. The HUD's button and the
## autoplay call it.
func swap_waiting() -> bool:
	if _picker.active or not PowerUps.swap(state):
		return false
	if state.can_drop:
		_jar.show_waiting(Chain.data(state.current))
	_hud.set_next(Chain.data(state.next))
	_audio.play_sfx(SfxLibrary.SWAP)
	_show_power_ups()
	return true


## Romper's button: starts choosing (the tree pauses, the hint shows) or, while choosing, stops
## without spending anything.
func toggle_break() -> void:
	if _picker.active:
		_stop_picking()
		return
	if _pause or not PowerUps.can_break(state, _jar.creatures().size()):
		_hud.set_picking(false)
		return
	_picker.start()
	get_tree().paused = true
	_hud.set_picking(true)


## Romper on body: it goes in a burst of its colour, with its sound, and gives nothing (a charge
## goes); false if it can't be used. The picker and the autoplay call it.
func break_creature(body: CreatureBody) -> bool:
	if body == null or body.merged or not PowerUps.use_break(state):
		return false
	_jar.break_creature(body)
	_audio.play_sfx(SfxLibrary.BREAK)
	_show_power_ups()
	return true


## A tap while choosing: the creature under it breaks; none there, it keeps choosing.
func _on_picked(screen: Vector2) -> void:
	var body := _jar.creature_at(_jar.world_point(screen))
	if body == null:
		return
	_stop_picking()
	break_creature(body)


func _stop_picking() -> void:
	if not _picker.active:
		return
	_picker.stop()
	_hud.set_picking(false)
	get_tree().paused = false


## The helps' buttons: their charges and whether they can be used now.
func _show_power_ups() -> void:
	_hud.set_power_ups(state.breaks, state.swaps,
		PowerUps.can_break(state, _jar.creatures().size()), PowerUps.can_swap(state))


## Opciones over the pause: each change is put into effect and saved, as on the title. The pause
## (and its scrim) hides while it is open, so it never shows through.
func _open_options() -> void:
	if _options_window or _pause == null:
		return
	_pause.visible = false
	_options_window = OptionsWindow.new(_options)
	_options_window.set_audio(_audio)
	_options_window.changed.connect(_on_options_changed)
	_options_window.closed.connect(_close_options)
	add_child(_options_window)


func _close_options() -> void:
	if _options_window == null:
		return
	_options_window.queue_free()
	_options_window = null
	if _pause:
		_pause.visible = true


func _on_options_changed() -> void:
	_audio.set_volume(_options.sfx_volume)
	_audio.play_sfx(SfxLibrary.CURSOR)
	DisplaySettings.apply(get_window(), _options)
	SaveStore.save(_profile, _options)


## One physics frame of the round: its clocks, the jar, then the danger's count.
func _tick(delta: float) -> void:
	state.elapsed += delta
	state.since_merge += delta
	if not state.can_drop:
		state.wait_left -= delta
		if state.wait_left <= 0.0:
			_present()
	_jar.step(delta)
	var over := Danger.is_over(_jar.highest_top(JarSpec.SETTLE_TIME))
	state.danger_time = Danger.step(state.danger_time, over, delta)
	_jar.show_danger(Danger.fraction(state.danger_time))
	if Danger.lost(state.danger_time):
		_lose()


## A new round: the kept one is forgotten, a new GameState, its first creatures and a new Jar.
func _start_round() -> void:
	_forget_round()
	var seed_flag := RunFlags.seed()
	state = GameState.new(seed_flag + _round if seed_flag >= 0 else -1)
	_round += 1
	Spawner.start(state)
	PowerUps.start(state)
	_new_jar()
	_show_round()
	_present()


## A new Jar in place of the old one.
func _new_jar() -> void:
	if _jar:
		remove_child(_jar)
		_jar.queue_free()
	_jar = Jar.new()
	_jar.released.connect(drop_at)
	_jar.merge_found.connect(_on_merge_found)
	add_child(_jar)


## The HUD of the round in state.
func _show_round() -> void:
	_hud.clear()
	_hud.set_score(state.score)
	_hud.set_record(_profile.best_score)
	_hud.set_next(Chain.data(state.next))


## A new round throws the kept one away, and the save says so at once (only if there was one).
func _forget_round() -> void:
	if _profile.saved_round.is_empty():
		return
	_profile.saved_round = {}
	SaveStore.save(_profile, _options)


## The waiting creature appears at the top of the jar.
func _present() -> void:
	state.can_drop = true
	state.wait_left = 0.0
	_jar.show_waiting(Chain.data(state.current))
	_show_power_ups()


## Two equal creatures touch (the Jar's merge_found): the combo and the points (Scoring), then the
## creature they make (Chain), or nothing for two of the last level.
func _on_merge_found(a: CreatureBody, b: CreatureBody) -> void:
	if state.over:
		return
	var level := a.data.level
	var old_score := state.score
	var old_max := state.max_level
	state.combo = Scoring.next_combo(state.combo, state.since_merge)
	state.since_merge = 0.0
	var points := Scoring.points(Chain.merge_points(level), state.combo)
	state.score += points
	var made := Chain.next_level(level)
	var at := (a.position + b.position) / 2.0
	if made == 0:
		_jar.vanish(a, b)
		_audio.play_sfx(SfxLibrary.PRIZE)
	else:
		var data := Chain.data(made)
		_jar.merge(a, b, data)
		_audio.play_sfx(SfxLibrary.plop_id(made))
		_note_creature(data)
	_jar.show_points(at, points)
	_vibrate(made if made > 0 else Chain.MAX_LEVEL)
	_hud.set_score(state.score)
	_hud.show_combo(state.combo)
	PowerUps.earn(state, old_score, old_max)
	_show_power_ups()
	if _autopilot:
		_autopilot.on_merged(Chain.IDS[made - 1] if made > 0 else "", state.combo)


## A creature has come into the jar (dropped or made by a merge): the round's biggest and, the
## first time ever, the bestiary, in silence: only a save (and the autoplay's line).
func _note_creature(data: CreatureData) -> void:
	state.max_level = maxi(state.max_level, data.level)
	if not Bestiary.discover(_profile, data.id):
		return
	SaveStore.save(_profile, _options)
	if _autopilot:
		_autopilot.on_discovered(data.id)


## A short vibration for a merge that makes level, if the player wants it (never on autoplay).
func _vibrate(level: int) -> void:
	if _options.vibration and _autopilot == null:
		Input.vibrate_handheld(Chain.vibration_ms(level))


## The jar overflowed: everything stops, the record is checked and saved (and the kept round
## forgotten in the same save), the end window opens.
func _lose() -> void:
	state.over = true
	state.can_drop = false
	_jar.freeze_all()
	_jar.show_danger(0.0)
	_show_power_ups()
	_audio.play_sfx(SfxLibrary.LOSE)
	var new_record := Scoring.record(_profile, state.score)
	_profile.saved_round = {}
	_hud.set_record(_profile.best_score)
	var saved := SaveStore.save(_profile, _options)
	_end = EndWindow.new(state.score, Chain.data(state.max_level).display_name, new_record)
	_end.set_audio(_audio)
	_end.again_requested.connect(_restart)
	_end.quit_requested.connect(_quit)
	add_child(_end)
	if _autopilot:
		_autopilot.on_round_over({"score": state.score, "max_level": state.max_level,
			"seconds": state.elapsed, "new_record": new_record}, saved)


## Otra vez: the end window goes and a new round starts.
func _restart() -> void:
	if _end:
		_end.queue_free()
		_end = null
	_start_round()


## Back to the title; a Game run on its own (nothing above it) quits instead.
func _quit() -> void:
	if get_parent() == get_tree().root:
		get_tree().quit()
		return
	quit_to_title.emit()
