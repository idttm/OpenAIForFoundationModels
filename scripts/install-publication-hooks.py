#!/usr/bin/env python3
"""Install local publication guards while preserving existing Git hooks."""
from pathlib import Path
import shlex
import subprocess


def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()


def main():
    git_dir = Path(git('rev-parse', '--absolute-git-dir'))
    managed = git_dir / 'publication-hooks'
    active = Path(git('rev-parse', '--git-path', 'hooks')).resolve()
    previous_record = managed / 'previous-hooks.txt'
    if active == managed:
        if not previous_record.is_file():
            raise SystemExit('Missing previous-hook record; refusing to replace hooks.')
        previous = Path(previous_record.read_text().strip())
    else:
        previous = active
        if managed.exists():
            raise SystemExit('Publication hook directory already exists; inspect it before reinstalling.')
        managed.mkdir()
        previous_record.write_text(str(previous) + '\n')

    # Leave original files and shared/global hook configuration untouched.
    if previous.is_dir():
        for original in previous.iterdir():
            if original.name in ('pre-commit', 'pre-push') or original.name.endswith('.sample'):
                continue
            target = managed / original.name
            if not target.exists() and not target.is_symlink():
                target.symlink_to(original)

    for name, option in [('pre-commit', '--index'), ('pre-push', '--pre-push')]:
        old = shlex.quote(str(previous / name))
        content = '#!/bin/sh\n# Managed publication guard; original hooks remain intact.\nset -eu\n'
        content += 'root=$(git rev-parse --show-toplevel)\n'
        if name == 'pre-commit':
            # Formatters may change the index: inspect the final candidate tree.
            content += f'if [ -x {old} ]; then\n  {old} "$@"\nfi\n'
        if name == 'pre-push':
            content += 'input=$(mktemp)\ntrap \'rm -f "$input"\' EXIT HUP INT TERM\ncat > "$input"\n'
        content += 'python3 "$root/scripts/check-publication.py" --repo "$root" ' + option
        content += ' < "$input"\n' if name == 'pre-push' else '\n'
        if name == 'pre-push':
            content += f'if [ -x {old} ]; then\n  {old} "$@" < "$input"\nfi\n'
        hook = managed / name
        hook.write_text(content)
        hook.chmod(0o755)
    subprocess.run(['git', 'config', '--local', 'core.hooksPath', str(managed)], check=True)
    print('Installed pre-commit and pre-push publication guards; existing hooks preserved.')


if __name__ == '__main__':
    main()
