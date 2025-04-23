import{_ as s,c as n,o as e,aA as t}from"./chunks/framework.CkLnrQ7S.js";const m=JSON.parse('{"title":"Cycling a battery 40 times with a constant current constant voltage (CCCV) control","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_cycle.md","filePath":"examples/example_cycle.md","lastUpdated":null}'),p={name:"examples/example_cycle.md"};function l(i,a,o,c,r,u){return e(),n("div",null,a[0]||(a[0]=[t(`<h1 id="Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control" tabindex="-1">Cycling a battery 40 times with a constant current constant voltage (CCCV) control <a class="header-anchor" href="#Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control" aria-label="Permalink to &quot;Cycling a battery 40 times with a constant current constant voltage (CCCV) control {#Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><p>We use the setup provided in the <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152" target="_blank" rel="noreferrer">p2d_40.json</a> file. In particular, see the data under the <code>Control</code> key.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>file_path_cell = string(dirname(pathof(BattMo)), &quot;/../src/input/defaults/cell_parameters/&quot;, &quot;3D_demo_example.json&quot;)</span></span>
<span class="line"><span>file_path_model = string(dirname(pathof(BattMo)), &quot;/../src/input/defaults/model_settings/&quot;, &quot;P2D.json&quot;)</span></span>
<span class="line"><span>file_path_cycling = string(dirname(pathof(BattMo)), &quot;/../src/input/defaults/cycling_protocols/&quot;, &quot;CCCV.json&quot;)</span></span>
<span class="line"><span>file_path_simulation = string(dirname(pathof(BattMo)), &quot;/../src/input/defaults/simulation_settings/&quot;, &quot;P2D.json&quot;)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>cell_parameters = load_cell_parameters(; from_file_path = file_path_cell)</span></span>
<span class="line"><span>cycling_protocol = load_cycling_protocol(; from_file_path = file_path_cycling)</span></span>
<span class="line"><span>model_settings = load_model_settings(; from_file_path = file_path_model)</span></span>
<span class="line"><span>simulation_settings = load_simulation_settings(; from_file_path = file_path_simulation)</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>########################################</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>model = LithiumIonBatteryModel(; model_settings);</span></span>
<span class="line"><span></span></span>
<span class="line"><span>sim = Simulation(model, cell_parameters, cycling_protocol; simulation_settings);</span></span>
<span class="line"><span>output = solve(sim)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>nothing # hide</span></span>
<span class="line"><span></span></span>
<span class="line"><span>states = output[:states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>t = [state[:Control][:ControllerCV].time for state in states]</span></span>
<span class="line"><span>E = [state[:Control][:Phi][1] for state in states]</span></span>
<span class="line"><span>I = [state[:Control][:Current][1] for state in states]</span></span>
<span class="line"><span>nothing # hide</span></span></code></pre></div><h2 id="Plot-the-results" tabindex="-1">Plot the results <a class="header-anchor" href="#Plot-the-results" aria-label="Permalink to &quot;Plot the results {#Plot-the-results}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>f = Figure(size = (1000, 400))</span></span>
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
<span class="line"><span>	markercolor = :black)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[1, 2],</span></span>
<span class="line"><span>	title = &quot;Current&quot;,</span></span>
<span class="line"><span>	xlabel = &quot;Time / s&quot;,</span></span>
<span class="line"><span>	ylabel = &quot;Current / A&quot;,</span></span>
<span class="line"><span>	xlabelsize = 25,</span></span>
<span class="line"><span>	ylabelsize = 25,</span></span>
<span class="line"><span>	xticklabelsize = 25,</span></span>
<span class="line"><span>	yticklabelsize = 25)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	I;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>f</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_cycle.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_cycle.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,10)]))}const d=s(p,[["render",l]]);export{m as __pageData,d as default};
