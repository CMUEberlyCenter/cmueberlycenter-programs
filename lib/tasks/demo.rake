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
    # [title, tags, days from today, hours, location, more days it runs]
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
    ['Microteaching Sessions (Spring 2027)', 'workshop, s27', 6, [9, 17], 'Tepper Quad 1309 or Zoom', 10],
    ['Making the Most of Office Hours', 'seminar', 51, [12, 13], 'Baker Hall A53'],
    ['Mentoring Undergraduate Researchers: A Two-Day Institute', 'workshop, s27', 52, [9, 12], 'Tepper Quad 1308', 1],
    ['Course Design Institute', 'other', 58, [9, 16], 'Tepper Quad 1310', 1]
  ].freeze

  ASYNCHRONOUS = [
    ['Teaching at CMU: A Self-Paced Introduction', 'core', 60],
    ['Accessible Course Materials', 'dei', 90],
    ['Creating a Welcoming Classroom From Day One', 'core, dei', 280],
    ['Running a Recitation Section', 'core', 280],
    ['Grading Quantitative Work: Code and Problem Sets', 'core', 280],
    ['Grading Written Work: Papers and Lab Reports', 'core', 280]
  ].freeze

  DESCRIPTIONS = {
    'core' => 'One of the core seminars on teaching practice. Bring a course you teach or hope to teach.',
    'dei' => 'Ways to make a course work for every student, with examples from CMU courses.',
    'workshop' => 'A hands-on session: you leave with a draft and feedback on it.',
    'other' => 'A program outside the seminar series, open to graduate students and postdocs.',
    'seminar' => 'A seminar on one part of teaching, with time to try it out.'
  }.freeze

  # Full descriptions for the programs open now: a bold line on logistics,
  # paragraphs, a list, a note and the facilitators
  ASYNC_LEAD = 'This program is self-paced. Your confirmation email says how to join its Canvas course.'
  DETAILS = {
    'Engaging Students on the First Day' => {
      paras: ['The first day of class sets expectations for the whole semester. Students decide quickly whether a ' \
              'course will be worth their effort, whether they belong in it and how much the instructor cares about ' \
              'their learning.',
              'This seminar looks at research on first impressions in the classroom and walks through first-day plans ' \
              'from CMU courses in several disciplines. You will draft your own plan and get feedback on it from other ' \
              'participants. You do not have to be teaching this semester to take part.'],
      intro: 'You will:',
      items: ['Plan a first day that introduces the course, its goals and you',
              'Choose activities that let students meet each other and the material',
              'Set norms for participation, questions and feedback'],
      facilitators: 'Louise Carnegie, Eberly Center'
    },
    'Assessing Student Learning' => {
      paras: ['Assessments tell you and your students what they have learned, and they shape what students choose to ' \
              'study. Well-designed assessments line up with a course\'s learning objectives and give students chances ' \
              'to practice before the work counts.',
              'We compare formative and summative assessments, look at examples of exams, projects and short in-class ' \
              'checks, and practice writing questions that measure the skills you care about most. Bring an ' \
              'assignment or exam you have written or graded if you have one.'],
      intro: 'You will:',
      items: ['Connect each assessment to a learning objective',
              'Use low-stakes checks to see what students understand before an exam',
              'Write questions that ask students to apply, not just recall',
              'Give feedback students can use on the next assignment'],
      facilitators: 'Margaret Morrison, Eberly Center'
    },
    'Universal Design for Learning' => {
      paras: ['Universal Design for Learning (UDL) is a framework for planning courses that work for the widest range ' \
              'of students from the start, instead of adjusting them one student at a time.',
              'We introduce the framework\'s three principles, look at how CMU instructors have applied them to ' \
              'lectures, labs and online materials, and work on one change you can make to a course this semester.'],
      intro: 'You will:',
      items: ['Offer more than one way to take in course material',
              'Give students choices in how they show what they have learned',
              'Build in structure that helps students plan and stay engaged'],
      note: 'This seminar meets the DEI seminar requirement of the Future Faculty Program.',
      facilitators: 'Louise Carnegie, Eberly Center'
    },
    'Microteaching Sessions (Spring 2027)' => {
      lead: 'Choose one session: in person or on Zoom.',
      paras: ['In a microteaching session, you teach a 15-minute lesson to a small group of other participants and ' \
              'get feedback from them and from an Eberly Center consultant. You also watch and give feedback on ' \
              'the others\' lessons. Afterward, you receive a written summary of your teaching strengths and ' \
              'strategies to try.',
              'Microteaching counts as one observation toward the Future Faculty Program\'s teaching feedback ' \
              'requirement. Registering here signs you up; the facilitator then emails you to choose a session.'],
      intro: 'Sessions:',
      items: ['Monday, 9-11:30 a.m. (Zoom), 2 seats left',
              'Wednesday, 1-3:30 p.m. (Tepper Quad 1309), full: join the waitlist',
              'Friday, 2:30-5 p.m. (Zoom), 4 seats left'],
      note: 'Before your session, meet with the facilitator for 15 to 30 minutes to plan your lesson. If every ' \
            'session is full, you can still register to observe one, and you will hear about the next round.',
      facilitators: 'Margaret Morrison, Eberly Center'
    },
    'Mentoring Undergraduate Researchers: A Two-Day Institute' => {
      lead: 'Two mornings, 9 a.m.-noon. Registering signs you up for both days.',
      paras: ['Graduate students and postdocs often mentor undergraduates in research, usually without any training ' \
              'in how to do it. This institute helps you plan a research project an undergraduate can finish and ' \
              'build habits that make mentoring work for both of you.',
              'You will leave with a mentoring plan and a set of strategies for the questions that come up most:'],
      intro: nil,
      items: ['What makes mentoring inclusive and effective?',
              'How is mentoring like teaching, and how is it different?',
              'How do you set goals and scope a project for an undergraduate?',
              'How can you help students build the habits of a researcher?'],
      facilitators: 'Margaret Morrison, Eberly Center'
    },
    'Course Design Institute' => {
      lead: 'Two full days, with lunch. Registering signs you up for both.',
      paras: ['The Course Design Institute is for anyone building or rebuilding a course. Over two days, you work ' \
              'through the whole design process, from learning objectives to assessments to a week-by-week schedule, ' \
              'in a small group with an Eberly Center consultant.',
              'Space is limited, so registering puts you on a waitlist; the Eberly Center confirms seats a week before ' \
              'the institute.'],
      intro: 'You will:',
      items: ['Write learning objectives for a course you will teach',
              'Design assessments and activities that line up with them',
              'Build a course schedule and a draft syllabus',
              'Get feedback from a consultant and other participants'],
      facilitators: 'Louise Carnegie and Margaret Morrison, Eberly Center'
    },
    'Teaching at CMU: A Self-Paced Introduction' => {
      lead: ASYNC_LEAD,
      paras: ['An introduction to teaching at Carnegie Mellon, for anyone new to teaching here or new to teaching at ' \
              'all. The four modules cover CMU\'s students, its policies on accommodations and academic integrity, ' \
              'and the campus offices that support instructors.',
              'Each module takes about 30 minutes and ends with a short reflection. Finish all four by the date ' \
              'above for the program to count toward the Future Faculty Program.']
    },
    'Accessible Course Materials' => {
      lead: ASYNC_LEAD,
      paras: ['Accessible materials work for students who use screen readers, captions or other assistive technology, ' \
              'and they are easier for every student to use. Most fixes take minutes once you know what to look for.',
              'This program walks through slides, documents, videos and Canvas pages, with a checklist to keep and ' \
              'before-and-after examples from CMU courses.'],
      note: 'This program meets the DEI seminar requirement of the Future Faculty Program.'
    },
    'Creating a Welcoming Classroom From Day One' => {
      lead: ASYNC_LEAD,
      paras: ['Whether you have taught before or this is your first time, this program helps you build a classroom ' \
              'climate that supports every student from the start of the semester. You will look at research on ' \
              'how climate affects learning and work through five strategies: getting to know your students, ' \
              'adjusting your teaching to CMU students, setting expectations, handling difficult moments and ' \
              'connecting students to the material early.']
    },
    'Running a Recitation Section' => {
      lead: ASYNC_LEAD,
      paras: ['Leading a recitation is different from teaching a lecture. Recitations give students a chance to ' \
              'practice solving problems and ask questions in a smaller group, and they work best when they have ' \
              'goals of their own.',
              'This program covers setting goals for a recitation, planning sessions that get students working, ' \
              'and coaching students through example problems instead of solving them at the board.']
    },
    'Grading Quantitative Work: Code and Problem Sets' => {
      lead: ASYNC_LEAD,
      paras: ['Strategies for grading and giving feedback on quantitative work, such as problem sets and code. You will ' \
              'look at research on what makes feedback useful, practice with rubrics and grade sample student work.'],
      note: 'This program and Grading Written Work cover the same ideas with different examples. Take the one that ' \
            'fits your discipline or TA assignment; if you take both, only one counts toward the Future Faculty ' \
            'Program.'
    },
    'Grading Written Work: Papers and Lab Reports' => {
      lead: ASYNC_LEAD,
      paras: ['Strategies for grading and giving feedback on written work, such as papers, lab reports and ' \
              'short-answer questions. You will look at research on what makes feedback useful, practice with ' \
              'rubrics and grade sample student work.'],
      note: 'This program and Grading Quantitative Work cover the same ideas with different examples. Take the one ' \
            'that fits your discipline or TA assignment; if you take both, only one counts toward the Future ' \
            'Faculty Program.'
    }
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
    entry = DETAILS[title]
    unless entry
      return "<p>#{DESCRIPTIONS.fetch(tags.split(',').first.strip)}</p>" \
             '<p>Bring questions from your own teaching; there is time at the end to work on them with other ' \
             'participants.</p>'
    end

    html = +''
    html << "<p><strong>#{entry[:lead]}</strong></p>" if entry[:lead]
    entry[:paras].each { |para| html << "<p>#{para}</p>" }
    html << "<p>#{entry[:intro]}</p>" if entry[:intro]
    html << "<ul>#{entry[:items].map { |item| "<li>#{item}</li>" }.join}</ul>" if entry[:items]
    html << "<p><strong>Please note:</strong> #{entry[:note]}</p>" if entry[:note]
    html << "<p><strong>Facilitators:</strong> #{entry[:facilitators]}</p>" if entry[:facilitators]
    html
  end

  def settings
    { 'admin-list-tag' => 'core, dei, seminar, workshop', 'default-tag' => 'seminar' }.each do |key, value|
      Setting.find_by!(key:).update!(value:)
    end
    {
      'homepage-participant' => ['Home Page Note',
                                 '<p class="cmu-lead">Seminars and workshops on teaching from the Eberly Center, ' \
                                 'wherever you are in your teaching. Register for one below; the Future ' \
                                 'Faculty Program counts the ones you attend.</p>'],
      'sidebar-participant' => ['Sidebar Note for Signed-In Participants',
                                '<h2>Questions?</h2><p>Email <a href="mailto:seminars@eberly.cmu.edu">' \
                                'seminars@eberly.cmu.edu</a>.</p>']
    }.each do |key, (label, value)|
      Setting.find_or_create_by!(key:) { |s| s.assign_attributes(label:, value:) }
    end
  end

  def staff
    person('aa00').update!(is_admin: true)
    person('cc00').update!(is_admin: false, is_consultant: true)
    person('lc00').update!(is_consultant: true)
  end

  def person(andrewid)
    participant = Participant.find_or_create_by!(andrewid:)
    participant.update_ldap_attrs if participant.name(fallback: false).blank?
    participant
  end

  def seminar(title, tags, days, hours, location, more_days = 0)
    Seminar.find_or_create_by!(title:) do |s|
      day = today + days
      last = day + more_days
      s.start_at = Time.zone.local(day.year, day.month, day.day, hours.first)
      s.end_at = Time.zone.local(last.year, last.month, last.day, hours.last)
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
