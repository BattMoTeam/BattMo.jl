import{_ as a,c as n,o as i,aA as p}from"./chunks/framework.CkLnrQ7S.js";const d=JSON.parse('{"title":"Example with SEI layer","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_sei.md","filePath":"examples/example_sei.md","lastUpdated":null}'),e={name:"examples/example_sei.md"};function t(l,s,h,o,r,c){return i(),n("div",null,s[0]||(s[0]=[p(`<h1 id="Example-with-SEI-layer" tabindex="-1">Example with SEI layer <a class="header-anchor" href="#Example-with-SEI-layer" aria-label="Permalink to &quot;Example with SEI layer {#Example-with-SEI-layer}&quot;">​</a></h1><h2 id="Preparation-of-the-input" tabindex="-1">Preparation of the input <a class="header-anchor" href="#Preparation-of-the-input" aria-label="Permalink to &quot;Preparation of the input {#Preparation-of-the-input}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Jutul, BattMo, GLMakie</span></span></code></pre></div><p>We use the SEI model presented in [<a href="/BattMo.jl/previews/PR28/extras/refs#bolay2022">1</a>]. We use the json data given in <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/bolay.json#L157" target="_blank" rel="noreferrer">bolay.json</a> which contains the parameters for the SEI layer.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cell_parameters/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;SEI_example.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cycling_protocols/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCCV.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_simulation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/simulation_settings/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P2D.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cycling)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">simulation_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_simulation_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_simulation)</span></span></code></pre></div><p>We retrieve the parameters for the SEI layer, using the fact that their names have a &quot;SEI&quot; prefix.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">interphaseparams </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> cell_parameters[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;NegativeElectrode&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Interphase&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(interphaseparams)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 8 entries:</span></span>
<span class="line"><span>  &quot;IntersticialConcentration&quot;      =&gt; 0.015</span></span>
<span class="line"><span>  &quot;Description&quot;                    =&gt; &quot;EC-based CEI&quot;</span></span>
<span class="line"><span>  &quot;ElectronicDiffusionCoefficient&quot; =&gt; 1.6e-12</span></span>
<span class="line"><span>  &quot;InitialThickness&quot;               =&gt; 1.0e-8</span></span>
<span class="line"><span>  &quot;IonicConductivity&quot;              =&gt; 1.0e-5</span></span>
<span class="line"><span>  &quot;StoichiometricCoefficient&quot;      =&gt; 2</span></span>
<span class="line"><span>  &quot;InitialPotentialDrop&quot;           =&gt; 0.5</span></span>
<span class="line"><span>  &quot;MolarVolume&quot;                    =&gt; 9.586e-5</span></span></code></pre></div><h2 id="We-start-the-simulation-and-retrieve-the-result" tabindex="-1">We start the simulation and retrieve the result <a class="header-anchor" href="#We-start-the-simulation-and-retrieve-the-result" aria-label="Permalink to &quot;We start the simulation and retrieve the result {#We-start-the-simulation-and-retrieve-the-result}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>model = LithiumIonBatteryModel();</span></span>
<span class="line"><span></span></span>
<span class="line"><span>model_settings = model.model_settings</span></span>
<span class="line"><span>model_settings[&quot;UseSEIModel&quot;] = &quot;Bolay&quot;</span></span>
<span class="line"><span></span></span>
<span class="line"><span>cycling_protocol[&quot;TotalNumberOfCycles&quot;] = 10</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);</span></span>
<span class="line"><span></span></span>
<span class="line"><span>output = solve(sim)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>states = output[:states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>t = [state[:Control][:ControllerCV].time for state in states]</span></span>
<span class="line"><span>E = [state[:Control][:Phi][1] for state in states]</span></span>
<span class="line"><span>I = [state[:Control][:Current][1] for state in states]</span></span>
<span class="line"><span>nothing # hide</span></span></code></pre></div><h2 id="Plot-of-voltage-and-current" tabindex="-1">Plot of voltage and current <a class="header-anchor" href="#Plot-of-voltage-and-current" aria-label="Permalink to &quot;Plot of voltage and current {#Plot-of-voltage-and-current}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>f = Figure(size = (1000, 400))</span></span>
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
<span class="line"><span></span></span>
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
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_sei.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_sei.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,19)]))}const u=a(e,[["render",t]]);export{d as __pageData,u as default};
