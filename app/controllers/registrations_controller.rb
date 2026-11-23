# frozen_string_literal: true

class RegistrationsController < ApplicationController
  include Pagy::Backend

  before_action :require_authentication, only: %i[index create destroy]

  # Administrators get everyone's registrations; everyone else gets their own
  # coming up (My Registrations)
  def index
    return mine unless Current.user.admin?

    @q = params[:q].to_s.strip
    registrations = Registration.includes(:waitlist_status, :attendance_status,
                                          seminar: :seminar_tags,
                                          participant: :future_faculty_progress_status)
                                .order(updated_at: :desc)
    if @q.present?
      like = "%#{Registration.sanitize_sql_like(@q)}%"
      registrations = registrations.joins(:participant, :seminar)
                                   .where('participants.name LIKE :like OR participants.andrewid LIKE :like ' \
                                          'OR seminars.title LIKE :like', like:)
    end

    respond_to do |format|
      format.html { @pagy, @registrations = pagy(registrations, items: 50) }
      format.xlsx do
        @registrations = registrations
        response.headers['Content-Disposition'] = 'attachment; filename="Participant-Registrations.xlsx"'
      end
    end
  end

  def create
    @seminar = Seminar.find(params[:seminar_id])
    Current.user.admin? && params.key?(:participants) ? register_attendees : register_self
  end

  def destroy
    registration = Registration.find(params[:id])
    return redirect_to(root_path) unless Current.user.admin? || registration.participant == Current.user

    ParticipantMailer.canceled_registration_email(registration).deliver
    registration.destroy
    redirect_back_or_to root_path, notice: "You canceled your registration for #{registration.seminar.title}."
  end

  private

  def mine
    @registrations = Current.user.registrations.present_seminars
                            .includes(:waitlist_status, :seminar).order('seminars.start_at')
    render :mine
  end

  # A signed-in participant asks for a seat: confirmed, or waitlisted when
  # the seminar has a waitlist
  def register_self
    return redirect_to(root_path, alert: "#{@seminar.title} isn't open for registration.") unless @seminar.open?

    status = Registration::WaitlistStatusType.find_by!(key: @seminar.enable_waitlist? ? 'pending' : 'confirmed')
    registration = Registration.new(seminar: @seminar, participant: Current.user, waitlist_status: status)
    unless registration.save
      return redirect_to(root_path, alert: registration.errors.full_messages.to_sentence)
    end

    if registration.pending?
      ParticipantMailer.registration_pending_email(Current.user, registration).deliver
      redirect_to root_path, notice: "You asked for a seat in #{@seminar.title}. You're on the waitlist until the Eberly Center confirms it."
    else
      ParticipantMailer.registration_confirmed_email(Current.user, registration).deliver
      redirect_to root_path, notice: "You registered for #{@seminar.title}."
    end
  end

  # An administrator records attendance for a list of Andrew IDs: each is
  # registered, confirmed and marked attended
  def register_attendees
    confirmed = Registration::WaitlistStatusType.find_by!(key: 'confirmed')
    attended = Registration::AttendanceStatusType.find_by!(key: 'attended')
    added = []
    failed = []
    params[:participants].to_s.split(/[\s,]+/).map(&:downcase).compact_blank.uniq.each do |andrewid|
      participant = Participant.find_or_initialize_by(andrewid:)
      if participant.new_record?
        next failed << andrewid unless participant.save

        participant.update_ldap_attrs
      end
      registration = Registration.find_or_initialize_by(seminar: @seminar, participant:)
      registration.assign_attributes(waitlist_status: confirmed, attendance_status: attended)
      registration.save ? added << andrewid : failed << andrewid
    end

    flash[:notice] = "Marked #{added.size} #{'person'.pluralize(added.size)} attended." if added.any?
    flash[:alert] = "Couldn't add #{failed.to_sentence}." if failed.any?
    redirect_to attendance_admin_seminar_path(@seminar)
  end
end
