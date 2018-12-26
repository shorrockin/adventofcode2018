require './boilerplate'

MIN_CONST_DISTANCE = 3

Pos = Struct.new(:x, :y, :z, :t) do
  def distance(pos)
    (x - pos.x).abs + (y - pos.y).abs + (z - pos.z).abs + (t - pos.t).abs
  end

  def to_s
    "Pos(x: #{x}, y: #{y}, z: #{z}, t: #{t})"
  end
end

class Const
  include Loggable
  attr_accessor :stars
  def initialize(logging: false)
    @logging = logging
    @stars = []
  end

  def populate(unused)
    new_stars = [unused.first]
    unused.delete(new_stars.first)

    log "populating constalation starting with", new_stars.first
    log "unused stars", unused.length do

      # looping here allows us to reprocess once we get a new star
      while new_stars.any?
        @stars = @stars + new_stars
        new_stars = []

        unused = unused.reject do |star|
          joined = false

          @stars.each do |const_star|
            if const_star.distance(star) <= MIN_CONST_DISTANCE
              log "adding #{star} (close to #{const_star})"
              new_stars << star
              joined = true
              break
            end
          end

          joined
        end

        log "unused length after iteration", unused.length
        log "new stars added", new_stars.length
      end
    end

    unused
  end

  def num_stars; @stars.length; end
end

class State
  include Loggable
  attr_accessor :stars, :consts
  def initialize(input, logging: false)
    @logging = logging
    @consts = []

    @stars = input.map(&:strip).map do |line|
      coords = line.split(",").map(&:to_i)
      Pos.new(coords[0], coords[1], coords[2], coords[3])
    end

    unused = @stars.dup
    while unused.any?
      log "populating constalation from unused", unused.length do
        @consts << Const.new(logging: @logging)
        unused = @consts.last.populate(unused)
      end
      log "constalation contains #{@consts.last.stars.length} stars"
    end
  end
end

def assert_input(const_count, input, logging: false)
  input = input.split("\n") unless input.is_a?(Array)
  state = State.new(input, logging: logging)
  assert_equal(const_count, state.consts.length, "state.consts.length")
end

part "1 (examples)" do
  assert_input(2, """0,0,0,0
 3,0,0,0
 0,3,0,0
 0,0,3,0
 0,0,0,3
 0,0,0,6
 9,0,0,0
12,0,0,0""")

  assert_input(1, """ 0,0,0,0
 3,0,0,0
 0,3,0,0
 0,0,3,0
 0,0,0,3
 0,0,0,6
 9,0,0,0
 6,0,0,0
12,0,0,0""")

  assert_input(4, """-1,2,2,0
0,0,2,-2
0,0,0,-2
-1,2,0,0
-2,-2,-2,2
3,0,2,-1
-1,3,2,2
-1,0,-1,0
0,2,1,-2
3,0,0,0""")

  assert_input(3, """1,-1,0,1
2,0,-1,0
3,2,-1,0
0,0,3,1
0,0,-1,-1
2,3,-2,0
-2,2,0,0
2,-2,0,-1
1,-1,0,-1
3,2,0,2""")

  assert_input(8, """1,-1,-1,-2
-2,-2,0,1
0,2,1,3
-2,3,-2,1
0,2,3,-2
-1,-1,1,-2
0,-2,-1,0
-2,2,3,-1
1,2,2,0
-1,-2,0,-2""")
end

part "1" do
  assert_input(331, input)
end
