// admin_charts.js
// Todas las gráficas leen de MongoDB via endpoints Flask /api/charts/

// ─── Helper para fetch ────────────────────────────────────────
async function fetchData(url) {
    const res = await fetch(url);
    return await res.json();
}

// ─── 1. Tendencia de Asistencias (línea) ─────────────────────
async function cargarTendenciaAsistencias() {
    const datos = await fetchData('/api/charts/tendencia-sesiones');
    const fechas = datos.map(d => d.fecha);
    const totales = datos.map(d => d.total);

    Highcharts.chart('tendenciaChart', {
        chart: { type: 'line', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: fechas, labels: { rotation: -45, style: { fontSize: '11px' } } },
        yAxis: { title: { text: 'Sesiones' }, allowDecimals: false },
        series: [{ name: 'Sesiones por día', data: totales, color: '#2563eb' }],
        credits: { enabled: false },
        legend: { enabled: false }
    });
}

// ─── 2. Estados de Sesiones (dona) ───────────────────────────
async function cargarEstadosSesiones() {
    const datos = await fetchData('/api/charts/estados-sesiones');
    const seriesData = datos.map(d => ({
        name: d.estado_sesion,
        y: parseInt(d.total)
    }));

    Highcharts.chart('estadoSesionesChart', {
        chart: { type: 'pie', backgroundColor: 'transparent' },
        title: { text: null },
        plotOptions: {
            pie: {
                innerSize: '50%',
                dataLabels: { enabled: true, format: '<b>{point.name}</b>: {point.percentage:.1f}%' }
            }
        },
        series: [{ name: 'Sesiones', colorByPoint: true, data: seriesData }],
        colors: ['#2563eb', '#16a34a', '#d97706', '#dc2626'],
        credits: { enabled: false }
    });
}

// ─── 3. Asistencia por Paciente (barras) ─────────────────────
async function cargarAsistenciaPacientes() {
    const datos = await fetchData('/api/charts/asistencia-pacientes');
    const nombres   = datos.map(d => d.paciente);
    const asistidas = datos.map(d => parseInt(d.sesiones_asistidas));
    const faltadas  = datos.map(d => parseInt(d.sesiones_faltadas));

    Highcharts.chart('asistenciaPacientes', {
        chart: { type: 'bar', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: nombres },
        yAxis: { title: { text: 'Sesiones' }, allowDecimals: false },
        series: [
            { name: 'Asistidas', data: asistidas, color: '#16a34a' },
            { name: 'Faltas',    data: faltadas,  color: '#dc2626' }
        ],
        credits: { enabled: false }
    });
}

// ─── 4. Tendencia por Sesión (área) ──────────────────────────
async function cargarTendenciaSesiones() {
    const datos  = await fetchData('/api/charts/tendencia-sesiones');
    const fechas = datos.map(d => d.fecha);
    const totales = datos.map(d => parseInt(d.total));

    Highcharts.chart('tendenciaSesiones', {
        chart: { type: 'area', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: fechas, labels: { rotation: -45, style: { fontSize: '11px' } } },
        yAxis: { title: { text: 'Sesiones' }, allowDecimals: false },
        series: [{
            name: 'Sesiones',
            data: totales,
            color: '#0d9488',
            fillOpacity: 0.2
        }],
        credits: { enabled: false },
        legend: { enabled: false }
    });
}

// ─── 5. Evolución Movilidad (línea) ──────────────────────────
async function cargarEvolucionMovilidad() {
    const datos  = await fetchData('/api/charts/evolucion-movilidad');
    const fechas = datos.map(d => d.fecha);
    const valores = datos.map(d => parseFloat(d.movilidad_promedio));

    Highcharts.chart('evolucionMovilidad', {
        chart: { type: 'line', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: fechas, labels: { rotation: -45, style: { fontSize: '11px' } } },
        yAxis: { title: { text: 'Nivel (0-10)' }, min: 0, max: 10 },
        series: [{ name: 'Movilidad promedio', data: valores, color: '#16a34a' }],
        credits: { enabled: false },
        legend: { enabled: false }
    });
}

// ─── 6. Evolución Dolor (línea) ──────────────────────────────
async function cargarEvolucionDolor() {
    const datos  = await fetchData('/api/charts/evolucion-dolor');
    const fechas = datos.map(d => d.fecha);
    const valores = datos.map(d => parseFloat(d.dolor_promedio));

    Highcharts.chart('evolucionDolor', {
        chart: { type: 'line', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: fechas, labels: { rotation: -45, style: { fontSize: '11px' } } },
        yAxis: { title: { text: 'Nivel (0-10)' }, min: 0, max: 10 },
        series: [{ name: 'Dolor promedio', data: valores, color: '#dc2626' }],
        credits: { enabled: false },
        legend: { enabled: false }
    });
}

// ─── 7. Tipos de Sesión (pastel) ─────────────────────────────
async function cargarTiposSesion() {
    const datos = await fetchData('/api/charts/tipos-sesion');
    const seriesData = datos.map(d => ({
        name: d.nombre,
        y: parseInt(d.total)
    }));

    Highcharts.chart('tiposSesion', {
        chart: { type: 'pie', backgroundColor: 'transparent' },
        title: { text: null },
        plotOptions: {
            pie: { dataLabels: { enabled: true, format: '<b>{point.name}</b>: {point.y}' } }
        },
        series: [{ name: 'Sesiones', colorByPoint: true, data: seriesData }],
        colors: ['#2563eb', '#0d9488', '#d97706'],
        credits: { enabled: false }
    });
}

// ─── 8. Sesiones por Terapeuta (columnas) ────────────────────
async function cargarSesionesTerapeuta() {
    const datos = await fetchData('/api/charts/sesiones-terapeuta');
    const nombres = datos.map(d => d.terapeuta);
    const totales = datos.map(d => parseInt(d.total_sesiones));

    Highcharts.chart('sesionesTerapeuta', {
        chart: { type: 'column', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: nombres },
        yAxis: { title: { text: 'Sesiones' }, allowDecimals: false },
        series: [{ name: 'Sesiones', data: totales, color: '#2563eb' }],
        credits: { enabled: false },
        legend: { enabled: false }
    });
}

// ─── Cargar todas las gráficas al cargar la página ────────────
document.addEventListener('DOMContentLoaded', () => {
    cargarTendenciaAsistencias();
    cargarEstadosSesiones();
    cargarAsistenciaPacientes();
    cargarTendenciaSesiones();
    cargarEvolucionMovilidad();
    cargarEvolucionDolor();
    cargarTiposSesion();
    cargarSesionesTerapeuta();
});
