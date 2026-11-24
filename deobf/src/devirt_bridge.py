import json
import os
import sys

here = os.path.dirname(os.path.abspath(__file__))
core_dir = os.path.join(here, "..", "core")
if core_dir not in sys.path:
    sys.path.insert(0, core_dir)

cmd = sys.argv[1]

if cmd == "pipeline":
    config_file = sys.argv[2]
    with open(config_file, "r", encoding="utf-8") as f:
        c = json.load(f)

    from obfuscators.base import Job
    import harness

    if c.get("plugin") == "luraph_v14":
        from obfuscators.luraph_v14 import driver
    else:
        from obfuscators.luraph_v15 import driver

    class DummyArgs:
        defaults = {
            "cfg": [],
            "keep_harness": False, "no_hooks": False, "no_devirt": False,
            "max_runs": 1, "raw": None, "input_text": None, "port": None,
        }

        def __init__(self, d):
            for k, v in d.items():
                setattr(self, k, v)

        def __getattr__(self, k):
            return DummyArgs.defaults.get(k, False)

    args = DummyArgs(c["args"])
    job = Job(c["input"], c["source"], args, c["trace_path"], c["debug"], c["obfuscator"])
    job.source_path = c["source_path"]
    job.credit_header = lambda: ""

    runner = harness.Runner(job)
    runner.luau = c["luau_exe"]

    profiler = None
    prof_path = os.environ.get("DEOB_PROFILE")
    if prof_path:
        import cProfile
        profiler = cProfile.Profile()

    if profiler:
        profiler.enable()
    driver.lift(
        job,
        runner,
        c["patched"],
        c["cfg"],
        c.get("chunks", {}),
        c["run_text"],
        c["ppath"],
        c["dpath"],
        c.get("chunk_paths", []),
    )
    if profiler:
        profiler.disable()
        profiler.dump_stats(prof_path)
        sys.stderr.write("[*] cProfile stats written to %s\n" % prof_path)
    runner.finish()

    dpath = c["dpath"]
    if os.path.exists(dpath):
        with open(dpath, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
        clean = []
        skip_header = True
        for line in lines:
            stripped = line.strip()
            if skip_header and (
                stripped.startswith("-- Deobfuscated by") or
                stripped.startswith("-- Detected obfuscation") or
                stripped.startswith("-- Local names are inferred") or
                stripped.startswith("-- source:") or
                stripped.startswith("-- NOTE: reconstructed") or
                stripped.startswith("--       during the trace")
            ):
                continue
            if skip_header and stripped == "":
                continue
            skip_header = False
            clean.append(line)
        with open(dpath, "w", encoding="utf-8", newline="\n") as f:
            f.writelines(clean)

    print(json.dumps({"success": True, "output": c["dpath"]}))

else:
    sys.exit(f"Unknown command: {cmd} (expected: pipeline)")
