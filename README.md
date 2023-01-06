# Export Compile Commands - ECC
Module implementing support for [JSON Compilation Database Format
Specification](https://clang.llvm.org/docs/JSONCompilationDatabase.html).

This is an alternative to
[tarruda's](https://github.com/tarruda/premake-export-compile-commands) module,
which does one simple thing - generates one `compile_commands.json` file for
your project.

Tested with clangd-13.

Work is still in progress !

## Requirements
Premake 5.0.0 or later.

## How to use
First of all you need to embedded it your premake build.  To get it done follow
the [manual](https://premake.github.io/docs/Embedding-Modules/) After you simply
can call:

```
premake5 ecc
```

Moldule will generate **one** `compile_commands.json` file near your main
premake script. During generation it will use the default config (the first one
you have specified in script). If you want to select specific config just pass
it's name with command line option:

```
premake5 --config=release ecc
```

Careful! `config` option case sensitive! If there is no config passed via
command line, module will choose the default one. 

## Future plans
- Add unit tests

## Alternatives
- [export-compile-commands](https://github.com/tarruda/premake-export-compile-commands)
- [bear](https://github.com/rizsotto/Bear)
