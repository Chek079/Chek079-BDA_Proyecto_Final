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

Y finalmente se corre el programa con el script de `./run.sh` con esto se ingresa a la liga local de `http://127.0.0.1:5000



USUARIOS:

admin01 | 1234
laura.mendoza | 1234
andres.fuentes | 1234
fam_pac1 | 1234



laura mendoza y andres fuentes son los terapuetas registrados






Para correr la app estamos usando una herramienta llamada ngrok, la cual se requiere instalar en nuestra instancia mediante:

wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xf ngrok-v3-stable-linux-amd64.tgz


esto se hace para instalar los requerimientos para ngrok, se tiene que crear una cuenta de ngrok, una vez creada, ir al apartado de you auth token, copiarlo y poner el sigueiente comando en la vm dentro del directorio del proyecto

./ngrok config add-authtoken TU_TOKEN_AQUI


ya dentro del directorio hechamos a volar la pagina mediante
./run.sh

en otra terminal colocamos ./ngrok http 5000
para actiar ngrok.

Copiamos el link que aparece al activar ngrok que viene como: https://hermit-voter-effects.ngrok-free.dev


pegamos ese link en el navegador y ya entrariamos en la app

para activar el NFC, en nuestro celular android colocamos este link https://hermit-voter-effects.ngrok-free.dev/nfc

para entrar en el modo escaneo del celular, 

despues agendamos una sesion, es importante recalcar que el paciente tiene que ser Carlos ya que es el que tiene asignado el NFC que se va a usar, se le da a escanar, acercamos el nfc y el estado de Pendiente pasara a estar presente.






Para el Beacon se tiene que hacer un script de python llamado BeaconScanner.py y colocarlo en nuestra terminal en local para habilitar el bluethooth, el script es el siguiente:

~~~python
import asyncio
import aiohttp
from bleak import BleakScanner

FLASK_URL = "https://hermit-voter-effects.ngrok-free.dev/beacon/datos"
INTERVALO = 5  # segundos entre escaneos

async def escanear_y_enviar():
    print("Escáner BLE iniciado. Buscando dispositivos...")
    while True:
        try:
            dispositivos = await BleakScanner.discover(timeout=3.0, return_adv=True)
            datos = []

            for direccion, (device, adv_data) in dispositivos.items():
                rssi = adv_data.rssi if adv_data.rssi is not None else -100
                distancia = round(10 ** ((-69 - rssi) / (10 * 2)), 2)
                datos.append({
                    'nombre':    device.name or 'Desconocido',
                    'mac':       device.address,
                    'rssi':      rssi,
                    'distancia': distancia
                })

            print(f"Encontrados {len(datos)} dispositivos BLE")

            async with aiohttp.ClientSession() as session:
                await session.post(FLASK_URL, json={
                    'total':        len(datos),
                    'dispositivos': datos
                })

        except Exception as e:
            print(f"Error: {e}")

        await asyncio.sleep(INTERVALO)

if __name__ == '__main__':
    asyncio.run(escanear_y_enviar())
~~~





se pega en vs code y se guarda en local, despues se enciende el beacon y corremos el script con: python BeaconScanner.py


una vez corriendo se detectarian los dispositivos alrededor en la zona en un rango determinado de metros.






Para el GPS


se tiene que instalar una aplicacion llamada traccar client, es una app para gps con un icono verde y blanco
dentro de la app, el url del servidor, se coloca lo siguiente: https://hermit-voter-effects.ngrok-free.dev/gps

se tiene que estar conectado a la misma red de internet, 

una vez puesto el link se le da a enviar ubicacion y en la vista de terapeuta, en terapias a domicilio aparece un iframe de google maps donde se actualizara la ubicacion,

para confirmar que esta jalando, nos vamos al apartado donde esta corriendo ngrok y vemos si se envia un POST hacia /gps, si se envia eso es que si esta mandando correctamente la ubicacion







para mas facilidad, dejo una cuenta de google cloud donde esta todo configurado, nadamas es de hechar a volar al pagina

sergio.ayalag@udem.edu | Udem2024!!
