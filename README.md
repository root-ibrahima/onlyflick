# OnlyFlick

OnlyFlick est une application Flutter conçue pour [brève description ici, par exemple : permettre le streaming, la gestion ou la découverte de contenus multimédia dans un environnement distribué].

## Getting Started

### Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Chrome browser](https://www.google.com/chrome/) (pour le développement web)
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [Grafana](https://grafana.com/)
- [Prometheus](https://prometheus.io/)

### Installation de l'application Flutter

1. Cloner le dépôt

    ```bash
    git clone https://github.com/ibrahima-eemi/onlyflick.git
    cd onlyflick
    ```

2. Nettoyer le projet

    ```bash
    flutter clean
    ```

3. Installer les dépendances

    ```bash
    flutter pub get
    ```

### Lancement de l'application Flutter

Pour exécuter l'application dans Chrome :

```bash
flutter run -d chrome
```

## Fonctionnalités de l'application

- [Fonctionnalité 1]
- [Fonctionnalité 2]
- [Fonctionnalité 3]

## Infrastructure Kubernetes & Monitoring

Le projet intègre un environnement Kubernetes pour le déploiement de l'application, accompagné d'un système de monitoring complet avec Prometheus et Grafana.

### Services inclus

- **Prometheus** : collecte des métriques systèmes, applicatives et Kubernetes
- **Grafana** : visualisation des données, dashboards personnalisés
- **Kube-State-Metrics** : expose les états de ressources Kubernetes
- **Node Exporter** : expose les métriques système (CPU, RAM, disque)

### Dashboards Grafana

Un dossier dédié contient les dashboards pour le monitoring :

Chemin : `grafana/dashboards/`

#### Dashboard principal

`devops_dashboard_grafana.json` :
Dashboard combiné incluant :

- Métriques système (CPU, mémoire, disque, uptime)
- Métriques Kubernetes (pods, nodes, namespaces)
- Variables dynamiques pour filtrage

#### Import manuel

Depuis Grafana :

1. Aller dans Dashboards > Import
2. Cliquer sur Upload JSON file
3. Sélectionner `grafana/dashboards/devops_dashboard_grafana.json`

#### Import via API Grafana

```bash
curl -X POST http://<GRAFANA_URL>/api/dashboards/db \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <API_KEY>" \
  --data-binary @grafana/dashboards/devops_dashboard_grafana.json
```

Remplacer `<GRAFANA_URL>` et `<API_KEY>` par vos valeurs

### Déploiement Kubernetes (exemple local)

1. Démarrer Minikube ou KinD

2. Déployer Prometheus + Grafana via Helm :

    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    helm install monitoring prometheus-community/kube-prometheus-stack \
      --namespace monitoring --create-namespace
    ```

3. Appliquer les ingress pour exposer les services :

    ```bash
    kubectl apply -f k8s/grafana-ingress.yaml
    kubectl apply -f k8s/onlyflick-ingress.yaml
    ```

4. Ajouter les entrées dans `/etc/hosts` si besoin :

    ```txt
    127.0.0.1 grafana.local onlyflick.local
    ```
