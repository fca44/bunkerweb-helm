# BunkerWeb Kubernetes Helm chart

Official [Helm chart](https://helm.sh/docs/) to deploy [BunkerWeb](https://www.bunkerweb.io/?utm_campaign=self&utm_source=github) on Kubernetes.

## Prerequisites

Please first refer to the [BunkerWeb documentation](https://docs.bunkerweb.io/latest/?utm_campaign=self&utm_source=github), particularly the [Kubernetes integration](https://docs.bunkerweb.io/latest/integrations/?utm_campaign=self&utm_source=bunkerwebio#kubernetes) section.

## Helm repository

The BunkerWeb Helm chart repository is available at `https://repo.bunkerweb.io/charts` : 
```bash
helm repo add bunkerweb https://repo.bunkerweb.io/charts
```

You can then use the `bunkerweb` helm chart from that repository :
```bash
helm install -f myvalues.yaml mybunkerweb bunkerweb/bunkerweb
```

## Values

The full list of values are listed in the `charts/bunkerweb/values.yaml` file.