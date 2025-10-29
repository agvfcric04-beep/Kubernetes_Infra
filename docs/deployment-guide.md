# Guía de Despliegue: Plataforma Kubernetes Empresarial

> **Propósito**: Proporcionar pasos operativos, requisitos y validaciones para desplegar y mantener el clúster Kubernetes descrito en la documentación técnica.

## 1. Requisitos Previos

### 1.1 Infraestructura
- **Control Plane**: 3 nodos (4 vCPU, 16 GB RAM, 100 GB SSD) distribuidos en al menos dos zonas de disponibilidad.
- **Workers**: Mínimo 3 nodos (4 vCPU, 16 GB RAM, 200 GB SSD) con etiquetas `topology.kubernetes.io/zone` para balanceo multi-AZ.
- **Red**: Subredes dedicadas para control plane y workers con conectividad privada; latencia intra-AZ < 2 ms.
- **Balanceadores**: Endpoint externo para API server (Network LB) y otro para Ingress NGINX/Traefik.
- **DNS**: Zona pública/privada para registrar FQDNs de API (`api.<dominio>`) e ingress (`apps.<dominio>`).

### 1.2 Software y Herramientas
- `kubectl` 1.28+ y `helm` 3.12+ instalados en la estación de administración.
- Acceso a repositorio Git con manifests (`manifests/`) y charts (`helm/`).
- Credenciales con permisos de administrador en la infraestructura (AWS IAM, vSphere, bare-metal, etc.).
- Certificados TLS válidos o acceso a Let's Encrypt (mediante cert-manager incluido en `manifests/networking.yaml`).

### 1.3 Seguridad y Cumplimiento
- Integración con gestor de identidades (IAM/AD/LDAP) para grupos `cluster-admin`, `platform-ops`, `developers`.
- Vault desplegado externamente o habilitado en `manifests/secrets-and-vault.yaml` con backends de almacenamiento resistentes.
- Auditoría corporativa habilitada (S3, syslog, ELK) para logs del API server y Wazuh.

## 2. Flujo de Despliegue

1. **Inicialización del Control Plane**
   - Revisar/ajustar `manifests/cluster-init.yaml` con valores de certificados, tokens kubeadm y endpoints.
   - Ejecutar en un nodo maestro primario: `kubeadm init --config manifests/cluster-init.yaml`.
   - Unir nodos maestros y workers con los comandos `kubeadm join` generados (añadir flags `--control-plane` y `--certificate-key` para HA).
2. **Configurar kubectl**
   - Copiar `/etc/kubernetes/admin.conf` al nodo de administración y exportar `KUBECONFIG`.
   - Verificar conectividad: `kubectl get nodes` debe mostrar todos los nodos en `Ready`.
3. **Namespaces y Políticas Base**
   - `kubectl apply -f manifests/rbac-and-security.yaml` para namespaces, PSS labels, RBAC inicial y Gatekeeper.
   - Confirmar status de Gatekeeper: `kubectl get pods -n gatekeeper-system`.
4. **Red y Entrada**
   - `kubectl apply -f manifests/networking.yaml` para Calico/Cilium, cert-manager e Ingress Controller.
   - Validar pods `calico-node`/`cilium` y `ingress-nginx` en estado `Running`.
5. **Almacenamiento y Recursos**
   - `kubectl apply -f manifests/storage-and-resources.yaml` para StorageClasses CSI, quotas y LimitRanges.
   - Crear PVC de prueba: `kubectl apply -f manifests/tests/pvc-smoke.yaml` (opcional) y comprobar binding.
6. **Seguridad Avanzada y Secretos**
   - `kubectl apply -f manifests/secrets-and-vault.yaml` para habilitar sincronización con Vault y cifrado de secretos.
   - Probar creación de secreto cifrado: `kubectl create secret generic vault-test --from-literal=foo=bar -n dev`.
7. **Observabilidad y SIEM**
   - `kubectl apply -f manifests/monitoring-observability.yaml` para Zabbix, Wazuh, ELK, InfluxDB, Telegraf, Netdata.
   - Esperar a que StatefulSets `zabbix-server`, `wazuh-manager`, `elasticsearch` reporten `Ready`.
