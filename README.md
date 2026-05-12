# Proyecto Final Bases de Datos Avanzadas

*Objetivo*: Este proyecto busca desarrollar un sistema integral de base de datos y aplicación web que optimice la gestión clínica y operativa de un centro de rehabilitación física, integrando un ecosistema IoT escalonado (GPS, Beacons BLE y NFC) para el seguimiento de pacientes, y facilitando la toma de decisiones médicas mediante visualización dinámica de datos y métricas de efectividad terapéutica.

El proyecto está desarrollado utilizando Python 3 en conjunto con el framework Flask para implementar el backend de la aplicación, buscando mantener una arquitectura ligera, modular y fácil de mantener. Flask fue seleccionado debido a su flexibilidad para construir aplicaciones web basadas en rutas, manejo de sesiones, autenticación y comunicación con bases de datos, permitiendo integrar de forma eficiente los distintos módulos del sistema de rehabilitación física. A través de esta arquitectura se gestionan operaciones relacionadas con pacientes, terapeutas, sesiones, evaluaciones clínicas, dispositivos IoT y generación de reportes administrativos.

El backend también integra conexión con PostgreSQL como sistema gestor de base de datos principal, utilizando consultas SQL, vistas, triggers y procedimientos de validación para garantizar integridad y automatización de procesos clínicos. Adicionalmente, se incorporó MongoDB como capa analítica para almacenamiento de datasets orientados a dashboards y gráficas dinámicas, desacoplando la visualización estadística de las operaciones transaccionales. La aplicación expone múltiples endpoints REST mediante Flask para comunicación con el frontend, permitiendo consumir información en formato JSON desde componentes JavaScript y librerías de visualización como Highcharts.

La base de datos elegida para este proyecto es PostgreSQL debido a su robustez, soporte para integridad relacional, manejo avanzado de consultas SQL, compatibilidad con triggers, views y capacidad para administrar múltiples relaciones complejas entre entidades clínicas, administrativas y dispositivos IoT. PostgreSQL permite mantener consistencia en la información del sistema de rehabilitación física, además de facilitar la generación de reportes, métricas y operaciones transaccionales críticas utilizadas por el backend desarrollado en Python y Flask.

## Pasos para su instalación
### Requisitos:
- Python 3.10 o superior
- PostgreSQL 14 o superior
- MongoDB Community Edition
- pip

Primero se debe instalar Python3 para poder correr este proyecto, es recomendable que para instalar las liberias de pip se cree lo que es un ambiente virtual. Esto se reallizá con el siguiente codigo. 

```python3
python -m venv venv
```

Dependiendo de donde se corre la aplicación es necesario activar el ambiente. Para activarlo en Linux o Mac simplementa se corre el siguiente script

```bash
source venv/bin/activate
```

En cambio en Window se tiene que ejecutar el siguiente codigo

```bash
venv\\Scripts\\activate
```

Una ves activado esto se pueden instalar las dependencias usando un archivo txt

```bash
pip install -r requirements.txt
```

Con esto simplemente falta hacer es crear la base de datos


```postgresql
CREATE DATABASE rehabilitacion_fisica;
```

Ejecutar el script del esquema SQL:

- tablas
- constraints
- triggers
- views
- índices


Ejecutar el archivo para poner el esquema de la base de datos y luego se ingresan los datos.
```postgresql
psql -U postgres -d rehabilitacion_fisica -f dml.sql
```

Dentro de la base de datos se tiene que poner las credenciales de como se haga dependiendo de la instalacion de cada quien
DB_HOST=
DB_PORT=
DB_NAME=
DB_USER=
DB_PASSWORD=

Y finalmente se corre el programa con el script de `./run.sh` con esto se ingresa a la liga local de `http://127.0.0.1:5000`
