import { Controller } from "@hotwired/stimulus"
import { DateTime } from "luxon";
import { TabulatorFull as Tabulator } from 'tabulator-tables';

export default class extends Controller {
  static targets = [ "q" ]
  //static get targets() {
  //  return ['q'];
  //}
  lookupParticipants(event) {
    //let term = this.qTarget.value.length;
    //console.log(event);
    console.log(this.qTarget.value)

  }
    //initialize() {
    connect() {
	// this.config for persistance
	const config = JSON.parse(this.element.dataset.config)
	const nameColumn = config.columns.find(col => col.field === 'andrewid');
if (nameColumn) {
  nameColumn.headerFilterFunc = function(headerValue, rowValue, rowData, filterParams) {
    if (!headerValue) return true;
    if (!rowData.name) return false;
    return rowData.name.toLowerCase().includes(headerValue.toLowerCase());
  };
}
	// columns marked headerFilterFunc: 'numeric' in the helper get a comparison filter
	const attachNumericFilters = cols => cols.forEach(col => {
	    if (col.columns) attachNumericFilters(col.columns);
	    if (col.headerFilterFunc === 'numeric') col.headerFilterFunc = numericFilter;
	});
	attachNumericFilters(config.columns);
	var table = new Tabulator("#example-table", config);

	table.on("dataProcessed", function(e, row){
	    var firstRow = table.getRows()[0];

	    if(firstRow){
		firstRow.freeze();
	    }
	});
	//document.getElementById("download-csv").addEventListener("click", function(){
	//    table.download("csv", "data.csv");
	//});

	    /*

	        //trigger an alert message when the row is clicked
        table.on("rowClick", function(e, row){
                alert("Row " + row.getIndex() + " Clicked!!!!");
        });*/

    }
}

// "6" or "=6" exact, ">=6", "<=6", ">6", "<6", "!=6"; anything else falls back to substring match
function numericFilter(headerValue, rowValue, rowData, filterParams) {
  const m = String(headerValue).trim().match(/^(>=|<=|!=|<>|>|<|=)?\s*(-?\d+(?:\.\d+)?)$/);
  if (!m) return String(rowValue ?? '').includes(headerValue);
  const v = Number(rowValue), n = Number(m[2]);
  if (rowValue === null || rowValue === undefined || rowValue === '' || isNaN(v)) return false;
  switch (m[1]) {
    case '>=': return v >= n;
    case '<=': return v <= n;
    case '>':  return v > n;
    case '<':  return v < n;
    case '!=': case '<>': return v != n;
    default:   return v == n;
  }
}