8. **GitOps, Autoscaling y Mesh**
   - `kubectl apply -f manifests/cicd-autoscaling.yaml` para Argo CD, HPAs personalizados y Cluster Autoscaler.
   - (Opcional) `kubectl apply -f manifests/service-mesh.yaml` para Istio cuando se requiera mTLS avanzado.
9. **Aplicación de Referencia**
   - `helm upgrade --install sample-app helm/microservice -n prod --create-namespace`.
   - Verificar `kubectl get pods -n prod` y confirmar endpoints en `kubectl get ingress -n prod`.

## 3. Validaciones Posteriores

- **Salud del Clúster**: `kubectl get cs` (o `kubectl get --raw /healthz`) y `kubectl top nodes`.
- **Cumplimiento PSS**: Intentar desplegar un pod privilegiado en `dev` y verificar rechazo por Gatekeeper/PSS.
- **Network Policies**: Ejecutar pruebas de conectividad con `kubectl exec` y herramientas como `netshoot` en namespaces restringidos.
- **Almacenamiento**: Restaurar backup de prueba con snapshots CSI; validar replicación.
- **Monitoreo**: Confirmar recepción de métricas en Zabbix e InfluxDB; disparar alertas de umbral para CPU.
- **GitOps**: Sincronizar repositorio en Argo CD (`argocd app sync sample-app`).

## 4. Requisitos Operacionales Continuos

- **Backups**: Programar snapshots etcd (`etcdctl snapshot save`) y backups Vault (según backend) diarios.
- **Actualizaciones**: Seguir `kubectl drain` + PDB para mantenimiento; actualizar nodos por lotes (one-by-one).
- **Rotación de Credenciales**: Renovar certificados TLS y tokens cada 90 días; usar `cert-manager` para automatizar.
- **Auditoría**: Revisar dashboards Wazuh/ELK semanalmente; exportar reportes PCI/GDPR mensuales.
- **Capacidad**: Revisar métricas de Cluster Autoscaler e informes de costos; ajustar `requests/limits` en `values.yaml`.

## 5. Troubleshooting Común

| Problema | Diagnóstico | Resolución |
|----------|-------------|------------|
| Pods de CNI no levantan | `kubectl describe pod -n kube-system calico-node-*` | Verificar permisos del nodo, MTU de red y reemplazar certificados si caducaron. |
| Certificados TLS no se emiten | `kubectl describe challenge -n cert-manager` | Validar DNS/HTTP01, revisar logs de cert-manager y secrets `letsencrypt-prod`. |
| Vault Agent no inyecta secretos | `kubectl logs -n security vault-agent-injector-*` | Confirmar políticas de Vault y anotaciones en Deployment. |
| HPA no escala | `kubectl get hpa -A` y revisar métricas en InfluxDB | Ajustar `metrics-server`/Telegraf, calibrar umbrales en `manifests/cicd-autoscaling.yaml`. |
| Ingress sin acceso externo | `kubectl get svc -n ingress-nginx` | Validar asignación de LoadBalancer/IP y reglas de firewall/seguridad. |

## 6. Checklist de Go-Live

- [ ] Todos los nodos en estado `Ready` y sin taints imprevistos (`kubectl describe node`).
- [ ] Gatekeeper, Calico/Cilium, Ingress, Storage CSI, Zabbix, Wazuh, ELK, InfluxDB y Argo CD con pods `Ready`.
- [ ] Certificados TLS válidos para dominios principales.
- [ ] Backups iniciales completados (etcd, Vault, PostgreSQL de la app de referencia).
- [ ] Alertas críticas configuradas y probadas (Zabbix/InfluxDB/Wazuh).
- [ ] Pipelines GitOps sincronizados con repositorio de referencia.

> **Resultado esperado**: Clúster listo para cargas productivas con controles de seguridad, monitoreo y automatización alineados a estándares empresariales.
