# Kubernetes_Infra

Repositorio con manifests YAML y Helm charts para desplegar una plataforma Kubernetes empresarial con alta disponibilidad, seguridad reforzada y capacidades de observabilidad avanzadas.

## Documentación
- [Resumen Ejecutivo](docs/executive-summary.md)
- [Documentación Técnica Detallada](docs/technical-documentation.md)
- [Guía de Despliegue](docs/deployment-guide.md)

## Componentes Destacados
- Manifests para inicialización del clúster, seguridad, networking, almacenamiento, monitoreo y automatización en `manifests/`.
- Chart de ejemplo `helm/microservice` que despliega un microservicio web con PostgreSQL, HPA, PDB e Ingress TLS.
- Archivo `requerimets.txt` con dependencias de automatización y herramientas operativas.

## Uso Rápido
1. Revisar requisitos y pasos en la [Guía de Despliegue](docs/deployment-guide.md).
2. Aplicar manifests en el orden descrito usando `kubectl apply -f`.
3. Instalar el chart de ejemplo con `helm upgrade --install sample-app helm/microservice -n prod --create-namespace`.

## Soporte y Contribuciones
Para mejoras o issues, crear un pull request o registrar un issue con detalles del entorno y logs relevantes.
