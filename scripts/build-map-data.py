"""Rebuild the cached WGS84 map. Python standard library only; no browser API keys.

Usage: python scripts/build-map-data.py --osm ../map-osm.json --proxy http://127.0.0.1:7897
The OSM extract query and point provenance are recorded in autumn/map-sources.json.
"""
import argparse, collections, json, math, pathlib, time, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--osm', required=True, help='Overpass JSON extract described in map-sources.json')
parser.add_argument('--proxy')
args = parser.parse_args()
opener = urllib.request.build_opener(urllib.request.ProxyHandler({'https': args.proxy} if args.proxy else {}))

# Place/tourism nodes, not administrative-boundary centroids or verified car parks.
points = {
    'jiangmen': ['江门',113.0761073,22.5816619,'relation/3463901'],
    'shaoguan': ['韶关',113.5922116,24.8136095,'node/244081622'],
    'taihe': ['泰和',114.9167963,26.8029102,'node/3826676480'],
    'fuliang': ['浮梁',117.2099191,29.3544265,'node/1675718429'],
    'yaoli': ['瑶里',117.5680213,29.5324688,'node/5175990732'],
    'jujing': ['菊径',117.6449342,29.4659735,'node/5151324189'],
    'qinghua': ['清华镇',117.7743350,29.4190080,'node/2689956678'],
    'hongguan': ['虹关',117.8967951,29.5213051,'node/5153142282'],
    'zhangcun': ['漳村',117.8125914,29.3616462,'node/5138928877'],
    'shendu': ['深渡',118.6092310,29.8680516,'node/9096632868'],
    'yangchan': ['阳产',118.6584636,29.8757386,'node/9096631093'],
    'chaji': ['查济',118.0283888,30.5154642,'node/2432189687'],
    'taohuatan': ['桃花潭镇',118.1494118,30.4832636,'node/4726643966'],
    'jingdezhen': ['景德镇',117.1727822,29.2712774,'node/244080868'],
    'shexian': ['歙县',118.4101129,29.8635777,'node/3728600618'],
}

def simplify(line, tolerance):
    if len(line) <= 2: return line
    first, last = line[0], line[-1]
    dx, dy = last[0]-first[0], last[1]-first[1]
    denominator = dx*dx+dy*dy
    best, index = 0, 0
    for i,p in enumerate(line[1:-1],1):
        t = max(0,min(1,((p[0]-first[0])*dx+(p[1]-first[1])*dy)/denominator)) if denominator else 0
        distance = (p[0]-first[0]-t*dx)**2+(p[1]-first[1]-t*dy)**2
        if distance > best: best,index = distance,i
    if best > tolerance*tolerance:
        return simplify(line[:index+1],tolerance)[:-1]+simplify(line[index:],tolerance)
    return [first,last]

def rounded(line): return [[round(x,5),round(y,5)] for x,y in line]

osm = json.loads(pathlib.Path(args.osm).read_text(encoding='utf8'))
groups = collections.defaultdict(list)
for item in osm['elements']:
    if not item.get('geometry'): continue
    tags = item.get('tags',{})
    kind = 'river' if tags.get('waterway')=='river' else tags.get('highway')
    if kind not in ('river','motorway','trunk','primary','secondary'): continue
    line = [(p['lon'],p['lat']) for p in item['geometry']]
    groups[kind].append(line)

# Join degree-two endpoints before simplifying; preserve branches and junctions.
roads = []
for kind, lines in groups.items():
    endpoints = collections.defaultdict(list)
    for i,line in enumerate(lines):
        endpoints[line[0]].append(i); endpoints[line[-1]].append(i)
    used = set()
    for i,line in enumerate(lines):
        if i in used: continue
        used.add(i); chain = list(line)
        for reverse in (False,True):
            if reverse: chain.reverse()
            while len(endpoints[chain[-1]])==2:
                candidates = [j for j in endpoints[chain[-1]] if j not in used]
                if not candidates: break
                j = candidates[0]; used.add(j); nxt = lines[j]
                if nxt[-1] == chain[-1]: nxt = list(reversed(nxt))
                chain.extend(nxt[1:])
        local = all(117 <= x <= 118.9 and 29.1 <= y <= 30.7 for x,y in chain)
        tolerance = .00035 if local else .003
        chain = simplify(chain,tolerance)
        span = math.hypot(chain[0][0]-chain[-1][0],chain[0][1]-chain[-1][1])
        if span < (0.002 if local else 0.015) and len(chain)<4: continue
        roads.append({'kind':kind,'coordinates':rounded(chain)})

legs = [
    ('jiangmen','shaoguan'),('shaoguan','taihe'),('taihe','fuliang'),
    ('fuliang','yaoli'),('yaoli','jujing'),('jujing','qinghua'),
    ('qinghua','hongguan'),('qinghua','zhangcun'),('qinghua','shendu'),
    ('shendu','yangchan'),('shendu','chaji'),('chaji','taohuatan'),
    ('chaji','jingdezhen'),('jingdezhen','taihe'),
]
routes = {}
for start,end in legs:
    coords = ';'.join(','.join(map(str,points[p][1:3])) for p in (start,end))
    url = 'https://router.project-osrm.org/route/v1/driving/'+coords+'?geometries=geojson&overview=full'
    request = urllib.request.Request(url,headers={'User-Agent':'CinnaTravelMap/1.0 (https://github.com/icelemon233/cinna-travel)'})
    with opener.open(request,timeout=45) as response: result = json.load(response)
    if result.get('code') != 'Ok': raise RuntimeError((start,end,result))
    route = result['routes'][0]
    coordinates = rounded(simplify(route['geometry']['coordinates'],.00015))
    routes[start+'|'+end] = {'coordinates':coordinates,'routing':'OSRM fastest reference',
        'snapDistances':[round(p['distance']) for p in result['waypoints']]}
    print(start+'|'+end,len(coordinates),flush=True)
    time.sleep(1)

data = {'fetched':'2026-10-11','coordinateSystem':'WGS84',
        'osmTimestamp':osm.get('osm3s',{}).get('timestamp_osm_base'),
        'points':{k:{'name':v[0],'coordinates':v[1:3],'osm':v[3]} for k,v in points.items()},
        'roads':roads,'routes':routes}
(ROOT/'autumn/map-data.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf8')
print('Saved map-data.json:',len(roads),'base roads',flush=True)
