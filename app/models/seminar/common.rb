# frozen_string_literal: true

require 'active_support/concern'
module Seminar::Common
  extend ActiveSupport::Concern

  STATUS_KEYS = %w[open closed].freeze

  included do
    scope :present, -> { where('end_at >= ? or end_at is null', Time.zone.now) }
    scope :past, -> { where('end_at < ?', Time.zone.now) }
    scope :in_days, lambda { |n = 2|
      where('start_at between ? and ?',
            Time.zone.now.beginning_of_day + n.days,
            Time.zone.now.end_of_day + n.days)
    }
    STATUS_KEYS.each do |key|
      # Scopes Seminar.open, Seminar.closed, etc.
      scope key, -> { where(seminars: { seminar_status_id: Seminar::StatusType.where(key: key).select(:id) }) }

      # Methods s.open?, s.closed?, etc.
      define_method("#{key}?") { seminar_status&.key == key }
    end
    scope :registerable, -> { present.merge(open) }
    scope :asynchronous, -> { present.merge(where(is_async: true)) }
    scope :in_person, -> { present.merge(where(is_async: [false, nil])) }
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
