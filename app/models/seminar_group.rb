# A heading and its seminars on the home page, in a full-width section with
# one of the template's section colors (teal, blue or grey)
class SeminarGroup
  attr_accessor :title, :seminars, :color

  def to_partial_path() "seminars/seminar_group" end

  # White heading text on the darker colors
  def invert? = color != 'grey'

  def initialize(attributes = {})
    @title, @seminars, @color =
      *attributes.values_at(:title, :seminars, :color)
  end
end
