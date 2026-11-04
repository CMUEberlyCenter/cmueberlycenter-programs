require 'test_helper'
require 'minitest/mock'

class Programs::FutureFacultyControllerTest < ActionController::TestCase
  self.fixture_table_names = []

  test 're-enrollment has its own PATCH route' do
    assert_routing(
      { path: '/future-faculty/existing/reenroll', method: :patch },
      { controller: 'programs/future_faculty', action: 'reenroll', participant_id: 'existing' }
    )
  end

  test 're-enrollment restores status without restarting enrollment or adding an overview' do
    participant = Minitest::Mock.new
    participant.expect(:future_faculty_progress_status_id=, 1, [1])
    participant.expect(:save, true)
    original_enrollment = Object.new
    prevent_new_enrollment = ->(*) { flunk 'Re-enrollment must preserve the existing requirements version' }
    skip_response = ->(&block) {}

    @controller.params = { participant_id: 'existing' }
    Participant.stub(:find, participant) do
      Programs::FutureFaculty::Enrollment.stub(:find, original_enrollment) do
        Programs::FutureFaculty::Enrollment.stub(:new, prevent_new_enrollment) do
          @controller.stub(:respond_to, skip_response) { @controller.reenroll }
        end
      end
    end

    assert participant.verify
  end
end
