#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"
require File.expand_path(File.dirname(__FILE__)) + "/../../config/environment.rb"
require 'rest_client'

$running = true
Signal.trap("TERM") do
  $running = false
end
Signal.trap("INT") do
  $running = false
end
Signal.trap("KILL") do
  $running = false
end



if Rails.env.development?
  HOST = 'localhost'
  PORT = 3000
else
  HOST = 'elitecommand.net'
  PORT = 80
end

AI_USER = User.where(:username => 'TomServo').first

def send_command(gid, cmd, params)
  puts "Sending #{cmd}."
  p = { :command => cmd, :as => AI_USER.id.to_s, :as_pwd => AI_USER.password_hash }.merge(params)
  RestClient.post("http://#{HOST}:#{PORT}/games/#{gid.to_s}/execute_command", p)
end

while($running) do
  begin
    ai_user = AI_USER
    ai_user.games.select { |g| g.status == 'started' and g.current_user == ai_user }.each do |g|
      # Make one move for this game

      # Each unit has the following priorities (in this order):
      # 1. Capture base unit is standing on (if the unit is standing on a neutral or enemy base and can capture)
      # 2. Attack nearest attackable enemy unit (tie-breaker: enemy unit most vulnerable to the unit type)
      # 3. Move toward the nearest neutral or enemy base

      took_unit_action = false

      g.units.each do |u|
        next if u.player_id.to_s != ai_user.id.to_s
        next if b = g.base_at(u.x, u.y) and b.capture_phase

        if b = g.base_at(u.x, u.y) and b.player_id.to_s != ai_user.id.to_s and u.can_capture?
          # Capture the base
          send_command(g.id, 'CaptureBase', x: u.x, y: u.y)
          took_unit_action = true
          break
        end

        b = g.base_at(u.x, u.y)
        if u.has_enough_attack_points_to_attack? and u.attack_allowed_by_attack_type? \
           and (!b or !b.capture_phase)

          range_cost_map = {}
          g.map.tiles_hash.each do |coords, tile_index|
            range_cost_map[coords] = 1
          end

          rf = RangeFinder.new(range_cost_map, u)
          possible_targets = rf.possible_destination_tiles.keys

          # See if there is a unit within attack range
          defender = g.units.find do |defender|
            u.can_attack_unit_type?(defender.unit_type) and possible_targets.include?([defender.x, defender.y]) \
              and defender.player_id.to_s != ai_user.id.to_s
          end

          if defender
            send_command(g.id, 'Attack', unit_x: u.x, unit_y: u.y, target_x: defender.x, target_y: defender.y)
            took_unit_action = true
            break
          end

        end

        # If we made it here, the only thing left to do is move toward the closest
        # enemy or neutral base that is not occupied by one of our units (if we can)
        possible_bases = g.bases.select do |b|
          ou = g.unit_at(b.x, b.y)

          b.player_id.to_s != ai_user.id.to_s and \
            (!ou or ou.player_id.to_s != ai_user.id.to_s)
        end

        next if possible_bases.empty? # We must have won already, units don't need to do anything

        closest_base = possible_bases.inject do |b, mem|
          new_distance = Math.sqrt((b.x - u.x)**2 + (b.y - u.y)**2)
          old_distance = Math.sqrt((mem.x - u.x)**2 + (mem.y - u.y)**2)
          (new_distance < old_distance ? b : mem)
        end

        # Determine reachable locations
        cost_map = {}
        g.map.tiles_hash.each do |coords, tile_index|
          cost_map[coords] = u.terrain_cost(g.terrain_at(*coords), g.unmodified_terrain_at(*coords))
        end

        pf = PathFinder.new(cost_map, u, g.rival_units)
        occupied_tiles = g.units.map { |ou| [ou.x, ou.y] }
        dests = pf.possible_destination_tiles.except(*occupied_tiles)

        next if dests.empty? # Nevermind this unit if they can't move at all

        dests = dests.map { |d| d[0] }
        dest = dests.inject do |d, mem|
          new_distance = Math.sqrt((closest_base.x - d[0])**2 + (closest_base.y - d[1])**2)
          old_distance = Math.sqrt((closest_base.x - mem[0])**2 + (closest_base.y - mem[1])**2)
          (new_distance < old_distance ? d : mem)
        end

        send_command(g.id, 'MoveUnit', unit_x: u.x, unit_y: u.y, dest_x: dest[0], dest_y: dest[1])
        took_unit_action = true
        break
      end

      # If we never took a unit action, then try to build a unit at a random one of our unoccupied bases
      
      took_base_action = false

      # 25% chance of skipping a build and going straight to ending turn
      if rand < 0.75
        if !took_unit_action
          if base = g.bases.select { |b| !g.unit_at(b.x, b.y) and b.player_id.to_s == ai_user.id.to_s }.sample
            affordable_units = base.unit_types.select do |type|
              UnitDefinitions[type][:credits] <= g.user_credits(ai_user)
            end - [:MobileFlak]

            if u = affordable_units.sample
              send_command(g.id, 'BuyUnit', x: base.x, y: base.y, unit_type: u)
              took_base_action = true
            end
          end
        end
      end

      # If we never took a unit or base action, then we are out of moves; end turn
      if !took_unit_action and !took_base_action
        send_command(g.id, 'EndTurn', {})
      end
    end

    puts 'Sleeping.'
    sleep 1
  rescue
    puts $!.inspect
    puts $!.backtrace.join("\n")
  end
end

