class Participant < ApplicationRecord
  include Participant::Ldap

  # Multivalued fields that use store and are archived
  STORE_ATTRS = %w[
    affiliation
    college
    dept
  ].freeze

  # Fields with fallback values
  FALLBACK_ATTRS = %w[
    name
    sortable_name
  ].freeze

  # See slug as id in urls
  def to_param = andrewid

  # Find user by their andrew id unless id is a number
  def self.find(id) = id.to_i.zero? ? find_by(andrewid: id) : super

  # TODO: prioritize exesting people
  def self.filter(keyword: nil)
    x = AndrewPerson.filter(keyword: keyword)
    return if x.blank?
    #   x.map{|p| {id: p.uid.downcase, label: p.name + " (" + p.uid.downcase + ")"} }
       x.map{|p| {id: p.uid.downcase, label: "#{p.name} <span class=\"uid\">(#{p.uid.downcase})</span>" } }
  end    

  # Participant filters (e.g.: Participant.admins)
  scope :admins, -> { where(is_admin: true) }
  scope :consultants, -> { where(is_consultant: true) }
  scope :empties, -> { select(&:empty?) }

  # Calculated fields with fallback values
  def name(fallback: true)
    if fallback
      self['name'] || name_archive || andrewid
    else
      self['name']
    end
  end
  
  def sortable_name(fallback: true)
    if fallback
      self['sortable_name'] || sortable_name_archive || andrewid
    else
      self['sortable_name']
    end
  end

  # Store multivalued fields coming from LDAP in a single column
  STORE_ATTRS.each do |attr|
    store(attr, accessors: ["#{attr}s", "pretty_#{attr}s"], coder: JSON)

    # Define the accessor methods above (e.g. affiliations=(values))
    define_method "#{attr}s=" do |values|
      values = Array(values)
      send("pretty_#{attr}s=", values.join('; '))
      super(values)
    end

    store("#{attr}_archive",
          accessors: ["#{attr}s_archive", "pretty_#{attr}s_archive"],
          coder: JSON)

    # Define the accessor methods above (e.g. affiliations_archive=(values))
    define_method "#{attr}s_archive=" do |values|
      values = Array(values)
      send("pretty_#{attr}s_archive=", values.join('; '))
      super(values)
    end
  end

  def admin? = is_admin
  def consultant? = is_consultant
  def was_consultant? = observations.present? || lead_consultations.present?
  def eberly_flavored? = admin? || consultant? || was_consultant?
  def note? = note.to_s.present?
    def ffp_status
      future_faculty_progress_status.key unless future_faculty_progress_status.blank?
    end

    
  def program_enrollment?
    Programs::FutureFaculty::Enrollment.find(self).present?
  end

  def empty?
    activity = eberly_flavored? || program_enrollment? || note? ||
               registrations.present? || activities.present?
    return true unless activity
  end

  belongs_to(:future_faculty_enrollment,
             -> { readonly },
             class_name: 'Programs::FutureFaculty::RequirementsVersion',
             optional: true)
  belongs_to(:future_faculty_progress_status,
             -> { readonly },
             class_name: 'ProgressStatusType',
             optional: true)
             

  has_many(:registrations, dependent: :destroy)






  has_many :activities, class_name: 'Participant::Activity', dependent: :destroy,
           inverse_of: :participant, autosave: true

  has_many :observations, class_name: 'Participant::Activity',
           foreign_key: :observer_id, dependent: :destroy
  has_many :lead_consultations, class_name: 'Participant::Activity',
           foreign_key: :lead_consultant_id, dependent: :destroy


  before_save :update_program_progress_statuses

  # Recalculate progress in programs
  def update_program_progress_statuses
    ffp_requirements = self.future_faculty_enrollment
    ffp_requirements.calculate_participant_status( self ) if ffp_requirements
  end

  def self.options_for_select
    order("LOWER(name)").map { |e| [e.name, e.id] }
  end


#  has_many :additional_activities, class_name: Participants::Activities::Additional, dependent: :destroy
  #
  #accepts_nested_attributes_for :additional_activities
  accepts_nested_attributes_for :activities

  #scope :program_requirements, -> (program) { where.not("#{program}_requirement_id".to_sym => nil) }
  #has_many :workshops, through: :registrations, foreign_key: "seminar_id"
  #has_many :workshop_registrations, source: :registrations



  # helper for attended_workshops and attended_seminars relations
  has_many :attended_registrations, -> { attended }, class_name: "Registration"

  # Attended event calculations
  has_many( :attended_workshops, -> { with_tag( "workshop" ) },
            through: :attended_registrations, source: :seminar )
  has_many( :attended_seminars, -> { without_tag( "workshop" ).without_tag( "other" ) },
            through: :attended_registrations, source: :seminar )
  has_many( :attended_other, -> { with_tag( "other" ) },
            through: :attended_registrations, source: :seminar )



#  has_many :attended_workshops, -> { joins(:registrations).where(attended) }, through: :registrations, source: :seminar
           #, #joins(:workshopregistrations).merge(Book.available)



#  default_scope { order("udpate") }
  # TODO: default to fetching active students
  #  default_scope :active

  def self.find_andrew_user search_string
    u = self.find_by_andrewid search_string
    u ||= self.find_or_create_by( andrewid: CarnegieMellonPerson.
                                    find_by_andrewid( search_string )[:cmuandrewid] )
  rescue ActiveLdap::EntryNotFound
  end



