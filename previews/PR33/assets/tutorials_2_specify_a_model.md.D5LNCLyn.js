import{_ as a,c as n,o as i,aA as e}from"./chunks/framework.Bu1rAwjv.js";const k=JSON.parse('{"title":"Setting Up a Custom Battery Model","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/2_specify_a_model.md","filePath":"tutorials/2_specify_a_model.md","lastUpdated":null}'),p={name:"tutorials/2_specify_a_model.md"};function t(l,s,o,h,c,d){return i(),n("div",null,s[0]||(s[0]=[e(`<h1 id="Setting-Up-a-Custom-Battery-Model" tabindex="-1">Setting Up a Custom Battery Model <a class="header-anchor" href="#Setting-Up-a-Custom-Battery-Model" aria-label="Permalink to &quot;Setting Up a Custom Battery Model {#Setting-Up-a-Custom-Battery-Model}&quot;">​</a></h1><p>In this tutorial, we’ll configure a custom battery model using BattMo, with a specific focus on SEI (Solid Electrolyte Interphase) growth within a P2D simulation framework.</p><h3 id="Load-BattMo-and-Model-Settings" tabindex="-1">Load BattMo and Model Settings <a class="header-anchor" href="#Load-BattMo-and-Model-Settings" aria-label="Permalink to &quot;Load BattMo and Model Settings {#Load-BattMo-and-Model-Settings}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span></code></pre></div><p>Let’s begin by loading the default model settings for a P2D simulation. This will return a ModelSettings object:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/model_settings/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P2D.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_model)</span></span></code></pre></div><p>We can inspect all current settings with:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">all</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 3 entries:</span></span>
<span class="line"><span>  &quot;UseDiffusionModel&quot; =&gt; &quot;PXD&quot;</span></span>
<span class="line"><span>  &quot;ModelGeometry&quot;     =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>  &quot;UseRampUp&quot;         =&gt; &quot;Generic&quot;</span></span></code></pre></div><p>By default, the &quot;UseSEIModel&quot; parameter is set to false. Since we want to observe SEI effects, we’ll enable it:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;UseSEIModel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">all</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 4 entries:</span></span>
<span class="line"><span>  &quot;UseDiffusionModel&quot; =&gt; &quot;PXD&quot;</span></span>
<span class="line"><span>  &quot;ModelGeometry&quot;     =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>  &quot;UseRampUp&quot;         =&gt; &quot;Generic&quot;</span></span>
<span class="line"><span>  &quot;UseSEIModel&quot;       =&gt; true</span></span></code></pre></div><h3 id="Initialize-the-Model" tabindex="-1">Initialize the Model <a class="header-anchor" href="#Initialize-the-Model" aria-label="Permalink to &quot;Initialize the Model {#Initialize-the-Model}&quot;">​</a></h3><p>Let’s now create the battery model using the modified settings:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>🔍 Validation of ModelSettings failed with 2 issues:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 1:</span></span>
<span class="line"><span>📍 Where:       [UseSEIModel]</span></span>
<span class="line"><span>🔢 Provided:    true</span></span>
<span class="line"><span>🔑 Rule:        type = string</span></span>
<span class="line"><span>🛠  Issue:       Expected type: string</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 2:</span></span>
<span class="line"><span>📍 Where:       [UseSEIModel]</span></span>
<span class="line"><span>🔢 Provided:    true</span></span>
<span class="line"><span>🔑 Rule:        enum = [&quot;Bolay&quot;]</span></span>
<span class="line"><span>🛠  Issue:       Value must be one of: Bolay</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>We can see that some warnings are given in the terminal. When setting up the model, the LithiumIonBatteryModel constructor runs a validation on the model_settings. In this case, because we set the &quot;UseSEIModel&quot; parameter to true, the validator provides a warning that we should define which SEI model we would like to use. If we ignore the warnings and pass the model to the Simulation constructor then we get an error:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cell_parameters/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;SEI_example.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cycling_protocols/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCCV.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters_sei </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cccv_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cycling)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters_sei, cccv_protocol)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Oops! Your Model object is not valid. 🛑</span></span>
<span class="line"><span></span></span>
<span class="line"><span>TIP: Validation happens when instantiating the Model object.</span></span>
<span class="line"><span>Check the warnings to see exactly where things went wrong. 🔍</span></span></code></pre></div><p>As expected, this results in an error because we haven&#39;t yet specified the SEI model type.</p><h3 id="Specify-SEI-Model-and-Rebuild" tabindex="-1">Specify SEI Model and Rebuild <a class="header-anchor" href="#Specify-SEI-Model-and-Rebuild" aria-label="Permalink to &quot;Specify SEI Model and Rebuild {#Specify-SEI-Model-and-Rebuild}&quot;">​</a></h3><p>To resolve this, we’ll explicitly set the SEI model to &quot;Bolay&quot;:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;SEIModel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bolay&quot;</span></span></code></pre></div><p>Now rebuild the model:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>🔍 Validation of ModelSettings failed with 2 issues:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 1:</span></span>
<span class="line"><span>📍 Where:       [UseSEIModel]</span></span>
<span class="line"><span>🔢 Provided:    true</span></span>
<span class="line"><span>🔑 Rule:        type = string</span></span>
<span class="line"><span>🛠  Issue:       Expected type: string</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Issue 2:</span></span>
<span class="line"><span>📍 Where:       [UseSEIModel]</span></span>
<span class="line"><span>🔢 Provided:    true</span></span>
<span class="line"><span>🔑 Rule:        enum = [&quot;Bolay&quot;]</span></span>
<span class="line"><span>🛠  Issue:       Value must be one of: Bolay</span></span>
<span class="line"><span></span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>Run the Simulation Now we can setup the simulation and run it.</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>sim = Simulation(model, cell_parameters_sei, cccv_protocol)</span></span>
<span class="line highlighted"><span>output = solve(sim);</span></span>
<span class="line"><span>nothing # hide</span></span></code></pre></div><h2 id="Plot-of-voltage-and-current" tabindex="-1">Plot of voltage and current <a class="header-anchor" href="#Plot-of-voltage-and-current" aria-label="Permalink to &quot;Plot of voltage and current {#Plot-of-voltage-and-current}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>states = output[:states]</span></span>
<span class="line highlighted"><span></span></span>
<span class="line"><span>t = [state[:Control][:Controller].time for state in states]</span></span>
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
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/2_specify_a_model.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/2_specify_a_model.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,37)]))}const u=a(p,[["render",t]]);export{k as __pageData,u as default};
