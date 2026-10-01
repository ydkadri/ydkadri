# finder

A faster, simpler replacement for `find` and `grep`. Source: `github.com/ydkadri/finders`. Install: `cargo install finders`. Binary: `finder`.

```bash
finder -f "*.tf"                              # files by name
finder -s "reef-config"                       # files containing a string
finder -f "*.py" -r "def\s+handle_" -i        # regex inside Python files, ignoring case
finder src -f "*.rs" -l -s "unsafe"           # paths only
```

`finder --help` lists every option (`--json`, `-c` for counts). `PATH` defaults to the current directory.
