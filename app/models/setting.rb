class Setting < ActiveRecord::Base
  #  attr_accessible :label, :key, :value

  def self.sidebar_settings
    select { |s| s.key.match? '^sidebar-' }
  end
end
