# Healthcare ML CI/CD Pipeline - Complete Setup Guide

## 🎯 Overview

This document provides complete setup instructions for the Healthcare ML Genetic Predictor CI/CD pipeline, designed specifically for:
- **quarkus-websocket-service**: Real-time WebSocket communication service
- **vep-service**: VEP annotation service for genetic data processing

## 📋 Prerequisites

### Required Tools
- **GitHub repository** with admin access
- **OpenShift cluster** (Azure Red Hat OpenShift recommended)
- **GitHub Container Registry (GHCR)** access
- **Maven 3.8+** and **Java 17** for local development

### Required Operators (OpenShift)
- **Strimzi Kafka Operator**
- **KEDA Operator** 
- **Red Hat Cost Management Metrics Operator**

## 🔧 Step 1: Repository Configuration

### 1.1 Branch Protection Rules

Configure branch protection in GitHub Settings > Branches:

#### Main Branch (`main`)
```yaml
Protection Rules:
  - Require pull request reviews: 2 reviewers
  - Dismiss stale reviews: true
  - Require review from code owners: true
  - Restrict reviews to specific teams: platform-team, security-team
  - Required status checks:
    - code-quality
    - threading-validation / Threading Validation Tests
    - test-services (websocket) / Test Services (websocket)
    - test-services (vep) / Test Services (vep)
    - healthcare-compliance / Healthcare Compliance Check
  - Require branches to be up to date: true
  - Restrict pushes: administrators only
  - Allow force pushes: false
  - Allow deletions: false
```

#### Develop Branch (`develop`)
```yaml
Protection Rules:
  - Require pull request reviews: 1 reviewer
  - Required status checks:
    - code-quality
    - threading-validation
    - test-services (websocket)
    - test-services (vep)
  - Require branches to be up to date: true
  - Allow force pushes: false
```

### 1.2 Repository Secrets

Add these secrets in GitHub Settings > Secrets and variables > Actions:

#### Required Secrets
```bash
# GitHub Container Registry (automatically provided)
GITHUB_TOKEN                    # Auto-provided by GitHub Actions

# OpenShift Deployment (optional for actual deployment)
OPENSHIFT_SERVER               # https://api.your-cluster.example.com:6443
OPENSHIFT_TOKEN                # Service account token
OPENSHIFT_CA_CERT             # Base64 encoded CA certificate

# Notifications (optional)
SLACK_WEBHOOK_URL             # Slack webhook for notifications
TEAMS_WEBHOOK_URL             # Teams webhook for notifications

# Security Scanning (optional)
SNYK_TOKEN                    # Snyk security scanning token
SONAR_TOKEN                   # SonarQube token
```

#### Service Account Setup (OpenShift)
```bash
# Create service account for CI/CD
oc create serviceaccount github-actions -n healthcare-ml-demo

# Grant necessary permissions
oc adm policy add-role-to-user admin system:serviceaccount:healthcare-ml-demo:github-actions -n healthcare-ml-demo

# Get token for GitHub secrets
oc create token github-actions -n healthcare-ml-demo --duration=8760h
```

## 🌐 Step 2: Environment Configuration

### 2.1 GitHub Environments

Create environments in GitHub Settings > Environments:

#### Development Environment
```yaml
Environment: development
Protection Rules:
  - No protection rules (auto-deploy)
Environment Variables:
  - NAMESPACE: healthcare-ml-demo-dev
  - CLUSTER_URL: https://dev-cluster.example.com
  - APP_URL: https://dev-healthcare-ml-demo.example.com
```

#### Staging Environment
```yaml
Environment: staging
Protection Rules:
  - Required reviewers: platform-team (1 reviewer)
  - Wait timer: 5 minutes
Environment Variables:
  - NAMESPACE: healthcare-ml-demo-staging
  - CLUSTER_URL: https://staging-cluster.example.com
  - APP_URL: https://staging-healthcare-ml-demo.example.com
```

