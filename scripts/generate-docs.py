#!/usr/bin/env python3
"""
BunkerWeb Helm Chart Values Documentation Generator

This script generates two types of markdown documentation from the values.yaml file:
1. values-reference.md: Technical reference (auto-generated, searchable)
2. values.md: User guide with examples and best practices

Usage:
    python3 scripts/generate-docs.py
"""

import yaml
import re
import os
from typing import Dict, Any, List, Tuple

def parse_comment_block(lines: List[str], start_idx: int) -> Tuple[str, List[str]]:
    """
    Parse a comment block and extract description and examples.
    
    Args:
        lines: All lines from the file
        start_idx: Starting index of the comment block
    
    Returns:
        Tuple of (description, examples)
    """
    description_lines = []
    examples = []
    
    i = start_idx
    while i < len(lines) and lines[i].strip().startswith('#'):
        line = lines[i].strip()
        if line.startswith('#'):
            # Remove leading # and whitespace
            content = line[1:].strip()
            if content.startswith('Example:'):
                # This is an example
                examples.append(content[8:].strip())
            elif content and not content.startswith('====='):
                # This is part of the description
                description_lines.append(content)
        i += 1
    
    description = ' '.join(description_lines) if description_lines else ""
    return description, examples

def get_yaml_type(value: Any) -> str:
    """Get the YAML type of a value."""
    if isinstance(value, bool):
        return "bool"
    elif isinstance(value, int):
        return "int"
    elif isinstance(value, str):
        return "string"
    elif isinstance(value, list):
        return "list"
    elif isinstance(value, dict):
        return "object"
    else:
        return "mixed"

def get_default_value(value: Any) -> str:
    """Get a string representation of the default value."""
    if isinstance(value, str):
        if value == "":
            return '`""`'
        else:
            return f'`"{value}"`'
    elif isinstance(value, bool):
        return f"`{str(value).lower()}`"
    elif isinstance(value, (int, float)):
        return f"`{value}`"
    elif isinstance(value, list):
        if not value:
            return "`[]`"
        else:
            return f"`{value}`"
    elif isinstance(value, dict):
        if not value:
            return "`{}`"
        else:
            return "See values.yaml"
    else:
        return f"`{str(value)}`"

def extract_values_documentation(values_path: str) -> List[Dict]:
    """
    Extract documentation from values.yaml file.
    
    Args:
        values_path: Path to the values.yaml file
    
    Returns:
        List of dictionaries containing parameter documentation
    """
    with open(values_path, 'r') as f:
        lines = f.readlines()
    
    # Load the YAML to get actual values
    with open(values_path, 'r') as f:
        yaml_content = yaml.safe_load(f)
    
    docs = []
    current_section = ""
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Check for section headers
        if line.startswith('# ====='):
            # Look for section title in next lines
            j = i + 1
            while j < len(lines) and lines[j].strip().startswith('#'):
                section_line = lines[j].strip()
                if not section_line.startswith('# =====') and section_line != '#':
                    current_section = section_line[1:].strip()
                    break
                j += 1
            i = j
            continue
        
        # Look for parameter definitions (lines that don't start with # and contain :)
        if not line.startswith('#') and ':' in line and not line.startswith('---'):
            # Extract parameter name
            param_match = re.match(r'^(\s*)([^:]+):', line)
            if param_match:
                indent = len(param_match.group(1))
                param_name = param_match.group(2).strip()
                
                # Skip if this looks like a value, not a key
                if param_name.startswith('"') or param_name.startswith("'"):
                    i += 1
                    continue
                
                # Look backwards for comments
                description = ""
                examples = []
                
                j = i - 1
                comment_lines = []
                while j >= 0 and (lines[j].strip().startswith('#') or lines[j].strip() == ''):
                    if lines[j].strip().startswith('#'):
                        comment_lines.insert(0, lines[j])
                    elif lines[j].strip() == '':
                        break
                    j -= 1
                
                if comment_lines:
                    desc, ex = parse_comment_block(comment_lines, 0)
                    description = desc
                    examples = ex
                
                # Get the actual value from YAML
                try:
                    # Build the path to this parameter
                    path_parts = []
                    
                    # Look backwards to build the full path
                    current_indent = indent
                    k = i - 1
                    parent_parts = []
                    
                    while k >= 0:
                        prev_line = lines[k].strip()
                        if not prev_line.startswith('#') and ':' in prev_line and not prev_line.startswith('---'):
                            prev_match = re.match(r'^(\s*)([^:]+):', lines[k])
                            if prev_match:
                                prev_indent = len(prev_match.group(1))
                                prev_param = prev_match.group(2).strip()
                                
                                if prev_indent < current_indent:
                                    parent_parts.insert(0, prev_param)
                                    current_indent = prev_indent
                        k -= 1
                    
                    # Get value from YAML
                    value = yaml_content
                    full_path = parent_parts + [param_name]
                    
                    for part in full_path:
                        if isinstance(value, dict) and part in value:
                            value = value[part]
                        else:
                            value = None
                            break
                    
                    if value is not None:
                        param_type = get_yaml_type(value)
                        default_val = get_default_value(value)
                        
                        # Build full parameter name
                        full_param_name = '.'.join(full_path)
                        
                        docs.append({
                            'section': current_section,
                            'parameter': full_param_name,
                            'description': description or f"Configuration for {param_name}",
                            'type': param_type,
                            'default': default_val,
                            'examples': examples
                        })
                
                except Exception as e:
                    # If we can't get the value, skip it
                    pass
        
        i += 1
    
    return docs

