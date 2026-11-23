extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func settle():
 await process_frame;await process_frame;await process_frame
func _initialize():call_deferred('run')
func run():
 var cfg=ConfigFile.new();cfg.set_value('prefs','character','wolf');cfg.set_value('records','best',731)
 cfg.set_value('prefs','language_mode_revision',2);cfg.set_value('prefs','language_override',true);cfg.set_value('prefs','language','it');cfg.save('user://save.cfg')
 var game=load('res://scripts/game.gd').new();root.add_child(game);await settle();game.set_physics_process(false);game.front.skip_intro();await settle()
 check(GameText.LANGUAGES==['tr','en'],'Only Turkish and English are selectable')
 check(game.FRIENDS==['aion','sheep','rabbit','eren','armadillo','frog'],'Six playable heroes preserve original four order; companions are absent')
 check(game.character=='aion' and game.best==731,'Removed saved hero migrates without deleting the record')
 check(game.language==game.default_language() and not game.language_override,'Removed saved locale follows the supported device fallback')
 check(game.character_name('rabbit')=='Ayça','Stable rabbit save key displays the new game identity')
 for locale in ['tr','tr-TR','TR_tr']:
  check(GameText.language_for_locale(locale)=='tr','Turkish device language: '+locale)
 for locale in ['en-US','cs-CZ','ja','it-IT']:
  check(GameText.language_for_locale(locale)=='en','Unsupported language falls back to English: '+locale)
 for viewport in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873)]:
  root.size=viewport;await settle();game.touch_mode=viewport.x<1000
  for scale_value in [1.,1.5,2.]:
   for locale in GameText.LANGUAGES:
    game.interface_options.text_scale=scale_value;game.language=locale;game.build_theme();game.ui.theme=game.ui_theme;game.rebuild();await settle()
    var seen=[]
    var previous=game.menu_layer.find_child('RosterPrevious',true,false)
    while previous!=null and not previous.disabled:
     previous.pressed.emit();await settle();previous=game.menu_layer.find_child('RosterPrevious',true,false)
    for page in game.FRIENDS.size():
     for button in game.menu_layer.find_children('*','Button',true,false):
      if not button.is_visible_in_tree():continue
      var rect=button.get_global_rect()
      check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=game.view_w+1 and rect.end.y<=game.view_h+1,'Visible action fits: '+str(button.name)+' '+str(viewport)+' '+str(scale_value)+' '+locale+' '+str(rect))
      if str(button.name).begins_with('StartSelect_'):seen.append(str(button.name).trim_prefix('StartSelect_'))
     for required in ['StartCampaign','StartRun','OpenSettings','HowToPlay']:
      var button=game.menu_layer.find_child(required,true,false)
      check(button!=null and button.is_visible_in_tree(),'Primary menu action remains reachable: '+required)
     var following=game.menu_layer.find_child('RosterNext',true,false)
     if following==null or following.disabled:break
     following.pressed.emit();await settle()
    for hero in game.FRIENDS:check(hero in seen,'Playable hero appears through real roster pages: '+hero)
    check(not game.menu_layer.find_child('StartSelect_owl',true,false) and not game.menu_layer.find_child('StartSelect_wolf',true,false),'Companions never appear as selectable hero cards')
 # A wide system font must not inflate a width-zero heading or hide a second card row.
 var broad=SystemFont.new();broad.font_names=PackedStringArray(['DejaVu Sans']);broad.fallbacks=game.interface_options.body_font.fallbacks
 for viewport in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873)]:
  root.size=viewport;await settle();game.touch_mode=true
  for scale_value in [1.,2.]:
   for locale in GameText.LANGUAGES:
    game.language=locale;game.interface_options.text_scale=scale_value;game.build_theme();game.interface_options.body_font=broad;game.ui_theme.default_font=broad;game.ui.theme=game.ui_theme;game.show_page('main');await settle()
    var heading=game.menu_layer.find_child('StartChooser',true,false)
    if heading.is_visible_in_tree():
     check(heading.size.y<=game.pixel_ui.chooser_height()+1.,'Actual shaped chooser stays within its measured height '+str(viewport)+' '+locale)
    for button in game.menu_layer.find_children('*','Button',true,false):
     if not button.is_visible_in_tree():continue
     var rect=button.get_global_rect()
     check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=game.view_w+1 and rect.end.y<=game.view_h+1,'Wide-font action fits '+str(button.name)+' '+str(viewport)+' '+locale+' '+str(rect))
     if heading.is_visible_in_tree() and str(button.name).begins_with('StartSelect_'):
      check(heading.get_global_rect().end.y<=rect.position.y,'Heading never overlaps a hero card '+str(viewport)+' '+locale)
 game.interface_options.text_scale=1.;game.show_page('main');await settle()
 for hero in game.FRIENDS:game.select_character(hero);check(game.character==hero,'Normal selection updates hero: '+hero)
 var arcade=AionCampaignGame.new();arcade.world.begin('aion');arcade.world.state='playing';arcade.down_down=true;arcade.right_down=true;arcade.update_arcade_aim()
 check(arcade.world.move_axis.y>.55 and arcade.world.move_axis.x>0,'Keyboard Down+Right reaches crawl intent')
 check(arcade.world.aim_direction.is_equal_approx(Vector2.RIGHT),'Crawling fires horizontally rather than into the ground')
 arcade.world.mount.ridden=true;arcade.pad_look=Vector2(.8,-.6);arcade.update_arcade_aim()
 check(arcade.world.aim_direction.is_equal_approx(Vector2(.8,-.6)),'Mounted right stick retains a continuous circular aim angle')
 var file=FileAccess.open('user://campaign.json',FileAccess.WRITE);file.store_string(JSON.stringify(arcade.world.snapshot()));file.close()
 for viewport in [Vector2i(1152,648),Vector2i(393,873)]:
  root.size=viewport;await settle();game.touch_mode=viewport.x<1000
  for locale in GameText.LANGUAGES:
   game.language=locale;game.interface_options.text_scale=2.;game.build_theme();game.ui.theme=game.ui_theme;game.show_page('main');await settle()
   var resume=game.menu_layer.find_child('ContinueCampaign',true,false)
   check(resume!=null and resume.is_visible_in_tree(),'Existing checkpoint has a visible Continue action at200% '+locale)
   var panel=game.menu_layer.find_child('PagePanel',true,false)
   for button in game.menu_layer.find_children('*','Button',true,false):
    if not button.is_visible_in_tree():continue
    var rect=button.get_global_rect()
    check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=game.view_w+1 and rect.end.y<=game.view_h+1,'Checkpoint-menu action fits: '+str(button.name)+' '+str(viewport)+' '+locale+' '+str(rect))
    if str(button.name).begins_with('StartSelect_'):check(not panel.get_global_rect().intersects(rect),'Operations plate never obscures a selectable hero '+str(viewport))
 arcade.free();game.queue_free();await settle()
 print('RESULT: ',checks,' arcade roster/UI checks, ',failures,' failures');quit(1 if failures else 0)
