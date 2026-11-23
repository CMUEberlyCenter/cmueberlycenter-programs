require "test_helper"
require 'minitest/mock'

class ParticipantsControllerTest < ActionController::TestCase
  test 'spreadsheet exports the table activity counts as numbers including zeros' do
    load Rails.root.join('db/seeds.rb')
    participant = Participant.create!(andrewid: 'counts', ldap_entry: Object.new)
    empty = Participant.create!(andrewid: 'nocounts', ldap_entry: Object.new)

    Participant::FFP_MEMO_COUNTS.each_value do |type|
      participant.activities.create!(type: type, memo_completed_on: Date.current)
      participant.activities.create!(type: type, completed_on: Date.current)
    end
    participant.activities.create!(type: Participant::FFP_MEMO_COUNTS.fetch(:ffp_obs),
                                   memo_completed_on: Date.current)
    Participant::FFP_COMPLETED_COUNTS.each_value do |type|
      participant.activities.create!(type: type, completed_on: Date.current)
      participant.activities.create!(type: type, memo_completed_on: Date.current)
    end

    ['', 'dei', 'workshop,dei', 'other', 'not-attended'].each do |tags|
      seminar = Seminar.create!(title: "Export #{tags}", tags: tags,
                                seminar_status: Seminar::StatusType.find_by!(key: 'open'))
      Registration.create!(participant: participant, seminar: seminar,
        waitlist_status: Registration::WaitlistStatusType.find_by!(key: 'confirmed'),
        attendance_status: tags == 'not-attended' ? nil : Registration::AttendanceStatusType.find_by!(key: 'attended'))
    end

    admin = Struct.new(:admin?).new(true)
    Current.stub(:user, admin) { get :index, format: :xlsx }

    assert_response :success
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', response.media_type
    rows = spreadsheet_rows
    assert_equal 3, rows.size, rows.inspect
    assert_equal ['Seminars', 'DEI Seminars', 'Obs', 'ECFs', 'Micros', 'LPRs', 'CSDs', 'TPs'], rows.first.last(8)
    assert_equal [2, 1, 2, 1, 1, 1, 1, 1], rows.find { |row| row[2] == participant.andrewid }.last(8)
    assert_equal [0] * 8, rows.find { |row| row[2] == empty.andrewid }.last(8)

    fields = %w[ffp_seminar_size ffp_dei_size ffp_obs ffp_ecf ffp_micro ffp_lpr ffp_csd ffp_tp]
    Current.stub(:user, admin) { get :index, format: :json }
    JSON.parse(response.body).each do |row|
      assert_equal row.values_at(*fields), rows.find { |cells| cells[2] == row['andrewid'] }.last(8)
    end
  end

  test 'completed FFP download link and spreadsheet preserve the participant filter' do
    load Rails.root.join('db/seeds.rb')
    participant = Participant.create!(andrewid: 'completed', ldap_entry: Object.new)
    participant.update_columns(
      future_faculty_enrollment_id: Programs::FutureFaculty::RequirementsVersion.find_by!(key: '2023').id,
      future_faculty_progress_status_id: ProgressStatusType.find_by!(key: 'complete').id)
    Participant.create!(andrewid: 'notcompleted', ldap_entry: Object.new)
    admin = Struct.new(:admin?, :name).new(true, 'Admin')

    Current.stub(:user, admin) { get :index, params: { ffp_status: 'complete' } }
    assert_response :success
    config = JSON.parse(Nokogiri::HTML(response.body).at_css('#example-table')['data-config'])
    link = Nokogiri::HTML.fragment(config.fetch('footerElement')).at_css('a')
    assert_equal participants_path(format: :xlsx, ffp_status: 'complete'), link['href']
    assert_equal 'Download 1 Participants (.xlsx)', link.text

    Current.stub(:user, admin) { get :index, params: { ffp_status: 'complete' }, format: :xlsx }
    assert_response :success
    assert_equal [participant.andrewid], spreadsheet_rows.drop(1).map { |row| row[2] }
  end

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

  private

  def spreadsheet_rows
    rows = nil
    Zip::File.open_buffer(response.body) do |archive|
      strings_entry = archive.find_entry('xl/sharedStrings.xml')
      strings = strings_entry ? Nokogiri::XML(strings_entry.get_input_stream.read).remove_namespaces!.xpath('//si').map(&:text) : []
      sheet = Nokogiri::XML(archive.read('xl/worksheets/sheet1.xml')).remove_namespaces!
      rows = sheet.xpath('//sheetData/row').map do |row|
        row.xpath('c').map do |cell|
          case cell['t']
          when 's' then strings.fetch(cell.at_xpath('v').text.to_i)
          when 'inlineStr' then cell.at_xpath('is').text
          else cell.at_xpath('v')&.text&.to_i
          end
        end
      end
    end
    rows
  end
end
