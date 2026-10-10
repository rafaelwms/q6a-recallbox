import re, os, subprocess, urllib.parse, sys
os.chdir(os.path.expanduser('~/q6a-recallbox/recalbox'))
log = open(os.path.expanduser('~/q6a-recallbox/source.log'), errors='ignore').read()
urls = set(re.findall(r"https://gitlab\.com/([^\s']+?)/-/archive/([0-9a-f]{7,40})/([^\s']+?\.tar\.gz)", log))
dls = os.listdir('dl')
ok = bad = 0
for proj, sha, fname in sorted(urls):
    cands = [d for d in dls if fname.startswith(d + '-')]
    if not cands: print('NO PKG DIR', fname); bad += 1; continue
    d = max(cands, key=len)
    dest = f'dl/{d}/{fname}'
    if os.path.exists(dest) and os.path.getsize(dest) > 1000: continue
    api = 'https://gitlab.com/api/v4/projects/%s/repository/archive.tar.gz?sha=%s' % (urllib.parse.quote(proj, safe=''), sha)
    r = subprocess.run(['curl', '-sfL', '--retry', '3', '-o', dest + '.part', api])
    if r.returncode == 0:
        os.rename(dest + '.part', dest); ok += 1; print('OK', dest)
    else:
        bad += 1; print('FAIL', proj, sha, r.returncode)
print('fetched', ok, 'failed', bad, 'total urls', len(urls))
