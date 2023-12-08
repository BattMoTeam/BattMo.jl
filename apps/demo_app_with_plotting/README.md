Compiled demo app
-----------------
To build:
Run julia in this folder:
```bash
cd BattMo.jl/apps/demo_app_with_plotting
julia --project=.
```
Add the demo app using `dev`:
```julia
]dev ./BattMoDemoApp
```
You can hit backspace to leave package mode and compile the executable:
```julia
include("create_executable.jl")
```
If a window appears during compilation you will have to close it for the compilation to continue once a plot has appeared. This will take some time, especially the first time you run it. It will create a folder named `battmo_compiled`. You can then run the following command in your terminal to simulate a test case:
```bash
./battmo_compiled/bin/BattMoDemoApp ./data/p2d_40_jl.json
```
You will then get output and a plot. The program terminates once the plot is closed. If you are using Windows the executable will be named `BattMoDemoApp.exe` and you will have to change the paths to use `\` instead of `/`.
