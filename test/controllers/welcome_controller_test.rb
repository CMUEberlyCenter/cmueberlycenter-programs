require 'test_helper'

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test 'fresh setup renders the public page and asynchronous programs' do
    load Rails.root.join('db/seeds.rb')
    Seminar.create!(title: 'Self-paced Orientation', is_async: true,
                    end_at: 1.month.from_now, maximum_capacity: 20,
                    seminar_status: Seminar::StatusType.find_by!(key: 'open'))

    get root_url

    assert_response :success
    assert_includes response.body, 'Self-paced Orientation'
  end
end
