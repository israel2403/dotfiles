"""Read only reports changed by this run; XML parsing uses the standard library."""
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

request = json.load(sys.stdin)
rows = []
for filename in request['files']:
    try:
        root = ET.parse(filename).getroot()
        for suite in ([root] if root.tag == 'testsuite' else root.findall('testsuite')):
            cases = []
            for case in suite.findall('testcase'):
                problem = next((case.find(k) for k in ('failure', 'error', 'skipped') if case.find(k) is not None), None)
                status = 'passed' if problem is None else ('skipped' if problem.tag == 'skipped' else 'failed')
                cases.append(dict(name=case.get('name', '?'), status=status, time=case.get('time', ''), detail='' if problem is None else (problem.get('message', '') + '\n' + (problem.text or '')).strip()))
            if cases:
                rows.append(dict(name=suite.get('name', Path(filename).stem), cases=cases))
    except (OSError, ET.ParseError) as error:
        rows.append(dict(name=str(error), cases=[]))
json.dump(rows, sys.stdout)