def group_by_section(docs: List[Dict]) -> Dict[str, List[Dict]]:
    """Group documentation by section."""
    sections = {}
    for doc in docs:
        section = doc['section'] or 'General'
        if section not in sections:
            sections[section] = []
        sections[section].append(doc)
    return sections

def generate_markdown_table(docs: List[Dict]) -> str:
    """Generate a markdown table from documentation."""
    if not docs:
        return ""
    
    lines = []
    lines.append("| Parameter | Description | Type | Default |")
    lines.append("|-----------|-------------|------|---------|")
    
    for doc in docs:
        param = f"`{doc['parameter']}`"
        desc = doc['description'].replace('|', '\\|')  # Escape pipes
        type_val = f"`{doc['type']}`"
        default = doc['default']
        
        lines.append(f"| {param} | {desc} | {type_val} | {default} |")
    
    return '\n'.join(lines)

def generate_reference_documentation(docs: List[Dict]) -> List[str]:
    """Generate technical reference documentation (values-reference.md)."""
    content = []
    
    # Header
    content.append("# BunkerWeb Helm Chart - Values Reference")
    content.append("")
    content.append("Quick reference for all configuration values available in the BunkerWeb Helm chart.")
    content.append("")
    content.append("> ⚠️ **Auto-generated**: This file is automatically generated from `values.yaml`. Do not edit manually.")
    content.append("")
    
    sections = group_by_section(docs)
    
    # Table of contents
    content.append("## Table of Contents")
    content.append("")
    for section_name in sections.keys():
        anchor = section_name.lower().replace(' ', '-').replace('(', '').replace(')', '').replace('/', '')
        content.append(f"- [{section_name}](#{anchor})")
    content.append("")
    
    # Sections with compact tables
    for section_name, section_docs in sections.items():
        anchor = section_name.lower().replace(' ', '-').replace('(', '').replace(')', '').replace('/', '')
        content.append(f"## {section_name}")
        content.append("")
        
        table = generate_markdown_table(section_docs)
        content.append(table)
        content.append("")
    
    # Footer
    content.append("## Further Reading")
    content.append("")
    content.append("- [BunkerWeb Documentation](https://docs.bunkerweb.io/)")
    content.append("- [Kubernetes Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/)")
    content.append("- [Helm Chart Development Guide](https://helm.sh/docs/chart_template_guide/)")
    content.append("")
    content.append("---")
    content.append("*This documentation was auto-generated from `values.yaml`*")
    
    return content

