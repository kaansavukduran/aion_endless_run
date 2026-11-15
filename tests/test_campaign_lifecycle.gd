extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 await process_frame
 var baseline: int=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 var orphan_baseline: int=Node.get_orphan_node_ids().size()
 var samples: Array=[]
 for cycle in 4:
  var scene:=AionCampaignGame.new();root.add_child(scene);await process_frame;scene.set_process(false);scene.audio_enabled=false
  for stage in ["fork_one","water","fork_two","terrace","roots","arena"]:
   scene.world.load_section(stage);scene.resize();await process_frame;await process_frame
  scene.queue_free();await process_frame;await process_frame
  var nodes: int=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT));samples.append(nodes)
  check(nodes<=baseline,"Campaign scenes, touch controls, ambient and menus release all nodes after exit: "+str(cycle))
  check(Node.get_orphan_node_ids().size()<=orphan_baseline,"Campaign cycle leaves no additional orphan nodes")
 print("LIFECYCLE ",JSON.stringify({"node_baseline":baseline,"after_cycles":samples,"scope":"native headless node lifetime; not GPU/WASM peak memory"}))
 print("RESULT: %d campaign lifecycle checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
