class_name BattleLogControl
extends Control

const HEADER_TEXT := "[b]Battle Log[/b]\n"

var rich_text_label: RichTextLabel


func _ready() -> void:
	if not _cache_nodes():
		return
	rich_text_label.bbcode_enabled = true
	clear()


func open() -> void:
	show()


func close() -> void:
	hide()


func clear() -> void:
	if not _cache_nodes():
		return
	rich_text_label.text = HEADER_TEXT


func add_message(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	if not _cache_nodes():
		return
	if not visible:
		show()
	rich_text_label.append_text("%s\n" % _escape_bbcode(message))
	rich_text_label.scroll_to_line(rich_text_label.get_line_count())


func _cache_nodes() -> bool:
	if rich_text_label == null:
		rich_text_label = get_node_or_null("MarginContainer/PanelContainer/ScrollContainer/RichTextLabel") as RichTextLabel
	return rich_text_label != null


func _escape_bbcode(message: String) -> String:
	return message.replace("[", "[lb]")
