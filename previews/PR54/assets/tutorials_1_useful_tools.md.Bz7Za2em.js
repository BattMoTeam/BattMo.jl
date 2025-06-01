import{_ as a,c as n,o as e,aA as i}from"./chunks/framework.CyRZrN79.js";const d=JSON.parse('{"title":"Useful Tools in BattMo","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/1_useful_tools.md","filePath":"tutorials/1_useful_tools.md","lastUpdated":null}'),p={name:"tutorials/1_useful_tools.md"};function t(l,s,o,r,c,h){return e(),n("div",null,s[0]||(s[0]=[i(`<h1 id="Useful-Tools-in-BattMo" tabindex="-1">Useful Tools in BattMo <a class="header-anchor" href="#Useful-Tools-in-BattMo" aria-label="Permalink to &quot;Useful Tools in BattMo {#Useful-Tools-in-BattMo}&quot;">​</a></h1><p>Before we dive into how to set up and run simulations, it&#39;s helpful to get familiar with some of the built-in tools provided by <strong>BattMo</strong>. These utilities can save time and improve your workflow, and we&#39;ll be using most of them throughout the tutorials.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span></code></pre></div><h2 id="Saving-Default-Parameter-Sets-Locally" tabindex="-1">Saving Default Parameter Sets Locally <a class="header-anchor" href="#Saving-Default-Parameter-Sets-Locally" aria-label="Permalink to &quot;Saving Default Parameter Sets Locally {#Saving-Default-Parameter-Sets-Locally}&quot;">​</a></h2><p>BattMo includes several default parameter sets that you can use as a starting point. If you want to explore or customize them, you can easily save them to your local disk using:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> pwd</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">folder_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;default_parameter_sets&quot;</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">generate_default_parameter_files</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(path, folder_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>🛠 JSON files successfully written! Path:</span></span>
<span class="line"><span>	/home/runner/work/BattMo.jl/BattMo.jl/docs/build/tutorials/default_parameter_sets</span></span></code></pre></div><p>This will create a folder in your current working directory containing the default parameter files.</p><h2 id="Viewing-Parameter-Set-Information" tabindex="-1">Viewing Parameter Set Information <a class="header-anchor" href="#Viewing-Parameter-Set-Information" aria-label="Permalink to &quot;Viewing Parameter Set Information {#Viewing-Parameter-Set-Information}&quot;">​</a></h2><p>To quickly inspect which default parameter sets are included with BattMo and what each contains, you can use:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_default_input_sets_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span></span></span>
<span class="line"><span>====================================================================================================</span></span>
<span class="line"><span>📋 Overview of Available Default Sets</span></span>
<span class="line"><span>====================================================================================================</span></span>
<span class="line"><span></span></span>
<span class="line"><span>📁 cell_parameters:         Chen2020, SEI_example, Xu2015, tabular_data_example</span></span>
<span class="line"><span>📁 cycling_protocols:       CCCV, CCCharge, CCCycling, CCDischarge, user_defined_current_function</span></span>
<span class="line"><span>📁 model_settings:          P2D, P4D_pouch</span></span>
<span class="line"><span>📁 simulation_settings:     P2D, P4D_pouch</span></span>
<span class="line"><span></span></span>
<span class="line"><span>====================================================================================================</span></span>
<span class="line"><span>📖 Detailed Descriptions</span></span>
<span class="line"><span>====================================================================================================</span></span>
<span class="line"><span></span></span>
<span class="line"><span>📂 cell_parameters</span></span>
<span class="line"><span>----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span>Chen2020</span></span>
<span class="line"><span>🔹 Cell name:       	LG INR 21700 M50</span></span>
<span class="line"><span>🔹 Cell case:       	Cylindrical</span></span>
<span class="line"><span>🔹 Source:          	\x1B]8;;https://doi.org/10.1149/1945-7111/ab9050\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span>🔹 Suitable for:</span></span>
<span class="line"><span>   • CurrentCollectors:  Generic</span></span>
<span class="line"><span>   • RampUp:             Sinusoidal</span></span>
<span class="line"><span>   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span>   • ModelFramework:     P2D</span></span>
<span class="line"><span>🔹 Description:     	Parameter set of a cylindrical 21700 commercial cell (LGM50), for an electrochemical pseudo-two-dimensional (P2D) model, after calibration.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>SEI_example</span></span>
<span class="line"><span>🔹 Cell name:</span></span>
<span class="line"><span>🔹 Cell case:       	Pouch</span></span>
<span class="line"><span>🔹 Suitable for:</span></span>
<span class="line"><span>   • CurrentCollectors:  Generic</span></span>
<span class="line"><span>   • SEIModel:           Bolay</span></span>
<span class="line"><span>   • RampUp:             Sinusoidal</span></span>
<span class="line"><span>   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span>   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span>🔹 Description:     	Parameter set to test SEI simulations. Obtained from the Julia repository but with unknown source.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>Xu2015</span></span>
<span class="line"><span>🔹 Cell name:       	LP2770120</span></span>
<span class="line"><span>🔹 Cell case:       	Pouch</span></span>
<span class="line"><span>🔹 Source:          	\x1B]8;;https://doi.org/10.1016/j.energy.2014.11.073\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span>🔹 Suitable for:</span></span>
<span class="line"><span>   • CurrentCollectors:  Generic</span></span>
<span class="line"><span>   • RampUp:             Sinusoidal</span></span>
<span class="line"><span>   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span>   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span>🔹 Description:     	Parameter set of a commercial Type LP2770120 prismatic LiFePO4/graphite cell, for an electrochemical pseudo-two-dimensional (P2D) model.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>tabular_data_example</span></span>
<span class="line"><span>🔹 Cell name:</span></span>
<span class="line"><span>🔹 Cell case:       	3D-demo</span></span>
<span class="line"><span>🔹 Suitable for:</span></span>
<span class="line"><span>   • CurrentCollectors:  Generic</span></span>
<span class="line"><span>   • SEIModel:           Bolay</span></span>
<span class="line"><span>   • RampUp:             Sinusoidal</span></span>
<span class="line"><span>   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span>   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span>🔹 Description:     	Parameter set to test SEI simulations. Obtained from the Julia repository but with unknown source.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>📂 cycling_protocols</span></span>
<span class="line"><span>----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span>CCCV</span></span>
<span class="line"><span>🔹 Description:     	Parameter set for a constant current constant voltage cyling protocol.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>CCCharge</span></span>
<span class="line"><span>🔹 Description:     	Parameter set for a constant current charging protocol.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>CCCycling</span></span>
<span class="line"><span>🔹 Description:     	Parameter set for a constant current cycling protocol.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>CCDischarge</span></span>
<span class="line"><span>🔹 Description:     	Parameter set for a constant current discharging protocol.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>user_defined_current_function</span></span>
<span class="line"><span>🔹 Description:     	Parameter set that shows an example of how to include a user defined function in the cycling protocol parameters.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>📂 model_settings</span></span>
<span class="line"><span>----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span>P2D</span></span>
<span class="line"><span>🔹 Description:     	Default model settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>P4D_pouch</span></span>
<span class="line"><span>🔹 Description:     	Default model settings for a P4D pouch simulation including a current ramp up, current collectors.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>📂 simulation_settings</span></span>
<span class="line"><span>----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span>P2D</span></span>
<span class="line"><span>🔹 Suitable for:</span></span>
<span class="line"><span>   • SEIModel:           Bolay</span></span>
<span class="line"><span>   • RampUp:             Sinusoidal</span></span>
<span class="line"><span>   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span>   • ModelFramework:     P2D</span></span>
<span class="line"><span>🔹 Description:     	Default simulation settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.</span></span>
<span class="line"><span></span></span>
<span class="line"><span>P4D_pouch</span></span>
<span class="line"><span>🔹 Suitable for:</span></span>
<span class="line"><span>   • SEIModel:           Bolay</span></span>
<span class="line"><span>   • RampUp:             Sinusoidal</span></span>
<span class="line"><span>   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span>   • CurrentCollector:   Generic</span></span>
<span class="line"><span>   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span>🔹 Description:     	Default simulation settings for a P4D pouch simulation including a current ramp up, current collectors.</span></span></code></pre></div><h2 id="Inspecting-Individual-Parameters" tabindex="-1">Inspecting Individual Parameters <a class="header-anchor" href="#Inspecting-Individual-Parameters" aria-label="Permalink to &quot;Inspecting Individual Parameters {#Inspecting-Individual-Parameters}&quot;">​</a></h2><p>If you&#39;re unsure how a specific parameter should be defined or what it represents, you can print detailed information about it. For example:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;OpenCircuitPotential&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_parameter_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>================================================================================</span></span>
<span class="line"><span>ℹ️  Parameter Information</span></span>
<span class="line"><span>================================================================================</span></span>
<span class="line"><span>🔹 Name:         	OpenCircuitPotential</span></span>
<span class="line"><span>🔹 Description:		The open-circuit potential of the active material under a given intercalant stoichimetry and temperature.</span></span>
<span class="line"><span>🔹 Type:         	String, Dict{String, Vector}, Real</span></span>
<span class="line"><span>🔹 Unit:         	V</span></span>
<span class="line"><span>🔹 Documentation:	\x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/simulation_dependent_input\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span>🔹 Ontology link:	\x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_9c657fdc_b9d3_4964_907c_f9a6e8c5f52b\x1B\\visit\x1B]8;;\x1B\\</span></span></code></pre></div><p>Another example</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;ModelFramework&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_parameter_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>❌ No parameters found matching: ModelFramework</span></span></code></pre></div><p>This is especially useful when building or editing custom parameter sets.</p><h2 id="Listing-Available-Submodels" tabindex="-1">Listing Available Submodels <a class="header-anchor" href="#Listing-Available-Submodels" aria-label="Permalink to &quot;Listing Available Submodels {#Listing-Available-Submodels}&quot;">​</a></h2><p>BattMo supports a modular submodel architecture. To view all available submodels you can integrate into your simulation, run:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_submodels_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>No submodel parameters found.</span></span></code></pre></div><h2 id="Write-a-parameter-set-object-to-a-JSON-file" tabindex="-1">Write a parameter set object to a JSON file <a class="header-anchor" href="#Write-a-parameter-set-object-to-a-JSON-file" aria-label="Permalink to &quot;Write a parameter set object to a JSON file {#Write-a-parameter-set-object-to-a-JSON-file}&quot;">​</a></h2><p>You can use the following function to save your ParameterSet object to a JSON file:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;path_to_json_file/file.json&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> CellParameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;NegativeElectrode&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;ElectrodeCoating&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Thickness&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 100e-6</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">write_to_json_file</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path, parameter_set)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>An error occurred while writing to the file: SystemError(&quot;opening file \\&quot;path_to_json_file/file.json\\&quot;&quot;, 2, nothing)</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/1_useful_tools.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/1_useful_tools.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,32)]))}const g=a(p,[["render",t]]);export{d as __pageData,g as default};
