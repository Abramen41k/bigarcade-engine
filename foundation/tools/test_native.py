#!/usr/bin/env python3
import json, os, platform, subprocess, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
(ROOT/'build').mkdir(exist_ok=True)
results=[]
for standard in ['c++17','c++20']:
    binary=ROOT/'build'/('core-test-'+standard)
    cmd=[os.environ.get('CXX','g++'),'-std='+standard,'-O2','-Wall','-Wextra','-Werror',str(ROOT/'tests/core_test.cpp'),'-o',str(binary)]
    subprocess.run(cmd,check=True)
    result=json.loads(subprocess.check_output([str(binary)],text=True))
    result['command']=cmd; results.append(result)
report={'scope':'Standalone C++ logic, not rendered FPS','platform':platform.platform(),'results':results}
(ROOT/'reports/native-tests.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
