require 'pry'
require './utils'

def lines
  @lines ||= Utils.lines('./03.input.txt')
end

class Claim
  attr_reader :id, :x, :y, :width, :height
  def initialize(line)
    parsed = /\#([0-9]+) \@ ([0-9]+),([0-9]+)\: ([0-9]+)x([0-9]+)/.match(line)
    @id = parsed[1]
    @x = Integer(parsed[2])
    @y = Integer(parsed[3])
    @width = Integer(parsed[4])
    @height = Integer(parsed[5])
  end

  def occupy(data)
    (0...width).each do |w|
      (0...height).each do |h|
        data[[w + x, h + y]] ||= 0
        data[[w + x, h + y]] += 1
      end
    end
  end

  def alone?(data)
    (0...width).each do |w|
      (0...height).each do |h|
        if data[[w + x, h + y]] != 1
          return false
        end
      end
    end
    true
  end
end

claims = lines.map {|l| Claim.new(l)}
contents = Hash.new
claims.each {|c| c.occupy(contents)}

cnt = 0
contents.each do |key, value|
  if value > 1
    cnt +=1
  end
end
puts cnt

sel = claims.select {|c| c.alone?(contents)}
puts sel.first.id
