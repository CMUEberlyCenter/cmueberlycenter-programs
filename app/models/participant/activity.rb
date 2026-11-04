class Participant::Activity < ActiveRecord::Base
  belongs_to :participant
  belongs_to :status, class_name: 'Participant::Activity::Status', optional: true
  belongs_to :future_faculty_requirement, class_name: 'Programs::FutureFaculty::Requirement', optional: true
  belongs_to :observer, class_name: 'Participant', optional: true
  belongs_to :lead_consultant, class_name: 'Participant', optional: true
  
  # All activities meeting a requirement for some provided program (e.g.: future_faculty)
  scope :program_requirements, -> (program) { where.not("#{program}_requirement_id".to_sym => nil) }


  filterrific(
    default_filter_params: { sorted_by: 'created_at_desc' },
    available_filters: [
      :sorted_by,
      :search_query,
      :with_observer,
      :with_created_at_gte,
      :with_category,
      :with_first_consultation_on_gte
    ]
  )
  
  def self.options_for_select
    order("LOWER(name)").map { |e| [e.observer.name, e.observer_id] }
  end
#  scope :sorted_by, -> (key) { order(created_at: :desc) }
  #scope :sorted_by , -> { where( type: 'Participant::Activities::Additional' ) }
#  scope :search_query, -> { where( type: 'Participant::Activities::Additional' ) }
#  scope :with_observer_id, -> { where( type: 'Participant::Activities::Additional' ) }
#  scope :with_created_at_gte, -> { where( type: 'Participant::Activities::Additional' ) }
   # Scope definitions. We implement all Filterrific filters through ActiveRecord
  # scopes. In this example we omit the implementation of the scopes for brevity.
  # Please see 'Scope patterns' for scope implementation details.
  scope :search_query, ->(query) {
    # Filters students whose name or email matches the query
   
  }
  scope :sorted_by, ->(sort_option) {
    direction = /desc$/.match?(sort_option) ? "desc" : "asc"
    case sort_option.to_s
    when /^name/
      order("LOWER(activities.participant.name) #{direction}")
    #when /^country/
    #  order("LOWER(students.country) #{direction}")
    when /^created_at/
      order("LOWER(participant_activities.created_at) #{direction}")
    else
      raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
    end
  }
  scope :with_observer, ->(observer_ids) {
    # Filters students with any of the given country_ids
   
  }
  scope :with_created_at_gte, ->(ref_date) {
   
  }

  scope :with_first_consultation_on_gte, ->(ref_date) {
   
  }

  scope :with_category, ->(ref_date) {
   
  }

  # Scopes for each activity type
  #Programs::FutureFaculty::Requirement.find_each do |a|
  #  scope a.key.pluralize, -> { where( type: a.activity_class) }
  #end
  
  # Additional activities are not governed by one specific progam, thus they are explicitly scoped here
  scope :additional, -> { where( type: 'Participant::Activities::Additional' ) }


  
  validates :participant, presence: true
  validates_associated :participant
  
  validates_associated :future_faculty_requirement
  
end
