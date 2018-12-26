# Advent Boilerplate Start
 require 'pry'

class String
  def colorize(color_code); "\e[#{color_code}m#{self}\e[0m"; end
  def red; colorize(31); end
  def green; colorize(32); end
  def yellow; colorize(33); end
end

def value_string(val)
  value_str = val
  value_str = '"' + value_str + '"' if val.is_a?(String)
  value_str = 'nil' if val.nil?
  value_str
end

def assert_equal(expect, value, description)
  puts "  #{'✔'.green} #{description} == #{value_string(value)}" if value == expect
  puts "  #{'✖'.red} #{description}: expected #{value_string(expect)}, received #{value_string(value)}" if value != expect
  value
end

def assert_call(expect, *args)
  log_call(*args) {|m, r, desc| assert_equal(expect, r, "#{m}(#{desc})")}
end

def log_call(method, *args)
  arg_description = args.to_s[1...-1]
  arg_description = "..." if arg_description.length > 10
  method, arg_description = method if method.is_a?(Array)

  result = self.send(method, *args)
  return yield method, result, arg_description if block_given?
  puts "  #{'-'.yellow} #{method}(#{arg_description}) == #{value_string(result)}"
end

def input
  @input ||= $<.map(&:to_s)
  @input.length == 1 ? @input[0].dup : @input.dup # prevents alterations to source
end

def part(num, &block)
  puts "Part #{num}:".green; yield; puts ""
end
# Advent Boilerplate End

Unit = Struct.new(:id, :health, :attack, :enemy, :team)

class Map
  attr_accessor :tiles, :elves, :goblins, :walls, :round, :starting_elfs

  def initialize(data, elf_power = 3)
    @tiles = {}
    @elves = {}
    @goblins = {}
    @walls = {}
    @round = 0

    ids = 0

    data.each_with_index do |line, y|
      line.chars.each_with_index do |plot, x|
        case plot
        when '.'
          @tiles[[x, y]] = '.'
        when 'G'
          ids += 1
          @goblins[[x, y]] = Unit.new(ids, 200, 3, 'E', 'G')
          @tiles[[x, y]] = '.'
        when 'E'
          ids += 1
          @elves[[x, y]] = Unit.new(ids, 200, elf_power, 'G', 'E')
          @tiles[[x, y]] = '.'
        when '#'
          @walls[[x, y]] = '#'
        end
      end
    end

    @starting_elfs = @elves.length
  end

  def did_elves_die?
    @starting_elfs != @elves.length
  end

  def score
    score = 0
    score += @goblins.map {|_, g| g.health }.sum
    score += @elves.map {|_, g| g.health }.sum
    score * @round
  end

  def exec_round(logging = true)
    puts "RND #{@round}" if logging
    @elves.merge(@goblins).sort_by {|k ,v| k.reverse}.each do |_, unit|
      if @goblins.any? && @elves.any?
        unit_turn(unit, logging) if unit.health > 0
      else
        @round -= 1
        break
      end
    end

    @round += 1

    return (@goblins.any? && @elves.any?)
  end

  def unit_turn(unit, logging = true)
    pos = position(unit)
    puts "  TUR: #{unit.team}(#{pos[0]}, #{pos[1]})" if logging
    enemies_bes = enemies_beside(pos[0], pos[1], unit)
    enemies = unit.enemy == 'G' ? @goblins : @elves

    if enemies_bes.empty? # do we need to move?
      paths = enemies.map do |enemy_pos, e|
        [e, path_to(enemy_pos[0], enemy_pos[1])]
      end

      move_to = nil
      open_around(pos[0], pos[1]).each do |option|
        value_of = paths.map {|_, p| p[option]}.compact.min
        if !value_of.nil? && (move_to.nil? || move_to[0] > value_of)
          # binding.pry
          move_to = [value_of, option]
        end
      end

      if !move_to.nil?
        puts "    MOV: #{unit.team}([#{pos[0]}, #{pos[1]}] -> [#{move_to[1][0]}, #{move_to[1][1]}])" if logging
        pos = move(move_to[1][0], move_to[1][1], unit)
      end
    end

    enemies_bes = enemies_beside(pos[0], pos[1], unit)
    unless enemies_bes.empty?
      to_attack = enemies_bes.map {|p| [enemies[p], p[0], p[1]]}.sort_by {|a| [a[0].health, a[2], a[1]]}.first
      puts "    ATT: #{unit.team}([#{pos[0]}, #{pos[0]}] x [#{to_attack[1]}, #{to_attack[2]}])" if logging
      to_attack = to_attack[0]
      to_attack.health -= unit.attack

      if to_attack.health <= 0
        puts "    KIL: #{to_attack}" if logging
        remove(to_attack)
      end
    end
  end

  def remove(unit)
    team = unit.team == 'E' ? @elves : @goblins
    current_pos = position(unit)
    team.delete([current_pos[0], current_pos[1]])
  end

  def move(x, y, unit)
    team = unit.team == 'E' ? @elves : @goblins
    remove(unit)
    team[[x, y]] = unit
    [x, y]
  end

  def open?(x, y, path = nil)
    position = [x, y]
    @tiles.include?(position) && !@elves.include?(position) && !@goblins.include?(position) && !path&.include?(position)
  end

  def position(unit)
    team = unit.team == 'E' ? @elves : @goblins
    team.each do |k, v|
      return k if v == unit
    end
    raise "could not find position"
  end

  def enemies_beside(x, y, unit)
    enemies = unit.enemy == 'E' ? @elves : @goblins
    beside = [] # reading ordered
    beside.push([x, y - 1]) if enemies.include?([x, y - 1])
    beside.push([x - 1, y]) if enemies.include?([x - 1, y])
    beside.push([x + 1, y]) if enemies.include?([x + 1, y])
    beside.push([x, y + 1]) if enemies.include?([x, y + 1])
    beside
  end

  def open_around(x, y, path = nil)
    out = [] # reading ordered
    out.push([x, y - 1]) if open?(x, y - 1, path)
    out.push([x - 1, y]) if open?(x - 1, y, path)
    out.push([x + 1, y]) if open?(x + 1, y, path)
    out.push([x, y + 1]) if open?(x, y + 1, path)
    out
  end

  def path_to(x, y)
    step = 0
    path = {step => [[x, y]]}
    path[[x, y]] = step

    while path.include?(step)
      step += 1
      # p({step: step, path: path})

      path[step - 1].each do |cx, cy|
        open = open_around(cx, cy, path)
        if open.any?
          path[step] ||= []
          path[step] = path[step] + open
          open.each do |ox, oy|
            open_key = [ox, oy]
            path[open_key] = step unless path.include?(open_key)
          end
        end
      end
    end

    path
  end

  def to_s(path = nil)
    current_y = 0
    out = "0: "

    @tiles.merge(@walls).sort_by{|k, v| k.reverse}.each do |k, v|
      if k[1] != current_y
        out = out + "   "
        @elves.merge(@goblins).sort_by {|up, _| up[0]}.each do |pos, unit|
          if pos[1] == current_y
            out = out + "#{unit.team}(#{unit.health}) "
          end
        end

        out = out + "\n#{k[1]}: "
      end
      current_y = k[1]

      if @elves.include?(k)
        out = out + "E".green
      elsif @goblins.include?(k)
        out = out + "G".red
      elsif path&.include?(k)
        out = out + path[k].to_s
      else
        out = out + v
      end
    end
    out
  end
