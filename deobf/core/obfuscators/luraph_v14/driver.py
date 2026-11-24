def lift(job, runner, patched, cfg, chunks, run_text, ppath, dpath, chunk_paths):
    from obfuscators.luraph_v15 import driver
    from obfuscators.luraph_v14 import devirt
    driver.lift(job, runner, patched, cfg, chunks, run_text, ppath, dpath, chunk_paths, devirt)
