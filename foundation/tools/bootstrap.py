#!/usr/bin/env python3
"""Reconstruct the fork from the pinned upstream and the versioned overlay; never reset local edits."""
import argparse, json, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = json.loads((ROOT / 'UPSTREAM.lock.json').read_text())

def git(*args, cwd):
    return subprocess.check_output(['git', *args], cwd=cwd, text=True).strip()

def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--destination', type=Path, default=ROOT/'engine/godot'); args=ap.parse_args()
    dest = args.destination.resolve()
    if not dest.exists():
        subprocess.run(['git','clone','--depth','1','--branch',LOCK['tag'],LOCK['repository'],str(dest)],check=True)
    # An offline source delivery has the modified Godot tree but not its nested
    # Git metadata. It is already patched, so do not clone or overwrite it.
    if dest.exists() and not (dest/'.git').exists():
        version_file = dest/'version.py'
        module_file = dest/'modules/bigarcade/bigarcade_runtime.cpp'
        if version_file.exists() and module_file.exists():
            version_text = version_file.read_text()
            if 'BigArcade Studio' in version_text and 'bigarcade.0.2.0-dev' in version_text:
                print(json.dumps({'fork':str(dest),'mode':'vendored-offline-snapshot',
                                  'upstream':LOCK['commit'],'bigarcade_version':LOCK['bigarcade_version']}))
                return
        raise SystemExit('Existing destination is not a verified BigArcade snapshot or Git checkout.')
    if not (dest/'.git').exists(): raise SystemExit('Destination is not a Git checkout.')
    subprocess.run(['git','merge-base','--is-ancestor',LOCK['commit'],'HEAD'],cwd=dest,check=True)
    if git('status','--porcelain',cwd=dest): raise SystemExit('Fork has local changes. Review and commit them before refreshing overlays.')
    if git('rev-parse','--abbrev-ref','HEAD',cwd=dest) == 'HEAD':
        subprocess.run(['git','switch','-c','bigarcade/godot-foundation'],cwd=dest,check=True)
    shutil.copytree(ROOT/'modules/bigarcade',dest/'modules/bigarcade',dirs_exist_ok=True)
    version = (dest/'version.py').read_text()
    version = version.replace('short_name = "godot"','short_name = "bigarcade"').replace('name = "Godot Engine"','name = "BigArcade Studio"')
    version = version.replace('module_config = ""','module_config = "bigarcade.0.2.0-dev"')
    (dest/'version.py').write_text(version)
    branding = ROOT/'branding/splash_editor.png'
    if branding.exists(): shutil.copyfile(branding,dest/'main/splash_editor.png')
    subprocess.run(['git','add','version.py','modules/bigarcade'],cwd=dest,check=True)
    if branding.exists(): subprocess.run(['git','add','-f','main/splash_editor.png'],cwd=dest,check=True)
    if git('diff','--cached','--name-only',cwd=dest):
        subprocess.run(['git','-c','user.name=BigArcade Development','-c','user.email=development@bigarcade.local','commit','-m','feat(bigarcade): integrate Foundation runtime and Studio identity'],cwd=dest,check=True)
    print(json.dumps({'fork':str(dest),'upstream':LOCK['commit'],'commit':git('rev-parse','HEAD',cwd=dest)}))
if __name__ == '__main__': main()