#### Production Environment
```yaml
Environment: production
Protection Rules:
  - Required reviewers: platform-team, security-team (2 reviewers)
  - Wait timer: 30 minutes
  - Environment secrets required
Environment Variables:
  - NAMESPACE: healthcare-ml-demo
  - CLUSTER_URL: https://prod-cluster.example.com
  - APP_URL: https://healthcare-ml-demo.example.com
```

### 2.2 OpenShift Namespace Preparation

```bash
# Create development namespace
oc new-project healthcare-ml-demo-dev
oc label namespace healthcare-ml-demo-dev \
  cost-center=genomics-research \
  project=risk-predictor-v1 \
  environment=development

# Create staging namespace
oc new-project healthcare-ml-demo-staging
oc label namespace healthcare-ml-demo-staging \
  cost-center=genomics-research \
  project=risk-predictor-v1 \
  environment=staging

# Production namespace (should already exist)
oc label namespace healthcare-ml-demo \
  cost-center=genomics-research \
  project=risk-predictor-v1 \
  environment=production
```

## 🔒 Step 3: Security Configuration

### 3.1 Container Registry Access

```bash
# Create registry secret for OpenShift
oc create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_ACTOR \
  --docker-password=$GITHUB_TOKEN \
  --docker-email=$GITHUB_EMAIL \
  -n healthcare-ml-demo

# Link secret to default service account
oc secrets link default ghcr-secret --for=pull -n healthcare-ml-demo
```

### 3.2 Security Scanning Setup

#### Enable CodeQL Analysis
1. Go to repository Settings > Security > Code scanning
2. Enable CodeQL analysis
3. Configure scheduled scans (weekly recommended)

#### Container Security Scanning
The pipeline automatically scans containers with Trivy. Results appear in:
- GitHub Security > Code scanning alerts
- Pull request security checks

### 3.3 HIPAA Compliance Validation

The pipeline includes automated HIPAA compliance checks:
- Audit logging configuration validation
- Data encryption verification
- Access control (RBAC) validation
- Security context enforcement

## 🧪 Step 4: Testing Configuration

### 4.1 Maven Configuration

Ensure both services have proper test configuration:

#### quarkus-websocket-service/pom.xml
```xml
<properties>
    <maven.compiler.release>17</maven.compiler.release>
    <quarkus.platform.version>3.8.6</quarkus.platform.version>
    <surefire-plugin.version>3.2.5</surefire-plugin.version>
</properties>

<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-surefire-plugin</artifactId>
    <version>${surefire-plugin.version}</version>
    <configuration>
        <systemPropertyVariables>
            <java.util.logging.manager>org.jboss.logmanager.LogManager</java.util.logging.manager>
            <maven.home>${maven.home}</maven.home>
        </systemPropertyVariables>
    </configuration>
</plugin>
```

### 4.2 Threading Validation Setup

Ensure threading test scripts are executable:
```bash
# Make scripts executable
chmod +x quarkus-websocket-service/test-threading-local.sh
chmod +x scripts/test-vep-threading-local.sh
chmod +x scripts/test-local-integration.sh
```

### 4.3 Test Coverage Configuration

Add JaCoCo plugin for coverage reporting:
```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.10</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 🚀 Step 5: Deployment Configuration

### 5.1 Kustomize Structure Validation

Ensure your Kustomize structure is valid:
```bash
# Validate base manifests
kustomize build k8s/base

# Validate overlays
kustomize build k8s/overlays/dev
kustomize build k8s/overlays/staging
kustomize build k8s/overlays/prod
```

### 5.2 Image Registry Configuration

Update Kustomize images in overlays:

#### k8s/overlays/dev/kustomization.yaml
```yaml
images:
  - name: quarkus-websocket-service
    newName: ghcr.io/your-org/healthcare-ml/quarkus-websocket-service
    newTag: develop-latest
  - name: vep-service
    newName: ghcr.io/your-org/healthcare-ml/vep-service
    newTag: develop-latest