#  def completed_seminars
#    self.registrations.credited.collect(&:seminar)
#  end


  scope :ffp_participants, -> (status) { where(:future_faculty_progress_status => Program::ProgressStatusType.find(status)) }

  scope :completed_future_faculty_requirements, -> {
    joins(:future_faculty_progress_status)
      .where(progress_status_types: { key: 'complete' })
      .where.not(future_faculty_enrollment_id: nil)
  }


  default_scope { order(created_at: :desc) }
  
  #filterrific(
  #  default_filter_params: { sorted_by: 'created_at_desc' },
  #  available_filters: [
  #    :sorted_by,
  #    :search_query,
  #    :with_created_at_gte
  #  ]
  #)

  scope :sorted_by, ->(sort_option) {
    direction = /desc$/.match?(sort_option) ? "desc" : "asc"
    case sort_option.to_s
    when /^name/
      order("LOWER(name) #{direction}")
    when /^created_at/
      order("created_at #{direction}")
    else
      raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
    end
  }

  def self.options_for_select
    order("LOWER(name)").map { |e| [e.observer.name, e.observer_id] }
  end
  scope :search_query, ->(query) {
    #where
  }

  scope :with_created_at_gte, ->(ref_datetime) {
    where("created_at > ?", DateTime.parse(ref_datetime).to_fs(:db))
  }

  def ffp_obs
    activities.where('memo_completed_on is not null and type="Participant::Activities::TeachingObservation"').size
  end

  def ffp_ecf
    activities.where('memo_completed_on is not null and type="Participant::Activities::EarlyCourseFeedback"').size
  end

  def ffp_micro
    activities.where('memo_completed_on is not null and type="Participant::Activities::MicroteachingWorkshop"').size
  end

  def ffp_lpr
    activities.where('memo_completed_on is not null and type="Participant::Activities::LessonPlanReview"').size
  end

  def ffp_csd
    activities.where('completed_on is not null and type="Participant::Activities::CourseAndSyllabusDesignProject"').size
  end

  def ffp_tp
    activities.where('completed_on is not null and type="Participant::Activities::TeachingStatementProject"').size
  end

  def ffp_seminar_size
    attended_seminars.size
  end

  def ffp_dei_size
    attended_seminars.with_tag("dei").size
  end

  # Rows for the participants table: same values as the ffp_* methods above,
  # but counted with one grouped query per column instead of per participant
  FFP_MEMO_COUNTS = {
    ffp_obs: 'Participant::Activities::TeachingObservation',
    ffp_ecf: 'Participant::Activities::EarlyCourseFeedback',
    ffp_micro: 'Participant::Activities::MicroteachingWorkshop',
    ffp_lpr: 'Participant::Activities::LessonPlanReview'
  }.freeze
  FFP_COMPLETED_COUNTS = {
    ffp_csd: 'Participant::Activities::CourseAndSyllabusDesignProject',
    ffp_tp: 'Participant::Activities::TeachingStatementProject'
  }.freeze

  def self.table_rows(participants)
    memo = Participant::Activity.where.not(memo_completed_on: nil)
                                .where(type: FFP_MEMO_COUNTS.values)
                                .group(:participant_id, :type).count
    completed = Participant::Activity.where.not(completed_on: nil)
                                     .where(type: FFP_COMPLETED_COUNTS.values)
                                     .group(:participant_id, :type).count
    seminar_ids = Seminar.without_tag("workshop").without_tag("other").pluck(:id)
    dei_ids = Seminar.where(id: seminar_ids).with_tag("dei").pluck(:id)
    attended = Registration.attended.group(:participant_id)
    seminars = attended.where(seminar_id: seminar_ids).count
    dei = attended.where(seminar_id: dei_ids).count

    participants.includes(:future_faculty_progress_status).map do |p|
      row = p.as_json(methods: %i[pretty_colleges pretty_depts ffp_status])
      FFP_MEMO_COUNTS.each { |k, type| row[k.to_s] = memo.fetch([p.id, type], 0) }
      FFP_COMPLETED_COUNTS.each { |k, type| row[k.to_s] = completed.fetch([p.id, type], 0) }
      row.merge('ffp_seminar_size' => seminars.fetch(p.id, 0),
                'ffp_dei_size' => dei.fetch(p.id, 0))
    end
  end
  

  
  #scope :created_before, ->(time) { where("created_at < ?", time)

#          <th>Last Change</th>
#        <th>Name</th>

#        <th>Andrew ID</th>
#        <th>Department</th>
#        <th>School</th>
#        <th>Student Class</th>
#        <th>FFP Graduation Date</th>
#        <th>FFP Status</th>
#        <th>First Consultation On</th>


#    scope s.status, -> { where( attendance_status: s ).
#                         joins( :seminar ).
#                         merge( Seminar.completed ) }
    #after_initialize do |p|
    #end

  #def ldap_entry_exists
  #  errors.add(:andrewid, 'does not exist at CMU') unless ldap
  #end

  validates :andrewid, presence: true
  validates :andrewid, uniqueness: true
  validate :ldap_entry_exists, on: :create, unless: -> { andrewid.blank? }
end
