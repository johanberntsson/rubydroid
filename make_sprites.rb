#!/usr/bin/env ruby
#
# Utility to create new sprite images
# 

require "rubygems"
require "rubygame"
require "config"

require "robotlibrarian"

if __FILE__ == $0
    puts "Reading files from "+$datapath
    Rubygame.init()
    robotdata=RobotLibrarian.new
    robotdata.make_sprites("robots.bmp", false)
    robotdata.make_sprites("captured_robots.bmp", true)
    puts "robots.bmp and captured_robots.bmp created. Convert to png, e.g 'convert robots.bmp robots.png'"
end
