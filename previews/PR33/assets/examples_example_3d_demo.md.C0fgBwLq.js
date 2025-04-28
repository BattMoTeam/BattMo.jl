import{_ as a,c as n,o as i,aA as l}from"./chunks/framework.Bu1rAwjv.js";const p="/BattMo.jl/previews/PR33/assets/khtjmmr.BoNIIp81.jpeg",t="/BattMo.jl/previews/PR33/assets/bdandug.RhD_-zTM.jpeg",e="/BattMo.jl/previews/PR33/assets/heijbsz.BwAMrkae.jpeg",h="/BattMo.jl/previews/PR33/assets/lbktxdv.Dfi0IQuS.jpeg",k="/BattMo.jl/previews/PR33/assets/tvvsvlw.D1WtWRFf.jpeg",E="/BattMo.jl/previews/PR33/assets/fiivzoo.DJ7HRFoq.jpeg",r="/BattMo.jl/previews/PR33/assets/lqjxpce.BLIE89pD.jpeg",D=JSON.parse('{"title":"3D battery example","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_3d_demo.md","filePath":"examples/example_3d_demo.md","lastUpdated":null}'),o={name:"examples/example_3d_demo.md"};function d(c,s,g,y,C,u){return i(),n("div",null,s[0]||(s[0]=[l(`<h1 id="3D-battery-example" tabindex="-1">3D battery example <a class="header-anchor" href="#3D-battery-example" aria-label="Permalink to &quot;3D battery example {#3D-battery-example}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Jutul, BattMo, GLMakie</span></span></code></pre></div><h2 id="Setup-input-parameters" tabindex="-1">Setup input parameters <a class="header-anchor" href="#Setup-input-parameters" aria-label="Permalink to &quot;Setup input parameters {#Setup-input-parameters}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cell_parameters/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Xu2015.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/model_settings/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P4D_pouch.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/cycling_protocols/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCDischarge.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_simulation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> string</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">dirname</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pathof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(BattMo)), </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;/../src/input/defaults/simulation_settings/&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P4D_pouch.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cycling)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_model)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">simulation_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_simulation_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_simulation)</span></span></code></pre></div><h2 id="Setup-and-run-simulation" tabindex="-1">Setup and run simulation <a class="header-anchor" href="#Setup-and-run-simulation" aria-label="Permalink to &quot;Setup and run simulation {#Setup-and-run-simulation}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBatteryModel</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model, cell_parameters, cycling_protocol; simulation_settings);</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>[ Info: (&quot;par = &quot;, BattMo.CCPolicy{Union{Missing, Float64}}(&quot;discharging&quot;, 0.0, 0.0, 2.4, 4.1, missing))</span></span>
<span class="line"><span>[ Info: (&quot;control = &quot;, &quot;discharging&quot;)</span></span>
<span class="line"><span>[ Info: (&quot;I = &quot;, 0.051468843077052365)</span></span>
<span class="line"><span>[ Info: (&quot;val = &quot;, 0.0)</span></span>
<span class="line"><span>[ Info: (&quot;con = &quot;, &quot;discharging&quot;)</span></span>
<span class="line"><span>Jutul: Simulating 2 hours, 12 minutes as 163 report steps</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.3151327941596844,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.0030386879579956325,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.291708682006676,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.02321200713128439,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.259180379708335,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2579401599126165,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2566409132948904,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2555920855021183,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2549369600087408,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2544234404164962,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2539755914307165,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2535885308608377,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.253218354561542,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2528594716965187,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.252508639543446,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.252163714377339,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2518530097041283,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.251639285745432,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2514330544723102,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2512268812028293,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2510204513917103,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2508134966872784,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2506057938463466,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2503971571598833,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.250187431549248,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.249976486837476,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.249764213122323,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2495505170462535,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2493353187740643,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.249107795162689,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.248857545877281,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2485859079059063,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2483126366703963,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.248037662109724,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2477609311557676,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.247482399306103,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2472020267339112,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.246919776562586,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2466356139168724,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2463495052717777,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.246061417941886,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2457713196540596,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2454789511117745,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2451069254423106,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.244660416674032,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2441294054196033,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2435963495204216,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2430611427775844,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.242523715417515,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.241984017333717,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2414420033272866,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2408976283776063,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.240350846136375,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2398016083926255,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.239249864814968,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.238695562769915,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2381223348531196,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.237423005315141,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.236553858335603,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.235559540011389,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2345624044227796,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.233562381991241,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2325593570084346,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.23155324197419,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2305439544594616,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2295314099538013,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.228515519723471,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2274961901087322,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.226473322185941,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2254468114918664,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2244129292594153,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.223229923169626,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2218048257487344,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.220301234738525,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2187932443725047,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.217280869695743,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2157639279831733,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.214242250872962,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.212715666484064,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.211183993651998,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.209647039832807,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2081045999714513,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.206556455534201,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.205002373481919,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.203442105110272,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.201807976760422,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.2000474682591196,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.198255869880387,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1964532120111526,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1946428961118234,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.192824525476774,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.190997692157037,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1891619608168322,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.18731686181005,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1853729287943864,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1833823275285744,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1813818565778558,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1793708514344896,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1773485019068546,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1750923461904996,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1724269870889916,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1688097383147493,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.164431315786477,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1601428521729273,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.155928671385978,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1517808778927843,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.147692401327261,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.143657984476388,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.139672889663036,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1357326250679844,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1318328096942443,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.1246412625004822,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.116910377031402,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.108007439927908,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0968067098849565,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0862089828429724,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.076053088560072,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.066226111689722,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.056643908380883,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0472412949820904,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0379663848140854,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0287769260838067,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0196377102078444,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.010518602064906,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(3.0013929487570143,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.9922362140668106,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.9830247240309373,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.968334172279868,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.948855965389169,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.9292438327038712,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.9051492843032776,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.8794369521845846,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.8534325406609047,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.820427932334672,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.786759869401139,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.7496143077991952,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.699497874296658,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.648031116401546,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.5193779563573466,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(2.278066043774487,1.0,0.0)</span></span>
<span class="line"><span>[ Info: Dual{Cells()}(0.051468843077052365,0.0,1.0)</span></span>
<span class="line"><span>╭────────────────┬───────────┬───────────────┬──────────╮</span></span>
<span class="line"><span>│ Iteration type │  Avg/step │  Avg/ministep │    Total │</span></span>
<span class="line"><span>│                │ 138 steps │ 138 ministeps │ (wasted) │</span></span>
<span class="line"><span>├────────────────┼───────────┼───────────────┼──────────┤</span></span>
<span class="line"><span>│ Newton         │   2.12319 │       2.12319 │  293 (0) │</span></span>
<span class="line"><span>│ Linearization  │   3.12319 │       3.12319 │  431 (0) │</span></span>
<span class="line"><span>│ Linear solver  │   2.12319 │       2.12319 │  293 (0) │</span></span>
<span class="line"><span>│ Precond apply  │       0.0 │           0.0 │    0 (0) │</span></span>
<span class="line"><span>╰────────────────┴───────────┴───────────────┴──────────╯</span></span>
<span class="line"><span>╭───────────────┬──────────┬────────────┬─────────╮</span></span>
<span class="line"><span>│ Timing type   │     Each │   Relative │   Total │</span></span>
<span class="line"><span>│               │       ms │ Percentage │       s │</span></span>
<span class="line"><span>├───────────────┼──────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Properties    │   2.8087 │     2.46 % │  0.8230 │</span></span>
<span class="line"><span>│ Equations     │  23.5691 │    30.36 % │ 10.1583 │</span></span>
<span class="line"><span>│ Assembly      │   9.3213 │    12.01 % │  4.0175 │</span></span>
<span class="line"><span>│ Linear solve  │  18.5487 │    16.24 % │  5.4348 │</span></span>
<span class="line"><span>│ Linear setup  │   0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Precond apply │   0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Update        │   5.0422 │     4.42 % │  1.4774 │</span></span>
<span class="line"><span>│ Convergence   │  13.7047 │    17.65 % │  5.9067 │</span></span>
<span class="line"><span>│ Input/Output  │   2.6310 │     1.09 % │  0.3631 │</span></span>
<span class="line"><span>│ Other         │  18.0178 │    15.78 % │  5.2792 │</span></span>
<span class="line"><span>├───────────────┼──────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Total         │ 114.1976 │   100.00 % │ 33.4599 │</span></span>
<span class="line"><span>╰───────────────┴──────────┴────────────┴─────────╯</span></span></code></pre></div><h2 id="Plot-discharge-curve" tabindex="-1">Plot discharge curve <a class="header-anchor" href="#Plot-discharge-curve" aria-label="Permalink to &quot;Plot discharge curve {#Plot-discharge-curve}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model  </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:extra</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:model</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">t </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Controller</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">time </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">E </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">I </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Current</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">400</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Voltage / V&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	E;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current / A&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	I;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+p+`" alt=""></p><h2 id="Plot-potential-on-grid-at-last-time-step" tabindex="-1">Plot potential on grid at last time step <a class="header-anchor" href="#Plot-potential-on-grid-at-last-time-step" aria-label="Permalink to &quot;Plot potential on grid at last time step {#Plot-potential-on-grid-at-last-time-step}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> plot_potential</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(am, cc, label)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	f3D </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">600</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">650</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ax3d </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Potential in </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> electrode (coating and active material)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	maxPhi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[cc][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[am][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])])</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	minPhi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">([</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[cc][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]), </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(state[am][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])])</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, maxPhi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minPhi]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	components </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [am, cc]</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">	for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> component </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> components</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		g </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model[component]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">domain</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">representation</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		phi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[component][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		Jutul</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_data!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax3d, g, phi </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minPhi; colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">	end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	cbar </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Colorbar</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minPhi,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;potential&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">	display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Screen</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), f3D)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">	return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> f3D</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><h2 id="Plot-the-potential-in-the-positive-electrode" tabindex="-1">Plot the potential in the positive electrode <a class="header-anchor" href="#Plot-the-potential-in-the-positive-electrode" aria-label="Permalink to &quot;Plot the potential in the positive electrode {#Plot-the-potential-in-the-positive-electrode}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_potential</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeCc</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;positive&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+t+'" alt=""></p><h2 id="Plot-the-potential-in-the-negative-electrode" tabindex="-1">Plot the potential in the negative electrode <a class="header-anchor" href="#Plot-the-potential-in-the-negative-electrode" aria-label="Permalink to &quot;Plot the potential in the negative electrode {#Plot-the-potential-in-the-negative-electrode}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_potential</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeCc</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;negative&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+e+`" alt=""></p><h2 id="Plot-surface-concentration-on-grid-at-last-time-step" tabindex="-1">Plot surface concentration on grid at last time step <a class="header-anchor" href="#Plot-surface-concentration-on-grid-at-last-time-step" aria-label="Permalink to &quot;Plot surface concentration on grid at last time step {#Plot-surface-concentration-on-grid-at-last-time-step}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> plot_surface_concentration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(component, label)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	f3D </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">600</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">650</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ax3d </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Surface concentration in </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> electrode&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	cs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[component][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Cs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	maxcs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cs)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	mincs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cs)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, maxcs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> mincs]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	g </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model[component]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">domain</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">representation</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	Jutul</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_data!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax3d, g, cs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> mincs;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	cbar </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Colorbar</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> mincs,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;concentration&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">	display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Screen</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), f3D)</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">	return</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> f3D</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><h2 id="Plot-the-surface-concentration-in-the-positive-electrode" tabindex="-1">Plot the surface concentration in the positive electrode <a class="header-anchor" href="#Plot-the-surface-concentration-in-the-positive-electrode" aria-label="Permalink to &quot;Plot the surface concentration in the positive electrode {#Plot-the-surface-concentration-in-the-positive-electrode}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_surface_concentration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:PeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;positive&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+h+'" alt=""></p><h2 id="Plot-the-surface-concentration-in-the-negative-electrode" tabindex="-1">Plot the surface concentration in the negative electrode <a class="header-anchor" href="#Plot-the-surface-concentration-in-the-negative-electrode" aria-label="Permalink to &quot;Plot the surface concentration in the negative electrode {#Plot-the-surface-concentration-in-the-negative-electrode}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_surface_concentration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:NeAm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;negative&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+k+`" alt=""></p><h2 id="Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step" tabindex="-1">Plot electrolyte concentration and potential on grid at last time step <a class="header-anchor" href="#Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step" aria-label="Permalink to &quot;Plot electrolyte concentration and potential on grid at last time step {#Plot-electrolyte-concentration-and-potential-on-grid-at-last-time-step}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">function</span><span style="--shiki-light:#6F42C1;--shiki-dark:#B392F0;"> plot_elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(var, label)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	f3D </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">600</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">650</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ax3d </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]; title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> in electrolyte&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	val </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][var]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	maxval </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> maximum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(val)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	minval </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> minimum</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(val)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, maxval </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minval]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	g </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> model[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">domain</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">representation</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	Jutul</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_cell_data!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax3d, g, val </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.-</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minval;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	cbar </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Colorbar</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f3D[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">];</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :viridis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> colorrange </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.+</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> minval,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">		label </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$label</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">	display</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(GLMakie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Screen</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(), f3D)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	f3D</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span></code></pre></div><h2 id="Plot-of-the-concentration-in-the-electrolyte" tabindex="-1">Plot of the concentration in the electrolyte <a class="header-anchor" href="#Plot-of-the-concentration-in-the-electrolyte" aria-label="Permalink to &quot;Plot of the concentration in the electrolyte {#Plot-of-the-concentration-in-the-electrolyte}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:C</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;concentration&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="`+E+'" alt=""></p><h2 id="Plot-of-the-potential-in-the-electrolyte" tabindex="-1">Plot of the potential in the electrolyte <a class="header-anchor" href="#Plot-of-the-potential-in-the-electrolyte" aria-label="Permalink to &quot;Plot of the potential in the electrolyte {#Plot-of-the-potential-in-the-electrolyte}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">plot_elyte</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;potential&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><img src="'+r+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_3d_demo.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_3d_demo.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',38)]))}const f=a(o,[["render",d]]);export{D as __pageData,f as default};
