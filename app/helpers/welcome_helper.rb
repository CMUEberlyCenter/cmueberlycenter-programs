module WelcomeHelper
  def greeting
    if Current.user
      content_tag(:h1, "Welcome, #{Current.user.name}!")
    else
      content_tag(:h1, "Participate in Seminars and Workshops")
    end
  end

  def filterable_list(seminar_groups)
    render("seminars/filterable_list",
           seminar_groups: seminar_groups,
           no_results_message: "No seminars match the filter criteria.")
  end

  def admin_options(seminar)
    opts = "" +
    link_to("Edit",
            edit_admin_seminar_url(seminar), class: 'cta') + "<br/>" +
    link_to("Manage Registrations",
            admin_seminar_url(seminar), class: 'cta') + '<br/>' +
    link_to("Manage Attendance",
            seminar_attendance_url(seminar), class: 'cta') + '<br/><br/>' +
    "#{admin_registrations_summary(seminar)}"
    opts.html_safe
  end

  def registration_options(seminar)
    return unless seminar.open?
    registration = Current.user.registrations.find_by(seminar: seminar)

    note = ""
    if Current.user.registrations.map{|s| s.title}.include? seminar.title
      note = "<p><strong>Note:</strong> it is likely you may have already taken this seminar. Please check your past enrollments to make sure you want to attend this seminar.</p>"
    end
    accomodations_link = link_to('Request Accomodations',
                                 "mailto:seminars@eberly.cmu.edu?subject=Accomodations%20Request%20for%20#{seminar.title}",
                                 target: :blank,
                                 class: 'btn ghost')

    if registration && registration.confirmed?
      button_to('Cancel Confirmed Registration',
                registration_path(registration),
                method: :delete,
                remote: false) + '  '+accomodations_link + raw(" #{note}")

    elsif registration && registration.pending?
      button_to('Cancel Pending Registration',
                registration_path(registration),
                method: :delete,
                remote: false) + '  '+accomodations_link + raw(" #{note}")
    else
      button_to('Request Registration',
                seminar_registrations_path(seminar_id: seminar.id),
                method: :post,
                remote: false) + raw(" #{note}")
    end
  end

  def guest_options(seminar)
    return unless seminar.open?
    link_to( 'Sign in to Register',
             login_url,
             class: 'cta')
  end

  private

  def admin_registrations_summary(seminar)
    return unless seminar.open?
    "Registrations: <strong>#{seminar.registrations.size}</strong> \
    (Pending: <strong>#{seminar.registrations.pending.size} + </strong> \
    Confirmed: <strong>#{seminar.registrations.confirmed.size}</strong> ),\
    Attended: <strong>#{seminar.registrations.attended.size}</strong>"
  end
end
