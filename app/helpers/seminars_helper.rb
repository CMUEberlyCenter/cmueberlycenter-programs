module SeminarsHelper
    SEMINARS_TABLE_COLUMNS =
    [    
      { title: 'ID', field: 'id', sorter: 'string',
        headerFilter: 'input',
        formatter:"link",
          formatterParams:{
            labelField:"id",
            urlPrefix:"admin/seminars/"}
      }, 
      { title: 'Tags', field: 'tags', sorter: 'string',
        headerFilter: 'input'},
      { title: 'Title', field: 'title', sorter: 'string',
        headerFilter: 'input'},
      { title: 'Confirmed', field: 'confirmed_registrations_size', sorter: 'string',
        headerFilter: 'input'},
      { title: 'Attended', field: 'attended_registrations_size', sorter: 'string',
        headerFilter: 'input'},

      #{ title: 'School', field: 'pretty_colleges', sorter: 'string',
      #  hozAlign: 'left', headerFilter: 'input', width: 100, resizable: true },
      #{ title: 'General Eberly',
      #  columns: [
      #    { title: 'First Consultation On', field: 'first_consultation_on',
      #      sorter: 'date', hozAlign: 'left', headerFilter: 'input' },
      #    { title: 'Last Change', field: 'updated_at', sorter: 'date',
      #      hozAlign: 'left', headerFilter: 'input' }
      # ] },
     #{ title: 'Future Faculty Program',
     #  columns: [
     #    { title: 'Graduation Date',
     #      field: 'future_faculty_program_graduated_on', sorter: 'date',
     #      hozAlign: 'left', headerFilter: 'input' },
     #    { title: 'Status',
     #      field: 'ffp_status', sorter: 'string',
     #      hozAlign: 'left', headerFilter: 'input' }
     #    # TODO p.future_faculty_progress_status.label if p.future_faculty_progress_status
      # ] }
      ].freeze

  #footerElement: "<button id=\"download-csv\">Download #{Seminar.all.size} Seminars (.xlsx)</button>",
  def seminars_table_config
    { footerElement: "<a class=\"btn\" href=\"seminars.xlsx\">Download #{Seminar.all.size} Seminars (.xlsx)</a>",
      placeholder: '<h2>No Data Available</h2>',
      paginationCounter: 'rows',
      pagination: true,
      paginationSize: 50,
      ajaxURL: seminars_path(format: :json),
      resizableColumnFit: true,
      columns: SEMINARS_TABLE_COLUMNS }.to_json
  end

end
