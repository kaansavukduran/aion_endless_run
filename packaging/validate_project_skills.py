"""Validate project-local skill manifests and bundled Markdown references.

This does not claim that the cloud-installed packages were updated, nor does it
execute skill instructions or game tests.
"""
from pathlib import Path
import argparse
import json
import re

parser = argparse.ArgumentParser()
parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
parser.add_argument('--output', type=Path)
args = parser.parse_args()
rows = []
for name in ['unslop', 'fragaria-unslop']:
    directory = args.root / '.agents' / 'skills' / name
    main = directory / 'SKILL.md'
    text = main.read_text()
    assert text.startswith('---\n'), f'{main}: missing YAML frontmatter'
    front = text.split('---', 2)[1]
    assert re.search(rf'^name:\s*{re.escape(name)}\s*$', front, re.M), main
    assert re.search(r'^description:\s*>-', front, re.M), main
    assert 'require task-specific user authorization' in text or 'avoid unrequested external transfers or deployments' in text, f'{main}: execution safeguards missing'
    pages = sorted(directory.rglob('*.md'))
    count = 0
    for page in pages:
        content = page.read_text()
        for target in re.findall(r'\[[^\]]+\]\(([^)]+)\)', content):
            if re.match(r'^[a-z][a-z0-9+.-]*:', target) or target.startswith('#'):
                continue
            relative = target.split('#', 1)[0]
            destination = (page.parent / relative).resolve()
            assert destination.is_relative_to(directory.resolve()), f'{page}: reference leaves package: {target}'
            assert destination.is_file(), f'{page}: missing bundled reference: {target}'
            count += 1
        assert not re.search(r'https://(?:docs\.google\.com/document/d|drive\.google\.com/drive/folders)/', content), f'{page}: private authority URL should be resolved from active project/context'
    rows.append({'skill': name, 'manifest': str(main.relative_to(args.root)), 'markdown_files': len(pages), 'local_links_checked': count, 'passed': True})
report = {'scope': 'Project-local packages only; cloud skill writes are unavailable', 'packages': rows, 'passed': True}
if args.output:
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
