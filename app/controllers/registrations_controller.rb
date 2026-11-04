class RegistrationsController < ApplicationController
  include Pagy::Backend

  before_action :require_administrator, except: [:create, :destroy]

  def index
    respond_to do |format|
      format.html do
        @pagy, @registrations = pagy(
          Registration.includes(:participant, :seminar).order(updated_at: :desc),
          items: 50
        )
      end
      format.js
      format.xlsx do
        @registrations = Registration.all
        response.headers['Content-Disposition'] = 'attachment; filename="Participant-Registrations.xlsx"'
      end
    end
  end

  def new
    @seminar = Seminar.find(params[:seminar_id])
    @seminar.registrations.build
  end

  # TODO: Add to calendar link?
  def create
    if Current.user.admin?
      @seminar = Seminar.find(params[:seminar_id])
      @uids = ""
      @bad_uids = ""
      ws = Registration::WaitlistStatusType.find_by_key('confirmed')
      as = Registration::AttendanceStatusType.find_by_key('attended')
      params[:participants].to_s.split(',').map { |uid| uid.strip.downcase }.reject(&:blank?).uniq.each do |uid|
        p = Participant.find_or_initialize_by(andrewid: uid)
        if p.new_record?
          unless p.save
            @bad_uids += "<li>#{ERB::Util.html_escape(uid)}</li>"
            next
          end
          p.update_ldap_attrs
        end

        r = Registration.new(seminar: @seminar, waitlist_status: ws, attendance_status: as, participant: p)
        if r.save
          @uids += "<li>#{ERB::Util.html_escape(p.name)} (#{ERB::Util.html_escape(uid)})</li>"
        else
          @bad_uids += "<li>#{ERB::Util.html_escape(uid)}</li>"
        end
      end
      
      #flash[:success] = "<div><h2>Bulk Registrations:</h2><ul>#{uids}</ul></div>"
      #redirect_to seminar_path(seminar)
      render 'seminars/show'
    else
      seminar = Seminar.find(params[:seminar_id])
      status_key = seminar.enable_waitlist? ? 'pending' : 'confirmed'
      status = Registration::WaitlistStatusType.find_by_key( status_key || 'pending' )
      #status = Registration::WaitlistStatusType.find_by_key( 'pending' )
      #status = Registration::WaitlistStatusType.find_by_key( 'confirmed' )

      r = Registration.new(seminar: seminar, waitlist_status: status)
      r.save
      accomodations_url = contact_email_url(subject: "Accomodations%20Request%20for%20#{r.title}")
      accomodations_link = "<a href=\"#{accomodations_url}\" class=\"cta\" target=\"blank\">Request Accomodations</a>"
      flash[:success] = "<strong>Successfully requested registration for #{r.title}.</strong><br/>#{accomodations_link}"
      
      if seminar.enable_waitlist?
        ParticipantMailer.registration_pending_email( Current.user,r).deliver
      else
        ParticipantMailer.registration_confirmed_email( Current.user, r).deliver
      end
      
      #respond_to do |format|
      #format.js
      #  format.html { redirect_to root_url }
      #end
      redirect_to root_url
    end

  end

  def destroy
    #Current.user.cancel_registration( params[:id] )

    #registration = self.registrations.find( registration_id )
    registration = Registration.find(params[:id])
    registration_copy = registration.clone
    registration.destroy
    #registration.registration_status = RegistrationStatus.find_by_key "cancelled"
    #registration.save
    ParticipantMailer.canceled_registration_email( registration_copy ).deliver
    flash[:success] = "<strong>Canceled your seminar registration for #{registration.title}.</strong>"
    respond_to do |format|
      #format.js
      format.html { redirect_to root_url }
    end
  end 

end
