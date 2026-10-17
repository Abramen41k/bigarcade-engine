#!/usr/bin/env python3
"""Inspect a proposed upstream update without modifying a working branch or lock."""
import argparse, json, re, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('tag',help='Reviewed stable Godot tag, e.g. 4.7.2-stable')
args=ap.parse_args()
if not re.fullmatch(r'4\.\d+(?:\.\d+)?-stable',args.tag):
    raise SystemExit('Only explicit Godot 4 stable tags are accepted.')
lock=json.loads((ROOT/'UPSTREAM.lock.json').read_text())
fork=ROOT/'engine/godot'
subprocess.run(['git','fetch','--depth=1',lock['repository'],'refs/tags/'+args.tag],cwd=fork,check=True)
candidate=subprocess.check_output(['git','rev-parse','FETCH_HEAD'],cwd=fork,text=True).strip()
diff=subprocess.check_output(['git','diff','--stat',lock['commit'],candidate],cwd=fork,text=True)
report={'current_tag':lock['tag'],'current_commit':lock['commit'],'candidate_tag':args.tag,'candidate_commit':candidate,'diff_stat':diff,'applied':False}
path=ROOT/'reports/upstream-review.json'; path.parent.mkdir(exist_ok=True)
path.write_text(json.dumps(report,indent=2))
print(json.dumps(report))
