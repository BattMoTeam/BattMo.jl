import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";
import path from 'path'

function getBaseRepository(base: string): string {
  if (!base || base === '/') return '/';
  const parts = base.split('/').filter(Boolean);
  return parts.length > 0 ? `/${parts[0]}/` : '/';
}

const baseTemp = {
  base: '/BattMo.jl/previews/PR56/',// TODO: replace this in makedocs!
}

const navTemp = {
  nav: [
{ text: 'User Guide', collapsed: false, items: [
{ text: 'Getting started', collapsed: false, items: [
{ text: 'Installation', link: '/manuals/user_guide/installation' },
{ text: 'Getting started', link: '/manuals/user_guide/getting_started' }]
 },
{ text: 'Models and architecture', collapsed: false, items: [
{ text: 'PXD model', link: '/manuals/user_guide/pxd_model' },
{ text: 'Ramp up model', link: '/manuals/user_guide/ramp_up' },
{ text: 'SEI model', link: '/manuals/user_guide/sei_model' }]
 },
{ text: 'Public API', collapsed: false, items: [
{ text: 'Input terminology', link: '/manuals/user_guide/terminology' },
{ text: 'Simulation dependent input parameters', link: '/manuals/user_guide/simulation_dependent_input' },
{ text: 'Functions and types', link: '/manuals/user_guide/public_api' }]
 },
{ text: 'Tutorials', collapsed: false, items: [
{ text: 'Tutorial 1 - Useful tools', link: '/tutorials/1_useful_tools' },
{ text: 'Tutorial 2 - Run a simulation', link: '/tutorials/2_run_a_simulation' },
{ text: 'Tutorial 3 - Handle outputs', link: '/tutorials/3_handle_outputs' },
{ text: 'Tutorial 4 - Select a model', link: '/tutorials/4_select_a_model' },
{ text: 'Tutorial 5 - Create parameter sets', link: '/tutorials/5_create_parameter_sets' },
{ text: 'Tutorial 6 - Handle cell parameters', link: '/tutorials/6_handle_cell_parameters' },
{ text: 'Tutorial 7 - Handle cycling protocol', link: '/tutorials/7_handle_cycling_protocols' },
{ text: 'Tutorial 8 - Compute cell KPIs', link: '/tutorials/8_compute_cell_kpis' },
{ text: 'Tutorial 9 - Run a parameter sweep', link: '/tutorials/9_run_parameter_sweep' }]
 }]
 },
{ text: 'Examples', collapsed: false, items: [
{ text: 'Advanced examples', collapsed: false, items: [
{ text: 'Cycle example', link: '/examples/example_cycle' },
{ text: '1D plotting', link: '/examples/example_1d_plotting' },
{ text: 'Drive cycle example', link: '/examples/example_run_current_function' },
{ text: '3D Pouch example', link: '/examples/example_3D_pouch' },
{ text: 'Calibration example', link: '/examples/example_calibration' },
{ text: 'SEI layer growth', link: '/examples/example_sei' },
{ text: 'Matlab example', link: '/examples/example_battery' }]
 }]
 },
{ text: 'API Documentation', collapsed: false, items: [
{ text: 'High level API', link: '/manuals/api_documentation/highlevel' }]
 },
{ text: 'Contribution guide', collapsed: false, items: [
{ text: 'Contribute to BattMo.jl', link: '/manuals/contribution/contribution' },
{ text: 'Jutul', link: '/manuals/contribution/jutul_integration' }]
 },
{ text: 'References', collapsed: false, items: [
{ text: 'Bibliography', link: '/extras/refs' }]
 }
]
,
}

