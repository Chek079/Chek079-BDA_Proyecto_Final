import asyncio
import aiohttp
from bleak import BleakScanner

FLASK_URL = "http://34.9.241.20:5000/beacon/datos"
INTERVALO = 5  # segundos entre escaneos

async def escanear_y_enviar():
    print("Escáner BLE iniciado. Buscando dispositivos...")
    while True:
        try:
            dispositivos = await BleakScanner.discover(timeout=3.0)
            datos = []
            for d in dispositivos:
                datos.append({
                    'nombre':   d.name or 'Desconocido',
                    'mac':      d.address,
                    'rssi':     d.rssi,
                    'distancia': round(10 ** ((-69 - d.rssi) / (10 * 2)), 2)
                })

            print(f"Encontrados {len(datos)} dispositivos BLE")

            async with aiohttp.ClientSession() as session:
                await session.post(FLASK_URL, json={
                    'total':       len(datos),
                    'dispositivos': datos
                })

        except Exception as e:
            print(f"Error: {e}")

        await asyncio.sleep(INTERVALO)

if __name__ == '__main__':
    asyncio.run(escanear_y_enviar())
