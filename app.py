from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
import psycopg2
import psycopg2.extras
from functools import wraps
 
app = Flask(__name__)
app.secret_key = '1234'



# Variable global para guardar última ubicación GPS
ultima_ubicacion = {'lat': None, 'lon': None, 'device': None}




@app.route('/', methods=['GET', 'POST'])
def gps_osmand():
    global ultima_ubicacion

    json_data = request.get_json(silent=True)
    if json_data:
        coords    = json_data.get('location', {}).get('coords', {})
        lat       = coords.get('latitude')
        lon       = coords.get('longitude')
        device_id = json_data.get('device_id', '')
        speed     = coords.get('speed', 0)

        print(f"GPS: lat={lat}, lon={lon}, device={device_id}")

        if lat and lon:
            ultima_ubicacion = {'lat': lat, 'lon': lon, 'device': device_id}
            try:
                query(
                    """INSERT INTO gps_registros
                       (id_paciente, id_terapeuta, latitud, longitud, fecha, hora, id_estado)
                       VALUES (1, 1, %s, %s, CURRENT_DATE, CURRENT_TIME, 1)""",
                    (lat, lon), commit=True
                )
            except Exception as e:
                print("Error GPS:", e)

    return 'OK', 200


@app.route('/gps/recibir', methods=['GET', 'POST'])
def gps_recibir():
    global ultima_ubicacion
    print("GPS recibido:", request.args)
    lat    = request.args.get('lat', type=float)
    lon    = request.args.get('lon', type=float)
    device = request.args.get('id', '')
    if lat and lon:
        ultima_ubicacion = {'lat': lat, 'lon': lon, 'device': device}
        try:
            query(
                """INSERT INTO gps_registros
                   (id_paciente, id_terapeuta, latitud, longitud, fecha, hora, id_estado)
                   VALUES (1, 1, %s, %s, CURRENT_DATE, CURRENT_TIME, 1)""",
                (lat, lon), commit=True
            )
        except Exception as e:
            print("Error GPS:", e)
    return 'OK', 200


@app.route('/gps/ultima')
def gps_ultima():
    return jsonify(ultima_ubicacion)






# Variable global para guardar datos del beacon en memoria
beacon_data = {'total': 0, 'dispositivos': []}

@app.route('/beacon/datos', methods=['POST'])
def beacon_datos():
    global beacon_data
    beacon_data = request.get_json()
    return jsonify({'ok': True})

@app.route('/beacon/estado')
def beacon_estado():
    return jsonify(beacon_data)


# === METODOS DE LOGIN / LOGOUT ========================
def get_css():
    rol = session.get('rol')

    if rol == 'admin':
        return 'css/admin_base.css'
    elif rol == 'terapeuta':
        return 'css/clinica_base.css'
    elif rol == 'familiar':
        return 'css/publica_base.css'
    return 'css/admin_base.css'
# ─── CONFIGURACIÓN DE BD ───────────────────────────────────────────────────────
DB_CONFIG = {
    'host':     '127.0.0.1',
    'database': 'rehabilitacion_fisica',
    'user':     'postgres',
    'password': '666999',
    'port':     5432
}
 
def get_db():
    return psycopg2.connect(**DB_CONFIG)
 
def query(sql, params=None, fetchone=False, fetchall=False, commit=False):
    conn = get_db()
    cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    try:
        cur.execute(sql, params)
        if commit:
            conn.commit()
        if fetchone:
            return cur.fetchone()
        if fetchall:
            return cur.fetchall()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cur.close()
        conn.close()




def call_procedure_out(sql, params=None):
    """Ejecuta un CALL con params OUT y devuelve los resultados como dict."""
    conn = get_db()
    cur  = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    try:
        cur.execute(sql, params)
        conn.commit()
        return cur.fetchone()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cur.close()
        conn.close()
 
# ─── DECORADORES ──────────────────────────────────────────────────────────────
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'logeado' not in session:
            return redirect(url_for('principal'))
        return f(*args, **kwargs)
    return decorated
 
def role_required(*roles):
    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if session.get('rol') not in roles:
                flash('No tienes permisos para esta sección.')
                return redirect(url_for('principal'))
            return f(*args, **kwargs)
        return decorated
    return decorator
 
