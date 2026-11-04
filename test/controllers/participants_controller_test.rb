require "test_helper"
require 'minitest/mock'

class ParticipantsControllerTest < ActionController::TestCase
  test 'a participation record renders as PDF with the upgraded renderer' do
    load Rails.root.join('db/seeds.rb')
    participant = Participant.create!(andrewid: 'pdfsample', name: 'Example Participant',
                                      is_admin: true, ldap_entry: Object.new)

    Current.stub(:user, participant) do
      Participant.stub(:find_or_create_by!, participant) do
        participant.stub(:update_ldap_attrs, nil) do
          get :show, params: { id: participant.andrewid }, format: :pdf
        end
      end
    end

    assert_response :success
    assert_equal 'application/pdf', response.media_type
    assert response.body.start_with?('%PDF-')
  end
end
