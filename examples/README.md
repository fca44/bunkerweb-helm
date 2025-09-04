# BunkerWeb Helm Chart Examples

This directory contains example configurations for common BunkerWeb deployment scenarios.

## Available Examples

### Basic Configurations

- [`minimal.yaml`](minimal.yaml) - Minimal configuration for testing
- [`production.yaml`](production.yaml) - Production-ready setup with persistence
- [`monitoring.yaml`](monitoring.yaml) - Full monitoring stack with Prometheus and Grafana

## Future Examples to come and open to contribution

- [`high-availability.yaml`](high-availability.yaml) - HA setup with multiple replicas
- [`external-database.yaml`](external-database.yaml) - Using external MariaDB and Redis
- [`security-hardened.yaml`](security-hardened.yaml) - Security-focused configuration
- [`multi-tenant.yaml`](multi-tenant.yaml) - Multi-tenant setup with namespace isolation
- [`edge-deployment.yaml`](edge-deployment.yaml) - Edge/CDN-style deployment

## Usage

To use any of these examples:

```bash
# Download the example file
curl -O https://raw.githubusercontent.com/bunkerity/bunkerweb-helm/main/examples/production.yaml

# Install BunkerWeb with the example configuration
helm install mybunkerweb bunkerweb/bunkerweb -f production.yaml

# Or upgrade existing installation
helm upgrade mybunkerweb bunkerweb/bunkerweb -f production.yaml
```

## Customization

These examples serve as starting points. You should:

1. Review all settings for your specific needs
2. Change default passwords and secrets
3. Adjust resource limits based on your workload
4. Configure ingress hostnames and TLS certificates
5. Set appropriate storage classes and sizes

## Security Notes

⚠️ **Important**: These examples contain default passwords and settings that should be changed for production use. Always:

- Use strong, unique passwords
- Store secrets in Kubernetes Secret resources
- Enable TLS/SSL with proper certificates
- Configure network policies for your environment
- Set appropriate RBAC permissions
