# frozen_string_literal: true

module ParticipantsHelper
  FFP_STATUS_NAMES = {
    'incomplete' => 'In Progress',
    'complete' => 'Requirements Met',
    'graduated' => 'Graduated',
    'dropout' => 'Left CMU'
  }.freeze

  # The count columns in the participants table, in order
  COUNT_COLUMNS = {
    'ffp_seminar_size' => 'Seminars',
    'ffp_dei_size' => 'DEI Seminars',
    'ffp_obs' => 'Observations',
    'ffp_ecf' => 'ECFs',
    'ffp_micro' => 'Microteaching',
    'ffp_lpr' => 'Lesson Plan Reviews',
    'ffp_csd' => 'Course Designs',
    'ffp_tp' => 'Teaching Statements'
  }.freeze

  # A People table row's text, as its cells show it, in lowercase
  def participant_row_text(row)
    [row['name'] || row['andrewid'], row['andrewid'], row['pretty_depts'], row['pretty_colleges'], row['student_class'],
     ap_date(row['first_consultation_on']&.to_date), FFP_STATUS_NAMES[row['ffp_status']],
     ap_date(row['future_faculty_program_graduated_on']&.to_date), *row.values_at(*COUNT_COLUMNS.keys)]
      .compact.join(' ').downcase
  end

  # A Future Faculty Program status in a word or two
  def ffp_status_name(status)
    FFP_STATUS_NAMES.fetch(status&.key, status&.key.to_s.titleize) if status
  end

  # A Future Faculty Program status as a pill: green once requirements are
  # met, amber for someone who left
  def ffp_status_pill(status)
    return unless status

    tone = { 'complete' => 'green', 'graduated' => 'green', 'dropout' => 'amber', 'incomplete' => 'blue' }
    tag.span(ffp_status_name(status), class: "cmu-pill cmu-pill--#{tone.fetch(status.key, 'outline')}")
  end
end
