# Serverless Calculator Batch Processing

Este repositorio contiene la Infraestructura como Código (IaC) para desplegar un pipeline de procesamiento en batch Serverless en AWS, orientado a registrar transacciones de una calculadora. El proyecto utiliza **Terraform**, **Terragrunt**, y **GitHub Actions**.

## Arquitectura

La solución implementa una arquitectura orientada a eventos con los siguientes componentes:

1. **Amazon S3**: Actúa como punto de entrada. Recibe archivos CSV con las transacciones. Tiene versionamiento y protección BPA.
2. **AWS Lambda (Procesador)**: Se activa automáticamente cuando un nuevo archivo CSV se deposita en S3. Extrae la información y la escribe en DynamoDB.
3. **Amazon DynamoDB**: Tabla NoSQL escalable para almacenar todas las transacciones históricas procesadas. En el ambiente de producción, la tabla cuenta con protección contra borrado accidental.
4. **Amazon API Gateway (REST API)**: Expone endpoints protegidos mediante una API Key.
5. **AWS Lambda (Query)**: Procesador del endpoint de API Gateway que consulta la base de datos de DynamoDB para extraer métricas, como el total global de transacciones procesadas o el historial filtrado de un usuario en específico.

![Diagrama Arquitectura](https://d1.awsstatic.com/serverless/Lambda%20Resources%20images/Serverless_Architecture_Diagram.b21ba1070e28f117ce678b8f2b2eecde82fb32fb.png) *(Imagen referencial)*

## Estructura de Directorios

Se utiliza la estrategia DRY de Terragrunt para separar la declaración del recurso (módulo) de la parametrización de sus despliegues.

```
├── .github/
│   └── workflows/
│       └── deploy.yml      # CI/CD Pipeline para despliegues controlados
├── environments/           # Archivos de Terragrunt
│   ├── dev/
│   ├── qa/
│   └── prod/
├── modules/
│   └── calculator-batch/   # Wrappers de los módulos oficiales y configuración Terraform
├── references/             # Documentación, instrucciones y data de ejemplo
└── src/                    # Código fuente Python de las funciones Lambda
```

## Primeros Pasos

Para instrucciones detalladas sobre cómo configurar tu ambiente local, agregar secretos a GitHub (como tu API Key) y desplegar el proyecto manualmente en modo desarrollo, consulta el documento de referencias:

👉 [Ver Instrucciones de Setup (setup_instructions.md)](references/setup_instructions.md)

## Flujo de Desarrollo

Cualquier adición de recursos (nuevos buckets, tablas o APIs) debe declararse en el módulo `modules/calculator-batch` de manera completamente genérica (sin "quemar" IDs ni nombres). Los nombres finales serán inferidos inyectando los valores de `pipeline.tfvars` durante la inicialización en CI/CD con GitHub Actions.
