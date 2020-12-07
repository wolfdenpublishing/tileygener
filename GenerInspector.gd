extends MarginContainer


var property_monitors = []


func create_inspector(node:Node) -> void:
	while get_child_count() > 0:
		get_child(0).free()
	property_monitors = []
	var vbox := VBoxContainer.new()
	vbox.set("custom_constants/separation", 8)
	add_child(vbox)
	for property in node.gener_properties:
		add_control(vbox, node, property)


func add_control(vbox:VBoxContainer, node:Node, property:String):
	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)
	add_label(hbox, property.capitalize())
	var control
	match node.gener_properties[property][0]:
		"bool":
			control = add_bool_control(hbox, node, property)
		"int", "float":
			control = add_numeric_control(hbox, node, property)
		"string":
			control = add_string_control(hbox, node, property)
		"option":
			control = add_option_control(hbox, node, property)
		"array":
			control = add_array_control(hbox, node, property)
		_:
			control = add_label(hbox, "?: %s" % node.gener_properties[property][0])
	property_monitors.push_back(PropertyUpdater.new(node, property, control))


func add_label(hbox:HBoxContainer, label_text:String):
	var label := Label.new()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.text = label_text
	hbox.add_child(label)


func add_bool_control(hbox:HBoxContainer, node:Node, property:String, array_element:int = -1):
	var check_box = CheckBox.new()
	check_box.size_flags_horizontal = SIZE_EXPAND_FILL
	if array_element == -1:
		check_box.pressed = node[property] 
	else:
		check_box.pressed = node[node.gener_properties[property][1]][array_element]
	hbox.add_child(check_box)
	return check_box


func add_numeric_control(hbox:HBoxContainer, node:Node, property:String, array_element:int = -1):
	var spin_box := SpinBox.new()
	spin_box.size_flags_horizontal = SIZE_EXPAND_FILL
	if array_element == -1:
		spin_box.min_value = node.gener_properties[property][1]
		spin_box.max_value = node.gener_properties[property][2]
		if node.gener_properties[property][0] == "float":
			spin_box.step = node.gener_properties[property][3]
		spin_box.value = node[property]
	else:
		spin_box.min_value = node.gener_properties[property][5]
		spin_box.max_value = node.gener_properties[property][6]
		if node.gener_properties[property][3] == "float":
			spin_box.step = node.gener_properties[property][7]
		spin_box.value = node[node.gener_properties[property][1]][array_element]
	hbox.add_child(spin_box)
	return spin_box


func add_string_control(hbox:HBoxContainer, node:Node, property:String, array_element:int = -1):
	var line_edit := LineEdit.new()
	line_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	if array_element == -1:
		line_edit.text = node[property]
	else:
		line_edit.text = node[node.gener_properties[property][1]][array_element]
	hbox.add_child(line_edit)
	return line_edit


func add_option_control(hbox:HBoxContainer, node:Node, property:String, array_element:int = -1):
	var option_button := OptionButton.new()
	option_button.size_flags_horizontal = SIZE_EXPAND_FILL
	var option_list
	if array_element == -1:
		option_list = node.gener_properties[property][1]
	else:
		option_list = node.gener_properties[property][5]
	var n := 0
	for option in option_list:
		option_button.add_item(option, n)
		if array_element == -1:
			if node[property] == option:
				option_button.selected = n
		else:
			if option == node.gener_properties[property][4]:
				option_button.selected = n
		n += 1
	hbox.add_child(option_button)
	return option_button


func add_array_control(hbox:HBoxContainer, node:Node, property:String):
	var parent_vbox = hbox.get_parent()
	parent_vbox.remove_child(hbox)
	var vbox = VBoxContainer.new()
	parent_vbox.add_child(vbox)
	vbox.add_child(hbox)
	var control_variable := SpinBox.new()
	control_variable.size_flags_horizontal = SIZE_EXPAND_FILL
	control_variable.min_value = 0
	control_variable.max_value = node.gener_properties[property][2]
	control_variable.value = node[property]
	hbox.add_child(control_variable)
	var vbox2 := VBoxContainer.new()
	vbox2.set("custom_constants/separation", 8)
	hbox.get_parent().add_child(vbox2)
	var property_array = node[node.gener_properties[property][1]]
	var array_elements = node.gener_properties[property][2]
	if property_array.size() < array_elements:
		property_array.resize(array_elements)
		for n in array_elements:
			property_array[n] = node.gener_properties[property][4]
	for n in array_elements:
		var hbox2 := HBoxContainer.new()
		vbox2.add_child(hbox2)
		add_label(hbox2, "  %s [%s]" % [node.gener_properties[property][1].capitalize(), n])
		var control
		match node.gener_properties[property][3]:
			"bool":
				control = add_bool_control(hbox2, node, property, n)
			"int", "float":
				control = add_numeric_control(hbox2, node, property, n)
			"string":
				control = add_string_control(hbox2, node, property, n)
			"option":
				control = add_option_control(hbox2, node, property, n)
			_:
				control = add_label(hbox2, "?: %s" % node.gener_properties[property][3])
		if n >= node[property]:
			control.get_parent().visible = false
	return control_variable


func update_inspector():
	for monitor in property_monitors:
		match monitor.node.gener_properties[monitor.property][0]:
			"bool":
				monitor.control.pressed = monitor.node[monitor.property]
			"int", "float":
				monitor.control.value = monitor.node[monitor.property]
			"string":
				monitor.control.text = monitor.node[monitor.property]
			"option":
				pass
			"array":
				pass


class PropertyUpdater:
	
	var node:Node
	var property:String
	var control:Control
	var array_element:int
	var array_element_monitors = []
	
	
	func _init(node_in:Node, property_in:String, control_in:Control, array_element_in:int = -1):
		node = node_in
		property = property_in
		control = control_in
		array_element = array_element_in
		var type:String
		var on_array_element:String
		if array_element == -1:
			type = node.gener_properties[property][0]
			on_array_element = ""
		else:
			type = node.gener_properties[property][3]
			on_array_element = "_array_element"
		match type:
			"bool":
				var err = control.connect("toggled", self, "_on_update" + on_array_element)
				assert(err == OK)
			"int", "float":
				var err = control.connect("value_changed", self, "_on_update" + on_array_element)
				assert(err == OK)
			"string":
				var err = control.connect("text_changed", self, "_on_update" + on_array_element)
				assert(err == OK)
			"option":
				var err = control.connect("item_selected", self, "_on_option_update" + on_array_element)
				assert(err == OK)
			"array":
				var err = control.connect("value_changed", self, "_on_array_size_update")
				assert(err == OK)
				var vbox = control.get_parent().get_parent().get_child(1)
				for n in vbox.get_child_count():
					var array_element_control = vbox.get_child(n).get_child(1)
					array_element_monitors.push_back(PropertyUpdater.new(node, property, array_element_control, n))


	func _on_update(value):
		node[property] = value


	func _on_option_update(index):
		node[property] = node.gener_properties[property][1][index]


	func _on_array_size_update(value):
		node[property] = value
		var vbox = control.get_parent().get_parent().get_child(1)
		for n in vbox.get_child_count():
				vbox.get_child(n).visible = n < value


	func _on_update_array_element(value):
		node[node.gener_properties[property][1]][array_element] = value


	func _on_option_update_array_element(index):
		node[node.gener_properties[property][1]][array_element] = node.gener_properties[property][5][index]
