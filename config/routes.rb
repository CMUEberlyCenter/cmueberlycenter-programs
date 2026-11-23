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

  # Signing in: developer sign-in in development and test, drawn only there
  # (DevSessionsController refuses everywhere else too). In production /login
  # says sign-in isn't set up; single sign-on (Entra ID) goes there later.
  direct(:login) do |options|
    query = options.slice(:return_to).compact
    "/login#{"?#{query.to_query}" if query.any?}"
  end
  if DemoMode.on?
    match 'login', to: 'dev_sessions#new', as: :dev_login, via: %i[get post]
    post 'login/:andrew_id', to: 'dev_sessions#create', as: :dev_login_as
  else
    match 'login', to: 'sessions#new', via: %i[get post], as: nil
  end
  get 'logout', to: 'sessions#destroy'
  delete 'logout', to: 'sessions#destroy'

  # An administrator acting as someone else (the kit's Acting as Another User)
  post 'participants/:participant_id/act-as', to: 'sessions#create_acting', as: :act_as
  post 'stop-acting', to: 'sessions#destroy_acting', as: :stop_acting

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

  # Participants: administrators see everyone; anyone signed in sees their
  # own record at /profile
  resources :participants, only: %i[index show create update] do
    get 'search', on: :collection
    get 'record', on: :member
    resources :activities, only: %i[new create edit update destroy], shallow: true
  end
  get 'profile', to: 'participants#record', as: :profile

  resources :seminars, only: %i[index destroy] do
    resources :registrations, only: :create
  end
  resources :registrations, only: %i[index destroy]

  # Running seminars: registrations, attendance and the sign-in sheet
  namespace :admin do
    get '/', to: redirect('/seminars')
    resources :seminars, only: %i[new create show edit update] do
      member do
        get :attendance
        get 'sign-in-sheet', action: :sign_in_sheet, as: :sign_in_sheet
        patch :statuses
        patch :attendances
      end
    end
    resources :registrations, only: [] do
      member do
        patch :status
        patch :attendance
      end
    end
  end

  get 'up', to: 'rails/health#show', as: :rails_health_check
end
