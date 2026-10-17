#!/usr/bin/env python3
"""Package committed source/history and a separately validated Linux editor."""
import argparse, hashlib, io, json, shutil, subprocess, tarfile, tempfile, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]; REPO=ROOT.parent
ap=argparse.ArgumentParser(); ap.add_argument('--output',type=Path,required=True); ap.add_argument('--binary',type=Path,required=True); args=ap.parse_args()
out=args.output.resolve(); out.mkdir(parents=True,exist_ok=True)
fork=ROOT/'engine/godot'
def git(*a,cwd=REPO): return subprocess.check_output(['git',*a],cwd=cwd,text=True).strip()
if git('status','--porcelain') or git('status','--porcelain',cwd=fork):
    raise SystemExit('Commit reviewed changes before packaging. A package must identify exact source.')
prefix='BigArcade_Engine_0.2.0-dev'
source=out/(prefix+'_Source.tar.gz'); editor=out/(prefix+'_Linux_x64.tar.gz')
manifest={'version':'0.2.0-dev','parent_commit':git('rev-parse','HEAD'),'fork_commit':git('rev-parse','HEAD',cwd=fork),'upstream':json.loads((ROOT/'UPSTREAM.lock.json').read_text()),'artifacts':[]}
def add_text(tar,name,text):
    data=text.encode(); item=tarfile.TarInfo(name); item.size=len(data); item.mode=0o755 if name.endswith('.sh') else 0o644; tar.addfile(item,io.BytesIO(data))
def add_git_archive(tar,repo,path):
    process=subprocess.Popen(['git','archive','--format=tar','--prefix='+path+'/', 'HEAD'],cwd=repo,stdout=subprocess.PIPE)
    with tarfile.open(fileobj=process.stdout,mode='r|') as stream:
        for member in stream:
            tar.addfile(member,stream.extractfile(member) if member.isfile() else None)
    if process.wait()!=0: raise RuntimeError('git archive failed')
with tempfile.TemporaryDirectory(prefix='ba-package-',dir=ROOT/'build') as temp:
    history=Path(temp)/'BigArcade-history.bundle'
    subprocess.run(['git','bundle','create',str(history),'--all'],cwd=REPO,check=True)
    subprocess.run(['git','bundle','verify',str(history)],cwd=REPO,check=True,stdout=subprocess.DEVNULL)
    with tarfile.open(source,'w:gz',compresslevel=4) as tar:
        add_git_archive(tar,REPO,prefix+'/source')
        add_git_archive(tar,fork,prefix+'/source/foundation/engine/godot')
        # A shallow Git bundle does not carry its shallow boundary. Preserve a real
        # minimal checkout database instead, including that boundary and the index.
        git_prefix=prefix+'/source/foundation/engine/godot/.git'
        for name in ['HEAD','index','shallow','packed-refs']:
            path=fork/'.git'/name
            if path.exists(): tar.add(path,arcname=git_prefix+'/'+name)
        for name in ['objects','refs']:
            tar.add(fork/'.git'/name,arcname=git_prefix+'/'+name)
        add_text(tar,git_prefix+'/config','[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n\tlogallrefupdates = true\n[remote "origin"]\n\turl = https://github.com/godotengine/godot.git\n\tfetch = +refs/heads/*:refs/remotes/origin/*\n')
        tar.add(history,arcname=prefix+'/BigArcade-history.bundle')
        patch=subprocess.check_output(['git','diff','--binary',manifest['upstream']['commit'],'HEAD'],cwd=fork).decode()
        add_text(tar,prefix+'/Godot-to-BigArcade.patch',patch)
        add_text(tar,prefix+'/PROVENANCE.json',json.dumps(manifest,indent=2))
        add_text(tar,prefix+'/RESTORE.md','# Restore\n\nThe source/ directory contains the complete committed source and the Godot fork.\nThe fork retains a shallow Git database, including its shallow boundary.\nBuild directly from source/ with foundation/tools/build.py after installing prerequisites.\n\nTo restore the parent Git history separately:\n\n```sh\ngit clone BigArcade-history.bundle restored-parent\ngit -C restored-parent switch foundation/godot-0.2.0\n```\n\nCopy source/foundation/engine/godot into restored-parent/foundation/engine/godot\nfor an offline build, or use bootstrap.py to fetch the pinned upstream online.\nDo not claim this shallow fork contains the complete Godot historical repository.\n')
    with tarfile.open(editor,'w:gz',compresslevel=4) as tar:
        tar.add(args.binary.resolve(),arcname=prefix+'/bigarcade.linuxbsd.editor.x86_64')
        for member in git('ls-files','foundation/projects/lab','foundation/README.md','foundation/DEVELOPMENT_REPORT.md','foundation/LICENSE.txt','foundation/LICENSE-GODOT.txt','foundation/COPYRIGHT-GODOT.txt','foundation/docs/KNOWN_ISSUES.md','foundation/reports').splitlines():
            path=REPO/member
            tar.add(path,arcname=prefix+'/'+str(path.relative_to(ROOT)))
        add_text(tar,prefix+'/RUN.sh','#!/bin/sh\nset -eu\ncd "$(dirname "$0")"\nexec ./bigarcade.linuxbsd.editor.x86_64 --editor --path projects/lab "$@"\n')
        add_text(tar,prefix+'/PROVENANCE.json',json.dumps(manifest,indent=2))
for path in [source,editor]:
    with path.open('rb') as f: digest=hashlib.file_digest(f,'sha256').hexdigest()
    manifest['artifacts'].append({'file':path.name,'bytes':path.stat().st_size,'sha256':digest})
(out/(prefix+'_Manifest.json')).write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2))
