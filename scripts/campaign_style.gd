class_name CampaignStyle
extends RefCounted

## Bonuses extend existing score ownership: a defeated ID can pay only once.
## Pause/story/menu time never reaches this step, and base score is not lost.
static func step(w,dt: float) -> void:
	w.chain_time=maxf(0.,w.chain_time-dt)
	if w.chain_time<=0.:w.chain=0
	for popup in w.score_popups:popup.age=float(popup.age)+dt
	w.score_popups=w.score_popups.filter(func(p):return float(p.age)<1.)

static func defeat(w,e: Dictionary,base: int,style: String) -> void:
	var id: String=str(e.id)
	if w.awarded.has(id):return
	w.kills+=1;w.award(id,base)
	w.chain=w.chain+1 if w.chain_time>0. else 1;w.chain_time=4.;w.best_chain=maxi(w.best_chain,w.chain)
	var bonus: int=mini(4,maxi(0,w.chain-1))*25+(25 if style in ["melee","stomp"] else 0)
	if bonus>0:
		w.award(id+":style",bonus)
		w.score_popups.append({"p":Vector2(float(e.x),float(e.y)-75.),"age":0.,"bonus":bonus,"chain":w.chain})
		while w.score_popups.size()>5:w.score_popups.pop_front()
