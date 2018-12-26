lines = $<.readlines.map(&:strip)

OPEN = ?.
TREE = ?|
LUMBER = ?#

grid = lines

def adj(grid, y, x)
  (-1..1).flat_map do |yd|
    next if y+yd < 0 || y+yd >= grid.size
    (-1..1).map do |xd|
      next if x+xd < 0 || x+xd >= grid.first.size || (yd == 0 && xd == 0)
      grid[y+yd][x+xd]
    end
  end
end

so_far = []
found = false

i = 0
ITER = 1000000000
until i == ITER do
  p i
  if !found && so_far.any? { |p| (0...grid.size).all? { |j| p[j] == grid[j] } }
    i = ITER - ITER % i
    found = true
  else
    so_far << grid.map { |l| l.dup }
  end

  new = grid.map { |l| l.dup }
  grid.each.with_index do |l, y|
    l.chars.each.with_index do |c, x|
      adjac = adj(grid, y, x)
      case c
      when OPEN
        new[y][x] = TREE if adjac.count(TREE) >= 3
      when TREE
        new[y][x] = LUMBER if adjac.count(LUMBER) >= 3
      when LUMBER
        new[y][x] = OPEN unless adjac.count(LUMBER) >= 1 && adjac.count(TREE) >= 1
      end
    end
  end
  grid = new
  i += 1
end

p grid.sum { |l| l.chars.count(TREE) } * grid.sum { |l| l.chars.count(LUMBER) }
