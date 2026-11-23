Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'welcome#index'

  # External navigation items
  direct :eberly do
    '//www.cmu.edu/teaching'
  end
  direct :eberly_future_faculty_program do
    '//www.cmu.edu/teaching/graduatestudentsupport/futurefacultyprogram.html'
  end
  direct :eberly_graduate_students do
    '//www.cmu.edu/teaching/services/graduate-students/index.html'
  end
  direct :contact_email do |options|
    params = options.map { |k,v| "#{k}=#{v}" }.join('&')
    params.prepend('?') unless params.blank?
    "mailto:seminars@eberly.cmu.edu#{params}"
  end

  # Shibboleth logout path (with optional return url)
  direct :sso_logout, return_url: nil do |options|
    if Rails.env.staging? || Rails.env.production?
      "/Shibboleth.sso/Logout?return=#{options[:return_url]}"
    else
      options[:return_url] || root_url
    end
  end

  # Session management
  scope module: :sessions do
    get 'login'
    get 'logout'
    post 'impersonate/:participant_id', as: :impersonate, action: :impersonate
    get 'unimpersonate'
  end

  # Application settings
  resources :settings, only: [:index, :update]

  # Future faculty program management
  scope module: :programs do
    resource :future_faculty, path: 'future-faculty', only: [] do
      member do
        get :index
        scope ':participant_id' do
          patch :enroll
          patch :unenroll
          patch :graduate
          patch :ungraduate
          patch :drop
          patch :undrop
          patch :reenroll
        end
      end
    end
  end

  # Participants resource route
  resources :participants, except: :new do
    get 'search', on: :collection
    resources :activities, shallow: true
  end

  # Direct link to a participant's own resource
  get 'profile', to: 'participants#show', as: :profile




  resources :seminars do
    resources :registrations, shallow: true
  end
  get 'registrations', to: 'registrations#index', :as => 'registrations'  


  patch 'admin/seminars/update_seminar' => 'admin/seminars#update_seminar', :as => 'update_whole_seminar'
  get 'admin/seminars/:id/attendance' => 'admin/seminars#show_attendance', :as => 'seminar_attendance'

  patch 'admin/seminars/change_status' => 'admin/seminars#change_status', :as => 'change_registration_status'
  patch 'admin/seminars/change_status_multiple' => 'admin/seminars#change_status_multiple', :as => 'change_registration_status_multiple'

  patch 'admin/seminars/change_attendance_status' => 'admin/seminars#change_attendance_status', :as => 'change_attendance_status'
  patch 'admin/seminars/change_attendance_status_multiple' => 'admin/seminars#change_attendance_status_multiple', :as => 'change_attendance_status_multiple'



  namespace :admin do
    root '/seminars#index'
    # Directs /admin/seminars/* to Admin::SeminarController
    # (app/controllers/admin/seminars_controller.rb)
    resources :seminars

  end
end
