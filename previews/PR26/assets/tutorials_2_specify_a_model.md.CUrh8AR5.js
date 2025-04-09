import{_ as a,c as n,o as e,aA as i}from"./chunks/framework.BFbzQv2c.js";const k=JSON.parse('{"title":"Setting Up a Custom Battery Model","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/2_specify_a_model.md","filePath":"tutorials/2_specify_a_model.md","lastUpdated":null}'),p={name:"tutorials/2_specify_a_model.md"};function t(l,s,o,h,c,d){return e(),n("div",null,s[0]||(s[0]=[i(`<h1 id="Setting-Up-a-Custom-Battery-Model" tabindex="-1">Setting Up a Custom Battery Model <a class="header-anchor" href="#Setting-Up-a-Custom-Battery-Model" aria-label="Permalink to &quot;Setting Up a Custom Battery Model {#Setting-Up-a-Custom-Battery-Model}&quot;">​</a></h1><p>In this tutorial, we’ll configure a custom battery model using BattMo, with a specific focus on SEI (Solid Electrolyte Interphase) growth within a P2D simulation framework.</p><h3 id="Load-BattMo-and-Model-Settings" tabindex="-1">Load BattMo and Model Settings <a class="header-anchor" href="#Load-BattMo-and-Model-Settings" aria-label="Permalink to &quot;Load BattMo and Model Settings {#Load-BattMo-and-Model-Settings}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span></code></pre></div><p>Let’s begin by loading the default model settings for a P2D simulation. This will return a ModelSettings object:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/model_settings/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;model_settings_P2D.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> read_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path_model)</span></span></code></pre></div><p>We can inspect all current settings with:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">all</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 5 entries:</span></span>
<span class="line"><span>  &quot;UseThermalModel&quot;      =&gt; false</span></span>
<span class="line"><span>  &quot;UseCurrentCollectors&quot; =&gt; false</span></span>
<span class="line"><span>  &quot;ModelGeometry&quot;        =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>  &quot;UseRampUp&quot;            =&gt; true</span></span>
<span class="line"><span>  &quot;UseSEIModel&quot;          =&gt; false</span></span></code></pre></div><p>By default, the &quot;UseSEIModel&quot; parameter is set to false. Since we want to observe SEI effects, we’ll enable it:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;UseSEIModel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">all</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 5 entries:</span></span>
<span class="line"><span>  &quot;UseThermalModel&quot;      =&gt; false</span></span>
<span class="line"><span>  &quot;UseCurrentCollectors&quot; =&gt; false</span></span>
<span class="line"><span>  &quot;ModelGeometry&quot;        =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>  &quot;UseRampUp&quot;            =&gt; true</span></span>
<span class="line"><span>  &quot;UseSEIModel&quot;          =&gt; true</span></span></code></pre></div><h3 id="Initialize-the-Model" tabindex="-1">Initialize the Model <a class="header-anchor" href="#Initialize-the-Model" aria-label="Permalink to &quot;Initialize the Model {#Initialize-the-Model}&quot;">​</a></h3><p>Let’s now create the battery model using the modified settings:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>🔍 Validation of ModelSettings failed with 2 issues:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 1:</span></span>
<span class="line"><span>📍 Where:</span></span>
<span class="line"><span>🔢 Provided:    Dict{String, Any}(&quot;UseThermalModel&quot; =&gt; false, &quot;UseCurrentCollectors&quot; =&gt; false, &quot;ModelGeometry&quot; =&gt; &quot;1D&quot;, &quot;UseRampUp&quot; =&gt; true, &quot;UseSEIModel&quot; =&gt; true)</span></span>
<span class="line"><span>🔑 Rule:        required = [&quot;SEIModel&quot;]</span></span>
<span class="line"><span>🛠  Issue:       Missing required field(s): SEIModel</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 2:</span></span>
<span class="line"><span>📍 Where:</span></span>
<span class="line"><span>🔢 Provided:    Dict{String, Any}(&quot;UseThermalModel&quot; =&gt; false, &quot;UseCurrentCollectors&quot; =&gt; false, &quot;ModelGeometry&quot; =&gt; &quot;1D&quot;, &quot;UseRampUp&quot; =&gt; true, &quot;UseSEIModel&quot; =&gt; true)</span></span>
<span class="line"><span>🔑 Rule:        required = [&quot;SEIModel&quot;]</span></span>
<span class="line"><span>🛠  Issue:       Missing required field(s): SEIModel</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>We can see that some warnings are given in the terminal. When setting up the model, the LithiumIonBatteryModel constructor runs a validation on the model_settings. In this case, because we set the &quot;UseSEIModel&quot; parameter to true, the validator provides a warning that we should define which SEI model we would like to use. If we ignore the warnings and pass the model to the Simulation constructor then we get an error:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/cell_parameters/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cell_parameter_set_SEI_example.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/cycling_protocols/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCCV.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters_sei </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> read_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cccv_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> read_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path_cycling)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters_sei, cccv_protocol)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Oops! Your Model object is not valid. 🛑</span></span>
<span class="line"><span></span></span>
<span class="line"><span>TIP: Validation happens when instantiating the Model object.</span></span>
<span class="line"><span>Check the warnings to see exactly where things went wrong. 🔍</span></span></code></pre></div><p>As expected, this results in an error because we haven&#39;t yet specified the SEI model type.</p><h3 id="Specify-SEI-Model-and-Rebuild" tabindex="-1">Specify SEI Model and Rebuild <a class="header-anchor" href="#Specify-SEI-Model-and-Rebuild" aria-label="Permalink to &quot;Specify SEI Model and Rebuild {#Specify-SEI-Model-and-Rebuild}&quot;">​</a></h3><p>To resolve this, we’ll explicitly set the SEI model to &quot;Bolay&quot;:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;SEIModel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bolay&quot;</span></span></code></pre></div><p>Now rebuild the model:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>Run the Simulation Now we can setup the simulation and run it.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters_sei, cccv_protocol)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Jutul: Simulating 9 hours as 648 report steps</span></span>
<span class="line"><span>╭────────────────┬───────────┬───────────────┬────────────╮</span></span>
<span class="line"><span>│ Iteration type │  Avg/step │  Avg/ministep │      Total │</span></span>
<span class="line"><span>│                │ 609 steps │ 648 ministeps │   (wasted) │</span></span>
<span class="line"><span>├────────────────┼───────────┼───────────────┼────────────┤</span></span>
<span class="line"><span>│ Newton         │   2.99343 │       2.81327 │ 1823 (390) │</span></span>
<span class="line"><span>│ Linearization  │   4.05747 │       3.81327 │ 2471 (416) │</span></span>
<span class="line"><span>│ Linear solver  │   2.99343 │       2.81327 │ 1823 (390) │</span></span>
<span class="line"><span>│ Precond apply  │       0.0 │           0.0 │      0 (0) │</span></span>
<span class="line"><span>╰────────────────┴───────────┴───────────────┴────────────╯</span></span>
<span class="line"><span>╭───────────────┬────────┬────────────┬────────╮</span></span>
<span class="line"><span>│ Timing type   │   Each │   Relative │  Total │</span></span>
<span class="line"><span>│               │     ms │ Percentage │      s │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Properties    │ 0.0522 │     5.01 % │ 0.0952 │</span></span>
<span class="line"><span>│ Equations     │ 0.2009 │    26.10 % │ 0.4965 │</span></span>
<span class="line"><span>│ Assembly      │ 0.0781 │    10.15 % │ 0.1931 │</span></span>
<span class="line"><span>│ Linear solve  │ 0.4049 │    38.81 % │ 0.7381 │</span></span>
<span class="line"><span>│ Linear setup  │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Precond apply │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Update        │ 0.0537 │     5.15 % │ 0.0979 │</span></span>
<span class="line"><span>│ Convergence   │ 0.0684 │     8.89 % │ 0.1691 │</span></span>
<span class="line"><span>│ Input/Output  │ 0.0848 │     2.89 % │ 0.0550 │</span></span>
<span class="line"><span>│ Other         │ 0.0313 │     3.00 % │ 0.0571 │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Total         │ 1.0434 │   100.00 % │ 1.9020 │</span></span>
<span class="line"><span>╰───────────────┴────────┴────────────┴────────╯</span></span></code></pre></div><h2 id="Plot-of-voltage-and-current" tabindex="-1">Plot of voltage and current <a class="header-anchor" href="#Plot-of-voltage-and-current" aria-label="Permalink to &quot;Plot of voltage and current {#Plot-of-voltage-and-current}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>states = output[:states]</span></span>
<span class="line highlighted"><span></span></span>
<span class="line"><span>t = [state[:Control][:ControllerCV].time for state in states]</span></span>
<span class="line"><span>E = [state[:Control][:Phi][1] for state in states]</span></span>
<span class="line"><span>I = [state[:Control][:Current][1] for state in states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>f = Figure(size = (1000, 400))</span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[1, 1],</span></span>
<span class="line"><span>	title = &quot;Voltage&quot;,</span></span>
<span class="line"><span>	xlabel = &quot;Time / s&quot;,</span></span>
<span class="line"><span>	ylabel = &quot;Voltage / V&quot;,</span></span>
<span class="line"><span>	xlabelsize = 25,</span></span>
<span class="line"><span>	ylabelsize = 25,</span></span>
<span class="line"><span>	xticklabelsize = 25,</span></span>
<span class="line"><span>	yticklabelsize = 25,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	E;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black,</span></span>
<span class="line"><span>	label = &quot;Julia&quot;,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[1, 2],</span></span>
<span class="line"><span>	title = &quot;Current&quot;,</span></span>
<span class="line"><span>	xlabel = &quot;Time / s&quot;,</span></span>
<span class="line"><span>	ylabel = &quot;Current / A&quot;,</span></span>
<span class="line"><span>	xlabelsize = 25,</span></span>
<span class="line"><span>	ylabelsize = 25,</span></span>
<span class="line"><span>	xticklabelsize = 25,</span></span>
<span class="line"><span>	yticklabelsize = 25,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	I;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black,</span></span>
<span class="line"><span>	label = &quot;Julia&quot;,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>display(GLMakie.Screen(), f) # hide</span></span>
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Plot-of-SEI-length" tabindex="-1">Plot of SEI length <a class="header-anchor" href="#Plot-of-SEI-length" aria-label="Permalink to &quot;Plot of SEI length {#Plot-of-SEI-length}&quot;">​</a></h2><p>We recover the SEI length from the <code>state</code> output</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>seilength = [state[:NeAm][:SEIlength][end] for state in states]</span></span>
<span class="line highlighted"><span></span></span>
<span class="line"><span>f = Figure(size = (1000, 400))</span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[1, 1],</span></span>
<span class="line"><span>	title = &quot;Length&quot;,</span></span>
<span class="line"><span>	xlabel = &quot;Time / s&quot;,</span></span>
<span class="line"><span>	ylabel = &quot;Length / m&quot;,</span></span>
<span class="line"><span>	xlabelsize = 25,</span></span>
<span class="line"><span>	ylabelsize = 25,</span></span>
<span class="line"><span>	xticklabelsize = 25,</span></span>
<span class="line"><span>	yticklabelsize = 25,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	seilength;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[2, 1],</span></span>
<span class="line"><span>	title = &quot;Length&quot;,</span></span>
<span class="line"><span>	xlabel = &quot;Time / s&quot;,</span></span>
<span class="line"><span>	ylabel = &quot;Voltage / V&quot;,</span></span>
<span class="line"><span>	xlabelsize = 25,</span></span>
<span class="line"><span>	ylabelsize = 25,</span></span>
<span class="line"><span>	xticklabelsize = 25,</span></span>
<span class="line"><span>	yticklabelsize = 25,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	E;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>display(GLMakie.Screen(), f) # hide</span></span>
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/2_specify_a_model.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/2_specify_a_model.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,38)]))}const u=a(p,[["render",t]]);export{k as __pageData,u as default};
