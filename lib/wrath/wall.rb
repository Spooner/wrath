module Wrath
class Wall < BasicGameObject
  ELASTICITY = 0
  FRICTION = 0

  attr_reader :side, :owner

  def exists?; true; end

  def initialize(x1, y1, x2, y2, side)
    super()

    @side = side

    @@body ||= CP::StaticBody.new # Can share a body quite happily.
    @shape = CP::Shape::Segment.new(@@body, vec2(x1, y1), vec2(x2, y2), 0.0)
    @shape.e = ELASTICITY
    @shape.u = FRICTION
    @shape.collision_type = :wall
    @shape.group = CollisionGroup::STATIC
    @shape.object = self

    @parent.space.add_shape @shape # Body not needed, since we don't want to be affected by gravity et al.
  end
end
end