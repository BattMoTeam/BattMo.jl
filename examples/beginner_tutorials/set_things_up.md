# Quickstart: Julia + VS Code Setup
### Install requires Software 
To run BattMo.jl we will need three pieces of software:
* **A Julia compiler**. The compiler is the software that translates our code into instructions that our PC can follow to carry out operations. Since BattMo.jl is written in Julia, we will need the Julia compiler to build models and run simulations.
* **A code editor**. Any text editor can be used to write code (e.g. Windows notepad). However, there are specialized editors tailored to write, test, and debug code. These come with lots of useful features. We prefer VS Code and we will show how to set it up. However, you can see other [editors tailored to develop code](https://en.wikipedia.org/wiki/List_of_text_editors) if you are interested.
* **Integration between Julia and the code editor**. This integration is sometimes optional but quite useful. It essentially facilitates the process of writting code, sending it to the compiler to run computations, showing the results back to you, and handling errors. The integration requires configuring the text editor to communicate with Julia. In VS Code, we will install a Julia extension.

### Setting up Julia Projects
Once the necessary software is installed, we will walk you thorugh starting a project, i.e. create a separate directory where you will write your BattMo.jl code, keep your used packages, store data, save results, etc. 

When you install Julia you usually install packages. A package is a collection of reusable code, such as functions and tools, that you can add to your project to extend its capabilities without writing everything from scratch.   

It is good practice to create a project, where all packages for a task are isolated from the packages of a different task. In essence, to start a Julia project we:
* Create a new folder, where we will store our code, data and results.
* Create a Julia project environment within the folder. The environment is represented as two files: `Project.toml` and `Manifest.toml`, which store and keeps track of the packages you have installed.
* When we start working on our code, we activate the environment, to ensure we have available the packages we need, and that new packages are installed and tracked in our folder and remain isolated from other projects.

### Starting a session
Once the project is in place, we will walk you through how to activate your environment and start coding where you left off the last time.


# 1. Install Julia
We recommend to install Julia from the official installer at the [Julia Downloads page](https://julialang.org/downloads/).

### Installation for windows
- In the table of "Current Stable Releases", click on the installer in either 64 bit or 32 bit. Most modern Windows PC use a 64 bit system so we recommend installing this version. However, if you have issues, install the 32 bit version. If you want to be sure, you can check which system you use by going to Start, search for System Information, and check for "System Type". 64 bit versions look like "x64", while 32 bit version look like "x86".
- When the download finishes, click on the file to start the installation. 
> **Important** Make sure to enable the option of "Add Julia to Path".
- When installation is complete you can close the installation window.

### Installation for MacOS
   - Download the `.dmg` from the same page, open it, and drag Julia to your Applications folder.

### Verify installation 
Open the command line (or terminal), which is a text-based interface to a lot of software in your machine.   
* On Windows, open the Command Prompt (cmd) or PowerShell.
* On macOS, open the Terminal application (found in Applications > Utilities).

Type the following command:
   ```bash
   julia --version
   ```
You should see output like `julia version 1.x.x.`. If not, you might need to add Julia to PATH, i.e. to configure your system to run Julia from any terminal without needing to specify its full installation path.

### Add Julia to PATH (optional)
**Windows:**

* First, find the location where Julia is installed. 
* In Windows, go to the start menu and search for "Environment Variables".
* Under the list of "User variables", select "Path" and click the "New" button. Then, add in the text box the path to the binary directory. It should look like "C:\Users\<user_name>\.julia\juliaup\julia-1.11.0+0.x64.w64.mingw32\bin"

**macOS/Linux:**
* Add to your shell startup (e.g. ~/.bash_profile or ~/.zshrc):
`export PATH="/Applications/Julia-1.x.app/Contents/Resources/julia/bin:$PATH"
`  

Then reopen your terminal and rerun `julia --version`.

# 2. Install VS Code
To install VS Code, follow the instructions from [the website](https://code.visualstudio.com/download) and the installer will guide you through the process.

> **Important** Make sure to enable the option of "Add VS Code to Path".

# 3. Install the Julia Extension in VS Code
The Julia extension for VS Code provides useful tools tailored to develop Julia code, e.g. highlighting of wrong syntax, and seamless integration with the Julia compiler.

### Install
* Open VS Code, open the Extensions pane (⇧⌘X on macOS, Ctrl+Shift+X on Windows).

* Search for Julia (by “Julia Language Support” team) and click Install.

### Configure
* Open Settings (⌘ on macOS, `Ctrl+,` on Windows).

* Search for `julia.enableClipboardIntegration` and ensure it’s checked.

* Ensure `julia.executablePath` points to the location of your Julia `.exe` file. To find the location:
   * Open PowerShell and run `Get-Command -ShowCommandInfo julia`
   * Copy the path that appears under "Definition". The path should look like: `"C:\Users\<your_username>\.julia\juliaup\julia-1.11.0+0.x64.w64.mingw32\bin\julia.exe"`. 
   * Paste the path into the VS Code configuration `julia.executablePath`.

**Verify configuration:** In VS Code, press `Shift + Ctrl + P` and select "Julia: Start REPL". A terminal window should appear within VS Code. Wait for some seconds until you see green `julia> `, which means the REPL is up and ready to accept commands.

# 4. Setup a project

### Create an environment
* Create a new folder
* Open VS Code on the folder. In VS Code, go to `File -> Open Folder` and navigate to your created folder.
* Open the Julia REPL from VS Code: Run the `Shift + Ctrl + P` command and select "Julia: Start REPL". 
* In the REPL, run the following commands:
```
julia> using Pkg: Pkg
julia> using Pkg.activate("./")
julia> using Pkg.instantiate()
julia> using Pkg.add("IJulia")
```
* These commands do:
   * Load the Package manager of Julia `Pkg`.
   * Activate the environment, which generates a  `Project.toml` file that will keep track of all packages installed in the environment.
   * Instantiate the environment, which installs all the packages listed in the `Project.toml`, and creates a new `Manifest.toml` that tracks dependencies to other packages.
   * Install a package called IJulia to run [interavtive Julia notebooks](https://juliapackages.com/p/IJulia) - more about notebooks when we get to the BattMo tutorials.

### Install BattMo.jl and other packages
* To install BattMo.jl in your newly created environment, ensure you are in the REPLs Package mode (`]`) and simply run `pkg> add BattMo` from the Package mode of the Julia REPL.
```
julia> ]
pkg> add BattMo
```
* Optionally you can install other Julia packages that you might need, e.g. `pkg> add DataFrames` to manipulate tabular data, or `pkg> add PlotlyJS` to make interactive plots. After you finish installing packages, press the `BackSpace` key to abandon Package mode and get back to the Julia REPL.
```
pkg> add DataFrames
pkg> add PlotlyJS
pkg> #BackSpace
julia>
```

### Verify the installation
HOW TO VERIFY THAT THE ENVIRONMENT IS SET AND THE PACKAGES INSTALLED

# 5. Start a new coding session
Once set up, you simply reopen your project and pick up where you left off.
* Open VS Code on the folder: `File -> Open Folder` and navigate to your project.
* Open the Julia REPL: press `Shift + Ctrl + P` and select "Julia: Start REPL".
* Activate and instantiate your environment, and then come back to the Julia REPL with `BackSpace`:
```
julia> ]
pkg> activate .
pkg> instantiate
pkg> #BackSpace
julia>
```
* Create your julia files, where you will write and run code. In the side bar of VS Code, ensure you are in Explorer mode, i.e. you see your files in the current folder. Hover over the Folder name and click "New File". Give it an appropiate name and add the .jl extension, e.g. `my_first_julia_code.jl`.
