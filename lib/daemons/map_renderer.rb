#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"
require File.expand_path(File.dirname(__FILE__)) + "/../../config/environment.rb"

require 'RMagick'

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



require 'map_renderer'
require 'fileutils'

AWS::S3::Base.establish_connection!(:access_key_id => AWS_ACCESS_KEY_ID, :secret_access_key => AWS_SECRET_ACCESS_KEY)

MapImagesDir = File.expand_path(Rails.root) + '/public/images/maps'
MapPublicImagesDir = "#{Rails.env}/maps"

puts "MapRenderer started at #{Time.now}."

while($running) do
  mr = MapRenderer.new
  
  begin
    if map = Map.where(:status => 'published', :img_full => nil).first or map = Map.where(:status => 'published', :img_full.exists => false).first
      puts '. ' + map.name
      today = Date.today
      
      year = today.year.to_s
      month = today.month.to_s
      day = today.day.to_s
      
      file_path_full = File.join(MapImagesDir, year, month, day, "#{map._id}_full.jpg")
      file_path_medium = File.join(MapImagesDir, year, month, day, "#{map._id}_medium.jpg")
      
      public_path_full = [MapPublicImagesDir, year, month, day, "#{map._id}_full.jpg"].join('/')
      public_path_medium = [MapPublicImagesDir, year, month, day, "#{map._id}_medium.jpg"].join('/')
      
      FileUtils.mkdir_p(File.join(MapImagesDir, year, month, day))
      
      mr.set_data(map.tiles, map.bases, map.units)
      mr.render(file_path_full, file_path_medium)
      
      AWS::S3::S3Object.store(public_path_full, open(file_path_full), AWS_DEFAULT_S3_BUCKET, :access => :public_read)
      AWS::S3::S3Object.store(public_path_medium, open(file_path_medium), AWS_DEFAULT_S3_BUCKET, :access => :public_read)
      
      File.unlink(file_path_full)
      File.unlink(file_path_medium)
      
      map.img_full = "http://s3.amazonaws.com/#{AWS_DEFAULT_S3_BUCKET}/#{public_path_full}"
      map.img_medium = "http://s3.amazonaws.com/#{AWS_DEFAULT_S3_BUCKET}/#{public_path_medium}"
      map.save!

      puts '-'
    else
      $running = false
    end
    
    sleep 1
  rescue
    puts $!.inspect
    puts $!.backtrace.join("\n")
  end
end

puts "MapRenderer finished at #{Time.now}."
