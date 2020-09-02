extends Control

var max_width = 0
var height = 0

func show_text(txt_a:Array):
	max_width = 0
	height = 0
	var font = $Text.get_font("font")
	$Text.text = ""
	for i in range(0, txt_a.size()):
		$Text.text += txt_a[i] + ("\n" if i != txt_a.size() - 1 else "")
		height += font.get_string_size(txt_a[i]).y + 3
		max_width = max(font.get_string_size(txt_a[i]).x, max_width)
	yield(get_tree().create_timer(0.01), "timeout")
	$Text.rect_size.x = max_width
	$Text.rect_size.y = height
