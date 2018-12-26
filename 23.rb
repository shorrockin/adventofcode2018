require './boilerplate'

Coord = Struct.new(:x, :y, :z) do
  def distance(target)
    (x - target.x).abs + (y - target.y).abs + (z - target.z).abs
  end

  def count_bots_in_range(bots)
    bots.count {|b| b.in_range?(self)}
  end
end

ORIGIN = Coord.new(0, 0, 0)

Bot = Struct.new(:x, :y, :z, :radius) do
  def distance(target)
    (x - target.x).abs + (y - target.y).abs + (z - target.z).abs
  end

  def in_range?(target)
    distance(target) <= radius
  end

  def positions(&block)
    (x-radius..x+radius).each do |cx|

      x_radius = radius - (cx - x).abs
      (y-x_radius..y+x_radius).each_with_index do |cy|

        y_radius = x_radius - (cy - y).abs
        (z-y_radius..z+y_radius).each do |cz|
          yield Coord.new(cx, cy, cz)
        end
      end
    end
  end
end

SamplePosition = Struct.new(:coord, :origin_distance, :bot_count) do
  def better?(other)
    return true if bot_count > other.bot_count
    return true if bot_count == other.bot_count && origin_distance < other.origin_distance
    false
  end
end

class State
  include Loggable
  attr_accessor :bots
  def initialize(input, logging: false)
    @logging = logging
    @bots = []

    input.map do |line|
      match = /pos=<(-?\d+),(-?\d+),(-?\d+)>, r=(\d+)/.match(line)
      bots << Bot.new(match[1].to_i, match[2].to_i, match[3].to_i, match[4].to_i)
    end
  end

  def strongest_signal; @bots.max_by(&:radius); end
  def nanobots_in_range_of(bot); @bots.count {|b| bot.in_range?(b)}; end

  # def best_starting_position(sections: 10)
  #   min_x = @bots.map {|b| b.from.x - b.range}.min
  #   max_x = @bots.map {|b| b.from.x + b.range}.max
  #   x_inc = (max_x - min_x) / sections

  #   min_y = @bots.map {|b| b.from.y - b.range}.min
  #   max_y = @bots.map {|b| b.from.y + b.range}.max
  #   y_inc = (max_y - min_y) / sections

  #   min_z = @bots.map {|b| b.from.z - b.range}.min
  #   max_z = @bots.map {|b| b.from.z + b.range}.max
  #   z_inc = (max_z - min_z) / sections

  #   sections.times do |xc|
  #     sections.times do |yc|
  #       sections.times do |zc|
  #       end
  #       end




  #   log "calculating best starting position" do
  #     all_bounds = @bots.map(&:bounds)

  #     min_x = round_down(all_bounds.min_by {|b| b.from.x }.from.x)
  #     min_y = round_down(all_bounds.min_by {|b| b.from.y }.from.y)
  #     min_z = round_down(all_bounds.min_by {|b| b.from.z }.from.z)

  #     max_x = round_up(all_bounds.max_by {|b| b.to.x }.to.x)
  #     max_y = round_up(all_bounds.max_by {|b| b.to.y }.to.y)
  #     max_z = round_up(all_bounds.max_by {|b| b.to.z }.to.z)

  #     log "min values of x, y, z", min_x, min_y, min_z
  #     log "max values of x, y, z", max_x, max_y, max_z

  #     bounds = Bounds.new(
  #       Coord.new(min_x, min_y, min_z),
  #       Coord.new(max_x, max_y, max_z),
  #     )

  #     max_delta = [
  #       (min_x - max_x).abs,
  #       (min_y - max_y).abs,
  #       (min_z - max_z).abs
  #     ].max

  #     middle_x = min_x + (max_x - min_x) / 2
  #     middle_y = min_y + (max_y - min_y) / 2
  #     middle_z = min_z + (max_z - min_z) / 2

  #     log "max delta of bounds", max_delta
  #     log "middle values of x, y, z", middle_x, middle_y, middle_z

  #     max_delta = (max_delta / 2) # half for each side

  #     bounds = Bounds.new(
  #       Coord.new(
  #         round_down(middle_x - max_delta),
  #         round_down(middle_y - max_delta),
  #         round_down(middle_z - max_delta)
  #       ),
  #       Coord.new(
  #         round_up(middle_x + max_delta),
  #         round_up(middle_y + max_delta),
  #         round_up(middle_z + max_delta)
  #       )
  #     )

  #     log "calculated starting bounds", bounds
  #     bounds
  #   end
  # end

  def sample_position(x, y, z)
    coord = Coord.new(x, y, z)
    bot_count = coord.count_bots_in_range(@bots)
    origin_distance = coord.distance(ORIGIN)
    SamplePosition.new(Coord.new(x, y, z), origin_distance, bot_count)
  end

  def default_fringe_size
    (@bots.map(&:radius).sum / @bots.length) / 50
  end

  # we start be selecting a "random" starting point, exploring all points around it and
  # moving to the "best" point in that finding. continue this process until we don't find
  # a better solution.
  def best_position_v2(buffer: 1, fringe_size: default_fringe_size )
    current = sample_position(
      @bots.map(&:x).sum / @bots.length,
      @bots.map(&:y).sum / @bots.length,
      @bots.map(&:z).sum / @bots.length,
    )

    fringes = [fringe_size * 4, fringe_size, 0, -fringe_size, fringe_size * -4]
    best_sample = current

    log "initializing best position with buffer, and fringe size", buffer, fringe_size
    log "starting sample position", current

    while true
      log "current positioning / range", current do
        # first test around the current position
        (-buffer..buffer).each do |dx|
          (-buffer..buffer).each do |dy|
            (-buffer..buffer).each do |dz|
              next if dx == 0 && dy == 0 && dz == 0 # ignore self
              test_sample = sample_position(current.coord.x + dx, current.coord.y + dy, current.coord.z + dz)
              best_sample = test_sample if test_sample.better?(best_sample)
            end
          end
        end

        # then take a random sampling on the fringes
        fringes.each do |dx|
          fringes.each do |dy|
            fringes.each do |dz|
              next if dx == 0 && dy == 0 && dz == 0 # ignore self
              test_sample = sample_position(current.coord.x + dx, current.coord.y + dy, current.coord.z + dz)
              best_sample = test_sample if test_sample.better?(best_sample)
            end
          end
        end

        log("new best sample set", best_sample) if best_sample != current
      end

      break if best_sample == current
      current = best_sample
    end

    log "found best position", current
    current
  end

