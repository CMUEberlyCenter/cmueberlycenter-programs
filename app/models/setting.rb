class Setting < ActiveRecord::Base
  # The settings in Settings, with each one's label, by key
  LABELS = {
    'homepage-participant' => 'Home Page Note',
    'sidebar-participant' => 'Sidebar Note for Signed-In Participants',
    'default-tag' => 'Default Tag for New Seminars'
  }.freeze

  def label = LABELS.fetch(key) { self[:label] }

  def self.sidebar_settings
    select { |s| s.key.match? '^sidebar-' }
  end
end
