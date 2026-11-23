class Setting < ActiveRecord::Base
  # Each setting's label in Admin, by key; a key not listed uses its row's label
  LABELS = {
    'homepage-participant' => 'Home Page Note',
    'sidebar-participant' => 'Sidebar Note for Signed-In Participants',
    'default-tag' => 'Default Tag for New Seminars',
    'admin-list-tag' => 'Show Past Programs Tagged'
  }.freeze

  def label = LABELS.fetch(key) { self[:label] }

  def self.sidebar_settings
    select { |s| s.key.match? '^sidebar-' }
  end
end
