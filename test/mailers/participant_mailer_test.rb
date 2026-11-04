require 'test_helper'

class ParticipantMailerTest < ActionMailer::TestCase
  test 'confirmation emails retain the seminar email snippet' do
    load Rails.root.join('db/seeds.rb')
    participant = Participant.create!(andrewid: 'mailsample', name: 'Example Participant',
                                      email: 'participant@example.invalid', ldap_entry: Object.new)
    seminar = Seminar.create!(title: 'Example Seminar', start_at: 1.week.from_now,
                              end_at: 1.week.from_now + 1.hour,
                              confirmed_email_insert: 'Please bring your course outline.',
                              seminar_status: Seminar::StatusType.find_by!(key: 'open'))
    registration = Registration.create!(participant: participant, seminar: seminar,
      waitlist_status: Registration::WaitlistStatusType.find_by!(key: 'confirmed'))

    message = ParticipantMailer.registration_confirmed_email(participant, registration).message

    assert_equal ['participant@example.invalid'], message.to
    assert_includes message.body.to_s, 'Please bring your course outline.'
    assert_equal '[Eberly Center] Confirmation for Example Seminar', message.subject
  end
end
