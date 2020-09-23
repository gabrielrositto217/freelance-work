// Código:

function concentrarGSheets() {
  var documento = SpreadsheetApp.getActiveSpreadsheet();
  var hojaConcentrada = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Base');
  // Inicio: borra todo el contenido existente de antes salvo por los títulos, excepto si la hoja está vacía
  if (hojaConcentrada.getMaxRows() > 3) {
    hojaConcentrada.insertRowBefore(3);
    hojaConcentrada.deleteRows(4, hojaConcentrada.getMaxRows() - 3);
  };
  // Lista archivos a procesar
  var hojaIndice = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Indice');
  // Itera base por base
  var filaActual = 4;
  var posicionActual = hojaIndice.getRange(filaActual, 3, 1, 3);
  var cursorBaseActual = posicionActual.getValues();
  while (cursorBaseActual[0][0] !== '') {
    // Busco los datos de la base
    var baseActual = SpreadsheetApp.openByUrl(cursorBaseActual[0][1]);
    var hojaActual = baseActual.getSheetByName(cursorBaseActual[0][2]);
    var datos = hojaActual.getDataRange().getDisplayValues();
    // Matchea nombres de columna para ambas hojas
    var columnasOrigen = datos[0].filter(String);
    var columnasDestino = hojaConcentrada.getRange('A2:AE2').getValues()[0];
    var idColumnas = [];
    columnasOrigen.forEach(function(nombre) {
      idColumnas.push(columnasDestino.indexOf(nombre));
    });
    // Itero para todos los prospectos de la base
    var baseArmada = [];
    for (var i = 1; i < datos.length; i++) {
      fila = [];
      var j = 0;
      datos[i].forEach(function(valor) {
        fila[idColumnas[j]] = valor;
        j++;
      })
      // Asigna campos calculados
      valorFecha = datos[i][columnasOrigen.indexOf('SubmittedOn')];
      // Lógica de fechas dependiendo el formato
      if (valorFecha.indexOf('/') > 0) {                 // Formato MM/DD/YYYY HH24:MI:SS o similar
        fila[0] = valorFecha.split(' ')[0];    // Fecha
        fila[1] = parseInt(valorFecha.substring(0, valorFecha.indexOf('/')), 10);    // Mes
        fila[2] = parseInt(valorFecha.split('/')[2].substring(0, 4));    // Año
      } else if (valorFecha.indexOf('-') > 0) {             // Formato YYYY-MM-DDTHH24:MI:SS-TZ
        fila[0] = valorFecha.substring(0, 10);    // Fecha
        fila[1] = parseInt(valorFecha.substring(5, 7), 10);    // Mes
        fila[2] = parseInt(valorFecha.substring(0, 4));    // Año
      }
      // Asigna nombre de campaña y divide nombre/apellido
      fila[3] = cursorBaseActual[0][0];    // Campaña
      var nombreApellido = datos[i][columnasOrigen.indexOf('Nombre')]
      fila[4] = nombreApellido.split(' ')[0];    // Nombre inicial
      fila[5] = nombreApellido.substring(nombreApellido.indexOf(' ') + 1, 1000);    // Apellido(s)
      // Agrega texto vacío en caso que el dato no exista (valor null dentro de 'fila')
      var k = 0;
      columnasDestino.forEach(function(valorNulo) {
        if (fila[k] == undefined) {
          fila[k] = ''
        };
        k++;
      });
      // Agrega la fila a la base preliminar
      baseArmada.push(fila);
    }  
    // Escribe las filas generadas en el concentrado
    hojaConcentrada.getRange(hojaConcentrada.getLastRow() + 1, 1, baseArmada.length, columnasDestino.length).setValues(baseArmada);
    // Avanza a la siguiente base
    filaActual++;
    posicionActual = hojaIndice.getRange(filaActual, 3, 1, 3);
    cursorBaseActual = posicionActual.getValues();
  }
}