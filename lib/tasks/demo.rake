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

  # Full descriptions for the programs open now: an overview, what you'll
  # do and who leads it, at the length of a real catalog entry
  DETAILS = {
    'Engaging Students on the First Day' => [
      'The first day of class sets expectations for the whole semester. Students decide quickly whether a course ' \
      'will be worth their effort, whether they belong in it and how much the instructor cares about their learning.',
      'This seminar looks at what research says about first impressions in the classroom and walks through ' \
      'first-day plans from CMU courses in several disciplines. You will draft your own plan and get feedback on it ' \
      'from other participants.',
      ['Plan a first day that introduces the course, its goals and you',
       'Choose activities that let students meet each other and the material',
       'Set norms for participation, questions and feedback',
       'Leave with a draft first-day plan for a course you teach or hope to teach'],
      'Louise Carnegie, Eberly Center'
    ],
    'Assessing Student Learning' => [
      'Assessments tell you and your students what they have learned, and they shape what students choose to study. ' \
      'Well-designed assessments line up with a course\'s learning objectives and give students chances to practice ' \
      'before the work counts.',
      'In this seminar, we compare formative and summative assessments, look at examples of exams, projects and ' \
      'short in-class checks, and practice writing questions that measure the skills you care about most.',
      ['Connect each assessment to a learning objective',
       'Use low-stakes checks to see what students understand before an exam',
       'Write questions that ask students to apply, not just recall',
       'Give feedback students can use on the next assignment'],
      'Margaret Morrison, Eberly Center'
    ],
    'Universal Design for Learning' => [
      'Universal Design for Learning (UDL) is a framework for planning courses that work for the widest range of ' \
      'students from the start, instead of adjusting them one student at a time.',
      'We will introduce the framework\'s three principles, look at how CMU instructors have applied them to ' \
      'lectures, labs and online materials, and work on one change you can make to a course this semester.',
      ['Offer more than one way to take in course material',
       'Give students choices in how they show what they have learned',
       'Build in structure that helps students plan and stay engaged',
       'Pick one change to try in your own course'],
      'Louise Carnegie, Eberly Center'
    ],
    'Making the Most of Office Hours' => [
      'Many students never come to office hours, and the ones who do are often unsure what to ask. Small changes in ' \
      'how you describe and run office hours can bring in more students and make the time more useful.',
      'This seminar shares strategies from instructors and TAs across campus, including group office hours, ' \
      'sign-up queues and drop-in sessions held before major assignments.',
      ['Explain what office hours are for in your syllabus and in class',
       'Run sessions that work for one student or ten',
       'Help students arrive with a question they can work on'],
      'Margaret Morrison, Eberly Center'
    ],
    'Course Design Institute' => [
      'The Course Design Institute is a full-day program for anyone building or rebuilding a course. You will work ' \
      'through the whole design process, from learning objectives to assessments to a week-by-week schedule.',
      'Participants work in small groups with an Eberly Center consultant and leave with a draft syllabus. Space is ' \
      'limited, so registration opens a waitlist; the Eberly Center confirms seats a week before the institute. ' \
      'Lunch is provided.',
      ['Write learning objectives for a course you will teach',
       'Design assessments and activities that line up with them',
       'Build a course schedule and a draft syllabus',
       'Get feedback from a consultant and other participants'],
      'Louise Carnegie and Margaret Morrison, Eberly Center'
    ],
    'Teaching at CMU: A Self-Paced Introduction' => [
      'A self-paced introduction to teaching at Carnegie Mellon, for anyone new to teaching here or new to teaching ' \
      'at all. The modules cover CMU\'s students, its policies on accommodations and academic integrity, and the ' \
      'campus offices that support instructors.',
      'Each module takes about 30 minutes and ends with a short reflection. Finish all four by the date below for ' \
      'it to count toward the Future Faculty Program.',
      ['Learn who CMU\'s students are and what they expect from a course',
       'Find the policies and offices that support your teaching',
       'Reflect on your own goals as an instructor'],
      'Eberly Center staff'
    ],
    'Accessible Course Materials' => [
      'Accessible materials work for students who use screen readers, captions or other assistive technology, and ' \
      'they are easier for every student to use. Most fixes take minutes once you know what to look for.',
      'This self-paced program walks through slides, documents, videos and Canvas pages, with a checklist you can ' \
      'keep and examples of before-and-after materials from CMU courses.',
      ['Add headings, alternative text and readable contrast to your materials',
       'Caption videos and provide transcripts',
       'Check a Canvas course page for common problems'],
      'Eberly Center staff'
    ]
  }.freeze

  STUDENTS = %w[pp00 ss00 gg00 an00 ap00 ah00 tb00 rd00 jw00 rw00 rc00 hh00 aw00 hc00 tm00 pm00 jh00 rm00 as00].freeze

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

  # A program's description: its full one when there is one, else its tag's
  # sentence and a second paragraph
  def description(title, tags)
    overview, more, items, facilitators = DETAILS[title]
    unless overview
      return "<p>#{DESCRIPTIONS.fetch(tags.split(',').first)}</p>" \
             '<p>Bring questions from your own teaching; there is time at the end to work on them with other ' \
             'participants.</p>'
    end

    list = items.map { |item| "<li>#{item}</li>" }.join
    "<p>#{overview}</p><p>#{more}</p><p>In this program, you will:</p><ul>#{list}</ul>" \
      "<p><strong>Facilitators:</strong> #{facilitators}</p>"
  end

  def settings
    { 'admin-list-tag' => 'core, dei, seminar, workshop', 'default-tag' => 'seminar' }.each do |key, value|
      Setting.find_by!(key:).update!(value:)
    end
    {
      'homepage-participant' => ['Home page note',
                                 '<p class="cmu-lead">Seminars and workshops on teaching from the Eberly Center, ' \
                                 'wherever you are in your teaching. Register for one below; the Future ' \
                                 'Faculty Program counts the ones you attend.</p>'],
      'sidebar-participant' => ['Sidebar note for signed-in participants',
                                '<p>Questions? Email seminars@eberly.cmu.edu.</p>']
    }.each do |key, (label, value)|
      Setting.find_or_create_by!(key:) { |s| s.assign_attributes(label:, value:) }
    end
  end

  def staff
    person('aa00').update!(is_admin: true)
    person('cc00').update!(is_admin: true, is_consultant: true)
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
      s.description = description(title, tags)
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
      s.description = description(title, tags)
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
    # Gary Graduate and Allen Newell attended every past seminar; Andrew
    # Mellon all but the workshops
    Seminar.past.find_each do |seminar|
      %w[gg00 an00 pp00].each do |id|
        next if id == 'pp00' && seminar.tag?('workshop')

        registration = Registration.find_or_initialize_by(seminar:, participant: people.fetch(id))
        registration.update!(waitlist_status: @confirmed, attendance_status: @attended)
      end
    end
  end

  def future_faculty(people)
    consultant = Participant.find_by!(andrewid: 'cc00')
    v2023 = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2023')
    v2015 = Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2015')

    # [andrewid, version, activities, final status]
    [
      ['pp00', v2023, %i[overview observation], nil],
      ['gg00', v2023, %i[overview observation observation syllabus statement], 'graduated'],
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
