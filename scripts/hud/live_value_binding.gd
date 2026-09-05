extends Node
## Update a value without replacing its control, focus, tooltip or click target.
var target:Node
var property:String
var reader:Callable
var elapsed:=0.0
static func attach(node:Node,key:String,callback:Variant)->void:
	if not callback is Callable or not callback.is_valid(): return
	var binding:=new()
	binding.target=node; binding.property=key; binding.reader=callback
	node.add_child(binding)
func _process(delta:float)->void:
	elapsed+=delta
	if elapsed<.25: return
	elapsed=0
	refresh()
func refresh()->void:
	if not is_instance_valid(target) or not reader.is_valid(): return
	if target is Control and not target.is_visible_in_tree(): return
	var value:Variant=reader.call()
	if target.get(property)!=value: target.set(property,value)
