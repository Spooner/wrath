# encoding: utf-8

require_relative 'mob'

class Goat < Mob
  IMAGE_ROW = 3

  def favor; 10; end

  def initialize(options = {})
    options = {
      speed: 0.5,
      encumbrance: 0.2,
    }.merge! options

    super(IMAGE_ROW, options)
  end
end