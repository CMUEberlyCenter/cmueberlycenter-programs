require 'test_helper'

# People: one search for the list, which also finds people at CMU who aren't
# in Programs yet
class PeoplePageTest < ActionDispatch::IntegrationTest
  setup do
    load Rails.root.join('db/seeds.rb')
  end

  test 'staff get one Find People search, with no separate look-up' do
    sign_in('cc00')

    get participants_path

    assert_response :success
    assert_select '.cmu-search-bar label.cmu-label', 'Find People'
    assert_select '.cmu-search-bar input#prg-participant-search[data-cmu-filter="prg-participants"]'
    assert_select '#prg-look-up', count: 0
    assert_select '[data-people-search-target="more"][hidden] h2', 'Not in Programs Yet'
    assert_select 'p.cmu-results-count', /\AShowing all \d+ (person|people)\z/
  end

  test "the search finds people in the directory who aren't in Programs yet" do
    sign_in('cc00')
    Participant.find_or_create_by!(andrewid: 'gg00')
    Participant.where(andrewid: 'ss00').destroy_all

    get search_participants_path(q: 'ss00')
    assert_equal ['ss00'], response.parsed_body.map { |person| person['andrewid'] }

    get search_participants_path(q: 'gg00')
    assert_empty response.parsed_body
  end

  test "participants can't use the directory search" do
    sign_in('pp00')

    get search_participants_path(q: 'ss00')

    assert_response :redirect
  end
end
