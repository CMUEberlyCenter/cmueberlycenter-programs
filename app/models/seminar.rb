class Seminar < ApplicationRecord
  include Seminar::Common

  default_scope { order(start_at: :asc) }

  def self.core_indicia = '*'

  belongs_to(:seminar_status,
             -> { readonly },
             class_name: 'Seminar::StatusType',
             inverse_of: :seminars)

  has_many(:registrations,
           -> { includes :participant },
           inverse_of: :seminar,
           dependent: :restrict_with_error)

  has_many :seminar_tags, class_name: 'Seminar::Tag', dependent: :destroy

  def tags = seminar_tags.map(&:value).map(&:downcase)

  def tags=(new_tags)
    return unless new_tags.is_a? String

    new_tags = new_tags.split(',').map(&:strip).map(&:downcase)

    # Destroy existing tags not in new tags
    (tags - new_tags).each { |t| seminar_tags.destroy_by(value: t) }

    # Add tags in new_tags not in existing tags
    (new_tags - tags).each { |t| seminar_tags.build(value: t) }
  end

  def title_with_indicia = "#{title}#{Seminar.core_indicia if core?}"
  def core? = tags.include? 'core'



  def confirmed_registrations_size
    return 0 unless self.registrations && self.registrations.confirmed
    return self.registrations.confirmed.size
  end

  def attended_registrations_size
    return 0 unless self.registrations && self.registrations.attended
    return self.registrations.attended.size
  end



  def self.confirmed_for( participant )
    self.status_for( "confirmed", participant )
  end

  def self.pending_for( participant )
    self.status_for( "pending", participant )
  end

  def self.status_for( status, participant )
    joins(:registrations).where(
      "registrations.participant_id = ? and " +
      "registrations.waitlist_status_id = ?",
      participant.id,
      Registration::WaitlistStatusType.find_by_key( status ).id
    )
  end





  def self.unrequested_by( participant )
    if participant.blank?
      all
    else
      select{ |s| s.registrations.find_by_participant_id( participant) == nil }
    end
  end



  validates :title, :presence => true

  #named_scope :confirmed, lambda {|participant| {:conditions => {:author_id => author.id}}}


  def async?
    self.is_async
  end

  def registration_for(p)
    self.registrations.where(participant: p).first
  end


  def formatted_timespan
    if self.start_at && self.end_at
      start_format = "%A, %B %e, %Y %l:%M%P "
      end_format = if self.start_at.to_date == self.end_at.to_date
                     "%-l:%M%P"
                   else
                     " " + start_format
                   end
      "#{self.start_at.strftime(start_format)}&ndash;\
        #{self.end_at.strftime(end_format)}".html_safe
    else
      end_format = "Available until %A, %B %e, %Y %l:%M"
      self.end_at.strftime(end_format)
    end
  end

  def formatted_timespan_short
    start_format = "%b %e %Y"
    self.start_at.strftime(start_format)
  end

  def seminar_params
    params.require(:seminar).permit!
  end
end