# ─── RUTAS PRINCIPALES ────────────────────────────────────────────────────────
@app.route('/')
def principal():
    if 'logeado' in session:
        rol = session.get('rol')
        if rol == 'admin':
            return redirect(url_for('admin_dashboard'))
        elif rol == 'terapeuta':
            return redirect(url_for('clinica_dashboard'))
        elif rol == 'familiar':
            return redirect(url_for('publica_dashboard'))
    return render_template('login.html')
 

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        usuario_id   = request.form.get('id', '').strip()
        usuario_pass = request.form.get('password', '').strip()

        try:
            row = call_procedure_out(
                "CALL sp_login(%s, %s, NULL, NULL, NULL, NULL, NULL)",
                (usuario_id, usuario_pass)
            )
            print("Resultado login:", row)
        except Exception as e:
            print("Error:", e)
            row = None

        if row and row['o_autenticado']:
            session['logeado'] = True
            session['id']      = row['o_user_id']
            session['rol']     = row['o_rol']
            session['nombre']  = row['o_nombre']
            session['ref_id']  = row['o_ref_id']
            rol = row['o_rol']
            if rol == 'admin':
                return redirect(url_for('admin_dashboard'))
            elif rol == 'terapeuta':
                return redirect(url_for('clinica_dashboard'))
            elif rol == 'familiar':
                return redirect(url_for('publica_dashboard'))
        else:
            error = "ID o Contraseña incorrectos. Intenta de nuevo."

    return render_template('login.html', error=error)


 
@app.route('/logout')
def logout():
    session.clear()
    session.modified = True
    return redirect(url_for('login'))




# ═══════════════════════════════════════════════════════════════════════════════
# ADMIN
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/admin/dashboard')
@login_required
@role_required('admin')
def admin_dashboard():
    try:
        kpis = query("SELECT * FROM vw_dashboard_admin", fetchone=True)
        nfc_recientes = query(
            """SELECT a.fecha, a.hora_entrada,
                      p.nombre || ' ' || p.apellido_paterno AS paciente,
                      d.ubicacion AS zona
               FROM   asistencias_nfc a
               JOIN   pacientes p ON p.id_paciente = a.id_paciente
               JOIN   dispositivos_nfc d ON d.id_dispositivo = a.id_dispositivo
               ORDER  BY a.fecha DESC, a.hora_entrada DESC
               LIMIT  10""",
            fetchall=True
        )
    except Exception:
        kpis, nfc_recientes = None, []

    return render_template('admin_dashboard.html',
                           total_pacientes_hoy=kpis['total_pacientes_hoy'] if kpis else 0,
                           rutas_activas=kpis['rutas_activas'] if kpis else 0,
                           alertas_iot=kpis['alertas_iot'] if kpis else 0,
                           nfc_recientes=nfc_recientes or [])

@app.route('/admin/paciente')
@login_required
@role_required('admin')
def admin_obtenerPacientes():
    try:
        pacientes = query("SELECT * FROM vw_pacientes_completo ORDER BY id_paciente", fetchall=True)
    except Exception:
        pacientes = []
    return render_template('admin_pacientes.html', pacientes=pacientes or [])

