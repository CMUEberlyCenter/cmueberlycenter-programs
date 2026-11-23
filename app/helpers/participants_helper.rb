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