```

### 5.3 Health Check Configuration

Ensure services have proper health checks:
```yaml
# In deployment manifests
livenessProbe:
  httpGet:
    path: /q/health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /q/health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## 📊 Step 6: Monitoring & Observability

### 6.1 Cost Management Setup

Ensure cost attribution labels are applied:
```yaml
metadata:
  labels:
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
    app.kubernetes.io/name: "service-name"
    app.kubernetes.io/part-of: "healthcare-ml-demo"
  annotations:
    cost-center: "genomics-research"
    project: "risk-predictor-v1"
```

### 6.2 Metrics and Logging

Configure Prometheus metrics collection:
```yaml
# In service manifests
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/q/metrics"
```

## 🔄 Step 7: Workflow Triggers

### 7.1 Automated Triggers

The pipeline automatically triggers on:
- **Push to `main`**: Full pipeline + staging deployment
- **Push to `develop`**: Full pipeline + dev deployment
- **Push tags `v*`**: Full pipeline + production deployment
- **Pull requests**: Code quality + testing (no deployment)

### 7.2 Manual Triggers

Use workflow dispatch for:
- Testing pipeline changes
- Manual deployments
- Debugging specific services

## 🛠️ Step 8: Troubleshooting Setup

### 8.1 Common Setup Issues

#### Java Version Mismatch
```bash
# Verify Java 17 is configured
./mvnw --version
# Should show Java version 17.x.x
```

#### Maven Wrapper Permissions
```bash
# Fix permissions if needed
chmod +x mvnw
chmod +x */mvnw
```

#### OpenShift Connectivity
```bash
# Test OpenShift connection
oc whoami
oc get projects
```

### 8.2 Pipeline Validation

Test the pipeline setup:
1. Create a test branch
2. Make a small change to a service
3. Open a pull request
4. Verify all required checks run
5. Merge to `develop` and verify dev deployment

## 📚 Step 9: Documentation Updates

### 9.1 Update Project README

Add CI/CD badge to main README:
```markdown
[![CI/CD Pipeline](https://github.com/your-org/healthcare-ml/actions/workflows/ci-cd-pipeline.yml/badge.svg)](https://github.com/your-org/healthcare-ml/actions/workflows/ci-cd-pipeline.yml)
```

### 9.2 Team Training

Ensure your team understands:
- Branch protection rules and workflow
- Threading validation requirements
- Security compliance checks
- Deployment process and environments
- How to troubleshoot pipeline failures

## ✅ Step 10: Validation Checklist

Before going live, verify:

### Repository Configuration
- [ ] Branch protection rules configured
- [ ] Required secrets added
- [ ] Environments configured with proper protection
- [ ] Service accounts created in OpenShift

### Pipeline Testing
- [ ] Code quality checks pass
- [ ] Threading validation works for both services
- [ ] Unit tests run successfully
- [ ] Container images build and scan clean
- [ ] Kubernetes manifests validate
- [ ] Healthcare compliance checks pass

### Security & Compliance
- [ ] CodeQL analysis enabled
- [ ] Container security scanning configured
- [ ] HIPAA compliance validation works
- [ ] Cost attribution labels present
- [ ] RBAC permissions configured

### Deployment Readiness
- [ ] OpenShift namespaces prepared
- [ ] Registry secrets configured
- [ ] Health checks working
- [ ] Monitoring configured
- [ ] Cost management labels applied

## 🔄 Ongoing Maintenance

### Weekly Tasks
- Review Dependabot updates
- Check security scan results
- Monitor build performance
- Validate cost attribution

### Monthly Tasks
- Review and update documentation
- Audit security configurations
- Optimize pipeline performance
- Update compliance validations

### Quarterly Tasks
- Review branch protection rules
- Audit service account permissions
- Update security scanning tools
- Validate disaster recovery procedures

---

**🏥 Your Healthcare ML CI/CD pipeline is now ready for production use!**

For additional support, refer to the troubleshooting guide or create an issue using the provided templates.
