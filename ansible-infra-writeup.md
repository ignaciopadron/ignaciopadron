# Project Deep Dive: Fully Automated VPS Infrastructure with Ansible

![Ansible & Docker IaC](https://img.shields.io/badge/IaC%20Orchestration-Ansible%20%7C%20Docker%20%7C%20Jinja2-success?style=for-the-badge&logo=docker)

Hola de nuevo. Si has llegado hasta aquí es porque quieres saber más sobre cómo he construido la infraestructura que soporta mis proyectos personales. ¡Vamos al lío!

## 1. El Problema: El Monolito de Infra-App

En versiones anteriores de mis proyectos, caí en una práctica muy común: mezclar la definición de la infraestructura con el código de la aplicación en el mismo repositorio. Esto presentaba varios problemas:

-   **Alto Acoplamiento:** Cualquier cambio en la configuración del servidor requería un despliegue de la aplicación.
-   **Riesgos de Seguridad:** El código de la infraestructura tenía más exposición de la necesaria.
-   **Mala Escalabilidad:** Era difícil reutilizar la configuración para nuevos proyectos.

El objetivo estaba claro: **desacoplar la infraestructura de las aplicaciones**, adoptando un enfoque de Infraestructura como Código (IaC) puro.

## 2. La Solución: Un Repositorio Dedicado para Ansible (repositorio privado por seguridad)

La solución fue crear el repositorio `ansible-infra`, cuya única responsabilidad es definir y mantener el estado deseado de mi servidor VPS.

### Arquitectura de Alto Nivel

La arquitectura se basa en la modularidad y la comunicación a través de una red segura.
```
+------------------+      +-------------------------+      +---------------------------+
| Repositorio de   |----->| GitHub Actions (CI/CD)  |----->|                           |
| Aplicación (Web) |      | (Solo copia el código)  |      | /srv/portfolio/website    |
+------------------+      +-------------------------+      |                           |
                                                             |       SERVIDOR VPS        |
+------------------+      +-------------------------+      |                           |
| ansible-infra    |----->|   Ansible (Local)       |----->|  Docker & Docker Compose  |
| (Este proyecto)  |      | (Provisiona y configura)|      |   (Gestionado por Ansible)|
+------------------+      +-------------------------+      +---------------------------+
                                                             |
                                                             |  [proxy_network] (Red Docker)
                                                             |      ^
                                                             |      |
        +--------------------------+  <--- Tráfico ---->  +-------------------------+
        | Nginx Proxy Manager      |                      | Contenedor App (Portfolio)|
        | (Gestiona SSL y dominios)|                      | Contenedor App (Radar)    |
        +--------------------------+                      +-------------------------+


### La Estrategia con Ansible

El corazón del proyecto es cómo está estructurado Ansible. En lugar de un único `playbook.yml` gigante, he optado por una estructura modular y orquestada.

**1. Estructura de Directorios:**
```
/
├── main.yml                 # Playbook principal que llama a los demás
├── playbooks/               # Playbooks con responsabilidades únicas
│   ├── 01_setup_server.yml  # Securización base (UFW, Fail2Ban)
│   ├── 02_setup_docker.yml  # Instalación de Docker y Docker Compose
│   ├── 03_setup_network.yml # Creación de la red Docker compartida
│   └── 04_deploy_services.yml # Despliegue de servicios
│
├── templates/               # Plantillas Jinja2 para docker-compose.yml
│   ├── ...
│
└── vars/
    └── secrets.yml          # ¡Encriptado! Contiene IPs, usuarios, etc.

**2. Orquestación con `main.yml`:**

Este es el único fichero que ejecuto. Actúa como un director de orquesta, llamando a los demás playbooks en el orden correcto. Esto hace que el proceso sea predecible y fácil de depurar.

```yaml
# main.yml
---
- import_playbook: playbooks/01_setup_server.yml
- import_playbook: playbooks/02_setup_docker.yml
- import_playbook: playbooks/03_setup_network.yml
- import_playbook: playbooks/04_deploy_services.yml
```

**3. Idempotencia y Plantillas:**

Cada playbook está escrito para ser **idempotente**. Puedo ejecutar `ansible-playbook` cien veces y solo se aplicarán los cambios necesarios para alcanzar el estado definido, nunca se duplicarán tareas.

Los ficheros `docker-compose.yml` se generan a partir de plantillas Jinja2. Esto me permite estandarizar la configuración (como asegurarse de que todos los servicios se conectan a la red `proxy_network`) y gestionar variables fácilmente.

**4. La Seguridad es lo Primero: Ansible Vault**

Toda la información sensible (IPs del servidor, nombres de usuario, tokens, etc.) se almacena en `vars/secrets.yml`. Este fichero **nunca se sube en texto plano a Git**. Está encriptado usando **Ansible Vault**.

Para editarlo, uso `ansible-vault edit ...` y para ejecutar el playbook, añado la bandera `--ask-vault-pass`. De esta forma, combino la potencia de la automatización con la seguridad de no exponer credenciales.

## 3. Conclusión: Beneficios Obtenidos

Este enfoque me ha proporcionado un sistema:

-   ✅ **Predecible y Reproducible:** Puedo destruir el VPS y levantarlo de nuevo en minutos con un solo comando.
-   ✅ **Seguro:** Los secretos están a salvo y la configuración de seguridad es la primera en aplicarse.
-   ✅ **Mantenible y Escalable:** Añadir un nuevo servicio o aplicación es tan simple como crear una nueva plantilla y añadirla al playbook de despliegue.
-   ✅ **Fomenta un CI/CD Limpio:** Mis repositorios de aplicaciones ahora solo se preocupan de su código. El pipeline de CI/CD es mucho más simple: testea el código y lo copia al directorio correspondiente en el servidor. La infraestructura ya está lista para servirlo.

---
Gracias por leer este desglose. Si tienes alguna pregunta, no dudes en contactarme.
