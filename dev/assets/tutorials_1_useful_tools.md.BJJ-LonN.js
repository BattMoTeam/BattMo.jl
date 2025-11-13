import{_ as e,c as a,o as i,aA as n}from"./chunks/framework.y_Ki7YdF.js";const l="/BattMo.jl/dev/assets/ovupqjs.CVzjx1iG.jpeg",g=JSON.parse('{"title":"Useful Tools in BattMo","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/1_useful_tools.md","filePath":"tutorials/1_useful_tools.md","lastUpdated":null}'),t={name:"tutorials/1_useful_tools.md"};function p(h,s,r,k,c,o){return i(),a("div",null,[...s[0]||(s[0]=[n(`<h1 id="Useful-Tools-in-BattMo" tabindex="-1">Useful Tools in BattMo <a class="header-anchor" href="#Useful-Tools-in-BattMo" aria-label="Permalink to &quot;Useful Tools in BattMo {#Useful-Tools-in-BattMo}&quot;">​</a></h1><p>Before we dive into how to set up and run simulations, it&#39;s helpful to get familiar with some of the built-in tools provided by <strong>BattMo</strong>. These utilities can save time and improve your workflow, and we&#39;ll be using most of them throughout the tutorials.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span></code></pre></div><h2 id="Saving-Default-Parameter-Sets-Locally" tabindex="-1">Saving Default Parameter Sets Locally <a class="header-anchor" href="#Saving-Default-Parameter-Sets-Locally" aria-label="Permalink to &quot;Saving Default Parameter Sets Locally {#Saving-Default-Parameter-Sets-Locally}&quot;">​</a></h2><p>BattMo includes several default parameter sets that you can use as a starting point. If you want to explore or customize them, you can easily save them to your local disk using:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> pwd</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">folder_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;default_parameter_sets&quot;</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">generate_default_parameter_files</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(path, folder_name)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🛠 JSON files successfully written! Path:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">	/home/runner/work/BattMo.jl/BattMo.jl/docs/build/tutorials/default_parameter_sets</span></span></code></pre></div><p>This will create a folder in your current working directory containing the default parameter files.</p><h2 id="Viewing-Parameter-Set-Information" tabindex="-1">Viewing Parameter Set Information <a class="header-anchor" href="#Viewing-Parameter-Set-Information" aria-label="Permalink to &quot;Viewing Parameter Set Information {#Viewing-Parameter-Set-Information}&quot;">​</a></h2><p>To quickly inspect which default parameter sets are included with BattMo and what each contains, you can use:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_default_input_sets</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📋 Overview of Available Default Sets</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 cell_parameters:         chayambuka_2022, chen_2020, xu_2015</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 cycling_protocols:       cc_charge, cc_cycling, cc_discharge, cccv, user_defined_current_function</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 full_simulation_input:   chen_2020, chen_2020_p4d</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 model_settings:          p2d, p4d_cylindrical, p4d_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 simulation_settings:     p2d, p2d_fine_resolution, p4d_cylindrical, p4d_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📁 solver_settings:         default, direct, iterative</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📖 Detailed Descriptions</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 cell_parameters</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">chayambuka_2022</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell name:       	-</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Cell case:       	Pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Source:          	\x1B]8;;(Invalid metadata format)\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a Sodium ion cell based on Chayambuka et al. The positive electrode open circuit potential has been retrieved from a [COMSOL example](https://www.comsol.com/model/1d-isothermal-sodium-ion-battery-117341).</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">chen_2020</span></span>
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
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">xu_2015</span></span>
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
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">cc_charge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current charging protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">cc_cycling</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current cycling protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">cc_discharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current discharging protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">cccv</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set for a constant current constant voltage cyling protocol.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">user_defined_current_function</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set that shows an example of how to include a user defined function in the cycling protocol parameters.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 full_simulation_input</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">chen_2020</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Source:          	\x1B]8;;https://doi.org/10.1149/1945-7111/ab9050\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set of a cylindrical 21700 commercial cell (LGM50), for an electrochemical pseudo-two-dimensional (P2D) model, after calibration. SEI parameters are from Bolay2022: https://doi.org/10.1016/j.powera.2022.100083 .</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">chen_2020_p4d</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Source:          	\x1B]8;;https://doi.org/10.1149/1945-7111/ab9050\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Parameter set of a cylindrical 21700 commercial cell (LGM50), for an electrochemical pseudo-two-dimensional (P2D) model, after calibration. SEI parameters are from Bolay2022: https://doi.org/10.1016/j.powera.2022.100083 .</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 model_settings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p2d</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default model settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p4d_cylindrical</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default model settings for a P4D cylindrical cell with a current ramp up.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p4d_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default model settings for a P4D pouch simulation including a current ramp up, current collectors.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 simulation_settings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p2d</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • SEIModel:           Bolay</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default simulation settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p2d_fine_resolution</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • SEIModel:           Bolay</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default simulation settings for a P2D simulation including a current ramp up, excluding current collectors and SEI effects for a finer resolution.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p4d_cylindrical</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">p4d_pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Suitable for:</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • SEIModel:           Bolay</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • RampUp:             Sinusoidal</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • TransportInSolid:   FullDiffusion</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • CurrentCollector:   Generic</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">   • ModelFramework:     P2D, P4D Pouch</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔹 Description:     	Default simulation settings for a P4D pouch simulation including a current ramp up, current collectors.</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📂 solver_settings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">default</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">direct</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">iterative</span></span></code></pre></div><h2 id="Inspecting-Individual-Parameters" tabindex="-1">Inspecting Individual Parameters <a class="header-anchor" href="#Inspecting-Individual-Parameters" aria-label="Permalink to &quot;Inspecting Individual Parameters {#Inspecting-Individual-Parameters}&quot;">​</a></h2><p>If you&#39;re unsure how a specific parameter should be defined or what it represents, you can print detailed information about it. For example, for cell parameters and cycling protocol parameters:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;OpenCircuitPotential&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name; view </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;CellParameters&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔋  Cell Parameter:  OpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               OpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CellParameters</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        The open-circuit potential of the active material under a given intercalant stoichimetry and temperature.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               String, Dict{String, Vector}, Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               V</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Documentation      \x1B]8;;https://battmo.org/BattMo.jl/dev/manuals/user_guide/simulation_dependent_input\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_9c657fdc_b9d3_4964_907c_f9a6e8c5f52b\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">========================================================================================================================</span></span></code></pre></div><p>An example for model or simulation settings:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;ModelFramework&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name; view </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;ModelSettings&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🕸️  Model Setting:  ModelFramework</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ModelFramework</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           ModelSettings</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Framework defining the dimensionality of the electrochemical model. Examples: &quot;P2D&quot;, &quot;P4D Pouch&quot;.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               String</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Options            P2D, P4D Pouch, P4D Cylindrical</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Documentation      \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/battery#battery_b1921f7b_afac_465a_a275_26f929f7f936\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">========================================================================================================================</span></span></code></pre></div><p>An example for output variables:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Concentration&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(parameter_name; view </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;OutputVariable&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  NegativeElectrodeActiveMaterialSurfaceConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               NegativeElectrodeActiveMaterialSurfaceConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Concentration of lithium ions at the surface of negative electrode particles.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               mol·L⁻¹</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  PositiveElectrodeActiveMaterialParticleConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               PositiveElectrodeActiveMaterialParticleConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Radial distribution of lithium concentration in positive electrode particles.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition, nPositiveElectrodeActiveMaterialRadius)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               mol·L⁻¹</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  ElectrolyteConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ElectrolyteConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Concentration of lithium ions in the electrolyte.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               mol·m⁻³</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  PositiveElectrodeActiveMaterialSurfaceConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               PositiveElectrodeActiveMaterialSurfaceConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Concentration of lithium ions at the surface of positive electrode particles.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               mol·L⁻¹</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  NegativeElectrodeActiveMaterialParticleConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               NegativeElectrodeActiveMaterialParticleConcentration</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Radial distribution of lithium concentration in negative electrode particles.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition, nNegativeElectrodeActiveMaterialRadius)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               mol·L⁻¹</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">========================================================================================================================</span></span></code></pre></div><p>And a general example, find variables with charge in the name.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;charge&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔋  Cell Parameter:  ChargeNumber</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ChargeNumber</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CellParameters</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Electric charge of an ion divided by the elementary charge.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Int64</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Minimum value      1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Maximum value      4</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo#EMMO_dc467621_3b49_4f31_9b09_82290f29da52\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔋  Cell Parameter:  ChargeTransferCoefficient</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ChargeTransferCoefficient</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CellParameters</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Constant alpha in the Butler-Volmer equation. It represents the fraction of the electrostatic potential energy affecting the reduction rate in an electrode reaction, with the remaining fraction affecting the corresponding oxidation rate.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               -</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Minimum value      0.1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Maximum value      0.9</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_a4dfa5c1_55a9_4285_b71d_90cf6613ca31\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🚴  Cycling Protocol:  RestingTimeAfterDischarge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               RestingTimeAfterDischarge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CyclingProtocol</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Time during which the cell is kept at open-circuit conditions after completing a discharging step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               s</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Minimum value      0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Maximum value      1.0e6</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_2678a656_4a27_4706_8dde_b0a93e9b92fa\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🚴  Cycling Protocol:  InitialStateOfCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               InitialStateOfCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CyclingProtocol</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        State of charge of the cell at the start of a simulation.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               1</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Minimum value      0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Maximum value      1.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_8b2aaa50_bbe1_45da_8778_8898326246a2\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🚴  Cycling Protocol:  RestingTimeAfterCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               RestingTimeAfterCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CyclingProtocol</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Time during which the cell is kept at open-circuit conditions after completing a charging step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               s</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Minimum value      0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Maximum value      1.0e6</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_2678a656_4a27_4706_8dde_b0a93e9b92fa\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  DischargeCapacity</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               DischargeCapacity</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Total amount of charge delivered during the discharge phase.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nCycleIndex,)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               Ah</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  NegativeElectrodeActiveMaterialCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               NegativeElectrodeActiveMaterialCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Charge stored in the negative electrode.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               C</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  ElectrolyteCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ElectrolyteCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Charge carried by the ions in the electrolyte.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               C</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  DischargeEnergy</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               DischargeEnergy</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Total energy output from the battery during discharge.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nCycleIndex,)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               J</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  PositiveElectrodeActiveMaterialCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               PositiveElectrodeActiveMaterialCharge</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Charge stored in the positive electrode.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               C</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  ChargeEnergy</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ChargeEnergy</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Total energy input to the battery during charging.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nCycleIndex,)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               J</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  ChargeCapacity</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               ChargeCapacity</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Total amount of charge accepted during the charge phase.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nCycleIndex,)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               Ah</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">========================================================================================================================</span></span></code></pre></div><p>This is especially useful when building or editing custom parameter sets.</p><h2 id="Listing-Available-Submodels" tabindex="-1">Listing Available Submodels <a class="header-anchor" href="#Listing-Available-Submodels" aria-label="Permalink to &quot;Listing Available Submodels {#Listing-Available-Submodels}&quot;">​</a></h2><p>BattMo supports a modular submodel architecture. To view all available submodels you can integrate into your simulation, run:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_submodels</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ℹ️  Submodels Information</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">====================================================================================================</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Parameter                     Options                                           Documentation</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ButlerVolmer                  Standard, Chayambuka                              \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">CurrentCollectors             Standard                                          -</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">SEIModel                      Bolay                                             \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/sei_model\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">RampUp                        Sinusoidal                                        \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/ramp_up\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">TemperatureDependence         Arrhenius                                         \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/arrhenius\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">PotentialFlowDiscretization   GeneralAD, TwoPointDiscretization                 -</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">TransportInSolid              FullDiffusion                                     -</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">ModelFramework                P2D, P4D Pouch, P4D Cylindrical                   \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/pxd_model\x1B\\visit\x1B]8;;\x1B\\</span></span></code></pre></div><h2 id="Write-a-parameter-set-object-to-a-JSON-file" tabindex="-1">Write a parameter set object to a JSON file <a class="header-anchor" href="#Write-a-parameter-set-object-to-a-JSON-file" aria-label="Permalink to &quot;Write a parameter set object to a JSON file {#Write-a-parameter-set-object-to-a-JSON-file}&quot;">​</a></h2><p>You can use the following function to save your ParameterSet object to a JSON file:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;path_to_json_file/file.json&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">parameter_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> CellParameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;NegativeElectrode&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Coating&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Dict</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Thickness&quot;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 100e-6</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">write_to_json_file</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path, parameter_set)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">An error occurred while writing to the file: SystemError(&quot;opening file \\&quot;path_to_json_file/file.json\\&quot;&quot;, 2, nothing)</span></span></code></pre></div><h2 id="Get-quick-information-on-a-cell-parameter-set" tabindex="-1">Get quick information on a cell parameter set <a class="header-anchor" href="#Get-quick-information-on-a-cell-parameter-set" aria-label="Permalink to &quot;Get quick information on a cell parameter set {#Get-quick-information-on-a-cell-parameter-set}&quot;">​</a></h2><p>Let&#39;s load a default cell parameter set.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;chen_2020&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>You can easily print some handy quantities and metrics for debugging:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">quick_cell_check</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cell_parameters)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">════════════════════════════════════════════════════════════════════════════════════════════════════════════</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">🔋 Quick Cell Check</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">════════════════════════════════════════════════════════════════════════════════════════════════════════════</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Cell 1: Chen2020</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Quantity                                Cell 1         | Unit         | Source</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">────────────────────────────────────────────────────────────────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Nominal Voltage                         3.71           | V            | </span><span style="--shiki-light:#005cc5;--shiki-dark:#79b8ff;">[INPUT]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Nominal Capacity                        4.8            | Ah           | </span><span style="--shiki-light:#005cc5;--shiki-dark:#79b8ff;">[INPUT]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Cell Theoretical Capacity               5.09           | Ah           | </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">[EQUILIBRIUM CALCULATION]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Cell N:P Ratio                          0.9131         | -            | </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">[EQUILIBRIUM CALCULATION]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Cell Mass                               0.04745        | kg           | </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">[EQUILIBRIUM CALCULATION]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Positive Electrode Mass Loading         24.89          | mg/cm²       | </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">[EQUILIBRIUM CALCULATION]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Negative Electrode Mass Loading         14.44          | mg/cm²       | </span><span style="--shiki-light:#22863a;--shiki-dark:#85e89d;">[EQUILIBRIUM CALCULATION]</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">════════════════════════════════════════════════════════════════════════════════════════════════════════════</span></span></code></pre></div><p>If there are functional parameters present within the parameter set, like the OCP or electrolyte diffusion coefficient, you can easily plot those parameters against a realistic x-quantity range:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_curves</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cell_parameters)</span></span></code></pre></div><p><img src="`+l+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/beginner_tutorials/1_useful_tools.jl" target="_blank" rel="noreferrer">as a script</a>.</p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',47)])])}const u=e(t,[["render",p]]);export{g as __pageData,u as default};
