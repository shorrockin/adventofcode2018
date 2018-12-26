require 'pry'

def lines
  @lines ||= File.readlines('./04.input.txt')
  # @lines ||= File.readlines('./04.input.example.txt')
end

BEGINS = /\[(\d+)-(\d+)-(\d+) (\d+):(\d+)\] Guard \#(\d+) begins shift/
WAKES = /\[(\d+)-(\d+)-(\d+) (\d+):(\d+)\] wakes up/
SLEEPS = /\[(\d+)-(\d+)-(\d+) (\d+):(\d+)\] falls asleep/

class Log
  attr_reader :year, :month, :day, :hour, :minute, :guard, :type, :line
  def initialize(line)
    res = nil
    @line = line

    if res = BEGINS.match(line)
      @guard = res[6].to_i
      @type = :begins
    elsif res = WAKES.match(line)
      @type = :wakes
    elsif res = SLEEPS.match(line)
      @type = :sleeps
    else
      raise "invalid line: #{line}"
    end

    @year = res[1].to_i
    @month = res[2].to_i
    @day = res[3].to_i
    @hour = res[4].to_i
    @minute = res[5].to_i
  end
end

def parse_sleep_time(parsed)
  time_asleep = Hash.new

  active_guard = nil
  sleep_start = nil
  parsed.each do |p|
    if p.type == :begins
      active_guard = p.guard
    elsif p.type == :sleeps
      sleep_start = p.minute
    elsif p.type == :wakes
      time_asleep[active_guard] ||= []
      (sleep_start...p.minute).each {|m| time_asleep[active_guard] << m}
    end
  end

  time_asleep
end

logs        = lines.map {|l| Log.new(l)}.sort_by{|l| [l.year, l.month, l.day, l.hour, l.minute]}
time_asleep = parse_sleep_time(logs)
max_sleeper = time_asleep.max_by{|k,v| v.length}
hour        = max_sleeper[1].group_by(&:to_s).max_by{|_,v| v.length}.first.to_i

puts "1: #{max_sleeper[0] * hour}"

max_guards_sleep_hour = time_asleep.map{|g,m| [g,m.group_by(&:to_i).max_by{|_,v|v.length}]}.to_h.map{|k,v| [k,v[0],v[1].length]}
max_guard = max_guards_sleep_hour.sort_by{|ary|ary[2]}.last

p(max_guard) # guard, minute, number of times slept at that minute
puts "2: #{max_guard[0] * max_guard[1]}"
