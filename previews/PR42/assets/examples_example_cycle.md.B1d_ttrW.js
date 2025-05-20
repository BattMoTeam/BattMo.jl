import{_ as n,c as a,o as e,aA as p}from"./chunks/framework.ClLQvxBi.js";const t="/BattMo.jl/previews/PR42/assets/ywgfijh.BSatcuuy.jpeg",S=JSON.parse('{"title":"Cycling a battery 40 times with a constant current constant voltage (CCCV) control","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_cycle.md","filePath":"examples/example_cycle.md","lastUpdated":null}'),i={name:"examples/example_cycle.md"};function o(l,s,u,h,c,r){return e(),a("div",null,s[0]||(s[0]=[p(`<h1 id="Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control" tabindex="-1">Cycling a battery 40 times with a constant current constant voltage (CCCV) control <a class="header-anchor" href="#Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control" aria-label="Permalink to &quot;Cycling a battery 40 times with a constant current constant voltage (CCCV) control {#Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><p>We use the setup provided in the <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152" target="_blank" rel="noreferrer">p2d_40.json</a> file. In particular, see the data under the <code>Control</code> key.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cell_parameters&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Chen2020_calibrated.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;model_settings&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P2D.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cycling </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cycling_protocols&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;CCCV.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_simulation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;simulation_settings&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;P2D.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cell_parameters </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cell_parameters</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cell)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cycling_protocol </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_cycling_protocol</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_cycling)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_model_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_model)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">simulation_settings </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> load_simulation_settings</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; from_file_path </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> file_path_simulation)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model_setup </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> LithiumIonBattery</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(; model_settings);</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">sim </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Simulation</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(model_setup, cell_parameters, cycling_protocol; simulation_settings);</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">output </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> solve</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(sim; info_level </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">states </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> output[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:states</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">t </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Controller</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">time </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">E </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Phi</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">I </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Current</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span>──────────────────────────────────────────────────</span></span>
<span class="line"><span>Jutul: Simulating 15 hours as 1080 report steps</span></span>
<span class="line"><span>Step    1/1080: Solving start to 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    2/1080: Solving 50 seconds to 1 minute, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    3/1080: Solving 1 minute, 40 seconds to 2 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    4/1080: Solving 2 minutes, 30 seconds to 3 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    5/1080: Solving 3 minutes, 20 seconds to 4 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    6/1080: Solving 4 minutes, 10 seconds to 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step    7/1080: Solving 5 minutes to 5 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    8/1080: Solving 5 minutes, 50 seconds to 6 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step    9/1080: Solving 6 minutes, 40 seconds to 7 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   10/1080: Solving 7 minutes, 30 seconds to 8 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   11/1080: Solving 8 minutes, 20 seconds to 9 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   12/1080: Solving 9 minutes, 10 seconds to 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   13/1080: Solving 10 minutes to 10 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   14/1080: Solving 10 minutes, 50 seconds to 11 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   15/1080: Solving 11 minutes, 40 seconds to 12 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   16/1080: Solving 12 minutes, 30 seconds to 13 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   17/1080: Solving 13 minutes, 20 seconds to 14 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   18/1080: Solving 14 minutes, 10 seconds to 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   19/1080: Solving 15 minutes to 15 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   20/1080: Solving 15 minutes, 50 seconds to 16 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   21/1080: Solving 16 minutes, 40 seconds to 17 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   22/1080: Solving 17 minutes, 30 seconds to 18 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   23/1080: Solving 18 minutes, 20 seconds to 19 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   24/1080: Solving 19 minutes, 10 seconds to 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   25/1080: Solving 20 minutes to 20 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   26/1080: Solving 20 minutes, 50 seconds to 21 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   27/1080: Solving 21 minutes, 40 seconds to 22 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   28/1080: Solving 22 minutes, 30 seconds to 23 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   29/1080: Solving 23 minutes, 20 seconds to 24 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   30/1080: Solving 24 minutes, 10 seconds to 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   31/1080: Solving 25 minutes to 25 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   32/1080: Solving 25 minutes, 50 seconds to 26 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   33/1080: Solving 26 minutes, 40 seconds to 27 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   34/1080: Solving 27 minutes, 30 seconds to 28 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   35/1080: Solving 28 minutes, 20 seconds to 29 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   36/1080: Solving 29 minutes, 10 seconds to 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   37/1080: Solving 30 minutes to 30 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   38/1080: Solving 30 minutes, 50 seconds to 31 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   39/1080: Solving 31 minutes, 40 seconds to 32 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   40/1080: Solving 32 minutes, 30 seconds to 33 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Convergence: Report step 40, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 40, mini-step #3 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 40, mini-step #4 (12 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 40, mini-step #6 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 40, mini-step #7 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 40, mini-step #8 (4 seconds, 687.5 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Step   41/1080: Solving 33 minutes, 20 seconds to 34 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   42/1080: Solving 34 minutes, 10 seconds to 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   43/1080: Solving 35 minutes to 35 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   44/1080: Solving 35 minutes, 50 seconds to 36 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   45/1080: Solving 36 minutes, 40 seconds to 37 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   46/1080: Solving 37 minutes, 30 seconds to 38 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   47/1080: Solving 38 minutes, 20 seconds to 39 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   48/1080: Solving 39 minutes, 10 seconds to 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   49/1080: Solving 40 minutes to 40 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   50/1080: Solving 40 minutes, 50 seconds to 41 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   51/1080: Solving 41 minutes, 40 seconds to 42 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   52/1080: Solving 42 minutes, 30 seconds to 43 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   53/1080: Solving 43 minutes, 20 seconds to 44 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   54/1080: Solving 44 minutes, 10 seconds to 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   55/1080: Solving 45 minutes to 45 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   56/1080: Solving 45 minutes, 50 seconds to 46 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   57/1080: Solving 46 minutes, 40 seconds to 47 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   58/1080: Solving 47 minutes, 30 seconds to 48 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   59/1080: Solving 48 minutes, 20 seconds to 49 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   60/1080: Solving 49 minutes, 10 seconds to 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   61/1080: Solving 50 minutes to 50 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   62/1080: Solving 50 minutes, 50 seconds to 51 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   63/1080: Solving 51 minutes, 40 seconds to 52 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   64/1080: Solving 52 minutes, 30 seconds to 53 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   65/1080: Solving 53 minutes, 20 seconds to 54 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   66/1080: Solving 54 minutes, 10 seconds to 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   67/1080: Solving 55 minutes to 55 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   68/1080: Solving 55 minutes, 50 seconds to 56 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   69/1080: Solving 56 minutes, 40 seconds to 57 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   70/1080: Solving 57 minutes, 30 seconds to 58 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   71/1080: Solving 58 minutes, 20 seconds to 59 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   72/1080: Solving 59 minutes, 10 seconds to 1 hour, Δt = 50 seconds</span></span>
<span class="line"><span>Step   73/1080: Solving 1 hour to 1 hour, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step   74/1080: Solving 1 hour, 50 seconds to 1 hour, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step   75/1080: Solving 1 hour, 1.667 minute to 1 hour, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   76/1080: Solving 1 hour, 2.5 minutes to 1 hour, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   77/1080: Solving 1 hour, 3.333 minutes to 1 hour, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   78/1080: Solving 1 hour, 4.167 minutes to 1 hour, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   79/1080: Solving 1 hour, 5 minutes to 1 hour, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   80/1080: Solving 1 hour, 5.833 minutes to 1 hour, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   81/1080: Solving 1 hour, 6.667 minutes to 1 hour, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   82/1080: Solving 1 hour, 7.5 minutes to 1 hour, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   83/1080: Solving 1 hour, 8.333 minutes to 1 hour, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   84/1080: Solving 1 hour, 9.167 minutes to 1 hour, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   85/1080: Solving 1 hour, 10 minutes to 1 hour, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   86/1080: Solving 1 hour, 10.83 minutes to 1 hour, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   87/1080: Solving 1 hour, 11.67 minutes to 1 hour, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   88/1080: Solving 1 hour, 12.5 minutes to 1 hour, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   89/1080: Solving 1 hour, 13.33 minutes to 1 hour, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   90/1080: Solving 1 hour, 14.17 minutes to 1 hour, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   91/1080: Solving 1 hour, 15 minutes to 1 hour, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   92/1080: Solving 1 hour, 15.83 minutes to 1 hour, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   93/1080: Solving 1 hour, 16.67 minutes to 1 hour, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   94/1080: Solving 1 hour, 17.5 minutes to 1 hour, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   95/1080: Solving 1 hour, 18.33 minutes to 1 hour, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   96/1080: Solving 1 hour, 19.17 minutes to 1 hour, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   97/1080: Solving 1 hour, 20 minutes to 1 hour, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   98/1080: Solving 1 hour, 20.83 minutes to 1 hour, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step   99/1080: Solving 1 hour, 21.67 minutes to 1 hour, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  100/1080: Solving 1 hour, 22.5 minutes to 1 hour, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  101/1080: Solving 1 hour, 23.33 minutes to 1 hour, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  102/1080: Solving 1 hour, 24.17 minutes to 1 hour, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  103/1080: Solving 1 hour, 25 minutes to 1 hour, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  104/1080: Solving 1 hour, 25.83 minutes to 1 hour, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  105/1080: Solving 1 hour, 26.67 minutes to 1 hour, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  106/1080: Solving 1 hour, 27.5 minutes to 1 hour, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  107/1080: Solving 1 hour, 28.33 minutes to 1 hour, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  108/1080: Solving 1 hour, 29.17 minutes to 1 hour, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  109/1080: Solving 1 hour, 30 minutes to 1 hour, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  110/1080: Solving 1 hour, 30.83 minutes to 1 hour, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  111/1080: Solving 1 hour, 31.67 minutes to 1 hour, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  112/1080: Solving 1 hour, 32.5 minutes to 1 hour, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  113/1080: Solving 1 hour, 33.33 minutes to 1 hour, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  114/1080: Solving 1 hour, 34.17 minutes to 1 hour, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  115/1080: Solving 1 hour, 35 minutes to 1 hour, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  116/1080: Solving 1 hour, 35.83 minutes to 1 hour, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  117/1080: Solving 1 hour, 36.67 minutes to 1 hour, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  118/1080: Solving 1 hour, 37.5 minutes to 1 hour, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  119/1080: Solving 1 hour, 38.33 minutes to 1 hour, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  120/1080: Solving 1 hour, 39.17 minutes to 1 hour, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  121/1080: Solving 1 hour, 40 minutes to 1 hour, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  122/1080: Solving 1 hour, 40.83 minutes to 1 hour, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  123/1080: Solving 1 hour, 41.67 minutes to 1 hour, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  124/1080: Solving 1 hour, 42.5 minutes to 1 hour, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  125/1080: Solving 1 hour, 43.33 minutes to 1 hour, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  126/1080: Solving 1 hour, 44.17 minutes to 1 hour, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  127/1080: Solving 1 hour, 45 minutes to 1 hour, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  128/1080: Solving 1 hour, 45.83 minutes to 1 hour, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  129/1080: Solving 1 hour, 46.67 minutes to 1 hour, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  130/1080: Solving 1 hour, 47.5 minutes to 1 hour, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  131/1080: Solving 1 hour, 48.33 minutes to 1 hour, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  132/1080: Solving 1 hour, 49.17 minutes to 1 hour, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  133/1080: Solving 1 hour, 50 minutes to 1 hour, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  134/1080: Solving 1 hour, 50.83 minutes to 1 hour, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  135/1080: Solving 1 hour, 51.67 minutes to 1 hour, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  136/1080: Solving 1 hour, 52.5 minutes to 1 hour, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  137/1080: Solving 1 hour, 53.33 minutes to 1 hour, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  138/1080: Solving 1 hour, 54.17 minutes to 1 hour, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  139/1080: Solving 1 hour, 55 minutes to 1 hour, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  140/1080: Solving 1 hour, 55.83 minutes to 1 hour, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  141/1080: Solving 1 hour, 56.67 minutes to 1 hour, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  142/1080: Solving 1 hour, 57.5 minutes to 1 hour, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  143/1080: Solving 1 hour, 58.33 minutes to 1 hour, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  144/1080: Solving 1 hour, 59.17 minutes to 2 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  145/1080: Solving 2 hours to 2 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  146/1080: Solving 2 hours, 50 seconds to 2 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  147/1080: Solving 2 hours, 1.667 minute to 2 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  148/1080: Solving 2 hours, 2.5 minutes to 2 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  149/1080: Solving 2 hours, 3.333 minutes to 2 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  150/1080: Solving 2 hours, 4.167 minutes to 2 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  151/1080: Solving 2 hours, 5 minutes to 2 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  152/1080: Solving 2 hours, 5.833 minutes to 2 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  153/1080: Solving 2 hours, 6.667 minutes to 2 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  154/1080: Solving 2 hours, 7.5 minutes to 2 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  155/1080: Solving 2 hours, 8.333 minutes to 2 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  156/1080: Solving 2 hours, 9.167 minutes to 2 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  157/1080: Solving 2 hours, 10 minutes to 2 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  158/1080: Solving 2 hours, 10.83 minutes to 2 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  159/1080: Solving 2 hours, 11.67 minutes to 2 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  160/1080: Solving 2 hours, 12.5 minutes to 2 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  161/1080: Solving 2 hours, 13.33 minutes to 2 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  162/1080: Solving 2 hours, 14.17 minutes to 2 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  163/1080: Solving 2 hours, 15 minutes to 2 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  164/1080: Solving 2 hours, 15.83 minutes to 2 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  165/1080: Solving 2 hours, 16.67 minutes to 2 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  166/1080: Solving 2 hours, 17.5 minutes to 2 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  167/1080: Solving 2 hours, 18.33 minutes to 2 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  168/1080: Solving 2 hours, 19.17 minutes to 2 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  169/1080: Solving 2 hours, 20 minutes to 2 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  170/1080: Solving 2 hours, 20.83 minutes to 2 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  171/1080: Solving 2 hours, 21.67 minutes to 2 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  172/1080: Solving 2 hours, 22.5 minutes to 2 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  173/1080: Solving 2 hours, 23.33 minutes to 2 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  174/1080: Solving 2 hours, 24.17 minutes to 2 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  175/1080: Solving 2 hours, 25 minutes to 2 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  176/1080: Solving 2 hours, 25.83 minutes to 2 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  177/1080: Solving 2 hours, 26.67 minutes to 2 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  178/1080: Solving 2 hours, 27.5 minutes to 2 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  179/1080: Solving 2 hours, 28.33 minutes to 2 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  180/1080: Solving 2 hours, 29.17 minutes to 2 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  181/1080: Solving 2 hours, 30 minutes to 2 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  182/1080: Solving 2 hours, 30.83 minutes to 2 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  183/1080: Solving 2 hours, 31.67 minutes to 2 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  184/1080: Solving 2 hours, 32.5 minutes to 2 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  185/1080: Solving 2 hours, 33.33 minutes to 2 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  186/1080: Solving 2 hours, 34.17 minutes to 2 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  187/1080: Solving 2 hours, 35 minutes to 2 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  188/1080: Solving 2 hours, 35.83 minutes to 2 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  189/1080: Solving 2 hours, 36.67 minutes to 2 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  190/1080: Solving 2 hours, 37.5 minutes to 2 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  191/1080: Solving 2 hours, 38.33 minutes to 2 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  192/1080: Solving 2 hours, 39.17 minutes to 2 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  193/1080: Solving 2 hours, 40 minutes to 2 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  194/1080: Solving 2 hours, 40.83 minutes to 2 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  195/1080: Solving 2 hours, 41.67 minutes to 2 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  196/1080: Solving 2 hours, 42.5 minutes to 2 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  197/1080: Solving 2 hours, 43.33 minutes to 2 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  198/1080: Solving 2 hours, 44.17 minutes to 2 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  199/1080: Solving 2 hours, 45 minutes to 2 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  200/1080: Solving 2 hours, 45.83 minutes to 2 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  201/1080: Solving 2 hours, 46.67 minutes to 2 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  202/1080: Solving 2 hours, 47.5 minutes to 2 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  203/1080: Solving 2 hours, 48.33 minutes to 2 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  204/1080: Solving 2 hours, 49.17 minutes to 2 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  205/1080: Solving 2 hours, 50 minutes to 2 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  206/1080: Solving 2 hours, 50.83 minutes to 2 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  207/1080: Solving 2 hours, 51.67 minutes to 2 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  208/1080: Solving 2 hours, 52.5 minutes to 2 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  209/1080: Solving 2 hours, 53.33 minutes to 2 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  210/1080: Solving 2 hours, 54.17 minutes to 2 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  211/1080: Solving 2 hours, 55 minutes to 2 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  212/1080: Solving 2 hours, 55.83 minutes to 2 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  213/1080: Solving 2 hours, 56.67 minutes to 2 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  214/1080: Solving 2 hours, 57.5 minutes to 2 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  215/1080: Solving 2 hours, 58.33 minutes to 2 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  216/1080: Solving 2 hours, 59.17 minutes to 3 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  217/1080: Solving 3 hours to 3 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  218/1080: Solving 3 hours, 50 seconds to 3 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  219/1080: Solving 3 hours, 1.667 minute to 3 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  220/1080: Solving 3 hours, 2.5 minutes to 3 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  221/1080: Solving 3 hours, 3.333 minutes to 3 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  222/1080: Solving 3 hours, 4.167 minutes to 3 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  223/1080: Solving 3 hours, 5 minutes to 3 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  224/1080: Solving 3 hours, 5.833 minutes to 3 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  225/1080: Solving 3 hours, 6.667 minutes to 3 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  226/1080: Solving 3 hours, 7.5 minutes to 3 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  227/1080: Solving 3 hours, 8.333 minutes to 3 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  228/1080: Solving 3 hours, 9.167 minutes to 3 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  229/1080: Solving 3 hours, 10 minutes to 3 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  230/1080: Solving 3 hours, 10.83 minutes to 3 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  231/1080: Solving 3 hours, 11.67 minutes to 3 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  232/1080: Solving 3 hours, 12.5 minutes to 3 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  233/1080: Solving 3 hours, 13.33 minutes to 3 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  234/1080: Solving 3 hours, 14.17 minutes to 3 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  235/1080: Solving 3 hours, 15 minutes to 3 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  236/1080: Solving 3 hours, 15.83 minutes to 3 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  237/1080: Solving 3 hours, 16.67 minutes to 3 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  238/1080: Solving 3 hours, 17.5 minutes to 3 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  239/1080: Solving 3 hours, 18.33 minutes to 3 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  240/1080: Solving 3 hours, 19.17 minutes to 3 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  241/1080: Solving 3 hours, 20 minutes to 3 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  242/1080: Solving 3 hours, 20.83 minutes to 3 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  243/1080: Solving 3 hours, 21.67 minutes to 3 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  244/1080: Solving 3 hours, 22.5 minutes to 3 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  245/1080: Solving 3 hours, 23.33 minutes to 3 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  246/1080: Solving 3 hours, 24.17 minutes to 3 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  247/1080: Solving 3 hours, 25 minutes to 3 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  248/1080: Solving 3 hours, 25.83 minutes to 3 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  249/1080: Solving 3 hours, 26.67 minutes to 3 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  250/1080: Solving 3 hours, 27.5 minutes to 3 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  251/1080: Solving 3 hours, 28.33 minutes to 3 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  252/1080: Solving 3 hours, 29.17 minutes to 3 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Convergence: Report step 252, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 252, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 252, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 252, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 252, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Step  253/1080: Solving 3 hours, 30 minutes to 3 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  254/1080: Solving 3 hours, 30.83 minutes to 3 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  255/1080: Solving 3 hours, 31.67 minutes to 3 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  256/1080: Solving 3 hours, 32.5 minutes to 3 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  257/1080: Solving 3 hours, 33.33 minutes to 3 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  258/1080: Solving 3 hours, 34.17 minutes to 3 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  259/1080: Solving 3 hours, 35 minutes to 3 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  260/1080: Solving 3 hours, 35.83 minutes to 3 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  261/1080: Solving 3 hours, 36.67 minutes to 3 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  262/1080: Solving 3 hours, 37.5 minutes to 3 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  263/1080: Solving 3 hours, 38.33 minutes to 3 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  264/1080: Solving 3 hours, 39.17 minutes to 3 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  265/1080: Solving 3 hours, 40 minutes to 3 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  266/1080: Solving 3 hours, 40.83 minutes to 3 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  267/1080: Solving 3 hours, 41.67 minutes to 3 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  268/1080: Solving 3 hours, 42.5 minutes to 3 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  269/1080: Solving 3 hours, 43.33 minutes to 3 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  270/1080: Solving 3 hours, 44.17 minutes to 3 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  271/1080: Solving 3 hours, 45 minutes to 3 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  272/1080: Solving 3 hours, 45.83 minutes to 3 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  273/1080: Solving 3 hours, 46.67 minutes to 3 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  274/1080: Solving 3 hours, 47.5 minutes to 3 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  275/1080: Solving 3 hours, 48.33 minutes to 3 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  276/1080: Solving 3 hours, 49.17 minutes to 3 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  277/1080: Solving 3 hours, 50 minutes to 3 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  278/1080: Solving 3 hours, 50.83 minutes to 3 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  279/1080: Solving 3 hours, 51.67 minutes to 3 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  280/1080: Solving 3 hours, 52.5 minutes to 3 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  281/1080: Solving 3 hours, 53.33 minutes to 3 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  282/1080: Solving 3 hours, 54.17 minutes to 3 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  283/1080: Solving 3 hours, 55 minutes to 3 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  284/1080: Solving 3 hours, 55.83 minutes to 3 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  285/1080: Solving 3 hours, 56.67 minutes to 3 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  286/1080: Solving 3 hours, 57.5 minutes to 3 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  287/1080: Solving 3 hours, 58.33 minutes to 3 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  288/1080: Solving 3 hours, 59.17 minutes to 4 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  289/1080: Solving 4 hours to 4 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  290/1080: Solving 4 hours, 50 seconds to 4 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  291/1080: Solving 4 hours, 1.667 minute to 4 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  292/1080: Solving 4 hours, 2.5 minutes to 4 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  293/1080: Solving 4 hours, 3.333 minutes to 4 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  294/1080: Solving 4 hours, 4.167 minutes to 4 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  295/1080: Solving 4 hours, 5 minutes to 4 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  296/1080: Solving 4 hours, 5.833 minutes to 4 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  297/1080: Solving 4 hours, 6.667 minutes to 4 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  298/1080: Solving 4 hours, 7.5 minutes to 4 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  299/1080: Solving 4 hours, 8.333 minutes to 4 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Convergence: Report step 299, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 299, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 299, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 299, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 299, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Step  300/1080: Solving 4 hours, 9.167 minutes to 4 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  301/1080: Solving 4 hours, 10 minutes to 4 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  302/1080: Solving 4 hours, 10.83 minutes to 4 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  303/1080: Solving 4 hours, 11.67 minutes to 4 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  304/1080: Solving 4 hours, 12.5 minutes to 4 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  305/1080: Solving 4 hours, 13.33 minutes to 4 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  306/1080: Solving 4 hours, 14.17 minutes to 4 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  307/1080: Solving 4 hours, 15 minutes to 4 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  308/1080: Solving 4 hours, 15.83 minutes to 4 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  309/1080: Solving 4 hours, 16.67 minutes to 4 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  310/1080: Solving 4 hours, 17.5 minutes to 4 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  311/1080: Solving 4 hours, 18.33 minutes to 4 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  312/1080: Solving 4 hours, 19.17 minutes to 4 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  313/1080: Solving 4 hours, 20 minutes to 4 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  314/1080: Solving 4 hours, 20.83 minutes to 4 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  315/1080: Solving 4 hours, 21.67 minutes to 4 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  316/1080: Solving 4 hours, 22.5 minutes to 4 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  317/1080: Solving 4 hours, 23.33 minutes to 4 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  318/1080: Solving 4 hours, 24.17 minutes to 4 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  319/1080: Solving 4 hours, 25 minutes to 4 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  320/1080: Solving 4 hours, 25.83 minutes to 4 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  321/1080: Solving 4 hours, 26.67 minutes to 4 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  322/1080: Solving 4 hours, 27.5 minutes to 4 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  323/1080: Solving 4 hours, 28.33 minutes to 4 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  324/1080: Solving 4 hours, 29.17 minutes to 4 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  325/1080: Solving 4 hours, 30 minutes to 4 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  326/1080: Solving 4 hours, 30.83 minutes to 4 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  327/1080: Solving 4 hours, 31.67 minutes to 4 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  328/1080: Solving 4 hours, 32.5 minutes to 4 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  329/1080: Solving 4 hours, 33.33 minutes to 4 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  330/1080: Solving 4 hours, 34.17 minutes to 4 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  331/1080: Solving 4 hours, 35 minutes to 4 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  332/1080: Solving 4 hours, 35.83 minutes to 4 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  333/1080: Solving 4 hours, 36.67 minutes to 4 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  334/1080: Solving 4 hours, 37.5 minutes to 4 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  335/1080: Solving 4 hours, 38.33 minutes to 4 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  336/1080: Solving 4 hours, 39.17 minutes to 4 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  337/1080: Solving 4 hours, 40 minutes to 4 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  338/1080: Solving 4 hours, 40.83 minutes to 4 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  339/1080: Solving 4 hours, 41.67 minutes to 4 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  340/1080: Solving 4 hours, 42.5 minutes to 4 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  341/1080: Solving 4 hours, 43.33 minutes to 4 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  342/1080: Solving 4 hours, 44.17 minutes to 4 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  343/1080: Solving 4 hours, 45 minutes to 4 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  344/1080: Solving 4 hours, 45.83 minutes to 4 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  345/1080: Solving 4 hours, 46.67 minutes to 4 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  346/1080: Solving 4 hours, 47.5 minutes to 4 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  347/1080: Solving 4 hours, 48.33 minutes to 4 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  348/1080: Solving 4 hours, 49.17 minutes to 4 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  349/1080: Solving 4 hours, 50 minutes to 4 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  350/1080: Solving 4 hours, 50.83 minutes to 4 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  351/1080: Solving 4 hours, 51.67 minutes to 4 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  352/1080: Solving 4 hours, 52.5 minutes to 4 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  353/1080: Solving 4 hours, 53.33 minutes to 4 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  354/1080: Solving 4 hours, 54.17 minutes to 4 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  355/1080: Solving 4 hours, 55 minutes to 4 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  356/1080: Solving 4 hours, 55.83 minutes to 4 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  357/1080: Solving 4 hours, 56.67 minutes to 4 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  358/1080: Solving 4 hours, 57.5 minutes to 4 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  359/1080: Solving 4 hours, 58.33 minutes to 4 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  360/1080: Solving 4 hours, 59.17 minutes to 5 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  361/1080: Solving 5 hours to 5 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  362/1080: Solving 5 hours, 50 seconds to 5 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  363/1080: Solving 5 hours, 1.667 minute to 5 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  364/1080: Solving 5 hours, 2.5 minutes to 5 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  365/1080: Solving 5 hours, 3.333 minutes to 5 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  366/1080: Solving 5 hours, 4.167 minutes to 5 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  367/1080: Solving 5 hours, 5 minutes to 5 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  368/1080: Solving 5 hours, 5.833 minutes to 5 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  369/1080: Solving 5 hours, 6.667 minutes to 5 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  370/1080: Solving 5 hours, 7.5 minutes to 5 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  371/1080: Solving 5 hours, 8.333 minutes to 5 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  372/1080: Solving 5 hours, 9.167 minutes to 5 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  373/1080: Solving 5 hours, 10 minutes to 5 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  374/1080: Solving 5 hours, 10.83 minutes to 5 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  375/1080: Solving 5 hours, 11.67 minutes to 5 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  376/1080: Solving 5 hours, 12.5 minutes to 5 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  377/1080: Solving 5 hours, 13.33 minutes to 5 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  378/1080: Solving 5 hours, 14.17 minutes to 5 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  379/1080: Solving 5 hours, 15 minutes to 5 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  380/1080: Solving 5 hours, 15.83 minutes to 5 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  381/1080: Solving 5 hours, 16.67 minutes to 5 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  382/1080: Solving 5 hours, 17.5 minutes to 5 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  383/1080: Solving 5 hours, 18.33 minutes to 5 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  384/1080: Solving 5 hours, 19.17 minutes to 5 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  385/1080: Solving 5 hours, 20 minutes to 5 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  386/1080: Solving 5 hours, 20.83 minutes to 5 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  387/1080: Solving 5 hours, 21.67 minutes to 5 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  388/1080: Solving 5 hours, 22.5 minutes to 5 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  389/1080: Solving 5 hours, 23.33 minutes to 5 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  390/1080: Solving 5 hours, 24.17 minutes to 5 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  391/1080: Solving 5 hours, 25 minutes to 5 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  392/1080: Solving 5 hours, 25.83 minutes to 5 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  393/1080: Solving 5 hours, 26.67 minutes to 5 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  394/1080: Solving 5 hours, 27.5 minutes to 5 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  395/1080: Solving 5 hours, 28.33 minutes to 5 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  396/1080: Solving 5 hours, 29.17 minutes to 5 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  397/1080: Solving 5 hours, 30 minutes to 5 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  398/1080: Solving 5 hours, 30.83 minutes to 5 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  399/1080: Solving 5 hours, 31.67 minutes to 5 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  400/1080: Solving 5 hours, 32.5 minutes to 5 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  401/1080: Solving 5 hours, 33.33 minutes to 5 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  402/1080: Solving 5 hours, 34.17 minutes to 5 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  403/1080: Solving 5 hours, 35 minutes to 5 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  404/1080: Solving 5 hours, 35.83 minutes to 5 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  405/1080: Solving 5 hours, 36.67 minutes to 5 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  406/1080: Solving 5 hours, 37.5 minutes to 5 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  407/1080: Solving 5 hours, 38.33 minutes to 5 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  408/1080: Solving 5 hours, 39.17 minutes to 5 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  409/1080: Solving 5 hours, 40 minutes to 5 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  410/1080: Solving 5 hours, 40.83 minutes to 5 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  411/1080: Solving 5 hours, 41.67 minutes to 5 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  412/1080: Solving 5 hours, 42.5 minutes to 5 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  413/1080: Solving 5 hours, 43.33 minutes to 5 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  414/1080: Solving 5 hours, 44.17 minutes to 5 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  415/1080: Solving 5 hours, 45 minutes to 5 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  416/1080: Solving 5 hours, 45.83 minutes to 5 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  417/1080: Solving 5 hours, 46.67 minutes to 5 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  418/1080: Solving 5 hours, 47.5 minutes to 5 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  419/1080: Solving 5 hours, 48.33 minutes to 5 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  420/1080: Solving 5 hours, 49.17 minutes to 5 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  421/1080: Solving 5 hours, 50 minutes to 5 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  422/1080: Solving 5 hours, 50.83 minutes to 5 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  423/1080: Solving 5 hours, 51.67 minutes to 5 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  424/1080: Solving 5 hours, 52.5 minutes to 5 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  425/1080: Solving 5 hours, 53.33 minutes to 5 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  426/1080: Solving 5 hours, 54.17 minutes to 5 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  427/1080: Solving 5 hours, 55 minutes to 5 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  428/1080: Solving 5 hours, 55.83 minutes to 5 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  429/1080: Solving 5 hours, 56.67 minutes to 5 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  430/1080: Solving 5 hours, 57.5 minutes to 5 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  431/1080: Solving 5 hours, 58.33 minutes to 5 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  432/1080: Solving 5 hours, 59.17 minutes to 6 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  433/1080: Solving 6 hours to 6 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  434/1080: Solving 6 hours, 50 seconds to 6 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  435/1080: Solving 6 hours, 1.667 minute to 6 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  436/1080: Solving 6 hours, 2.5 minutes to 6 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  437/1080: Solving 6 hours, 3.333 minutes to 6 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  438/1080: Solving 6 hours, 4.167 minutes to 6 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  439/1080: Solving 6 hours, 5 minutes to 6 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  440/1080: Solving 6 hours, 5.833 minutes to 6 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  441/1080: Solving 6 hours, 6.667 minutes to 6 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  442/1080: Solving 6 hours, 7.5 minutes to 6 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  443/1080: Solving 6 hours, 8.333 minutes to 6 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  444/1080: Solving 6 hours, 9.167 minutes to 6 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  445/1080: Solving 6 hours, 10 minutes to 6 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  446/1080: Solving 6 hours, 10.83 minutes to 6 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  447/1080: Solving 6 hours, 11.67 minutes to 6 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  448/1080: Solving 6 hours, 12.5 minutes to 6 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  449/1080: Solving 6 hours, 13.33 minutes to 6 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  450/1080: Solving 6 hours, 14.17 minutes to 6 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  451/1080: Solving 6 hours, 15 minutes to 6 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  452/1080: Solving 6 hours, 15.83 minutes to 6 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  453/1080: Solving 6 hours, 16.67 minutes to 6 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  454/1080: Solving 6 hours, 17.5 minutes to 6 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  455/1080: Solving 6 hours, 18.33 minutes to 6 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  456/1080: Solving 6 hours, 19.17 minutes to 6 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  457/1080: Solving 6 hours, 20 minutes to 6 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  458/1080: Solving 6 hours, 20.83 minutes to 6 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  459/1080: Solving 6 hours, 21.67 minutes to 6 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  460/1080: Solving 6 hours, 22.5 minutes to 6 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  461/1080: Solving 6 hours, 23.33 minutes to 6 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  462/1080: Solving 6 hours, 24.17 minutes to 6 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  463/1080: Solving 6 hours, 25 minutes to 6 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  464/1080: Solving 6 hours, 25.83 minutes to 6 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  465/1080: Solving 6 hours, 26.67 minutes to 6 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  466/1080: Solving 6 hours, 27.5 minutes to 6 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  467/1080: Solving 6 hours, 28.33 minutes to 6 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  468/1080: Solving 6 hours, 29.17 minutes to 6 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  469/1080: Solving 6 hours, 30 minutes to 6 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  470/1080: Solving 6 hours, 30.83 minutes to 6 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  471/1080: Solving 6 hours, 31.67 minutes to 6 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  472/1080: Solving 6 hours, 32.5 minutes to 6 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  473/1080: Solving 6 hours, 33.33 minutes to 6 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  474/1080: Solving 6 hours, 34.17 minutes to 6 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  475/1080: Solving 6 hours, 35 minutes to 6 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  476/1080: Solving 6 hours, 35.83 minutes to 6 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  477/1080: Solving 6 hours, 36.67 minutes to 6 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  478/1080: Solving 6 hours, 37.5 minutes to 6 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  479/1080: Solving 6 hours, 38.33 minutes to 6 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  480/1080: Solving 6 hours, 39.17 minutes to 6 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  481/1080: Solving 6 hours, 40 minutes to 6 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  482/1080: Solving 6 hours, 40.83 minutes to 6 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  483/1080: Solving 6 hours, 41.67 minutes to 6 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  484/1080: Solving 6 hours, 42.5 minutes to 6 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  485/1080: Solving 6 hours, 43.33 minutes to 6 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  486/1080: Solving 6 hours, 44.17 minutes to 6 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  487/1080: Solving 6 hours, 45 minutes to 6 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  488/1080: Solving 6 hours, 45.83 minutes to 6 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  489/1080: Solving 6 hours, 46.67 minutes to 6 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  490/1080: Solving 6 hours, 47.5 minutes to 6 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  491/1080: Solving 6 hours, 48.33 minutes to 6 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  492/1080: Solving 6 hours, 49.17 minutes to 6 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  493/1080: Solving 6 hours, 50 minutes to 6 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  494/1080: Solving 6 hours, 50.83 minutes to 6 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  495/1080: Solving 6 hours, 51.67 minutes to 6 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  496/1080: Solving 6 hours, 52.5 minutes to 6 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  497/1080: Solving 6 hours, 53.33 minutes to 6 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  498/1080: Solving 6 hours, 54.17 minutes to 6 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  499/1080: Solving 6 hours, 55 minutes to 6 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  500/1080: Solving 6 hours, 55.83 minutes to 6 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  501/1080: Solving 6 hours, 56.67 minutes to 6 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  502/1080: Solving 6 hours, 57.5 minutes to 6 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  503/1080: Solving 6 hours, 58.33 minutes to 6 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  504/1080: Solving 6 hours, 59.17 minutes to 7 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  505/1080: Solving 7 hours to 7 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  506/1080: Solving 7 hours, 50 seconds to 7 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  507/1080: Solving 7 hours, 1.667 minute to 7 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  508/1080: Solving 7 hours, 2.5 minutes to 7 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  509/1080: Solving 7 hours, 3.333 minutes to 7 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  510/1080: Solving 7 hours, 4.167 minutes to 7 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Convergence: Report step 510, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 510, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 510, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 510, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 510, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Step  511/1080: Solving 7 hours, 5 minutes to 7 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  512/1080: Solving 7 hours, 5.833 minutes to 7 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  513/1080: Solving 7 hours, 6.667 minutes to 7 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  514/1080: Solving 7 hours, 7.5 minutes to 7 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  515/1080: Solving 7 hours, 8.333 minutes to 7 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  516/1080: Solving 7 hours, 9.167 minutes to 7 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  517/1080: Solving 7 hours, 10 minutes to 7 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  518/1080: Solving 7 hours, 10.83 minutes to 7 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  519/1080: Solving 7 hours, 11.67 minutes to 7 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  520/1080: Solving 7 hours, 12.5 minutes to 7 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  521/1080: Solving 7 hours, 13.33 minutes to 7 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  522/1080: Solving 7 hours, 14.17 minutes to 7 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  523/1080: Solving 7 hours, 15 minutes to 7 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  524/1080: Solving 7 hours, 15.83 minutes to 7 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  525/1080: Solving 7 hours, 16.67 minutes to 7 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  526/1080: Solving 7 hours, 17.5 minutes to 7 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  527/1080: Solving 7 hours, 18.33 minutes to 7 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  528/1080: Solving 7 hours, 19.17 minutes to 7 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  529/1080: Solving 7 hours, 20 minutes to 7 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  530/1080: Solving 7 hours, 20.83 minutes to 7 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  531/1080: Solving 7 hours, 21.67 minutes to 7 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  532/1080: Solving 7 hours, 22.5 minutes to 7 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  533/1080: Solving 7 hours, 23.33 minutes to 7 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  534/1080: Solving 7 hours, 24.17 minutes to 7 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  535/1080: Solving 7 hours, 25 minutes to 7 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  536/1080: Solving 7 hours, 25.83 minutes to 7 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  537/1080: Solving 7 hours, 26.67 minutes to 7 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  538/1080: Solving 7 hours, 27.5 minutes to 7 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  539/1080: Solving 7 hours, 28.33 minutes to 7 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  540/1080: Solving 7 hours, 29.17 minutes to 7 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  541/1080: Solving 7 hours, 30 minutes to 7 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  542/1080: Solving 7 hours, 30.83 minutes to 7 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  543/1080: Solving 7 hours, 31.67 minutes to 7 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  544/1080: Solving 7 hours, 32.5 minutes to 7 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  545/1080: Solving 7 hours, 33.33 minutes to 7 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  546/1080: Solving 7 hours, 34.17 minutes to 7 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  547/1080: Solving 7 hours, 35 minutes to 7 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  548/1080: Solving 7 hours, 35.83 minutes to 7 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  549/1080: Solving 7 hours, 36.67 minutes to 7 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  550/1080: Solving 7 hours, 37.5 minutes to 7 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  551/1080: Solving 7 hours, 38.33 minutes to 7 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  552/1080: Solving 7 hours, 39.17 minutes to 7 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  553/1080: Solving 7 hours, 40 minutes to 7 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  554/1080: Solving 7 hours, 40.83 minutes to 7 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  555/1080: Solving 7 hours, 41.67 minutes to 7 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  556/1080: Solving 7 hours, 42.5 minutes to 7 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  557/1080: Solving 7 hours, 43.33 minutes to 7 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Convergence: Report step 557, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 557, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 557, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 557, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 557, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Step  558/1080: Solving 7 hours, 44.17 minutes to 7 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  559/1080: Solving 7 hours, 45 minutes to 7 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  560/1080: Solving 7 hours, 45.83 minutes to 7 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  561/1080: Solving 7 hours, 46.67 minutes to 7 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  562/1080: Solving 7 hours, 47.5 minutes to 7 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  563/1080: Solving 7 hours, 48.33 minutes to 7 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  564/1080: Solving 7 hours, 49.17 minutes to 7 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  565/1080: Solving 7 hours, 50 minutes to 7 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  566/1080: Solving 7 hours, 50.83 minutes to 7 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  567/1080: Solving 7 hours, 51.67 minutes to 7 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  568/1080: Solving 7 hours, 52.5 minutes to 7 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  569/1080: Solving 7 hours, 53.33 minutes to 7 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  570/1080: Solving 7 hours, 54.17 minutes to 7 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  571/1080: Solving 7 hours, 55 minutes to 7 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  572/1080: Solving 7 hours, 55.83 minutes to 7 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  573/1080: Solving 7 hours, 56.67 minutes to 7 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  574/1080: Solving 7 hours, 57.5 minutes to 7 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  575/1080: Solving 7 hours, 58.33 minutes to 7 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  576/1080: Solving 7 hours, 59.17 minutes to 8 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  577/1080: Solving 8 hours to 8 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  578/1080: Solving 8 hours, 50 seconds to 8 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  579/1080: Solving 8 hours, 1.667 minute to 8 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  580/1080: Solving 8 hours, 2.5 minutes to 8 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  581/1080: Solving 8 hours, 3.333 minutes to 8 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  582/1080: Solving 8 hours, 4.167 minutes to 8 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  583/1080: Solving 8 hours, 5 minutes to 8 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  584/1080: Solving 8 hours, 5.833 minutes to 8 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  585/1080: Solving 8 hours, 6.667 minutes to 8 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  586/1080: Solving 8 hours, 7.5 minutes to 8 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  587/1080: Solving 8 hours, 8.333 minutes to 8 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  588/1080: Solving 8 hours, 9.167 minutes to 8 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  589/1080: Solving 8 hours, 10 minutes to 8 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  590/1080: Solving 8 hours, 10.83 minutes to 8 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  591/1080: Solving 8 hours, 11.67 minutes to 8 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  592/1080: Solving 8 hours, 12.5 minutes to 8 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  593/1080: Solving 8 hours, 13.33 minutes to 8 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  594/1080: Solving 8 hours, 14.17 minutes to 8 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  595/1080: Solving 8 hours, 15 minutes to 8 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  596/1080: Solving 8 hours, 15.83 minutes to 8 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  597/1080: Solving 8 hours, 16.67 minutes to 8 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  598/1080: Solving 8 hours, 17.5 minutes to 8 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  599/1080: Solving 8 hours, 18.33 minutes to 8 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  600/1080: Solving 8 hours, 19.17 minutes to 8 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  601/1080: Solving 8 hours, 20 minutes to 8 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  602/1080: Solving 8 hours, 20.83 minutes to 8 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  603/1080: Solving 8 hours, 21.67 minutes to 8 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  604/1080: Solving 8 hours, 22.5 minutes to 8 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  605/1080: Solving 8 hours, 23.33 minutes to 8 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  606/1080: Solving 8 hours, 24.17 minutes to 8 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  607/1080: Solving 8 hours, 25 minutes to 8 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  608/1080: Solving 8 hours, 25.83 minutes to 8 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  609/1080: Solving 8 hours, 26.67 minutes to 8 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  610/1080: Solving 8 hours, 27.5 minutes to 8 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  611/1080: Solving 8 hours, 28.33 minutes to 8 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  612/1080: Solving 8 hours, 29.17 minutes to 8 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  613/1080: Solving 8 hours, 30 minutes to 8 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  614/1080: Solving 8 hours, 30.83 minutes to 8 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  615/1080: Solving 8 hours, 31.67 minutes to 8 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  616/1080: Solving 8 hours, 32.5 minutes to 8 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  617/1080: Solving 8 hours, 33.33 minutes to 8 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  618/1080: Solving 8 hours, 34.17 minutes to 8 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  619/1080: Solving 8 hours, 35 minutes to 8 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  620/1080: Solving 8 hours, 35.83 minutes to 8 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  621/1080: Solving 8 hours, 36.67 minutes to 8 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  622/1080: Solving 8 hours, 37.5 minutes to 8 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  623/1080: Solving 8 hours, 38.33 minutes to 8 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  624/1080: Solving 8 hours, 39.17 minutes to 8 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  625/1080: Solving 8 hours, 40 minutes to 8 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  626/1080: Solving 8 hours, 40.83 minutes to 8 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  627/1080: Solving 8 hours, 41.67 minutes to 8 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  628/1080: Solving 8 hours, 42.5 minutes to 8 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  629/1080: Solving 8 hours, 43.33 minutes to 8 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  630/1080: Solving 8 hours, 44.17 minutes to 8 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  631/1080: Solving 8 hours, 45 minutes to 8 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  632/1080: Solving 8 hours, 45.83 minutes to 8 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  633/1080: Solving 8 hours, 46.67 minutes to 8 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  634/1080: Solving 8 hours, 47.5 minutes to 8 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  635/1080: Solving 8 hours, 48.33 minutes to 8 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  636/1080: Solving 8 hours, 49.17 minutes to 8 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  637/1080: Solving 8 hours, 50 minutes to 8 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  638/1080: Solving 8 hours, 50.83 minutes to 8 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  639/1080: Solving 8 hours, 51.67 minutes to 8 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  640/1080: Solving 8 hours, 52.5 minutes to 8 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  641/1080: Solving 8 hours, 53.33 minutes to 8 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  642/1080: Solving 8 hours, 54.17 minutes to 8 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  643/1080: Solving 8 hours, 55 minutes to 8 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  644/1080: Solving 8 hours, 55.83 minutes to 8 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  645/1080: Solving 8 hours, 56.67 minutes to 8 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  646/1080: Solving 8 hours, 57.5 minutes to 8 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  647/1080: Solving 8 hours, 58.33 minutes to 8 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  648/1080: Solving 8 hours, 59.17 minutes to 9 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  649/1080: Solving 9 hours to 9 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  650/1080: Solving 9 hours, 50 seconds to 9 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  651/1080: Solving 9 hours, 1.667 minute to 9 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  652/1080: Solving 9 hours, 2.5 minutes to 9 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  653/1080: Solving 9 hours, 3.333 minutes to 9 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  654/1080: Solving 9 hours, 4.167 minutes to 9 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  655/1080: Solving 9 hours, 5 minutes to 9 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  656/1080: Solving 9 hours, 5.833 minutes to 9 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  657/1080: Solving 9 hours, 6.667 minutes to 9 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  658/1080: Solving 9 hours, 7.5 minutes to 9 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  659/1080: Solving 9 hours, 8.333 minutes to 9 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  660/1080: Solving 9 hours, 9.167 minutes to 9 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  661/1080: Solving 9 hours, 10 minutes to 9 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  662/1080: Solving 9 hours, 10.83 minutes to 9 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  663/1080: Solving 9 hours, 11.67 minutes to 9 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  664/1080: Solving 9 hours, 12.5 minutes to 9 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  665/1080: Solving 9 hours, 13.33 minutes to 9 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  666/1080: Solving 9 hours, 14.17 minutes to 9 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  667/1080: Solving 9 hours, 15 minutes to 9 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  668/1080: Solving 9 hours, 15.83 minutes to 9 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  669/1080: Solving 9 hours, 16.67 minutes to 9 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  670/1080: Solving 9 hours, 17.5 minutes to 9 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  671/1080: Solving 9 hours, 18.33 minutes to 9 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  672/1080: Solving 9 hours, 19.17 minutes to 9 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  673/1080: Solving 9 hours, 20 minutes to 9 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  674/1080: Solving 9 hours, 20.83 minutes to 9 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  675/1080: Solving 9 hours, 21.67 minutes to 9 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  676/1080: Solving 9 hours, 22.5 minutes to 9 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  677/1080: Solving 9 hours, 23.33 minutes to 9 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  678/1080: Solving 9 hours, 24.17 minutes to 9 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  679/1080: Solving 9 hours, 25 minutes to 9 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  680/1080: Solving 9 hours, 25.83 minutes to 9 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  681/1080: Solving 9 hours, 26.67 minutes to 9 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  682/1080: Solving 9 hours, 27.5 minutes to 9 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  683/1080: Solving 9 hours, 28.33 minutes to 9 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  684/1080: Solving 9 hours, 29.17 minutes to 9 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  685/1080: Solving 9 hours, 30 minutes to 9 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  686/1080: Solving 9 hours, 30.83 minutes to 9 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  687/1080: Solving 9 hours, 31.67 minutes to 9 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  688/1080: Solving 9 hours, 32.5 minutes to 9 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  689/1080: Solving 9 hours, 33.33 minutes to 9 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  690/1080: Solving 9 hours, 34.17 minutes to 9 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  691/1080: Solving 9 hours, 35 minutes to 9 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  692/1080: Solving 9 hours, 35.83 minutes to 9 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  693/1080: Solving 9 hours, 36.67 minutes to 9 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  694/1080: Solving 9 hours, 37.5 minutes to 9 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  695/1080: Solving 9 hours, 38.33 minutes to 9 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  696/1080: Solving 9 hours, 39.17 minutes to 9 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  697/1080: Solving 9 hours, 40 minutes to 9 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  698/1080: Solving 9 hours, 40.83 minutes to 9 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  699/1080: Solving 9 hours, 41.67 minutes to 9 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  700/1080: Solving 9 hours, 42.5 minutes to 9 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  701/1080: Solving 9 hours, 43.33 minutes to 9 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  702/1080: Solving 9 hours, 44.17 minutes to 9 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  703/1080: Solving 9 hours, 45 minutes to 9 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  704/1080: Solving 9 hours, 45.83 minutes to 9 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  705/1080: Solving 9 hours, 46.67 minutes to 9 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  706/1080: Solving 9 hours, 47.5 minutes to 9 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  707/1080: Solving 9 hours, 48.33 minutes to 9 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  708/1080: Solving 9 hours, 49.17 minutes to 9 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  709/1080: Solving 9 hours, 50 minutes to 9 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  710/1080: Solving 9 hours, 50.83 minutes to 9 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  711/1080: Solving 9 hours, 51.67 minutes to 9 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  712/1080: Solving 9 hours, 52.5 minutes to 9 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  713/1080: Solving 9 hours, 53.33 minutes to 9 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  714/1080: Solving 9 hours, 54.17 minutes to 9 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  715/1080: Solving 9 hours, 55 minutes to 9 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  716/1080: Solving 9 hours, 55.83 minutes to 9 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  717/1080: Solving 9 hours, 56.67 minutes to 9 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  718/1080: Solving 9 hours, 57.5 minutes to 9 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  719/1080: Solving 9 hours, 58.33 minutes to 9 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  720/1080: Solving 9 hours, 59.17 minutes to 10 hours, Δt = 50 seconds</span></span>
<span class="line"><span>Step  721/1080: Solving 10 hours to 10 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span>Step  722/1080: Solving 10 hours, 50 seconds to 10 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span>Step  723/1080: Solving 10 hours, 1.667 minute to 10 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  724/1080: Solving 10 hours, 2.5 minutes to 10 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  725/1080: Solving 10 hours, 3.333 minutes to 10 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  726/1080: Solving 10 hours, 4.167 minutes to 10 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  727/1080: Solving 10 hours, 5 minutes to 10 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  728/1080: Solving 10 hours, 5.833 minutes to 10 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  729/1080: Solving 10 hours, 6.667 minutes to 10 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  730/1080: Solving 10 hours, 7.5 minutes to 10 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  731/1080: Solving 10 hours, 8.333 minutes to 10 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  732/1080: Solving 10 hours, 9.167 minutes to 10 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  733/1080: Solving 10 hours, 10 minutes to 10 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  734/1080: Solving 10 hours, 10.83 minutes to 10 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  735/1080: Solving 10 hours, 11.67 minutes to 10 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  736/1080: Solving 10 hours, 12.5 minutes to 10 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  737/1080: Solving 10 hours, 13.33 minutes to 10 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  738/1080: Solving 10 hours, 14.17 minutes to 10 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  739/1080: Solving 10 hours, 15 minutes to 10 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  740/1080: Solving 10 hours, 15.83 minutes to 10 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  741/1080: Solving 10 hours, 16.67 minutes to 10 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  742/1080: Solving 10 hours, 17.5 minutes to 10 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  743/1080: Solving 10 hours, 18.33 minutes to 10 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  744/1080: Solving 10 hours, 19.17 minutes to 10 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  745/1080: Solving 10 hours, 20 minutes to 10 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  746/1080: Solving 10 hours, 20.83 minutes to 10 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  747/1080: Solving 10 hours, 21.67 minutes to 10 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  748/1080: Solving 10 hours, 22.5 minutes to 10 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  749/1080: Solving 10 hours, 23.33 minutes to 10 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  750/1080: Solving 10 hours, 24.17 minutes to 10 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  751/1080: Solving 10 hours, 25 minutes to 10 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  752/1080: Solving 10 hours, 25.83 minutes to 10 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  753/1080: Solving 10 hours, 26.67 minutes to 10 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  754/1080: Solving 10 hours, 27.5 minutes to 10 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  755/1080: Solving 10 hours, 28.33 minutes to 10 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  756/1080: Solving 10 hours, 29.17 minutes to 10 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  757/1080: Solving 10 hours, 30 minutes to 10 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  758/1080: Solving 10 hours, 30.83 minutes to 10 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  759/1080: Solving 10 hours, 31.67 minutes to 10 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  760/1080: Solving 10 hours, 32.5 minutes to 10 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  761/1080: Solving 10 hours, 33.33 minutes to 10 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  762/1080: Solving 10 hours, 34.17 minutes to 10 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  763/1080: Solving 10 hours, 35 minutes to 10 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  764/1080: Solving 10 hours, 35.83 minutes to 10 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  765/1080: Solving 10 hours, 36.67 minutes to 10 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  766/1080: Solving 10 hours, 37.5 minutes to 10 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  767/1080: Solving 10 hours, 38.33 minutes to 10 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  768/1080: Solving 10 hours, 39.17 minutes to 10 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Convergence: Report step 768, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 768, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 768, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 768, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Convergence: Report step 768, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span>Step  769/1080: Solving 10 hours, 40 minutes to 10 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  770/1080: Solving 10 hours, 40.83 minutes to 10 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  771/1080: Solving 10 hours, 41.67 minutes to 10 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  772/1080: Solving 10 hours, 42.5 minutes to 10 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  773/1080: Solving 10 hours, 43.33 minutes to 10 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  774/1080: Solving 10 hours, 44.17 minutes to 10 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  775/1080: Solving 10 hours, 45 minutes to 10 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  776/1080: Solving 10 hours, 45.83 minutes to 10 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  777/1080: Solving 10 hours, 46.67 minutes to 10 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  778/1080: Solving 10 hours, 47.5 minutes to 10 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  779/1080: Solving 10 hours, 48.33 minutes to 10 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  780/1080: Solving 10 hours, 49.17 minutes to 10 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  781/1080: Solving 10 hours, 50 minutes to 10 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  782/1080: Solving 10 hours, 50.83 minutes to 10 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  783/1080: Solving 10 hours, 51.67 minutes to 10 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  784/1080: Solving 10 hours, 52.5 minutes to 10 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Step  785/1080: Solving 10 hours, 53.33 minutes to 10 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span>Simulation complete: Completed 785 report steps in 12 seconds, 969 milliseconds, 955.9 microseconds and 2157 iterations.</span></span>
<span class="line"><span>╭────────────────┬───────────┬───────────────┬────────────╮</span></span>
<span class="line"><span>│ Iteration type │  Avg/step │  Avg/ministep │      Total │</span></span>
<span class="line"><span>│                │ 785 steps │ 829 ministeps │   (wasted) │</span></span>
<span class="line"><span>├────────────────┼───────────┼───────────────┼────────────┤</span></span>
<span class="line"><span>│ Newton         │   2.74777 │       2.60193 │ 2157 (465) │</span></span>
<span class="line"><span>│ Linearization  │   3.80382 │       3.60193 │ 2986 (496) │</span></span>
<span class="line"><span>│ Linear solver  │   2.74777 │       2.60193 │ 2157 (465) │</span></span>
<span class="line"><span>│ Precond apply  │       0.0 │           0.0 │      0 (0) │</span></span>
<span class="line"><span>╰────────────────┴───────────┴───────────────┴────────────╯</span></span>
<span class="line"><span>╭───────────────┬────────┬────────────┬─────────╮</span></span>
<span class="line"><span>│ Timing type   │   Each │   Relative │   Total │</span></span>
<span class="line"><span>│               │     ms │ Percentage │       s │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Properties    │ 0.0327 │     0.54 % │  0.0705 │</span></span>
<span class="line"><span>│ Equations     │ 1.8293 │    42.12 % │  5.4624 │</span></span>
<span class="line"><span>│ Assembly      │ 0.3738 │     8.61 % │  1.1162 │</span></span>
<span class="line"><span>│ Linear solve  │ 0.3469 │     5.77 % │  0.7482 │</span></span>
<span class="line"><span>│ Linear setup  │ 0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Precond apply │ 0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span>│ Update        │ 0.2052 │     3.41 % │  0.4426 │</span></span>
<span class="line"><span>│ Convergence   │ 0.4817 │    11.09 % │  1.4385 │</span></span>
<span class="line"><span>│ Input/Output  │ 0.1311 │     0.84 % │  0.1086 │</span></span>
<span class="line"><span>│ Other         │ 1.6611 │    27.63 % │  3.5830 │</span></span>
<span class="line"><span>├───────────────┼────────┼────────────┼─────────┤</span></span>
<span class="line"><span>│ Total         │ 6.0130 │   100.00 % │ 12.9700 │</span></span>
<span class="line"><span>╰───────────────┴────────┴────────────┴─────────╯</span></span></code></pre></div><h2 id="Plot-the-results" tabindex="-1">Plot the results <a class="header-anchor" href="#Plot-the-results" aria-label="Permalink to &quot;Plot the results {#Plot-the-results}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">400</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
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
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	E;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">ax </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Axis</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	title </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Time / s&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabel </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Current / A&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xlabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	ylabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	xticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	yticklabelsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 25</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">scatterlines!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(ax,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	t,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	I;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	linewidth </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markersize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	marker </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :cross</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">	markercolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :black</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f</span></span></code></pre></div><p><img src="`+t+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_cycle.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_cycle.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',12)]))}const d=n(i,[["render",o]]);export{S as __pageData,d as default};
