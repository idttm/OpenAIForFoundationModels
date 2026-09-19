#!/usr/bin/env python3
"""Scan publication candidates, reporting paths and categories but never values."""
import argparse
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

ROOT_FILES = {
    '.env.example', '.gitattributes', '.gitignore', '.swift-format',
    'Package.swift', 'Package.resolved', 'LICENSE', 'README.md', 'CHANGELOG.md',
    'CONTRIBUTING.md', 'CODE_OF_CONDUCT.md', 'SECURITY.md', 'SUPPORT.md', 'setup.sh',
}
PUBLIC_DIRS = {'Sources', 'Tests', 'Examples', 'Docs', '.github', '.githooks'}
PUBLIC_SCRIPTS = {
    'scripts/check-repository-hygiene.sh', 'scripts/check-publication.py',
    'scripts/install-publication-hooks.py', 'scripts/release-check.sh',
    'scripts/tests/test_publication.py',
}
PRIVATE_COMPONENTS = {
    '.git', '.agents', '.codex', '.claude', '.grok', '.muse', '.agy',
    '.cursor', '.windsurf', '.gemini', '.opencode',
    '.private', 'private', 'secrets', 'harness', 'orchestration', 'prompts',
    'verification', 'audit', 'audits', 'reviews', 'handoffs', 'logs',
    'node_modules', '.build', '.deriveddata', 'deriveddata', 'xcuserdata',
}
PRIVATE_NAMES = {
    'agents.md', 'claude.md', 'gemini.md', 'skill.md', '.mcp.json',
    'implementation_plan.md', 'devpost_submission.md', 'devpost_demo_script.md',
    'harness.md', 'os27compatibility.md', 'localsigning.xcconfig',
    'copilot-instructions.md', '.cursorrules', '.windsurfrules', '.aider.conf.yml',
    '.ds_store', '.netrc',
}
PATTERNS = {
    'OpenAI credential': rb'\bsk-(?:(?:proj|svcacct)-[A-Za-z0-9_-]{20,}|[A-Za-z0-9]{40,})',
    'GitHub credential': rb'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})',
    'AWS access key': rb'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b',
    'Slack credential': rb'\bxox[baprs]-[A-Za-z0-9-]{20,}',
    'private key': rb'-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----',
    'personal machine path': rb'(?:/(?:Users|home)/(?!runner/|runneradmin/)[A-Za-z0-9._-]+/|[A-Za-z]:\\Users\\(?!runneradmin\\)[A-Za-z0-9._-]+\\)',
    'personal signing team': rb'(?:DEVELOPMENT_TEAM\s*=\s*"?[A-Z0-9]{10}"?\s*;|DevelopmentTeam\s*=\s*"?[A-Z0-9]{10}"?\s*;)',
    'embedded credential assignment': rb'(?i)(?:api[_-]?key|access[_-]?token|client[_-]?secret|password)\s*[=:]\s*["\x27][A-Za-z0-9_+/=-]{24,}["\x27]',
    'merge conflict': rb'(?m)^(?:<<<<<<< |=======\r?$|>>>>>>> )',
}
COMPILED = {name: re.compile(pattern) for name, pattern in PATTERNS.items()}


def content_findings(data):
    return [name for name, pattern in COMPILED.items() if pattern.search(data)]


def path_findings(path):
    parts = PurePosixPath(path).parts
    lower = [part.lower() for part in parts]
    if not parts or '..' in parts or path.startswith('/'):
        return ['invalid publication path']
    name = lower[-1]
    if len(lower) > 1 and lower[0] == '.github' and lower[1] in ('agents', 'instructions', 'prompts'):
        return ['private agent configuration']
    if any(part in PRIVATE_COMPONENTS for part in lower) or name in PRIVATE_NAMES:
        return ['private development file']
    if (name.startswith('.env') and path != '.env.example') or name.endswith(
        ('.pem', '.p12', '.p8', '.key', '.pfx', '.keychain', '.keychain-db',
         '.mobileprovision', '.xcuserstate', '.log', '.xcresult', '.jsonl')
    ):
        return ['private credential or execution artifact']
    if re.search(r'(?i)(?:^|[_-])(?:audit|review|handoff|execution|agent|prompt|plan)(?:[_-]|\.)', name):
        return ['private development document']
    if path in ROOT_FILES or path in PUBLIC_SCRIPTS or parts[0] in PUBLIC_DIRS:
        return []
    return ['outside public product/contributor allowlist']


