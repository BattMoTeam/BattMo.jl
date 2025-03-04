import{_ as n,c as a,o as p,aA as e}from"./chunks/framework.BIuidntl.js";const d=JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"examples/example_battery.md","filePath":"examples/example_battery.md","lastUpdated":null}'),l={name:"examples/example_battery.md"};function t(i,s,c,o,r,u){return p(),a("div",null,s[0]||(s[0]=[e(`<p>A basic example</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>using Jutul, BattMo, GLMakied</span></span>
<span class="line"><span></span></span>
<span class="line"><span>name = &quot;p2d_40&quot;</span></span></code></pre></div><p>name = &quot;p2d_40_jl_ud_func&quot; name = &quot;p2d_40_no_cc&quot; name = &quot;p2d_40_cccv&quot; name = &quot;p2d_40_jl_chen2020&quot; name = &quot;3d_demo_case&quot;</p><div class="language-@example vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">@example</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>do_json = false</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if do_json</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    fn = string(dirname(pathof(BattMo)), &quot;/../test/data/jsonfiles/&quot;, name, &quot;.json&quot;)</span></span>
<span class="line"><span>    inputparams = readBattMoJsonInputFile(fn)</span></span>
<span class="line"><span>    config_kwargs = (info_level = 0, )</span></span>
<span class="line"><span>    function hook(simulator,</span></span>
<span class="line"><span>                  model,</span></span>
<span class="line"><span>                  state0,</span></span>
<span class="line"><span>                  forces,</span></span>
<span class="line"><span>                  timesteps,</span></span>
<span class="line"><span>                  cfg)</span></span>
<span class="line"><span>    end</span></span>
<span class="line"><span>    output = run_battery(inputparams;</span></span>
<span class="line"><span>                         hook = hook,</span></span>
<span class="line"><span>                         config_kwargs = config_kwargs,</span></span>
<span class="line"><span>                         extra_timing = false);</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    states = output[:states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    t = [state[:Control][:ControllerCV].time for state in states]</span></span>
<span class="line"><span>    E = [state[:Control][:Phi][1] for state in states]</span></span>
<span class="line"><span>    I = [state[:Control][:Current][1] for state in states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>else</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    fn = string(dirname(pathof(BattMo)), &quot;/../test/data/matlab_files/&quot;, name, &quot;.mat&quot;)</span></span>
<span class="line"><span>    inputparams = readBattMoMatlabInputFile(fn)</span></span>
<span class="line"><span>    inputparams.dict[&quot;use_state_ref&quot;] = true</span></span>
<span class="line"><span>    config_kwargs = (info_level = 0,)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    function hook(simulator,</span></span>
<span class="line"><span>                  model,</span></span>
<span class="line"><span>                  state0,</span></span>
<span class="line"><span>                  forces,</span></span>
<span class="line"><span>                  timesteps,</span></span>
<span class="line"><span>                  cfg)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>        names = [:Elyte,</span></span>
<span class="line"><span>                 :NeAm,</span></span>
<span class="line"><span>                 :Control,</span></span>
<span class="line"><span>                 :PeAm]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>        if inputparams[&quot;model&quot;][&quot;include_current_collectors&quot;]</span></span>
<span class="line"><span>            names = append!(names, [:PeCc, :NeCc])</span></span>
<span class="line"><span>        end</span></span>
<span class="line"><span></span></span>
<span class="line"><span>        for name in names</span></span>
<span class="line"><span>            cfg[:tolerances][name][:default] = 1e-8</span></span>
<span class="line"><span>        end</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    end</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    output = run_battery(inputparams;</span></span>
<span class="line"><span>                         hook = hook,</span></span>
<span class="line"><span>                         config_kwargs = config_kwargs,</span></span>
<span class="line"><span>                         max_step = nothing);</span></span>
<span class="line"><span>    states = output[:states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    t = [state[:Control][:ControllerCV].time for state in states]</span></span>
<span class="line"><span>    E = [state[:Control][:Phi][1] for state in states]</span></span>
<span class="line"><span>    I = [state[:Control][:Current][1] for state in states]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    nsteps = size(states, 1)</span></span>
<span class="line"><span></span></span>
<span class="line"><span>    statesref = inputparams[&quot;states&quot;]</span></span>
<span class="line"><span>    timeref   = t</span></span>
<span class="line"><span>    Eref      = [state[&quot;Control&quot;][&quot;E&quot;] for state in statesref[1 : nsteps]]</span></span>
<span class="line"><span>    Iref      = [state[&quot;Control&quot;][&quot;I&quot;] for state in statesref[1 : nsteps]]</span></span>
<span class="line"><span></span></span>
<span class="line"><span>end</span></span>
<span class="line"><span></span></span>
<span class="line"><span>f = Figure(size = (1000, 400))</span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[1, 1],</span></span>
<span class="line"><span>          title     = &quot;Voltage&quot;,</span></span>
<span class="line"><span>          xlabel    = &quot;Time / s&quot;,</span></span>
<span class="line"><span>          ylabel    = &quot;Voltage / V&quot;,</span></span>
<span class="line"><span>          xlabelsize = 25,</span></span>
<span class="line"><span>          ylabelsize = 25,</span></span>
<span class="line"><span>          xticklabelsize = 25,</span></span>
<span class="line"><span>          yticklabelsize = 25</span></span>
<span class="line"><span>          )</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>              t,</span></span>
<span class="line"><span>              E;</span></span>
<span class="line"><span>              linewidth = 4,</span></span>
<span class="line"><span>              markersize = 10,</span></span>
<span class="line"><span>              marker = :cross,</span></span>
<span class="line"><span>              markercolor = :black,</span></span>
<span class="line"><span>              label = &quot;Julia&quot;</span></span>
<span class="line"><span>              )</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>if !do_json</span></span>
<span class="line"><span>    scatterlines!(ax,</span></span>
<span class="line"><span>                  t,</span></span>
<span class="line"><span>                  Eref;</span></span>
<span class="line"><span>                  linewidth = 2,</span></span>
<span class="line"><span>                  marker = :cross,</span></span>
<span class="line"><span>                  markercolor = :black,</span></span>
<span class="line"><span>                  markersize = 1,</span></span>
<span class="line"><span>                  label = &quot;Matlab&quot;)</span></span>
<span class="line"><span>    axislegend()</span></span>
<span class="line"><span>end</span></span>
<span class="line"><span></span></span>
<span class="line"><span></span></span>
<span class="line"><span>ax = Axis(f[1, 2],</span></span>
<span class="line"><span>          title     = &quot;Current&quot;,</span></span>
<span class="line"><span>          xlabel    = &quot;Time / s&quot;,</span></span>
<span class="line"><span>          ylabel    = &quot;Current / A&quot;,</span></span>
<span class="line"><span>          xlabelsize = 25,</span></span>
<span class="line"><span>          ylabelsize = 25,</span></span>
<span class="line"><span>          xticklabelsize = 25,</span></span>
<span class="line"><span>          yticklabelsize = 25</span></span>
<span class="line"><span>          )</span></span>
<span class="line"><span></span></span>
<span class="line"><span>scatterlines!(ax,</span></span>
<span class="line"><span>              t,</span></span>
<span class="line"><span>              I;</span></span>
<span class="line"><span>              linewidth = 4,</span></span>
<span class="line"><span>              markersize = 10,</span></span>
<span class="line"><span>              marker = :cross,</span></span>
<span class="line"><span>              markercolor = :black,</span></span>
<span class="line"><span>              label = &quot;Julia&quot;</span></span>
<span class="line"><span>              )</span></span>
<span class="line"><span></span></span>
<span class="line"><span>if !do_json</span></span>
<span class="line"><span>    scatterlines!(ax,</span></span>
<span class="line"><span>                  t,</span></span>
<span class="line"><span>                  Iref;</span></span>
<span class="line"><span>                  linewidth = 2,</span></span>
<span class="line"><span>                  marker = :cross,</span></span>
<span class="line"><span>                  markercolor = :black,</span></span>
<span class="line"><span>                  markersize = 1,</span></span>
<span class="line"><span>                  label = &quot;Matlab&quot;)</span></span>
<span class="line"><span>    axislegend()</span></span>
<span class="line"><span>end</span></span>
<span class="line"><span></span></span>
<span class="line"><span>f</span></span></code></pre></div><h2 id="Example-on-GitHub" tabindex="-1">Example on GitHub <a class="header-anchor" href="#Example-on-GitHub" aria-label="Permalink to &quot;Example on GitHub {#Example-on-GitHub}&quot;">​</a></h2><p>If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository <a href="https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/example_battery.jl" target="_blank" rel="noreferrer">as a script</a>, or as a <a href="https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/example_battery.ipynb" target="_blank" rel="noreferrer">Jupyter Notebook</a></p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>`,8)]))}const f=n(l,[["render",t]]);export{d as __pageData,f as default};
