import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Dependy',
  description: 'A Simple Dependency Injection Library for Dart',
  base: '/dependy/',

  head: [
    ['link', { rel: 'icon', href: '/dependy/img/favicon.ico' }],
  ],

  themeConfig: {
    logo: '/img/logo.png',

    nav: [
      { text: 'Docs', link: '/introduction/getting-started' },
      { text: 'pub.dev', link: 'https://pub.dev/packages/dependy' },
      { text: 'GitHub', link: 'https://github.com/xeinebiu/dependy' },
    ],

    sidebar: [
      {
        text: 'Introduction',
        items: [
          { text: 'Getting Started', link: '/introduction/getting-started' },
          { text: 'Installation', link: '/introduction/installation' },
          { text: 'Core Concepts', link: '/introduction/core-concepts' },
          { text: 'Exceptions', link: '/introduction/exceptions' },
        ],
      },
      {
        text: 'Guides',
        items: [
          { text: 'Transient Providers', link: '/guides/transient-providers' },
          { text: 'Tagged Instances', link: '/guides/tagged-instances' },
          { text: 'Testing & Overrides', link: '/guides/testing-overrides' },
          { text: 'Debug Graph', link: '/guides/debug-graph' },
          { text: 'Provider Decorators', link: '/guides/provider-decorators' },
          { text: 'Provider Reset', link: '/guides/provider-reset' },
        ],
      },
      {
        text: 'Examples',
        items: [
          { text: 'Counter Service', link: '/examples/counter-service' },
          { text: 'Multiple Services', link: '/examples/multiple-services' },
          { text: 'Depends On', link: '/examples/depends-on' },
          { text: 'Combine Modules', link: '/examples/combine-modules' },
          { text: 'Scopes', link: '/examples/scopes' },
          { text: 'Eager', link: '/examples/eager' },
          { text: 'Transient', link: '/examples/transient' },
          { text: 'Tagged', link: '/examples/tagged' },
          { text: 'Overrides', link: '/examples/overrides' },
          { text: 'Debug Graph', link: '/examples/debug-graph' },
          { text: 'Decorators', link: '/examples/decorators' },
          { text: 'Reset', link: '/examples/reset' },
        ],
      },
      {
        text: 'Flutter',
        items: [
          { text: 'Getting Started', link: '/flutter/getting-started' },
          { text: 'Installation', link: '/flutter/installation' },
          { text: 'Scoping', link: '/flutter/scoping' },
          { text: 'API', link: '/flutter/api' },
          {
            text: 'Examples',
            collapsed: false,
            items: [
              { text: 'ScopedDependyMixin', link: '/flutter/examples/scoped-dependy-mixin' },
              { text: 'ScopedDependyProvider', link: '/flutter/examples/scoped-dependy-provider' },
              { text: 'Shared Scope (Provider)', link: '/flutter/examples/share-scope-dependy-provider' },
              { text: 'Shared Scope (Mixin)', link: '/flutter/examples/share-scope-dependy-mixin' },
              { text: 'Nested Scope (Mixin)', link: '/flutter/examples/nested-scope-dependy-mixin' },
              { text: 'Nested Scope (Provider)', link: '/flutter/examples/nested-scope-dependy-provider' },
              { text: 'Eager', link: '/flutter/examples/eager' },
              { text: 'Widgets', link: '/flutter/examples/widgets' },
              { text: 'Async Builder', link: '/flutter/examples/async-builder' },
            ],
          },
        ],
      },
    ],

    editLink: {
      pattern: 'https://github.com/xeinebiu/dependy/edit/main/docs/:path',
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024-present Dependy',
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/xeinebiu/dependy' },
    ],

    search: {
      provider: 'local',
    },
  },
})