def generate_user_guide_documentation(docs: List[Dict]) -> List[str]:
    """Generate user-friendly guide documentation (values.md)."""
    content = []
    
    # Header
    content.append("# BunkerWeb Helm Chart - Configuration Guide")
    content.append("")
    content.append("Complete configuration guide for the BunkerWeb Helm chart with examples and best practices.")
    content.append("")
    content.append("> 📚 **User Guide**: This document provides detailed explanations and examples for configuring BunkerWeb.")
    content.append("> For a quick reference, see [`values-reference.md`](values-reference.md).")
    content.append("")
    
    # Quick start section
    content.append("## Quick Start")
    content.append("")
    content.append("```bash")
    content.append("# Add the BunkerWeb Helm repository")
    content.append("helm repo add bunkerweb https://repo.bunkerweb.io/charts")
    content.append("")
    content.append("# Install with default values")
    content.append("helm install mybunkerweb bunkerweb/bunkerweb")
    content.append("")
    content.append("# Install with custom values")
    content.append("helm install mybunkerweb bunkerweb/bunkerweb -f custom-values.yaml")
    content.append("```")
    content.append("")
    
    sections = group_by_section(docs)
    
    # Table of contents
    content.append("## Table of Contents")
    content.append("")
    for section_name in sections.keys():
        anchor = section_name.lower().replace(' ', '-').replace('(', '').replace(')', '').replace('/', '')
        content.append(f"- [{section_name}](#{anchor})")
    content.append("")
    
    # Detailed sections with examples
    for section_name, section_docs in sections.items():
        anchor = section_name.lower().replace(' ', '-').replace('(', '').replace(')', '').replace('/', '')
        content.append(f"## {section_name}")
        content.append("")
        
        # Add section description based on section name
        if "Global" in section_name:
            content.append("These settings apply to all components and can be overridden by component-specific values.")
            content.append("")
            content.append("### Example Configuration")
            content.append("```yaml")
            content.append("# Global node selector")
            content.append("nodeSelector:")
            content.append('  kubernetes.io/arch: "amd64"')
            content.append("")
            content.append("# Global tolerations")
            content.append("tolerations:")
            content.append("  - key: node-role")
            content.append("    operator: Equal")
            content.append("    value: master")
            content.append("    effect: NoSchedule")
            content.append("```")
            content.append("")
        elif "BunkerWeb" in section_name and "Core" in section_name:
            content.append("Core BunkerWeb settings that control how it behaves in the Kubernetes environment.")
            content.append("")
            content.append("### Security Configuration")
            content.append("```yaml")
            content.append("settings:")
            content.append("  # Use existing secret for sensitive data")
            content.append("  existingSecret: \"bunkerweb-secrets\"")
            content.append("  ")
            content.append("  kubernetes:")
            content.append("    # Monitor specific namespaces")
            content.append("    namespaces: \"default,production\"")
            content.append("    ingressClass: \"bunkerweb\"")
            content.append("```")
            content.append("")
        elif "Service" in section_name:
            content.append("Configure how BunkerWeb is exposed outside the cluster.")
            content.append("")
            content.append("### Load Balancer Configuration")
            content.append("```yaml")
            content.append("service:")
            content.append("  type: LoadBalancer")
            content.append("  externalTrafficPolicy: Local")
            content.append("  annotations:")
            content.append("    # AWS Network Load Balancer")
            content.append('    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"')
            content.append("```")
            content.append("")
        elif "BunkerWeb Component" in section_name:
            content.append("Main BunkerWeb reverse proxy and WAF configuration.")
            content.append("")
            content.append("### DaemonSet vs Deployment")
            content.append("```yaml")
            content.append("bunkerweb:")
            content.append("  # DaemonSet: One pod per node (recommended)")
            content.append("  kind: DaemonSet")
            content.append("  hostPorts: true")
            content.append("  ")
            content.append("  # OR Deployment: Specific number of replicas")
            content.append("  # kind: Deployment")
            content.append("  # replicas: 3")
            content.append("  # hostPorts: false")
            content.append("```")
            content.append("")
        elif "Monitoring" in section_name:
            content.append("Monitoring and observability configuration.")
            content.append("")
            content.append("### Enable Full Monitoring Stack")
            content.append("```yaml")
            if "Prometheus" in section_name:
                content.append("prometheus:")
                content.append("  enabled: true")
                content.append("  persistence:")
                content.append("    enabled: true")
                content.append("    size: 50Gi")
            else:  # Grafana
                content.append("grafana:")
                content.append("  enabled: true")
                content.append("  adminPassword: \"secure-password\"")
                content.append("  ingress:")
                content.append("    enabled: true")
                content.append("    hosts:")
                content.append("      - host: grafana.example.com")
            content.append("```")
            content.append("")
        
        # Configuration table
        content.append("### Configuration Values")
        content.append("")
        table = generate_markdown_table(section_docs)
        content.append(table)
        content.append("")
    
    # Best practices section
    content.append("## Best Practices")
    content.append("")
    content.append("### Security")
    content.append("- Always change default passwords in production")
    content.append("- Use Kubernetes secrets for sensitive data")
    content.append("- Enable network policies for micro-segmentation")
    content.append("- Set appropriate resource limits")
    content.append("")
    content.append("### Performance")
    content.append("- Use DaemonSet for better performance")
    content.append("- Configure resource requests and limits")
    content.append("- Enable persistent storage for databases")
    content.append("")
    content.append("### High Availability")
    content.append("- Enable Pod Disruption Budgets")
    content.append("- Use anti-affinity rules")
    content.append("- Configure health checks properly")
    content.append("")
    content.append("## Examples")
    content.append("")
    content.append("See the [`examples/`](../examples/) directory for complete configuration examples:")
    content.append("- [`minimal.yaml`](../examples/minimal.yaml) - Basic setup")
    content.append("- [`production.yaml`](../examples/production.yaml) - Production-ready configuration")
    content.append("- [`monitoring.yaml`](../examples/monitoring.yaml) - Full monitoring stack")
    
    return content

