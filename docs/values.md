# BunkerWeb Helm Chart - Configuration Guide

Complete configuration guide for the BunkerWeb Helm chart with examples and best practices.

> 📚 **User Guide**: This document provides detailed explanations and examples for configuring BunkerWeb.
> For a quick reference, see [`values-reference.md`](values-reference.md).

## Quick Start

```bash
# Add the BunkerWeb Helm repository
helm repo add bunkerweb https://repo.bunkerweb.io/charts

# Install with default values
helm install mybunkerweb bunkerweb/bunkerweb

# Install with custom values
helm install mybunkerweb bunkerweb/bunkerweb -f custom-values.yaml
```

## Table of Contents

- [These settings apply to all components unless overridden](#these-settings-apply-to-all-components-unless-overridden)
- [Configuration for BunkerWeb behavior in Kubernetes environment](#configuration-for-bunkerweb-behavior-in-kubernetes-environment)
- [External service for BunkerWeb (LoadBalancer/NodePort)](#external-service-for-bunkerweb-loadbalancernodeport)
- [Main reverse proxy and WAF component](#main-reverse-proxy-and-waf-component)
- [Manages BunkerWeb configuration and coordination](#manages-bunkerweb-configuration-and-coordination)
- [Kubernetes controller for automatic Ingress management](#kubernetes-controller-for-automatic-ingress-management)
- [Web interface for BunkerWeb management and monitoring](#web-interface-for-bunkerweb-management-and-monitoring)
- [Database backend for BunkerWeb configuration and logs](#database-backend-for-bunkerweb-configuration-and-logs)
- [Cache and session storage for BunkerWeb](#cache-and-session-storage-for-bunkerweb)
- [Kubernetes IngressClass resource for BunkerWeb](#kubernetes-ingressclass-resource-for-bunkerweb)
- [Metrics collection and storage](#metrics-collection-and-storage)
- [Dashboards and visualization](#dashboards-and-visualization)
- [Network policies for micro-segmentation](#network-policies-for-micro-segmentation)

## These settings apply to all components unless overridden

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `imagePullSecrets` | Global image pull secrets for private registries | `list` | `[]` |
| `nameOverride` | Override the chart name (default: chart name) | `string` | `""` |
| `namespaceOverride` | Override the namespace (default: release namespace) | `string` | `""` |
| `fullnameOverride` | Override the full resource name (default: release-chart) | `string` | `""` |
| `nodeSelector` | Node selector for all pods (can be overridden per component) | `object` | `{}` |
| `tolerations` | Tolerations for all pods (can be overridden per component) | `list` | `[]` |
| `topologySpreadConstraints` | Topology spread constraints for better pod distribution | `list` | `[]` |

## Configuration for BunkerWeb behavior in Kubernetes environment

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `settings` | Configuration for settings | `object` | See values.yaml |
| `ingressClass` | Ingress class name that BunkerWeb will handle Must match the IngressClass resource name | `object` | See values.yaml |
| `redis` | ----- REDIS CONFIGURATION ----- | `object` | See values.yaml |
| `ui` | ----- WEB UI CONFIGURATION ----- | `object` | See values.yaml |

## External service for BunkerWeb (LoadBalancer/NodePort)

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `service` | Configuration for service | `object` | See values.yaml |

## Main reverse proxy and WAF component

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `bunkerweb` | Configuration for bunkerweb | `object` | See values.yaml |
| `imagePullSecrets` | Image pull secrets (overrides global setting) | `list` | `[]` |
| `nodeSelector` | Node selector (overrides global setting) | `object` | `{}` |
| `tolerations` | Tolerations (overrides global setting) | `list` | `[]` |

## Manages BunkerWeb configuration and coordination

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `scheduler` | Configuration for scheduler | `object` | See values.yaml |
| `imagePullSecrets` | Image pull secrets (overrides global setting) | `list` | `[]` |
| `nodeSelector` | Node selector (overrides global setting) | `object` | `{}` |
| `tolerations` | Tolerations (overrides global setting) | `list` | `[]` |

## Kubernetes controller for automatic Ingress management

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `controller` | Configuration for controller | `object` | See values.yaml |
| `imagePullSecrets` | Image pull secrets (overrides global setting) | `list` | `[]` |
| `nodeSelector` | Node selector (overrides global setting) | `object` | `{}` |
| `tolerations` | Tolerations (overrides global setting) | `list` | `[]` |

## Web interface for BunkerWeb management and monitoring

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `ui` | Configuration for ui | `object` | See values.yaml |
| `imagePullSecrets` | Image pull secrets (overrides global setting) | `list` | `[]` |
| `nodeSelector` | Node selector (overrides global setting) | `object` | `{}` |
| `tolerations` | Tolerations (overrides global setting) | `list` | `[]` |

## Database backend for BunkerWeb configuration and logs

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `mariadb` | Configuration for mariadb | `object` | See values.yaml |
| `imagePullSecrets` | Image pull secrets (overrides global setting) | `list` | `[]` |
| `nodeSelector` | Node selector (overrides global setting) | `object` | `{}` |
| `tolerations` | Tolerations (overrides global setting) | `list` | `[]` |

## Cache and session storage for BunkerWeb

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `redis` | Configuration for redis | `object` | See values.yaml |
| `imagePullSecrets` | Image pull secrets (overrides global setting) | `list` | `[]` |
| `nodeSelector` | Node selector (overrides global setting) | `object` | `{}` |
| `tolerations` | Tolerations (overrides global setting) | `list` | `[]` |

## Kubernetes IngressClass resource for BunkerWeb

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `ingressClass` | Configuration for ingressClass | `object` | See values.yaml |
| `controller` | Controller identifier for this IngressClass | `object` | See values.yaml |

## Metrics collection and storage

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `prometheus` | Configuration for prometheus | `object` | See values.yaml |

## Dashboards and visualization

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `grafana` | Configuration for grafana | `object` | See values.yaml |
| `service` | Service configuration | `object` | See values.yaml |

## Network policies for micro-segmentation

### Configuration Values

| Parameter | Description | Type | Default |
|-----------|-------------|------|---------|
| `networkPolicy` | Configuration for networkPolicy | `object` | See values.yaml |

## Best Practices

### Security
- Always change default passwords in production
- Use Kubernetes secrets for sensitive data
- Enable network policies for micro-segmentation
- Set appropriate resource limits

### Performance
- Use DaemonSet for better performance
- Configure resource requests and limits
- Enable persistent storage for databases

### High Availability
- Enable Pod Disruption Budgets
- Use anti-affinity rules
- Configure health checks properly

## Examples

See the [`examples/`](../examples/) directory for complete configuration examples:
- [`minimal.yaml`](../examples/minimal.yaml) - Basic setup
- [`production.yaml`](../examples/production.yaml) - Production-ready configuration
- [`monitoring.yaml`](../examples/monitoring.yaml) - Full monitoring stack