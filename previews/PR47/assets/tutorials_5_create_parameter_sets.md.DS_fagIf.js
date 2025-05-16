import{_ as s,c as n,o as t,aA as e}from"./chunks/framework.C8T9lM5z.js";const d=JSON.parse('{"title":"Tutorial: Creating Your Own Parameter Sets in BattMo.jl","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/5_create_parameter_sets.md","filePath":"tutorials/5_create_parameter_sets.md","lastUpdated":null}'),p={name:"tutorials/5_create_parameter_sets.md"};function i(l,a,o,r,u,c){return t(),n("div",null,a[0]||(a[0]=[e(`<h1 id="Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl" tabindex="-1">Tutorial: Creating Your Own Parameter Sets in BattMo.jl <a class="header-anchor" href="#Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl" aria-label="Permalink to &quot;Tutorial: Creating Your Own Parameter Sets in BattMo.jl {#Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl}&quot;">​</a></h1><p>This tutorial walks you through the process of creating and customizing your own parameter sets in <strong>BattMo.jl</strong>. Parameter sets define the physical and chemical properties of the battery system you&#39;re simulating. You can build them from scratch using model templates, modify them, and save them for future use.</p><h2 id="Step-1:-Load-a-Model-Setup" tabindex="-1">Step 1: Load a Model Setup <a class="header-anchor" href="#Step-1:-Load-a-Model-Setup" aria-label="Permalink to &quot;Step 1: Load a Model Setup {#Step-1:-Load-a-Model-Setup}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">#First, define the battery model configuration you&#39;d like to use. This will serve as the template for generating your parameter set. BattMo includes several default setups to choose from.</span></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;P4D_pouch&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_setup </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBattery</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>LithiumIonBattery(&quot;P4D Pouch Setup object for a lithium-ion model&quot;, {</span></span>
<span class="line"><span>    &quot;CurrentCollectors&quot; =&gt; &quot;Generic&quot;</span></span>
<span class="line"><span>    &quot;RampUp&quot; =&gt; &quot;Sinusoidal&quot;</span></span>
<span class="line"><span>    &quot;TransportInSolid&quot; =&gt; &quot;FullDiffusion&quot;</span></span>
<span class="line"><span>    &quot;ModelFramework&quot; =&gt; &quot;P4D Pouch&quot;</span></span>
<span class="line"><span>}, true)</span></span></code></pre></div><h2 id="Step-2:-Create-an-Empty-Parameter-Set" tabindex="-1">Step 2: Create an Empty Parameter Set <a class="header-anchor" href="#Step-2:-Create-an-Empty-Parameter-Set" aria-label="Permalink to &quot;Step 2: Create an Empty Parameter Set {#Step-2:-Create-an-Empty-Parameter-Set}&quot;">​</a></h2><p>Next, create an empty parameter dictionary based on your model setup. This will include all the required keys but without any values filled in.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">empty_cell_parameter_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_model_template </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model_setup)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>{</span></span>
<span class="line"><span>    &quot;Electrolyte&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;TransferenceNumber&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;DiffusionCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;IonicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;ChargeNumber&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;Concentration&quot; =&gt; 0.0</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;Cell&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;ElectrodeGeometricSurfaceArea&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;ElectrodeWidth&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;ElectrodeLength&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;Case&quot; =&gt; &quot;&quot;</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;PositiveElectrode&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfDiffusion&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;NumberOfElectronsTransfered&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;OpenCircuitPotential&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ReactionRateConstant&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfReaction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;MaximumConcentration&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;VolumetricSurfaceArea&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;DiffusionCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ParticleRadius&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ChargeTransferCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ElectrodeCoating&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;BruggemanCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;EffectiveDensity&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;TabLength&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;TabWidth&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;Separator&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;BruggemanCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span>        &quot;Porosity&quot; =&gt; 0.0</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;NegativeElectrode&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfDiffusion&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;NumberOfElectronsTransfered&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;OpenCircuitPotential&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ReactionRateConstant&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfReaction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;MaximumConcentration&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;VolumetricSurfaceArea&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;DiffusionCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ParticleRadius&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ChargeTransferCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ElectrodeCoating&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;BruggemanCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;EffectiveDensity&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;TabLength&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;TabWidth&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>}</span></span></code></pre></div><h2 id="Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File" tabindex="-1">Step 3: Save the Empty Parameter Set to a JSON File <a class="header-anchor" href="#Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File" aria-label="Permalink to &quot;Step 3: Save the Empty Parameter Set to a JSON File {#Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File}&quot;">​</a></h2><p>You can now write this empty set to a JSON file. This file can be edited manually, shared, or used as a base for further customization.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;my_custom_parameters.json&quot;</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">write_to_json_file</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path, empty_cell_parameter_set)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Data successfully written to my_custom_parameters.json</span></span></code></pre></div><h2 id="Step-4:-Get-Help-with-Parameters" tabindex="-1">Step 4: Get Help with Parameters <a class="header-anchor" href="#Step-4:-Get-Help-with-Parameters" aria-label="Permalink to &quot;Step 4: Get Help with Parameters {#Step-4:-Get-Help-with-Parameters}&quot;">​</a></h2><p>If you&#39;re unsure about what a specific parameter means or how it should be formatted, BattMo provides a helpful function to inspect any parameter.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_parameter_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;OpenCircuitPotential&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>================================================================================</span></span>
<span class="line"><span>ℹ️  Parameter Information</span></span>
<span class="line"><span>================================================================================</span></span>
<span class="line"><span>Parameter                     type                                    unit</span></span>
<span class="line"><span>--------------------------------------------------------------------------------</span></span>
<span class="line"><span>OpenCircuitPotential          String, Dict{String, Vector}, Real      V</span></span></code></pre></div><h2 id="Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it." tabindex="-1">Step 5: Now you can load you own parameter set to run simulations with it. <a class="header-anchor" href="#Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it." aria-label="Permalink to &quot;Step 5: Now you can load you own parameter set to run simulations with it. {#Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it.}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;my_custom_parameters.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/5_create_parameter_sets.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/5_create_parameter_sets.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,23)]))}const g=s(p,[["render",i]]);export{d as __pageData,g as default};
