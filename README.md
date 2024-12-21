# Intelligent Intern Core

Welcome to **Intelligent Intern Core**, your one-stop solution for a fully automated infrastructure setup designed for highly scalable Symfony applications paired with Python microservices. This project is pre-configured to provide seamless integration between various services, reducing setup complexity and improving developer productivity.


### Prerequisites

- `make` utility

## Installing Make on Ubuntu

To install Make on Ubuntu, run the following command:

```bash
sudo apt update && sudo apt install -y make
```

## Intelligent Intern Core's build script ensures the following tools are installed:

- Docker and Docker Compose
- Python (for microservices)
- mkcert for self signed certificates - the authority is automatically added to chrome so it trusts the certs

---

## Overview

![infra.png](documentation%2Finfra.png)

```mermaid
%%{init: {"theme": "dark", "themeVariables": {"primaryColor": "#ffcc00", "primaryTextColor": "#000000"}}}%%

flowchart TD
    subgraph "Build Process"
        X1[Run make prepare] --> X2[Execute build.sh Script]
        X2 --> X3[Start Infrastructure: Vault, Keycloak, Postgres, MinIO, etc.]
        X3 --> X4[Write Secrets into Vault]
        X4 --> X5[Build Docker Containers]
    end

    subgraph "Docker Container"
        A[Start Symfony Container] --> B[VAULT_URL, VAULT_ROLE_ID, VAULT_SECRET_ID as Env Variables]
    end

    B --> C[Vault Service in Symfony Kernel]
    C --> D[Authenticate with Vault: Role ID and Secret ID]
    D --> E[Vault returns Token]
    E --> F[Vault Service fetches all Secrets]
    F --> G[Secrets are set as Environment Variables]
    G --> H[Symfony Application is started]

    subgraph "Vault"
        D --> Z[Secrets stored in Vault: Keycloak, Postgres, MinIO, etc.]
        X4 --> Z
    end

    H --> I[Symfony fetches Keycloak Config from Vault]
    I --> J[Keycloak provides Client Credentials]
    J --> K[Symfony uses OpenID Connect for Authentication]
    K --> L[Access Tokens are generated]

    subgraph "Clients"
        N[Next.js Frontend] --> M[Keycloak Login - OIDC]
        M --> L
        O[Python Microservices] --> Q[Use iilib Library]
        Q --> P[iilib fetches Secrets and Keycloak Tokens from Vault]
        P --> L
    end

    X5 --> A

    style Z fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style A fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style H fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style L fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style X1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style X2 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style X3 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style X4 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style X5 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00

```


```mermaid
%%{init: {"theme": "dark", "themeVariables": {"primaryColor": "#ffcc00", "primaryTextColor": "#000000"}}}%%

flowchart TD
    subgraph "Build Process"
        X1[Run make prepare] --> X2[Execute build.sh Script]
        X2 --> X3[Start Infrastructure: Vault, Keycloak, Postgres, MinIO]
        X3 --> X4[Write secrets into Vault]
        X4 --> X5[Build Docker containers]
    end

    subgraph "Symfony Backend"
        A1[Symfony backend] --> A2[Manage users in Keycloak]
        A1 --> A3[Provide API Platform for microservices]
        A3 --> A4[Validate tokens via Keycloak]
    end

    subgraph "Keycloak"
        K1[Keycloak] --> K2[Issue tokens: Access and ID tokens]
        K1 --> K3[Manage user identities and roles]
    end

    subgraph "Next.js Frontend"
        F1[User login via Keycloak] --> F2[Receive access token]
        F2 --> F3[Call Symfony API Platform with token]
    end

    subgraph "Python Microservices"
        P1[Use iilib] --> P2[Fetch secrets via Vault]
        P1 --> P3[Call Symfony API with token]
        P3 --> A3
    end

    X5 --> A1
    F3 --> A3
    A3 --> K2
    P3 --> A3
    K2 --> A4

    style A1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style A3 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style K1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style F1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style P1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style X1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00

```



```mermaid

%%{init: {"theme": "dark", "themeVariables": {"primaryColor": "#ffcc00", "primaryTextColor": "#000000"}}}%%

flowchart TD
%% Keycloak Login
F1[Next.js Frontend] --> K1[Authenticate via Keycloak]
K1 --> F2[Receive Access Token]

    %% Datei-Upload
    F2 --> F3[Upload file to MinIO with x-amz-meta-token]
    F3 --> M1[MinIO]

    %% RabbitMQ Event
    M1 --> RMQ[RabbitMQ PUT Event]
    RMQ --> P1[Python Microservice]

    %% Token Validation
    P1 --> P2[Extract Access Token from Metadata]
    P2 --> P3[Validate Token with Keycloak]
    P3 --> P4[Process file - OCR, etc.]

    %% Send Data to Symfony
    P4 --> S1[Send extracted data to Symfony API]
    S1 --> S2[Symfony validates Token and maps data to User]

    %% Notify User with Mercure
    S2 --> M2[Notify User via Mercure]
    M2 --> F4[Next.js Frontend receives completion event]

    %% Styling Anpassung
    style F1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style F3 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style M1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style RMQ fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style P1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style S1 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style M2 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00
    style F4 fill:#000000,stroke:#ffcc00,stroke-width:2px,color:#ffcc00

```


## Features

- **Automation**: Easy setup, deployment, and teardown using Make commands.
- **Pre-configured Services**:
    - Mercure
    - Vault
    - RabbitMQ
    - MinIO
    - Redis
    - Mailcatcher
    - Neo4j
    - Postgres with TimetableDB and PostGIS 
    - KeyCloak
- **Symfony and Python Integration**:
    - Symfony: Includes API Platform, Vault Bootstrapping instead of .env stuff, Keycloak integration, Logging to Grafana and Minio Integration via FlySystem  
    - Python: A base library for service connectivity is provided.
- **Comprehensive Testing**:
    - Unit, integration, and system tests.

The services are managed through Docker Compose for efficient deployment.

### Accessing the Repository
To access the `intelligent-intern` repository, contact the sales team at [sales@intelligent-intern.com](mailto:sales@intelligent-intern.com) for approval and to receive your customer number.

### Building and Running the Services
1. To build and start the services:
   ```bash
   make prepare
   ```
   
2. For subsequent runs without rebuilding:
   ```bash
   make run
   ```

### Initializing the Database
The database initializes automatically, creating tables for storing document metadata and analysis results.