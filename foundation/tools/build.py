#!/usr/bin/env python3
"""Compile the pinned fork with SCons, preserve full logs and the exact invocation."""
import argparse, datetime, hashlib, json, os, platform, shutil, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('--platform',choices=['linuxbsd','windows'],default='windows' if sys.platform=='win32' else 'linuxbsd')
ap.add_argument('--jobs',type=int,default=4)
ap.add_argument('--profile',choices=['development','release'],default='development')
ap.add_argument('--scons-target',default='')
args=ap.parse_args()
env=os.environ.copy()
local=ROOT/'.tools'
if (local/'scons').exists(): env['PYTHONPATH']=str(local/'scons')+os.pathsep+env.get('PYTHONPATH','')
if (local/'sysroot/usr/bin').exists():
    env['PATH']=str(local/'sysroot/usr/bin')+os.pathsep+env['PATH']
    env['LD_LIBRARY_PATH']=str(local/'sysroot/usr/lib/x86_64-linux-gnu')+os.pathsep+env.get('LD_LIBRARY_PATH','')
cmd=[sys.executable,'-m','SCons',f'platform={args.platform}','target=editor','arch=x86_64','tests=yes','debug_symbols=no','lto=none','no_editor_splash=no',f'-j{args.jobs}','progress=no','optimize=none' if args.profile=='development' else 'optimize=speed']
if args.platform=='linuxbsd': cmd+=['wayland=no']
if args.scons_target: cmd.append(args.scons_target)
reports=ROOT/'reports'; reports.mkdir(exist_ok=True)
name=f'build-{args.platform}-{args.profile}'
started=time.time()
for suffix in ['.log', '.json']:
    previous=reports/(name+suffix)
    if previous.exists():
        stamp=datetime.datetime.fromtimestamp(previous.stat().st_mtime,datetime.timezone.utc).strftime('%Y%m%dT%H%M%S')
        previous.rename(reports/(name+'-'+stamp+suffix))
with (reports/(name+'.log')).open('w') as out:
    result=subprocess.run(cmd,cwd=ROOT/'engine/godot',env=env,stdout=out,stderr=subprocess.STDOUT)
report={'command':cmd,'platform':platform.platform(),'python':sys.version,'started_at':datetime.datetime.fromtimestamp(started,datetime.timezone.utc).isoformat(),'duration_seconds':time.time()-started,'exit_code':result.returncode}
try:
    report['fork_commit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT/'engine/godot',text=True,stderr=subprocess.DEVNULL).strip()
except (subprocess.CalledProcessError, FileNotFoundError):
    report['fork_commit']='6c3ff96d4fb87c80765fb989154c114be92b2bbd (snapshot, Git metadata not included)'
report['artifacts']=[]
if result.returncode==0:
    for original in (ROOT/'engine/godot/bin').glob(f'godot.{args.platform}.editor.x86_64*'):
        if original.is_file() and (args.platform!='windows' or original.suffix=='.exe'):
            branded=original.with_name(original.name.replace('godot.','bigarcade.',1))
            shutil.copy2(original,branded)
            report['artifacts'].append({'path':str(branded.relative_to(ROOT)), 'bytes':branded.stat().st_size,'sha256':hashlib.file_digest(branded.open('rb'),'sha256').hexdigest()})
(reports/(name+'.json')).write_text(json.dumps(report,indent=2))
print(json.dumps(report)); sys.exit(result.returncode)
