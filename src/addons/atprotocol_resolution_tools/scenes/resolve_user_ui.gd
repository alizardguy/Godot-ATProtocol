extends Control

@export var handle_input: TextEdit;

func _on_resolve_pressed():
	ATPResolution.resolve_identity_from_handle(handle_input.text);
