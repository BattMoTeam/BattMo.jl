import{_ as i,c as e,o as a,aA as n}from"./chunks/framework.d7jBtXBg.js";const d=JSON.parse('{"title":"How to change solver related settings in BattMo","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/11_handling_solver_settings.md","filePath":"tutorials/11_handling_solver_settings.md","lastUpdated":null}'),t={name:"tutorials/11_handling_solver_settings.md"};function l(p,s,h,k,r,o){return a(),e("div",null,[...s[0]||(s[0]=[n(`<h1 id="How-to-change-solver-related-settings-in-BattMo" tabindex="-1">How to change solver related settings in BattMo <a class="header-anchor" href="#How-to-change-solver-related-settings-in-BattMo" aria-label="Permalink to &quot;How to change solver related settings in BattMo {#How-to-change-solver-related-settings-in-BattMo}&quot;">​</a></h1><p>Until now we have seen four different input types that can be used to define a simulation in BattMo:</p><ul><li><p><em>CellParameters</em> : defines the physical and chemical properties of the battery cell</p></li><li><p><em>CyclingProtocol</em> : defines the current/voltage profile that the cell is subjected to during the simulation</p></li><li><p><em>ModelSettings</em> : defines various settings for the battery model, such as which submodels to use</p></li><li><p><em>SimulationSettings</em> : defines the time step and grid resolution for your simulations</p></li></ul><p>In addition to these, there is a fifth input type called SolverSettings. These settings allow you to control various aspects of the numerical solver used in BattMo. This can be useful for improving convergence, stability, and performance of the simulations. But as a beginner, just learning how to use BattMo, for most solver settings you&#39;ll stick with the default settings. Therefore, we will not go into detail about all the available options here, but just show how to load and modify the solver settings for a couple of specific settings that can be very useful and handy for every user.</p><p>Let&#39;s get into it.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><p>Just like we can load the default cell parameters, cycling protocol, model settings, and simulation settings, we can also load the default solver settings.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">solver_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_solver_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;default&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Lets setup a simple simulation to demonstrate the solver settings.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Chen2020&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;CCDischarge&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBattery</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters, cycling_protocol)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span></code></pre></div><p>As the solver settings tell the solver how to solve the simulation object, we need to pass the solver settings to the solve function.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim; solver_settings)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of SolverSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Jutul: Simulating 2 hours, 12 minutes as 163 report steps</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭────────────────┬───────────┬───────────────┬──────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Iteration type </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/step </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/ministep </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">    Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">                │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 146 steps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 146 ministeps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> (wasted) </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├────────────────┼───────────┼───────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Newton         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.32192 │       2.32192 │  339 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linearization  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   3.32192 │       3.32192 │  485 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solver  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.32192 │       2.32192 │  339 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│       0.0 │           0.0 │    0 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰────────────────┴───────────┴───────────────┴──────────╯</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭───────────────┬────────┬────────────┬──────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Timing type   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Each </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Relative </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">    Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">               │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">     ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> Percentage </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">       ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Properties    </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0435 │     1.55 % │  14.7532 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Equations     </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 1.4239 │    72.67 % │ 690.5773 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Assembly      </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0764 │     3.90 % │  37.0704 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solve  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.4059 │    14.48 % │ 137.6113 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear setup  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │   0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │   0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Update        </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0547 │     1.95 % │  18.5304 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Convergence   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0727 │     3.71 % │  35.2759 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Input/Output  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0270 │     0.42 % │   3.9453 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Other         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0370 │     1.32 % │  12.5573 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Total         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 2.8033 │   100.00 % │ 950.3212 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰───────────────┴────────┴────────────┴──────────╯</span></span></code></pre></div><p>The simulation should run just like before, but now we have the option to modify the solver settings. One useful setting is that we can set an output path that will save the simulation output to an HDF5 file. This can be useful if you are running long simulations and want to save the output for later analysis. By default, the output is not saved to a file, but we can change that by setting the OutputPath field in the solver settings.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">solver_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;OutputPath&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;example_path/&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim; solver_settings)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#dbab09;--shiki-light-font-weight:bold;--shiki-dark:#ffea7f;--shiki-dark-font-weight:bold;">┌ </span><span style="--shiki-light:#dbab09;--shiki-light-font-weight:bold;--shiki-dark:#ffea7f;--shiki-dark-font-weight:bold;">Warning: </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Assignment to \`output\` in soft scope is ambiguous because a global variable by the same name exists: \`output\` will be treated as a new local. Disambiguate by using \`local output\` to suppress this warning or \`global output\` to assign to the existing global variable.</span></span>
<span class="line"><span style="--shiki-light:#dbab09;--shiki-light-font-weight:bold;--shiki-dark:#ffea7f;--shiki-dark-font-weight:bold;">└ </span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">@ 11_handling_solver_settings.md:60</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of SolverSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Jutul: Simulating 2 hours, 12 minutes as 163 report steps</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭────────────────┬───────────┬───────────────┬──────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Iteration type </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/step </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/ministep </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">    Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">                │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 146 steps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 146 ministeps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> (wasted) </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├────────────────┼───────────┼───────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Newton         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.32192 │       2.32192 │  339 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linearization  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   3.32192 │       3.32192 │  485 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solver  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.32192 │       2.32192 │  339 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│       0.0 │           0.0 │    0 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰────────────────┴───────────┴───────────────┴──────────╯</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭───────────────┬────────┬────────────┬──────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Timing type   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Each </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Relative </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">    Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">               │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">     ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> Percentage </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">       ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Properties    </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0479 │     2.56 % │  16.2368 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Equations     </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.7698 │    58.79 % │ 373.3647 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Assembly      </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0818 │     6.25 % │  39.6734 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solve  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.3887 │    20.75 % │ 131.7564 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear setup  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │   0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │   0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Update        </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0583 │     3.11 % │  19.7593 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Convergence   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0755 │     5.76 % │  36.5958 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Input/Output  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0299 │     0.69 % │   4.3692 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Other         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0394 │     2.10 % │  13.3465 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Total         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 1.8735 │   100.00 % │ 635.1020 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰───────────────┴────────┴────────────┴──────────╯</span></span></code></pre></div><p>Another convenient setting is the option to change the amount of information printed to the console during the simulation. For this we use the setting &quot;InfoLevel&quot;. This can be useful for monitoring the progress of the simulation, and debugging purposes. Or on the contrary, if you want to run a simulation without any output to the console, you can set the value to -1. Let&#39;s have a look at the description of the setting to see the available options.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_setting_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;InfoLevel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	InfoLevel</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	info_level</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	-1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	4</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Info level determines the amount of runtime output to the terminal during simulation.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">0  - gives minimal output (just a progress bar by default, and a final report)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">1  - gives some more details, printing at the start of each step</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">2  - as 1, but also printing the current worst residual at each iteration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">3  - as 1, but prints a table of all non-converged residuals at each iteration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">4  - as 3, but all residuals are printed (even converged values)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">-1 - disables output.</span></span></code></pre></div><p>As you can see, the default value is 0, which gives minimal output (just a progress bar by default, and a final report).</p><p>To have a look at the other available settings, you can print them all like this:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_setting_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; category </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;SolverSettings&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	LinearSolver</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	linear_solver</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Dict</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		The linear solver used to solve linearized systems.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	Method</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	direct, iterative</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Linear solver method.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MinTimestep</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	min_timestep</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	1000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Minimum time step length.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	OutputSubstrates</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	output_substates</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Store substates (between report steps) as field on each state.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MaxSize</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10000000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Maximum size for linear solver.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	InMemoryReports</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	in_memory_reports</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Limit for number of reports kept in memory if output_path is provided.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	TimeStepSelectors</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	timestep_selectors</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	TimestepSelector</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Time-step selectors that pick mini steps.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MaxLinearIterations</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	max_linear_iterations</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Max number of linear iterations in a Newton solve before time-step is cut.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	CheckBeforeSolve</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	check_before_solve</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	true, false</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Check convergence before solving linear system. Can skip some linear solves if not using increment tolerances.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	AlwaysUpdateSecondary</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	always_update_secondary</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	true, false</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Always update secondary variables (even when they can be reused from end of previous step). Only useful for nested solvers</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ReportLevel</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	report_level</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Level of information stored in reports when written to disk.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MaxNonLinearIterations</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	max_nonlinear_iterations</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Max number of nonlinear iterations in a Newton solve before time-step is cut.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	Verbosity</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Verbosity for linear solver.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	EndReport</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	end_report</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Output a final report that includes timings etc. If nothing, depends on info_level instead.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	OutputPath</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	output_path</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Path to write output. If nothing, output is not written to disk.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ASCIITerminal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	ascii_terminal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Avoid unicode (if possible) in terminal output.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MaxTimestep</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	max_timestep</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	1.0e100</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Maximum time step length.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	TimestepMaxDecrease</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	timestep_max_decrease</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	100</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Max allowable factor to decrease time-step by. Overrides step selectors.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	progress_glyphs</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	progress_glyphs</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	default</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Glyphs</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ID</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	id</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		String identifier for simulator that is prefixed to some verbose output.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	FailureCutsTimesteps</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	failure_cuts_timestep</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	true, false</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Cut the timestep if exceptions occur during step. If set to false, throw errors and terminate.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	DebugLevel</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	debug_level</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Define the amount of debug output in the reports. Higher values means more output.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	Relaxation</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	relaxation</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	NoRelaxation, SimpleRelaxation</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Non-Linear relaxation used. Currently supports \`NoRelaxation()\` and \`SimpleRelaxation()\`.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MinNonLinearIterations</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	min_nonlinear_iterations</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	100000000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Minimum number of nonlinear iterations in Newton solver. This number of Newtion iterations is always performed, even if all equations are converged.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	TimestepMaxIncrease</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	timestep_max_increase</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	100</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Max allowable factor to increase time-step by. Overrides step selectors.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	InfoLevel</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	info_level</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	-1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	4</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Info level determines the amount of runtime output to the terminal during simulation.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">0  - gives minimal output (just a progress bar by default, and a final report)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">1  - gives some more details, printing at the start of each step</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">2  - as 1, but also printing the current worst residual at each iteration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">3  - as 1, but prints a table of all non-converged residuals at each iteration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">4  - as 3, but all residuals are printed (even converged values)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">-1 - disables output.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	TolFactorFinalIteration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	tol_factor_final_iteration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Value that multiplies all tolerances for the final convergence check before a time-step is cut.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	LinearTolerance</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	linear_tolerance</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	1.0e-40</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Tolerance used for convergence criterions.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	SafeMode</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	safe_mode</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	true, false</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Add extra checks in simulator that have a small extra cost.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	MaxTimestepCuts</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	max_timestep_cuts</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	10000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Maximum time step cuts in a single mini step before termination of simulation.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	OutputReports</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	output_reports</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Return reports in-memory as output.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ExtraTiming</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	extra_timing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	true, false</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Output extra, highly detailed performance report at simulation end.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	OutputStates</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	output_states</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Return states in-memory as output.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	CuttingCriterion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	cutting_criterion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Nothing</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Criterion to use for early cutting of time-steps. Default value of nothing means cutting when max_nonlinear_iterations is reached.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	Tolerances</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	tolerances</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Dict</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Minimum value:      	1.0e-40</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Maximum value:      	1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Tolerances used for convergence criterions.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ProgressColor</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	progress_color</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Color for progress meter.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ErrorOnIncomplete</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Category:		SolverSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Keyword argument:	error_on_incomplete</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	Bool</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	true, false</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Throw an error if the simulation could not complete. If \`false\` emit a message and return.</span></span></code></pre></div><p>As most of the time we&#39;ll only change one or two settings, and we use some of the settings often temporary, BattMo also has the option to pass the solver settings directly to the solve function, without having to create a SolverSettings object first. This can be useful for quick tests, or if you want to change a setting for a single simulation only. In that case you have to pass them as keyword arguments to the solve function. Because of convention, we use snake_case for the keyword arguments, instead of the usual CamelCase used in the SolverSettings object. The snake_case name is just the CamelCase name with the first letter lowercased and the low dash in between, if you&#39;re unsure, you can find the correct name by printing the setting info as shown above.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim; info_level </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#1b7c83;--shiki-light-font-weight:bold;--shiki-dark:#39c5cf;--shiki-dark-font-weight:bold;">[ </span><span style="--shiki-light:#1b7c83;--shiki-light-font-weight:bold;--shiki-dark:#39c5cf;--shiki-dark-font-weight:bold;">Info: </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Overwriting solver setting: InfoLevel =&gt; 2</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of SolverSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Jutul: Simulating 2 hours, 12 minutes as 163 report steps</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭────────────────┬───────────┬───────────────┬──────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Iteration type </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/step </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/ministep </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">    Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">                │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 146 steps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 146 ministeps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> (wasted) </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├────────────────┼───────────┼───────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Newton         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.32192 │       2.32192 │  339 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linearization  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   3.32192 │       3.32192 │  485 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solver  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.32192 │       2.32192 │  339 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│       0.0 │           0.0 │    0 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰────────────────┴───────────┴───────────────┴──────────╯</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭───────────────┬────────┬────────────┬──────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Timing type   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Each </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Relative </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">    Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">               │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">     ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> Percentage </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">       ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Properties    </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0443 │     2.56 % │  15.0093 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Equations     </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.6000 │    49.54 % │ 290.9776 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Assembly      </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0748 │     6.17 % │  36.2593 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solve  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.5086 │    29.35 % │ 172.4155 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear setup  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │   0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │   0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Update        </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0559 │     3.22 % │  18.9359 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Convergence   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0739 │     6.10 % │  35.8471 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Input/Output  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0295 │     0.73 % │   4.3034 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Other         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0401 │     2.32 % │  13.6082 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼──────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Total         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 1.7326 │   100.00 % │ 587.3563 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰───────────────┴────────┴────────────┴──────────╯</span></span></code></pre></div><p>These keywork arguments will override the settings in the SolverSettings object, if both are provided.</p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/beginner_tutorials/11_handling_solver_settings.jl" target="_blank" rel="noreferrer">as a script</a>.</p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,32)])])}const y=i(t,[["render",l]]);export{d as __pageData,y as default};
