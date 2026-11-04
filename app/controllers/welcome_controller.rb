# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    homepage_note_setting = Setting.find_by(key: 'homepage-participant')
    @homepage_note = homepage_note_setting.value unless homepage_note_setting.blank?
    sidebar_note_setting = Setting.find_by(key: 'sidebar-participant')
    @sidebar_note = sidebar_note_setting.value unless sidebar_note_setting.blank?

    @seminar_groups = [
      SeminarGroup.new(title: 'Programs Open for Registration: Synchronous',
                       seminars: Seminar.registerable.in_person),
      SeminarGroup.new(title: 'Programs Open for Registration: Asynchronous',
                       seminars: Seminar.registerable.async)
    ]

    if Current.user&.admin?
      @seminar_groups.append(
        SeminarGroup.new(title: 'Past Programs',
                         seminars: recent_past_seminars))
      @seminar_groups.append(
        SeminarGroup.new(title: 'Programs Unavailable for Registration',
                         seminars: Seminar.closed))
    end

    seminars = @seminar_groups.map{ |g| g.seminars }.flatten
    @seminar_tags = [seminars.map{ |s| s.tags}].flatten.uniq.sort
  end
end

private

def recent_past_seminars
  tag_setting = Setting.find_by_key('admin-list-tag').value.downcase
  filter_tags = tag_setting.split(',').map{|t| t.strip}
  filter_tags.map { |t| Seminar.past.with_tag(t)}.flatten
end
