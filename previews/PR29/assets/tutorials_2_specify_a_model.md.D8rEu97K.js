import{_ as n,c as a,o as t,aA as p}from"./chunks/framework.Wenau9Pp.js";const q=JSON.parse('{"title":"Setting Up a Custom Battery Model","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/2_specify_a_model.md","filePath":"tutorials/2_specify_a_model.md","lastUpdated":null}'),e={name:"tutorials/2_specify_a_model.md"};function i(l,s,o,c,u,r){return t(),a("div",null,s[0]||(s[0]=[p(`<h1 id="Setting-Up-a-Custom-Battery-Model" tabindex="-1">Setting Up a Custom Battery Model <a class="header-anchor" href="#Setting-Up-a-Custom-Battery-Model" aria-label="Permalink to &quot;Setting Up a Custom Battery Model {#Setting-Up-a-Custom-Battery-Model}&quot;">​</a></h1><p>In this tutorial, we’ll configure a custom battery model using BattMo, with a specific focus on SEI (Solid Electrolyte Interphase) growth within a P2D simulation framework.</p><h3 id="Load-BattMo-and-Model-Settings" tabindex="-1">Load BattMo and Model Settings <a class="header-anchor" href="#Load-BattMo-and-Model-Settings" aria-label="Permalink to &quot;Load BattMo and Model Settings {#Load-BattMo-and-Model-Settings}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span></code></pre></div><p>Let’s begin by loading the default model settings for a P2D simulation. This will return a ModelSettings object:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;model_settings&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P2D.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_model)</span></span></code></pre></div><p>We can inspect all current settings with:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">all</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 3 entries:</span></span>
<span class="line"><span>  &quot;UseDiffusionModel&quot; =&gt; &quot;PXD&quot;</span></span>
<span class="line"><span>  &quot;ModelGeometry&quot;     =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>  &quot;UseRampUp&quot;         =&gt; &quot;Generic&quot;</span></span></code></pre></div><p>By default, the &quot;UseSEIModel&quot; parameter is set to false. Since we want to observe SEI effects, we’ll enable and set it to Bolay, which is a specific SEI model.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;UseSEIModel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bolay&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">all</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Dict{String, Any} with 4 entries:</span></span>
<span class="line"><span>  &quot;UseDiffusionModel&quot; =&gt; &quot;PXD&quot;</span></span>
<span class="line"><span>  &quot;ModelGeometry&quot;     =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>  &quot;UseRampUp&quot;         =&gt; &quot;Generic&quot;</span></span>
<span class="line"><span>  &quot;UseSEIModel&quot;       =&gt; &quot;Bolay&quot;</span></span></code></pre></div><h3 id="Initialize-the-Model" tabindex="-1">Initialize the Model <a class="header-anchor" href="#Initialize-the-Model" aria-label="Permalink to &quot;Initialize the Model {#Initialize-the-Model}&quot;">​</a></h3><p>Let’s now create the battery model using the modified settings:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>We can see that some warnings are given in the terminal. When setting up the model, the LithiumIonBatteryModel constructor runs a validation on the model_settings. In this case, because we set the &quot;UseSEIModel&quot; parameter to true, the validator provides a warning that we should define which SEI model we would like to use. If we ignore the warnings and pass the model to the Simulation constructor then we get an error:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cell_parameters&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;SEI_example.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cycling_protocols&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCCV.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters_sei </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cccv_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cycling)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters_sei, cccv_protocol)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Simulation(BattMo.run_battery, LithiumIonBatteryModel(&quot;1D Doyle-Fuller-Newman lithium-ion model&quot;, {</span></span>
<span class="line"><span>    &quot;UseDiffusionModel&quot; =&gt; &quot;PXD&quot;</span></span>
<span class="line"><span>    &quot;ModelGeometry&quot; =&gt; &quot;1D&quot;</span></span>
<span class="line"><span>    &quot;UseRampUp&quot; =&gt; &quot;Generic&quot;</span></span>
<span class="line"><span>    &quot;UseSEIModel&quot; =&gt; &quot;Bolay&quot;</span></span>
<span class="line"><span>}, true), {</span></span>
<span class="line"><span>    &quot;Electrolyte&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;TransferenceNumber&quot; =&gt; 0.2594</span></span>
<span class="line"><span>        &quot;Description&quot; =&gt; &quot;Ethylene carbonate based electrolyte&quot;</span></span>
<span class="line"><span>        &quot;DiffusionCoefficient&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;functionname&quot; =&gt; &quot;computeDiffusionCoefficient_default&quot;</span></span>
<span class="line"><span>            &quot;argumentlist&quot; =&gt; Any[&quot;concentration&quot;, &quot;temperature&quot;]</span></span>
<span class="line"><span>            &quot;type&quot; =&gt; &quot;function&quot;</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;IonicConductivity&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;functionname&quot; =&gt; &quot;computeElectrolyteConductivity_default&quot;</span></span>
<span class="line"><span>            &quot;argumentlist&quot; =&gt; Any[&quot;concentration&quot;, &quot;temperature&quot;]</span></span>
<span class="line"><span>            &quot;type&quot; =&gt; &quot;function&quot;</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;Density&quot; =&gt; 1200.0</span></span>
<span class="line"><span>        &quot;ChargeNumber&quot; =&gt; 1</span></span>
<span class="line"><span>        &quot;Concentration&quot; =&gt; 1000.0</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;Cell&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;ElectrodeGeometricSurfaceArea&quot; =&gt; 0.0002</span></span>
<span class="line"><span>        &quot;ElectrodeWidth&quot; =&gt; 0.01</span></span>
<span class="line"><span>        &quot;ElectrodeLength&quot; =&gt; 0.02</span></span>
<span class="line"><span>        &quot;Name&quot; =&gt; &quot;&quot;</span></span>
<span class="line"><span>        &quot;Case&quot; =&gt; &quot;3D-demo&quot;</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;Metadata&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;Description&quot; =&gt; &quot;Parameter set to test SEI simulations. Obtained from the Julia repository but with unknown source.&quot;</span></span>
<span class="line"><span>        &quot;Title&quot; =&gt; &quot;SEI example&quot;</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;PositiveElectrode&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfDiffusion&quot; =&gt; 5000.0</span></span>
<span class="line"><span>            &quot;NumberOfElectronsTransfered&quot; =&gt; 1</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.99174</span></span>
<span class="line"><span>            &quot;ReactionRateConstant&quot; =&gt; 2.33e-11</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.95</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.4955</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfReaction&quot; =&gt; 5000.0</span></span>
<span class="line"><span>            &quot;OpenCircuitVoltage&quot; =&gt;             {</span></span>
<span class="line"><span>                &quot;functionname&quot; =&gt; &quot;computeOCP_NMC111&quot;</span></span>
<span class="line"><span>                &quot;argumentlist&quot; =&gt; Any[&quot;concentration&quot;, &quot;temperature&quot;, &quot;cmax&quot;]</span></span>
<span class="line"><span>                &quot;type&quot; =&gt; &quot;function&quot;</span></span>
<span class="line"><span>            }</span></span>
<span class="line"><span>            &quot;MaximumConcentration&quot; =&gt; 55554.0</span></span>
<span class="line"><span>            &quot;VolumetricSurfaceArea&quot; =&gt; 885000.0</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;NCM111&quot;</span></span>
<span class="line"><span>            &quot;DiffusionCoefficient&quot; =&gt; 1.0e-14</span></span>
<span class="line"><span>            &quot;ParticleRadius&quot; =&gt; 1.0e-6</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 4650.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span>            &quot;ChargeTransferCoefficient&quot; =&gt; 0.5</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ElectrodeCoating&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;BruggemanCoefficient&quot; =&gt; 1.5</span></span>
<span class="line"><span>            &quot;EffectiveDensity&quot; =&gt; 3500.0</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 8.0e-5</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.025</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 1750.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Aluminum&quot;</span></span>
<span class="line"><span>            &quot;TabLength&quot; =&gt; 0.001</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 2700.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 3.55e7</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 1.0e-5</span></span>
<span class="line"><span>            &quot;TabWidth&quot; =&gt; 0.004</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.025</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 1830.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;Separator&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span>        &quot;Density&quot; =&gt; 946.0</span></span>
<span class="line"><span>        &quot;BruggemanCoefficient&quot; =&gt; 1.5</span></span>
<span class="line"><span>        &quot;Thickness&quot; =&gt; 5.0e-5</span></span>
<span class="line"><span>        &quot;Porosity&quot; =&gt; 0.55</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>    &quot;NegativeElectrode&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;Interphase&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;IntersticialConcentration&quot; =&gt; 0.015</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;EC-based CEI&quot;</span></span>
<span class="line"><span>            &quot;ElectronicDiffusionCoefficient&quot; =&gt; 1.6e-12</span></span>
<span class="line"><span>            &quot;InitialThickness&quot; =&gt; 1.0e-8</span></span>
<span class="line"><span>            &quot;IonicConductivity&quot; =&gt; 1.0e-5</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficient&quot; =&gt; 2</span></span>
<span class="line"><span>            &quot;InitialPotentialDrop&quot; =&gt; 0.5</span></span>
<span class="line"><span>            &quot;MolarVolume&quot; =&gt; 9.586e-5</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfDiffusion&quot; =&gt; 5000.0</span></span>
<span class="line"><span>            &quot;NumberOfElectronsTransfered&quot; =&gt; 1</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.1429</span></span>
<span class="line"><span>            &quot;ReactionRateConstant&quot; =&gt; 5.031e-11</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.94</span></span>
<span class="line"><span>            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.88551</span></span>
<span class="line"><span>            &quot;ActivationEnergyOfReaction&quot; =&gt; 5000.0</span></span>
<span class="line"><span>            &quot;OpenCircuitVoltage&quot; =&gt;             {</span></span>
<span class="line"><span>                &quot;functionname&quot; =&gt; &quot;computeOCP_Graphite_Torchio&quot;</span></span>
<span class="line"><span>                &quot;argumentlist&quot; =&gt; Any[&quot;concentration&quot;, &quot;temperature&quot;, &quot;cmax&quot;]</span></span>
<span class="line"><span>                &quot;type&quot; =&gt; &quot;function&quot;</span></span>
<span class="line"><span>            }</span></span>
<span class="line"><span>            &quot;MaximumConcentration&quot; =&gt; 30555.0</span></span>
<span class="line"><span>            &quot;VolumetricSurfaceArea&quot; =&gt; 723600.0</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Graphite&quot;</span></span>
<span class="line"><span>            &quot;DiffusionCoefficient&quot; =&gt; 3.9e-14</span></span>
<span class="line"><span>            &quot;ParticleRadius&quot; =&gt; 1.0e-6</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 2240.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span>            &quot;ChargeTransferCoefficient&quot; =&gt; 0.5</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ElectrodeCoating&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;BruggemanCoefficient&quot; =&gt; 1.5</span></span>
<span class="line"><span>            &quot;EffectiveDensity&quot; =&gt; 1900.0</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 0.0001</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.03</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 1100.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Copper&quot;</span></span>
<span class="line"><span>            &quot;TabLength&quot; =&gt; 0.001</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 8960.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 5.96e7</span></span>
<span class="line"><span>            &quot;Thickness&quot; =&gt; 1.0e-5</span></span>
<span class="line"><span>            &quot;TabWidth&quot; =&gt; 0.004</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span>            &quot;Description&quot; =&gt; &quot;Unknown&quot;</span></span>
<span class="line"><span>            &quot;MassFraction&quot; =&gt; 0.03</span></span>
<span class="line"><span>            &quot;Density&quot; =&gt; 1950.0</span></span>
<span class="line"><span>            &quot;ElectronicConductivity&quot; =&gt; 100.0</span></span>
<span class="line"><span>        }</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>}, {</span></span>
<span class="line"><span>    &quot;Protocol&quot; =&gt; &quot;CCCV&quot;</span></span>
<span class="line"><span>    &quot;UpperVoltageLimit&quot; =&gt; 4.0</span></span>
<span class="line"><span>    &quot;InitialControl&quot; =&gt; &quot;charging&quot;</span></span>
<span class="line"><span>    &quot;DRate&quot; =&gt; 1.0</span></span>
<span class="line"><span>    &quot;TotalNumberOfCycles&quot; =&gt; 3</span></span>
<span class="line"><span>    &quot;CRate&quot; =&gt; 1.0</span></span>
<span class="line"><span>    &quot;InitialStateOfCharge&quot; =&gt; 0</span></span>
<span class="line"><span>    &quot;InitialKelvinTemperature&quot; =&gt; 298.15</span></span>
<span class="line"><span>    &quot;CurrentChangeLimit&quot; =&gt; 0.0001</span></span>
<span class="line"><span>    &quot;VoltageChangeLimit&quot; =&gt; 0.0001</span></span>
<span class="line"><span>    &quot;LowerVoltageLimit&quot; =&gt; 3.0</span></span>
<span class="line"><span>}, {</span></span>
<span class="line"><span>    &quot;Grid&quot; =&gt; Any[]</span></span>
<span class="line"><span>    &quot;TimeStepDuration&quot; =&gt; 50</span></span>
<span class="line"><span>    &quot;RampUpSteps&quot; =&gt; 5</span></span>
<span class="line"><span>    &quot;RampUpTime&quot; =&gt; 10</span></span>
<span class="line"><span>    &quot;GridPoints&quot; =&gt;     {</span></span>
<span class="line"><span>        &quot;PositiveElectrodeCoating&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;PositiveElectrodeCurrentCollector&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;NegativeElectrodeCurrentCollectorTabLength&quot; =&gt; 2</span></span>
<span class="line"><span>        &quot;Separator&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;PositiveElectrodeCurrentCollectorTabWidth&quot; =&gt; 2</span></span>
<span class="line"><span>        &quot;PositiveElectrodeCurrentCollectorTabLength&quot; =&gt; 2</span></span>
<span class="line"><span>        &quot;NegativeElectrodeCoating&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;NegativeElectrodeActiveMaterial&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;NegativeElectrodeCurrentCollector&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;ElectrodeWidth&quot; =&gt; 5</span></span>
<span class="line"><span>        &quot;ElectrodeLength&quot; =&gt; 5</span></span>
<span class="line"><span>        &quot;PositiveElectrodeActiveMaterial&quot; =&gt; 10</span></span>
<span class="line"><span>        &quot;NegativeElectrodeCurrentCollectorTabWidth&quot; =&gt; 2</span></span>
<span class="line"><span>    }</span></span>
<span class="line"><span>}, true)</span></span></code></pre></div><p>As expected, this results in an error because we haven&#39;t yet specified the SEI model type.</p><h3 id="Specify-SEI-Model-and-Rebuild" tabindex="-1">Specify SEI Model and Rebuild <a class="header-anchor" href="#Specify-SEI-Model-and-Rebuild" aria-label="Permalink to &quot;Specify SEI Model and Rebuild {#Specify-SEI-Model-and-Rebuild}&quot;">​</a></h3><p>To resolve this, we’ll explicitly set the SEI model to &quot;Bolay&quot;:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;SEIModel&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bolay&quot;</span></span></code></pre></div><p>Now rebuild the model:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span></code></pre></div><p>Run the Simulation Now we can setup the simulation and run it.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters_sei, cccv_protocol)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Jutul: Simulating 9 hours as 648 report steps</span></span>
<span class="line"><span>╭────────────────┬───────────┬───────────────┬─────────────╮</span></span>
<span class="line"><span>│ Iteration type │  Avg/step │  Avg/ministep │       Total │</span></span>
<span class="line"><span>│                │ 320 steps │ 434 ministeps │    (wasted) │</span></span>
<span class="line"><span>├────────────────┼───────────┼───────────────┼─────────────┤</span></span>
<span class="line"><span>│ Newton         │   6.58125 │       4.85253 │ 2106 (1185) │</span></span>
<span class="line"><span>│ Linearization  │    7.9375 │       5.85253 │ 2540 (1264) │</span></span>
<span class="line"><span>│ Linear solver  │   6.58125 │       4.85253 │ 2106 (1185) │</span></span>
<span class="line"><span>│ Precond apply  │       0.0 │           0.0 │       0 (0) │</span></span>
<span class="line"><span>╰────────────────┴───────────┴───────────────┴─────────────╯</span></span>
<span class="line"><span>╭───────────────┬────────┬────────────┬────────╮</span></span>
<span class="line"><span>│ Timing type   │   Each │   Relative │  Total │</span></span>
<span class="line"><span>│               │     ms │ Percentage │      s │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Properties    │ 0.0470 │     4.66 % │ 0.0991 │</span></span>
<span class="line"><span>│ Equations     │ 0.2061 │    24.60 % │ 0.5234 │</span></span>
<span class="line"><span>│ Assembly      │ 0.0771 │     9.20 % │ 0.1957 │</span></span>
<span class="line"><span>│ Linear solve  │ 0.4478 │    44.33 % │ 0.9432 │</span></span>
<span class="line"><span>│ Linear setup  │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Precond apply │ 0.0000 │     0.00 % │ 0.0000 │</span></span>
<span class="line"><span>│ Update        │ 0.0523 │     5.18 % │ 0.1102 │</span></span>
<span class="line"><span>│ Convergence   │ 0.0752 │     8.97 % │ 0.1909 │</span></span>
<span class="line"><span>│ Input/Output  │ 0.0257 │     0.52 % │ 0.0111 │</span></span>
<span class="line"><span>│ Other         │ 0.0256 │     2.54 % │ 0.0540 │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼────────┤</span></span>
<span class="line"><span>│ Total         │ 1.0102 │   100.00 % │ 2.1275 │</span></span>
<span class="line"><span>╰───────────────┴────────┴────────────┴────────╯</span></span></code></pre></div><h2 id="Plot-of-voltage-and-current" tabindex="-1">Plot of voltage and current <a class="header-anchor" href="#Plot-of-voltage-and-current" aria-label="Permalink to &quot;Plot of voltage and current {#Plot-of-voltage-and-current}&quot;">​</a></h2><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>states = output[:states]</span></span>
<span class="line highlighted"><span></span></span>
<span class="line"><span>t = [state[:Control][:ControllerCV].time for state in states]</span></span>
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
<span class="line"><span>f # hide</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/2_specify_a_model.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/2_specify_a_model.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,38)]))}const d=n(e,[["render",i]]);export{q as __pageData,d as default};