class Scanner:
    def __init__(self, repo):
        self.repo = str(repo)
        self.findings = set()
        self.blobs = {}

    def git(self, *args, input=None):
        result = subprocess.run(['git', '-C', self.repo, *args], input=input, capture_output=True)
        if result.returncode:
            raise RuntimeError('Git operation failed')  # stderr may contain private data
        return result.stdout

    def add(self, reference, path, types):
        for kind in types:
            self.findings.add((reference, path, kind))

    def check_blob(self, reference, path, mode, oid):
        self.add(reference, path, path_findings(path))
        if mode in ('160000', '120000'):
            self.add(reference, path, ['submodule or symlink requires separate review'])
            return
        if oid not in self.blobs:
            self.blobs[oid] = content_findings(self.git('cat-file', 'blob', oid))
        self.add(reference, path, self.blobs[oid])

    def index(self):
        for row in self.git('ls-files', '--stage', '-z').split(b'\0'):
            if not row:
                continue
            header, raw_path = row.split(b'\t', 1)
            mode, oid, stage = header.decode().split()
            path = os.fsdecode(raw_path)
            if stage != '0':
                self.add('index', path, ['unmerged index entry'])
            else:
                self.check_blob('index', path, mode, oid)

    def worktree(self):
        names = self.git('ls-files', '--cached', '--others', '--exclude-standard', '-z')
        for raw_path in sorted(set(names.split(b'\0')) - {b''}):
            path = os.fsdecode(raw_path)
            self.add('worktree', path, path_findings(path))
            target = Path(self.repo) / path
            if target.is_symlink() or any(parent.is_symlink() for parent in target.parents):
                self.add('worktree', path, ['symlink requires separate review'])
                continue
            try:
                self.add('worktree', path, content_findings(target.read_bytes()))
            except OSError:
                self.add('worktree', path, ['unreadable publication candidate'])

    def history(self, refs):
        if refs and self.git('rev-parse', '--is-shallow-repository').strip() == b'true':
            raise RuntimeError('Complete history is required')
        seen = set()
        for ref in refs:
            oid = self.git('rev-parse', '--verify', '--end-of-options', ref + '^{commit}').decode().strip()
            for commit in self.git('rev-list', oid).decode().splitlines():
                if commit in seen:
                    continue
                seen.add(commit)
                self.add(commit, '<commit-message>', content_findings(self.git('show', '-s', '--format=%B', commit)))
                for row in self.git('ls-tree', '-r', '-z', '--full-tree', commit).split(b'\0'):
                    if row:
                        header, raw_path = row.split(b'\t', 1)
                        mode, kind, blob = header.decode().split()
                        self.check_blob(commit, os.fsdecode(raw_path), mode, blob)
            tag = self.git('rev-parse', '--verify', '--end-of-options', ref).decode().strip()
            if self.git('cat-file', '-t', tag).strip() == b'tag':
                self.add(ref, '<tag-message>', content_findings(self.git('cat-file', 'tag', tag)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', default='.')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--index', action='store_true')
    mode.add_argument('--history', nargs='+', metavar='REF')
    mode.add_argument('--pre-push', action='store_true')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    scanner = Scanner(Path(args.repo).resolve())
    try:
        if args.index:
            scanner.index()
        elif args.history:
            scanner.history(args.history)
        elif args.pre_push:
            refs = []
            for line in sys.stdin:
                fields = line.split()
                if len(fields) != 4 or not re.fullmatch(r'[0-9a-fA-F]{40,64}', fields[1]):
                    raise RuntimeError('Invalid pre-push input')
                if set(fields[1]) != {'0'}:
                    refs.append(fields[1])
            scanner.history(refs)
        else:
            scanner.worktree()
    except (OSError, ValueError, RuntimeError):
        print('Publication check could not complete; refusing publication.', file=sys.stderr)
        return 2
    rows = [{'reference': ref, 'path': path, 'type': kind} for ref, path, kind in sorted(scanner.findings)]
    if args.json:
        print(json.dumps(rows, indent=2, ensure_ascii=True))
    else:
        for row in rows:
            print(json.dumps(row, ensure_ascii=True))
        print('Publication check failed.' if rows else 'Publication check passed.')
    return int(bool(rows))


if __name__ == '__main__':
    sys.exit(main())
