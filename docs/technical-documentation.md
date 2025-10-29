# Documentación Técnica: Plataforma Kubernetes Empresarial

## 1. Arquitectura del Clúster
- **Control Plane**: Tres nodos maestros desplegados con kubeadm, etcd en modo HA usando certificados TLS y cifrado en reposo (`manifests/cluster-init.yaml`).
- **Nodos Worker**: Al menos tres nodos distribuidos en zonas de disponibilidad múltiples con labels para segmentar cargas dev/staging/prod.
- **Namespaces**: Separación lógica por entorno con políticas de seguridad mediante Pod Security Standards (PSS) estrictas (`baseline` y `restricted`).

## 2. Seguridad y Cumplimiento
- **RBAC**: Roles y RoleBindings mínimos para operadores, desarrolladores y automatización (`manifests/rbac-and-security.yaml`).
- **OPA Gatekeeper**: Plantillas y Constraints que fuerzan políticas PCI/GDPR (no privilegios, etiquetas obligatorias).
- **Cifrado**: Proveedor de cifrado para etcd y uso de Vault para secretos críticos (`manifests/secrets-and-vault.yaml`).
- **Network Policies**: Calico/Cilium restringen tráfico east-west, permitiendo únicamente comunicaciones explícitas.
- **Auditoría**: Configuración del API Server con logging extendido y envío a la pila ELK (`manifests/monitoring-observability.yaml`).

## 3. Redes y Entrada de Tráfico
- **CNI**: Calico con eBPF habilitado (opcional Cilium) para visibilidad de red (`manifests/networking.yaml`).
- **Ingress**: NGINX Ingress Controller HA con certificados TLS emitidos por Let's Encrypt y compatibilidad con Istio Gateway (`helm/microservice/templates/ingress.yaml`).
- **Service Mesh**: Istio opcional para mTLS, control de tráfico y observabilidad (`manifests/service-mesh.yaml`).

## 4. Almacenamiento y Gestión de Recursos
- **Storage Classes**: CSI (AWS EBS/Longhorn) con políticas replicadas y snapshots (`manifests/storage-and-resources.yaml`).
- **QoS y Quotas**: LimitRanges y ResourceQuotas por namespace, más Pod Disruption Budgets para resiliencia.
- **PVCs**: Definidos para aplicaciones críticas como PostgreSQL (`helm/microservice/templates/postgres.yaml`).

## 5. Monitoreo y Observabilidad
- **Zabbix**: Deployment HA con agentes en DaemonSet para nodos y pods, integrado con HPA (`manifests/monitoring-observability.yaml`).
- **Wazuh**: Recolección de eventos de seguridad y SIEM distribuido.
- **ELK + Kibana**: Ingesta de logs de Kubernetes y aplicaciones, con pipelines Beats/FluentD.
- **InfluxDB + Telegraf**: Métricas de series temporales para autoscaling avanzado.
- **Netdata**: Visibilidad en tiempo real de recursos node-level.
- **kube-state-metrics & node-exporter**: Métricas nativas para integraciones externas.

## 6. CI/CD y Automatización
- **Argo CD**: Despliegue GitOps de aplicaciones y control declarativo (`manifests/cicd-autoscaling.yaml`).
- **Pipelines**: Integración con repos Git y Hooks para ejecutar Helm charts (`helm/microservice`).
- **Autoscaling**: Cluster Autoscaler y HPA configurados para métricas personalizadas.

## 7. Aplicación de Referencia
- **Microservicio Nginx + PostgreSQL**: Helm chart modular con configuraciones para secrets, ingress, HPA y PDB.
- **Monitoreo**: Dashboards preconfigurados en Zabbix y alertas QoS en InfluxDB/Telegraf.
- **Seguridad**: Reglas Wazuh personalizadas y cumplimiento de PSS restringido.

## 8. Procedimiento de Despliegue
1. **Bootstrap**: `kubectl apply -f manifests/cluster-init.yaml` para inicializar control plane y nodos.
2. **Seguridad Base**: `kubectl apply -f manifests/rbac-and-security.yaml` y `manifests/networking.yaml`.
3. **Observabilidad**: `kubectl apply -f manifests/monitoring-observability.yaml`.
4. **Secretos**: `kubectl apply -f manifests/secrets-and-vault.yaml`.
5. **Storage y Recursos**: `kubectl apply -f manifests/storage-and-resources.yaml`.
6. **GitOps y Autoscaling**: `kubectl apply -f manifests/cicd-autoscaling.yaml`.
7. **Service Mesh**: `kubectl apply -f manifests/service-mesh.yaml` (opcional).
8. **Aplicación**: `helm install sample-app helm/microservice -n prod`.

## 9. Consideraciones Operacionales
- **Backups**: etcd snapshots automáticos y backups de Vault.
- **Actualizaciones**: Uso de PDBs y `kubectl drain` coordinado con autoscaler.
- **Cumplimiento**: Revisiones periódicas de auditoría API y reportes Wazuh.
- **Costos**: Ajustar solicitudes/limites y políticas HPA para balancear gasto y rendimiento.

