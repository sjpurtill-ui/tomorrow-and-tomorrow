extends Node
## Headless maintenance for the interaction database. Never contacts the API.
##   <godot> --headless --path <project> res://tools/interaction_db_tool.tscn -- <command> [options]
## Commands:
##   --stats                              counts by source, surface and type
##   --export <file.jsonl> [--with-shipped]
##   --import <bundle.jsonl> [--into user|<out.jsonl>] [--relabel curated]
##   --propose [--out <report.md>]        clustering and profile-drift report
## Options: --user-dir <dir> reads/writes another player store (default user://interactions/).

const _Store:=preload("res://scripts/interaction_store.gd")
const _Curation:=preload("res://scripts/interaction_curation.gd")

func _arg(args:PackedStringArray,name:String,fallback:String="")->String:
	var i:int=args.find(name)
	if i>=0 and i+1<args.size(): return args[i+1]
	return fallback

func _ready()->void:
	var args:PackedStringArray=OS.get_cmdline_user_args()
	var user_dir:String=_arg(args,"--user-dir","")
	if not user_dir.is_empty(): _Store.user_root=user_dir
	var code:int=0
	if args.has("--stats"):
		print(JSON.stringify(_Store.stats(),"  "))
	elif args.has("--export"):
		var result:Dictionary=_Store.export_bundle(_arg(args,"--export"),args.has("--with-shipped"))
		print(JSON.stringify(result))
		code=0 if bool(result.get("ok",false)) else 1
	elif args.has("--import"):
		var result2:Dictionary=_Store.import_bundle(_arg(args,"--import"),_arg(args,"--into","user"),_arg(args,"--relabel",""))
		print(JSON.stringify(result2))
		code=0 if bool(result2.get("ok",false)) else 1
	elif args.has("--propose"):
		var report:Dictionary=_Curation.propose()
		var md:String=_Curation.to_markdown(report)
		var out:String=_arg(args,"--out","")
		if out.is_empty(): print(md)
		else:
			var fa:FileAccess=FileAccess.open(out,FileAccess.WRITE)
			if fa==null: code=1
			else:
				fa.store_string(md); fa.flush()
				print("Report written to %s" % out)
	else:
		print("Usage: -- --stats | --export <file> | --import <bundle> [--into user|<out.jsonl>] [--relabel curated] | --propose [--out <md>]")
	get_tree().quit(code)
