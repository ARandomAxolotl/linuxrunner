"""Optional Mac host-driver footprint samples; never physical-iPhone metrics.

All emulated Linux processes are threads in this one host driver, so this is
the complete guest fixture (Firefox plus X11/helpers), not Firefox-only RSS.
Uses the installed Darwin RUSAGE_INFO_V0 ABI, without inspecting guest memory.
"""
import ctypes
import json
import pathlib
import sys
import threading
import time


class RUsageV0(ctypes.Structure):
    _fields_ = [("uuid", ctypes.c_uint8 * 16)] + [
        (name, ctypes.c_uint64) for name in (
            "user_time", "system_time", "pkg_idle_wkups", "interrupt_wkups",
            "pageins", "wired_size", "resident_size", "phys_footprint",
            "proc_start_abstime", "proc_exit_abstime")]


class RuntimeMetrics:
    def __init__(self, pid, output):
        if sys.platform != "darwin":
            raise RuntimeError("Host resource sampling requires macOS")
        self.pid = pid
        self.output = pathlib.Path(output)
        self.started = time.monotonic()
        self.samples = []
        self.errors = 0
        self.stop_event = threading.Event()
        self.lib = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
        self.lib.proc_pid_rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_void_p]
        self.lib.proc_pid_rusage.restype = ctypes.c_int
        self.thread = threading.Thread(target=self.run, daemon=True)

    def sample(self):
        usage = RUsageV0()
        if self.lib.proc_pid_rusage(self.pid, 0, ctypes.byref(usage)) != 0:
            self.errors += 1
            return
        self.samples.append({"elapsed_seconds": time.monotonic() - self.started,
                             "resident_bytes": usage.resident_size,
                             "physical_footprint_bytes": usage.phys_footprint,
                             "pageins": usage.pageins})

    def run(self):
        while not self.stop_event.is_set():
            self.sample()
            self.stop_event.wait(1)

    def start(self):
        self.thread.start()

    def stop(self):
        self.stop_event.set()
        self.thread.join(timeout=2)
        report = {"environment": "Mac host driver; not physical iPhone",
                  "scope": "entire emulated Linux fixture; Firefox and X11/helpers share this PID",
                  "interval_seconds": 1, "sample_errors": self.errors,
                  "samples": self.samples}
        if self.samples:
            for metric in ("resident_bytes", "physical_footprint_bytes"):
                report["sampled_peak_" + metric] = max(s[metric] for s in self.samples)
        self.output.write_text(json.dumps(report, indent=2) + "\n")
