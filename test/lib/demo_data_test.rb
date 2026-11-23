require 'test_helper'
Rails.application.load_tasks unless defined?(DemoData)

class DemoDataTest < ActiveSupport::TestCase
  test 'the demo loads made-up people at each program stage, and loading again adds nothing' do
    load Rails.root.join('db/seeds.rb')
    DemoData.new.load
    counts = [Seminar.count, Participant.count, Registration.count, Participant::Activity.count]
    DemoData.new.load

    assert_equal counts, [Seminar.count, Participant.count, Registration.count, Participant::Activity.count]
    assert_equal Participant::DemoPerson.entries.map(&:uid).sort, Participant.pluck(:andrewid).sort
    statuses = Participant.where.not(future_faculty_enrollment_id: nil).map { |p| p.future_faculty_progress_status.key }
    assert_equal %w[complete dropout graduated incomplete], statuses.uniq.sort
  end
end
