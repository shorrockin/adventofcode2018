serial = 8979

def power_level(x, y, serial)
  rack_id = x + 10
  level = ((rack_id * y) + serial) * rack_id
  level = (level / 100) % 10
  level - 5
end

def grid(serial)
  (1..300).map do |y|
    (1..300).map { |x| power_level(x, y, serial) }
  end
end

def biggest_square(width, grid)
  last_idx = 300 - (width - 1)
  squares = (1..last_idx).map do |y|
    (1..last_idx).map do |x|
      sum = grid[(y - 1)...(y - 1 + width)].
        map {|column| column[(x - 1)...(x - 1 + width)]}.
        flatten.
        sum
      [x, y, sum]
    end
  end

  squares.flatten(1).max_by {|s| s[2]}
end

grid = grid(serial)
puts biggest_square(3, grid)
puts (2..20).map { |n| biggest_square(n, grid) + [n] }.max_by {|s| s[2]}
