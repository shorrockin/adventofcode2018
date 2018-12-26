require './boilerplate'

module Teams
  Immune = :immune
  Infection = :infection
end

INPUT_PATTERN = /(\d+) units each with (\d+) hit points( \(.*\))? with an attack that does (\d+) (\w+) damage at initiative (\d+)/
WEAKNESS_PATTERN = /weak to ([\w, ]+)[\);]/
IMMUNE_PATTERN = /immune to ([\w, ]+)[\);]/

Group = Struct.new(:id, :team, :units, :max_units, :hit_points, :weaknesses, :immunities, :attack, :attack_type, :boost, :initiative) do
  def effective_power; (attack + boost) * units; end
  def selection_order_sort; [-effective_power, -initiative]; end
  def attack_order_sort; -initiative; end
  def dead?; units <= 0; end

  def calculate_damage_from(from)
    return -1 if from.team == team
    return 0 if immunities.include?(from.attack_type)
    return from.effective_power unless weaknesses.include?(from.attack_type)
    from.effective_power * 2
  end

  def team_id
    return id.to_s.green if team == Teams::Immune
    id.to_s.red
  end
end

class State
  include Loggable
  attr_accessor :groups, :round
  def initialize(input, logging: false)
    @logging = logging
    @round = 0

    ids = {
      Teams::Immune => 0,
      Teams::Infection => 0
    }

    @team = Teams::Immune
    @groups = input.map(&:strip).map do |line|
      next if line == ""
      next if line == "Immune System:"

      if line == "Infection:"
        @team = Teams::Infection
        next
      end

      match = INPUT_PATTERN.match(line)
      conditions = match[3]
      weaknesses = []
      immunities = []

      if !conditions.nil?
        if weak_match = WEAKNESS_PATTERN.match(conditions)
          weaknesses = weak_match[1].split(", ")
        end

        if immune_match = IMMUNE_PATTERN.match(conditions)
          immunities = immune_match[1].split(", ")
        end
      end

      ids[@team] += 1
      Group.new(ids[@team], @team, match[1].to_i, match[1].to_i, match[2].to_i, weaknesses, immunities, match[4].to_i, match[5], 0, match[6].to_i)
    end.compact

    def reset(boost)
      @groups.each do |g|
        g.units = g.max_units
        g.boost = boost if g.team == Teams::Immune
      end
      @round = 0
      fight
    end

    def fight
     teams_alive = {Teams::Immune => true, Teams::Infection => true}

      while teams_alive[Teams::Immune] && teams_alive[Teams::Infection]
        @round += 1
        orders = []
        untargeted = @groups.select {|t| !t.dead?}

        log "round #{@round.to_s.blue} starting" do
          @groups.sort_by(&:selection_order_sort).each do |attacker|
            next if attacker.dead?

            target = untargeted.max_by {|t| [t.calculate_damage_from(attacker), t.effective_power, t.initiative] }
            damage = target.calculate_damage_from(attacker)

            if damage == 0 || target.team == attacker.team
              log "attack group #{attacker.team_id} could not find target to do damage to"
            else
              orders << [attacker.attack_order_sort, attacker, target]
              untargeted.delete(target)
              log "attacking group #{attacker.team_id} would deal defending group #{target.team_id} #{damage} damage"
            end
          end

          orders.sort.each do |_, attacker, target|
            unless attacker.dead?
              damage = target.calculate_damage_from(attacker)
              units_killed = [damage / target.hit_points, target.units].min
              target.units -= units_killed
              log "group #{attacker.team_id} attacking #{target.team_id}, killing #{units_killed} units"
            else
              log "skipping group #{attacker.team_id}, was killed recently"
            end
          end

          log "round complete, remaining groups:" do
            teams_alive = {Teams::Immune => false, Teams::Infection => false}
            @groups.each do |group|
              unless group.dead?
                teams_alive[group.team] = true
                log "group #{group.team_id} contains #{group.units} units"
              end
            end
          end
        end
      end
    end

    def remaining_units; @groups.sum(&:units); end
  end
end

part "1 example" do
  input = """Immune System:
17 units each with 5390 hit points (weak to radiation, bludgeoning) with an attack that does 4507 fire damage at initiative 2
989 units each with 1274 hit points (immune to fire; weak to bludgeoning, slashing) with an attack that does 25 slashing damage at initiative 3

Infection:
801 units each with 4706 hit points (weak to radiation) with an attack that does 116 bludgeoning damage at initiative 1
4485 units each with 2961 hit points (immune to radiation; weak to fire, cold) with an attack that does 12 slashing damage at initiative 4""".split("\n")

  state = State.new(input, logging: false)
  state.fight
  assert_call_on(state, 5216, :remaining_units)
end

part "1" do
  state = State.new(input, logging: true)
  state.fight
  log_call_on(state, :remaining_units)

  # part 2 manually ran, did binary search until we had boost level (88), mid 80s had some infinite loops
  # binding.pry
end
