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
 for viewport in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873),Vector2i(320,700)]:
  root.size=viewport;await settle();game.touch_mode=viewport.x<1000
  for scale_value in [1.,1.5,2.]:
   for locale in GameText.LANGUAGES:
    game.language=locale;game.interface_options.text_scale=scale_value;game.build_theme();game.ui.theme=game.ui_theme
    game.show_page("characters");await settle()
    var cards: Array=game.menu_layer.find_children("Select_*","Button",true,false)
    check(cards.size()==6,"All six cards on one screen "+str(viewport)+locale)
    for card in cards:
     var viewport_rect:=Rect2(0,0,game.view_w,game.view_h)
     check(card.is_visible_in_tree() and viewport_rect.encloses(card.get_global_rect()),"Selectable target fits "+str(card.name)+str(viewport)+locale)
     for child in card.get_children():
      check(card.get_global_rect().encloses(child.get_global_rect()),"Name and portrait fit their rectangle "+str(card.name))
      if child is Label:
       check(child.get_theme_font("font").get_string_size(child.text,HORIZONTAL_ALIGNMENT_LEFT,-1,child.get_theme_font_size("font_size")).x<=child.size.x,"Full localized name fits "+child.text)
      elif child is RunnerHeroPreview and viewport.x<viewport.y:
       var name_label: Label=card.get_node("HeroName")
       check(child.position==Vector2(2.,2.) and is_equal_approx(child.size.x,card.size.x-4.) and is_equal_approx(child.position.y+child.size.y,name_label.position.y+2.),"Phone portrait fills the card down to the name band: "+str(card.name))
      elif child is RunnerHeroPreview and viewport.x>viewport.y and scale_value==1.:
       check(child.size.aspect()<1.4,"The landscape card shows a full portrait instead of a cropped strip: "+str(card.name))
    var confirm: Button=game.menu_layer.find_child("ConfirmHero",true,false)
    var back: Button=game.menu_layer.find_child("CharacterBack",true,false)
    check(confirm!=null and back!=null and confirm.is_visible_in_tree() and back.is_visible_in_tree(),"Confirm and Back have real valid controls")
    check(game.menu_layer.find_child("NextPage",true,false)==null,"Picker requires no pagination")
 for hero in game.FRIENDS:
  game.select_character(hero)
  check(game.character==hero,"Normal selection updates hero: "+hero)
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
   for button in game.menu_layer.find_children('*','Button',true,false):
    if not button.is_visible_in_tree():continue
    var rect=button.get_global_rect()
    check(rect.position.x>=-1 and rect.position.y>=-1 and rect.end.x<=game.view_w+1 and rect.end.y<=game.view_h+1,'Checkpoint-menu action fits: '+str(button.name)+' '+str(viewport)+' '+locale+' '+str(rect))
   check(game.menu_layer.find_child('StartRun',true,false)==null,'The landing page only launches Arcade')
 arcade.free();game.queue_free();await settle()
 print('RESULT: ',checks,' arcade roster/UI checks, ',failures,' failures');quit(1 if failures else 0)
