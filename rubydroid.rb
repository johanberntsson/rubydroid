#!/usr/bin/env ruby
# 
# A Paradroid clone written by Johan Berntsson 2007
# This code is in the public domain, but some of the
# data may be under copyright by other companies. Use
# at your own risk

=begin
TODO:
* use $redraw
* game balancing (work out proper strenght and demotions)
* only the floor tile should be transparent (colorkey in Deck...)
=end



require "rubygems"
require "rubygame"
require "config"

require "views"
require "sprites"
require "robotlibrarian"

$window_size={
  :application => Rubygame::Rect.new(0,0,640,370),
  :status => Rubygame::Rect.new(0,0,640,50),
  :game => Rubygame::Rect.new(0,50,640,370-50),
  :map => Rubygame::Rect.new(0,0,640,370-50)
}

$deck_color=[
  { :color=>$color[:lightGray], :tiles=>"graytiles.png" },
  { :color=>$color[:lightBlue], :tiles=>"bluetiles.png" },
  { :color=>$color[:yellow], :tiles=>"yellowtiles.png" },
  { :color=>$color[:green], :tiles=>"greentiles.png" },
  { :color=>$color[:cyan], :tiles=>"cyantiles.png" },
  { :color=>$color[:lightRed], :tiles=>"redtiles.png" }
]

# data format: filename | [filename,tilewidth,transparentcolor]
$graphics={
  :win=>"win.png",
  :logo=>"logo.png",
  :fail=>"fail.png",
  :splash=>"splash.png",
  :console=>"console.png",
  :robots=>[ "robots.png", 64],
  :captured_robots=>[ "captured_robots.png", 64],
  :explosion=>[ "explosion.png", 64, [0,0]],
  :lasers=>[ "laser.png", 64]
}

$sounds={
  :explosion=>"explode.wav",
  :door=>"door.wav",
  :fail=>"fail.wav",
  :bump=>"bump.wav",
  :health=>"health.wav",
  :laser=>"laser.wav",
  :win=>"win.wav"
}

