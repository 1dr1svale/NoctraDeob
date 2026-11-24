import os
import re
import sys

class Obfuscator:
    name = ""
    label = ""
    doc = ""

    def detect(self, source):
        return 0.0

    def add_arguments(self, parser):
        pass

    def deobfuscate(self, job):
        raise NotImplementedError

class Job:
    def __init__(self, input_path, source, args, trace_path, debug, obfuscator=""):
        self.input = input_path
        self.source = source
        self.source_path = input_path
        self.args = args
        self.trace_path = trace_path
        self.debug = debug
        self.obfuscator = obfuscator

    def credit_header(self):
        return ""

    @property
    def base(self):
        return re.sub(r"\.deobf\.luau$|\.luau$", "", self.trace_path)

    def path(self, suffix):
        return self.base + suffix

    def wrote(self, path):
        if self.debug:
            print("[+] wrote " + path, file=sys.stderr)

    def write(self, path, text, encoding="utf-8"):
        with open(path, "w", encoding=encoding, newline="\n" if encoding == "utf-8" else "") as f:
            f.write(text)
        self.wrote(path)
        return path

    @property
    def outdir(self):
        return os.path.dirname(os.path.abspath(self.trace_path))
