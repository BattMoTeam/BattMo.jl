import{_ as a,c as n,o as i,aA as p}from"./chunks/framework.BFbzQv2c.js";const e="/BattMo.jl/previews/PR26/assets/payhlkt.CDk-EQ3g.jpeg",l="/BattMo.jl/previews/PR26/assets/pnbicel.Br2u4DWB.jpeg",g=JSON.parse('{"title":"Initial simulation","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_optimization.md","filePath":"examples/example_optimization.md","lastUpdated":null}'),t={name:"examples/example_optimization.md"};function h(k,s,r,E,u,o){return i(),n("div",null,s[0]||(s[0]=[p(`<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><h1 id="Initial-simulation" tabindex="-1">Initial simulation <a class="header-anchor" href="#Initial-simulation" aria-label="Permalink to &quot;Initial simulation {#Initial-simulation}&quot;">​</a></h1><p>Run a simulation witht the initial parameter values</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Chen2020_calibrated&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> name)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;CCDischarge&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters, cycling_protocol)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output_0 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output_0[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>╭────────────────┬──────────┬──────────────┬──────────╮</span></span>
<span class="line"><span>│ Iteration type │ Avg/step │ Avg/ministep │    Total │</span></span>
<span class="line"><span>│                │ 84 steps │ 84 ministeps │ (wasted) │</span></span>
<span class="line"><span>├────────────────┼──────────┼──────────────┼──────────┤</span></span>
<span class="line"><span>│ Newton         │  3.07143 │      3.07143 │  258 (0) │</span></span>
<span class="line"><span>│ Linearization  │  4.07143 │      4.07143 │  342 (0) │</span></span>
<span class="line"><span>│ Linear solver  │  3.07143 │      3.07143 │  258 (0) │</span></span>
<span class="line"><span>│ Precond apply  │      0.0 │          0.0 │    0 (0) │</span></span>
<span class="line"><span>╰────────────────┴──────────┴──────────────┴──────────╯</span></span>
<span class="line"><span>╭───────────────┬────────┬────────────┬────────╮</span></span>
<span class="line"><span>│ Timing type   │   Each │   Relative │  Total │</span></span>
<span class="line"><span>│               │     ms │ Percentage │      s │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Properties    │ 0.0340 │     0.47 % │ 0.0088 │</span></span>
<span class="line"><span>│ Equations     │ 1.2845 │    23.78 % │ 0.4393 │</span></span>
<span class="line"><span>│ Assembly      │ 0.5490 │    10.17 % │ 0.1878 │</span></span>
<span class="line"><span>│ Linear solve  │ 0.3905 │     5.46 % │ 0.1008 │</span></span>
<span class="line"><span>│ Linear setup  │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Precond apply │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Update        │ 0.1690 │     2.36 % │ 0.0436 │</span></span>
<span class="line"><span>│ Convergence   │ 0.3729 │     6.90 % │ 0.1275 │</span></span>
<span class="line"><span>│ Input/Output  │ 0.8715 │     3.96 % │ 0.0732 │</span></span>
<span class="line"><span>│ Other         │ 3.3569 │    46.89 % │ 0.8661 │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Total         │ 7.1589 │   100.00 % │ 1.8470 │</span></span>
<span class="line"><span>╰───────────────┴────────┴────────────┴────────╯</span></span></code></pre></div><h1 id="Specify-an-objective" tabindex="-1">Specify an objective <a class="header-anchor" href="#Specify-an-objective" aria-label="Permalink to &quot;Specify an objective {#Specify-an-objective}&quot;">​</a></h1><p>Objective: Penalize any voltage less than target value of 4.2 (higher than initial voltage for battery)</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">v_target </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4.2</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> objective</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, state, dt, step_no, forces)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">	return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> max</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(v_target </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">^</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>objective (generic function with 1 method)</span></span></code></pre></div><h1 id="Setup-the-optimization-problem" tabindex="-1">Setup the optimization problem <a class="header-anchor" href="#Setup-the-optimization-problem" aria-label="Permalink to &quot;Setup the optimization problem {#Setup-the-optimization-problem}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">opt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Optimization</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(output_0, objective)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Parameters for Elyte</span></span>
<span class="line"><span>┌──────────────────────┬────────┬────┬─────────┬─────────────────┬─────────────┬──────────────────────┬─────────┐</span></span>
<span class="line"><span>│                 Name │ Entity │  N │   Scale │     Abs. limits │ Rel. limits │               Limits │ Lumping │</span></span>
<span class="line"><span>├──────────────────────┼────────┼────┼─────────┼─────────────────┼─────────────┼──────────────────────┼─────────┤</span></span>
<span class="line"><span>│ BruggemanCoefficient │  Cells │ 30 │ default │     [-Inf, Inf] │    [0.5, 5] │          [0.75, 7.5] │       - │</span></span>
<span class="line"><span>│               Volume │  Cells │ 30 │ default │ [2.22e-16, Inf] │    [0.5, 5] │ [6.16e-08, 4.38e-06] │       - │</span></span>
<span class="line"><span>│          Temperature │  Cells │ 30 │ default │     [-Inf, Inf] │    [0.5, 5] │      [149, 1.49e+03] │       - │</span></span>
<span class="line"><span>│       VolumeFraction │  Cells │ 30 │ default │ [2.22e-16, Inf] │    [0.5, 5] │        [0.125, 2.35] │       - │</span></span>
<span class="line"><span>│ ECTransmissibilities │  Faces │ 29 │ default │     [-Inf, Inf] │    [0.5, 5] │ [6.03e+03, 4.28e+05] │       - │</span></span>
<span class="line"><span>└──────────────────────┴────────┴────┴─────────┴─────────────────┴─────────────┴──────────────────────┴─────────┘</span></span>
<span class="line"><span>Parameters for NeAm</span></span>
<span class="line"><span>┌──────────────────────┬────────────────────────┬────┬─────────┬─────────────────┬─────────────┬──────────────────────┬─────────┐</span></span>
<span class="line"><span>│                 Name │                 Entity │  N │   Scale │     Abs. limits │ Rel. limits │               Limits │ Lumping │</span></span>
<span class="line"><span>├──────────────────────┼────────────────────────┼────┼─────────┼─────────────────┼─────────────┼──────────────────────┼─────────┤</span></span>
<span class="line"><span>│          BoundaryPhi │ BoundaryDirichletFaces │  1 │ default │     [-Inf, Inf] │    [0.5, 5] │           [0, 1e-18] │       - │</span></span>
<span class="line"><span>│               Volume │                  Cells │ 10 │ default │ [2.22e-16, Inf] │    [0.5, 5] │ [4.38e-07, 4.38e-06] │       - │</span></span>
<span class="line"><span>│          Temperature │                  Cells │ 10 │ default │     [-Inf, Inf] │    [0.5, 5] │      [149, 1.49e+03] │       - │</span></span>
<span class="line"><span>│       VolumeFraction │                  Cells │ 10 │ default │ [2.22e-16, Inf] │    [0.5, 5] │        [0.375, 3.75] │       - │</span></span>
<span class="line"><span>│         Conductivity │                  Cells │ 10 │ default │     [-Inf, Inf] │    [0.5, 5] │          [69.8, 698] │       - │</span></span>
<span class="line"><span>│ ECTransmissibilities │                  Faces │  9 │ default │     [-Inf, Inf] │    [0.5, 5] │ [6.03e+03, 6.03e+04] │       - │</span></span>
<span class="line"><span>└──────────────────────┴────────────────────────┴────┴─────────┴─────────────────┴─────────────┴──────────────────────┴─────────┘</span></span>
<span class="line"><span>Parameters for Control</span></span>
<span class="line"><span>┌───────────────┬────────┬───┬─────────┬─────────────┬─────────────┬──────────────┬─────────┐</span></span>
<span class="line"><span>│          Name │ Entity │ N │   Scale │ Abs. limits │ Rel. limits │       Limits │ Lumping │</span></span>
<span class="line"><span>├───────────────┼────────┼───┼─────────┼─────────────┼─────────────┼──────────────┼─────────┤</span></span>
<span class="line"><span>│ ImaxDischarge │  Cells │ 1 │ default │ [-Inf, Inf] │    [0.5, 5] │ [2.55, 25.5] │       - │</span></span>
<span class="line"><span>└───────────────┴────────┴───┴─────────┴─────────────┴─────────────┴──────────────┴─────────┘</span></span>
<span class="line"><span>Parameters for PeAm</span></span>
<span class="line"><span>┌──────────────────────┬────────┬────┬─────────┬─────────────────┬─────────────┬──────────────────────┬─────────┐</span></span>
<span class="line"><span>│                 Name │ Entity │  N │   Scale │     Abs. limits │ Rel. limits │               Limits │ Lumping │</span></span>
<span class="line"><span>├──────────────────────┼────────┼────┼─────────┼─────────────────┼─────────────┼──────────────────────┼─────────┤</span></span>
<span class="line"><span>│               Volume │  Cells │ 10 │ default │ [2.22e-16, Inf] │    [0.5, 5] │ [3.88e-07, 3.88e-06] │       - │</span></span>
<span class="line"><span>│          Temperature │  Cells │ 10 │ default │     [-Inf, Inf] │    [0.5, 5] │      [149, 1.49e+03] │       - │</span></span>
<span class="line"><span>│       VolumeFraction │  Cells │ 10 │ default │ [2.22e-16, Inf] │    [0.5, 5] │        [0.333, 3.33] │       - │</span></span>
<span class="line"><span>│         Conductivity │  Cells │ 10 │ default │     [-Inf, Inf] │    [0.5, 5] │      [0.0488, 0.488] │       - │</span></span>
<span class="line"><span>│ ECTransmissibilities │  Faces │  9 │ default │     [-Inf, Inf] │    [0.5, 5] │ [6.79e+03, 6.79e+04] │       - │</span></span>
<span class="line"><span>└──────────────────────┴────────┴────┴─────────┴─────────────────┴─────────────┴──────────────────────┴─────────┘</span></span></code></pre></div><h1 id="Solve-the-optimization-problem" tabindex="-1">Solve the optimization problem <a class="header-anchor" href="#Solve-the-optimization-problem" aria-label="Permalink to &quot;Solve the optimization problem {#Solve-the-optimization-problem}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output_tuned </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(opt)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #1: 3.7688e+03 (best: Inf, relative: 1.0000e+00)</span></span>
<span class="line"><span>[ Info: Initial objective: 3768.7668171689625, gradient norm 190969.3252199628</span></span>
<span class="line"><span>RUNNING THE L-BFGS-B CODE</span></span>
<span class="line"><span></span></span>
<span class="line"><span>           * * *</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Machine precision = 2.220D-16</span></span>
<span class="line"><span> N =          249     M =           10</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At X0         1 variables are exactly at the bounds</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #2: 3.7688e+03 (best: 3.7688e+03, relative: 1.0000e+00)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    0    f=  3.76877D+03    |proj g|=  8.88889D-01</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #3: 2.4979e+01 (best: 3.7688e+03, relative: 6.6278e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    1    f=  2.49786D+01    |proj g|=  1.51721D-02</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #4: 2.4979e+01 (best: 2.4979e+01, relative: 6.6278e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #5: 2.4979e+01 (best: 2.4979e+01, relative: 6.6278e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #6: 2.4979e+01 (best: 2.4979e+01, relative: 6.6278e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #7: 2.4979e+01 (best: 2.4979e+01, relative: 6.6278e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #8: 2.4979e+01 (best: 2.4979e+01, relative: 6.6278e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #9: 2.4978e+01 (best: 2.4979e+01, relative: 6.6277e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #10: 2.4977e+01 (best: 2.4978e+01, relative: 6.6275e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #11: 2.4974e+01 (best: 2.4977e+01, relative: 6.6265e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    2    f=  2.49738D+01    |proj g|=  1.24265D-02</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #12: 2.4954e+01 (best: 2.4974e+01, relative: 6.6212e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    3    f=  2.49538D+01    |proj g|=  6.04406D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #13: 2.4945e+01 (best: 2.4954e+01, relative: 6.6189e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    4    f=  2.49451D+01    |proj g|=  4.46797D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #14: 2.4938e+01 (best: 2.4945e+01, relative: 6.6169e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    5    f=  2.49376D+01    |proj g|=  2.80680D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #15: 2.4936e+01 (best: 2.4938e+01, relative: 6.6166e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    6    f=  2.49363D+01    |proj g|=  2.54004D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #16: 2.4935e+01 (best: 2.4936e+01, relative: 6.6162e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    7    f=  2.49350D+01    |proj g|=  2.26234D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #17: 2.4931e+01 (best: 2.4935e+01, relative: 6.6151e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    8    f=  2.49307D+01    |proj g|=  1.18018D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #18: 2.4931e+01 (best: 2.4931e+01, relative: 6.6150e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #19: 2.4930e+01 (best: 2.4931e+01, relative: 6.6150e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #20: 2.4930e+01 (best: 2.4930e+01, relative: 6.6149e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate    9    f=  2.49299D+01    |proj g|=  1.21230D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #21: 2.4930e+01 (best: 2.4930e+01, relative: 6.6148e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #22: 2.4929e+01 (best: 2.4930e+01, relative: 6.6147e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   10    f=  2.49294D+01    |proj g|=  1.23403D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #23: 2.4927e+01 (best: 2.4929e+01, relative: 6.6142e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   11    f=  2.49274D+01    |proj g|=  1.51346D-03</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #24: 2.4927e+01 (best: 2.4927e+01, relative: 6.6142e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #25: 2.4927e+01 (best: 2.4927e+01, relative: 6.6141e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #26: 2.4927e+01 (best: 2.4927e+01, relative: 6.6141e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   12    f=  2.49269D+01    |proj g|=  1.63959D-03</span></span>
<span class="line"><span>  ys=-3.446E-05  -gs= 5.009E-04 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #27: 2.4927e+01 (best: 2.4927e+01, relative: 6.6141e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   13    f=  2.49268D+01    |proj g|=  1.65642D-03</span></span>
<span class="line"><span>  ys=-5.731E-07  -gs= 6.640E-05 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #28: 2.4927e+01 (best: 2.4927e+01, relative: 6.6140e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #29: 2.4927e+01 (best: 2.4927e+01, relative: 6.6140e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   14    f=  2.49267D+01    |proj g|=  1.68495D-03</span></span>
<span class="line"><span>  ys=-1.614E-06  -gs= 1.112E-04 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #30: 2.4927e+01 (best: 2.4927e+01, relative: 6.6140e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   15    f=  2.49267D+01    |proj g|=  1.69998D-03</span></span>
<span class="line"><span>  ys=-4.655E-07  -gs= 5.794E-05 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #31: 2.4927e+01 (best: 2.4927e+01, relative: 6.6140e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #32: 2.4926e+01 (best: 2.4927e+01, relative: 6.6139e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #33: 2.4926e+01 (best: 2.4926e+01, relative: 6.6138e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   16    f=  2.49259D+01    |proj g|=  1.91159D-03</span></span>
<span class="line"><span>  ys=-8.348E-05  -gs= 7.472E-04 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #34: 2.4926e+01 (best: 2.4926e+01, relative: 6.6138e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   17    f=  2.49258D+01    |proj g|=  1.93209D-03</span></span>
<span class="line"><span>  ys=-7.001E-07  -gs= 7.258E-05 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #35: 2.4926e+01 (best: 2.4926e+01, relative: 6.6138e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #36: 2.4925e+01 (best: 2.4926e+01, relative: 6.6137e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #37: 2.4924e+01 (best: 2.4925e+01, relative: 6.6134e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   18    f=  2.49243D+01    |proj g|=  2.37719D-03</span></span>
<span class="line"><span>  ys=-2.768E-04  -gs= 1.349E-03 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #38: 2.4924e+01 (best: 2.4924e+01, relative: 6.6134e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #39: 2.4924e+01 (best: 2.4924e+01, relative: 6.6133e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   19    f=  2.49240D+01    |proj g|=  2.47885D-03</span></span>
<span class="line"><span>  ys=-1.170E-05  -gs= 3.027E-04 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #40: 2.4924e+01 (best: 2.4924e+01, relative: 6.6133e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #41: 2.4923e+01 (best: 2.4924e+01, relative: 6.6132e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #42: 2.4921e+01 (best: 2.4923e+01, relative: 6.6126e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #43: 2.4917e+01 (best: 2.4921e+01, relative: 6.6116e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   20    f=  2.49174D+01    |proj g|=  5.33218D-03</span></span>
<span class="line"><span>  ys=-4.594E-03  -gs= 4.707E-03 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #44: 2.4917e+01 (best: 2.4917e+01, relative: 6.6114e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #45: 2.4915e+01 (best: 2.4917e+01, relative: 6.6109e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #46: 2.4902e+01 (best: 2.4915e+01, relative: 6.6076e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #47: 2.4882e+01 (best: 2.4902e+01, relative: 6.6022e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   21    f=  2.48823D+01    |proj g|=  3.78127D-02</span></span>
<span class="line"><span>  ys=-8.512E-02  -gs= 1.333E-02 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #48: 2.4874e+01 (best: 2.4882e+01, relative: 6.5999e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   22    f=  2.48737D+01    |proj g|=  2.91089D-02</span></span>
<span class="line"><span>  ys=-3.612E-03  -gs= 7.075E-03 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #49: 2.4868e+01 (best: 2.4874e+01, relative: 6.5983e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   23    f=  2.48676D+01    |proj g|=  3.04598D-02</span></span>
<span class="line"><span>  ys=-2.746E-03  -gs= 4.903E-03 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #50: 2.4862e+01 (best: 2.4868e+01, relative: 6.5967e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   24    f=  2.48615D+01    |proj g|=  3.47181D-02</span></span>
<span class="line"><span>  ys=-3.151E-03  -gs= 4.680E-03 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #51: 2.4855e+01 (best: 2.4862e+01, relative: 6.5949e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   25    f=  2.48548D+01    |proj g|=  1.22987D-02</span></span>
<span class="line"><span>  ys=-4.605E-03  -gs= 4.816E-03 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #52: 2.4854e+01 (best: 2.4855e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   26    f=  2.48540D+01    |proj g|=  1.22651D-04</span></span>
<span class="line"><span>  ys=-1.472E-04  -gs= 7.172E-04 BFGS update SKIPPED</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #53: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #54: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #55: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   27    f=  2.48540D+01    |proj g|=  1.22056D-04</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #56: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   28    f=  2.48540D+01    |proj g|=  9.28383D-05</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #57: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   29    f=  2.48540D+01    |proj g|=  4.26000D-05</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #58: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   30    f=  2.48540D+01    |proj g|=  4.14884D-05</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #59: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #60: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   31    f=  2.48539D+01    |proj g|=  3.17509D-05</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #61: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   32    f=  2.48539D+01    |proj g|=  2.26562D-05</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #62: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>At iterate   33    f=  2.48539D+01    |proj g|=  3.85082D-06</span></span>
<span class="line"><span></span></span>
<span class="line"><span>           * * *</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Tit   = total number of iterations</span></span>
<span class="line"><span>Tnf   = total number of function evaluations</span></span>
<span class="line"><span>Tnint = total number of segments explored during Cauchy searches</span></span>
<span class="line"><span>Skip  = number of BFGS updates skipped</span></span>
<span class="line"><span>Nact  = number of active bounds at final generalized Cauchy point</span></span>
<span class="line"><span>Projg = norm of the final projected gradient</span></span>
<span class="line"><span>F     = final function value</span></span>
<span class="line"><span></span></span>
<span class="line"><span>           * * *</span></span>
<span class="line"><span></span></span>
<span class="line"><span>   N    Tit     Tnf  Tnint  Skip  Nact     Projg        F</span></span>
<span class="line"><span>  249     33     61    263    15   226   3.851D-06   2.485D+01</span></span>
<span class="line"><span>  F =   24.853924918342159</span></span>
<span class="line"><span></span></span>
<span class="line"><span>CONVERGENCE: NORM_OF_PROJECTED_GRADIENT_&lt;=_PGTOL</span></span>
<span class="line"><span></span></span>
<span class="line"><span> Cauchy                time 3.052E-04 seconds.</span></span>
<span class="line"><span> Subspace minimization time 4.578E-04 seconds.</span></span>
<span class="line"><span> Line search           time 2.362E+01 seconds.</span></span>
<span class="line"><span></span></span>
<span class="line"><span> Total User time 2.410E+01 seconds.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span>
<span class="line"><span>Obj. #63: 2.4854e+01 (best: 2.4854e+01, relative: 6.5947e-03)</span></span>
<span class="line"><span>Jutul: Simulating 1 hour, 6 minutes as 84 report steps</span></span></code></pre></div><h1 id="Plot-results" tabindex="-1">Plot results <a class="header-anchor" href="#Plot-results" aria-label="Permalink to &quot;Plot results {#Plot-results}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states_tuned </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output_tuned[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">report_tuned </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output_tuned[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:report</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">final_x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output_tuned[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:final_x</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">optimization_setup </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> opt</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">setup</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">x0 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> optimization_setup</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">x0</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">F0 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> optimization_setup</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">F!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x0)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">F_final </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> optimization_setup</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">F!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(final_x)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">lower </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> optimization_setup</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">limits</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">min</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">upper </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> optimization_setup</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">limits</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">max</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> opt</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameters</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">opt_model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> opt</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">data </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> opt</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">setup</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">data</span></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fig </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ys </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> log10</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax1 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fig[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], yscale </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> ys, title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Objective evaluations&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, xlabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Iterations&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Objective&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, opt</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">setup[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:obj_hist</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">end</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 1e-12</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fig</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fig </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax1 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fig[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Scaled parameters&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Value&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatter!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, final_x, label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Final X&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatter!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, x0, label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Initial X&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">lines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, lower, label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Lower bound&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">lines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, upper, label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Upper bound&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">axislegend</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fig</span></span></code></pre></div><p><img src="`+e+`" alt=""></p><p>Plot difference in the main objective input</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">F </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> s </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> map</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> only</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]), s)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fig </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax1 </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fig[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> name, ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">lines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">F</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(states), label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Base case (G = </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$F0</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">lines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">F</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(states_tuned), label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Tuned (G = </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$F_final</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">lines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax1, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">repeat</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([v_target], </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">length</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(states)), label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Target voltage&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">axislegend</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(position </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:center</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:bottom</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fig</span></span></code></pre></div><p><img src="`+l+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_optimization.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_optimization.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',25)]))}const d=a(t,[["render",h]]);export{g as __pageData,d as default};
