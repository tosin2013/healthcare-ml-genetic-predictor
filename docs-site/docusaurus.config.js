module.exports = {
  title: 'Healthcare ML Genetic Predictor',
  tagline: 'A real-time genetic risk prediction system built with Quarkus WebSockets, deployed on Azure Red Hat OpenShift with event-driven architecture and scale-to-zero capabilities.',
  url: 'https://tosin2013.github.io',
  baseUrl: '/healthcare-ml-genetic-predictor/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'tosin2013',
  projectName: 'healthcare-ml-genetic-predictor',
  
  presets: [
    [
      'classic',
      {
        docs: {
          path: 'docs',
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/tosin2013/healthcare-ml-genetic-predictor/tree/main/docs-site/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'Healthcare ML Genetic Predictor',
      items: [
        {
          type: 'doc',
          docId: 'intro',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'https://github.com/tosin2013/healthcare-ml-genetic-predictor',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
  },
};