class Deck
  attr_reader :vdoor_images, :hdoor_images
  attr_reader :image, :color, :name, :map, :elevators, :index
  attr_reader :robot_sprites, :laser_sprites, :door_sprites, :explosion_sprites
  attr_accessor :flash
  
  def initialize(index, robots, tile_order, floor_tiles, special_tiles)
    @robots=robots
    @tile_order=tile_order
    @floor_tiles=floor_tiles
    @special_tiles=special_tiles
    
    @flash=0
    @index=index
    @robot_sprites=RobotGroup.new
    @door_sprites=DoorGroup.new
    @laser_sprites=LaserGroup.new
    @explosion_sprites=ExplosionGroup.new
    @vdoor_images=Array.new
    @hdoor_images=Array.new
  end

  def load(file)
    @map=Array.new
    @elevators=Array.new
    @name=@tile_set=nil
    robots=Array.new
    
    loop do
      line=file.gets.strip
      skip=(line=~/^#/ || line.empty?)
      if @name.nil? && !skip
        @name=line
      elsif @tile_set.nil? && !skip
        @tile_set=line.to_i
        #puts @tile_set
      elsif line=~/^\d/
        robots.push line
      else
        break if @map.length>0 && line.length!=@map[0].length
        @map.push line if !skip
      end
    end
    
    # Add robots (cheat to make it fit with old C++ system)
    # TODO: simplify robot defintions (don't add abc... in @map)
    if robots.length==0
      # Add some random robots
      for i in 0...2
        x="%d 1"%$robotdata.name(1+rand($robotdata.count-1))
        robots.push x
      end
    end
    robots.each { |line|
      name, count, x, y=line.split
      for name_id in 0..$robotdata.count
        raise "Robot error" if name_id==$robotdata.count
        break if $robotdata.name(name_id)==name
      end
      for i in 0...count.to_i
        xx=x.to_i
        yy=y.to_i
        loop do
          if x.nil?
            xx=rand(@map[0].length)
            yy=rand(@map.length)
          else
            raise "Can't put robot at x,y" if @map[yy][xx]!=46
          end
          break if @map[yy][xx]==46
        end
        @map[yy][xx]=name_id+97
      end
    }
    
    make_deck_image
  end
  
  def floor?(pos)
    tile=@floor_tiles.index(@map[pos[1]/64][pos[0]/64])
    !tile.nil?
  end
  
  def num_robots
    n=robot_sprites.length
    # An explosion is the remains of a robot
    n+=explosion_sprites.length
    return n
  end
  
  private

  def make_deck_image
    # return true if this is the starting deck (with robot 001)
    is_start_deck=false

    @image=Rubygame::Surface.new([@map[0].length*64, @map.length*64],$SURFACE_FLAGS)
    @color=$deck_color[@tile_set][:color]
    tiles=$deck_color[@tile_set][:tiles]
    
    # Extract door tiles
    [ 17, 18, 19, 15 ].each{ |x| @vdoor_images.push tiles[x] }
    [ 27, 28, 29, 26 ].each{ |x| @hdoor_images.push tiles[x] }
    
    (0...@map.length).each { |y|
      (0...@map[y].length).each { |x|
        tile=@tile_order.index(@map[y][x])
        # Is this an elevator?
        if tile.nil?
          tile="123456789".index(@map[y][x])
          if !tile.nil?
            @map[y][x]="@"
            @elevators[tile]=[x,y]
            tile=@tile_order.index("@")
          end
        end
        # Is this a robot?
        if tile.nil?
          robot=@robots.index(@map[y][x])
          if !robot.nil?
            tile=@tile_order.index(".")
            if robot==0
              is_start_deck=true
              $game.player=Player.new(robot, x, y)
              #puts "Starting on deck "+@name
            else
              @robot_sprites << Robot.new(robot, x, y)
            end
            @map[y][x]="."
          end
        end
        
        # Is this a door?
        if @map[y][x]==45 #"-"
          @door_sprites << Door.new(x*64, y*64, @hdoor_images)
        elsif @map[y][x]==124 # "|"
          @door_sprites << Door.new(x*64, y*64, @vdoor_images)
        end

        # Add picture
        tiles[tile].blit(@image,[x*64,y*64])
      }
    }
    is_start_deck
  end
end

class Ship
  attr_reader :deck, :name, :map, :elevators

  def initialize(filename)
    phase=0
    @name=nil
    @map=Array.new
    @decks=Array.new
    @elevators=Array.new
    file=File.open($datapath+filename)
    loop do
      break if file.eof
      
      line=file.gets.strip
      skip=(line=~/^#/ || line.empty?)
      if phase==0 && !skip
        phase=1
        @name=line
      elsif phase==1 && !skip
        phase=2
        @robots=line.split[2] # the first 2 arguments are redundant
      elsif phase==2 && !skip
        phase=3
        @tile_order=line
      elsif phase==3 && !skip      
        phase=4
        line=line.split
        @special_tiles=line[0]
        @floor_tiles=line[1]
      elsif phase==4
        if @map.length>0 && line.length!=@map[0].length
          phase=5
        else
          @map.push line if !skip
        end
      end
      
      if phase==5
        new_deck=Deck.new(@decks.length, @robots, @tile_order, @floor_tiles, @special_tiles)
        if new_deck.load(file)
          @deck=new_deck
        end
        @decks.push new_deck
        @elevators.push(new_deck.elevators)
      end
    end
    file.close
  end
  
  def change_deck(new_deck)
    @deck=@decks[new_deck]
  end
  
  def num_robots
    n=0
    @decks.each { |deck| n+=deck.num_robots }
    n
  end
end

class Game
  attr_reader :ship
  attr_accessor :player
  
  def play_sound(sound)
    begin
      case $sound_enabled
      when :SDL
        Rubygame::Mixer::play($sounds[sound],-1,0)
      when :aplay
        if fork==nil
          system("aplay -q "+$datapath+"sounds/"+$sounds[sound])
          exit
        end
      end
    rescue
    end
  end
  
  def load_graphics
    # Init fonts
    Rubygame::TTF.setup()
    $font=Rubygame::TTF.new($datapath+"freesansbold.ttf",12)
    raise "Font file not found" if $font.nil?
    
    # Init sounds
    Rubygame::Mixer::open_audio(22050, Rubygame::Mixer::AUDIO_U8, 2, 1024)
    $sounds.each_pair { |key, value|
      $sounds[key]=Rubygame::Mixer::Sample.load_audio($datapath+"sounds/"+value)
      raise "Sound file not found" if $sounds[key].nil?
    }
    if $music_enabled
      $music=Rubygame::Mixer::Music.load_audio($datapath+"sounds/(sblu)moon6.xm")
      raise "Music file not found" if $music.nil?
      Rubygame::Mixer::play_music($music, -1)
    end
    
    # Init graphics
    for i in 0...$deck_color.length
      $deck_color[i][:tiles]=load_tiles("tiles/"+$deck_color[i][:tiles], 64, nil)
    end
    $graphics.each_pair { |key, value|
      if value.class==Array
        $graphics[key]=load_tiles("sprites/"+value[0], value[1], value[2])
      else
        $graphics[key]=Rubygame::Surface.load_image($datapath+"images/"+value)
        raise "Graphics file not found" if $graphics[key].nil?
      end
    }
  end

  def load_tiles(filename, size, colorkey_source)
    tiles=Array.new
    puts "JB "+$datapath+filename
    image=Rubygame::Surface.load_image($datapath+filename)
    raise "Graphics file not found" if image.nil?
    xx=image.width/size
    yy=image.height/size
    (0...yy).each { |y|
      (0...xx).each { |x|
        tile=Rubygame::Surface.new([64,64],$SURFACE_FLAGS)
        image.blit(tile, [0,0], [x*size, y*size, 64, 64])
        unless colorkey_source.nil?
            puts colorkey_source
          tile.set_colorkey(tile.get_at(colorkey_source))
        end
        tiles.push tile
      }
    }
    
    return tiles
  end
  
  def change_view(new_view, *args)
    @view=@views[new_view]
    @view.init(*args)
  end
  
  def statusview
    @views[:status]
  end
  
  def consoleview
    @views[:console]
  end
  
  def init_game(screen, gamescreen, show_splash)
    # Init and view splash screen
    @views={}
    @views[:game]=GameView.new
    @views[:win]=WinView.new
    @views[:fail]=FailView.new
    @views[:status]=StatusView.new
    @views[:splash]=SplashView.new
    @views[:console]=ConsoleView.new
    @views[:elevator]=ElevatorView.new
    @views[:transfer]=TransferView.new

    if show_splash
      @view=@views[:splash]
      @views[:splash].paint(gamescreen)
      @views[:status].paint(gamescreen)
      Rubygame::Transform.zoom(gamescreen, $scale).blit(screen, [0,0]) if $scale!=1.0
      screen.update() # flip screen buffers (show new content)
    end
        
    # Init the rest of the data
    @ship=Ship.new("ship.d")
    
    if !show_splash
      @view=@views[:game]
      @views[:game].paint(gamescreen)
      @views[:status].paint(gamescreen)
      Rubygame::Transform.zoom(gamescreen, $scale).blit(screen, [0,0]) if $scale!=1.0
      screen.update() # flip screen buffers (show new content)
    end
  end
  
  def play_game
    $stdout.sync = true

    Rubygame.init()

    queue=Rubygame::EventQueue.new()
    queue.ignore=[Rubygame::MouseMotionEvent]
    clock=Rubygame::Clock.new()
    clock.target_framerate = 24

    # Create the SDL window
    w=($window_size[:application].w*$scale).to_i
    h=($window_size[:application].h*$scale).to_i
    screen=Rubygame::Screen.set_mode([w,h])
    screen.title="Rubydroid"
    screen.show_cursor=false;
    
    if $scale!=1.0
      gamescreen=Rubygame::Surface.new($window_size[:application][2..3])
    else
      gamescreen=screen
    end
    
    load_graphics()
    $robotdata=RobotLibrarian.new
    #$robotdata.make_sprites("test1.bmp", false)
    #$robotdata.make_sprites("test2.bmp", true)
    
    init_game(screen, gamescreen, true)
    loop do
      begin
        loop do
          $redraw=true
          
          queue.each do |event|          
            case event
            when Rubygame::KeyDownEvent
              raise SystemExit if (event.key==Rubygame::K_ESCAPE || event.key==Rubygame::K_Q)
            end
            @view.process(event)
          end
          
          @view.update(0)
          change_view(:win) if @ship.num_robots==0

          if $redraw 
            @views[:status].paint(gamescreen) # draw status window
            @view.paint(gamescreen)           # draw image/game window
            Rubygame::Transform.zoom(gamescreen, $scale).blit(screen, [0,0]) if $scale!=1.0
            screen.update() # flip screen buffers (show new content)
          end
          
          clock.tick()  # update time
          screen.set_caption("Paradroid [%d fps]"%clock.fps) if $debug_mode
        end
      rescue SystemExit
        # Turn off the game
        Rubygame::Mixer.close_audio()
        Rubygame.quit()
        exit
      rescue Interrupt
        # Restart the game
        init_game(screen, gamescreen, false)
      end
    end
  end
  
  def Game.play
    $game=Game.new
    $game.play_game
  end
end

if __FILE__ == $0
  Game.play
end
