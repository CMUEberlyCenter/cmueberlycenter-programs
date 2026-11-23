# frozen_string_literal: true

class WelcomeController < ApplicationController
  def index
    @homepage_note = Setting.find_by(key: 'homepage-participant')&.value
    @sidebar_note = Setting.find_by(key: 'sidebar-participant')&.value
    @tag = params[:tag].presence

    @seminar_groups = [
      SeminarGroup.new(title: 'Live Programs Open for Registration',
                       seminars: Seminar.registerable.in_person),
      SeminarGroup.new(title: 'Asynchronous Programs Open for Registration',
                       seminars: Seminar.registerable.asynchronous)
    ]
    if Current.user&.admin?
      @seminar_groups << SeminarGroup.new(title: 'Past Programs', seminars: recent_past_seminars)
      @seminar_groups << SeminarGroup.new(title: 'Programs Not Open for Registration',
                                          seminars: Seminar.present.closed)
    end

    @seminar_tags = @seminar_groups.flat_map(&:seminars).flat_map(&:tags).uniq.sort
    return unless @tag

    @seminar_groups.each { |group| group.seminars = group.seminars.select { |s| s.tag?(@tag) } }
  end

  private

  # Past seminars with the tags the admin-list-tag setting names
  def recent_past_seminars
    tags = Setting.find_by(key: 'admin-list-tag')&.value.to_s.downcase.split(',').map(&:strip).compact_blank
    tags.flat_map { |t| Seminar.past.with_tag(t).to_a }.uniq.sort_by(&:end_at).reverse
  end
end
