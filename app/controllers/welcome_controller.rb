# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @homepage_note = Setting.find_by(key: 'homepage-participant')&.value
    @sidebar_note = Setting.find_by(key: 'sidebar-participant')&.value

    @seminar_groups = [
      SeminarGroup.new(title: 'Scheduled Programs',
                       seminars: Seminar.registerable.in_person, color: 'teal'),
      SeminarGroup.new(title: 'Self-Paced Programs',
                       seminars: Seminar.registerable.asynchronous, color: 'blue')
    ]
    if Current.user&.admin?
      @seminar_groups << SeminarGroup.new(title: 'Past Programs', seminars: recent_past_seminars, color: 'grey')
      @seminar_groups << SeminarGroup.new(title: 'Programs Not Open for Registration',
                                          seminars: Seminar.present.closed, color: 'grey')
    end
  end

  private

  # Past seminars with the tags the admin-list-tag setting names
  def recent_past_seminars
    tags = Setting.find_by(key: 'admin-list-tag')&.value.to_s.downcase.split(',').map(&:strip).compact_blank
    tags.flat_map { |t| Seminar.past.with_tag(t).to_a }.uniq.sort_by(&:end_at).reverse
  end
end
