## Provides a configurable "typewriter" effect on a [RichTextLabel].
@tool
class_name TypeWriterLabel extends RichTextLabel

## Emitted when the last character from the text of the last [method write] has been typed.
signal writing_done

## Current typing speed in character per second.
@export_range(0.0, 1000.0) var typing_speed: float = 40.0:
	set(value):
		_typing_time_gap = 1.0 / typing_speed

## Optional. Plays whenever new characters are displayed on screen.
@export var writing_sound_player: AudioStreamPlayer
## Set [code]true[/code] if you want a pause after reaching a specific character.
@export var pause_after_character: bool = false:
	set(value):
		pause_after_character = value
		notify_property_list_changed()
## Duration of the pause after reaching a character from the [member pause_characters] list.
@export var pause_duration: float = 1.0
## Whenever a character from [member pause_characters] is reached, the [TypeWriterLabel] will stop typing for [member pause_duration] seconds.
@export var pause_characters: Array[String] = ["."]


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
	if !Engine.is_editor_hint():
		if !text.is_empty():
			write(text)


func _process(delta: float) -> void:
	if !Engine.is_editor_hint():
		if _typing:
			if !_stopped && !_text_to_type.is_empty():
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


## Returns [code]true[/code] if currently typing a text.
func is_typing() -> bool:
	return _typing


## Type the given text at [member typing_speed] characters per seconds.
func write(text_to_type: String) -> void:
	_typing_time_gap = 1.0 / typing_speed
	text = ""
	_typing_timer = 0.0
	_pause_timer = 0.0
	_text_to_type = text_to_type
	_typing = true

## @experimental
func pause_typing() -> void:
	set_deferred("_stopped", true)

## @experimental
func resume_typing() -> void:
	set_deferred("_stopped", false)

## Skip current typing and display the whole text.
func skip_typing() -> void:
	set_deferred("_typing_time_gap", 0.0)
