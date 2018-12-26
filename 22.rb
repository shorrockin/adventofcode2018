require './boilerplate'
require 'set'
require 'priority_queue'

ROCKY = "."
NARROW = "|"
WET = "="

MOVE_TIME = 1
SWITCH_TIME = 7

def wrap(phrase, color, inner)
  out = phrase.send(color)
  out += "(".send(color)
  out += inner
  out += ")".send(color)
  out
end

Tool = Struct.new(:name, :usable) do
  def to_s
    wrap("Tool", :blue, name)
  end
end

def tools_in_terrain(t)
  case t
  when ROCKY then [TORCH, CLIMBING]
  when NARROW then [TORCH, NEITHER]
  when WET then [CLIMBING, NEITHER]
  end
end

TORCH    = Tool.new("torch", [ROCKY, NARROW])
CLIMBING = Tool.new("climbing", [WET, ROCKY])
NEITHER  = Tool.new("neither", [WET, NARROW])
TOOLS    = [TORCH, CLIMBING, NEITHER]

NEIGHBORS = [[0, 0], [0, 1], [1, 0], [-1, 0], [0, -1]]

Region = Struct.new(:coord, :geologic, :erosion, :type, :risk)

Coord = Struct.new(:x, :y) do
  def to_s
    wrap("Coord", :yellow, "x: #{x}, y: #{y}")
  end
end

RegionWithTool = Struct.new(:region, :tool) do
  def to_s
    wrap("RegionWithTool", :red, "coord: #{region.coord}, tool: #{tool.name}")
  end
end

Distance = Struct.new(:value, :tool, :from) do
  def to_s
    wrap("Distance", :green, "value: #{value || 'nil'}, tool: #{tool || 'nil'}, from: #{from || 'nil'}")
  end
end

MAX_TRAVEL = Float::INFINITY

class State
  include Loggable
  attr_accessor :depth, :target, :mouth, :regions
  def initialize(depth, target, logging: false)
    @logging = logging
    @depth   = depth
    @regions = (target.y * 2).times.map { (target.x * 2).times.map {nil} }

    @mouth = create_region(Coord.new(0, 0), geologic: 0)
    @target = create_region(target, geologic: 0)

    @regions.each_with_index do |row, y|
      row.each_with_index do |region, x|
        create_region(Coord.new(x, y)) if region.nil?
      end
    end
  end

  def create_region(coord, geologic: nil)
    if geologic.nil?
      geologic = coord.x * 16807 if coord.y == 0
      geologic = coord.y * 48271 if coord.x == 0
      geologic = at(coord.x - 1, coord.y).erosion * at(coord.x, coord.y - 1).erosion if geologic.nil?
    end

    erosion = (@depth + geologic) % 20183

    type = case (erosion % 3)
    when 0 then ROCKY
    when 1 then WET
    when 2 then NARROW
    end

    risk = case type
    when ROCKY then 0
    when WET then 1
    when NARROW then 2
    end

    @regions[coord.y][coord.x] = Region.new(coord, geologic, erosion, type, risk)
  end

  def target_risk
    @regions[0, @target.coord.y + 1].map do |row|
      row[0, @target.coord.x + 1]
    end.flatten.map(&:risk).sum
  end

  def fastest_route
    unvisited = @regions.flatten.map {|r| tools_in_terrain(r.type).map {|t| RegionWithTool.new(r, t)} }.flatten.to_set
    distances = {} # unvisited.map {|rt| [rt, Distance.new(nil, nil, nil)]}.to_h

    # log "initializing starting point to zero", unvisited.first
    distances[unvisited.first] = Distance.new(0, TORCH, unvisited.first)

    while unvisited.any?
      current = smallest_unvisited(unvisited, distances)
      current_distance = distances[current]

      # log "analyzing current", current, current_distance do
        neighbors = unvisited_neighbors(unvisited, current)

        neighbors.each do |neighbor|
          # log "analyzing neighbor", neighbor do
            distance = distance_between(current, neighbor, current_distance)
            # log "calculated distance", distance

            existing_distance = distances[neighbor]&.value
            if existing_distance.nil? || existing_distance > distance.value
              # log "updating distance from #{existing_distance || 'nil'} to #{distance}"
              distances[neighbor] = distance
            else
              # log "ignoring distance existing #{existing_distance || 'nil'} in <= #{distance}"
            end
          # end
        end
      # end

      # binding.pry
      unvisited.delete(current)
    end

    distances[RegionWithTool.new(@target, TORCH)].value
  end

  def at(x, y)
    return nil if y < 0 || y >= @regions.length
    return nil if x < 0 || x >= @regions[y].length
    @regions[y][x]
  end

  def distance_between(from, to, distance) # assumes neighbors always passed in
    # if we're moving to oursef this is a noop
    if from == to
      return Distance.new(distance.value, distance.tool, from)
    end

    # checks to see if the tool we currently have in our previous distance state
    # is compatible with the region we're traveling to
    if to.tool == distance.tool
      return Distance.new(distance.value + 1, distance.tool, from)
    end

    # otherwise we need to switch tools so we'll incure 7 minutes to switch, plus 1
    # to travel if we're changing the region
    return Distance.new(distance.value + (from.region != to.region ? 8 : 7), to.tool, from)
  end

  def smallest_unvisited(unvisited, distances)
    smallest = nil
    smallest_region = nil

    unvisited.each do |region|
      distance = distances[region]
      if !distance.nil?
        if smallest.nil? || distance.value < smallest.value
          smallest = distance
          smallest_region = region
          return region if distance.value <= 1 # minor performance hack
        end
      end
    end

    smallest_region
  end

  def neighbors(region_with_tool, unvisited)
    neighbors = []
    region = region_with_tool.region

    NEIGHBORS.each do |n|
      candidate = at(n[0] + region.coord.x, n[1] + region.coord.y)

      if candidate && candidate != region # ignore self
        tools_in_terrain(candidate.type).each do |t|
          rt = RegionWithTool.new(candidate, t)
          if unvisited.include?(rt)
            neighbors << rt
          end
        end
      end
    end

    neighbors

    # region = region_with_tool.region
    # neighbors = NEIGHBORS.map {|n| at(n[0] + region.coord.x, n[1] + region.coord.y)}.compact
    # neighbors = neighbors.map {|n| tools_in_terrain(n.type).map {|t| RegionWithTool.new(n, t) }}.flatten
    # neighbors.reject {|n| n == region_with_tool || !unvisited.include?(n) } # remove self & already visited
  end

  def unvisited_neighbors(unvisited, region)
    neighbors(region, unvisited).select {|n| unvisited.include?(n)}
  end

end

part "1/2" do
  state = State.new(510, Coord.new(10, 10), logging: false)
  assert_call_on(state, 114, :target_risk)
  assert_call_on(state, 45, :fastest_route)

  state = State.new(5355, Coord.new(14, 796))
  assert_call_on(state, 11972, :target_risk)
  assert_call_on(state, 1092, :fastest_route)
end
