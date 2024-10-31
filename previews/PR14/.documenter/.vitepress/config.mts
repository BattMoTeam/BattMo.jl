import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/BattMo.jl/',// TODO: replace this in makedocs!
  title: 'BattMo.jl',
  description: 'Documentation for BattMo.jl',
  lastUpdated: true,
  cleanUrls: true,
  outDir: '../final_site', // This is required for MarkdownVitepress to work correctly...
  
  ignoreDeadLinks: true,

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
    nav: [
{ text: 'Introduction', collapsed: false, items: [
{ text: 'BattMo.jl', link: '/index' }]
 },
{ text: 'Examples: Introduction', collapsed: false, items: [
]
 },
{ text: 'Examples: Usage', collapsed: false, items: [
{ text: 'Cycling example', link: '/examples/example_cycle' },
{ text: 'Battery example', link: '/examples/example_battery' },
{ text: '3D demo example', link: '/examples/example_3d_demo' }]
 },
{ text: 'Examples: Validation', collapsed: false, items: [
]
 }
]
,
    sidebar: [
{ text: 'Introduction', collapsed: false, items: [
{ text: 'BattMo.jl', link: '/index' }]
 },
{ text: 'Examples: Introduction', collapsed: false, items: [
]
 },
{ text: 'Examples: Usage', collapsed: false, items: [
{ text: 'Cycling example', link: '/examples/example_cycle' },
{ text: 'Battery example', link: '/examples/example_battery' },
{ text: '3D demo example', link: '/examples/example_3d_demo' }]
 },
{ text: 'Examples: Validation', collapsed: false, items: [
]
 }
]
,
    editLink: { pattern: "https://https://github.com/sintefmath/BattMo.jl/edit/main/docs/src/:path" },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/sintefmath/BattMo.jl' }
    ],
    footer: {
      message: 'Made with <a href="https://luxdl.github.io/DocumenterVitepress.jl/dev/" target="_blank"><strong>DocumenterVitepress.jl</strong></a><br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})
