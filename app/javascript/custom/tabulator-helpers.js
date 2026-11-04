function nameFilter(headerValue, rowValue, rowData, filterParams) {
  if (!headerValue) return true;
  if (!rowData.name) return false;
  return rowData.name.toLowerCase().includes(headerValue.toLowerCase());
}
