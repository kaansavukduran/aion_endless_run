extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func largest_body(image: Image) -> Rect2i:
 var width:=image.get_width();var height:=image.get_height()
 var visited:=PackedByteArray();visited.resize(width*height)
 var largest:=0;var bounds:=Rect2i()
 for y in height:
  for x in width:
   var index:=y*width+x
   if visited[index] or image.get_pixel(x,y).a<.75:continue
   var queue:=PackedInt32Array([index]);visited[index]=1;var cursor:=0;var low:=Vector2i(x,y);var high:=low
   while cursor<queue.size():
    var at:=queue[cursor];cursor+=1;var xx:=at%width;var yy:=int(at/width)
    low=Vector2i(mini(low.x,xx),mini(low.y,yy));high=Vector2i(maxi(high.x,xx),maxi(high.y,yy))
    for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
     var nx: int=xx+offset.x;var ny: int=yy+offset.y
     if nx<0 or nx>=width or ny<0 or ny>=height:continue
     var next: int=ny*width+nx
     if not visited[next] and image.get_pixel(nx,ny).a>=.75:visited[next]=1;queue.append(next)
   if queue.size()>largest:largest=queue.size();bounds=Rect2i(low,high-low+Vector2i.ONE)
 return bounds
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var catalog:=CampaignCatalog.new();var bank:=RunnerFrameBank.new();var hashes: Dictionary={};var count:=0
 for key in CampaignCatalog.DATA.data.atlases:
  var atlas: Dictionary=CampaignCatalog.DATA.data.atlases[key]
  var hash:=FileAccess.get_sha256("res://"+str(atlas.path))
  check(hash==str(atlas.sha256),"Unchanged original source bytes agree with provenance: "+key)
  for row in atlas.rows:
   for frame in atlas.frames[row].size():
    var pose:=catalog.pose(key,row,frame);var image: Image=pose.texture.get_image();var valid:=true
    for x in image.get_width():valid=valid and image.get_pixel(x,0).a==0. and image.get_pixel(x,image.get_height()-1).a==0.
    for y in image.get_height():valid=valid and image.get_pixel(0,y).a==0. and image.get_pixel(image.get_width()-1,y).a==0.
    check(valid,"Runtime texture isolates every source drawing with transparent sampling gutters: %s/%d/%d" % [key,row,frame])
    var digest:=HashingContext.new();digest.start(HashingContext.HASH_SHA256);digest.update(image.get_data());hashes[digest.finish().hex_encode()]=true;count+=1
    if key=="rescue-heroes":
     var body:=largest_body(image);var actual_bottom: float=pose.offset.y+body.end.y*float(atlas.scales[row])
     check(absf(actual_bottom)<=.001,"Knife connected feet, not loose pixels, meet ground: %d/%d" % [row,frame])
     var hero: String=["aion","owl","sheep","wolf","rabbit","eren"][row]
     var neutral:=bank.pose("gun-run",bank.hero_row(hero),0);var neutral_body:=largest_body(neutral.texture.get_image());var approved: float=neutral_body.size.y*float(neutral.scale)
     check(body.size.y*float(atlas.scales[row])>approved*.80 and body.size.y*float(atlas.scales[row])<approved*1.17,"Knife body retains approved hero proportions: "+hero+" "+str(frame)+" actual="+str(body.size.y*float(atlas.scales[row]))+" approved="+str(approved))
 check(count==659 and hashes.size()==659,"659 independently sampled, nonidentical usable drawings; one bad connected source cell excluded")
 print("RESULT: %d campaign expansion art checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
