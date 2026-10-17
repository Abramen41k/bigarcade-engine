#!/usr/bin/env python3
"""Run the actual editor, native Godot tests, import, scene integration and benchmarks."""
import argparse, datetime, json, os, platform, re, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('--binary',type=Path,required=True)
ap.add_argument('--display',choices=['headless','desktop'],default='headless')
ap.add_argument('--duration',type=int,default=8)
args=ap.parse_args()
binary=args.binary.resolve(); project=ROOT/'projects/lab'; reports=ROOT/'reports'; reports.mkdir(exist_ok=True)
mode=['--headless'] if args.display=='headless' else []
results=[]
def run(name,tail,timeout=120,required_text=None):
    cmd=[str(binary),*mode,*tail]; started=time.monotonic()
    try:
        process=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',timeout=timeout)
        code=process.returncode; output=process.stdout
    except subprocess.TimeoutExpired as exc:
        code=124; output=(exc.stdout or b'').decode(errors='replace') if isinstance(exc.stdout,bytes) else (exc.stdout or '')
        output+='\nTIMEOUT\n'
    (reports/(name+'.log')).write_text(output)
    plain=re.sub(r'\x1b\[[0-9;]*m','',output)
    errors=re.findall(r'^(?:SCRIPT ERROR:|ERROR:|Parse Error:).*',plain,re.MULTILINE)
    if required_text and required_text not in output:
        errors.append('Expected evidence absent: '+required_text)
    result={'name':name,'command':cmd,'exit_code':code,'errors':errors,'duration_seconds':time.monotonic()-started}
    results.append(result); print(json.dumps(result),flush=True)
    return code==0 and not errors
success=run('engine-tests',['--test','--test-case=*BigArcade*'])
success=run('editor-import',['--editor','--path',str(project),'--import']) and success
if success:
    success=run('editor-startup',['--editor','--path',str(project),'--quit-after','120'],required_text='BIGARCADE_STUDIO_READY: native=true, templates=3') and success
if success:
    success=run('scene-integration',['--path',str(project),'--script','tests/integration.gd']) and success
if success:
    for scene in ['2d','isometric','3d']:
        for fps in [60,120]:
            output=reports/f'benchmark-{args.display}-{scene}-{fps}.json'
            success=run(f'benchmark-{args.display}-{scene}-{fps}',['--path',str(project),'--','--benchmark',f'--scene={scene}',f'--duration={args.duration}',f'--fps={fps}',f'--output={output}'],args.duration+60) and success
report={'date_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'host':platform.platform(),'display':args.display,'rendering_verified':args.display=='desktop' and success,'success':success,'checks':results}
(reports/('verification-'+args.display+'.json')).write_text(json.dumps(report,indent=2))
sys.exit(0 if success else 1)
