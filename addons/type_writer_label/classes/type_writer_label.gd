## Provides a configurable "typewriter" effect on a [RichTextLabel].
@tool
class_name TypeWriterLabel extends RichTextLabel

signal writing_done

## in character/second. Time before the full text is displayed.
@export_range(0.0, 1000.0) var typing_speed: float = 40.0
## Optional. Plays whenever new characters are displayed on screen.
@export var writing_sound_player: AudioStreamPlayer
## Setup a pause after reaching a specific character.
@export var pause_after_character: bool = false:
	set(value):
		pause_after_character = value
		notify_property_list_changed()
## 
@export var pause_characters: Array[String] = ["."]
@export var pause_duration: float = 1.0

var _text_to_type: String = ""
var _typing: bool = false
var _typing_time_gap: float = 0.0
var _typing_timer: float = 0.0
var _pause_timer: float = 0.0
var _stopped: bool = false

# INSPECTOR CONFIGURATION
func _validate_property(property: Dictionary) -> void:
	var hide_list = []
	if !pause_after_character:
		hide_list.append("pause_characters")
		hide_list.append("pause_duration")

	if property.name in hide_list:
		property.usage = PROPERTY_USAGE_NO_EDITOR

# MAIN FUNCTIONS
func _ready() -> void:
	_typing_time_gap = 1.0 / typing_speed
	if !text.is_empty():
		write(text)

func _process(delta: float) -> void:
	if _typing && !_stopped && !_text_to_type.is_empty():
		if _pause_timer <= 0:
			# Compute how much chars shall be written on the current frame.
			# More than 1 character can be written if the typing speed is higher than current framerate.
			var next_chars := ""
			while !_text_to_type.is_empty() && _typing_timer <= 0:
				var next_char = _text_to_type[0]
				_text_to_type = _text_to_type.erase(0)
				next_chars += next_char
				_typing_timer += _typing_time_gap
				# However if a "pause" character is reached, do not type more characters for the current frame.
				if pause_after_character && _is_pause_character(next_char):
					_pause_timer = pause_duration
					break
			text += next_chars
			# Play writing sound if exists and is not playing.
			if writing_sound_player && !writing_sound_player.playing:
				writing_sound_player.play()
			_typing_timer -= delta
		_pause_timer -= delta
	else: # Finish typing
		writing_done.emit()
		_typing = false


func _is_pause_character(char: String) -> bool:
	for pause_char in pause_characters:
		if char == pause_char:
			return true
	return false


## Start typing the given text.
func write(text_to_type: String) -> void:
	text = ""
	_typing_timer = 0.0
	_pause_timer = 0.0
	_text_to_type = text_to_type
	_typing = true


## Speed up current typing by the speed_scale amount. Will also skip pauses if asked for.
## @experimental
func speed_up_typing(speed_scale: float, skip_pauses: bool = false) -> void:
	pass

## @experimental
func pause_typing() -> void:
	set_deferred("_stopped", true)

## @experimental
func resume_typing() -> void:
	set_deferred("_stopped", false)


## Skip current typing and display the whole text.
## @experimental
func skip_typing() -> void:
	pass
