class Registration < ApplicationRecord
  include Seminar::Common

  scope :with_seminar_tag, -> (tag) { joins(:seminar).with_tag(tag) }
  scope :seminar_in_days, lambda { |n = 2|
    joins(:seminar).in_days(n)
  }
  scope :present_seminars, -> { joins(:seminar).present }
  scope :past_seminars, -> { joins(:seminar).past }
  Seminar::StatusType.find_each do |s|
    # Scopes Registration.open_seminars, etc.
    scope "#{s.key}_seminars", -> { joins(seminar: s.key.to_sym) }
  end
  
  Registration::WaitlistStatusType.find_each do |s|
    # Scopes Registration.pending, Registration.confirmed, etc.
    scope s.key, -> { where(waitlist_status: s) }

    # Methods r.pending?, r.confirmed?, etc.
    define_method("#{s.key}?") { waitlist_status.key == s.key.to_s }
  end

  Registration::AttendanceStatusType.find_each do |s|
    # Scopes Attendance.pending, Registration.confirmed, etc.
    scope s.key, -> { where(attendance_status: s) }

    # Methods r.attended?, r.absent?, etc.
    define_method("#{s.key}?") { attendance_status && attendance_status.key == s.key }
  end

  belongs_to :participant, default: -> { Current.user }
  belongs_to :seminar
  belongs_to :waitlist_status, class_name: 'Registration::WaitlistStatusType'
  belongs_to :attendance_status, class_name: 'Registration::AttendanceStatusType', optional: true

  has_many :seminar_tags, through: :seminar







  def search_string
  end

  def search_string=(search)
    participant=Participant.find_by_andrewid(search)
    CarnegieMellonPerson.find_by_andrewid(search)

    participant||=Participant.new(:andrewid =>search, :is_admin => false)
    participant.save!
    self.participant_id = Participant.find_by_andrewid(search).id
    #self.participant_id=64

  end



  #filterrific(
  #  default_filter_params: { sorted_by: 'created_at_desc' },
  #  available_filters: [
  #    :sorted_by,
  #    :search_query,
  #    :with_seminar,
  #    :with_created_at_gte,
  #    :with_waitlist_status
  #  ]
  #)

  scope :sorted_by, ->(sort_option) {
    direction = /desc$/.match?(sort_option) ? "desc" : "asc"
    case sort_option.to_s
    when /^created_at/
      order("LOWER(created_at) #{direction}")
    else
      raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
    end
  }

  def self.options_for_select
    order("LOWER(name)").map { |e| [e.observer.name, e.observer_id] }
  end
  scope :search_query, ->(query) {

  }
  scope :with_created_at_gte, ->(ref_date) {

  }
  scope :with_waitlist_status, -> (s) { where(waitlist_status: s) }

  validates :participant, :presence => true
  validates :participant_id, uniqueness: { scope: :seminar_id,
                                        message: "You have already registered for this seminar." }

  # Delegate any unknown method to the registration's seminar
  def method_missing(method, *args)
    return seminar.send(method,*args) if seminar.respond_to?(method)
    super
  end


  #validates_uniqueness_of :participant_id, :scope => [:seminar_id]
end
