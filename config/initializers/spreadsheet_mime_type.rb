# Register before mailers or other views initialize their template path parsers.
# caxlsx_rails otherwise waits until ActionController is loaded to register XLSX.
Mime::Type.register(
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', :xlsx
) unless Mime[:xlsx]
