# frozen_string_literal: true

# Made-up data for a demo in development: seminars from last semester and
# this one, registrations, attendance and Future Faculty Program
# participants at each stage, all with the made-up people in
# config/demo_directory.yml. Run after db:prepare:
#
#   bin/rails db:prepare demo:seed
#
# Refuses outside development and on a database with anyone not in the
# made-up directory. Running it again changes nothing.
namespace :demo do
  desc 'Load made-up seminars, people and records for a development demo'
  task seed: :environment do
    abort 'demo:seed runs only in development.' unless Rails.env.development?

    made_up = Participant::DemoPerson.entries.map(&:uid)
    others = Participant.where.not(andrewid: made_up).count
    abort "demo:seed stopped: the database has #{others} people who aren't made up." if others.positive?

    load Rails.root.join('db/seeds.rb')
    DemoData.new.load
    puts "Loaded the demo: #{Seminar.count} seminars, #{Participant.count} people, " \
         "#{Registration.count} registrations, #{Participant::Activity.count} activities."
  end
end

# Builds the demo's records; each step finds what's there before adding
class DemoData
  SEMINARS = [
    # [title, tags, days from today, hours, location]
    ['Designing Your First Course', 'core', -80, [12, 14], 'Tepper Quad 1310'],
    ['Active Learning in Large Classes', 'core', -73, [12, 14], 'Tepper Quad 1310'],
    ['Inclusive Teaching Strategies', 'core, dei', -66, [16, 18], 'Gates Hillman Center 6115'],
    ['Leading Effective Discussions', 'core', -59, [12, 14], 'Tepper Quad 1310'],
    ['Grading With Rubrics', 'seminar', -52, [12, 14], 'Tepper Quad 1310'],
    ['Recognizing and Reducing Bias in the Classroom', 'dei', -45, [16, 18], 'Cohon University Center, Rangos 2'],
    ['Giving Feedback on Student Writing', 'seminar', -38, [12, 14], 'Baker Hall A53'],
    ['Teaching With Generative AI', 'seminar', -31, [12, 14], 'Tepper Quad 1310'],
    ['Writing a Teaching Statement', 'workshop', -24, [10, 12], 'Tepper Quad 1310'],
    ['Student Well-Being in the Classroom', 'dei', -17, [12, 14], 'Baker Hall A53'],
    ['Microteaching Workshop', 'workshop', -10, [9, 12], 'Tepper Quad 1310'],
    ['Engaging Students on the First Day', 'core', 9, [12, 14], 'Tepper Quad 1310'],
    ['Assessing Student Learning', 'core', 16, [12, 14], 'Tepper Quad 1310'],
    ['Universal Design for Learning', 'dei', 23, [16, 18], 'Gates Hillman Center 6115'],
    ['Making the Most of Office Hours', 'seminar', 51, [12, 13], 'Baker Hall A53'],
    ['Course Design Institute', 'other', 58, [9, 16], 'Tepper Quad 1310']
  ].freeze

  ASYNCHRONOUS = [
    ['Teaching at CMU: A Self-Paced Introduction', 'core', 60],
    ['Accessible Course Materials', 'dei', 90]
  ].freeze

  DESCRIPTIONS = {
    'core' => 'One of the core seminars on teaching practice. Bring a course you teach or hope to teach.',
    'dei' => 'Ways to make a course work for every student, with examples from CMU courses.',
    'workshop' => 'A hands-on session: you leave with a draft and feedback on it.',
    'other' => 'A program outside the seminar series, open to graduate students and postdocs.',
    'seminar' => 'A seminar on one part of teaching, with time to try it out.'
  }.freeze

  STUDENTS = %w[am00 hf00 hs00 an00 ap00 ah00 tb00 rd00 jw00 rw00 rc00 hh00 aw00 hc00 tm00 pm00 jh00 rm00 as00].freeze

  def load
    @open = Seminar::StatusType.find_by!(key: 'open')
    @closed = Seminar::StatusType.find_by!(key: 'closed')
    @confirmed = Registration::WaitlistStatusType.find_by!(key: 'confirmed')
    @pending = Registration::WaitlistStatusType.find_by!(key: 'pending')
    @attended = Registration::AttendanceStatusType.find_by!(key: 'attended')
    @absent = Registration::AttendanceStatusType.find_by!(key: 'absent')

    settings
    staff
    people = STUDENTS.index_with { |id| person(id) }
    seminars = SEMINARS.map { |row| seminar(*row) } + ASYNCHRONOUS.map { |row| asynchronous(*row) }
    registrations(people, seminars)
    future_faculty(people)
  end

  private

  def today = Time.zone.today

  def settings
    { 'admin-list-tag' => 'core, dei, seminar, workshop', 'default-tag' => 'seminar' }.each do |key, value|
      Setting.find_by!(key:).update!(value:)
    end
    {
      'homepage-participant' => ['Home page note',
                                 '<p>Seminars and workshops on teaching for graduate students and postdocs. ' \
                                 'Register for any program below; the Future Faculty Program counts the ones ' \
                                 'you attend.</p>'],
      'sidebar-participant' => ['Sidebar note for signed-in participants',
                                '<p>Questions? Email seminars@eberly.cmu.edu.</p>']
    }.each do |key, (label, value)|
      Setting.find_or_create_by!(key:) { |s| s.assign_attributes(label:, value:) }
    end
  end

  def staff
    person('ac00').update!(is_admin: true)
    person('mm00').update!(is_admin: true, is_consultant: true)
    person('lc00').update!(is_consultant: true)
  end

  def person(andrewid)
    participant = Participant.find_or_create_by!(andrewid:)
    participant.update_ldap_attrs if participant.name(fallback: false).blank?
    participant
  end

  def seminar(title, tags, days, hours, location)
    Seminar.find_or_create_by!(title:) do |s|
      day = today + days
      s.start_at = Time.zone.local(day.year, day.month, day.day, hours.first)
      s.end_at = Time.zone.local(day.year, day.month, day.day, hours.last)
      s.tags = tags
      s.location = location
      s.description = "<p>#{DESCRIPTIONS.fetch(tags.split(',').first)}</p>"
      s.maximum_capacity = 30
      s.enable_waitlist = title == 'Course Design Institute'
      s.seminar_status = days.negative? || title == 'Making the Most of Office Hours' ? @closed : @open
    end
  end

  def asynchronous(title, tags, days)
    Seminar.find_or_create_by!(title:) do |s|
      s.is_async = true
      s.end_at = (today + days).in_time_zone.change(hour: 23, min: 59)
      s.tags = tags
      s.description = "<p>#{DESCRIPTIONS.fetch(tags.split(',').first)} Take it on your own schedule.</p>"
      s.seminar_status = @open
    end
  end

  # Past seminars: most students attended some, a few were absent. Coming
  # ones: confirmed seats and a waitlist.
  def registrations(people, seminars)
    seminars.each_with_index do |seminar, n|
      people.values.each_with_index do |participant, i|
        next unless (i + n).odd? || (i % 4).zero?

        past = seminar.end_at < Time.zone.now
        Registration.find_or_create_by!(seminar:, participant:) do |r|
          r.waitlist_status = seminar.enable_waitlist? && (i / 2).odd? ? @pending : @confirmed
          r.attendance_status = ((i + n) % 7).zero? ? @absent : @attended if past
        end
      end
    end
    # Herbert Simon and Allen Newell attended every past seminar; Andrew
    # Mellon all but the workshops
    Seminar.past.find_each do |seminar|
      %w[hs00 an00 am00].each do |id|
        next if id == 'am00' && seminar.tag?('workshop')

        registration = Registration.find_or_initialize_by(seminar:, participant: people.fetch(id))
        registration.update!(waitlist_status: @confirmed, attendance_status: @attended)
      end
    end
  end

  def future_faculty(people)
    consultant = Participant.find_by!(andrewid: 'mm00')
    v2023 = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2023')
    v2015 = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2015')

    # [andrewid, version, activities, final status]
    [
      ['am00', v2023, %i[overview observation], nil],
      ['hs00', v2023, %i[overview observation observation syllabus statement], 'graduated'],
      ['an00', v2023, %i[overview observation feedback syllabus statement], nil],
      ['ap00', v2023, %i[overview], nil],
      ['tb00', v2015, %i[overview observation syllabus], nil],
      ['ah00', v2023, %i[overview], 'dropout']
    ].each do |andrewid, version, kinds, status|
      participant = people.fetch(andrewid)
      next if participant.future_faculty_enrollment

      participant.update!(future_faculty_enrollment: version, first_consultation_on: today - 200,
                          future_faculty_progress_status: ProgressStatusType.find('incomplete'))
      kinds.each_with_index { |kind, i| activity(participant, kind, consultant, today - 180 + (i * 30)) }
      participant.reload.save!
      next unless status

      participant.update!(future_faculty_progress_status: ProgressStatusType.find(status),
                          future_faculty_program_graduated_on: status == 'graduated' ? today - 20 : nil)
    end
  end

  def activity(participant, kind, consultant, day)
    type, attributes = {
      overview: ['Additional', { title: 'FFP Overview', description: 'Went over the program and its requirements.',
                                 lead_consultant: consultant, completed_on: day }],
      observation: ['TeachingObservation', { course: '09-105 Introduction to Modern Chemistry I', observer: consultant,
                                             completed_on: day, memo_completed_on: day + 7 }],
      feedback: ['EarlyCourseFeedback', { course: '15-112 Fundamentals of Programming', observer: consultant,
                                          completed_on: day, memo_completed_on: day + 5 }],
      syllabus: ['CourseAndSyllabusDesignProject', { course: '85-102 Introduction to Psychology', lead_consultant: consultant,
                                                     first_consultation_on: day - 30, completed_on: day }],
      statement: ['TeachingStatementProject', { lead_consultant: consultant, first_consultation_on: day - 20,
                                                completed_on: day }]
    }.fetch(kind)
    class_name = "Participant::Activities::#{type}"
    requirement = Programs::FutureFaculty::Requirement.find_by(activity_class: class_name,
                                                                requirements_version: participant.future_faculty_enrollment)
    participant.activities.create!(type: class_name, future_faculty_requirement: requirement, **attributes)
  end
end
