import React from 'react';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';

function Homepage() {
  return (
    <Layout
      title="Healthcare ML Genetic Predictor"
      description="A real-time genetic risk prediction system built with Quarkus WebSockets, deployed on Azure Red Hat OpenShift with event-driven architecture and scale-to-zero capabilities.">
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '2rem',
        minHeight: '50vh',
        textAlign: 'center'
      }}>
        <h1>Healthcare ML Genetic Predictor</h1>
        <p style={{ fontSize: '1.2rem', maxWidth: '600px', marginBottom: '2rem' }}>
          A real-time genetic risk prediction system built with Quarkus WebSockets, 
          deployed on Azure Red Hat OpenShift with event-driven architecture and 
          scale-to-zero capabilities.
        </p>
        <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', justifyContent: 'center' }}>
          <Link
            className="button button--primary button--lg"
            to="/docs/">
            View Documentation
          </Link>
          <Link
            className="button button--secondary button--lg"
            href="https://github.com/tosin2013/healthcare-ml-genetic-predictor">
            GitHub Repository
          </Link>
        </div>
      </div>
    </Layout>
  );
}

export default Homepage;