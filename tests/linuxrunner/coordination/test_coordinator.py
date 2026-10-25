"""Coordinator component tests. The fake CLI below is NOT GPU/Claude evidence."""
import importlib.util
import json
import os
import signal
import time
import pathlib
import subprocess
import sys
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[3]
SCRIPT = ROOT / 'scripts/agent-coordinator.py'
spec = importlib.util.spec_from_file_location('coordinator', SCRIPT)
coordinator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(coordinator)


class CoordinatorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = pathlib.Path(self.temp.name)
        self.path = self.root / 'queue.sqlite3'
        self.db = coordinator.connect(self.path)

    def tearDown(self):
        self.db.close()
        self.temp.cleanup()

    def cli(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), '--db', str(self.path), *args], capture_output=True, text=True, timeout=10)

    def task(self, text='Implement actual rendering'):
        f = self.root / 'task.md';f.write_text(text)
        r = self.cli('enqueue', '--title', 'test', '--file', str(f))
        self.assertEqual(r.returncode, 0, r.stderr)
        return json.loads(r.stdout)['task']

    def test_mailbox_delivery_and_recovery(self):
        coordinator.send(self.db, 'claude', 'codex', 'question', 'Which files?')
        self.assertEqual(coordinator.messages(self.db, 'codex')[0]['body'], 'Which files?')
        self.assertEqual(len(coordinator.messages(self.db, 'codex', True)), 1)
        self.assertEqual(coordinator.messages(self.db, 'codex'), [])
        coordinator.send(self.db, 'codex', 'claude', 'answer', 'GPU files only')
        self.assertEqual(json.loads(self.cli('wait', '--recipient', 'claude', '--consume', '--timeout', '0').stdout)[0]['body'], 'GPU files only')
        self.assertEqual(coordinator.messages(self.db, 'claude'), [])

    def test_cli_inbox_consumes_once_unless_peeking(self):
        coordinator.send(self.db, 'codex', 'claude', 'answer', 'Read this once')
        peek = json.loads(self.cli('inbox', '--recipient', 'claude', '--peek').stdout)
        self.assertEqual(len(peek), 1)
        self.assertEqual(len(coordinator.messages(self.db, 'claude')), 1)
        delivered = json.loads(self.cli('inbox', '--recipient', 'claude').stdout)
        self.assertEqual(delivered[0]['body'], 'Read this once')
        self.assertEqual(json.loads(self.cli('inbox', '--recipient', 'claude').stdout), [])

    def test_claim_is_exclusive_and_pause_is_respected(self):
        self.task()
        self.cli('pause')
        self.assertIsNone(coordinator.claim(self.db))
        self.cli('resume')
        self.assertIsNotNone(coordinator.claim(self.db))
        self.assertIsNone(coordinator.claim(self.db))
        self.cli('recover', '--task', '1')
        self.assertIsNotNone(coordinator.claim(self.db))
        self.assertNotEqual(self.cli('recover', '--task', '1').returncode, 0)

    def test_real_worker_supplies_messages_to_cli_and_records_result(self):
        # Exercises subprocess delivery, not a real external API/model call.
        self.task('TASK_SENTINEL')
        coordinator.send(self.db, 'codex', 'claude', 'answer', 'ANSWER_SENTINEL')
        work = self.root / 'work';work.mkdir();(work / '.git').touch()
        fake = self.root / 'fake-claude'
        fake.write_text('#!/usr/bin/env python3\nimport sys,json\nassert "TASK_SENTINEL" in sys.argv[-1]\nassert "ANSWER_SENTINEL" in sys.argv[-1]\nassert sys.argv[sys.argv.index("--effort")+1]=="medium"\nassert sys.argv[sys.argv.index("--resume")+1]=="00000000-0000-0000-0000-000000000001"\nassert "--fork-session" in sys.argv\nprint(json.dumps({"type":"result","is_error":False,"result":"component fake successful"}))\n')
        fake.chmod(0o700)
        r = self.cli('work', '--worktree', str(work), '--claude', str(fake), '--logdir', str(self.root / 'logs'), '--max-seconds', '5', '--effort', 'medium', '--resume-session', '00000000-0000-0000-0000-000000000001')
        self.assertEqual(r.returncode, 0, r.stderr)
        task = self.db.execute('SELECT * FROM tasks').fetchone()
        self.assertEqual(task['status'], 'done')
        self.assertIsNone(task['pid'])
        self.assertEqual(coordinator.messages(self.db, 'claude'), [])
        report = coordinator.messages(self.db, 'codex')[0]
        self.assertEqual(report['kind'], 'completion')
        self.assertEqual(json.loads(report['body'])['status'], 'done')

    def test_missing_success_result_is_failure_not_completion(self):
        self.task()
        work = self.root / 'work';work.mkdir();(work / '.git').touch()
        fake = self.root / 'fake-claude';fake.write_text('#!/bin/sh\nexit 0\n');fake.chmod(0o700)
        r = self.cli('work', '--worktree', str(work), '--claude', str(fake), '--logdir', str(self.root / 'logs'), '--max-seconds', '5')
        self.assertEqual(r.returncode, 1)
        self.assertEqual(self.db.execute('SELECT status FROM tasks').fetchone()[0], 'failed')
        self.assertEqual(coordinator.messages(self.db, 'codex')[0]['kind'], 'blocker')

    def test_neutral_launch_keeps_explicit_worktree_and_absolute_mailbox(self):
        self.task()
        work = self.root / 'work';work.mkdir();(work / '.git').touch()
        launch = self.root / 'launch';launch.mkdir()
        fake = self.root / 'fake-claude'
        fake.write_text('#!/usr/bin/env python3\nimport sys,os,json\n'
            f'assert os.getcwd()=={str(launch.resolve())!r}\n'
            f'assert {str(work.resolve())!r} in sys.argv\n'
            f'assert "--db {self.path.resolve()}" in sys.argv[-1]\n'
            'assert "--strict-mcp-config" in sys.argv\n'
            'print(json.dumps({"type":"result","is_error":False,"result":"component fake"}))\n')
        fake.chmod(0o700)
        r=self.cli('work','--worktree',str(work),'--launch-directory',str(launch),
            '--claude',str(fake),'--logdir',str(self.root/'logs'),'--max-seconds','5')
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertEqual(self.db.execute('SELECT status FROM tasks').fetchone()[0],'done')

    def test_worker_signal_stops_owned_cli_and_preserves_task(self):
        self.task()
        work = self.root / 'work';work.mkdir();(work / '.git').touch()
        fake = self.root / 'fake-claude'
        fake.write_text('#!/usr/bin/env python3\nimport time\ntime.sleep(30)\n')
        fake.chmod(0o700)
        worker = subprocess.Popen([sys.executable, str(SCRIPT), '--db', str(self.path),
            'work', '--worktree', str(work), '--claude', str(fake),
            '--logdir', str(self.root / 'logs'), '--max-seconds', '20'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        cli_pid = None
        try:
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                row = self.db.execute('SELECT pid FROM tasks').fetchone()
                if row and row['pid']:
                    cli_pid = row['pid'];break
                time.sleep(.05)
            self.assertIsNotNone(cli_pid)
            worker.send_signal(signal.SIGTERM)
            output, error = worker.communicate(timeout=5)
            self.assertEqual(worker.returncode, 1, error)
            row = self.db.execute('SELECT * FROM tasks').fetchone()
            self.assertEqual(row['status'], 'stopped')
            self.assertIsNone(row['pid'])
            self.assertEqual(row['attempts'], 1)
            with self.assertRaises(ProcessLookupError):os.kill(cli_pid, 0)
            self.assertEqual(coordinator.messages(self.db, 'codex')[0]['kind'], 'blocker')
        finally:
            if worker.poll() is None:worker.kill();worker.communicate()
            if cli_pid:
                try:os.killpg(cli_pid, signal.SIGTERM)
                except ProcessLookupError:pass

    def test_message_size_is_bounded(self):
        with self.assertRaises(ValueError):
            coordinator.send(self.db, 'codex', 'claude', 'task', 'x' * 20001)


if __name__ == '__main__':
    unittest.main()
