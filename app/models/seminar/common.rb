# frozen_string_literal: true

require 'active_support/concern'
module Seminar::Common
  extend ActiveSupport::Concern

  included do
    scope :present, -> { where('end_at >= ? or end_at is null', Time.zone.now) }
    scope :past, -> { where('end_at < ?', Time.zone.now) }
    scope :in_days, lambda { |n = 2|
      where('start_at between ? and ?',
            Time.zone.now.beginning_of_day + n.days,
            Time.zone.now.end_of_day + n.days)
    }
    Seminar::StatusType.find_each do |s|
      # Scopes Seminar.open, Seminar.closed, etc.
      scope s.key, -> { where(seminars: { seminar_status: s }) }

      # Methods s.open?, s.closed?, etc.
      define_method("#{s.key}?") { seminar_status.key == s.key.to_s }
    end
    scope :registerable, -> { present.merge(open) }
    scope :async, -> { present.merge(where(is_async: true)) }
    scope :in_person, -> { present.merge(where(is_async: false)) }
    scope :upcoming, -> { present.merge(closed) }

    scope :with_tag, lambda { |tag|
      # rename the join to support with_tag chaining
      joins("inner join seminar_tags as seminar_tags_#{tag}"\
            " on seminars.id=seminar_tags_#{tag}.seminar_id")
        .where("seminar_tags_#{tag}.value = lower(:tag)", tag:)
    }

    # TODO
    scope :without_tag, lambda { |tag|
      where.not(id: with_tag(tag.downcase).pluck(:id))
    }
  end

  def tag?(tag) = tags.present? && tags.include?(tag)
end
