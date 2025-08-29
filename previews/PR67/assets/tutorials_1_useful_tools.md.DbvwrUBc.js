import{_ as i,c as e,o as a,aA as n}from"./chunks/framework.BCCeShPn.js";const t="/BattMo.jl/previews/PR67/assets/lmwjfie.CVzjx1iG.jpeg",d=JSON.parse('{"title":"Useful Tools in BattMo","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/1_useful_tools.md","filePath":"tutorials/1_useful_tools.md","lastUpdated":null}'),l={name:"tutorials/1_useful_tools.md"};function p(h,s,o,k,r,c){return a(),e("div",null,[...s[0]||(s[0]=[n(`<h1 id="Useful-Tools-in-BattMo" tabindex="-1">Useful Tools in BattMo <a class="header-anchor" href="#Useful-Tools-in-BattMo" aria-label="Permalink to &quot;Useful Tools in BattMo {#Useful-Tools-in-BattMo}&quot;">​</a></h1><p>Before we dive into how to set up and run simulations, it&#39;s helpful to get familiar with some of the built-in tools provided by <strong>BattMo</strong>. These utilities can save time and improve your workflow, and we&#39;ll be using most of them throughout the tutorials.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span></code></pre></div><h2 id="Saving-Default-Parameter-Sets-Locally" tabindex="-1">Saving Default Parameter Sets Locally <a class="header-anchor" href="#Saving-Default-Parameter-Sets-Locally" aria-label="Permalink to &quot;Saving Default Parameter Sets Locally {#Saving-Default-Parameter-Sets-Locally}&quot;">​</a></h2><p>BattMo includes several default parameter sets that you can use as a starting point. If you want to explore or customize them, you can easily save them to your local disk using:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> pwd</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">folder_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;default_parameter_sets&quot;</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">generate_default_parameter_files</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(path, folder_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🛠 JSON files successfully written! Path:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">	/home/runner/work/BattMo.jl/BattMo.jl/docs/build/tutorials/default_parameter_sets</span></span></code></pre></div><p>This will create a folder in your current working directory containing the default parameter files.</p><h2 id="Viewing-Parameter-Set-Information" tabindex="-1">Viewing Parameter Set Information <a class="header-anchor" href="#Viewing-Parameter-Set-Information" aria-label="Permalink to &quot;Viewing Parameter Set Information {#Viewing-Parameter-Set-Information}&quot;">​</a></h2><p>To quickly inspect which default parameter sets are included with BattMo and what each contains, you can use:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_default_input_sets_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📋 Overview of Available Default Sets</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 cell_parameters:         Chayambuka2022, Chen2020, Xu2015</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 cycling_protocols:       CCCV, CCCharge, CCCycling, CCDischarge, user_defined_current_function</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 model_settings:          P2D, P4D_cylindrical, P4D_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 simulation_settings:     P2D, P4D_cylindrical, P4D_pouch</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📖 Detailed Descriptions</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 cell_parameters</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Chayambuka2022</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell name:       	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell case:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Source:          	\x1B]8;;(Invalid metadata format)\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a Sodium ion cell based on Chayambuka et al. The positive electrode open circuit potential has been retrieved from a [COMSOL example](https://www.comsol.com/model/1d-isothermal-sodium-ion-battery-117341).</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Chen2020</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell name:       	LG INR 21700 M50</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell case:       	Cylindrical</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Source:          	\x1B]8;;https://doi.org/10.1149/1945-7111/ab9050\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • CurrentCollectors:  Generic</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • SEIModel:           Bolay</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set of a cylindrical 21700 commercial cell (LGM50), for an electrochemical pseudo-two-dimensional (P2D) model, after calibration. SEI parameters are from Bolay2022: https://doi.org/10.1016/j.powera.2022.100083 .</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Xu2015</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell name:       	LP2770120</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell case:       	Pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Source:          	\x1B]8;;https://doi.org/10.1016/j.energy.2014.11.073\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • CurrentCollectors:  Generic</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set of a commercial Type LP2770120 prismatic LiFePO4/graphite cell, for an electrochemical pseudo-two-dimensional (P2D) model.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 cycling_protocols</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">CCCV</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current constant voltage cyling protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">CCCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current charging protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">CCCycling</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current cycling protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">CCDischarge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current discharging protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">user_defined_current_function</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set that shows an example of how to include a user defined function in the cycling protocol parameters.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 model_settings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default model settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">P4D_cylindrical</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default model settings for a P4D cylindrical cell with a current ramp up.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">P4D_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default model settings for a P4D pouch simulation including a current ramp up, current collectors.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 simulation_settings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • SEIModel:           Bolay</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default simulation settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">P4D_cylindrical</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">P4D_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • SEIModel:           Bolay</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • CurrentCollector:   Generic</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default simulation settings for a P4D pouch simulation including a current ramp up, current collectors.</span></span></code></pre></div><h2 id="Inspecting-Individual-Parameters" tabindex="-1">Inspecting Individual Parameters <a class="header-anchor" href="#Inspecting-Individual-Parameters" aria-label="Permalink to &quot;Inspecting Individual Parameters {#Inspecting-Individual-Parameters}&quot;">​</a></h2><p>If you&#39;re unsure how a specific parameter should be defined or what it represents, you can print detailed information about it. For example, for cell parameters and cycling protocol parameters:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;OpenCircuitPotential&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_parameter_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Parameter Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	OpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		The open-circuit potential of the active material under a given intercalant stoichimetry and temperature.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String, Dict{String, Vector}, Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Unit:         	V</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	\x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/simulation_dependent_input\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	\x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_9c657fdc_b9d3_4964_907c_f9a6e8c5f52b\x1B\\visit\x1B]8;;\x1B\\</span></span></code></pre></div><p>An example for model or simulation settings:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;ModelFramework&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_setting_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Setting Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Name:         	ModelFramework</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:		Framework defining the dimensionality of the electrochemical model. Examples: &quot;P2D&quot;, &quot;P4D Pouch&quot;.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Type:         	String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Options:      	P2D, P4D Pouch, P4D Cylindrical</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Documentation:	\x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Ontology link:	\x1B]8;;https://w3id.org/emmo/domain/battery#battery_b1921f7b_afac_465a_a275_26f929f7f936\x1B\\visit\x1B]8;;\x1B\\</span></span></code></pre></div><p>An example for output variables:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Concenctration&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_output_variable_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">❌ No variables found matching: Concenctration</span></span></code></pre></div><p>This is especially useful when building or editing custom parameter sets.</p><h2 id="Listing-Available-Submodels" tabindex="-1">Listing Available Submodels <a class="header-anchor" href="#Listing-Available-Submodels" aria-label="Permalink to &quot;Listing Available Submodels {#Listing-Available-Submodels}&quot;">​</a></h2><p>BattMo supports a modular submodel architecture. To view all available submodels you can integrate into your simulation, run:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_submodels_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Submodels Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Parameter                     Options                       Documentation</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">--------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">CurrentCollectors             Generic                       -</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">SEIModel                      Bolay                         \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/sei_model\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ButlerVolmer                  Generic, Chayambuka           \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">RampUp                        Sinusoidal                    \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/ramp_up\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">TransportInSolid              FullDiffusion                 -</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ModelFramework                P2D, P4D Pouch, P4D Cylindrical\x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\x1B\\visit\x1B]8;;\x1B\\</span></span></code></pre></div><h2 id="Write-a-parameter-set-object-to-a-JSON-file" tabindex="-1">Write a parameter set object to a JSON file <a class="header-anchor" href="#Write-a-parameter-set-object-to-a-JSON-file" aria-label="Permalink to &quot;Write a parameter set object to a JSON file {#Write-a-parameter-set-object-to-a-JSON-file}&quot;">​</a></h2><p>You can use the following function to save your ParameterSet object to a JSON file:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;path_to_json_file/file.json&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> CellParameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;NegativeElectrode&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;ElectrodeCoating&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Thickness&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 100e-6</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">write_to_json_file</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path, parameter_set)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">An error occurred while writing to the file: SystemError(&quot;opening file \\&quot;path_to_json_file/file.json\\&quot;&quot;, 2, nothing)</span></span></code></pre></div><h2 id="Get-quick-information-on-a-cell-parameter-set" tabindex="-1">Get quick information on a cell parameter set <a class="header-anchor" href="#Get-quick-information-on-a-cell-parameter-set" aria-label="Permalink to &quot;Get quick information on a cell parameter set {#Get-quick-information-on-a-cell-parameter-set}&quot;">​</a></h2><p>Let&#39;s load a default cell parameter set.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Chen2020&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">{</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Electrolyte&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;TransferenceNumber&quot; =&gt; 0.2594</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Description&quot; =&gt; &quot;1 mol/l LiPF6 with ethylene carbonate (EC): ethyl methyl carbonate (EMC) (3:7, V:V)&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;DiffusionCoefficient&quot; =&gt; &quot;8.794*10^(-11)*(c/1000)^2 - 3.972*10^(-10)*(c/1000) + 4.862*10^(-10)&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;IonicConductivity&quot; =&gt; &quot;0.1297*(c/1000)^3 - 2.51*(c/1000)^(1.5) + 3.329*(c/1000)&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Density&quot; =&gt; 1200</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ChargeNumber&quot; =&gt; 1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Concentration&quot; =&gt; 1000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Cell&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;NominalVoltage&quot; =&gt; 3.71</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;InnerRadius&quot; =&gt; 0.002</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ElectrodeGeometricSurfaceArea&quot; =&gt; 0.1027</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Height&quot; =&gt; 0.065</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;NominalCapacity&quot; =&gt; 4.8</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Name&quot; =&gt; &quot;LG INR 21700 M50&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Case&quot; =&gt; &quot;Cylindrical&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;OuterRadius&quot; =&gt; 0.021</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Metadata&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Description&quot; =&gt; &quot;Parameter set of a cylindrical 21700 commercial cell (LGM50), for an electrochemical pseudo-two-dimensional (P2D) model, after calibration. SEI parameters are from Bolay2022: https://doi.org/10.1016/j.powera.2022.100083 .&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Source&quot; =&gt; &quot;https://doi.org/10.1149/1945-7111/ab9050&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Models&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;CurrentCollectors&quot; =&gt; &quot;Generic&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;SEIModel&quot; =&gt; &quot;Bolay&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;RampUp&quot; =&gt; &quot;Sinusoidal&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TransportInSolid&quot; =&gt; &quot;FullDiffusion&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ModelFramework&quot; =&gt; &quot;P2D&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Title&quot; =&gt; &quot;Chen2020&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;PositiveElectrode&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ActivationEnergyOfDiffusion&quot; =&gt; 5000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;NumberOfElectronsTransfered&quot; =&gt; 1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.9084</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;OpenCircuitPotential&quot; =&gt; &quot;-0.8090 * (c/cmax) + 4.4875 - 0.0428 * tanh(18.5138*((c/cmax) - 0.5542)) - 17.7326 * tanh(15.7890*((c/cmax) - 0.3117)) + 17.5842 * tanh(15.9308*((c/cmax) - 0.3120))&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ReactionRateConstant&quot; =&gt; 3.545e-11</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 1.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.27</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ActivationEnergyOfReaction&quot; =&gt; 17800.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MaximumConcentration&quot; =&gt; 63104.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;VolumetricSurfaceArea&quot; =&gt; 383959.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;NMC811&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;DiffusionCoefficient&quot; =&gt; 4.0e-15</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ParticleRadius&quot; =&gt; 5.22e-6</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 4950</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.18</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ChargeTransferCoefficient&quot; =&gt; 0.5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ElectrodeCoating&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;BruggemanCoefficient&quot; =&gt; 1.5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;EffectiveDensity&quot; =&gt; 3292</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 7.56e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 1780.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 100</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Aluminum&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabFractions&quot; =&gt; Any[0.5]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabWidth&quot; =&gt; 0.001</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 1.63e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 2700</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 5.96e7</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 1800.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 100</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Separator&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Description&quot; =&gt; &quot;Ceramic-coated Polyolefin&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Density&quot; =&gt; 946</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;BruggemanCoefficient&quot; =&gt; 1.5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Thickness&quot; =&gt; 1.2e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Porosity&quot; =&gt; 0.47</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;NegativeElectrode&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Interphase&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;EC-based SEI, from Bolay2022.&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicDiffusionCoefficient&quot; =&gt; 1.6e-12</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;InterstitialConcentration&quot; =&gt; 0.015</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;InitialThickness&quot; =&gt; 1.0e-8</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;IonicConductivity&quot; =&gt; 1.0e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficient&quot; =&gt; 2</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;InitialPotentialDrop&quot; =&gt; 0.5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MolarVolume&quot; =&gt; 9.586e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ActivationEnergyOfDiffusion&quot; =&gt; 5000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;NumberOfElectronsTransfered&quot; =&gt; 1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.0279</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;OpenCircuitPotential&quot; =&gt; &quot;1.9793 * exp(-39.3631*(c/cmax)) + 0.2482 - 0.0909 * tanh(29.8538*((c/cmax) - 0.1234)) - 0.04478 * tanh(14.9159*((c/cmax) - 0.2769)) - 0.0205 * tanh(30.4444*((c/cmax) - 0.6103))&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ReactionRateConstant&quot; =&gt; 6.716e-12</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 1.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.9014</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ActivationEnergyOfReaction&quot; =&gt; 35000</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MaximumConcentration&quot; =&gt; 33133.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;VolumetricSurfaceArea&quot; =&gt; 383959.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Graphite-SiOx&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;DiffusionCoefficient&quot; =&gt; 3.3e-14</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ParticleRadius&quot; =&gt; 5.86e-6</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 2260.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 215</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ChargeTransferCoefficient&quot; =&gt; 0.5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ElectrodeCoating&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;BruggemanCoefficient&quot; =&gt; 1.5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;EffectiveDensity&quot; =&gt; 1695</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 8.52e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 1100.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Copper&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabFractions&quot; =&gt; Any[0.5]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabWidth&quot; =&gt; 0.001</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 1.17e-5</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 8960</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 3.55e7</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 1950.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">}</span></span></code></pre></div><p>You can easily print some handy quantities and metrics for debugging:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_cell_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cell_parameters)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">─────────────────────────────</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">🔋 Quick Cell Check</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">─────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Title: Chen2020</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">📏 Core quantities</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Nominal Voltage:        3.71 V</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Nominal Capacity:       4.8 Ah</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Theoretical Capacity:   5.09 Ah</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  N:P Ratio:               0.9131</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Cell Mass:               0.06274 g</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Pos. Mass Loading:       0.2489 mg/cm²</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Neg. Mass Loading:       0.1444 mg/cm²</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">🧠 Functional Status</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Neg. Diffusion Coeff:     </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">CONST ✓</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Neg. OCP:                 </span><span style="--shiki-light:#b08800;--shiki-dark:#ffea7f;">FUNC</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Neg. Reaction Rate:       </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">CONST ✓</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Pos. Diffusion Coeff:     </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">CONST ✓</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Pos. OCP:                 </span><span style="--shiki-light:#b08800;--shiki-dark:#ffea7f;">FUNC</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Pos. Reaction Rate:       </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">CONST ✓</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Electrolyte Conductivity: </span><span style="--shiki-light:#b08800;--shiki-dark:#ffea7f;">FUNC</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">  Electrolyte Diffusion:    </span><span style="--shiki-light:#b08800;--shiki-dark:#ffea7f;">FUNC</span></span></code></pre></div><p>If there are functional parameters present within the parameter set, like the OCP or electrolyte diffusion coefficient, you can easily plot those parameters against a realistic x-quantity range:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_curves</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cell_parameters)</span></span></code></pre></div><p><img src="`+t+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/beginner_tutorials/1_useful_tools.jl" target="_blank" rel="noreferrer">as a script</a>.</p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',45)])])}const g=i(l,[["render",p]]);export{d as __pageData,g as default};
