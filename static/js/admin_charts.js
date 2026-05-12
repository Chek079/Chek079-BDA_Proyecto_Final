document.addEventListener('DOMContentLoaded', function () {
  cargarTendenciaAsistencias();
  cargarEstadosSesiones();
  cargarAsistenciaPacientes();
  cargarSesionesTerapeuta();
  cargarTiposSesion();
  cargarEvolucionDolor();
  cargarEvolucionMovilidad();
  cargarTendenciaSesiones();
});

function cargarTendenciaSesiones() {
    fetch('/api/kpi/tendencia_sesiones')
        .then(response => response.json())
        .then(data => {
            Highcharts.chart('tendenciaSesiones', {
                chart: { type: 'area' },
                title: { text: 'Tendencia de Sesiones' },
                xAxis: { categories: data.fecha },
                yAxis: {
                    title: {
                        text: 'Sesiones'
                    }
                },
                series: [{
                    name: 'Sesiones',
                    data: data.total
                }]
            });

        });
}

function cargarEvolucionMovilidad() {
    fetch('/api/kpi/evolucion_movilidad')
        .then(response => response.json())
        .then(data => {
            Highcharts.chart('evolucionMovilidad', {
                chart: { type: 'spline' },
                title: { text: 'Evolución de Movilidad' },
                xAxis: { categories: data.fecha },

                yAxis: {
                    min: 0,
                    max: 10,
                    title: {
                        text: 'Movilidad'
                    }
                },
                series: [{
                    name: 'Movilidad',
                    data: data.movilidad_promedio
                }]
            });
        });
}

function cargarEvolucionDolor() {
    fetch('/api/kpi/evolucion_dolor')
        .then(response => response.json())
        .then(data => {
            Highcharts.chart('evolucionDolor', {
                chart: { type: 'line' },
                title: { text: 'Evolución del Dolor' },
                xAxis: { categories: data.fecha },

                yAxis: {
                    min: 0,
                    max: 10,
                    title: {
                        text: 'Nivel de Dolor'
                    }
                },

                series: [{
                    name: 'Dolor',
                    data: data.dolor_promedio
                }]
            });

        });
}

function cargarTiposSesion() {
    fetch('/api/kpi/tipos_sesion')
        .then(response => response.json())
        .then(data => {
            const seriesData = data.nombre.map((nombre, index) => ({
                name: nombre,
                y: data.total[index]
            }));

            Highcharts.chart('tiposSesion', {
                chart: { type: 'pie' },
                title: { text: 'Tipos de Sesión' },
                series: [{ name: 'Total', data: seriesData }]
            });
        });
}

function cargarSesionesTerapeuta() {
    fetch('/api/kpi/sesiones_terapeuta')
        .then(response => response.json())
        .then(data => {

            Highcharts.chart('sesionesTerapeuta', {
                chart: { type: 'bar' },
                title: { text: 'Sesiones por Terapeuta' },
                xAxis: { categories: data.terapeuta },
                yAxis: { title: { text: 'Sesiones' } },
                series: [{
                    name: 'Sesiones',
                    data: data.total_sesiones
                }]
            });

        });
}

function cargarAsistenciaPacientes() {
    fetch('/api/kpi/asistencia_pacientes')
        .then(response => response.json())
        .then(data => {
            Highcharts.chart('asistenciaPacientes', {
                chart: { type: 'column' },
                title: { text: 'Asistencia por Paciente' },
                xAxis: { categories: data.paciente },
                yAxis: {
                    min: 0,
                    max: 100,
                    title: {
                        text: 'Porcentaje'
                    }
                },

                series: [{
                    name: 'Asistencia',
                    data: data.porcentaje_asistencia
                }]
            });
        });
}


function cargarTendenciaAsistencias() {
  const container = document.getElementById('tendenciaChart');
  container.innerHTML = '<p>Cargando gráfica...</p>';
  fetch('/api/kpi/tendencia-asistencias?dias=30') 
    .then(response => {
      if (!response.ok) { throw new Error(`HTTP Error: ${response.status}`); }
      return response.json();
    })
    .then(data => {
      Highcharts.chart('tendenciaChart', {
        chart: { type: 'areaspline', backgroundColor: 'transparent' },
        title: { text: null },
        xAxis: { categories: data.fechas, gridLineWidth: 0 },
        yAxis: { title: { text: 'Número de Sesiones' }, allowDecimals: false },
        tooltip: { shared: true },
        credits: { enabled: false },

        series: [
          {
            name: 'Asistencias',
            data: data.asistencias,
            color: '#2ecc71',
            fillColor: {
              linearGradient: [0, 0, 0, 300],
              stops: [
                [0, 'rgba(46, 204, 113, 0.3)'],
                [1, 'rgba(46, 204, 113, 0)']
              ]
            }
          },
          {
            name: 'Cancelaciones',
            data: data.cancelaciones,
            color: '#e74c3c',
            fillColor: {
              linearGradient: [0, 0, 0, 300],
              stops: [
                [0, 'rgba(231, 76, 60, 0.2)'],
                [1, 'rgba(231, 76, 60, 0)']
              ]
            }
          }
        ]
      });
    })
    .catch(err => {
      console.error('Error cargando gráfica:', err);
      container.innerHTML = `
        <div class="alert alert-danger">
          Error cargando datos de la gráfica
        </div>
      `;
    });
}

function cargarEstadosSesiones() {
  const container = document.getElementById('estadoSesionesChart');
  container.innerHTML = '<p>Cargando gráfica...</p>';
  fetch('/api/kpi/estados_sesiones')
    .then(response => {
      if (!response.ok) { throw new Error(`HTTP Error: ${response.status}`); }
      return response.json();
    })

    .then(data => {
      Highcharts.chart('estadoSesionesChart', {
        chart: { type: 'pie', backgroundColor: 'transparent' },
        title: { text: 'Estados de Sesiones' },
        credits: { enabled: false },
        series: [{
          name: 'Total',
          colorByPoint: true,
          data: data.estado_sesion.map((estado, index) => ({
            name: estado,
            y: data.total[index]
          }))
        }]
      });
    })
    .catch(err => { console.error('Error cargando gráfica:', err);
      container.innerHTML = ` <div class="alert alert-danger"> Error cargando datos de la gráfica </div> `;
    });
}
