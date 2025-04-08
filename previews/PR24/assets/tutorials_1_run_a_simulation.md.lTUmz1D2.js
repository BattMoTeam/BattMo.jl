import{_ as a,c as n,o as e,aA as i}from"./chunks/framework.DCHMZPbW.js";const u=JSON.parse('{"title":"How to run a model","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/1_run_a_simulation.md","filePath":"tutorials/1_run_a_simulation.md","lastUpdated":null}'),t={name:"tutorials/1_run_a_simulation.md"};function p(l,s,o,c,h,d){return e(),n("div",null,s[0]||(s[0]=[i(`<h1 id="How-to-run-a-model" tabindex="-1">How to run a model <a class="header-anchor" href="#How-to-run-a-model" aria-label="Permalink to &quot;How to run a model {#How-to-run-a-model}&quot;">​</a></h1><p>Lets how we can run a model in BattMo in the most simple way. We ofcourse start with importing the BattMo package.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><p>BattMo utilizes the JSON format to store all the input parameters of a model in a clear and intuitive way. We can use one of the default parameter sets, for example the Li-ion parameter set that has been created from the <a href="https://doi.org/10.1149/1945-7111/ab9050" target="_blank" rel="noreferrer">Chen 2020 paper</a>.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/cell_parameters/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cell_parameter_set_chen2020_calibrated.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/cycling_protocols/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCDischarge.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> read_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> read_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path_cycling)</span></span></code></pre></div><p>We instantiate a Lithium-ion battery model with default model settings</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>LithiumIonBatteryModel(&quot;1D Doyle-Fuller-Newman lithium-ion model&quot;, ModelSettings(Dict{String, Any}(&quot;TimeStepDuration&quot; =&gt; 50, &quot;GridPointsPositiveElectrodeActiveMaterial&quot; =&gt; 10, &quot;GridPointsSeparator&quot; =&gt; 10, &quot;GridPointsNegativeElectrodeActiveMaterial&quot; =&gt; 10, &quot;UseThermalModel&quot; =&gt; false, &quot;UseCurrentCollectors&quot; =&gt; false, &quot;GridPointsPositiveElectrode&quot; =&gt; 10, &quot;GridPointsNegativeElectrode&quot; =&gt; 10, &quot;ModelGeometry&quot; =&gt; &quot;1D&quot;, &quot;Grid&quot; =&gt; Any[]…)), true)</span></span></code></pre></div><p>Then we setup a Simulation object to validate our parameter sets to the intsnatiated battery model.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters, cycling_protocol);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>🔍 Validation of CellParameters failed with 6 issues:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 1:</span></span>
<span class="line"><span>📍 Where:       [Electrolyte][ThermalConductivity]</span></span>
<span class="line"><span>🔢 Provided:    0.099</span></span>
<span class="line"><span>🔑 Rule:        minimum = 0.1</span></span>
<span class="line"><span>🛠  Issue:       Value is below the minimum allowed (0.1)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 2:</span></span>
<span class="line"><span>📍 Where:       [Cell][DeviceSurfaceArea]</span></span>
<span class="line"><span>🔢 Provided:    0.0053</span></span>
<span class="line"><span>🔑 Rule:        minimum = 0.01</span></span>
<span class="line"><span>🛠  Issue:       Value is below the minimum allowed (0.01)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 3:</span></span>
<span class="line"><span>📍 Where:       [Cell][ElectrodeLength]</span></span>
<span class="line"><span>🔢 Provided:    1.58</span></span>
<span class="line"><span>🔑 Rule:        maximum = 0.5</span></span>
<span class="line"><span>🛠  Issue:       Value exceeds maximum allowed (0.5)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 4:</span></span>
<span class="line"><span>📍 Where:       [Cell][NominalCapacity]</span></span>
<span class="line"><span>🔢 Provided:    4.8</span></span>
<span class="line"><span>🔑 Rule:        minimum = 100</span></span>
<span class="line"><span>🛠  Issue:       Value is below the minimum allowed (100)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 5:</span></span>
<span class="line"><span>📍 Where:       [PositiveElectrode][ActiveMaterial][MaximumConcentration]</span></span>
<span class="line"><span>🔢 Provided:    63104.0</span></span>
<span class="line"><span>🔑 Rule:        maximum = 60000.0</span></span>
<span class="line"><span>🛠  Issue:       Value exceeds maximum allowed (60000.0)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 6:</span></span>
<span class="line"><span>📍 Where:       [PositiveElectrode][ConductiveAdditive][SpecificHeatCapacity]</span></span>
<span class="line"><span>🔢 Provided:    300.0</span></span>
<span class="line"><span>🔑 Rule:        minimum = 500.0</span></span>
<span class="line"><span>🛠  Issue:       Value is below the minimum allowed (500.0)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>check if the Simulation object is valid</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">is_valid</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>false</span></span></code></pre></div><p>Now we can solve the simulation</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>output = solve(sim)</span></span></code></pre></div><p>Now we&#39;ll have a look into what the output entail. The ouput is of type NamedTuple and contains multiple dicts. Lets print the keys of each dict.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>keys(output)</span></span></code></pre></div><p>So we can see the the output contains state data, cell specifications, reports on the simulation, the input parameters of the simulation, and some extra data. The most important dicts, that we&#39;ll dive a bit deeper into, are the states and cell specifications. First let&#39;s see how the states output is structured.</p><h3 id="states" tabindex="-1">States <a class="header-anchor" href="#states" aria-label="Permalink to &quot;States&quot;">​</a></h3><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>states = output[:states]</span></span>
<span class="line"><span>typeof(states)</span></span></code></pre></div><p>As we can see, the states output is a Vector that contains dicts.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>keys(states)</span></span></code></pre></div><p>In this case it consists of 77 dicts. Each dict represents a time step in the simulation and each time step stores quantities divided into battery component related group. This structure agrees with the overal model structure of BattMo.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>initial_state = states[1]</span></span>
<span class="line"><span>keys(initial_state)</span></span></code></pre></div><p>So each time step contains quantities related to the electrolyte, the negative electrode active material, the cycling control, and the positive electrode active material. Lets print the stored quantities for each group.</p><p>Electrolyte keys:</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>keys(initial_state[:Elyte])</span></span></code></pre></div><p>Negative electrode active material keys:</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>keys(initial_state[:NeAm])</span></span></code></pre></div><p>Positive electrode active material keys:</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>keys(initial_state[:PeAm])</span></span></code></pre></div><p>Control keys:</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>keys(initial_state[:Control])</span></span></code></pre></div><h3 id="Cell-specifications" tabindex="-1">Cell specifications <a class="header-anchor" href="#Cell-specifications" aria-label="Permalink to &quot;Cell specifications {#Cell-specifications}&quot;">​</a></h3><p>Now lets see what quantities are stored within the cellSpecifications dict in the simulation output.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>cell_specifications = output[:cellSpecifications];</span></span>
<span class="line"><span>keys(cell_specifications)</span></span></code></pre></div><p>Let&#39;s say we want to plot the cell current and cell voltage over time. First we&#39;ll retrieve these three quantities from the output.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>states = output[:states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>t = [state[:Control][:ControllerCV].time for state in states]</span></span>
<span class="line"><span>E = [state[:Control][:Phi][1] for state in states]</span></span>
<span class="line"><span>I = [state[:Control][:Current][1] for state in states]</span></span>
<span class="line"><span>nothing # hide</span></span></code></pre></div><p>Now we can use GLMakie to create a plot. Lets first plot the cell voltage.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>f = Figure(size = (1000, 400))</span></span>
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
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	E;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>f # hide</span></span></code></pre></div><p>And the cell current.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line highlighted"><span>ax = Axis(f[1, 2],</span></span>
<span class="line"><span>	title = &quot;Current&quot;,</span></span>
<span class="line"><span>	xlabel = &quot;Time / s&quot;,</span></span>
<span class="line"><span>	ylabel = &quot;Current / V&quot;,</span></span>
<span class="line"><span>	xlabelsize = 25,</span></span>
<span class="line"><span>	ylabelsize = 25,</span></span>
<span class="line"><span>	xticklabelsize = 25,</span></span>
<span class="line"><span>	yticklabelsize = 25,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>	t,</span></span>
<span class="line"><span>	I;</span></span>
<span class="line"><span>	linewidth = 4,</span></span>
<span class="line"><span>	markersize = 10,</span></span>
<span class="line"><span>	marker = :cross,</span></span>
<span class="line"><span>	markercolor = :black,</span></span>
<span class="line"><span>)</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/1_run_a_simulation.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/1_run_a_simulation.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,47)]))}const g=a(t,[["render",p]]);export{u as __pageData,g as default};
