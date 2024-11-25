import{_ as a,c as n,a5 as i,o as p}from"./chunks/framework.DVxdOaxS.js";const t="/BattMo.jl/dev/assets/mztrszm.BkJcVoEH.jpeg",l="/BattMo.jl/dev/assets/ydtioqs.BW0pUbd4.jpeg",e="/BattMo.jl/dev/assets/wyxpaec.2bAbBst8.jpeg",h="/BattMo.jl/dev/assets/sejjfte.BQTtdqfW.jpeg",k="/BattMo.jl/dev/assets/jmmnxle.dg6sAurV.jpeg",r="/BattMo.jl/dev/assets/norjgip.DyTHLBlO.jpeg",E="/BattMo.jl/dev/assets/wtpesaz.B9367kI9.jpeg",m=JSON.parse('{"title":"3D battery example","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_3d_demo.md","filePath":"examples/example_3d_demo.md","lastUpdated":null}'),o={name:"examples/example_3d_demo.md"};function g(u,s,c,d,y,b){return p(),n("div",null,s[0]||(s[0]=[i(`<h1 id="3D-battery-example" tabindex="-1">3D battery example <a class="header-anchor" href="#3D-battery-example" aria-label="Permalink to &quot;3D battery example {#3D-battery-example}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Jutul, BattMo, GLMakie</span></span></code></pre></div><h2 id="Setup-input-parameters" tabindex="-1">Setup input parameters <a class="header-anchor" href="#Setup-input-parameters" aria-label="Permalink to &quot;Setup input parameters {#Setup-input-parameters}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;p2d_40_jl_chen2020&quot;</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fn </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, name, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">inputparams </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> readBattMoJsonInputFile</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fn)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fn </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../test/data/jsonfiles/3d_demo_geometry.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">inputparams_geometry </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> readBattMoJsonInputFile</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(fn)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">inputparams </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mergeInputParams</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(inputparams_geometry, inputparams)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>InputParams(Dict{String, Any}(&quot;include_current_collectors&quot; =&gt; true, &quot;use_thermal&quot; =&gt; true, &quot;Geometry&quot; =&gt; Dict{String, Any}(&quot;height&quot; =&gt; 0.02, &quot;case&quot; =&gt; &quot;3D-demo&quot;, &quot;Nh&quot; =&gt; 10, &quot;width&quot; =&gt; 0.01, &quot;faceArea&quot; =&gt; 0.1027, &quot;Nw&quot; =&gt; 10), &quot;G&quot; =&gt; Any[], &quot;Separator&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 946.0, &quot;thickness&quot; =&gt; 5.0e-5, &quot;N&quot; =&gt; 3, &quot;bruggemanCoefficient&quot; =&gt; 1.5, &quot;thermalConductivity&quot; =&gt; 0.334, &quot;specificHeatCapacity&quot; =&gt; 1692.0, &quot;porosity&quot; =&gt; 0.4), &quot;Control&quot; =&gt; Dict{String, Any}(&quot;numberOfCycles&quot; =&gt; 10, &quot;CRate&quot; =&gt; 1.0, &quot;dEdtLimit&quot; =&gt; 0.0001, &quot;initialControl&quot; =&gt; &quot;discharge&quot;, &quot;DRate&quot; =&gt; 1.0, &quot;rampupTime&quot; =&gt; 10.0, &quot;dIdtLimit&quot; =&gt; 0.0001, &quot;controlPolicy&quot; =&gt; &quot;CCDischarge&quot;, &quot;lowerCutoffVoltage&quot; =&gt; 2.4, &quot;upperCutoffVoltage&quot; =&gt; 4.1…), &quot;SOC&quot; =&gt; 1.0, &quot;Electrolyte&quot; =&gt; Dict{String, Any}(&quot;ionicConductivity&quot; =&gt; Dict{String, Any}(&quot;functionname&quot; =&gt; &quot;computeElectrolyteConductivity_Chen2020&quot;, &quot;argumentlist&quot; =&gt; Any[&quot;c&quot;], &quot;type&quot; =&gt; &quot;function&quot;), &quot;compnames&quot; =&gt; Any[&quot;Li&quot;, &quot;PF6&quot;], &quot;density&quot; =&gt; 1200, &quot;diffusionCoefficient&quot; =&gt; Dict{String, Any}(&quot;functionname&quot; =&gt; &quot;computeDiffusionCoefficient_Chen2020&quot;, &quot;argumentlist&quot; =&gt; Any[&quot;c&quot;], &quot;type&quot; =&gt; &quot;function&quot;), &quot;initialConcentration&quot; =&gt; 1000, &quot;thermalConductivity&quot; =&gt; 0.099, &quot;specificHeatCapacity&quot; =&gt; 1518.0, &quot;bruggemanCoefficient&quot; =&gt; 1.5, &quot;species&quot; =&gt; Dict{String, Any}(&quot;transferenceNumber&quot; =&gt; 0.7406, &quot;nominalConcentration&quot; =&gt; 1000, &quot;chargeNumber&quot; =&gt; 1)), &quot;Output&quot; =&gt; Dict{String, Any}(&quot;variables&quot; =&gt; Any[&quot;energy&quot;]), &quot;PositiveElectrode&quot; =&gt; Dict{String, Any}(&quot;Coating&quot; =&gt; Dict{String, Any}(&quot;thickness&quot; =&gt; 8.0e-5, &quot;N&quot; =&gt; 3, &quot;effectiveDensity&quot; =&gt; 3500, &quot;ActiveMaterial&quot; =&gt; Dict{String, Any}(&quot;diffusionModelType&quot; =&gt; &quot;full&quot;, &quot;density&quot; =&gt; 4950.0, &quot;massFraction&quot; =&gt; 0.9, &quot;Interface&quot; =&gt; Dict{String, Any}(&quot;volumetricSurfaceArea&quot; =&gt; 382183.9, &quot;reactionRateConstant&quot; =&gt; 3.545e-11, &quot;chargeTransferCoefficient&quot; =&gt; 0.5, &quot;density&quot; =&gt; 4950.0, &quot;numberOfElectronsTransferred&quot; =&gt; 1, &quot;guestStoichiometry100&quot; =&gt; 0.2661, &quot;openCircuitPotential&quot; =&gt; Dict{String, Any}(&quot;functionname&quot; =&gt; &quot;computeOCP_NMC811_Chen2020&quot;, &quot;argumentlist&quot; =&gt; Any[&quot;c&quot;, &quot;cmax&quot;], &quot;type&quot; =&gt; &quot;function&quot;), &quot;guestStoichiometry0&quot; =&gt; 0.9084, &quot;saturationConcentration&quot; =&gt; 51765.0, &quot;activationEnergyOfReaction&quot; =&gt; 17800.0…), &quot;SolidDiffusion&quot; =&gt; Dict{String, Any}(&quot;activationEnergyOfDiffusion&quot; =&gt; 5000.0, &quot;particleRadius&quot; =&gt; 1.0e-6, &quot;N&quot; =&gt; 10, &quot;referenceDiffusionCoefficient&quot; =&gt; 1.0e-14), &quot;thermalConductivity&quot; =&gt; 2.1, &quot;specificHeatCapacity&quot; =&gt; 700.0, &quot;electronicConductivity&quot; =&gt; 100.0), &quot;bruggemanCoefficient&quot; =&gt; 1.5, &quot;Binder&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 1780.0, &quot;massFraction&quot; =&gt; 0.05, &quot;thermalConductivity&quot; =&gt; 0.165, &quot;specificHeatCapacity&quot; =&gt; 1400.0, &quot;electronicConductivity&quot; =&gt; 100.0), &quot;ConductingAdditive&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 1800.0, &quot;massFraction&quot; =&gt; 0.05, &quot;thermalConductivity&quot; =&gt; 0.5, &quot;specificHeatCapacity&quot; =&gt; 300.0, &quot;electronicConductivity&quot; =&gt; 100.0)), &quot;CurrentCollector&quot; =&gt; Dict{String, Any}(&quot;density&quot; =&gt; 8960, &quot;thickness&quot; =&gt; 1.0e-5, &quot;N&quot; =&gt; 2, &quot;tab&quot; =&gt; Dict{String, Any}(&quot;height&quot; =&gt; 0.001, &quot;Nh&quot; =&gt; 3, &quot;width&quot; =&gt; 0.004, &quot;Nw&quot; =&gt; 3), &quot;electronicConductivity&quot; =&gt; 5.96e7))…))</span></span></code></pre></div><h2 id="Setup-and-run-simulation" tabindex="-1">Setup and run simulation <a class="header-anchor" href="#Setup-and-run-simulation" aria-label="Permalink to &quot;Setup and run simulation {#Setup-and-run-simulation}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> run_battery</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(inputparams);</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span></span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps   3%|▏   |  ETA: 0:16:31\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 2/77 (0.13% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     1 iterations in 24.02 s (24.02 s each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps   8%|▎   |  ETA: 0:05:24\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 6/77 (2.73% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     16 iterations in 24.56 s (1.54 s each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  10%|▍   |  ETA: 0:04:01\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 8/77 (5.51% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     22 iterations in 25.03 s (1.14 s each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  13%|▌   |  ETA: 0:03:08\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 10/77 (8.29% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     28 iterations in 25.14 s (897.75 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  15%|▋   |  ETA: 0:02:32\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 12/77 (11.07% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     34 iterations in 25.26 s (742.81 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  18%|▊   |  ETA: 0:02:07\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 14/77 (13.85% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     40 iterations in 25.38 s (634.43 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  21%|▉   |  ETA: 0:01:48\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 16/77 (16.62% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     46 iterations in 25.49 s (554.06 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  23%|▉   |  ETA: 0:01:34\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 18/77 (19.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     52 iterations in 25.60 s (492.33 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  26%|█   |  ETA: 0:01:22\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 20/77 (22.18% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     58 iterations in 25.71 s (443.33 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  28%|█▏  |  ETA: 0:01:12\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 22/77 (24.96% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     64 iterations in 25.83 s (403.55 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  31%|█▎  |  ETA: 0:01:04\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 24/77 (27.73% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     70 iterations in 25.94 s (370.59 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  33%|█▍  |  ETA: 0:00:57\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 26/77 (30.51% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     76 iterations in 26.06 s (342.86 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  37%|█▌  |  ETA: 0:00:48\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 29/77 (34.68% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     84 iterations in 26.22 s (312.18 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  40%|█▋  |  ETA: 0:00:44\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 31/77 (37.46% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     90 iterations in 26.34 s (292.64 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  42%|█▊  |  ETA: 0:00:39\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 33/77 (40.23% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     96 iterations in 26.45 s (275.52 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  45%|█▊  |  ETA: 0:00:36\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 35/77 (43.01% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     102 iterations in 26.56 s (260.42 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  47%|█▉  |  ETA: 0:00:32\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 37/77 (45.79% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     108 iterations in 26.68 s (247.01 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  50%|██  |  ETA: 0:00:29\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 39/77 (48.57% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     114 iterations in 26.79 s (235.02 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  53%|██▏ |  ETA: 0:00:27\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 41/77 (51.35% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     120 iterations in 26.91 s (224.27 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  55%|██▎ |  ETA: 0:00:24\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 43/77 (54.12% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     126 iterations in 27.03 s (214.52 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  58%|██▎ |  ETA: 0:00:22\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 45/77 (56.90% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     132 iterations in 27.15 s (205.66 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  60%|██▍ |  ETA: 0:00:20\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 47/77 (59.68% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     138 iterations in 27.28 s (197.65 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  64%|██▋ |  ETA: 0:00:17\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 50/77 (63.85% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     144 iterations in 27.40 s (190.28 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  67%|██▋ |  ETA: 0:00:15\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 52/77 (66.62% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     149 iterations in 27.50 s (184.57 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  69%|██▊ |  ETA: 0:00:13\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 54/77 (69.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     155 iterations in 27.61 s (178.15 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  72%|██▉ |  ETA: 0:00:12\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 56/77 (72.18% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     161 iterations in 27.73 s (172.21 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  74%|███ |  ETA: 0:00:10\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 58/77 (74.96% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     167 iterations in 27.84 s (166.71 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  77%|███▏|  ETA: 0:00:09\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 60/77 (77.73% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     173 iterations in 27.95 s (161.58 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  79%|███▏|  ETA: 0:00:08\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 62/77 (80.51% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     179 iterations in 28.07 s (156.79 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  82%|███▎|  ETA: 0:00:07\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 64/77 (83.29% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     185 iterations in 28.18 s (152.32 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  85%|███▍|  ETA: 0:00:06\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 66/77 (86.07% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     191 iterations in 28.31 s (148.20 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  87%|███▌|  ETA: 0:00:05\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 68/77 (88.85% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     197 iterations in 28.42 s (144.27 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  90%|███▋|  ETA: 0:00:04\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 70/77 (91.62% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     203 iterations in 28.53 s (140.56 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  92%|███▊|  ETA: 0:00:03\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 72/77 (94.40% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     210 iterations in 28.67 s (136.51 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  95%|███▊|  ETA: 0:00:02\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 74/77 (97.18% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     217 iterations in 28.79 s (132.69 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps  97%|███▉|  ETA: 0:00:01\x1B[K</span></span>
<span class="line"><span>  Progress:  Solving step 76/77 (99.96% of time interval complete)\x1B[K</span></span>
<span class="line"><span>  Stats:     223 iterations in 28.91 s (129.64 ms each)\x1B[K</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span>\x1B[A</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>\x1B[K\x1B[A</span></span>
<span class="line"><span>Simulating 1 hour, 6 minutes as 77 report steps 100%|████| Time: 0:00:32\x1B[K</span></span>
<span class="line"><span>  Progress:  Solved step 77/77\x1B[K</span></span>
<span class="line"><span>  Stats:     229 iterations in 29.02 s (126.74 ms each)\x1B[K</span></span>
<span class="line"><span>╭────────────────┬──────────┬──────────────┬──────────╮</span></span>
<span class="line"><span>│ Iteration type │ Avg/step │ Avg/ministep │    Total │</span></span>
<span class="line"><span>│                │ 77 steps │ 77 ministeps │ (wasted) │</span></span>
<span class="line"><span>├────────────────┼──────────┼──────────────┼──────────┤</span></span>
<span class="line"><span>│ Newton         │  2.97403 │      2.97403 │  229 (0) │</span></span>
<span class="line"><span>│ Linearization  │  3.97403 │      3.97403 │  306 (0) │</span></span>
<span class="line"><span>│ Linear solver  │  2.97403 │      2.97403 │  229 (0) │</span></span>
<span class="line"><span>│ Precond apply  │      0.0 │          0.0 │    0 (0) │</span></span>
<span class="line"><span>╰────────────────┴──────────┴──────────────┴──────────╯</span></span>
<span class="line"><span>╭───────────────┬──────────┬────────────┬─────────╮</span></span>
<span class="line"><span>│ Timing type   │     Each │   Relative │   Total │</span></span>
<span class="line"><span>│               │       ms │ Percentage │       s │</span></span>
<span class="line"><span>├───────────────┼──────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Properties    │   0.2309 │     0.18 % │  0.0529 │</span></span>
<span class="line"><span>│ Equations     │  30.5004 │    32.16 % │  9.3331 │</span></span>
<span class="line"><span>│ Assembly      │  12.6168 │    13.30 % │  3.8607 │</span></span>
<span class="line"><span>│ Linear solve  │  16.4907 │    13.01 % │  3.7764 │</span></span>
<span class="line"><span>│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Precond apply │   0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Update        │   5.9152 │     4.67 % │  1.3546 │</span></span>
<span class="line"><span>│ Convergence   │  18.5479 │    19.55 % │  5.6756 │</span></span>
<span class="line"><span>│ Input/Output  │   4.1656 │     1.11 % │  0.3208 │</span></span>
<span class="line"><span>│ Other         │  20.3071 │    16.02 % │  4.6503 │</span></span>
<span class="line"><span>├───────────────┼──────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Total         │ 126.7443 │   100.00 % │ 29.0244 │</span></span>
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
