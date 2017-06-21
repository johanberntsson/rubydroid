#!/usr/bin/env ruby

require 'test/unit'
require 'paradroid'

class TestShip < Test::Unit::TestCase
  def test_loadship
    Rubygame.init()
    screen = Rubygame::Screen.set_mode([10,10])
    load_graphics
    ship=Ship.new("data/ship.d")
    assert_not_nil ship
  end
end
