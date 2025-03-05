## Installation

To install Julia, first visit the official Julia website at <https://julialang.org> and
[download](https://julialang.org/downloads/ ) the appropriate installer for your operating system (Windows, macOS, or
Linux).  After installation, you can verify it by opening a terminal or command prompt and typing julia to start the
Julia REPL (Read-Eval-Print Loop). This will confirm that Julia is correctly installed and ready for use.

BattMo is registered in the General Julia registry. To add it to your Julia environment, open Julia and run

```julia
using Pkg; Pkg.add("BattMo")
```

For those which are not used to Julia, you should be aware that julia uses JIT compilation. The first time the code is
run, you will therefore experience a compilation time which will not be present in the further runs.