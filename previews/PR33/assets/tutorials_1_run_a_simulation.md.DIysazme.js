import{_ as a,c as n,o as l,aA as p}from"./chunks/framework.Bu1rAwjv.js";const i="/BattMo.jl/previews/PR33/assets/jrxsiir.C_s0Glu8.jpeg",e="/BattMo.jl/previews/PR33/assets/wlxsxzg.DwNI8z11.jpeg",E=JSON.parse('{"title":"How to run a simulation","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/1_run_a_simulation.md","filePath":"tutorials/1_run_a_simulation.md","lastUpdated":null}'),t={name:"tutorials/1_run_a_simulation.md"};function h(o,s,c,k,r,u){return l(),n("div",null,s[0]||(s[0]=[p(`<h1 id="How-to-run-a-simulation" tabindex="-1">How to run a simulation <a class="header-anchor" href="#How-to-run-a-simulation" aria-label="Permalink to &quot;How to run a simulation {#How-to-run-a-simulation}&quot;">​</a></h1><p>BattMo simulations repicate the voltage-current response of a cell. To run a Battmo simulation, the basic workflow is:</p><ul><li><p>Set up cell parameters</p></li><li><p>Set up a cycling protocol</p></li><li><p>Select a model</p></li><li><p>Prepare a simulation</p></li><li><p>Run the simulation</p></li><li><p>Inspect and visualize the outputs of the simulation</p></li></ul><p>To start, we load BattMo (battery models and simulations) and GLMakie (plotting).</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><p>BattMo stores cell parameters, cycling protocols and settings in a user-friendly JSON format to facilitate reuse. For our example, we read the cell parameter set from a NMC811 vs Graphite-SiOx cell whose parameters were determined in the <a href="https://doi.org/10.1149/1945-7111/ab9050" target="_blank" rel="noreferrer">Chen 2020 paper</a>. We also read an example cycling protocol for a simple Constant Current Discharge.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cell_parameters/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Chen2020_calibrated.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cycling_protocols/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCDischarge.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cycling)</span></span></code></pre></div><p>Next, we select the Lithium-Ion Battery Model with default model settings. A model can be thought as a mathematical implementation of the electrochemical and transport phenomena occuring in a real battery cell. The implementation consist of a system of partial differential equations and their corresponding parameters, constants and boundary conditions. The default Lithium-Ion Battery Model selected below corresponds to a basic P2D model, where neither current collectors nor thermal effects are considered.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>LithiumIonBatteryModel(&quot;1D Doyle-Fuller-Newman lithium-ion model&quot;, {</span></span>
<span class="line"><span>    &quot;UseDiffusionModel&quot; =&gt; &quot;PXD&quot;</span></span>
<span class="line"><span>    &quot;ModelGeometry&quot; =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>    &quot;UseRampUp&quot; =&gt; &quot;Generic&quot;</span></span>
<span class="line"><span>}, true)</span></span></code></pre></div><p>Then we setup a Simulation by passing the model, cell parameters and a cycling protocol. A Simulation can be thought as a procedure to predict how the cell responds to the cycling protocol, by solving the equations in the model using the cell parameters passed. We first prepare the simulation:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters, cycling_protocol);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>When the simulation is prepared, there are some validation checks happening in the background, which verify whether i) the cell parameters, cycling protocol and settings are sensible and complete to run a simulation. It is good practice to ensure that the Simulation has been properly configured by checking if has passed the validation procedure:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">is_valid</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>true</span></span></code></pre></div><p>Now we can run the simulation</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim;)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>[ Info: (&quot;par = &quot;, BattMo.CCPolicy{Union{Missing, Float64}}(&quot;discharging&quot;, 0.0, 0.0, 2.4, 4.1, missing))</span></span>
<span class="line"><span>[ Info: (&quot;control = &quot;, &quot;discharging&quot;)</span></span>
<span class="line"><span>[ Info: (&quot;I = &quot;, 2.545210901747287)</span></span>
<span class="line"><span>[ Info: (&quot;val = &quot;, 0.0)</span></span>
<span class="line"><span>[ Info: (&quot;con = &quot;, &quot;discharging&quot;)</span></span>
<span class="line"><span>Jutul: Simulating 2 hours, 12 minutes as 163 report steps</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.1539793353803605,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.15026764262255132,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.1011691080071095,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(1.1478683038111976,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.040160064334555,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.031855395414651,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.02072118873662,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.008812309701237,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(4.002831890268736,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.999785022219478,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9980427765681283,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9967148729395015,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9953193963319182,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9935664333194953,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.991272875696908,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9883423529533513,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.984751778037646,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.980530451478965,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.975740477927872,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.970461811477385,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9647816793673605,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.958787683697784,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9525626513640058,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9461820522914386,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9397123166120434,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.933210174507307,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9267226274778473,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9202873121892603,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.913933067281147,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.907680550633714,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.9015427820515933,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8955255106877815,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.88962734309996,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.883839646516957,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8781464043274587,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8725244584477,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.866944791543353,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8613753036509775,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8557846093053505,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.850145287183843,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.844435091355833,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.838636015394547,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8327321957893545,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8267076269178157,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8205441939522022,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.814220212111358,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.807709673259681,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.8009827956359827,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7940092709134503,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7867665119828025,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.779254678515596,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.771515140225131,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7636393336789276,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7557526152370047,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.74797571115353,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7403883085403353,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7330160739985527,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7258407414319605,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.718819899060165,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.7119050920266754,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.705053784959484,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.69823536710894,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.691432941318447,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.684642585971682,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6778712794683974,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.671134223028313,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6644520008316555,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.657847848940842,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.651345212355706,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6449657108338926,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6387275852784136,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.63264464934544,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6267257265731,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6209745165877885,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.615389809212466,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.6099659543995255,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.604693497629903,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.599559901267628,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5945502878419053,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5896481571548122,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5848360425902865,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5800960819489522,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5754104851910773,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5707618872830627,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5661335804805248,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.561509627390605,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.556874863319625,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.552214802338563,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.547515465099635,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.54276314760875,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.537944149851131,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.533044483045719,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5280495763791277,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.522944010496044,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5177113179650217,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5123339121891375,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5067932360384653,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.5010702559316695,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4951464537434456,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4890054620934845,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4826354097202548,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.476031856621165,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4692009071881387,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.462161781923616,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4549479785757584,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4476063297844473,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4401937800782396,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.43277235492417,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4254032730812316,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4181412639134785,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.4110299113628075,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.40409842505394,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3973598243933307,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3908102346684657,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3844288773915183,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3781783768901277,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.372005147117932,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.365839763513368,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3595972061404713,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3531765324310414,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3464589213994813,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3393024339850226,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3315326636925775,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3229237285234774,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.313182382851716,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3019328451529057,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2887339703506706,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2731573248405925,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2549342795932765,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2341163479039228,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.211148340395831,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.186785247344385,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1618665669721566,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.137042175328454,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.112563881561256,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.088216877013923,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0633616229815916,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.037024780430126,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0079678914501065,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.9747099209738725,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.935500443912844,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.888250502995114,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.8304267685767877,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.758905880013344,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.669791211492263,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.5581739690163556,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.417824148958525,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.2407719557934103,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.545210901747287,0.0,1.0)</span></span>
<span class="line"><span>╭────────────────┬───────────┬───────────────┬──────────╮</span></span>
<span class="line"><span>│ Iteration type │  Avg/step │  Avg/ministep │    Total │</span></span>
<span class="line"><span>│                │ 146 steps │ 146 ministeps │ (wasted) │</span></span>
<span class="line"><span>├────────────────┼───────────┼───────────────┼──────────┤</span></span>
<span class="line"><span>│ Newton         │   2.32877 │       2.32877 │  340 (0) │</span></span>
<span class="line"><span>│ Linearization  │   3.32877 │       3.32877 │  486 (0) │</span></span>
<span class="line"><span>│ Linear solver  │   2.32877 │       2.32877 │  340 (0) │</span></span>
<span class="line"><span>│ Precond apply  │       0.0 │           0.0 │    0 (0) │</span></span>
<span class="line"><span>╰────────────────┴───────────┴───────────────┴──────────╯</span></span>
<span class="line"><span>╭───────────────┬────────┬────────────┬────────╮</span></span>
<span class="line"><span>│ Timing type   │   Each │   Relative │  Total │</span></span>
<span class="line"><span>│               │     ms │ Percentage │      s │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Properties    │ 0.0332 │     0.57 % │ 0.0113 │</span></span>
<span class="line"><span>│ Equations     │ 1.0029 │    24.38 % │ 0.4874 │</span></span>
<span class="line"><span>│ Assembly      │ 0.4108 │     9.99 % │ 0.1996 │</span></span>
<span class="line"><span>│ Linear solve  │ 0.2928 │     4.98 % │ 0.0996 │</span></span>
<span class="line"><span>│ Linear setup  │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Precond apply │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Update        │ 0.1350 │     2.30 % │ 0.0459 │</span></span>
<span class="line"><span>│ Convergence   │ 0.2875 │     6.99 % │ 0.1397 │</span></span>
<span class="line"><span>│ Input/Output  │ 0.2254 │     1.65 % │ 0.0329 │</span></span>
<span class="line"><span>│ Other         │ 2.8910 │    49.16 % │ 0.9830 │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Total         │ 5.8806 │   100.00 % │ 1.9994 │</span></span>
<span class="line"><span>╰───────────────┴────────┴────────────┴────────╯</span></span></code></pre></div><p>Now we&#39;ll have a look into what the output entail. The ouput is of type NamedTuple and contains multiple dicts. Lets print the keys of each dict.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(output)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>(:states, :cellSpecifications, :reports, :inputparams, :extra)</span></span></code></pre></div><p>So we can see the the output contains state data, cell specifications, reports on the simulation, the input parameters of the simulation, and some extra data. The most important dicts, that we&#39;ll dive a bit deeper into, are the states and cell specifications. First let&#39;s see how the states output is structured.</p><h3 id="states" tabindex="-1">States <a class="header-anchor" href="#states" aria-label="Permalink to &quot;States&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">typeof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(states)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Vector{Dict{Symbol, Any}} (alias for Array{Dict{Symbol, Any}, 1})</span></span></code></pre></div><p>As we can see, the states output is a Vector that contains dicts.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(states)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>145-element LinearIndices{1, Tuple{Base.OneTo{Int64}}}:</span></span>
<span class="line"><span>   1</span></span>
<span class="line"><span>   2</span></span>
<span class="line"><span>   3</span></span>
<span class="line"><span>   4</span></span>
<span class="line"><span>   5</span></span>
<span class="line"><span>   6</span></span>
<span class="line"><span>   7</span></span>
<span class="line"><span>   8</span></span>
<span class="line"><span>   9</span></span>
<span class="line"><span>  10</span></span>
<span class="line"><span>   ⋮</span></span>
<span class="line"><span> 137</span></span>
<span class="line"><span> 138</span></span>
<span class="line"><span> 139</span></span>
<span class="line"><span> 140</span></span>
<span class="line"><span> 141</span></span>
<span class="line"><span> 142</span></span>
<span class="line"><span> 143</span></span>
<span class="line"><span> 144</span></span>
<span class="line"><span> 145</span></span></code></pre></div><p>In this case it consists of 77 dicts. Each dict represents a time step in the simulation and each time step stores quantities divided into battery component related group. This structure agrees with the overal model structure of BattMo.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">initial_state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(initial_state)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>KeySet for a Dict{Symbol, Any} with 5 entries. Keys:</span></span>
<span class="line"><span>  :Elyte</span></span>
<span class="line"><span>  :NeAm</span></span>
<span class="line"><span>  :substates</span></span>
<span class="line"><span>  :Control</span></span>
<span class="line"><span>  :PeAm</span></span></code></pre></div><p>So each time step contains quantities related to the electrolyte, the negative electrode active material, the cycling control, and the positive electrode active material. Lets print the stored quantities for each group.</p><p>Electrolyte keys:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(initial_state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>KeySet for a Dict{Symbol, Any} with 6 entries. Keys:</span></span>
<span class="line"><span>  :Charge</span></span>
<span class="line"><span>  :Mass</span></span>
<span class="line"><span>  :Diffusivity</span></span>
<span class="line"><span>  :Phi</span></span>
<span class="line"><span>  :Conductivity</span></span>
<span class="line"><span>  :C</span></span></code></pre></div><p>Negative electrode active material keys:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(initial_state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>KeySet for a Dict{Symbol, Any} with 6 entries. Keys:</span></span>
<span class="line"><span>  :Ocp</span></span>
<span class="line"><span>  :Cp</span></span>
<span class="line"><span>  :Cs</span></span>
<span class="line"><span>  :Charge</span></span>
<span class="line"><span>  :Temperature</span></span>
<span class="line"><span>  :Phi</span></span></code></pre></div><p>Positive electrode active material keys:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(initial_state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>KeySet for a Dict{Symbol, Any} with 6 entries. Keys:</span></span>
<span class="line"><span>  :Ocp</span></span>
<span class="line"><span>  :Cp</span></span>
<span class="line"><span>  :Cs</span></span>
<span class="line"><span>  :Charge</span></span>
<span class="line"><span>  :Temperature</span></span>
<span class="line"><span>  :Phi</span></span></code></pre></div><p>Control keys:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(initial_state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>KeySet for a Dict{Symbol, Any} with 3 entries. Keys:</span></span>
<span class="line"><span>  :Controller</span></span>
<span class="line"><span>  :Current</span></span>
<span class="line"><span>  :Phi</span></span></code></pre></div><h3 id="Cell-specifications" tabindex="-1">Cell specifications <a class="header-anchor" href="#Cell-specifications" aria-label="Permalink to &quot;Cell specifications {#Cell-specifications}&quot;">​</a></h3><p>Now lets see what quantities are stored within the cellSpecifications dict in the simulation output.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_specifications </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:cellSpecifications</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">keys</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cell_specifications)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>KeySet for a Dict{Any, Any} with 4 entries. Keys:</span></span>
<span class="line"><span>  &quot;NegativeElectrodeCapacity&quot;</span></span>
<span class="line"><span>  &quot;MaximumEnergy&quot;</span></span>
<span class="line"><span>  &quot;PositiveElectrodeCapacity&quot;</span></span>
<span class="line"><span>  &quot;Mass&quot;</span></span></code></pre></div><p>Let&#39;s say we want to plot the cell current and cell voltage over time. First we&#39;ll retrieve these three quantities from the output.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">t </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Controller</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">time </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">E </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">I </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Current</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span></code></pre></div><p>Now we can use GLMakie to create a plot. Lets first plot the cell voltage.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">400</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage / V&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	E;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+i+`" alt=""></p><p>And the cell current.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current / V&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	I;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+e+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/1_run_a_simulation.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/1_run_a_simulation.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',61)]))}const g=a(t,[["render",h]]);export{E as __pageData,g as default};
