class ActivitiesController < ApplicationController
  def new
    if params[:type] == 'Participant::Activities::Additional'
      @title = 'Add Other Activity/Consultation' 
    else
      req = Programs::FutureFaculty::Requirement.find params[:requirement_id]

      @title = req.label
    end

    @participant = Participant.find(params[:participant_id])
    @activity = @participant.activities.build(type: params[:type], future_faculty_requirement_id: params[:requirement_id])
  end

  def edit
    @activity = Participant::Activity.find params[:id]
    @title = "Editing #{@activity.title}"
    @participant = @activity.participant
    @url = activity_path(@activity)
  end

  def update
    @activity = Participant::Activity.find params[:id]
    @participant = @activity.participant
    @activity.update!(activity_params)
    @activity.save!
    respond_to do |format|
      format.turbo_stream do
        
        render turbo_stream:
                 [
                   turbo_stream.update(
                    'activities',
                    partial: 'activities/activities',
                    locals: { participant: @participant }),
                   turbo_stream.update(
                    'ffp_activities',
                    partial: 'activities/future_faculty_program',
                    locals: { participant: @participant }),
                  turbo_stream.update("modal","")
                 ]
      end

      format.html do
        redirect_to participant_path(@participant), success: "Created activity #{@activity.title}." 
      end
    end
  end
  
  def create
    @participant = Participant.find(params[:participant_id])
    @activity = @participant.activities.build(activity_params)
    @activity.save!
    @participant = Participant.find(params[:participant_id])
    respond_to do |format|
      format.turbo_stream do
        
        render turbo_stream:
                 [turbo_stream.update(
                    'activities',
                    partial: 'activities/activities',
                    locals: { participant: @participant }),
                  turbo_stream.update(
                    'ffp_activities',
                    partial: 'activities/future_faculty_program',
                    locals: { participant: @participant }),
                  turbo_stream.update("modal","")
                 ]
      end

      format.html do
        redirect_to participant_path(@participant), success: "Created activity #{@activity.title}." 
      end
    end

  end          
        #redirect_to participante_path(@participant), success: "Created activity #{@activity.title}.", 
        #render turbo_stream: [
                 #turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Profile updated" }),
                 #turbo_stream.update("", partial: "users/about", locals: { user: current_user })
         #        turbo_stream.update("modal","")
         #      ]


  def destroy
    a = Participant::Activity.find(params[:id])
    @participant = a.participant
    a.destroy!
    respond_to do |format|
      format.turbo_stream do
              render turbo_stream:
                 [turbo_stream.update(
                    'activities',
                    partial: 'activities/activities',
                    locals: { participant: @participant }),
                  turbo_stream.update(
                    'ffp_activities',
                    partial: 'activities/future_faculty_program',
                    locals: { participant: @participant }),
                 ]
      end
      format.html do
        flash[:success] = "Activity #{a.title} Successfully Destroyed."
        redirect_to participant_path(p)
      end
    end
  end
  
  private
  def activity_params
    params.require(:activity).permit(:id, :title, :description, :lead_consultant_id,:type, :completed_on, :future_faculty_requirement_id, :observer_id, :memo_completed_on, :internal_notes, :course, :first_consultation_on)
  end
  #def edit_params
  #  params.require(:participant_activities_additional).permit(:id, :title, :description, :lead_consultant_id,:type, :completed_on)
    
  #end

end
