document.addEventListener('DOMContentLoaded', function () {
  const container = document.getElementById('tendenciaChart');
  container.innerHTML = '<p>Cargando gráfica...</p>';
  fetch('/api/kpi/tendencia-asistencias?dias=30')
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP Error: ${response.status}`);
      }
      return response.json();
    })
    .then(data => {
      Highcharts.chart('tendenciaChart', {
        chart: {
          type: 'areaspline',
          backgroundColor: 'transparent'
        },
        title: {
          text: null
        },
        xAxis: {
          categories: data.fechas,
          gridLineWidth: 0
        },
        yAxis: {
          title: {
            text: 'Número de Sesiones'
          },
          allowDecimals: false
        },

        tooltip: {
          shared: true
        },

        credits: {
          enabled: false
        },

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
              stops: [ [0, 'rgba(231, 76, 60, 0.2)'], [1, 'rgba(231, 76, 60, 0)'] ] } } ]
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

});
