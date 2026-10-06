# Looks up every REST call of a tracker file (method, path, body fields) in the vendor OpenAPI description. tests/tracker-apis/run.sh runs it.
import re,json,sys,yaml
kind,spec,src=sys.argv[1:4]
code=open(src).read()
if kind=='asana':
    d=yaml.safe_load(open(spec)); calls=re.findall(r'this\.req\("(\w+)", `([^`]+)`(?:, (\{[^}]*\}))?',code)
else:
    d=json.load(open(spec)); calls=re.findall(r'this\.rest\("(\w+)", `([^`]+)`(?:, (\{[^}]*\}))?',code)
calls+= [(m,p,b) for m,p,b in re.findall(r'this\.(?:req|rest)\("(\w+)", "([^"]+)"(?:, (\{[^}]*\}))?',code)]
def res(x):
    while isinstance(x,dict) and '$ref' in x: x=d['components'][x['$ref'].split('/')[-2]][x['$ref'].split('/')[-1]]
    return x
def props(s):
    s=res(s); o={}
    for a in s.get('allOf',[]): o.update(props(a))
    o.update(s.get('properties') or {}); return o
bad=0
for m,p,b in calls:
    p=p.replace('${repo}','/repos/${o}/${r}')
    tmpl=re.sub(r'\$\{[^}]+\}','{x}',p)
    rx='^'+re.escape(tmpl).replace(r'\{x\}','[^/]+')+'$'
    hit=[sp for sp in d['paths'] if re.match(rx, re.sub(r'\{[^}]+\}','X',sp).replace('X','{x}').replace('{x}','x'))] 
    hit=[sp for sp in d['paths'] if re.fullmatch(re.escape(tmpl).replace(r'\{x\}','[^/]+'), re.sub(r'\{[^}]+\}','PARAM',sp).replace('PARAM','x')) or re.fullmatch(re.sub(r'\\\{x\\\}','[^/]+',re.escape(tmpl)), re.sub(r'\{[^}]+\}','x',sp))]
    hit=[sp for sp in hit if m.lower() in d['paths'][sp]]
    if not hit: print('FAIL', m, p, '— no such path+method'); bad+=1; continue
    op=d['paths'][hit[0]][m.lower()]
    keys=re.findall(r'(?:^\{|, )\s*(\w+)(?=[:,}]|\s*\})', b) if b else []
    if keys:
        rb=res(op['requestBody'])['content']['application/json']['schema']; pr=props(rb)
        if kind=='asana': pr=props(pr['data'])
        missing=[k for k in keys if k not in pr]
        print(('FAIL' if missing else 'ok  '), m, hit[0], 'body', keys, ('unknown: '+str(missing)) if missing else '')
        bad+=bool(missing)
    else: print('ok  ', m, hit[0])
sys.exit(1 if bad else 0)
