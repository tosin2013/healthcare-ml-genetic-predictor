# Security Policy

## Supported Versions

This project is currently in active development. Security updates are provided for the latest version only.

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Healthcare ML Genetic Predictor seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### **Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to:

**tosin.akinosho@redhat.com**

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

### What to Include in Your Report

Please include the following information to help us better understand the nature and scope of the possible vulnerability:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Our Security Process

1. **Acknowledgement**: We will acknowledge receipt of your vulnerability report within 48 hours
2. **Investigation**: Our team will investigate the report and determine the impact and severity
3. **Fix Development**: If confirmed, we will develop a fix for the vulnerability
4. **Testing**: The fix will undergo thorough testing
5. **Release**: We will release the fix in a timely manner
6. **Disclosure**: We will coordinate public disclosure with you

### Vulnerability Disclosure Policy

We follow a coordinated disclosure policy:

- **90-day disclosure deadline**: We aim to resolve critical vulnerabilities within 90 days
- **Grace period**: We may request additional time for complex issues
- **Transparency**: We will keep you informed of our progress
- **Credit**: We will credit reporters in our security advisories (unless requested otherwise)

### Security Best Practices

This project follows security best practices including:

- Regular dependency vulnerability scanning
- Code review processes
- Automated security testing
- Principle of least privilege in deployment configurations
- Encryption of sensitive data in transit and at rest
- Input validation and sanitization
- Secure coding standards

### Security Updates

Security updates are released as patch versions. We recommend:

- Keeping your deployment environment updated
- Monitoring this repository for security advisories
- Subscribing to release notifications
- Regularly reviewing dependency vulnerabilities

### Additional Resources

- [OpenShift Security](https://www.redhat.com/en/topics/security)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
- [Apache Kafka Security](https://kafka.apache.org/documentation/#security)
- [Quarkus Security](https://quarkus.io/guides/security)

---

*Thank you for helping keep Healthcare ML Genetic Predictor and our users safe!*