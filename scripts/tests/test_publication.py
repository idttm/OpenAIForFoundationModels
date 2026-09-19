#!/usr/bin/env python3
"""Publication guard regression tests; all Git mutations use disposable repos."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.git('init', '-q')
        self.git('config', 'user.name', 'Fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        (self.root / 'scripts').mkdir()
        for name in ('check-publication.py', 'install-publication-hooks.py'):
            shutil.copy2(SCRIPTS / name, self.root / 'scripts' / name)
        self.write('README.md', 'Public product documentation.\n')
        self.write('.gitignore', '.private/\nAGENTS.md\n.env\n')
        self.git('add', '.')
        self.commit()
        self.secret = 'sk-' + 'proj-' + 'A' * 48

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.root), *args], stderr=subprocess.DEVNULL).decode().strip()

    def commit(self):
        self.git('-c', 'core.hooksPath=/dev/null', 'commit', '-qm', 'Synthetic fixture')

    def write(self, name, value):
        target = self.root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(value)
        return target

    def scan(self, *args, input=None):
        result = subprocess.run(['python3', str(self.root / 'scripts/check-publication.py'), *args],
                                cwd=self.root, input=input, text=True, capture_output=True)
        self.assertNotIn(self.secret, result.stdout + result.stderr)
        return result

    def test_clean_product_and_ignored_private_files(self):
        self.write('.private/local.md', self.secret)
        self.assertEqual(self.scan().returncode, 0)
        self.assertEqual(self.scan('--index').returncode, 0)
        self.assertEqual(self.scan('--history', 'HEAD').returncode, 0)

    def test_forced_private_file_in_index(self):
        self.write('AGENTS.md', 'Private development instructions')
        self.git('add', '-f', 'AGENTS.md')
        self.assertNotEqual(self.scan('--index').returncode, 0)

    def test_index_bytes_are_checked_independently(self):
        self.write('README.md', self.secret)
        self.git('add', 'README.md')
        self.write('README.md', 'Clean working copy')
        self.assertEqual(self.scan().returncode, 0)
        self.assertNotEqual(self.scan('--index').returncode, 0)

    def test_unstaged_secret_is_rejected(self):
        self.write('README.md', self.secret)
        self.assertEqual(self.scan('--index').returncode, 0)
        self.assertNotEqual(self.scan().returncode, 0)

    def test_history_rejects_removed_credential(self):
        self.write('Sources/Fixture.swift', self.secret)
        self.git('add', '.')
        self.commit()
        self.git('rm', '-q', 'Sources/Fixture.swift')
        self.commit()
        self.assertEqual(self.scan('--index').returncode, 0)
        self.assertNotEqual(self.scan('--history', 'HEAD').returncode, 0)
        sha = self.git('rev-parse', 'HEAD')
        self.assertNotEqual(self.scan('--pre-push', input=f'refs/heads/main {sha} refs/heads/main {"0" * 40}\n').returncode, 0)

    def test_annotated_tag_message_is_checked(self):
        self.git('tag', '-a', 'v-fixture', '-m', self.secret)
        self.assertNotEqual(self.scan('--history', 'v-fixture').returncode, 0)

    def test_personal_paths_and_unquoted_signing_team(self):
        for value in ['/' + 'Users/' + 'private-user/project/', 'DEVELOPMENT_TEAM = ' + 'A1B2C3D4E5;']:
            self.write('README.md', value)
            self.assertNotEqual(self.scan().returncode, 0)

    def test_symlink_and_missing_ref_fail_closed(self):
        (self.root / 'Docs').mkdir()
        (self.root / 'Docs/link.md').symlink_to(self.root / 'README.md')
        self.assertNotEqual(self.scan().returncode, 0)
        self.assertEqual(self.scan('--history', 'missing-ref').returncode, 2)

    def test_credential_families_and_private_artifacts(self):
        fixtures = [
            self.secret, 'gh' + 'p_' + 'B' * 36,
            'github_' + 'pat_' + 'C' * 50, 'AK' + 'IA' + 'D' * 16,
            'xox' + 'b-' + 'E' * 30,
            '-----BEGIN ' + 'PRIVATE KEY-----',
            'api_key = "' + 'F' * 30 + '"',
        ]
        for value in fixtures:
            with self.subTest(kind=fixtures.index(value)):
                self.write('README.md', value)
                result = self.scan()
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn(value, result.stdout + result.stderr)
        self.write('README.md', 'Public documentation')
        for name in ['Docs/review-notes.md', '.codex/config.toml',
                     'scripts/harness.py', 'Examples/session.log', '.env.local',
                     '.github/copilot-instructions.md', '.github/agents/helper.md']:
            with self.subTest(path=name):
                target = self.write(name, 'Private fixture')
                self.assertNotEqual(self.scan().returncode, 0)
                target.unlink()

    def test_shallow_history_fails_closed(self):
        (self.root / '.git/shallow').write_text(self.git('rev-parse', 'HEAD') + '\n')
        self.assertEqual(self.scan('--history', 'HEAD').returncode, 2)

    def test_hook_preservation_and_push_stdin(self):
        previous = self.root / '.git' / 'existing-hooks'
        previous.mkdir()
        hook = previous / 'pre-commit'
        hook.write_text('#!/bin/sh\necho preserved > .git/commit-hook-ran\n')
        hook.chmod(0o755)
        push = previous / 'pre-push'
        push.write_text('#!/bin/sh\ncat > .git/push-input\n')
        push.chmod(0o755)
        self.git('config', 'core.hooksPath', str(previous))
        for _ in range(2):
            subprocess.run(['python3', 'scripts/install-publication-hooks.py'], cwd=self.root,
                           check=True, capture_output=True)
        managed = Path(self.git('config', 'core.hooksPath'))
        result = subprocess.run([str(managed / 'pre-commit')], cwd=self.root, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertTrue((self.root / '.git/commit-hook-ran').exists())
        self.assertTrue(hook.exists())
        sha = self.git('rev-parse', 'HEAD')
        line = f'refs/heads/main {sha} refs/heads/main {"0" * 40}\n'
        result = subprocess.run([str(managed / 'pre-push'), 'origin', 'fixture'], cwd=self.root,
                                input=line, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertEqual((self.root / '.git/push-input').read_text(), line)
        self.write('README.md', self.secret)
        self.git('add', 'README.md')
        result = subprocess.run([str(managed / 'pre-commit')], cwd=self.root, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(self.secret.encode(), result.stdout + result.stderr)
        self.write('README.md', 'Public documentation')
        self.git('add', 'README.md')
        self.write('.git/private-fixture', self.secret)
        hook.write_text('#!/bin/sh\ncp .git/private-fixture README.md\ngit add README.md\n')
        result = subprocess.run([str(managed / 'pre-commit')], cwd=self.root, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(self.secret.encode(), result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