@app.route('/admin/pacientes/registrar', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def admin_registrarPacientes():
    if request.method == 'POST':
        f = request.form
        try:
            query(
                "CALL sp_insertar_paciente(%s,%s,%s,%s::DATE,%s::INTEGER,%s,%s,%s,%s,%s)",
                (f['nombre'], f['apellido_paterno'], f['apellido_materno'],
                 f['fecha_nacimiento'], int(f['sexo']),
                 f.get('telefono'), f.get('correo'), f.get('direccion'),
                 f['diagnostico'], f.get('antecedentes')),
                commit=True
            )
            flash('Paciente registrado exitosamente.', 'success')
            return redirect(url_for('admin_obtenerPacientes'))
        except Exception as e:
            flash(f'Error al registrar paciente: {e}', 'error')
    return render_template('admin_registrarPaciente.html')

@app.route('/admin/paciente/eliminar/<int:id_paciente>', methods=['POST'])
@login_required
@role_required('admin')
def admin_eliminar_paciente(id_paciente):
    try:
        query("CALL sp_eliminar_paciente(%s)", (id_paciente,), commit=True)
        flash('Paciente eliminado.', 'success')
    except Exception as e:
        flash(f'No se puede eliminar: {e}', 'error')
    return redirect(url_for('admin_obtenerPacientes'))

@app.route('/admin/terapeutas')
@login_required
@role_required('admin')
def admin_obtenerTerapeutas():
    try:
        terapeutas = query("SELECT * FROM vw_terapeutas_completo ORDER BY id_terapeuta", fetchall=True)
    except Exception:
        terapeutas = []
    return render_template('admin_terapeutas.html', terapeutas=terapeutas or [])

@app.route('/admin/terapeutas/registrar', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def admin_registrarTerapeutas():
    if request.method == 'POST':
        f = request.form
        try:
            query(
                "CALL sp_insertar_terapeuta(%s,%s,%s,%s::INTEGER,%s,%s,%s)",
                (f['nombre'], f['apellido_paterno'], f['apellido_materno'],
                 int(f['especialidad']), f.get('telefono'),
                 f.get('correo'), f.get('observaciones')),
                commit=True
            )
            flash('Terapeuta registrado.', 'success')
            return redirect(url_for('admin_obtenerTerapeutas'))
        except Exception as e:
            flash(f'Error: {e}', 'error')
    try:
        especialidades = query("SELECT * FROM cat_especialidades WHERE activo = TRUE", fetchall=True)
    except Exception:
        especialidades = []
    return render_template('admin_registrarTerapeuta.html', especialidades=especialidades or [])

@app.route('/admin/terapeuta/eliminar/<int:id_terapeuta>', methods=['POST'])
@login_required
@role_required('admin')
def admin_eliminar_terapeuta(id_terapeuta):
    try:
        query("CALL sp_eliminar_terapeuta(%s)", (id_terapeuta,), commit=True)
        flash('Terapeuta eliminado.', 'success')
    except Exception as e:
        flash(f'No se puede eliminar: {e}', 'error')
    return redirect(url_for('admin_obtenerTerapeutas'))

@app.route('/admin/sesiones')
@login_required
@role_required('admin')
def admin_obtenerSesiones():
    try:
        sesiones = query("SELECT * FROM vw_sesiones_detalle ORDER BY fecha DESC, hora_inicio", fetchall=True)
    except Exception:
        sesiones = []
    return render_template('admin_sesiones.html', sesiones=sesiones or [])

@app.route('/admin/sesiones/registrar', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def admin_registrarSesion():
    if request.method == 'POST':
        f = request.form
        print("Datos recibidos:", dict(f))
        try:
            query(
                "CALL sp_registrar_sesion(%s::INTEGER,%s::INTEGER,%s::DATE,%s::TIME,%s::TIME,%s::INTEGER,%s::BOOLEAN,%s::INTEGER,%s)",
                (int(f['id_paciente']), int(f['id_terapeuta']),
                 f['fecha'], f['hora_inicio'], f['hora_fin'],
                 int(f['modalidad']), False,
                 int(f['metodo_registro']), f.get('observaciones')),
                commit=True
            )
            flash('Sesión registrada.', 'success')
            return redirect(url_for('admin_obtenerSesiones'))
        except Exception as e:
            print("ERROR:", e)
            flash(f'Error: {e}', 'error')
    try:
        pacientes  = query("SELECT id_paciente, nombre || ' ' || apellido_paterno AS nombre_completo FROM pacientes ORDER BY nombre", fetchall=True)
        terapeutas = query("SELECT id_terapeuta, nombre || ' ' || apellido_paterno AS nombre_completo FROM terapeutas ORDER BY nombre", fetchall=True)
        tipos      = query("SELECT * FROM cat_tipos_sesion WHERE activo = TRUE", fetchall=True)
        metodos    = query("SELECT * FROM cat_metodos_registro WHERE activo = TRUE", fetchall=True)
    except Exception:
        pacientes = terapeutas = tipos = metodos = []
    return render_template('admin_registrarSesion.html',
                           pacientes=pacientes or [], terapeutas=terapeutas or [],
                           tipos=tipos or [], metodos=metodos or [])

@app.route('/admin/sesion/eliminar/<int:id_sesion>', methods=['POST'])
@login_required
@role_required('admin')
def admin_eliminar_sesion(id_sesion):
    try:
        query("CALL sp_eliminar_sesion(%s)", (id_sesion,), commit=True)
        flash('Sesión eliminada.', 'success')
    except Exception as e:
        print("ERROR eliminar sesion:", e)
        flash(f'No se puede eliminar: {e}', 'error')
    return redirect(url_for('admin_obtenerSesiones'))

@app.route('/admin/beacons')
@login_required
@role_required('admin')
def admin_obtenerBeacons():
    try:
        beacons = query(
            """SELECT b.id_beacon, b.area, b.habitacion, e.nombre AS estado_nombre,
                      COUNT(be.id_evento) AS total_eventos
               FROM   beacons b
               JOIN   cat_estados_beacon e ON e.id_estado = b.id_estado
               LEFT JOIN beacon_evento be ON be.id_beacon = b.id_beacon
               GROUP  BY b.id_beacon, b.area, b.habitacion, e.nombre
               ORDER  BY b.area, b.habitacion""",
            fetchall=True
        )
    except Exception:
        beacons = []
    return render_template('admin_beacons.html', beacons=beacons or [])

@app.route('/admin/reportes')
@login_required
@role_required('admin')
def admin_reportes():
    try:
        resumen = query("SELECT * FROM vw_reporte_asistencia", fetchall=True)
    except Exception:
        resumen = []
    return render_template('admin_reportes.html', resumen=resumen or [])



@app.route('/paciente/editar/<int:id_paciente>', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def admin_editar_paciente(id_paciente):
    if request.method == 'POST':
        f = request.form
        try:
            query(
                "CALL sp_actualizar_paciente(%s,%s,%s,%s,%s::DATE,%s::INTEGER,%s,%s,%s,%s,%s)",
                (id_paciente,
                 f['nombre'], f['apellido_paterno'], f['apellido_materno'],
                 f['fecha_nacimiento'], int(f['sexo']),
                 f.get('telefono'), f.get('correo'), f.get('direccion'),
                 f['diagnostico'], f.get('antecedentes')),
                commit=True
            )
            flash('Paciente actualizado.', 'success')
            return redirect(url_for('admin_obtenerPacientes'))
        except Exception as e:
            flash(f'Error: {e}', 'error')

    try:
        paciente = query(
            "SELECT * FROM vw_pacientes_completo WHERE id_paciente = %s",
            (id_paciente,), fetchone=True
        )
        sexos = query("SELECT * FROM cat_sexo WHERE activo = TRUE", fetchall=True)
    except Exception:
        paciente, sexos = None, []

    return render_template('admin_registrarPaciente.html', 
                           paciente=paciente, sexos=sexos or [])




@app.route('/terapeuta/editar/<int:id_terapeuta>', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def admin_editar_terapeuta(id_terapeuta):
    if request.method == 'POST':
        f = request.form
        try:
            query(
                "CALL sp_actualizar_terapeuta(%s,%s,%s,%s,%s::INTEGER,%s,%s,%s)",
                (id_terapeuta,
                 f['nombre'], f['apellido_paterno'], f['apellido_materno'],
                 int(f['especialidad']), f.get('telefono'),
                 f.get('correo'), f.get('observaciones')),
                commit=True
            )
            flash('Terapeuta actualizado.', 'success')
            return redirect(url_for('admin_obtenerTerapeutas'))
        except Exception as e:
            flash(f'Error: {e}', 'error')

    try:
        terapeuta = query(
            "SELECT * FROM vw_terapeutas_completo WHERE id_terapeuta = %s",
            (id_terapeuta,), fetchone=True
        )
        especialidades = query(
            "SELECT * FROM cat_especialidades WHERE activo = TRUE", fetchall=True
        )
    except Exception:
        terapeuta, especialidades = None, []

    return render_template('admin_registrarTerapeuta.html',
                           terapeuta=terapeuta, especialidades=especialidades or [])




@app.route('/sesion/editar/<int:id_sesion>', methods=['GET', 'POST'])
@login_required
@role_required('admin')
def admin_editar_sesion(id_sesion):
    if request.method == 'POST':
        f = request.form
        try:
            query(
                "CALL sp_actualizar_sesion(%s,%s::DATE,%s::TIME,%s::TIME,%s::INTEGER,%s::BOOLEAN,%s::INTEGER,%s)",
                (id_sesion,
                 f['fecha'], f['hora_inicio'], f['hora_fin'],
                 int(f['modalidad']), f.get('asistencia') == '1',
                 int(f['metodo_registro']), f.get('observaciones')),
                commit=True
            )
            flash('Sesión actualizada.', 'success')
            return redirect(url_for('admin_obtenerSesiones'))
        except Exception as e:
            flash(f'Error: {e}', 'error')

    try:
        sesion = query(
            "SELECT * FROM vw_sesiones_detalle WHERE id_sesion = %s",
            (id_sesion,), fetchone=True
        )
        tipos   = query("SELECT * FROM cat_tipos_sesion WHERE activo = TRUE", fetchall=True)
        metodos = query("SELECT * FROM cat_metodos_registro WHERE activo = TRUE", fetchall=True)
    except Exception:
        sesion, tipos, metodos = None, [], []

    return render_template('admin_registrarSesion.html',
                           sesion=sesion,
                           tipos=tipos or [],
                           metodos=metodos or [])






# ═══════════════════════════════════════════════════════════════════════════════
# CLÍNICA (TERAPEUTA)
# ═══════════════════════════════════════════════════════════════════════════════


@app.route('/clinica/dashboard')
@login_required
@role_required('terapeuta')
def clinica_dashboard():
    id_terapeuta = session.get('ref_id')
    try:
        citas_hoy = query(
            "SELECT * FROM vw_agenda_terapeuta WHERE id_terapeuta = %s ORDER BY hora_inicio",
            (id_terapeuta,), fetchall=True
        )
        kpis = call_procedure_out(
            "CALL sp_kpis_terapeuta(%s, CURRENT_DATE, NULL, NULL, NULL, NULL, NULL)",
            (id_terapeuta,)
        )
    except Exception:
        citas_hoy, kpis = [], None
 
    return render_template('clinica_dashboard.html',
                           terapeuta_nombre=session.get('nombre', ''),
                           citas_hoy=citas_hoy or [],
                           total_citas=kpis['o_total_citas'] if kpis else 0,
                           pacientes_espera=kpis['o_en_espera'] if kpis else 0,
                           atendidos_hoy=kpis['o_atendidos'] if kpis else 0)

@app.route('/clinica/pacientes')
@login_required
@role_required('terapeuta')
def clinica_obtenerPacientes():
    id_terapeuta = session.get('ref_id')
    try:
        mis_pacientes = query(
            "SELECT * FROM vw_mis_pacientes WHERE id_terapeuta = %s ORDER BY nombre",
            (id_terapeuta,), fetchall=True
        )
    except Exception:
        mis_pacientes = []
    return render_template('clinica_pacientes.html', mis_pacientes=mis_pacientes or [])


@app.route('/clinica/sesiones')
@login_required
@role_required('terapeuta')
def clinica_obtenerSesiones():
    id_terapeuta = session.get('ref_id')
    from datetime import date
    fecha_filtro = request.args.get('fecha_filtro', date.today().isoformat())
    try:
        historial_sesiones = query(
            "SELECT * FROM vw_historial_sesiones WHERE id_terapeuta = %s AND fecha = %s::DATE ORDER BY hora_inicio",
            (id_terapeuta, fecha_filtro), fetchall=True
        )
        kpis = call_procedure_out(
            "CALL sp_kpis_terapeuta(%s, %s::DATE, NULL, NULL, NULL, NULL, NULL)",
            (id_terapeuta, fecha_filtro)
        )
    except Exception:
        historial_sesiones, kpis = [], None
 
    return render_template('clinica_sesiones.html',
                           historial_sesiones=historial_sesiones or [],
                           fecha_actual=fecha_filtro,
                           kpi_completadas=kpis['o_atendidos']   if kpis else 0,
                           kpi_pacientes=kpis['o_pac_unicos']    if kpis else 0,
                           kpi_faltas=kpis['o_faltas']           if kpis else 0)



@app.route('/historial_diario')
@login_required
@role_required('terapeuta')
def historial_diario():
    return redirect(url_for('clinica_obtenerSesiones',
                            fecha_filtro=request.args.get('fecha_filtro', '')))

@app.route('/clinica/sesiones/domicilio')
@login_required
@role_required('terapeuta')
def clinica_sesionesDomicilio():
    id_terapeuta = session.get('ref_id')
    try:
        rutas = query(
            "SELECT * FROM vw_rutas_domicilio WHERE id_terapeuta = %s ORDER BY fecha DESC, hora DESC",
            (id_terapeuta,), fetchall=True
        )
    except Exception:
        rutas = []
    return render_template('clinica_domicilio.html', rutas=rutas or [])

@app.route('/clinica/sesion/iniciar/')
@login_required
@role_required('terapeuta')
def clinica_expedienteSesion():
    id_terapeuta = session.get('ref_id')
    try:
        sesion = query(
            """SELECT ps.id_sesion, ps.id_paciente,
                      p.nombre || ' ' || p.apellido_paterno AS paciente_nombre,
                      s.hora_inicio, s.hora_fin
               FROM   terapeuta_sesion ts_rel
               JOIN   sesiones s  ON s.id_sesion  = ts_rel.id_sesion
               JOIN   paciente_sesion ps ON ps.id_sesion = s.id_sesion
               JOIN   pacientes p ON p.id_paciente = ps.id_paciente
               WHERE  ts_rel.id_terapeuta = %s
                 AND  s.fecha = CURRENT_DATE AND s.asistencia = TRUE
               ORDER  BY s.hora_inicio LIMIT 1""",
            (id_terapeuta,), fetchone=True
        )
    except Exception:
        sesion = None
    return render_template('clinica_expediente_sesion.html', paciente=sesion)

@app.route('/clinica/sesion/nueva')
@login_required
@role_required('terapeuta')
def clinica_registrarSesion():
    return render_template('clinica_registrarSesion.html')


@app.route('/clinica/sesion/iniciar/<int:id_sesion>', methods=['POST', 'GET'])
@login_required
@role_required('terapeuta')
def clinica_iniciarSesionReal(id_sesion):
    """Registra hora_inicio_real cuando el terapeuta da clic en 'Iniciar Sesión'"""
    try:
        query("CALL sp_iniciar_sesion_real(%s)", (id_sesion,), commit=True)
        flash('Sesión iniciada correctamente.', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'error')
    return redirect(url_for('clinica_dashboard'))
 
 
@app.route('/clinica/sesion/finalizar/<int:id_sesion>', methods=['POST'])
@login_required
@role_required('terapeuta')
def clinica_finalizarSesionReal(id_sesion):
    """Registra hora_fin_real cuando el terapeuta finaliza la sesión"""
    observaciones = request.form.get('observaciones', '')
    try:
        query(
            "CALL sp_finalizar_sesion_real(%s, %s)",
            (id_sesion, observaciones or None),
            commit=True
        )
        flash('Sesión finalizada correctamente.', 'success')
    except Exception as e:
        flash(f'Error: {e}', 'error')
    return redirect(url_for('clinica_dashboard'))




@app.route('/clinica/paciente/expediente')
@login_required
@role_required('terapeuta')
def clinica_expedientePaciente():
    id_paciente = request.args.get('id_paciente', type=int)
    try:
        paciente = query(
            "SELECT * FROM vw_expediente_paciente WHERE id_paciente = %s",
            (id_paciente,), fetchone=True
        )
        proxima_sesion = query(
            """SELECT s.fecha, s.hora_inicio, s.hora_fin, ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s AND s.fecha >= CURRENT_DATE
               ORDER BY s.fecha, s.hora_inicio LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ultima_sesion = query(
            """SELECT s.fecha, s.hora_inicio, s.hora_fin,
                      s.asistencia, s.observaciones_clinicas,
                      ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s AND s.fecha < CURRENT_DATE
               ORDER BY s.fecha DESC, s.hora_inicio DESC LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ejercicios_actuales = query(
            """SELECT DISTINCT e.nombre_ejercicio, esd.repeticiones, esd.duracion_min
               FROM ejercicio_sesion_detalle esd
               JOIN sesiones s ON s.id_sesion = esd.id_sesion
               JOIN paciente_sesion ps ON ps.id_sesion = s.id_sesion
               JOIN ejercicios e ON e.id_ejercicio = esd.id_ejercicio
               WHERE ps.id_paciente = %s
               ORDER BY e.nombre_ejercicio""",
            (id_paciente,), fetchall=True
        )
        sesiones_anteriores = query(
            """SELECT s.fecha, s.hora_inicio, s.asistencia,
                      s.observaciones_clinicas, ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s
               ORDER BY s.fecha DESC, s.hora_inicio DESC
               LIMIT 10""",
            (id_paciente,), fetchall=True
        )
    except Exception:
        paciente = proxima_sesion = ultima_sesion = None
        ejercicios_actuales = sesiones_anteriores = []

    return render_template('clinica_expediente_paciente.html',
                           paciente=paciente,
                           proxima_sesion=proxima_sesion,
                           ultima_sesion=ultima_sesion,
                           ejercicios_actuales=ejercicios_actuales or [],
                           sesiones_anteriores=sesiones_anteriores or [])



# ═══════════════════════════════════════════════════════════════════════════════
# PORTAL FAMILIAR
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/paciente/')
@login_required
@role_required('familiar')
def publica_dashboard():
    id_paciente = session.get('ref_id')
    try:
        paciente = query(
            "SELECT nombre || ' ' || apellido_paterno AS nombre, diagnostico_principal AS diagnostico FROM pacientes WHERE id_paciente = %s",
            (id_paciente,), fetchone=True
        )
        proxima = query(
            """SELECT s.fecha, s.hora_inicio FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               WHERE ps.id_paciente = %s AND s.fecha >= CURRENT_DATE
               ORDER BY s.fecha, s.hora_inicio LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ultima = query(
            """SELECT s.fecha, s.hora_inicio FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               WHERE ps.id_paciente = %s AND s.fecha < CURRENT_DATE
               ORDER BY s.fecha DESC LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ejercicios = query(
            """SELECT DISTINCT e.nombre_ejercicio, e.descripcion, nd.nombre AS dificultad
               FROM   ejercicio_sesion_detalle esd
               JOIN   sesiones s ON s.id_sesion = esd.id_sesion
               JOIN   paciente_sesion ps ON ps.id_sesion = s.id_sesion
               JOIN   ejercicios e ON e.id_ejercicio = esd.id_ejercicio
               JOIN   cat_nivel_dificultad nd ON nd.id_nivel = e.id_nivel_dificultad
               WHERE  ps.id_paciente = %s""",
            (id_paciente,), fetchall=True
        )
    except Exception:
        paciente = proxima = ultima = None
        ejercicios = []
    return render_template('publica_dashboard.html',
                           paciente=paciente, proxima_sesion=proxima,
                           ultima_sesion=ultima, ejercicios=ejercicios or [])

@app.route('/paciente/sesiones')
@login_required
@role_required('familiar')
def publica_sesiones():
    id_paciente = session.get('ref_id')
    try:
        paciente = query(
            "SELECT nombre || ' ' || apellido_paterno AS nombre, diagnostico_principal AS diagnostico FROM pacientes WHERE id_paciente = %s",
            (id_paciente,), fetchone=True
        )
        historial_paciente = query(
            "SELECT * FROM vw_historial_paciente WHERE id_paciente = %s ORDER BY fecha_raw DESC",
            (id_paciente,), fetchall=True
        )
    except Exception:
        paciente, historial_paciente = None, []
    return render_template('publica_sesiones.html',
                           paciente=paciente,
                           historial_paciente=historial_paciente or [])



@app.route('/paciente/perfil')
@login_required
@role_required('familiar')
def publica_paciente():
    id_paciente = session.get('ref_id')
    try:
        paciente = query(
            "SELECT * FROM vw_expediente_paciente WHERE id_paciente = %s",
            (id_paciente,), fetchone=True
        )
        proxima_sesion = query(
            """SELECT s.fecha, s.hora_inicio, ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s AND s.fecha >= CURRENT_DATE
               ORDER BY s.fecha, s.hora_inicio LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ultima_sesion = query(
            """SELECT s.fecha, s.hora_inicio, ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s AND s.fecha < CURRENT_DATE
               ORDER BY s.fecha DESC LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        medicamentos = query(
            "SELECT medicamento_actual FROM paciente_medicamento WHERE id_paciente = %s",
            (id_paciente,), fetchall=True
        )
    except Exception:
        paciente = proxima_sesion = ultima_sesion = None
        medicamentos = []
    return render_template('publica_paciente.html',
                           paciente=paciente,
                           proxima_sesion=proxima_sesion,
                           ultima_sesion=ultima_sesion,
                           medicamentos=medicamentos or [],
                           css_file='css/publica_base.css')




@app.route('/paciente/info')
@login_required
def expedientePaciente():
    id_paciente = request.args.get('id_paciente', type=int)
    try:
        paciente = query(
            "SELECT * FROM vw_expediente_paciente WHERE id_paciente = %s",
            (id_paciente,), fetchone=True
        )
        proxima_sesion = query(
            """SELECT s.fecha, s.hora_inicio, s.hora_fin, ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s AND s.fecha >= CURRENT_DATE
               ORDER BY s.fecha, s.hora_inicio LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ultima_sesion = query(
            """SELECT s.fecha, s.hora_inicio, s.hora_fin,
                      s.asistencia, s.observaciones_clinicas,
                      ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s AND s.fecha < CURRENT_DATE
               ORDER BY s.fecha DESC LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        ejercicios_actuales = query(
            """SELECT DISTINCT e.nombre_ejercicio, esd.repeticiones, esd.duracion_min
               FROM ejercicio_sesion_detalle esd
               JOIN sesiones s ON s.id_sesion = esd.id_sesion
               JOIN paciente_sesion ps ON ps.id_sesion = s.id_sesion
               JOIN ejercicios e ON e.id_ejercicio = esd.id_ejercicio
               WHERE ps.id_paciente = %s
               ORDER BY e.nombre_ejercicio""",
            (id_paciente,), fetchall=True
        )
        sesiones_anteriores = query(
            """SELECT s.fecha, s.hora_inicio, s.asistencia,
                      s.observaciones_clinicas, ts.nombre AS tipo_sesion
               FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               JOIN cat_tipos_sesion ts ON ts.id_tipo_sesion = s.id_tipo_sesion
               WHERE ps.id_paciente = %s
               ORDER BY s.fecha DESC LIMIT 10""",
            (id_paciente,), fetchall=True
        )
    except Exception:
        paciente = proxima_sesion = ultima_sesion = None
        ejercicios_actuales = sesiones_anteriores = []

    return render_template('clinica_expediente_paciente.html',
                           paciente=paciente,
                           proxima_sesion=proxima_sesion,
                           ultima_sesion=ultima_sesion,
                           ejercicios_actuales=ejercicios_actuales or [],
                           sesiones_anteriores=sesiones_anteriores or [])



@app.route('/back/paciente')
@login_required
def back_paciente():
    if session['rol'] == 'admin':
        return redirect(url_for('admin_obtenerPacientes')) # Redirige a la pantalla de pacientes de admin
    elif session['rol'] == "doctor":
        return redirect(url_for('clinica_obtenerPacientes')) # Redirige a la pantalla de pacientes de clinica
    else:
        return redirect(url_for('publica_dashboard')) # Redirige a la pantalla principal de admin




@app.route('/nfc')
def nfc_scanner():
    return render_template('nfc_scanner.html')


@app.route('/nfc/registrar', methods=['POST'])
def nfc_registrar():
    from datetime import datetime
    data = request.get_json()
    uid  = data.get('uid', '').strip()

    if not uid:
        return jsonify({'success': False, 'mensaje': 'UID vacío.'})

    try:
        # Buscar paciente por UID del keyfob
        paciente = query(
            "SELECT id_paciente, nombre || ' ' || apellido_paterno AS nombre_completo FROM pacientes WHERE nfc_uid = %s",
            (uid,), fetchone=True
        )
        if not paciente:
            return jsonify({'success': False, 'mensaje': f'Tarjeta no registrada. UID: {uid}'})

        id_paciente = paciente['id_paciente']
        nombre      = paciente['nombre_completo']

        # Buscar sesión de hoy para ese paciente
        sesion = query(
            """SELECT s.id_sesion FROM paciente_sesion ps
               JOIN sesiones s ON s.id_sesion = ps.id_sesion
               WHERE ps.id_paciente = %s AND s.fecha = CURRENT_DATE
               ORDER BY s.hora_inicio LIMIT 1""",
            (id_paciente,), fetchone=True
        )
        if not sesion:
            return jsonify({'success': False, 'mensaje': f'{nombre} no tiene sesión para hoy.'})

        id_sesion = sesion['id_sesion']

        # Verificar que no esté ya registrado
        ya_registrado = query(
            "SELECT 1 FROM asistencias_nfc WHERE id_paciente = %s AND id_sesion = %s",
            (id_paciente, id_sesion), fetchone=True
        )
        if ya_registrado:
            return jsonify({'success': False, 'mensaje': f'{nombre} ya tiene asistencia registrada.'})

        # Registrar asistencia
        hora_ahora = datetime.now().strftime('%H:%M:%S')
        fecha_hoy  = datetime.now().strftime('%Y-%m-%d')

        query(
            """INSERT INTO asistencias_nfc
               (id_paciente, id_sesion, fecha, hora_entrada, asistencia_confirmada, id_dispositivo)
               VALUES (%s, %s, %s::DATE, %s::TIME, TRUE, 1)""",
            (id_paciente, id_sesion, fecha_hoy, hora_ahora),
            commit=True
        )

        return jsonify({
            'success':   True,
            'mensaje':   f'Asistencia registrada para {nombre}',
            'paciente':  nombre,
            'id_sesion': id_sesion,
            'hora':      hora_ahora
        })

    except Exception as e:
        return jsonify({'success': False, 'mensaje': f'Error: {e}'})


if __name__ == "__main__":
    app.run(debug=True)