end

part "1 (example)" do
  input = """pos=<0,0,0>, r=4
pos=<1,0,0>, r=1
pos=<4,0,0>, r=3
pos=<0,2,0>, r=1
pos=<0,5,0>, r=3
pos=<0,0,3>, r=1
pos=<1,1,1>, r=1
pos=<1,1,2>, r=1
pos=<1,3,1>, r=1""".split("\n")

  state = State.new(input)
  bots = state.bots
  assert_call_on(bots, 9, :length)
  assert_call_on(bots, Bot.new(0, 0, 0, 4), :first)
  assert_call_on(bots, Bot.new(1, 3, 1, 1), :last)

  assert_call_on(state, Bot.new(0, 0, 0, 4), :strongest_signal)
  assert_call_on(state, 7, :nanobots_in_range_of, bots.first)
end

part "1" do
  state = State.new(input)
  strongest = state.strongest_signal
  assert_call_on(state, 499, :nanobots_in_range_of, strongest)
end

part "2 (example)" do
  input = """pos=<10,12,12>, r=2
pos=<12,14,12>, r=2
pos=<16,12,12>, r=4
pos=<14,14,14>, r=6
pos=<50,50,50>, r=200
pos=<10,10,10>, r=5""".split("\n")

  state = State.new(input, logging: true)
  best_sample = state.best_position_v2
  assert_equal(Coord.new(12, 12, 12), best_sample.coord, "best_position_v2()")
  assert_equal(36, best_sample.origin_distance, "origin distance")
end

part "2" do
  state = State.new(input, logging: true)
  best_sample = state.best_position_v2
  assert_equal(Coord.new(12, 12, 12), best_sample.coord, "best_position_v2()")
  assert_equal(36, best_sample.origin_distance, "origin distance")
end
