# Healthcare ML CI/CD Pipeline - Configuration Files

This directory contains configuration files for the GitHub Actions CI/CD pipeline.

## Required Secrets

Add these secrets to your GitHub repository settings:

### Container Registry
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions
- `GHCR_TOKEN` - Alternative token for GitHub Container Registry (if needed)

### OpenShift Deployment (Optional - for actual deployment)
- `OPENSHIFT_SERVER` - OpenShift cluster API server URL
- `OPENSHIFT_TOKEN` - Service account token for deployments
- `OPENSHIFT_CA_CERT` - Cluster CA certificate (if using self-signed certs)

### Notifications (Optional)
- `SLACK_WEBHOOK_URL` - For Slack notifications
- `TEAMS_WEBHOOK_URL` - For Microsoft Teams notifications

## Environment Configuration

### Development Environment
- **Namespace**: `healthcare-ml-demo-dev`
- **URL**: `https://dev-healthcare-ml-demo.example.com`
- **Auto-deploy**: On push to `develop` branch

### Staging Environment
- **Namespace**: `healthcare-ml-demo-staging`
- **URL**: `https://staging-healthcare-ml-demo.example.com`
- **Auto-deploy**: On push to `main` branch
- **Requires**: Manual approval (configured in GitHub environments)

### Production Environment
- **Namespace**: `healthcare-ml-demo`
- **URL**: `https://healthcare-ml-demo.example.com`
- **Auto-deploy**: On tag push (`v*` pattern)
- **Requires**: Manual approval + additional security checks

## Branch Protection Rules

Configure these branch protection rules in your repository:

### Main Branch (`main`)
- Require pull request reviews (2 reviewers)
- Require status checks to pass:
  - `code-quality`
  - `threading-validation`
  - `test-services`
  - `healthcare-compliance`
- Require branches to be up to date
- Restrict pushes to administrators
- Allow force pushes: **No**

### Develop Branch (`develop`)
- Require pull request reviews (1 reviewer)
- Require status checks to pass:
  - `code-quality`
  - `threading-validation`
  - `test-services`
- Require branches to be up to date

## Workflow Features

### 🚀 **Multi-Service Architecture Support**
- Separate build and test jobs for WebSocket and VEP services
- Path-based change detection to skip unnecessary builds
- Matrix builds for efficient parallel processing

### 🧵 **Healthcare-Specific Threading Validation**
- Validates Quarkus reactive threading patterns
- Ensures no event loop blocking
- Verifies CloudEvent processing compliance

### 🔒 **Security & Compliance**
- OWASP dependency vulnerability scanning
- Container image security scanning with Trivy
- CodeQL static analysis for security vulnerabilities
- HIPAA compliance validation
- Cost optimization checks

### 📊 **Quality Assurance**
- Comprehensive test coverage reporting
- Maven integration with proper caching
- Artifact retention for debugging
- Performance and integration testing

### 🏥 **Healthcare ML Specific Features**
- Cost attribution validation (genomics-research billing)
- OpenShift-native deployment patterns
- KEDA autoscaling validation
- Kafka message streaming verification

### 🐳 **Container & Kubernetes**
- Multi-architecture container builds (amd64/arm64)
- Kustomize manifest validation
- Security context verification
- Resource limit enforcement

## Customization Guide

### Adding New Services
1. Add service to matrix builds in `build-applications` and `build-images` jobs
2. Update path filters in `code-quality` job
3. Add service-specific tests to `test-services` job
4. Update Kubernetes validation if needed

### Modifying Deployment Environments
1. Update environment configurations in deployment jobs
2. Modify branch/tag conditions for auto-deployment
3. Update environment URLs and namespaces
4. Configure GitHub environment protection rules

### Integration with External Services
1. Add necessary secrets to repository settings
2. Update notification job for external integrations
3. Add service-specific validation steps
4. Configure webhook URLs for monitoring

## Troubleshooting

### Common Issues

**Build Failures**
- Check Java version compatibility (requires Java 17)
- Verify Maven wrapper permissions
- Check Quarkus version compatibility

**Threading Validation Failures**
- Review `@Blocking` annotations on REST endpoints
- Check for event loop blocking patterns
- Verify CloudEvent processing implementation

**Security Scan Failures**
- Update vulnerable dependencies
- Review container base image versions
- Check for exposed secrets in code

**Deployment Failures**
- Verify OpenShift cluster connectivity
- Check namespace permissions
- Validate Kubernetes manifest syntax

### Getting Help
- Review GitHub Actions logs for detailed error messages
- Check artifact uploads for test reports and build outputs
- Use workflow dispatch for manual testing
- Review threading validation artifacts for detailed analysis
