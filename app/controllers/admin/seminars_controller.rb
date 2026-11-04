class Admin::SeminarsController < ApplicationController
  before_action :require_administrator

  def index
    @display_tag = Setting.find_by_key('admin-list-tag').value.downcase
    @expired_seminars = Seminar.past.with_tag( @display_tag )
    @offered_seminars = Seminar.registerable.open.with_tag( @display_tag )
    gusio_seminars = Seminar.registerable.open.with_tag("gusio")
    @offered_seminars = @offered_seminars + gusio_seminars
    @development_seminars = Seminar.closed

    @seminars = Seminar.all
    respond_to do |format|
      format.html
      format.json do
        render json: @seminars.to_json#(methods:
                                      #       %i[pretty_colleges pretty_depts ffp_status])
      end
      format.xlsx { response.headers.merge! file_export_headers }
    end

  end

  def new
    @update_url = { :action => "create" }
    @seminar = Seminar.new
    @seminar.start_at = '12:00:00'
    @seminar.end_at = '14:00:00'
    @seminar.seminar_tags.build( value: Setting.find_by_key( "default-tag" ).value.downcase)
    @seminar.seminar_status = Seminar::StatusType.find_by_key('closed')
    # TODO:
    #@default_tag = Setting.find_by_key( "default-tag" ).value

    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @update_url = update_whole_seminar_url
    @seminar = Seminar.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to seminars_path
  end


  def create
    @seminar = Seminar.new
    @seminar.assign_attributes( seminar_params )
    @seminar.start_at = nil if @seminar.is_async
    
    respond_to do |format|
      if @seminar.save
        format.html  { redirect_to(admin_seminar_path(@seminar),
                                   :success => '<strong>Seminar was successfully created.</strong>') }
        format.json  { render :json => @seminar,
          :status => :created, :location => @seminar }
      else

        format.html  { render :action => "new" }
        format.json  { render :json => @seminar.errors,
          :status => :unprocessable_entity }
      end
    end
  end


  def show
    @seminar = Seminar.find(params[:id])
    respond_to do |format|
      format.html
      format.pdf { render params[:profile] }
    end
  end

  def show_attendance
    @seminar = Seminar.find(params[:id])
    
    respond_to do |format|
      format.html
      format.pdf { render params[:profile] }
    end
  end

  def change_status
    r = Registration.find(params[:id])
    rs = Registration::WaitlistStatusType.find_by_key(params[:new_status])
    if params[:new_status] == "nil"
      r.destroy
    elsif r.waitlist_status != rs
      r.waitlist_status = rs
      if r.save && params[:new_status] == "confirmed" && r.seminar.end_at && r.seminar.end_at > Time.now
        ParticipantMailer.registration_confirmed_email( r.participant, r ).deliver
      end
    end

    #r.save
    #p params[:new_status]
    redirect_to admin_seminar_path(r.seminar)
  end

  def change_status_multiple
    @seminar = Seminar.find(params[:seminar])
    rs = Registration::WaitlistStatusType.find(params[:registration_status_key])
    selected = params[:participants].values
    selected.each do |aid|
      p = Participant.find_by_andrewid(aid)
      r = Registration.where(participant: p, seminar: @seminar).first()
      unless r.waitlist_status == rs
        r.waitlist_status = rs
        if r.save && rs.key == "confirmed" && r.seminar.end_at && r.seminar.end_at > Time.now
          ParticipantMailer.registration_confirmed_email( r.participant, r ).deliver
        end
      end
    end
    redirect_to admin_seminar_path(@seminar)
  end


  def change_attendance_status
    r = Registration.find(params[:id])
    as = Registration::AttendanceStatusType.find_by_key(params[:new_status])
    unless r.attendance_status == as
      r.attendance_status = as
      r.save
    end

    #r.save
    #p params[:new_status]
    redirect_to admin_seminar_path(r.seminar)
  end
  
  def change_attendance_status_multiple
    @seminar = Seminar.find(params[:seminar])
    as = Registration::AttendanceStatusType.find(params[:attendance_status_key])
    selected = params[:participants].values
    selected.each do |aid|
      p = Participant.find_by_andrewid(aid)
      r = Registration.where(participant: p, seminar: @seminar).first()
      unless r.attendance_status == as
        r.attendance_status = as
        r.save
      end
    end
    redirect_to seminar_attendance_path(@seminar)
  end
  
  def update
      logger.info params
      @seminar = Seminar.find(params[:id])
    
      if params[:attendance_status]
        registration = Registration.find(params[:registration_id])
        registration.attendance_status_id = params[:attendance_status]
        registration.save
      else

      @waitlists = CGI.parse(params[:waitlisted])['ids[]'].map{ |x| x.to_i }
      @registered = CGI.parse(params[:registered])['ids[]'].map { |x| x.to_i }
      logger.info "Waitlists: #{@waitlists}"
      logger.info "Registered #{@registered}"
      @waitlists.each do |w| 
        wtl = Registration.find(w)
        wtl.build_registration_status
        wtl.registration_status= Registration::WaitlistStatus.find_by_key('pending')
        wtl.save
      end 
      @registered.each do |r| 
        reg = Registration.find(r)
        confirmed = Registration::WaitlistStatus.find_by_key('confirmed')
        if reg and reg.registration_status != confirmed
        reg.build_registration_status
          reg.registration_status = confirmed
          if reg.save and reg.seminar.end_at > Time.now
            ParticipantMailer.registration_confirmed_email( reg.participant, reg ).deliver
          end
        end
       end 

       end #if attendance
  end

  def update_seminar
    @seminar = Seminar.find(params[:seminar][:id])
    @seminar.assign_attributes( seminar_params )
    @seminar.start_at = nil if @seminar.is_async
    @seminar.save!
    
    redirect_to admin_seminars_url
  end

  private
  def seminar_params
    if Current.user.admin?
      params.require(:seminar).permit(:id, :tags, :title, :description, :confirmed_email_insert, :pending_email_insert, :start_at, :is_async, :end_at, :enable_waitlist, :seminar_status_id, :maximum_capacity, :location )
    end
  end

  def file_export_headers
    filename = "Seminars-#{DateTime.now.to_fs(:db)}.xlsx"
    { 'Content-Disposition': "attachment; filename=\"#{filename}\"" }
  end

end
