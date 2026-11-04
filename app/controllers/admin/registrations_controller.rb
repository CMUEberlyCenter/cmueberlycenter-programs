class Admin::RegistrationsController < ApplicationController
  before_action :require_administrator

  def new
    @registration = Registration.new(params[:registration])
    @registration_type = params[:type]
    @registration.registration_status = RegistrationStatus.find_by_key('confirmed')
    #@registration.attendance_status = AttendanceStatus.find_by_key('attended')
  end

  def create
    if params[:eppns] && params[:eppns] != ""
      @errors = []
      @eppns = params[:eppns].split(",")
      
      begin
        @registration = Registration.new( registration_params )
        @registration.seminar_id = params[:seminar_id]
       
        @eppns.each do |e|
          p = Participant.find_andrew_user e
          if p
            r = Registration.where(participant: p, seminar_id: params[:seminar_id])
            if r && r.size == 1
              r = r.first
            else
              r = Registration.new( registration_params )
              r.seminar_id = params[:seminar_id]
              r.participant = p
            end
            r.attendance_status = AttendanceStatus.find_by_key('attended')
            unless r.save
              @errors.push(e)
            end
          else
            @errors.push(e)
          end
          
        end
        notice = 'Registrations created.'
        if @errors != []
          notice = 'Error processing: ' + @errors.join(", ")
        end
        respond_to do |format|
          format.html { redirect_to(admin_seminar_path(@registration.seminar), :notice => notice) }
        end
      #rescue
      #  redirect_to(admin_seminar_path(params[:seminar_id]), :notice => 'Error processing: ' + @eppns.join(",") + ' ' + @errors.join(", "))
      end
    else
      begin
        @registration = Registration.new( registration_params )
        @registration.seminar_id = params[:seminar_id]
        #@registration.attendance_status = AttendanceStatus.find_by_key('attended')
        
        respond_to do |format|
          if @registration.save
            if @registration.seminar.start_at > Time.now
              ParticipantMailer.registration_confirmed_email( @registration.participant, @registration ).deliver
            end
            format.html { redirect_to(admin_seminar_path(@registration.seminar), :notice => 'Registration created.') }
            format.js  
          else
            format.html { render :action => "new" }  
            format.js  
          end  
        end  
      rescue
        redirect_to(admin_seminar_path(params[:seminar_id]), :notice => 'Invalid AndrewID')
        #redirect_to(admin_seminar_path(params[:seminar_id]), :notice => params[:eppns])
        #render :controller => 'admin/seminars', :action =>"new" ,:notice => 'Invalid AndrewID'
      end 
    end
  #rescue
  #  redirect_to(admin_seminar_path(params[:seminar_id]), :notice => 'Error')
  end
  
  private
  def registration_params
    if current_user.admin?
      params.require(:registration).permit(:id, :seminar, :seminar_id, :participant_id, :registration_status_id, :attendance_status_id, :search_string)
    end
  end
end
