tool
extends HSplitContainer

var editor_reference
var last_saved_glossary
var glossary
var current_entry

var types = {
	0: 'Extra Information',
	1: 'Number',
	2: 'Text'
}

onready var nodes = {
	'item_list': $VBoxContainer/ItemList,
	
	'type': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/TypeMenuButton,
	
	'name': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/LineEdit3,
	'title': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ExtraInfo/LineEdit,
	'body': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ExtraInfo/RichTextLabel,
	'extra': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ExtraInfo/LineEdit2,
	
	'number': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Number/SpinBox,
	'string': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Text/LineEdit3,
}

onready var section = {
	'ExtraInfo': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/ExtraInfo,
	'Number': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Number,
	'Text': $ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Text,
}


func _ready():
	glossary = DialogicUtil.load_glossary()
	last_saved_glossary = DialogicUtil.load_glossary()
	
	nodes['name'].connect("text_changed", self, '_on_field_name_changed', [])
	nodes['title'].connect("text_changed", self, '_on_field_text_changed', ['title'])
	nodes['body'].connect("text_changed", self, '_on_field_text_changed', ['', 'body'])
	nodes['extra'].connect("text_changed", self, '_on_field_text_changed', ['extra'])
	
	nodes['string'].connect("text_changed", self, '_on_field_text_changed', ['string'])
	
	nodes['number'].connect("value_changed", self, '_on_number_changed', [])
	
	change_editor(types[0]) # Default view
	refresh_list()
	disable_all()


func disable_all():
	nodes['type'].disabled = true
	nodes['name'].editable = false
	nodes['title'].editable = false
	nodes['body'].readonly = true
	nodes['extra'].editable = false


func enable_all():
	nodes['type'].disabled = false
	nodes['title'].editable = true
	nodes['name'].editable = true
	nodes['body'].readonly = false
	nodes['extra'].editable = true


func change_editor(type):
	section['ExtraInfo'].visible = false
	section['Number'].visible = false
	section['Text'].visible = false
	
	if type == 'Extra Information':
		section['ExtraInfo'].visible = true
	if type == 'Number':
		section['Number'].visible = true
	if type == 'Text':
		section['Text'].visible = true
	
	nodes['type'].text = type


func _on_number_changed(value):
	print(value)
	glossary[current_entry]['number'] = nodes['number'].value
	save_glossary()


func _on_field_text_changed(new_text, key):
	if key == 'body':
		new_text = nodes['body'].text
	glossary[current_entry][key] = new_text
	save_glossary()


func _on_field_name_changed(new_text):
	var f_text = new_text
	glossary[current_entry]['name'] = new_text
	
	save_glossary()
	refresh_list(glossary[current_entry]['file'])


func _on_NewEntryButton_pressed():
	var index = 0
	var new_entry_id = 'entry-' + DialogicUtil.generate_random_id()
	var add_new = true
	glossary[new_entry_id] = {
		'file': new_entry_id + '.json',
		'name': new_entry_id,
		'type': 0,
		'title': '',
		'body': '',
		'extra': '',
		'string': '',
		'number': 0,
		'color': '#000000',
	}
	current_entry = new_entry_id
	DialogicUtil.save_glossary(glossary)
	refresh_list(new_entry_id)


func refresh_list(select = ''):
	nodes['item_list'].clear()
	#var icon = load("res://addons/dialogic/Images/character.svg")
	var index = 0
	for entry in glossary:
		nodes['item_list'].add_item(glossary[entry]['name'], get_icon("MultiLine", "EditorIcons"))
		nodes['item_list'].set_item_metadata(index, {'file': entry, 'index': index})
		print('metadata: ', entry)
		print(nodes['item_list'].get_item_metadata(index))
		
		# Auto selecting on create
		if select != '':
			if glossary[entry]['name'] == select:
				_on_ItemList_item_selected(index)
		index += 1


func _on_ItemList_item_rmb_selected(index, at_position):
	editor_reference.get_node("GlossaryPopupMenu").rect_position = get_viewport().get_mouse_position()
	editor_reference.get_node("GlossaryPopupMenu").popup()


func _on_ItemList_item_selected(index):
	select_entry(index)


func select_entry(index):
	print('[!] Select entry ', index)
	var selected = nodes['item_list'].get_item_text(index)
	var entry_id = nodes['item_list'].get_item_metadata(index)['file'].replace('.json', '')
	current_entry = entry_id
	clear_editor()
	update_editor(glossary[entry_id])
	enable_all()


func _on_GlossaryPopupMenu_id_pressed(id):
	if id == 0:
		OS.shell_open(ProjectSettings.globalize_path(DialogicUtil.get_path('WORKING_DIR')))
	if id == 1:
		editor_reference.get_node("RemoveGlossaryConfirmation").popup_centered()


func _on_RemoveGlossaryConfirmation_confirmed():
	var selected = nodes['item_list'].get_selected_items()[0]
	var entry_id = nodes['item_list'].get_item_metadata(selected)['file'].replace('.json', '')
	for entry in glossary:
		if entry == entry_id:
			glossary.erase(entry)
	DialogicUtil.save_glossary(glossary)
	
	clear_editor()
	refresh_list()
	
	if glossary.size() > 0:
		nodes['item_list'].select(0)
		select_entry(0)


func save_glossary():
	var changed = false
	if glossary.hash() != last_saved_glossary.hash():
		changed = true
		last_saved_glossary = DialogicUtil.load_glossary()


func update_editor(data):
	nodes['name'].text = data['name']
	if data.has('title'):
		nodes['title'].text = data['title']
	if data.has('body'):
		nodes['body'].text = data['body']
	if data.has('extra'):
		nodes['extra'].text = data['extra']
	
	if data.has('number'):
		nodes['number'].value = data['number']
	
	if data.has('string'):
		nodes['string'].text = data['string']
		
	change_editor(types[int(data['type'])])
	_on_TypeMenuButton_item_selected(int(data['type']))


func clear_editor():
	if glossary.size() == 0:
		$ScrollContainer.visible = false
		$CenterContainer.visible = true
	else:
		$ScrollContainer.visible = true
		$CenterContainer.visible = false
	nodes['name'].text = ''
	nodes['title'].text = ''
	nodes['body'].text = ''
	nodes['extra'].text = ''
	nodes['string'].text = ''
	nodes['number'].value = 0
	nodes['type'].text = types[0]


func _on_TypeMenuButton_item_selected(index):
	nodes['type'].text = types[index]
	
	var i = 0
	for j in types:
		nodes['type'].get_popup().set_item_as_checkable(i, false)
		i += 1
	
	glossary[current_entry]['type'] = index
	
	change_editor(types[index])
