import{_ as s,c as n,o as e,aA as p}from"./chunks/framework.B1B9arGg.js";const d=JSON.parse('{"title":"Example with SEI layer","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_sei.md","filePath":"examples/example_sei.md","lastUpdated":null}'),l={name:"examples/example_sei.md"};function t(i,a,o,r,c,h){return e(),n("div",null,a[0]||(a[0]=[p(`<h1 id="Example-with-SEI-layer" tabindex="-1">Example with SEI layer <a class="header-anchor" href="#Example-with-SEI-layer" aria-label="Permalink to &quot;Example with SEI layer {#Example-with-SEI-layer}&quot;">​</a></h1><h2 id="Preparation-of-the-input" tabindex="-1">Preparation of the input <a class="header-anchor" href="#Preparation-of-the-input" aria-label="Permalink to &quot;Preparation of the input {#Preparation-of-the-input}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Jutul, BattMo, GLMakie</span></span></code></pre></div><p>We use the SEI model presented in [<a href="/BattMo.jl/previews/PR27/extras/refs#bolay2022">1</a>]. We use the json data given in <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/bolay.json#L157" target="_blank" rel="noreferrer">bolay.json</a> which contains the parameters for the SEI layer.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>file_path_cell = string(dirname(pathof(BattMo)), &quot;/../test/data/jsonfiles/cell_parameters/&quot;, &quot;SEI_example.json&quot;)</span></span>
<span class="line"><span>file_path_cycling = string(dirname(pathof(BattMo)), &quot;/../test/data/jsonfiles/cycling_protocols/&quot;, &quot;CCCV.json&quot;)</span></span>
<span class="line"><span>file_path_simulation = string(dirname(pathof(BattMo)), &quot;/../test/data/jsonfiles/simulation_settings/&quot;, &quot;simulation_settings_P2D.json&quot;)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)</span></span>
<span class="line"><span>cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)</span></span>
<span class="line"><span>simulation_settings = read_simulation_settings(file_path_simulation)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>nothing # hide</span></span></code></pre></div><p>We retrieve the parameters for the SEI layer, using the fact that their names have a &quot;SEI&quot; prefix.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>interphaseparams = cell_parameters[&quot;NegativeElectrode&quot;][&quot;Interphase&quot;]</span></span>
<span class="line"><span>Dict(interphaseparams)</span></span></code></pre></div><h2 id="We-start-the-simulation-and-retrieve-the-result" tabindex="-1">We start the simulation and retrieve the result <a class="header-anchor" href="#We-start-the-simulation-and-retrieve-the-result" aria-label="Permalink to &quot;We start the simulation and retrieve the result {#We-start-the-simulation-and-retrieve-the-result}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>model = LithiumIonBatteryModel();</span></span>
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
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_sei.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_sei.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,18)]))}const m=s(l,[["render",t]]);export{d as __pageData,m as default};