def generate_documentation(values_path: str, reference_output_path: str, guide_output_path: str):
    """Generate both types of documentation."""
    
    print(f"Parsing {values_path}...")
    docs = extract_values_documentation(values_path)
    
    print(f"Found {len(docs)} parameters")
    
    # Generate reference documentation
    print("Generating values-reference.md...")
    reference_content = generate_reference_documentation(docs)
    
    # Generate user guide documentation  
    print("Generating values.md...")
    guide_content = generate_user_guide_documentation(docs)
    
    # Write reference file
    os.makedirs(os.path.dirname(reference_output_path), exist_ok=True)
    with open(reference_output_path, 'w') as f:
        f.write('\n'.join(reference_content))
    print(f"✅ Reference documentation: {reference_output_path}")
    
    # Write guide file
    os.makedirs(os.path.dirname(guide_output_path), exist_ok=True)
    with open(guide_output_path, 'w') as f:
        f.write('\n'.join(guide_content))
    print(f"✅ User guide documentation: {guide_output_path}")

if __name__ == "__main__":
    # Paths relative to the script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    
    values_path = os.path.join(repo_root, "charts", "bunkerweb", "values.yaml")
    reference_output_path = os.path.join(repo_root, "docs", "values-reference.md")
    guide_output_path = os.path.join(repo_root, "docs", "values.md")
    
    if not os.path.exists(values_path):
        print(f"❌ Error: values.yaml not found at {values_path}")
        exit(1)
    
    generate_documentation(values_path, reference_output_path, guide_output_path)
    print("🎉 Documentation generation complete!")
