# frozen_string_literal: true

module ParticipantsHelper
  # count columns: header filter accepts 6, >=6, <3, !=0 (function attached in table_controller.js)
  NUMERIC_FILTER = { headerFilter: 'input', headerFilterFunc: 'numeric',
                     headerFilterPlaceholder: 'e.g. >=6' }.freeze

  PARTICIPANTS_TABLE_COLUMNS =
    [
      { title: 'Name', field: 'andrewid', sorter: 'string',
        headerFilter: 'input', frozen: true,
        formatter:"link",
          formatterParams:{
            labelField:"name",
            urlPrefix:"participants/"}
      },
      { title: 'Andrew ID', field: 'andrewid', sorter: 'string',
        hozAlign: 'left', headerFilter: 'input' },
      { title: 'Department', field: 'pretty_depts', width: '250',
        sorter: 'string', hozAlign: 'left', headerFilter: 'input' },
      { title: 'School', field: 'pretty_colleges', sorter: 'string',
        hozAlign: 'left', headerFilter: 'input', width: 100, resizable: true },
      { title: 'Student Class', field: 'student_class',
        sorter: 'string', hozAlign: 'left', headerFilter: 'input' },
      { title: 'General Eberly',
        columns: [
          { title: 'First Consultation On', field: 'first_consultation_on',
            sorter: 'date', hozAlign: 'left', headerFilter: 'input' },
          { title: "Seminars",
           field: 'ffp_seminar_size', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
          { title: "DEI Seminars",
           field: 'ffp_dei_size', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
          #{ title: 'Last Change', field: 'updated_at', sorter: 'date',
          #  hozAlign: 'left', headerFilter: 'input' }
       ] },
     { title: 'Future Faculty Program',
       columns: [
         { title: 'Graduation Date',
           field: 'future_faculty_program_graduated_on', sorter: 'date',
           hozAlign: 'left', headerFilter: 'input' },
         { title: 'Status',
           field: 'ffp_status', sorter: 'string',
           hozAlign: 'left', headerFilter: 'input' },
         { title: "Obs",
           field: 'ffp_obs', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
        { title: "ECFs",
           field: 'ffp_ecf', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
        { title: "Micros",
           field: 'ffp_micro', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
        { title: "LPRs",
           field: 'ffp_lpr', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
        { title: "CSDs",
           field: 'ffp_csd', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
        { title: "TPs",
           field: 'ffp_tp', sorter: 'number',
           hozAlign: 'left', **NUMERIC_FILTER },
#         ffp_ecf ffp_micro ffp_lpr ffp_sp ffp_tsp
         # TODO p.future_faculty_progress_status.label if p.future_faculty_progress_status 
       ] }].freeze

  def participants_table_config
    { footerElement: "<button id=\"download-csv\">Download #{Participant.all.size} Participants (.xlsx)</button>",
      placeholder: '<h2>No Data Available</h2>',
      paginationCounter: 'rows',
      pagination: true,
      paginationSize: 50,
      ajaxURL: participants_path(format: :json, ffp_status: @ffp_status),
      resizableColumnFit: true,
      columns: PARTICIPANTS_TABLE_COLUMNS }.to_json
  end
end

