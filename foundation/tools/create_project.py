#!/usr/bin/env python3
"""Create a runnable project using one of the three checked templates; refuse overwrites."""
import argparse, shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser()
ap.add_argument('destination',type=Path)
ap.add_argument('--mode',choices=['2d','isometric','3d'],default='2d')
ap.add_argument('--name',default='BigArcade Project')
a=ap.parse_args()
if a.destination.exists(): raise SystemExit('Destination already exists; choose a new directory.')
if any(ch in a.name for ch in ['"','\n','\r','\\']): raise SystemExit('Project name contains unsupported characters.')
shutil.copytree(ROOT/'projects/lab',a.destination,ignore=shutil.ignore_patterns('.godot','benchmark-output','created_scenes'))
p=a.destination/'project.godot';s=p.read_text()
s=s.replace('config/name="BigArcade · Foundation Lab"','config/name="'+a.name+'"')
s=s.replace('run/main_scene="res://scenes/lab.tscn"','run/main_scene="res://scenes/demo_'+a.mode+'.tscn"')
p.write_text(s)
print(a.destination.resolve())
