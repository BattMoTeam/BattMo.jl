# PyBattMo
**BattMo.jl is available from Python!**
We’ve created PyBattMo, a Python wrapper for BattMo.jl, allowing you to access all of BattMo’s functionality directly from Python. If you’re more comfortable coding in Python but want to take advantage of BattMo, you can now do so seamlessly. 

In addition to Python, Julia needs to be installed. Visit the [Julia website](https://julialang.org/install/) for more information on how to install Julia.

Easily install PyBattMo via pip:

```
pip install pybattmo
```

The APIs of BattMo.jl and PyBattMo are very similar, and even BattMo’s plotting functions are supported. The main difference lies in performance: since Python is an interpreted language, you won’t benefit from Julia’s usual performance optimizations. However, if performance becomes critical, switching from PyBattMo to BattMo.jl is straightforward.