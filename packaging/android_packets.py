"""Reassemble bounded passive Android records; never accept a partial JSON packet."""
import base64,json

def decode_packets(text, prefix):
    complete=[];chunks={}
    for order,line in enumerate(text.splitlines()):
        if 'AION_CHUNK ' in line:
            kind,seq,index,count,part=line.split('AION_CHUNK ',1)[1].split(' ',4)
            if kind+' '!=prefix:continue
            index,count=int(index),int(count)
            if not 0<=index<count<=1000:raise ValueError('Invalid Android chunk indices')
            key=(kind,seq,count)
            chunks.setdefault(key,{})[index]=(order,part.strip())
        elif prefix in line:
            complete.append((order,json.loads(line.split(prefix,1)[1])))
    for (_,_,count),parts in chunks.items():
        if len(parts)!=count:continue # Logcat snapshot taken while a record was being printed.
        raw=''.join(parts[i][1] for i in range(count))
        decoded=base64.b64decode(raw,validate=True).decode('utf-8')
        complete.append((max(p[0] for p in parts.values()),json.loads(decoded)))
    return [item for _,item in sorted(complete,key=lambda pair:pair[0])]
