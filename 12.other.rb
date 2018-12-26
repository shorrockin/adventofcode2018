input = (ARGV.empty? ? DATA : ARGF).each_line.map(&:chomp)

initial = input.shift.split(?:).last.strip.each_char.map { |c| c == ?# }
input.shift

rules = input.each_with_object({}) { |x, h|
  l, r = x.split(' => ')
  h[l.each_char.map { |c| c == ?# }] = r == ?#
}.freeze

sums = {}

leftmost = 0
# Arbitrarily choose to stop after this many iterations have same diff:
diffs = [nil] * 10

plants = initial
sums[0] = plants.zip(leftmost.step).sum { |p, i| p ? i : 0 }

gens_done = 1.step { |gen|
  plants = ([false, false, false, false] + plants + [false, false, false, false]).each_cons(5).map { |c| rules.fetch(c) }
  leftmost -= 2
  sums[gen] = plants.zip(leftmost.step).sum { |p, i| p ? i : 0 }
  diffs.shift
  diffs << sums[gen] - sums[gen - 1]
  break gen if diffs.uniq.size == 1
}

puts sums[20]
puts sums[gens_done] + diffs[0] * (50 * 10 ** 9 - gens_done)