const nav = [
  ...navTemp.nav,
  {
    component: 'VersionPicker'
  }
]

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/BattMo.jl/previews/PR56/',// TODO: replace this in makedocs!
  title: 'BattMo.jl',
  description: 'Documentation for BattMo.jl',
  lastUpdated: true,
  cleanUrls: true,
  outDir: '../1', // This is required for MarkdownVitepress to work correctly...
  head: [
    
    ['script', {src: `${getBaseRepository(baseTemp.base)}versions.js`}],
    // ['script', {src: '/versions.js'], for custom domains, I guess if deploy_url is available.
    ['script', {src: `${baseTemp.base}siteinfo.js`}]
  ],
  
  vite: {
    define: {
      __DEPLOY_ABSPATH__: JSON.stringify('/BattMo.jl'),
    },
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '../components')
      }
    },
    optimizeDeps: {
      exclude: [ 
        '@nolebase/vitepress-plugin-enhanced-readabilities/client',
        'vitepress',
        '@nolebase/ui',
      ], 
    }, 
    ssr: { 
      noExternal: [ 
        // If there are other packages that need to be processed by Vite, you can add them here.
        '@nolebase/vitepress-plugin-enhanced-readabilities',
        '@nolebase/ui',
      ], 
    },
  },
  markdown: {
    math: true,
    config(md) {
      md.use(tabsMarkdownPlugin),
      md.use(mathjax3),
      md.use(footnote)
    },
    theme: {
      light: "github-light",
      dark: "github-dark"}
  },
  themeConfig: {
    outline: 'deep',
    
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav,
    sidebar: [
{ text: 'User Guide', collapsed: false, items: [
{ text: 'Getting started', collapsed: false, items: [
{ text: 'Installation', link: '/manuals/user_guide/installation' },
{ text: 'Getting started', link: '/manuals/user_guide/getting_started' }]
 },
{ text: 'Models and architecture', collapsed: false, items: [
{ text: 'PXD model', link: '/manuals/user_guide/pxd_model' },
{ text: 'Ramp up model', link: '/manuals/user_guide/ramp_up' },
{ text: 'SEI model', link: '/manuals/user_guide/sei_model' }]
 },
{ text: 'Public API', collapsed: false, items: [
{ text: 'Input terminology', link: '/manuals/user_guide/terminology' },
{ text: 'Simulation dependent input parameters', link: '/manuals/user_guide/simulation_dependent_input' },
{ text: 'Functions and types', link: '/manuals/user_guide/public_api' }]
 },
{ text: 'Tutorials', collapsed: false, items: [
{ text: 'Tutorial 1 - Useful tools', link: '/tutorials/1_useful_tools' },
{ text: 'Tutorial 2 - Run a simulation', link: '/tutorials/2_run_a_simulation' },
{ text: 'Tutorial 3 - Handle outputs', link: '/tutorials/3_handle_outputs' },
{ text: 'Tutorial 4 - Select a model', link: '/tutorials/4_select_a_model' },
{ text: 'Tutorial 5 - Create parameter sets', link: '/tutorials/5_create_parameter_sets' },
{ text: 'Tutorial 6 - Handle cell parameters', link: '/tutorials/6_handle_cell_parameters' },
{ text: 'Tutorial 7 - Handle cycling protocol', link: '/tutorials/7_handle_cycling_protocols' },
{ text: 'Tutorial 8 - Compute cell KPIs', link: '/tutorials/8_compute_cell_kpis' },
{ text: 'Tutorial 9 - Run a parameter sweep', link: '/tutorials/9_run_parameter_sweep' }]
 }]
 },
{ text: 'Examples', collapsed: false, items: [
{ text: 'Advanced examples', collapsed: false, items: [
{ text: 'Cycle example', link: '/examples/example_cycle' },
{ text: '1D plotting', link: '/examples/example_1d_plotting' },
{ text: 'Drive cycle example', link: '/examples/example_run_current_function' },
{ text: '3D Pouch example', link: '/examples/example_3D_pouch' },
{ text: 'Calibration example', link: '/examples/example_calibration' },
{ text: 'SEI layer growth', link: '/examples/example_sei' },
{ text: 'Matlab example', link: '/examples/example_battery' }]
 }]
 },
{ text: 'API Documentation', collapsed: false, items: [
{ text: 'High level API', link: '/manuals/api_documentation/highlevel' }]
 },
{ text: 'Contribution guide', collapsed: false, items: [
{ text: 'Contribute to BattMo.jl', link: '/manuals/contribution/contribution' },
{ text: 'Jutul', link: '/manuals/contribution/jutul_integration' }]
 },
{ text: 'References', collapsed: false, items: [
{ text: 'Bibliography', link: '/extras/refs' }]
 }
]
,
    editLink: { pattern: "https://github.com/BattMoTeam/BattMo.jl/edit/main/docs/src/:path" },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/BattMoTeam/BattMo.jl' }
    ],
    footer: {
      message: 'Made with <a href="https://luxdl.github.io/DocumenterVitepress.jl/dev/" target="_blank"><strong>DocumenterVitepress.jl</strong></a><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})
