module Programs::FutureFacultyHelper
  FUTURE_FACULTY_TABLE_COLUMNS = [
    { title: 'Created At', field: 'created_at' },
    { title: 'Name', field: 'name', frozen: true, formatter: 'link',
      formatterParams: { labelField: 'name', urlField: 'participant_url' } },
    { title: 'Andrew ID', field: 'participant_andrewid' },
    { title: 'FFP Graduation Date', field: 'graduated_on' },
    { title: 'Status', field: 'status' },
    { title: 'First Consultation On', field: 'first_consultation_on' },
    { title: 'Category', field: 'category' },
    { title: 'Type', field: 'requirement' },
    { title: 'Activity Title', field: 'title' },
    { title: 'Description', field: 'description', formatter: 'textarea', width: 300 },
    { title: 'Course', field: 'course' },
    { title: 'Observer', field: 'observer' },
    { title: 'Lead Consultant', field: 'lead_consultant' },
    { title: 'Completed On', field: 'completed_on' },
    { title: 'Memo Completed On', field: 'memo_completed_on' },
    { title: 'Internal Notes', field: 'internal_notes', formatter: 'textarea', width: 300 }
  ].map { |column| { sorter: 'string', headerFilter: 'input' }.merge(column) }.freeze

  def future_faculty_table_config
    {
      footerElement: link_to('Download Future Faculty Data (.xlsx)',
                             future_faculty_path(format: :xlsx), class: 'btn'),
      placeholder: '<h2>No Data Available</h2>',
      paginationCounter: 'rows',
      pagination: true,
      paginationSize: 50,
      ajaxURL: future_faculty_path(format: :json),
      resizableColumnFit: true,
      initialSort: [{ column: 'created_at', dir: 'desc' }],
      columns: FUTURE_FACULTY_TABLE_COLUMNS
    }.to_json
  end
end
