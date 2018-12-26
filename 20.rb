require './boilerplate'

class Room
  attr_accessor :x, :y, :step, :connections
  def initialize(x, y, step)
    @x, @y, @step = x, y, step
    @connections = []
  end

  def connect(other)
    @connections << other
    other.connections << self
  end

  def to_s
    "Room(x: #{@x}, y: #{@y}, step: #{step}, connections: #{connections.length})"
  end
end

class State
  include Loggable
  attr_accessor :start, :rooms

  def initialize(input, logging: false)
    @logging = logging
    @rooms   = {}
    @start   = Room.new(0, 0, 0)

    log "parsing input as:", input do
      parse(input[1...-1].chars.each, @start)
    end
  end

  def furthest_step; furthest_room.step; end
  def room_at(x, y); @rooms[[x, y]]; end
  def furthest_room; @rooms.map {|_, r| r}.max {|l, r| l.step <=> r.step}; end
  def rooms_with_steps(amount); @rooms.map {|_, r| r}.select {|r| r.step >= 1000}.length; end

  private def parse(input, source)
    begin
      last_room = source
      while true
        char = input.next
        case char
        when "N" then last_room = add_room(last_room.x, last_room.y - 1, last_room, char)
        when "E" then last_room = add_room(last_room.x + 1, last_room.y, last_room, char)
        when "S" then last_room = add_room(last_room.x, last_room.y + 1, last_room, char)
        when "W" then last_room = add_room(last_room.x - 1, last_room.y, last_room, char)
        when "(" then parse_branch(input, last_room)
        when ")" then return false # branch done
        when "|" then return true # branch continue
        else; raise "unknown character #{char} encountered while parsing"
        end
      end
    rescue StopIteration
      log "stop iteration raised, last character processed"
    end
  end

  private def parse_branch(branch_input, source)
    log "parsing branch from:", source do
      while parse(branch_input, source)
        log "continuing branch from:", source
      end
      log "branch complete from:", source
    end
  end

  private def add_room(x, y, from, char)
    existing = room_at(x, y)

    if existing.nil? # room doesn't exist, create it
      room = Room.new(x, y, from.step + 1)
      room.connect(from)
      @rooms[[x, y]] = room
      log "parsed #{char} into:", room
      room

    else # room already exists - sanity check step distance, don't think this ever occurs?
      raise "unexpected step from room #{existing} from #{from}" if (from.step - existing.step) > 1
      existing
    end
  end
end

part "1 (ex. 1)" do
  state = State.new("^WNE$")
  assert_call_on(state, state.room_at(0, -1), :furthest_room)
  assert_call_on(state, 3, :furthest_step)
end

part "1 (ex. 2)" do
  state = State.new("^ENWWW(NEEE|SSE(EE|N))$")
  assert_call_on(state, state.room_at(1, 1), :furthest_room)
  assert_call_on(state, 10, :furthest_step)
end

part "1 (ex. 3)" do
  state = State.new("^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$")
  assert_call_on(state, state.room_at(2, -2), :furthest_room)
  assert_call_on(state, 18, :furthest_step)
end

part "1 (ex. 4)" do
  state = State.new("^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$")
  assert_call_on(state, 23, :furthest_step)
end

part "1 (ex. 5)" do
  state = State.new("^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$")
  assert_call_on(state, 31, :furthest_step)
end

part "1" do
  state = State.new(input.strip)
  log_call_on(state, :furthest_step)
end

part "2" do
  state = State.new(input.strip)
  log_call_on(state, :rooms_with_steps, 1000)
end
