# Advent Boilerplate Start
require 'pry'

def test(value, expect, input)
  input = input.to_s.gsub("\n", "\\n").gsub("\t", "\\t")
  if input.length > 60
    input = input.slice(0,57) + '...'
  end

  check = '✓'
  outcome = expect.nil? ? '?' : (value == expect ? check : 'x')
  expect = '""' if expect == ""
  expected = (expect.nil? || outcome == check) ? '' : ", Expected: #{expect}"

  puts "  #{outcome} Value: #{value}#{expected}, Input: #{input}"
  return value
end

def test_call(method, expect, *args)
  result = self.send(method, *args)
  test(result, expect, "#{method}(#{args.to_s[1...-1]})")
end

def input
  @input ||= $<.map(&:to_s).map(&:strip)
  return @input[0] if @input.length == 1 # is this one line?
  @input.dup # prevents previous alteration to array
end

def part(num, &block)
  puts "Part #{num}:"
  yield
  puts ""
end
# Advent Boilerplate End


def is_bound?(coords, others)
  sorted_x   = others.sort_by(&:first)
  sorted_y   = others.sort_by(&:last)
  biggest_x  = sorted_x.last[0]
  biggest_y  = sorted_y.last[1]
  x          = coords[0]
  y          = coords[1]

  # explore the edges of our map to make sure we don't go onto infinity
  return false if closest_point(biggest_x, y, others) == coords # east
  return false if closest_point(0, y, others) == coords         # west
  return false if closest_point(x, biggest_y, others) == coords # south
  closest_point(x, 0, others) != coords                         # north
end

def closest_point(x, y, coords)
  coords_with_distance = coords.map do |x2, y2|
    [(x2 - x).abs + (y2 - y).abs, [x2, y2]]
  end.sort_by(&:first)

  return [] if coords_with_distance[0][0] == coords_with_distance[1][0]
  coords_with_distance.first[1]
end

def largest_finite_area(coordinates)
  max_width = coordinates.sort_by(&:first).last[0]
  max_height = coordinates.sort_by(&:last).last[1]

  contents = Hash.new
  (0..max_width).each do |x|
    (0..max_height).each do |y|
      contents[[x, y]] = closest_point(x, y, coordinates)
    end
  end

  bound = coordinates.select {|c| is_bound?(c, coordinates)}
  bound_area = bound.map {|b| contents.count{|_,v| v == b}}
  bound_area.sort.last
end

def total_safe_size(coordinates, min)
  max_width = coordinates.sort_by(&:first).last[0]
  max_height = coordinates.sort_by(&:last).last[1]
  count = 0

  (0..max_width).each do |x|
    (0..max_height).each do |y|
      distance_to_coords = coordinates.map do |coord|
        (coord[0] - x).abs + (coord[1] - y).abs
      end.sum

      count += 1 if distance_to_coords < min
    end
  end

  count
end

part 1 do
  example_input = [[1, 1], [1, 6], [8, 3], [3, 4], [5, 5], [8, 9]]
  bound_results = [false, false, false, true, true, false]

  bound_results.zip(example_input) do |criteria|
    test_call(:is_bound?, criteria[0], criteria[1], example_input)
  end

  test_call(:closest_point, [1, 1], 2, 2, example_input) # == A
  test_call(:closest_point, [3, 4], 2, 4, example_input) # == D
  test_call(:closest_point, [5, 5], 5, 2, example_input) # == E
  test_call(:closest_point, [], 1, 4, example_input) # == equidistant

  test_call(:largest_finite_area, 17, example_input)
  test_call(:largest_finite_area, nil, input.map {|coords| coords.split(",").map(&:to_i)})
end

part 2 do
  example_input = [[1, 1], [1, 6], [8, 3], [3, 4], [5, 5], [8, 9]]
  test_call(:total_safe_size, 16, example_input, 32)
  test_call(:total_safe_size, nil, input.map {|coords| coords.split(",").map(&:to_i)}, 10000)
end
