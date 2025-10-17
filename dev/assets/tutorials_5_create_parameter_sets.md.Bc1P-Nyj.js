import{_ as e,c as a,o as i,aA as t}from"./chunks/framework.BxeeVtwU.js";const c=JSON.parse('{"title":"Tutorial: Creating Your Own Parameter Sets in BattMo.jl","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/5_create_parameter_sets.md","filePath":"tutorials/5_create_parameter_sets.md","lastUpdated":null}'),n={name:"tutorials/5_create_parameter_sets.md"};function l(p,s,h,o,r,k){return i(),a("div",null,[...s[0]||(s[0]=[t(`<h1 id="Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl" tabindex="-1">Tutorial: Creating Your Own Parameter Sets in BattMo.jl <a class="header-anchor" href="#Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl" aria-label="Permalink to &quot;Tutorial: Creating Your Own Parameter Sets in BattMo.jl {#Tutorial:-Creating-Your-Own-Parameter-Sets-in-BattMo.jl}&quot;">​</a></h1><p>This tutorial walks you through the process of creating and customizing your own parameter sets in <strong>BattMo.jl</strong>. Parameter sets define the physical and chemical properties of the battery system you&#39;re simulating. You can build them from scratch using model templates, modify them, and save them for future use.</p><h2 id="Step-1:-Load-a-Model-Setup" tabindex="-1">Step 1: Load a Model Setup <a class="header-anchor" href="#Step-1:-Load-a-Model-Setup" aria-label="Permalink to &quot;Step 1: Load a Model Setup {#Step-1:-Load-a-Model-Setup}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;">#First, define the battery model configuration you&#39;d like to use. This will serve as the template for generating your parameter set. BattMo includes several default setups to choose from.</span></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_default_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;p4d_pouch&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBattery</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">LithiumIonBattery(&quot;Setup object for a P4D Pouch lithium-ion model&quot;, {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;ButlerVolmer&quot; =&gt; &quot;Standard&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;CurrentCollectors&quot; =&gt; &quot;Standard&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;RampUp&quot; =&gt; &quot;Sinusoidal&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Metadata&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Description&quot; =&gt; &quot;Default model settings for a P4D pouch simulation including a current ramp up, current collectors.&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Title&quot; =&gt; &quot;p4d_pouch&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;PotentialFlowDiscretization&quot; =&gt; &quot;GeneralAD&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;TransportInSolid&quot; =&gt; &quot;FullDiffusion&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;ModelFramework&quot; =&gt; &quot;P4D Pouch&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">}, true, #undef)</span></span></code></pre></div><h2 id="Step-2:-Create-an-Empty-Parameter-Set" tabindex="-1">Step 2: Create an Empty Parameter Set <a class="header-anchor" href="#Step-2:-Create-an-Empty-Parameter-Set" aria-label="Permalink to &quot;Step 2: Create an Empty Parameter Set {#Step-2:-Create-an-Empty-Parameter-Set}&quot;">​</a></h2><p>Next, create an empty parameter dictionary based on your model setup. This will include all the required keys but without any values filled in.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">empty_cell_parameter_set </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_model_template </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">{</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Electrolyte&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;TransferenceNumber&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;DiffusionCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;IonicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ChargeNumber&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Concentration&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Cell&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ElectrodeWidth&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ElectrodeLength&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;PositiveElectrode&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;NumberOfElectronsTransfered&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;OpenCircuitPotential&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ReactionRateConstant&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MaximumConcentration&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;VolumetricSurfaceArea&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;DiffusionCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ParticleRadius&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ChargeTransferCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Coating&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;BruggemanCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;EffectiveDensity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabLength&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabWidth&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;Separator&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;BruggemanCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Porosity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    &quot;NegativeElectrode&quot; =&gt;     {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ActiveMaterial&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;NumberOfElectronsTransfered&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC0&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;OpenCircuitPotential&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ReactionRateConstant&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;StoichiometricCoefficientAtSOC100&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MaximumConcentration&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;VolumetricSurfaceArea&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;DiffusionCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ParticleRadius&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ChargeTransferCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Binder&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;Coating&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;BruggemanCoefficient&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;EffectiveDensity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;CurrentCollector&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabLength&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Thickness&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;TabWidth&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        &quot;ConductiveAdditive&quot; =&gt;         {</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;MassFraction&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;Density&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">            &quot;ElectronicConductivity&quot; =&gt; 0.0</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">        }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    }</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">}</span></span></code></pre></div><h2 id="Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File" tabindex="-1">Step 3: Save the Empty Parameter Set to a JSON File <a class="header-anchor" href="#Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File" aria-label="Permalink to &quot;Step 3: Save the Empty Parameter Set to a JSON File {#Step-3:-Save-the-Empty-Parameter-Set-to-a-JSON-File}&quot;">​</a></h2><p>You can now write this empty set to a JSON file. This file can be edited manually, shared, or used as a base for further customization.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;my_custom_parameters.json&quot;</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">write_to_json_file</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(file_path, empty_cell_parameter_set)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Data successfully written to my_custom_parameters.json</span></span></code></pre></div><h2 id="Step-4:-Get-Help-with-Parameters" tabindex="-1">Step 4: Get Help with Parameters <a class="header-anchor" href="#Step-4:-Get-Help-with-Parameters" aria-label="Permalink to &quot;Step 4: Get Help with Parameters {#Step-4:-Get-Help-with-Parameters}&quot;">​</a></h2><p>If you&#39;re unsure about what a specific parameter means or how it should be formatted, BattMo provides a helpful function to inspect any parameter.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">print_info</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;OpenCircuitPotential&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">🔋  Cell Parameter:  OpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               OpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           CellParameters</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        The open-circuit potential of the active material under a given intercalant stoichimetry and temperature.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               String, Dict{String, Vector}, Real</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               V</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Documentation      \x1B]8;;https://battmoteam.github.io/BattMo.jl/dev/manuals/user_guide/simulation_dependent_input\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Ontology link      \x1B]8;;https://w3id.org/emmo/domain/electrochemistry#electrochemistry_9c657fdc_b9d3_4964_907c_f9a6e8c5f52b\x1B\\visit\x1B]8;;\x1B\\</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  PositiveElectrodeActiveMaterialOpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               PositiveElectrodeActiveMaterialOpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Open-circuit voltage of the positive electrode.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               V</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">📈  Output Variable:  NegativeElectrodeActiveMaterialOpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">----------------------------------------------------------------------------------------------------</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Name               NegativeElectrodeActiveMaterialOpenCircuitPotential</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Category           OutputVariable</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Description        Open-circuit voltage of the negative electrode.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Type               Vector{Real}</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Shape              (nTime, nPosition)</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">    🔹 Unit               mol·m⁻²·s⁻¹</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">========================================================================================================================</span></span></code></pre></div><h2 id="Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it." tabindex="-1">Step 5: Now you can load you own parameter set to run simulations with it. <a class="header-anchor" href="#Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it." aria-label="Permalink to &quot;Step 5: Now you can load you own parameter set to run simulations with it. {#Step-5:-Now-you-can-load-you-own-parameter-set-to-run-simulations-with-it.}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;my_custom_parameters.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/beginner_tutorials/5_create_parameter_sets.jl" target="_blank" rel="noreferrer">as a script</a>.</p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,23)])])}const d=e(n,[["render",l]]);export{c as __pageData,d as default};
