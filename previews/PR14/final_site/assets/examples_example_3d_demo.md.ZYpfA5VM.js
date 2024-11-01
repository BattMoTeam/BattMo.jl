import{_ as a,c as i,a5 as n,o as p}from"./chunks/framework.D8V24cO4.js";const t="/BattMo.jl/assets/ecyfvxa.BX2qSk17.jpeg",l="/BattMo.jl/assets/oyggnbm.BtSiHBnZ.jpeg",e="/BattMo.jl/assets/mxrhhyu.BnTZACec.jpeg",h="/BattMo.jl/assets/giichpf.qIF68E5k.jpeg",k="/BattMo.jl/assets/yywhast.Curc5IBu.jpeg",r="/BattMo.jl/assets/rmppdee.CIoAQyv5.jpeg",E="/BattMo.jl/assets/dwelsca.DNS3PWaM.jpeg",m=JSON.parse('{"title":"3D battery example","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_3d_demo.md","filePath":"examples/example_3d_demo.md","lastUpdated":null}'),o={name:"examples/example_3d_demo.md"};function g(c,s,d,u,y,F){return p(),i("div",null,s[0]||(s[0]=[n(`<h1 id="3D-battery-example" tabindex="-1">3D battery example <a class="header-anchor" href="#3D-battery-example" aria-label="Permalink to &quot;3D battery example {#3D-battery-example}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Jutul, BattMo, GLMakie</span></span></code></pre></div><h2 id="Setup-input-parameters" tabindex="-1">Setup input parameters <a class="header-anchor" href="#Setup-input-parameters" aria-label="Permalink to &quot;Setup input parameters {#Setup-input-parameters}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;p2d_40_jl_chen2020&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fn </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, name, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">inputparams </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> readBattMoJsonInputFile</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fn)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fn </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/3d_demo_geometry.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">inputparams_geometry </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> readBattMoJsonInputFile</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fn)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">inputparams </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mergeInputParams</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(inputparams_geometry, inputparams)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>InputParams(Dict{String, Any}(&quot;include_current_collectors&quot; =&gt; true, &quot;use_thermal&quot; =&gt; true, &quot;Geometry&quot; =&gt; Dict{String, Any}(&quot;height&quot; =&gt; 0.02, &quot;case&quot; =&gt; &quot;3D-demo&quot;, &quot;Nh&quot; =&gt; 10, &quot;width&quot; =&gt; 0.01, &quot;faceArea&quot; =&gt; 0.027, &quot;Nw&quot; =&gt; 10), &quot;G&quot; =&gt; Any[], &quot;Separator&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 946.0, &quot;thickness&quot; =&gt; 5.0e-5, &quot;N&quot; =&gt; 3, &quot;bruggemanCoefficient&quot; =&gt; 1.5, &quot;thermalConductivity&quot; =&gt; 0.334, &quot;specificHeatCapacity&quot; =&gt; 1692.0, &quot;porosity&quot; =&gt; 0.4), &quot;Control&quot; =&gt; Dict{String, Any}(&quot;numberOfCycles&quot; =&gt; 10, &quot;CRate&quot; =&gt; 1.0, &quot;dEdtLimit&quot; =&gt; 0.0001, &quot;initialControl&quot; =&gt; &quot;discharge&quot;, &quot;DRate&quot; =&gt; 1.0, &quot;rampupTime&quot; =&gt; 10.0, &quot;dIdtLimit&quot; =&gt; 0.0001, &quot;controlPolicy&quot; =&gt; &quot;CCDischarge&quot;, &quot;lowerCutoffVoltage&quot; =&gt; 2.4, &quot;upperCutoffVoltage&quot; =&gt; 4.1…), &quot;SOC&quot; =&gt; 1.0, &quot;Electrolyte&quot; =&gt; Dict{String, Any}(&quot;ionicConductivity&quot; =&gt; Dict{String, Any}(&quot;functionname&quot; =&gt; &quot;computeElectrolyteConductivity_Chen2020&quot;, &quot;argumentlist&quot; =&gt; Any[&quot;c&quot;], &quot;type&quot; =&gt; &quot;function&quot;), &quot;compnames&quot; =&gt; Any[&quot;Li&quot;, &quot;PF6&quot;], &quot;density&quot; =&gt; 1200, &quot;diffusionCoefficient&quot; =&gt; Dict{String, Any}(&quot;functionname&quot; =&gt; &quot;computeDiffusionCoefficient_Chen2020&quot;, &quot;argumentlist&quot; =&gt; Any[&quot;c&quot;], &quot;type&quot; =&gt; &quot;function&quot;), &quot;initialConcentration&quot; =&gt; 1000, &quot;thermalConductivity&quot; =&gt; 0.099, &quot;specificHeatCapacity&quot; =&gt; 1518.0, &quot;bruggemanCoefficient&quot; =&gt; 1.5, &quot;species&quot; =&gt; Dict{String, Any}(&quot;transferenceNumber&quot; =&gt; 0.7406, &quot;nominalConcentration&quot; =&gt; 1000, &quot;chargeNumber&quot; =&gt; 1)), &quot;Output&quot; =&gt; Dict{String, Any}(&quot;variables&quot; =&gt; Any[&quot;energy&quot;]), &quot;PositiveElectrode&quot; =&gt; Dict{String, Any}(&quot;Coating&quot; =&gt; Dict{String, Any}(&quot;thickness&quot; =&gt; 8.0e-5, &quot;N&quot; =&gt; 3, &quot;effectiveDensity&quot; =&gt; 3500, &quot;ActiveMaterial&quot; =&gt; Dict{String, Any}(&quot;diffusionModelType&quot; =&gt; &quot;full&quot;, &quot;density&quot; =&gt; 4950.0, &quot;massFraction&quot; =&gt; 0.9, &quot;Interface&quot; =&gt; Dict{String, Any}(&quot;volumetricSurfaceArea&quot; =&gt; 382183.9, &quot;reactionRateConstant&quot; =&gt; 3.545e-11, &quot;chargeTransferCoefficient&quot; =&gt; 0.5, &quot;density&quot; =&gt; 4950.0, &quot;numberOfElectronsTransferred&quot; =&gt; 1, &quot;guestStoichiometry100&quot; =&gt; 0.2661, &quot;openCircuitPotential&quot; =&gt; Dict{String, Any}(&quot;functionname&quot; =&gt; &quot;computeOCP_NMC811_Chen2020&quot;, &quot;argumentlist&quot; =&gt; Any[&quot;c&quot;, &quot;cmax&quot;], &quot;type&quot; =&gt; &quot;function&quot;), &quot;guestStoichiometry0&quot; =&gt; 0.9084, &quot;saturationConcentration&quot; =&gt; 51765.0, &quot;activationEnergyOfReaction&quot; =&gt; 17800.0…), &quot;SolidDiffusion&quot; =&gt; Dict{String, Any}(&quot;activationEnergyOfDiffusion&quot; =&gt; 5000.0, &quot;particleRadius&quot; =&gt; 1.0e-6, &quot;N&quot; =&gt; 10, &quot;referenceDiffusionCoefficient&quot; =&gt; 1.0e-14), &quot;thermalConductivity&quot; =&gt; 2.1, &quot;specificHeatCapacity&quot; =&gt; 700.0, &quot;electronicConductivity&quot; =&gt; 100.0), &quot;bruggemanCoefficient&quot; =&gt; 1.5, &quot;Binder&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 1780.0, &quot;massFraction&quot; =&gt; 0.05, &quot;thermalConductivity&quot; =&gt; 0.165, &quot;specificHeatCapacity&quot; =&gt; 1400.0, &quot;electronicConductivity&quot; =&gt; 100.0), &quot;ConductingAdditive&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 1800.0, &quot;massFraction&quot; =&gt; 0.05, &quot;thermalConductivity&quot; =&gt; 0.5, &quot;specificHeatCapacity&quot; =&gt; 300.0, &quot;electronicConductivity&quot; =&gt; 100.0)), &quot;CurrentCollector&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 8960, &quot;thickness&quot; =&gt; 1.0e-5, &quot;N&quot; =&gt; 2, &quot;tab&quot; =&gt; Dict{String, Any}(&quot;height&quot; =&gt; 0.001, &quot;Nh&quot; =&gt; 3, &quot;width&quot; =&gt; 0.004, &quot;Nw&quot; =&gt; 3), &quot;electronicConductivity&quot; =&gt; 5.96e7))…))</span></span></code></pre></div><h2 id="Setup-and-run-simulation" tabindex="-1">Setup and run simulation <a class="header-anchor" href="#Setup-and-run-simulation" aria-label="Permalink to &quot;Setup and run simulation {#Setup-and-run-simulation}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> run_battery</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(inputparams);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span></span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps   3%|▏   |  ETA: 0:18:56\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 2/77 (0.13% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     4 iterations in 27.71 s (6.93 s each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  12%|▌   |  ETA: 0:03:56\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 9/77 (6.90% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     33 iterations in 28.21 s (854.97 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  14%|▋   |  ETA: 0:03:09\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 11/77 (9.68% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     40 iterations in 28.34 s (708.42 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  18%|▊   |  ETA: 0:02:22\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 14/77 (13.85% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     50 iterations in 28.50 s (569.93 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  21%|▉   |  ETA: 0:02:01\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 16/77 (16.62% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     58 iterations in 28.62 s (493.53 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  23%|▉   |  ETA: 0:01:45\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 18/77 (19.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     64 iterations in 28.73 s (448.86 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  27%|█▏  |  ETA: 0:01:26\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 21/77 (23.57% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     73 iterations in 28.87 s (395.54 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  31%|█▎  |  ETA: 0:01:11\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 24/77 (27.73% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     82 iterations in 29.02 s (353.89 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  35%|█▍  |  ETA: 0:01:00\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 27/77 (31.90% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     91 iterations in 29.16 s (320.49 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  38%|█▌  |  ETA: 0:00:51\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 30/77 (36.07% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     100 iterations in 29.32 s (293.19 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  42%|█▊  |  ETA: 0:00:44\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 33/77 (40.23% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     109 iterations in 29.47 s (270.33 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  46%|█▉  |  ETA: 0:00:38\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 36/77 (44.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     118 iterations in 29.61 s (250.96 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  50%|██  |  ETA: 0:00:32\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 39/77 (48.57% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     127 iterations in 29.76 s (234.31 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  54%|██▏ |  ETA: 0:00:28\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 42/77 (52.73% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     136 iterations in 29.90 s (219.86 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  58%|██▎ |  ETA: 0:00:24\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 45/77 (56.90% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     145 iterations in 30.05 s (207.22 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  62%|██▌ |  ETA: 0:00:21\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 48/77 (61.07% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     154 iterations in 30.19 s (196.04 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  65%|██▋ |  ETA: 0:00:17\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 51/77 (65.23% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     163 iterations in 30.35 s (186.19 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  69%|██▊ |  ETA: 0:00:15\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 54/77 (69.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     172 iterations in 30.50 s (177.31 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  73%|██▉ |  ETA: 0:00:12\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 57/77 (73.57% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     181 iterations in 30.64 s (169.29 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  77%|███▏|  ETA: 0:00:10\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 60/77 (77.73% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     190 iterations in 30.79 s (162.04 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  81%|███▎|  ETA: 0:00:08\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 63/77 (81.90% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     199 iterations in 30.93 s (155.44 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  85%|███▍|  ETA: 0:00:06\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 66/77 (86.07% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     208 iterations in 31.08 s (149.41 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  87%|███▌|  ETA: 0:00:05\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 68/77 (88.85% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     215 iterations in 31.19 s (145.06 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  90%|███▋|  ETA: 0:00:04\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 70/77 (91.62% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     223 iterations in 31.32 s (140.43 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  92%|███▊|  ETA: 0:00:03\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 72/77 (94.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     231 iterations in 31.46 s (136.18 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  95%|███▊|  ETA: 0:00:02\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 74/77 (97.18% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     239 iterations in 31.59 s (132.18 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  97%|███▉|  ETA: 0:00:01\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 76/77 (99.96% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     246 iterations in 31.70 s (128.87 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps 100%|████| Time: 0:00:35\x1B[K</span></span>
<span class="line"><span>  Progress:  Solved step 77/77\x1B[K</span></span>
<span class="line"><span>  Stats:     252 iterations in 31.80 s (126.19 ms each)\x1B[K</span></span>
<span class="line"><span>╭────────────────┬──────────┬──────────────┬──────────╮</span></span>
<span class="line"><span>│ Iteration type │ Avg/step │ Avg/ministep │    Total │</span></span>
<span class="line"><span>│                │ 77 steps │ 77 ministeps │ (wasted) │</span></span>
<span class="line"><span>├────────────────┼──────────┼──────────────┼──────────┤</span></span>
<span class="line"><span>│ Newton         │  3.27273 │      3.27273 │  252 (0) │</span></span>
<span class="line"><span>│ Linearization  │  4.27273 │      4.27273 │  329 (0) │</span></span>
<span class="line"><span>│ Linear solver  │  3.27273 │      3.27273 │  252 (0) │</span></span>
<span class="line"><span>│ Precond apply  │      0.0 │          0.0 │    0 (0) │</span></span>
<span class="line"><span>╰────────────────┴──────────┴──────────────┴──────────╯</span></span>
<span class="line"><span>╭───────────────┬──────────┬────────────┬─────────╮</span></span>
<span class="line"><span>│ Timing type   │     Each │   Relative │   Total │</span></span>
<span class="line"><span>│               │       ms │ Percentage │       s │</span></span>
<span class="line"><span>├───────────────┼──────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Properties    │   0.2358 │     0.19 % │  0.0594 │</span></span>
<span class="line"><span>│ Equations     │  25.3689 │    26.25 % │  8.3464 │</span></span>
<span class="line"><span>│ Assembly      │  14.6338 │    15.14 % │  4.8145 │</span></span>
<span class="line"><span>│ Linear solve  │  14.6487 │    11.61 % │  3.6915 │</span></span>
<span class="line"><span>│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Precond apply │   0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Update        │   6.2780 │     4.98 % │  1.5821 │</span></span>
<span class="line"><span>│ Convergence   │  21.1774 │    21.91 % │  6.9674 │</span></span>
<span class="line"><span>│ Input/Output  │   4.5853 │     1.11 % │  0.3531 │</span></span>
<span class="line"><span>│ Other         │  23.7484 │    18.82 % │  5.9846 │</span></span>
<span class="line"><span>├───────────────┼──────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Total         │ 126.1860 │   100.00 % │ 31.7989 │</span></span>
<span class="line"><span>╰───────────────┴──────────┴────────────┴─────────╯</span></span></code></pre></div><h2 id="Plot-discharge-curve" tabindex="-1">Plot discharge curve <a class="header-anchor" href="#Plot-discharge-curve" aria-label="Permalink to &quot;Plot discharge curve {#Plot-discharge-curve}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model  </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:extra</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:model</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">t </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:ControllerCV</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">time </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">E </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">I </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Current</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">400</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          title     </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          xlabel    </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          ylabel    </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage / V&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              E;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              )</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          title     </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          xlabel    </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          ylabel    </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current / A&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">          )</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              I;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">              markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f</span></span></code></pre></div><p><img src="`+t+`" alt=""></p><h2 id="Plot-potential-on-grid-at-last-time-step" tabindex="-1">Plot potential on grid at last time step <a class="header-anchor" href="#Plot-potential-on-grid-at-last-time-step" aria-label="Permalink to &quot;Plot potential on grid at last time step {#Plot-potential-on-grid-at-last-time-step}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> plot_potential</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(am, cc, label)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    f3D </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">600</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">650</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ax3d </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                 title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Potential in </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> electrode (coating and active material)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    maxPhi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[cc][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[am][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])])</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    minPhi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[cc][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[am][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])])</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, maxPhi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minPhi]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    components </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [am, cc]</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> component </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> components</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        g </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model[component]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">domain</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">representation</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        phi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[component][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        Jutul</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_data!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax3d, g, phi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minPhi; colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    cbar </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Colorbar</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minPhi,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;potential&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Screen</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), f3D)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> f3D</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>plot_potential (generic function with 1 method)</span></span></code></pre></div><h2 id="" tabindex="-1"><a class="header-anchor" href="#" aria-label="Permalink to &quot;&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_potential</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeCc</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;positive&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+l+'" alt=""></p><h2 id="-2" tabindex="-1"><a class="header-anchor" href="#-2" aria-label="Permalink to &quot;{#-2}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_potential</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeCc</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;negative&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+e+`" alt=""></p><h2 id="Plot-surface-concentration-on-grid-at-last-time-step" tabindex="-1">Plot surface concentration on grid at last time step <a class="header-anchor" href="#Plot-surface-concentration-on-grid-at-last-time-step" aria-label="Permalink to &quot;Plot surface concentration on grid at last time step {#Plot-surface-concentration-on-grid-at-last-time-step}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> plot_surface_concentration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(component, label)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    f3D </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">600</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">650</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ax3d </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                 title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Surface concentration in </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> electrode&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    cs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[component][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Cs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    maxcs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cs)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    mincs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cs)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, maxcs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> mincs]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    g </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model[component]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">domain</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">representation</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    Jutul</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_data!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax3d, g, cs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> mincs;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                          colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                          colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    cbar </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Colorbar</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> mincs,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;concentration&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Screen</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), f3D)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> f3D</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>plot_surface_concentration (generic function with 1 method)</span></span></code></pre></div><h2 id="positive" tabindex="-1">Positive <a class="header-anchor" href="#positive" aria-label="Permalink to &quot;Positive&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_surface_concentration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;positive&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+h+'" alt=""></p><h2 id="negative" tabindex="-1">Negative <a class="header-anchor" href="#negative" aria-label="Permalink to &quot;Negative&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_surface_concentration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;negative&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+k+`" alt=""></p><h2 id="Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step" tabindex="-1">Plot electrolyte concentration and potential on grid at last time step <a class="header-anchor" href="#Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step" aria-label="Permalink to &quot;Plot electrolyte concentration and potential on grid at last time step {#Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> plot_elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(var, label)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    f3D </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">600</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">650</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ax3d </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]; title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> in electrolyte&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    val </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][var]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    maxval </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(val)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    minval </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(val)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, maxval </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minval]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    g </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">domain</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">representation</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    Jutul</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_data!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax3d, g, val </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minval;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                          colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                          colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    cbar </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Colorbar</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minval,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">                            label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Screen</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), f3D)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    f3D</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>plot_elyte (generic function with 1 method)</span></span></code></pre></div><h2 id="-3" tabindex="-1"><a class="header-anchor" href="#-3" aria-label="Permalink to &quot;{#-3}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:C</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;concentration&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+r+'" alt=""></p><h2 id="-4" tabindex="-1"><a class="header-anchor" href="#-4" aria-label="Permalink to &quot;{#-4}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;potential&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+E+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_3d_demo.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_3d_demo.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',42)]))}const C=a(o,[["render",g]]);export{m as __pageData,C as default};
