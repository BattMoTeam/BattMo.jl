import{_ as e,c as n,o as i,aA as t}from"./chunks/framework.CBU9woIg.js";const a="/BattMo.jl/previews/PR57/assets/phoghlz.D_iBJMiX.jpeg",g=JSON.parse('{"title":"Cycling a battery 40 times with a constant current constant voltage (CCCV) control","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_cycle.md","filePath":"examples/example_cycle.md","lastUpdated":null}'),l={name:"examples/example_cycle.md"};function p(h,s,o,k,u,r){return i(),n("div",null,s[0]||(s[0]=[t(`<h1 id="Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control" tabindex="-1">Cycling a battery 40 times with a constant current constant voltage (CCCV) control <a class="header-anchor" href="#Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control" aria-label="Permalink to &quot;Cycling a battery 40 times with a constant current constant voltage (CCCV) control {#Cycling-a-battery-40-times-with-a-constant-current-constant-voltage-CCCV-control}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> BattMo, GLMakie</span></span></code></pre></div><p>We use the setup provided in the <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/test/data/jsonfiles/p2d_40.json#L152" target="_blank" rel="noreferrer">p2d_40.json</a> file. In particular, see the data under the <code>Control</code> key.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">file_path_cell </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> parameter_file_path</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;cell_parameters&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Chen2020.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
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
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">I </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [state[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Control</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:Current</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">][</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> state </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> states]</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of ModelSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of CellParameters passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of CyclingProtocol passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">✔️ Validation of SimulationSettings passed: No issues found.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">──────────────────────────────────────────────────</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Jutul: Simulating 15 hours as 1080 report steps</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    1/1080: Solving start to 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    2/1080: Solving 50 seconds to 1 minute, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    3/1080: Solving 1 minute, 40 seconds to 2 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    4/1080: Solving 2 minutes, 30 seconds to 3 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    5/1080: Solving 3 minutes, 20 seconds to 4 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    6/1080: Solving 4 minutes, 10 seconds to 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    7/1080: Solving 5 minutes to 5 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    8/1080: Solving 5 minutes, 50 seconds to 6 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step    9/1080: Solving 6 minutes, 40 seconds to 7 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   10/1080: Solving 7 minutes, 30 seconds to 8 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   11/1080: Solving 8 minutes, 20 seconds to 9 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   12/1080: Solving 9 minutes, 10 seconds to 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   13/1080: Solving 10 minutes to 10 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   14/1080: Solving 10 minutes, 50 seconds to 11 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   15/1080: Solving 11 minutes, 40 seconds to 12 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   16/1080: Solving 12 minutes, 30 seconds to 13 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   17/1080: Solving 13 minutes, 20 seconds to 14 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   18/1080: Solving 14 minutes, 10 seconds to 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   19/1080: Solving 15 minutes to 15 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   20/1080: Solving 15 minutes, 50 seconds to 16 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   21/1080: Solving 16 minutes, 40 seconds to 17 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   22/1080: Solving 17 minutes, 30 seconds to 18 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   23/1080: Solving 18 minutes, 20 seconds to 19 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   24/1080: Solving 19 minutes, 10 seconds to 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   25/1080: Solving 20 minutes to 20 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   26/1080: Solving 20 minutes, 50 seconds to 21 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   27/1080: Solving 21 minutes, 40 seconds to 22 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   28/1080: Solving 22 minutes, 30 seconds to 23 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   29/1080: Solving 23 minutes, 20 seconds to 24 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   30/1080: Solving 24 minutes, 10 seconds to 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   31/1080: Solving 25 minutes to 25 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   32/1080: Solving 25 minutes, 50 seconds to 26 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   33/1080: Solving 26 minutes, 40 seconds to 27 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   34/1080: Solving 27 minutes, 30 seconds to 28 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   35/1080: Solving 28 minutes, 20 seconds to 29 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   36/1080: Solving 29 minutes, 10 seconds to 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   37/1080: Solving 30 minutes to 30 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   38/1080: Solving 30 minutes, 50 seconds to 31 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   39/1080: Solving 31 minutes, 40 seconds to 32 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   40/1080: Solving 32 minutes, 30 seconds to 33 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 40, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 40, mini-step #3 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 40, mini-step #4 (12 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 40, mini-step #6 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 40, mini-step #7 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 40, mini-step #8 (4 seconds, 687.5 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   41/1080: Solving 33 minutes, 20 seconds to 34 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   42/1080: Solving 34 minutes, 10 seconds to 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   43/1080: Solving 35 minutes to 35 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   44/1080: Solving 35 minutes, 50 seconds to 36 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   45/1080: Solving 36 minutes, 40 seconds to 37 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   46/1080: Solving 37 minutes, 30 seconds to 38 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   47/1080: Solving 38 minutes, 20 seconds to 39 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   48/1080: Solving 39 minutes, 10 seconds to 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   49/1080: Solving 40 minutes to 40 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   50/1080: Solving 40 minutes, 50 seconds to 41 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   51/1080: Solving 41 minutes, 40 seconds to 42 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   52/1080: Solving 42 minutes, 30 seconds to 43 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   53/1080: Solving 43 minutes, 20 seconds to 44 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   54/1080: Solving 44 minutes, 10 seconds to 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   55/1080: Solving 45 minutes to 45 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   56/1080: Solving 45 minutes, 50 seconds to 46 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   57/1080: Solving 46 minutes, 40 seconds to 47 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   58/1080: Solving 47 minutes, 30 seconds to 48 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   59/1080: Solving 48 minutes, 20 seconds to 49 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   60/1080: Solving 49 minutes, 10 seconds to 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   61/1080: Solving 50 minutes to 50 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   62/1080: Solving 50 minutes, 50 seconds to 51 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   63/1080: Solving 51 minutes, 40 seconds to 52 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   64/1080: Solving 52 minutes, 30 seconds to 53 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   65/1080: Solving 53 minutes, 20 seconds to 54 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   66/1080: Solving 54 minutes, 10 seconds to 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   67/1080: Solving 55 minutes to 55 minutes, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   68/1080: Solving 55 minutes, 50 seconds to 56 minutes, 40 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   69/1080: Solving 56 minutes, 40 seconds to 57 minutes, 30 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   70/1080: Solving 57 minutes, 30 seconds to 58 minutes, 20 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   71/1080: Solving 58 minutes, 20 seconds to 59 minutes, 10 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   72/1080: Solving 59 minutes, 10 seconds to 1 hour, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   73/1080: Solving 1 hour to 1 hour, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   74/1080: Solving 1 hour, 50 seconds to 1 hour, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   75/1080: Solving 1 hour, 1.667 minute to 1 hour, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   76/1080: Solving 1 hour, 2.5 minutes to 1 hour, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   77/1080: Solving 1 hour, 3.333 minutes to 1 hour, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   78/1080: Solving 1 hour, 4.167 minutes to 1 hour, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   79/1080: Solving 1 hour, 5 minutes to 1 hour, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   80/1080: Solving 1 hour, 5.833 minutes to 1 hour, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   81/1080: Solving 1 hour, 6.667 minutes to 1 hour, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   82/1080: Solving 1 hour, 7.5 minutes to 1 hour, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   83/1080: Solving 1 hour, 8.333 minutes to 1 hour, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   84/1080: Solving 1 hour, 9.167 minutes to 1 hour, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   85/1080: Solving 1 hour, 10 minutes to 1 hour, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   86/1080: Solving 1 hour, 10.83 minutes to 1 hour, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   87/1080: Solving 1 hour, 11.67 minutes to 1 hour, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   88/1080: Solving 1 hour, 12.5 minutes to 1 hour, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   89/1080: Solving 1 hour, 13.33 minutes to 1 hour, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   90/1080: Solving 1 hour, 14.17 minutes to 1 hour, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   91/1080: Solving 1 hour, 15 minutes to 1 hour, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   92/1080: Solving 1 hour, 15.83 minutes to 1 hour, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   93/1080: Solving 1 hour, 16.67 minutes to 1 hour, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   94/1080: Solving 1 hour, 17.5 minutes to 1 hour, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   95/1080: Solving 1 hour, 18.33 minutes to 1 hour, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   96/1080: Solving 1 hour, 19.17 minutes to 1 hour, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   97/1080: Solving 1 hour, 20 minutes to 1 hour, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   98/1080: Solving 1 hour, 20.83 minutes to 1 hour, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step   99/1080: Solving 1 hour, 21.67 minutes to 1 hour, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  100/1080: Solving 1 hour, 22.5 minutes to 1 hour, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  101/1080: Solving 1 hour, 23.33 minutes to 1 hour, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  102/1080: Solving 1 hour, 24.17 minutes to 1 hour, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  103/1080: Solving 1 hour, 25 minutes to 1 hour, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  104/1080: Solving 1 hour, 25.83 minutes to 1 hour, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  105/1080: Solving 1 hour, 26.67 minutes to 1 hour, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  106/1080: Solving 1 hour, 27.5 minutes to 1 hour, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  107/1080: Solving 1 hour, 28.33 minutes to 1 hour, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  108/1080: Solving 1 hour, 29.17 minutes to 1 hour, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  109/1080: Solving 1 hour, 30 minutes to 1 hour, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  110/1080: Solving 1 hour, 30.83 minutes to 1 hour, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  111/1080: Solving 1 hour, 31.67 minutes to 1 hour, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  112/1080: Solving 1 hour, 32.5 minutes to 1 hour, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  113/1080: Solving 1 hour, 33.33 minutes to 1 hour, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  114/1080: Solving 1 hour, 34.17 minutes to 1 hour, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  115/1080: Solving 1 hour, 35 minutes to 1 hour, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  116/1080: Solving 1 hour, 35.83 minutes to 1 hour, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  117/1080: Solving 1 hour, 36.67 minutes to 1 hour, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  118/1080: Solving 1 hour, 37.5 minutes to 1 hour, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  119/1080: Solving 1 hour, 38.33 minutes to 1 hour, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  120/1080: Solving 1 hour, 39.17 minutes to 1 hour, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  121/1080: Solving 1 hour, 40 minutes to 1 hour, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  122/1080: Solving 1 hour, 40.83 minutes to 1 hour, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  123/1080: Solving 1 hour, 41.67 minutes to 1 hour, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  124/1080: Solving 1 hour, 42.5 minutes to 1 hour, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  125/1080: Solving 1 hour, 43.33 minutes to 1 hour, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  126/1080: Solving 1 hour, 44.17 minutes to 1 hour, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  127/1080: Solving 1 hour, 45 minutes to 1 hour, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  128/1080: Solving 1 hour, 45.83 minutes to 1 hour, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  129/1080: Solving 1 hour, 46.67 minutes to 1 hour, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  130/1080: Solving 1 hour, 47.5 minutes to 1 hour, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  131/1080: Solving 1 hour, 48.33 minutes to 1 hour, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  132/1080: Solving 1 hour, 49.17 minutes to 1 hour, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  133/1080: Solving 1 hour, 50 minutes to 1 hour, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  134/1080: Solving 1 hour, 50.83 minutes to 1 hour, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  135/1080: Solving 1 hour, 51.67 minutes to 1 hour, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  136/1080: Solving 1 hour, 52.5 minutes to 1 hour, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  137/1080: Solving 1 hour, 53.33 minutes to 1 hour, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  138/1080: Solving 1 hour, 54.17 minutes to 1 hour, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  139/1080: Solving 1 hour, 55 minutes to 1 hour, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  140/1080: Solving 1 hour, 55.83 minutes to 1 hour, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  141/1080: Solving 1 hour, 56.67 minutes to 1 hour, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  142/1080: Solving 1 hour, 57.5 minutes to 1 hour, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  143/1080: Solving 1 hour, 58.33 minutes to 1 hour, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  144/1080: Solving 1 hour, 59.17 minutes to 2 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  145/1080: Solving 2 hours to 2 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  146/1080: Solving 2 hours, 50 seconds to 2 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  147/1080: Solving 2 hours, 1.667 minute to 2 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  148/1080: Solving 2 hours, 2.5 minutes to 2 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  149/1080: Solving 2 hours, 3.333 minutes to 2 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  150/1080: Solving 2 hours, 4.167 minutes to 2 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  151/1080: Solving 2 hours, 5 minutes to 2 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  152/1080: Solving 2 hours, 5.833 minutes to 2 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  153/1080: Solving 2 hours, 6.667 minutes to 2 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  154/1080: Solving 2 hours, 7.5 minutes to 2 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  155/1080: Solving 2 hours, 8.333 minutes to 2 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  156/1080: Solving 2 hours, 9.167 minutes to 2 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  157/1080: Solving 2 hours, 10 minutes to 2 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  158/1080: Solving 2 hours, 10.83 minutes to 2 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  159/1080: Solving 2 hours, 11.67 minutes to 2 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  160/1080: Solving 2 hours, 12.5 minutes to 2 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  161/1080: Solving 2 hours, 13.33 minutes to 2 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  162/1080: Solving 2 hours, 14.17 minutes to 2 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  163/1080: Solving 2 hours, 15 minutes to 2 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  164/1080: Solving 2 hours, 15.83 minutes to 2 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  165/1080: Solving 2 hours, 16.67 minutes to 2 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  166/1080: Solving 2 hours, 17.5 minutes to 2 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  167/1080: Solving 2 hours, 18.33 minutes to 2 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  168/1080: Solving 2 hours, 19.17 minutes to 2 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  169/1080: Solving 2 hours, 20 minutes to 2 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  170/1080: Solving 2 hours, 20.83 minutes to 2 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  171/1080: Solving 2 hours, 21.67 minutes to 2 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  172/1080: Solving 2 hours, 22.5 minutes to 2 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  173/1080: Solving 2 hours, 23.33 minutes to 2 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  174/1080: Solving 2 hours, 24.17 minutes to 2 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  175/1080: Solving 2 hours, 25 minutes to 2 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  176/1080: Solving 2 hours, 25.83 minutes to 2 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  177/1080: Solving 2 hours, 26.67 minutes to 2 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  178/1080: Solving 2 hours, 27.5 minutes to 2 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  179/1080: Solving 2 hours, 28.33 minutes to 2 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  180/1080: Solving 2 hours, 29.17 minutes to 2 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  181/1080: Solving 2 hours, 30 minutes to 2 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  182/1080: Solving 2 hours, 30.83 minutes to 2 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  183/1080: Solving 2 hours, 31.67 minutes to 2 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  184/1080: Solving 2 hours, 32.5 minutes to 2 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  185/1080: Solving 2 hours, 33.33 minutes to 2 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  186/1080: Solving 2 hours, 34.17 minutes to 2 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  187/1080: Solving 2 hours, 35 minutes to 2 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  188/1080: Solving 2 hours, 35.83 minutes to 2 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  189/1080: Solving 2 hours, 36.67 minutes to 2 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  190/1080: Solving 2 hours, 37.5 minutes to 2 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  191/1080: Solving 2 hours, 38.33 minutes to 2 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  192/1080: Solving 2 hours, 39.17 minutes to 2 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  193/1080: Solving 2 hours, 40 minutes to 2 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  194/1080: Solving 2 hours, 40.83 minutes to 2 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  195/1080: Solving 2 hours, 41.67 minutes to 2 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  196/1080: Solving 2 hours, 42.5 minutes to 2 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  197/1080: Solving 2 hours, 43.33 minutes to 2 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  198/1080: Solving 2 hours, 44.17 minutes to 2 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  199/1080: Solving 2 hours, 45 minutes to 2 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  200/1080: Solving 2 hours, 45.83 minutes to 2 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  201/1080: Solving 2 hours, 46.67 minutes to 2 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  202/1080: Solving 2 hours, 47.5 minutes to 2 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  203/1080: Solving 2 hours, 48.33 minutes to 2 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  204/1080: Solving 2 hours, 49.17 minutes to 2 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  205/1080: Solving 2 hours, 50 minutes to 2 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  206/1080: Solving 2 hours, 50.83 minutes to 2 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  207/1080: Solving 2 hours, 51.67 minutes to 2 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  208/1080: Solving 2 hours, 52.5 minutes to 2 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  209/1080: Solving 2 hours, 53.33 minutes to 2 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  210/1080: Solving 2 hours, 54.17 minutes to 2 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  211/1080: Solving 2 hours, 55 minutes to 2 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  212/1080: Solving 2 hours, 55.83 minutes to 2 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  213/1080: Solving 2 hours, 56.67 minutes to 2 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  214/1080: Solving 2 hours, 57.5 minutes to 2 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  215/1080: Solving 2 hours, 58.33 minutes to 2 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  216/1080: Solving 2 hours, 59.17 minutes to 3 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  217/1080: Solving 3 hours to 3 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  218/1080: Solving 3 hours, 50 seconds to 3 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  219/1080: Solving 3 hours, 1.667 minute to 3 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  220/1080: Solving 3 hours, 2.5 minutes to 3 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  221/1080: Solving 3 hours, 3.333 minutes to 3 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  222/1080: Solving 3 hours, 4.167 minutes to 3 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  223/1080: Solving 3 hours, 5 minutes to 3 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  224/1080: Solving 3 hours, 5.833 minutes to 3 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  225/1080: Solving 3 hours, 6.667 minutes to 3 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  226/1080: Solving 3 hours, 7.5 minutes to 3 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  227/1080: Solving 3 hours, 8.333 minutes to 3 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  228/1080: Solving 3 hours, 9.167 minutes to 3 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  229/1080: Solving 3 hours, 10 minutes to 3 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  230/1080: Solving 3 hours, 10.83 minutes to 3 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  231/1080: Solving 3 hours, 11.67 minutes to 3 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  232/1080: Solving 3 hours, 12.5 minutes to 3 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  233/1080: Solving 3 hours, 13.33 minutes to 3 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  234/1080: Solving 3 hours, 14.17 minutes to 3 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  235/1080: Solving 3 hours, 15 minutes to 3 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  236/1080: Solving 3 hours, 15.83 minutes to 3 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  237/1080: Solving 3 hours, 16.67 minutes to 3 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  238/1080: Solving 3 hours, 17.5 minutes to 3 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  239/1080: Solving 3 hours, 18.33 minutes to 3 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  240/1080: Solving 3 hours, 19.17 minutes to 3 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  241/1080: Solving 3 hours, 20 minutes to 3 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  242/1080: Solving 3 hours, 20.83 minutes to 3 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  243/1080: Solving 3 hours, 21.67 minutes to 3 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  244/1080: Solving 3 hours, 22.5 minutes to 3 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  245/1080: Solving 3 hours, 23.33 minutes to 3 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  246/1080: Solving 3 hours, 24.17 minutes to 3 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  247/1080: Solving 3 hours, 25 minutes to 3 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  248/1080: Solving 3 hours, 25.83 minutes to 3 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  249/1080: Solving 3 hours, 26.67 minutes to 3 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  250/1080: Solving 3 hours, 27.5 minutes to 3 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  251/1080: Solving 3 hours, 28.33 minutes to 3 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  252/1080: Solving 3 hours, 29.17 minutes to 3 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 252, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 252, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 252, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 252, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 252, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  253/1080: Solving 3 hours, 30 minutes to 3 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  254/1080: Solving 3 hours, 30.83 minutes to 3 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  255/1080: Solving 3 hours, 31.67 minutes to 3 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  256/1080: Solving 3 hours, 32.5 minutes to 3 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  257/1080: Solving 3 hours, 33.33 minutes to 3 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  258/1080: Solving 3 hours, 34.17 minutes to 3 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  259/1080: Solving 3 hours, 35 minutes to 3 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  260/1080: Solving 3 hours, 35.83 minutes to 3 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  261/1080: Solving 3 hours, 36.67 minutes to 3 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  262/1080: Solving 3 hours, 37.5 minutes to 3 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  263/1080: Solving 3 hours, 38.33 minutes to 3 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  264/1080: Solving 3 hours, 39.17 minutes to 3 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  265/1080: Solving 3 hours, 40 minutes to 3 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  266/1080: Solving 3 hours, 40.83 minutes to 3 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  267/1080: Solving 3 hours, 41.67 minutes to 3 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  268/1080: Solving 3 hours, 42.5 minutes to 3 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  269/1080: Solving 3 hours, 43.33 minutes to 3 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  270/1080: Solving 3 hours, 44.17 minutes to 3 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  271/1080: Solving 3 hours, 45 minutes to 3 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  272/1080: Solving 3 hours, 45.83 minutes to 3 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  273/1080: Solving 3 hours, 46.67 minutes to 3 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  274/1080: Solving 3 hours, 47.5 minutes to 3 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  275/1080: Solving 3 hours, 48.33 minutes to 3 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  276/1080: Solving 3 hours, 49.17 minutes to 3 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  277/1080: Solving 3 hours, 50 minutes to 3 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  278/1080: Solving 3 hours, 50.83 minutes to 3 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  279/1080: Solving 3 hours, 51.67 minutes to 3 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  280/1080: Solving 3 hours, 52.5 minutes to 3 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  281/1080: Solving 3 hours, 53.33 minutes to 3 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  282/1080: Solving 3 hours, 54.17 minutes to 3 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  283/1080: Solving 3 hours, 55 minutes to 3 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  284/1080: Solving 3 hours, 55.83 minutes to 3 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  285/1080: Solving 3 hours, 56.67 minutes to 3 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  286/1080: Solving 3 hours, 57.5 minutes to 3 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  287/1080: Solving 3 hours, 58.33 minutes to 3 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  288/1080: Solving 3 hours, 59.17 minutes to 4 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  289/1080: Solving 4 hours to 4 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  290/1080: Solving 4 hours, 50 seconds to 4 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  291/1080: Solving 4 hours, 1.667 minute to 4 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  292/1080: Solving 4 hours, 2.5 minutes to 4 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  293/1080: Solving 4 hours, 3.333 minutes to 4 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  294/1080: Solving 4 hours, 4.167 minutes to 4 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  295/1080: Solving 4 hours, 5 minutes to 4 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  296/1080: Solving 4 hours, 5.833 minutes to 4 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  297/1080: Solving 4 hours, 6.667 minutes to 4 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  298/1080: Solving 4 hours, 7.5 minutes to 4 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  299/1080: Solving 4 hours, 8.333 minutes to 4 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 299, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 299, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 299, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 299, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 299, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  300/1080: Solving 4 hours, 9.167 minutes to 4 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  301/1080: Solving 4 hours, 10 minutes to 4 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  302/1080: Solving 4 hours, 10.83 minutes to 4 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  303/1080: Solving 4 hours, 11.67 minutes to 4 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  304/1080: Solving 4 hours, 12.5 minutes to 4 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  305/1080: Solving 4 hours, 13.33 minutes to 4 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  306/1080: Solving 4 hours, 14.17 minutes to 4 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  307/1080: Solving 4 hours, 15 minutes to 4 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  308/1080: Solving 4 hours, 15.83 minutes to 4 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  309/1080: Solving 4 hours, 16.67 minutes to 4 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  310/1080: Solving 4 hours, 17.5 minutes to 4 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  311/1080: Solving 4 hours, 18.33 minutes to 4 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  312/1080: Solving 4 hours, 19.17 minutes to 4 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  313/1080: Solving 4 hours, 20 minutes to 4 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  314/1080: Solving 4 hours, 20.83 minutes to 4 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  315/1080: Solving 4 hours, 21.67 minutes to 4 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  316/1080: Solving 4 hours, 22.5 minutes to 4 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  317/1080: Solving 4 hours, 23.33 minutes to 4 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  318/1080: Solving 4 hours, 24.17 minutes to 4 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  319/1080: Solving 4 hours, 25 minutes to 4 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  320/1080: Solving 4 hours, 25.83 minutes to 4 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  321/1080: Solving 4 hours, 26.67 minutes to 4 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  322/1080: Solving 4 hours, 27.5 minutes to 4 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  323/1080: Solving 4 hours, 28.33 minutes to 4 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  324/1080: Solving 4 hours, 29.17 minutes to 4 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  325/1080: Solving 4 hours, 30 minutes to 4 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  326/1080: Solving 4 hours, 30.83 minutes to 4 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  327/1080: Solving 4 hours, 31.67 minutes to 4 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  328/1080: Solving 4 hours, 32.5 minutes to 4 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  329/1080: Solving 4 hours, 33.33 minutes to 4 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  330/1080: Solving 4 hours, 34.17 minutes to 4 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  331/1080: Solving 4 hours, 35 minutes to 4 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  332/1080: Solving 4 hours, 35.83 minutes to 4 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  333/1080: Solving 4 hours, 36.67 minutes to 4 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  334/1080: Solving 4 hours, 37.5 minutes to 4 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  335/1080: Solving 4 hours, 38.33 minutes to 4 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  336/1080: Solving 4 hours, 39.17 minutes to 4 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  337/1080: Solving 4 hours, 40 minutes to 4 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  338/1080: Solving 4 hours, 40.83 minutes to 4 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  339/1080: Solving 4 hours, 41.67 minutes to 4 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  340/1080: Solving 4 hours, 42.5 minutes to 4 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  341/1080: Solving 4 hours, 43.33 minutes to 4 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  342/1080: Solving 4 hours, 44.17 minutes to 4 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  343/1080: Solving 4 hours, 45 minutes to 4 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  344/1080: Solving 4 hours, 45.83 minutes to 4 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  345/1080: Solving 4 hours, 46.67 minutes to 4 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  346/1080: Solving 4 hours, 47.5 minutes to 4 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  347/1080: Solving 4 hours, 48.33 minutes to 4 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  348/1080: Solving 4 hours, 49.17 minutes to 4 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  349/1080: Solving 4 hours, 50 minutes to 4 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  350/1080: Solving 4 hours, 50.83 minutes to 4 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  351/1080: Solving 4 hours, 51.67 minutes to 4 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  352/1080: Solving 4 hours, 52.5 minutes to 4 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  353/1080: Solving 4 hours, 53.33 minutes to 4 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  354/1080: Solving 4 hours, 54.17 minutes to 4 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  355/1080: Solving 4 hours, 55 minutes to 4 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  356/1080: Solving 4 hours, 55.83 minutes to 4 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  357/1080: Solving 4 hours, 56.67 minutes to 4 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  358/1080: Solving 4 hours, 57.5 minutes to 4 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  359/1080: Solving 4 hours, 58.33 minutes to 4 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  360/1080: Solving 4 hours, 59.17 minutes to 5 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  361/1080: Solving 5 hours to 5 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  362/1080: Solving 5 hours, 50 seconds to 5 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  363/1080: Solving 5 hours, 1.667 minute to 5 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  364/1080: Solving 5 hours, 2.5 minutes to 5 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  365/1080: Solving 5 hours, 3.333 minutes to 5 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  366/1080: Solving 5 hours, 4.167 minutes to 5 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  367/1080: Solving 5 hours, 5 minutes to 5 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  368/1080: Solving 5 hours, 5.833 minutes to 5 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  369/1080: Solving 5 hours, 6.667 minutes to 5 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  370/1080: Solving 5 hours, 7.5 minutes to 5 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  371/1080: Solving 5 hours, 8.333 minutes to 5 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  372/1080: Solving 5 hours, 9.167 minutes to 5 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  373/1080: Solving 5 hours, 10 minutes to 5 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  374/1080: Solving 5 hours, 10.83 minutes to 5 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  375/1080: Solving 5 hours, 11.67 minutes to 5 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  376/1080: Solving 5 hours, 12.5 minutes to 5 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  377/1080: Solving 5 hours, 13.33 minutes to 5 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  378/1080: Solving 5 hours, 14.17 minutes to 5 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  379/1080: Solving 5 hours, 15 minutes to 5 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  380/1080: Solving 5 hours, 15.83 minutes to 5 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  381/1080: Solving 5 hours, 16.67 minutes to 5 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  382/1080: Solving 5 hours, 17.5 minutes to 5 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  383/1080: Solving 5 hours, 18.33 minutes to 5 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  384/1080: Solving 5 hours, 19.17 minutes to 5 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  385/1080: Solving 5 hours, 20 minutes to 5 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  386/1080: Solving 5 hours, 20.83 minutes to 5 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  387/1080: Solving 5 hours, 21.67 minutes to 5 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  388/1080: Solving 5 hours, 22.5 minutes to 5 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  389/1080: Solving 5 hours, 23.33 minutes to 5 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  390/1080: Solving 5 hours, 24.17 minutes to 5 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  391/1080: Solving 5 hours, 25 minutes to 5 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  392/1080: Solving 5 hours, 25.83 minutes to 5 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  393/1080: Solving 5 hours, 26.67 minutes to 5 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  394/1080: Solving 5 hours, 27.5 minutes to 5 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  395/1080: Solving 5 hours, 28.33 minutes to 5 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  396/1080: Solving 5 hours, 29.17 minutes to 5 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  397/1080: Solving 5 hours, 30 minutes to 5 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  398/1080: Solving 5 hours, 30.83 minutes to 5 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  399/1080: Solving 5 hours, 31.67 minutes to 5 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  400/1080: Solving 5 hours, 32.5 minutes to 5 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  401/1080: Solving 5 hours, 33.33 minutes to 5 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  402/1080: Solving 5 hours, 34.17 minutes to 5 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  403/1080: Solving 5 hours, 35 minutes to 5 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  404/1080: Solving 5 hours, 35.83 minutes to 5 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  405/1080: Solving 5 hours, 36.67 minutes to 5 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  406/1080: Solving 5 hours, 37.5 minutes to 5 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  407/1080: Solving 5 hours, 38.33 minutes to 5 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  408/1080: Solving 5 hours, 39.17 minutes to 5 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  409/1080: Solving 5 hours, 40 minutes to 5 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  410/1080: Solving 5 hours, 40.83 minutes to 5 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  411/1080: Solving 5 hours, 41.67 minutes to 5 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  412/1080: Solving 5 hours, 42.5 minutes to 5 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  413/1080: Solving 5 hours, 43.33 minutes to 5 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  414/1080: Solving 5 hours, 44.17 minutes to 5 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  415/1080: Solving 5 hours, 45 minutes to 5 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  416/1080: Solving 5 hours, 45.83 minutes to 5 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  417/1080: Solving 5 hours, 46.67 minutes to 5 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  418/1080: Solving 5 hours, 47.5 minutes to 5 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  419/1080: Solving 5 hours, 48.33 minutes to 5 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  420/1080: Solving 5 hours, 49.17 minutes to 5 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  421/1080: Solving 5 hours, 50 minutes to 5 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  422/1080: Solving 5 hours, 50.83 minutes to 5 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  423/1080: Solving 5 hours, 51.67 minutes to 5 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  424/1080: Solving 5 hours, 52.5 minutes to 5 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  425/1080: Solving 5 hours, 53.33 minutes to 5 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  426/1080: Solving 5 hours, 54.17 minutes to 5 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  427/1080: Solving 5 hours, 55 minutes to 5 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  428/1080: Solving 5 hours, 55.83 minutes to 5 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  429/1080: Solving 5 hours, 56.67 minutes to 5 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  430/1080: Solving 5 hours, 57.5 minutes to 5 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  431/1080: Solving 5 hours, 58.33 minutes to 5 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  432/1080: Solving 5 hours, 59.17 minutes to 6 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  433/1080: Solving 6 hours to 6 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  434/1080: Solving 6 hours, 50 seconds to 6 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  435/1080: Solving 6 hours, 1.667 minute to 6 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  436/1080: Solving 6 hours, 2.5 minutes to 6 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  437/1080: Solving 6 hours, 3.333 minutes to 6 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  438/1080: Solving 6 hours, 4.167 minutes to 6 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  439/1080: Solving 6 hours, 5 minutes to 6 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  440/1080: Solving 6 hours, 5.833 minutes to 6 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  441/1080: Solving 6 hours, 6.667 minutes to 6 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  442/1080: Solving 6 hours, 7.5 minutes to 6 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  443/1080: Solving 6 hours, 8.333 minutes to 6 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  444/1080: Solving 6 hours, 9.167 minutes to 6 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  445/1080: Solving 6 hours, 10 minutes to 6 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  446/1080: Solving 6 hours, 10.83 minutes to 6 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  447/1080: Solving 6 hours, 11.67 minutes to 6 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  448/1080: Solving 6 hours, 12.5 minutes to 6 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  449/1080: Solving 6 hours, 13.33 minutes to 6 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  450/1080: Solving 6 hours, 14.17 minutes to 6 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  451/1080: Solving 6 hours, 15 minutes to 6 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  452/1080: Solving 6 hours, 15.83 minutes to 6 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  453/1080: Solving 6 hours, 16.67 minutes to 6 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  454/1080: Solving 6 hours, 17.5 minutes to 6 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  455/1080: Solving 6 hours, 18.33 minutes to 6 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  456/1080: Solving 6 hours, 19.17 minutes to 6 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  457/1080: Solving 6 hours, 20 minutes to 6 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  458/1080: Solving 6 hours, 20.83 minutes to 6 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  459/1080: Solving 6 hours, 21.67 minutes to 6 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  460/1080: Solving 6 hours, 22.5 minutes to 6 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  461/1080: Solving 6 hours, 23.33 minutes to 6 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  462/1080: Solving 6 hours, 24.17 minutes to 6 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  463/1080: Solving 6 hours, 25 minutes to 6 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  464/1080: Solving 6 hours, 25.83 minutes to 6 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  465/1080: Solving 6 hours, 26.67 minutes to 6 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  466/1080: Solving 6 hours, 27.5 minutes to 6 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  467/1080: Solving 6 hours, 28.33 minutes to 6 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  468/1080: Solving 6 hours, 29.17 minutes to 6 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  469/1080: Solving 6 hours, 30 minutes to 6 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  470/1080: Solving 6 hours, 30.83 minutes to 6 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  471/1080: Solving 6 hours, 31.67 minutes to 6 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  472/1080: Solving 6 hours, 32.5 minutes to 6 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  473/1080: Solving 6 hours, 33.33 minutes to 6 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  474/1080: Solving 6 hours, 34.17 minutes to 6 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  475/1080: Solving 6 hours, 35 minutes to 6 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  476/1080: Solving 6 hours, 35.83 minutes to 6 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  477/1080: Solving 6 hours, 36.67 minutes to 6 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  478/1080: Solving 6 hours, 37.5 minutes to 6 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  479/1080: Solving 6 hours, 38.33 minutes to 6 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  480/1080: Solving 6 hours, 39.17 minutes to 6 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  481/1080: Solving 6 hours, 40 minutes to 6 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  482/1080: Solving 6 hours, 40.83 minutes to 6 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  483/1080: Solving 6 hours, 41.67 minutes to 6 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  484/1080: Solving 6 hours, 42.5 minutes to 6 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  485/1080: Solving 6 hours, 43.33 minutes to 6 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  486/1080: Solving 6 hours, 44.17 minutes to 6 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  487/1080: Solving 6 hours, 45 minutes to 6 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  488/1080: Solving 6 hours, 45.83 minutes to 6 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  489/1080: Solving 6 hours, 46.67 minutes to 6 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  490/1080: Solving 6 hours, 47.5 minutes to 6 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  491/1080: Solving 6 hours, 48.33 minutes to 6 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  492/1080: Solving 6 hours, 49.17 minutes to 6 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  493/1080: Solving 6 hours, 50 minutes to 6 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  494/1080: Solving 6 hours, 50.83 minutes to 6 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  495/1080: Solving 6 hours, 51.67 minutes to 6 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  496/1080: Solving 6 hours, 52.5 minutes to 6 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  497/1080: Solving 6 hours, 53.33 minutes to 6 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  498/1080: Solving 6 hours, 54.17 minutes to 6 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  499/1080: Solving 6 hours, 55 minutes to 6 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  500/1080: Solving 6 hours, 55.83 minutes to 6 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  501/1080: Solving 6 hours, 56.67 minutes to 6 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  502/1080: Solving 6 hours, 57.5 minutes to 6 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  503/1080: Solving 6 hours, 58.33 minutes to 6 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  504/1080: Solving 6 hours, 59.17 minutes to 7 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  505/1080: Solving 7 hours to 7 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  506/1080: Solving 7 hours, 50 seconds to 7 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  507/1080: Solving 7 hours, 1.667 minute to 7 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  508/1080: Solving 7 hours, 2.5 minutes to 7 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  509/1080: Solving 7 hours, 3.333 minutes to 7 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  510/1080: Solving 7 hours, 4.167 minutes to 7 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 510, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 510, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 510, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 510, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 510, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  511/1080: Solving 7 hours, 5 minutes to 7 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  512/1080: Solving 7 hours, 5.833 minutes to 7 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  513/1080: Solving 7 hours, 6.667 minutes to 7 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  514/1080: Solving 7 hours, 7.5 minutes to 7 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  515/1080: Solving 7 hours, 8.333 minutes to 7 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  516/1080: Solving 7 hours, 9.167 minutes to 7 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  517/1080: Solving 7 hours, 10 minutes to 7 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  518/1080: Solving 7 hours, 10.83 minutes to 7 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  519/1080: Solving 7 hours, 11.67 minutes to 7 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  520/1080: Solving 7 hours, 12.5 minutes to 7 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  521/1080: Solving 7 hours, 13.33 minutes to 7 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  522/1080: Solving 7 hours, 14.17 minutes to 7 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  523/1080: Solving 7 hours, 15 minutes to 7 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  524/1080: Solving 7 hours, 15.83 minutes to 7 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  525/1080: Solving 7 hours, 16.67 minutes to 7 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  526/1080: Solving 7 hours, 17.5 minutes to 7 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  527/1080: Solving 7 hours, 18.33 minutes to 7 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  528/1080: Solving 7 hours, 19.17 minutes to 7 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  529/1080: Solving 7 hours, 20 minutes to 7 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  530/1080: Solving 7 hours, 20.83 minutes to 7 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  531/1080: Solving 7 hours, 21.67 minutes to 7 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  532/1080: Solving 7 hours, 22.5 minutes to 7 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  533/1080: Solving 7 hours, 23.33 minutes to 7 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  534/1080: Solving 7 hours, 24.17 minutes to 7 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  535/1080: Solving 7 hours, 25 minutes to 7 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  536/1080: Solving 7 hours, 25.83 minutes to 7 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  537/1080: Solving 7 hours, 26.67 minutes to 7 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  538/1080: Solving 7 hours, 27.5 minutes to 7 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  539/1080: Solving 7 hours, 28.33 minutes to 7 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  540/1080: Solving 7 hours, 29.17 minutes to 7 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  541/1080: Solving 7 hours, 30 minutes to 7 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  542/1080: Solving 7 hours, 30.83 minutes to 7 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  543/1080: Solving 7 hours, 31.67 minutes to 7 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  544/1080: Solving 7 hours, 32.5 minutes to 7 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  545/1080: Solving 7 hours, 33.33 minutes to 7 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  546/1080: Solving 7 hours, 34.17 minutes to 7 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  547/1080: Solving 7 hours, 35 minutes to 7 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  548/1080: Solving 7 hours, 35.83 minutes to 7 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  549/1080: Solving 7 hours, 36.67 minutes to 7 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  550/1080: Solving 7 hours, 37.5 minutes to 7 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  551/1080: Solving 7 hours, 38.33 minutes to 7 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  552/1080: Solving 7 hours, 39.17 minutes to 7 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  553/1080: Solving 7 hours, 40 minutes to 7 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  554/1080: Solving 7 hours, 40.83 minutes to 7 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  555/1080: Solving 7 hours, 41.67 minutes to 7 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  556/1080: Solving 7 hours, 42.5 minutes to 7 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  557/1080: Solving 7 hours, 43.33 minutes to 7 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 557, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 557, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 557, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 557, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 557, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  558/1080: Solving 7 hours, 44.17 minutes to 7 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  559/1080: Solving 7 hours, 45 minutes to 7 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  560/1080: Solving 7 hours, 45.83 minutes to 7 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  561/1080: Solving 7 hours, 46.67 minutes to 7 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  562/1080: Solving 7 hours, 47.5 minutes to 7 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  563/1080: Solving 7 hours, 48.33 minutes to 7 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  564/1080: Solving 7 hours, 49.17 minutes to 7 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  565/1080: Solving 7 hours, 50 minutes to 7 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  566/1080: Solving 7 hours, 50.83 minutes to 7 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  567/1080: Solving 7 hours, 51.67 minutes to 7 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  568/1080: Solving 7 hours, 52.5 minutes to 7 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  569/1080: Solving 7 hours, 53.33 minutes to 7 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  570/1080: Solving 7 hours, 54.17 minutes to 7 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  571/1080: Solving 7 hours, 55 minutes to 7 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  572/1080: Solving 7 hours, 55.83 minutes to 7 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  573/1080: Solving 7 hours, 56.67 minutes to 7 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  574/1080: Solving 7 hours, 57.5 minutes to 7 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  575/1080: Solving 7 hours, 58.33 minutes to 7 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  576/1080: Solving 7 hours, 59.17 minutes to 8 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  577/1080: Solving 8 hours to 8 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  578/1080: Solving 8 hours, 50 seconds to 8 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  579/1080: Solving 8 hours, 1.667 minute to 8 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  580/1080: Solving 8 hours, 2.5 minutes to 8 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  581/1080: Solving 8 hours, 3.333 minutes to 8 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  582/1080: Solving 8 hours, 4.167 minutes to 8 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  583/1080: Solving 8 hours, 5 minutes to 8 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  584/1080: Solving 8 hours, 5.833 minutes to 8 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  585/1080: Solving 8 hours, 6.667 minutes to 8 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  586/1080: Solving 8 hours, 7.5 minutes to 8 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  587/1080: Solving 8 hours, 8.333 minutes to 8 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  588/1080: Solving 8 hours, 9.167 minutes to 8 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  589/1080: Solving 8 hours, 10 minutes to 8 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  590/1080: Solving 8 hours, 10.83 minutes to 8 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  591/1080: Solving 8 hours, 11.67 minutes to 8 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  592/1080: Solving 8 hours, 12.5 minutes to 8 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  593/1080: Solving 8 hours, 13.33 minutes to 8 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  594/1080: Solving 8 hours, 14.17 minutes to 8 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  595/1080: Solving 8 hours, 15 minutes to 8 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  596/1080: Solving 8 hours, 15.83 minutes to 8 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  597/1080: Solving 8 hours, 16.67 minutes to 8 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  598/1080: Solving 8 hours, 17.5 minutes to 8 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  599/1080: Solving 8 hours, 18.33 minutes to 8 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  600/1080: Solving 8 hours, 19.17 minutes to 8 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  601/1080: Solving 8 hours, 20 minutes to 8 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  602/1080: Solving 8 hours, 20.83 minutes to 8 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  603/1080: Solving 8 hours, 21.67 minutes to 8 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  604/1080: Solving 8 hours, 22.5 minutes to 8 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  605/1080: Solving 8 hours, 23.33 minutes to 8 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  606/1080: Solving 8 hours, 24.17 minutes to 8 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  607/1080: Solving 8 hours, 25 minutes to 8 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  608/1080: Solving 8 hours, 25.83 minutes to 8 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  609/1080: Solving 8 hours, 26.67 minutes to 8 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  610/1080: Solving 8 hours, 27.5 minutes to 8 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  611/1080: Solving 8 hours, 28.33 minutes to 8 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  612/1080: Solving 8 hours, 29.17 minutes to 8 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  613/1080: Solving 8 hours, 30 minutes to 8 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  614/1080: Solving 8 hours, 30.83 minutes to 8 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  615/1080: Solving 8 hours, 31.67 minutes to 8 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  616/1080: Solving 8 hours, 32.5 minutes to 8 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  617/1080: Solving 8 hours, 33.33 minutes to 8 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  618/1080: Solving 8 hours, 34.17 minutes to 8 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  619/1080: Solving 8 hours, 35 minutes to 8 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  620/1080: Solving 8 hours, 35.83 minutes to 8 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  621/1080: Solving 8 hours, 36.67 minutes to 8 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  622/1080: Solving 8 hours, 37.5 minutes to 8 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  623/1080: Solving 8 hours, 38.33 minutes to 8 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  624/1080: Solving 8 hours, 39.17 minutes to 8 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  625/1080: Solving 8 hours, 40 minutes to 8 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  626/1080: Solving 8 hours, 40.83 minutes to 8 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  627/1080: Solving 8 hours, 41.67 minutes to 8 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  628/1080: Solving 8 hours, 42.5 minutes to 8 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  629/1080: Solving 8 hours, 43.33 minutes to 8 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  630/1080: Solving 8 hours, 44.17 minutes to 8 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  631/1080: Solving 8 hours, 45 minutes to 8 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  632/1080: Solving 8 hours, 45.83 minutes to 8 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  633/1080: Solving 8 hours, 46.67 minutes to 8 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  634/1080: Solving 8 hours, 47.5 minutes to 8 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  635/1080: Solving 8 hours, 48.33 minutes to 8 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  636/1080: Solving 8 hours, 49.17 minutes to 8 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  637/1080: Solving 8 hours, 50 minutes to 8 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  638/1080: Solving 8 hours, 50.83 minutes to 8 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  639/1080: Solving 8 hours, 51.67 minutes to 8 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  640/1080: Solving 8 hours, 52.5 minutes to 8 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  641/1080: Solving 8 hours, 53.33 minutes to 8 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  642/1080: Solving 8 hours, 54.17 minutes to 8 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  643/1080: Solving 8 hours, 55 minutes to 8 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  644/1080: Solving 8 hours, 55.83 minutes to 8 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  645/1080: Solving 8 hours, 56.67 minutes to 8 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  646/1080: Solving 8 hours, 57.5 minutes to 8 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  647/1080: Solving 8 hours, 58.33 minutes to 8 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  648/1080: Solving 8 hours, 59.17 minutes to 9 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  649/1080: Solving 9 hours to 9 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  650/1080: Solving 9 hours, 50 seconds to 9 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  651/1080: Solving 9 hours, 1.667 minute to 9 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  652/1080: Solving 9 hours, 2.5 minutes to 9 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  653/1080: Solving 9 hours, 3.333 minutes to 9 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  654/1080: Solving 9 hours, 4.167 minutes to 9 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  655/1080: Solving 9 hours, 5 minutes to 9 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  656/1080: Solving 9 hours, 5.833 minutes to 9 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  657/1080: Solving 9 hours, 6.667 minutes to 9 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  658/1080: Solving 9 hours, 7.5 minutes to 9 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  659/1080: Solving 9 hours, 8.333 minutes to 9 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  660/1080: Solving 9 hours, 9.167 minutes to 9 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  661/1080: Solving 9 hours, 10 minutes to 9 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  662/1080: Solving 9 hours, 10.83 minutes to 9 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  663/1080: Solving 9 hours, 11.67 minutes to 9 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  664/1080: Solving 9 hours, 12.5 minutes to 9 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  665/1080: Solving 9 hours, 13.33 minutes to 9 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  666/1080: Solving 9 hours, 14.17 minutes to 9 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  667/1080: Solving 9 hours, 15 minutes to 9 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  668/1080: Solving 9 hours, 15.83 minutes to 9 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  669/1080: Solving 9 hours, 16.67 minutes to 9 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  670/1080: Solving 9 hours, 17.5 minutes to 9 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  671/1080: Solving 9 hours, 18.33 minutes to 9 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  672/1080: Solving 9 hours, 19.17 minutes to 9 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  673/1080: Solving 9 hours, 20 minutes to 9 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  674/1080: Solving 9 hours, 20.83 minutes to 9 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  675/1080: Solving 9 hours, 21.67 minutes to 9 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  676/1080: Solving 9 hours, 22.5 minutes to 9 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  677/1080: Solving 9 hours, 23.33 minutes to 9 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  678/1080: Solving 9 hours, 24.17 minutes to 9 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  679/1080: Solving 9 hours, 25 minutes to 9 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  680/1080: Solving 9 hours, 25.83 minutes to 9 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  681/1080: Solving 9 hours, 26.67 minutes to 9 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  682/1080: Solving 9 hours, 27.5 minutes to 9 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  683/1080: Solving 9 hours, 28.33 minutes to 9 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  684/1080: Solving 9 hours, 29.17 minutes to 9 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  685/1080: Solving 9 hours, 30 minutes to 9 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  686/1080: Solving 9 hours, 30.83 minutes to 9 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  687/1080: Solving 9 hours, 31.67 minutes to 9 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  688/1080: Solving 9 hours, 32.5 minutes to 9 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  689/1080: Solving 9 hours, 33.33 minutes to 9 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  690/1080: Solving 9 hours, 34.17 minutes to 9 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  691/1080: Solving 9 hours, 35 minutes to 9 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  692/1080: Solving 9 hours, 35.83 minutes to 9 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  693/1080: Solving 9 hours, 36.67 minutes to 9 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  694/1080: Solving 9 hours, 37.5 minutes to 9 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  695/1080: Solving 9 hours, 38.33 minutes to 9 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  696/1080: Solving 9 hours, 39.17 minutes to 9 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  697/1080: Solving 9 hours, 40 minutes to 9 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  698/1080: Solving 9 hours, 40.83 minutes to 9 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  699/1080: Solving 9 hours, 41.67 minutes to 9 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  700/1080: Solving 9 hours, 42.5 minutes to 9 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  701/1080: Solving 9 hours, 43.33 minutes to 9 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  702/1080: Solving 9 hours, 44.17 minutes to 9 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  703/1080: Solving 9 hours, 45 minutes to 9 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  704/1080: Solving 9 hours, 45.83 minutes to 9 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  705/1080: Solving 9 hours, 46.67 minutes to 9 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  706/1080: Solving 9 hours, 47.5 minutes to 9 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  707/1080: Solving 9 hours, 48.33 minutes to 9 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  708/1080: Solving 9 hours, 49.17 minutes to 9 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  709/1080: Solving 9 hours, 50 minutes to 9 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  710/1080: Solving 9 hours, 50.83 minutes to 9 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  711/1080: Solving 9 hours, 51.67 minutes to 9 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  712/1080: Solving 9 hours, 52.5 minutes to 9 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  713/1080: Solving 9 hours, 53.33 minutes to 9 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  714/1080: Solving 9 hours, 54.17 minutes to 9 hours, 55 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  715/1080: Solving 9 hours, 55 minutes to 9 hours, 55.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  716/1080: Solving 9 hours, 55.83 minutes to 9 hours, 56.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  717/1080: Solving 9 hours, 56.67 minutes to 9 hours, 57.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  718/1080: Solving 9 hours, 57.5 minutes to 9 hours, 58.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  719/1080: Solving 9 hours, 58.33 minutes to 9 hours, 59.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  720/1080: Solving 9 hours, 59.17 minutes to 10 hours, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  721/1080: Solving 10 hours to 10 hours, 50 seconds, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  722/1080: Solving 10 hours, 50 seconds to 10 hours, 1.667 minute, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  723/1080: Solving 10 hours, 1.667 minute to 10 hours, 2.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  724/1080: Solving 10 hours, 2.5 minutes to 10 hours, 3.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  725/1080: Solving 10 hours, 3.333 minutes to 10 hours, 4.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  726/1080: Solving 10 hours, 4.167 minutes to 10 hours, 5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  727/1080: Solving 10 hours, 5 minutes to 10 hours, 5.833 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  728/1080: Solving 10 hours, 5.833 minutes to 10 hours, 6.667 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  729/1080: Solving 10 hours, 6.667 minutes to 10 hours, 7.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  730/1080: Solving 10 hours, 7.5 minutes to 10 hours, 8.333 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  731/1080: Solving 10 hours, 8.333 minutes to 10 hours, 9.167 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  732/1080: Solving 10 hours, 9.167 minutes to 10 hours, 10 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  733/1080: Solving 10 hours, 10 minutes to 10 hours, 10.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  734/1080: Solving 10 hours, 10.83 minutes to 10 hours, 11.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  735/1080: Solving 10 hours, 11.67 minutes to 10 hours, 12.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  736/1080: Solving 10 hours, 12.5 minutes to 10 hours, 13.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  737/1080: Solving 10 hours, 13.33 minutes to 10 hours, 14.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  738/1080: Solving 10 hours, 14.17 minutes to 10 hours, 15 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  739/1080: Solving 10 hours, 15 minutes to 10 hours, 15.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  740/1080: Solving 10 hours, 15.83 minutes to 10 hours, 16.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  741/1080: Solving 10 hours, 16.67 minutes to 10 hours, 17.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  742/1080: Solving 10 hours, 17.5 minutes to 10 hours, 18.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  743/1080: Solving 10 hours, 18.33 minutes to 10 hours, 19.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  744/1080: Solving 10 hours, 19.17 minutes to 10 hours, 20 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  745/1080: Solving 10 hours, 20 minutes to 10 hours, 20.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  746/1080: Solving 10 hours, 20.83 minutes to 10 hours, 21.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  747/1080: Solving 10 hours, 21.67 minutes to 10 hours, 22.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  748/1080: Solving 10 hours, 22.5 minutes to 10 hours, 23.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  749/1080: Solving 10 hours, 23.33 minutes to 10 hours, 24.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  750/1080: Solving 10 hours, 24.17 minutes to 10 hours, 25 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  751/1080: Solving 10 hours, 25 minutes to 10 hours, 25.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  752/1080: Solving 10 hours, 25.83 minutes to 10 hours, 26.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  753/1080: Solving 10 hours, 26.67 minutes to 10 hours, 27.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  754/1080: Solving 10 hours, 27.5 minutes to 10 hours, 28.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  755/1080: Solving 10 hours, 28.33 minutes to 10 hours, 29.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  756/1080: Solving 10 hours, 29.17 minutes to 10 hours, 30 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  757/1080: Solving 10 hours, 30 minutes to 10 hours, 30.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  758/1080: Solving 10 hours, 30.83 minutes to 10 hours, 31.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  759/1080: Solving 10 hours, 31.67 minutes to 10 hours, 32.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  760/1080: Solving 10 hours, 32.5 minutes to 10 hours, 33.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  761/1080: Solving 10 hours, 33.33 minutes to 10 hours, 34.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  762/1080: Solving 10 hours, 34.17 minutes to 10 hours, 35 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  763/1080: Solving 10 hours, 35 minutes to 10 hours, 35.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  764/1080: Solving 10 hours, 35.83 minutes to 10 hours, 36.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  765/1080: Solving 10 hours, 36.67 minutes to 10 hours, 37.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  766/1080: Solving 10 hours, 37.5 minutes to 10 hours, 38.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  767/1080: Solving 10 hours, 38.33 minutes to 10 hours, 39.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  768/1080: Solving 10 hours, 39.17 minutes to 10 hours, 40 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 768, mini-step #1 (50 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 768, mini-step #2 (25 seconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 768, mini-step #4 (37 seconds, 500 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 768, mini-step #5 (18 seconds, 750 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Convergence: Report step 768, mini-step #6 (9 seconds, 375 milliseconds) failed to converge. Reducing mini-step.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  769/1080: Solving 10 hours, 40 minutes to 10 hours, 40.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  770/1080: Solving 10 hours, 40.83 minutes to 10 hours, 41.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  771/1080: Solving 10 hours, 41.67 minutes to 10 hours, 42.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  772/1080: Solving 10 hours, 42.5 minutes to 10 hours, 43.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  773/1080: Solving 10 hours, 43.33 minutes to 10 hours, 44.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  774/1080: Solving 10 hours, 44.17 minutes to 10 hours, 45 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  775/1080: Solving 10 hours, 45 minutes to 10 hours, 45.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  776/1080: Solving 10 hours, 45.83 minutes to 10 hours, 46.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  777/1080: Solving 10 hours, 46.67 minutes to 10 hours, 47.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  778/1080: Solving 10 hours, 47.5 minutes to 10 hours, 48.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  779/1080: Solving 10 hours, 48.33 minutes to 10 hours, 49.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  780/1080: Solving 10 hours, 49.17 minutes to 10 hours, 50 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  781/1080: Solving 10 hours, 50 minutes to 10 hours, 50.83 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  782/1080: Solving 10 hours, 50.83 minutes to 10 hours, 51.67 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  783/1080: Solving 10 hours, 51.67 minutes to 10 hours, 52.5 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  784/1080: Solving 10 hours, 52.5 minutes to 10 hours, 53.33 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Step  785/1080: Solving 10 hours, 53.33 minutes to 10 hours, 54.17 minutes, Δt = 50 seconds</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">Simulation complete: Completed 785 report steps in 12 seconds, 290 milliseconds, 231.4 microseconds and 2157 iterations.</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭────────────────┬───────────┬───────────────┬────────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Iteration type </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/step </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">  Avg/ministep </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">      Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">                │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 785 steps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> 829 ministeps </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">   (wasted) </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├────────────────┼───────────┼───────────────┼────────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Newton         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.74777 │       2.60193 │ 2157 (465) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linearization  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   3.80382 │       3.60193 │ 2986 (496) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solver  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│   2.74777 │       2.60193 │ 2157 (465) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│       0.0 │           0.0 │      0 (0) │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰────────────────┴───────────┴───────────────┴────────────╯</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╭───────────────┬────────┬────────────┬─────────╮</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Timing type   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Each </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Relative </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;">   Total </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">               │</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">     ms </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;"> Percentage </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#959da5;--shiki-dark:#959da5;">       s </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼─────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Properties    </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0488 │     0.86 % │  0.1052 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Equations     </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 1.6346 │    39.71 % │  4.8809 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Assembly      </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.3684 │     8.95 % │  1.1000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear solve  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.3225 │     5.66 % │  0.6955 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Linear setup  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Precond apply </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.0000 │     0.00 % │  0.0000 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Update        </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.2628 │     4.61 % │  0.5668 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Convergence   </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.5604 │    13.62 % │  1.6735 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Input/Output  </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 0.1053 │     0.71 % │  0.0873 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Other         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 1.4748 │    25.88 % │  3.1811 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">├───────────────┼────────┼────────────┼─────────┤</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│</span><span style="--shiki-light:#24292e;--shiki-light-font-weight:bold;--shiki-dark:#e1e4e8;--shiki-dark-font-weight:bold;"> Total         </span><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">│ 5.6978 │   100.00 % │ 12.2902 │</span></span>
<span class="line"><span style="--shiki-light:#24292e;--shiki-dark:#e1e4e8;">╰───────────────┴────────┴────────────┴─────────╯</span></span></code></pre></div><h2 id="Plot-the-results" tabindex="-1">Plot the results <a class="header-anchor" href="#Plot-the-results" aria-label="Permalink to &quot;Plot the results {#Plot-the-results}&quot;">​</a></h2><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Figure</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(size </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1000</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">400</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
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
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">f</span></span></code></pre></div><p><img src="`+a+'" alt=""></p><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_cycle.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_cycle.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>',12)]))}const c=e(l,[["render",p]]);export{g as __pageData,c as default};
