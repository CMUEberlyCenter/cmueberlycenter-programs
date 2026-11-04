class SeminarGroup
  attr_accessor :title, :seminars

  def to_partial_path() "seminars/seminar_group" end

  def initialize(attributes = {})
    @title, @seminars =
      *attributes.values_at(:title, :seminars)
  end
end