end

def run_game(data, logging)
  map = Map.new(data)

  while map.exec_round(logging)
    puts map.to_s if logging
  end

  puts "Done on Round #{map.round}" if logging
  puts map.to_s if logging
  map
end

def find_lowest_power(data, logging)
  elfs_lost = true
  elf_power = 4
  map = nil

  while elfs_lost
    map = Map.new(data, elf_power)
    while map.exec_round(logging)
      puts map.to_s if logging
    end

    puts "Done on Round #{map.round}" if logging
    elfs_lost = map.did_elves_die?
    elf_power += 1
  end

  map
end

part "1 & 2, Example 1" do
  example_input = [
    '#######',
    '#.G...#',
    '#...EG#',
    '#.#.#G#',
    '#..G#E#',
    '#.....#',
    '#######']

  map = Map.new(example_input)
  assert_equal(4, map.goblins.length, "goblins.length")
  assert_equal(2, map.elves.length, "elves.length")
  assert_equal(22, map.tiles.length, "tiles.length")
  assert_equal(true, map.open?(1, 1), "tile.open?")
  assert_equal(false, map.open?(2, 0), "wall.open?")
  assert_equal(false, map.open?(2, 1), "goblin.open?")
  assert_equal(false, map.open?(4, 2), "elf.open?")
  assert_equal(false, map.open?(1, 1, {[1, 1] => 1}), "tile.open?(path)")

  first_elf = map.elves[[4, 2]]
  first_elf_pos = map.position(first_elf)
  assert_equal([[5, 2]], map.enemies_beside(first_elf_pos[0], first_elf_pos[1], first_elf), "enemies_beside?(elves.first))")

  map = run_game(example_input, false)
  assert_equal(27730, map.score, "score")

  map = find_lowest_power(example_input, false)
  assert_equal(4988, map.score, "lowest score")
end

part "1, Example 2" do
  example_input = [
    '#######',
    '#G..#E#',
    '#E#E.E#',
    '#G.##.#',
    '#...#E#',
    '#...E.#',
    '#######',
  ]

  map = run_game(example_input, false)
  assert_equal(36334, map.score, "score")
end

part "1, Example 3" do
  example_input = [
    '#######',
    '#E..EG#',
    '#.#G.E#',
    '#E.##E#',
    '#G..#.#',
    '#..E#.#',
    '#######',
  ]
  map = run_game(example_input, false)
  assert_equal(39514, map.score, "score")
end

part "1, Example 4" do
  example_input = [
    '#######',
    '#E.G#.#',
    '#.#G..#',
    '#G.#.G#',
    '#G..#.#',
    '#...E.#',
    '#######',
  ]
  map = run_game(example_input, false)
  assert_equal(27755, map.score, "score")
end

part "1, Example 5" do
  example_input = [
    '#######',
    '#.E...#',
    '#.#..G#',
    '#.###.#',
    '#E#G#G#',
    '#...#G#',
    '#######',
  ]
  map = run_game(example_input, false)
  assert_equal(28944, map.score, "score")
end

part "1, Example 6" do
  example_input = [
    '#########',
    '#G......#',
    '#.E.#...#',
    '#..##..G#',
    '#...##..#',
    '#...#...#',
    '#.G...G.#',
    '#.....G.#',
    '#########',
  ]
  map = run_game(example_input, false)
  assert_equal(18740, map.score, "score")
end

part "1, Actual Input" do
  map = run_game(input, false)
  puts "  Score: #{map.score}"

  map = find_lowest_power(input, false)
  puts "  Lowest Score: #{map.score}"
end
