"""Rebuild only additional campaign CJK glyphs from the pinned OFL upstream.
Requires fonttools; not run during normal builds or by the game.
"""
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
import json,hashlib,urllib.request
root=Path(__file__).resolve().parents[1];folder=root/'assets/fonts';existing=set()
for path in [folder/'NotoSans-Game.ttf',folder/'NotoSansCJK-Game.otf',root/'assets/PixelifySans.ttf']:
 f=TTFont(path)
 for cmap in f['cmap'].tables:existing.update(cmap.cmap)
copy=json.loads((root/'assets/locales/campaign.json').read_text());need=set(map(ord,''.join(''.join(t.values()) for t in copy.values())+(root/'scripts/campaign_text.gd').read_text()));missing=sorted(c for c in need-existing if c>=32)
commit='f8d157532fbfaeda587e826d4cd5b21a49186f7c';url=f'https://raw.githubusercontent.com/notofonts/noto-cjk/{commit}/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Regular.otf';source=root/'work/font-cache/NotoSansCJKsc-Regular.otf';source.parent.mkdir(parents=True,exist_ok=True);source.write_bytes(urllib.request.urlopen(url,timeout=60).read());font=TTFont(source);options=subset.Options();options.name_IDs=['*'];options.name_legacy=True;tool=subset.Subsetter(options=options);tool.populate(unicodes=missing+[32]);tool.subset(font)
for entry in font['name'].names:
 if entry.nameID in [1,4,6]:entry.string=('AionCampaignCJK' if entry.nameID==6 else 'Campaign CJK Fallback').encode(entry.getEncoding())
target=folder/'Campaign-CJK.otf';font.save(target)
report={'source_url':url,'source_commit':commit,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'subset_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'glyphs_added':len(missing),'unicode_codepoints':missing,'license':'SIL Open Font License1.1; OFL-NotoSansCJK.txt retained','purpose':'Only additional characters required by the new campaign. Existing font subsets remain byte-identical.'};(folder/'CAMPAIGN-FONT-PROVENANCE.json').write_text(json.dumps(report,indent=2)+'\n');print('Added',len(missing),'glyphs in',target.stat().st_size,'bytes')
