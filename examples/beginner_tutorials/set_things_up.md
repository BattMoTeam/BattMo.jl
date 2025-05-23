# Quickstart: Julia + VS Code Setup
A concise guide to get you coding in Julia within VS Code.



# 1. Install Julia
BattMo.jl is written in Julia, so you need the Julia compiler to build models and run simulations. The compiler is the software that translates our code into instructions that our PC can follow to carry out operations.

### Installation  
   - **Windows**: Download the MSI installer from the [official Julia downloads page](https://julialang.org/downloads/) and run it.  
   - **macOS**: Download the `.dmg` from the same page, open it, and drag Julia to your Applications folder.

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

* Open System Properties → Advanced → Environment Variables.

* Under User variables, edit Path → New → add C:\Users\<you>\AppData\Local\Programs\Julia\bin.

**macOS/Linux:**
* Add to your shell startup (e.g. ~/.bash_profile or ~/.zshrc):
`export PATH="/Applications/Julia-1.x.app/Contents/Resources/julia/bin:$PATH"
`  

Then reopen your terminal and rerun julia --version.

# 2. Install VS Code
Visual Studio Code (VS Code) is an user-friendly text editor tailored to write, test, and debug code. It includes useful tools like syntax highlighting (i.e. highlights errors), and a mriad of useful extensions. We prefer VS Code but, in principle, any text editor can be used - see other [editors tailored to develop code](https://en.wikipedia.org/wiki/List_of_text_editors) if you are interested.

To install VS Code, follow the instructions from [the website](https://code.visualstudio.com/download) and the installer will guide you through the process.

# 3. Install the Julia Extension in VS Code
The Julia extension for VS Code provides useful tools tailored to develop Julia code, e.g. highlighting of wrong syntax, and seamless integration with the Julia compiler.
### Install
* In VS Code, open the Extensions pane (⇧⌘X on macOS, Ctrl+Shift+X on Windows).

* Search for Julia (by “Julia Language” team) and click Install.

### Configure
* Open Settings (⌘, or Ctrl+,).

* Search for julia.enableClipboardIntegration and ensure it’s checked.

* Ensure julia.executablePath points to your Julia binary (usually detected automatically).

* You can now run code blocks in a .jl file by selecting lines and pressing Alt+Enter.

MISSING: SET UP A JULIA PROJECT