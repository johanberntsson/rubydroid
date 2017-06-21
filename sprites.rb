# These classes implement Robots, Doors and Missile/explosion sprites
require "rubygame"
 
class RobotGroup < Rubygame::Sprites::Group
  include Rubygame::Sprites::UpdateGroup
end

class DoorGroup < Rubygame::Sprites::Group
  include Rubygame::Sprites::UpdateGroup
end

class LaserGroup < Rubygame::Sprites::Group
  include Rubygame::Sprites::UpdateGroup
end

class ExplosionGroup < Rubygame::Sprites::Group
  include Rubygame::Sprites::UpdateGroup
end

class Sprite
  include Rubygame::Sprites::Sprite
  
  def initialize
    super()
    @old_pos=Rubygame::Rect.new
  end
  
  def crop(image)
    # Calculate bounding box
    c=image.get_at(0,0)
    rect=Rubygame::Rect.new(image.width, image.height, 0, 0)
    for y in 0...image.height
      for x in 0...image.width
        if image.get_at(x,y)!=c
          rect.y=y if y<rect.y
          rect.h=y if y>rect.h
          rect.x=x if x<rect.x
          rect.w=x if x>rect.w
        end
      end
    end
    rect.w=rect.w-rect.x
    rect.h=rect.h-rect.y
    # Copy cropped version
    new_image=Rubygame::Surface.new([rect.w, rect.h],$SURFACE_FLAGS)
    image.blit(new_image, [0,0], rect)
    
    # Make transparent
    new_image.set_colorkey(c)
    [new_image, rect]
  end
  
  def draw(surface)
    r=super(surface)
    if $debug_mode
      Rubygame::Draw.box(surface, @rect.topleft, @rect.bottomright, $color[:black])
    end
    r
  end

  def save_position
    @old_pos.x=@rect.x
    @old_pos.y=@rect.y
    @old_pos.w=@rect.w
    @old_pos.h=@rect.h
  end
  
  def restore_position
    @rect.x=@old_pos.x
    @rect.y=@old_pos.y
    @rect.w=@old_pos.w
    @rect.h=@old_pos.h
  end
    
end

class Robot < Sprite  
  attr_reader :name, :description, :type
  
  def initialize(type, xc, yc)
    super()
    
    @image,@rect=crop($graphics[:robots][type])
    
    # Put in original position
    @rect.move!(xc*64, yc*64)
    
    # Get some robot data
    @type=type
    @dir=rand(4)
    @strength=100
    @data=$robotdata.data(type)
    
    # Don't shoot at once
    @weapon_cnt=@data[:weapon_delay]
  end
  
  def die
    $game.statusview.score+=10
    $game.play_sound(:explosion)
    $game.ship.deck.explosion_sprites << Explosion.new(@rect)
    $game.ship.deck.robot_sprites.delete(self)
  end
  
  def damage(value)
    @strength-=value
    die if @strength<0
  end

  def update
    shoot()
    
    save_position()
    moving=move() # :fail if not on a floor tile, :ok if no problem

    # Check if bumped into player
    moving=:fail if $game.player.collide_sprite?(self)
    # Check if bumped into another robot
    $game.ship.deck.robot_sprites.collide_sprite(self).each { |robot|
      moving=:fail if robot!=self
    }
    
    if moving==:fail
      restore_position()
      d=@dir
      while d==@dir
        @dir=rand(4)
      end
    end
  end
  
  def shoot
    @weapon_cnt-=1 if @weapon_cnt>0
    if @weapon_cnt==0
      if @data[:weapon]==:laser
        lasertype=0 
      else
        lasertype=1
      end
      if @data[:weapon]!=:none
        xr=(@rect.centerx-$game.player.rect.centerx).abs/64
        yr=(@rect.centery-$game.player.rect.centery).abs/64
        if xr<@data[:weapon_range] && yr<@data[:weapon_range]
          @weapon_cnt=@data[:weapon_delay]
          if @data[:weapon]==:disruptor
            $game.ship.deck.flash=6
            $game.player.damage(@data[:weapon_damage])
          else
            # laser weapon
            if @rect.centerx<$game.player.rect.centerx
              $game.ship.deck.laser_sprites << Laser.new(lasertype, :E, @rect.right, @rect.cy)
            else
              $game.ship.deck.laser_sprites << Laser.new(lasertype, :W, @rect.left, @rect.cy)
            end
          end
        end
      end
    end
  end

  def move
    speed=@data[:speed]
    return if speed==0
    
    # Change directions sometimes
    @dir=rand(4) if rand(500)<1
    
    case @dir
    when 0 # Right
      @rect.move!(speed, 0)
      return :fail if !$game.ship.deck.floor?(@rect.topright) || !$game.ship.deck.floor?(@rect.bottomright)
     when 1 # Left
      @rect.move!(-speed, 0)
      return :fail if !$game.ship.deck.floor?(@rect.topleft) || !$game.ship.deck.floor?(@rect.bottomleft)
    when 2 # Down
      @rect.move!(0, speed)
      return :fail if !$game.ship.deck.floor?(@rect.bottomleft) || !$game.ship.deck.floor?(@rect.bottomright)
    when 3 # Up
      @rect.move!(0, -speed)
      return :fail if !$game.ship.deck.floor?(@rect.topleft) || !$game.ship.deck.floor?(@rect.topright)
    end
    return :ok
  end
end

class Explosion < Sprite  
  def initialize(rect)
    super()
    @image=$graphics[:explosion][0]
    @rect=rect
    @dying=40
  end
  
  def update()
    @dying-=1
    @image=$graphics[:explosion][4-(@dying/10)]
    $game.ship.deck.explosion_sprites.delete(self) if @dying==0    
  end
end

class Laser < Sprite
  attr_accessor :owner
  
  def initialize(type, direction, x, y)
    super()
    @owner=nil
    @type=type
    
    s=10
    off=0
    if @type==1
      s=5
      off=4
    end

    if direction==:W
      @speed_x=-s; @speed_y=0 
    elsif direction==:E
      @speed_x=s;  @speed_y=0
    elsif direction==:N
      @speed_x=0;  @speed_y=-s; off+=1
    elsif direction==:S
      @speed_x=0;  @speed_y=s;  off+=1
    elsif direction==:NW
      @speed_x=-s; @speed_y=-s; off+=2
    elsif direction==:SW
      @speed_x=-s; @speed_y=s;  off+=3
    elsif direction==:NE
      @speed_x=s;  @speed_y=-s; off+=3
    elsif direction==:SE
      @speed_x=s;  @speed_y=s;  off+=2
    end
    
    @power=200;
    @image,@rect=crop($graphics[:lasers][off])
    @rect.x=x
    @rect.y=y
    
    @rect.move!(-@rect.w/2, -@rect.h/2)

    if @speed_x<0
      @rect.move!(-$game.player.rect.w/2, 0)
    elsif @speed_x>0
      @rect.move!($game.player.rect.w/2, 0)
    end

    if @speed_y<0
      @rect.move!(0, -$game.player.rect.h/2)
    elsif @speed_y>0
      @rect.move!(0, $game.player.rect.h/2)
    end
    
    $game.play_sound(:laser)
  end
  
  def update()
    @rect.move!(@speed_x, @speed_y);
    if !$game.ship.deck.floor?(@rect.center)
      $game.ship.deck.laser_sprites.delete(self)
    end
    


    # Check if bumped into another robot (or player) 
    $game.player.die if collide_sprite?($game.player)
    $game.ship.deck.robot_sprites.collide_sprite(self).each { |robot| 
      robot.die 
      $game.ship.deck.laser_sprites.delete(self)
    }
    
    # Check if hitting closed door
    hit_door=false
    $game.ship.deck.door_sprites.collide_sprite(self).each { |door|
      hit_door=true if !door.open?
    }
    $game.ship.deck.laser_sprites.delete(self) if hit_door
  end
end
  
class Door < Sprite
  def initialize(x, y, images)
    super()
    
    @cnt=0
    @images=images
    @image=@images[0]
    @rect=Rubygame::Rect.new(x,y,64,64)
  end
  
  def open?
    @cnt<11 && @cnt>3
  end
  
  def update()
    # Check if bumped into another robot (or player)
    $game.play_sound(:door) if collide_sprite?($game.player) && @cnt==0
    
    blocked=collide_sprite?($game.player) || $game.ship.deck.robot_sprites.collide_sprite(self).length>0
    self.open if blocked


    return if @cnt==0

    @delay-=1
    if @delay==0
      @delay=5
      @cnt+=1
      @image=@images[1] if @cnt==2
      @image=@images[2] if @cnt==3
      @image=@images[3] if @cnt==4 
      if @cnt==10
        # The door is about to be closed.
        # Is it blocked by any robot?
        if blocked
          @cnt=4;
          return
        end
        
        # Proceed to close the door
        @image=@images[2];
      end
      @image=@images[1] if @cnt==11
      if @cnt==12
        @image=@images[0]
        @cnt=0
      end
    end
  end
  
  def open()
    if @cnt==0
      @cnt=1
      @delay=1
    end
  end
end

class Player < Robot
  attr_reader :capture, :move_x, :move_y
  attr_accessor :strength
  
  def initialize(type, x, y)
    super(type, x, y)
    
    @robot_type=0
    @player_image=crop($graphics[:captured_robots][type])[0]
    @image=@player_image
    move_to(x,y)

    @dying=false
    @max_speed=20
    self.capture=false
    clear_keys()
  end
  
  def clear_keys()
    @move_x=0
    @move_y=0
    @key_up=@key_down=@key_left=@key_right=@key_shift=false
  end
  
  def process(event)
    case event
    when Rubygame::KeyUpEvent
      @key_up=false if event.key==Rubygame::K_UP
      @key_down=false if event.key==Rubygame::K_DOWN
      @key_left=false if event.key==Rubygame::K_LEFT
      @key_right=false if event.key==Rubygame::K_RIGHT
    when Rubygame::KeyDownEvent
      @key_up=true if event.key==Rubygame::K_UP
      @key_down=true if event.key==Rubygame::K_DOWN
      @key_left=true if event.key==Rubygame::K_LEFT
      @key_right=true if event.key==Rubygame::K_RIGHT
    end
  end
  
  def capture=(value)
    @capture=value
    if @capture
      $game.statusview.message="Capture"
    else
      $game.statusview.message="Mobile"
    end
  end

  def shoot
    return if @dying
    return if @move_x==0 && @move_y==0
    
    type=0
    laser=nil
    if @move_x<0 && @move_y==0
      laser=Laser.new(type, :W, @rect.left, @rect.cy)
    elsif @move_x>0 && @move_y==0
      laser=Laser.new(type, :E, @rect.right, @rect.cy)
    elsif @move_x==0 && @move_y<0
      laser=Laser.new(type, :N, @rect.centerx, @rect.top)
    elsif @move_x==0 && @move_y>0
      laser=Laser.new(type, :S, @rect.centerx, @rect.bottom)
    elsif @move_x<0 && @move_y<0
      laser=Laser.new(type, :NW, @rect.left, @rect.top)
    elsif @move_x<0 && @move_y>0
      laser=Laser.new(type, :SW, @rect.left, @rect.bottom)
    elsif @move_x>0 && @move_y<0
      laser=Laser.new(type, :NE, @rect.right, @rect.top)
    elsif @move_x>0 && @move_y>0
      laser=Laser.new(type, :SE, @rect.right, @rect.bottom)
    end
    laser.owner=self
    $game.ship.deck.laser_sprites << laser
    
    # Slow us down a bit
    @move_x=5 if @move_x>5
    @move_y=5 if @move_y>5
  end
  
  def die
    $game.play_sound(:explosion)
    @dying=40
  end
  
  def damage(value)
    @strength-=value
    self.demote() if @strength<0
  end
  
  def promote(robot)
    @robot_type=robot.type
    @strength=100 # TODO
    @image=crop($graphics[:captured_robots][robot.type])[0]
  end
  
  def demote
    die if @robot_type==0
    
    @strength=100 # TODO
    @robot_type==0
    @image=@player_image
  end
  
  def move_to(x, y)
    @move_x=@move_y=0
    
    @rect.x=x*64+@rect.x%64
    @rect.y=y*64+@rect.y%64
    
    x=x-5
    y=y-2
    x=0 if x<0
    y=0 if y<0
    $window_size[:map].x=x*64
    $window_size[:map].y=y*64
  end
  
  def update()
    if @dying
      @dying-=1
      @image=$graphics[:explosion][4-(@dying/10)]
      $game.change_view(:fail) if @dying==0
      return
    end
 
    # Acceleration
    @move_x=@move_x+2 if @key_right && @move_x<@max_speed
    @move_x=@move_x-2 if @key_left && @move_x>-@max_speed
    @move_y=@move_y+2 if @key_down && @move_y<@max_speed
    @move_y=@move_y-2 if @key_up && @move_y>-@max_speed
    # Deacceleration (friction)
    @move_x=@move_x+1 if @move_x<0
    @move_x=@move_x-1 if @move_x>0
    @move_y=@move_y+1 if @move_y<0
    @move_y=@move_y-1 if @move_y>0

    save_position()
    
    if @move_x<0
      # Move left
      @rect.move!(@move_x, 0)
      if @rect.left-$window_size[:map].left<128
        $window_size[:map].move!(@move_x, 0)        
        if $window_size[:map].x<0
          $window_size[:map].x=0
        end
      end
      
      if !$game.ship.deck.floor?(@rect.topleft) || !$game.ship.deck.floor?(@rect.bottomleft)
        @move_x=0
        @rect.x=@old_pos.x
      end
    end

    if @move_x>0
      # Move right
      @rect.move!(@move_x, 0)
      if $window_size[:map].right-@rect.right<128
          $window_size[:map].move!(@move_x, 0)
      end

      if !$game.ship.deck.floor?(@rect.topright) || !$game.ship.deck.floor?(@rect.bottomright)
        @move_x=0
        @rect.x=@old_pos.x
      end
    end

    if @move_y<0
      # Move up
      @rect.move!(0, @move_y)
      if @rect.top-$window_size[:map].top<128
        $window_size[:map].move!(0, @move_y)
        if $window_size[:map].y<0
          $window_size[:map].y=0
        end
      end
      
      if !$game.ship.deck.floor?(@rect.topleft) || !$game.ship.deck.floor?(@rect.topright)
        @move_y=0
        @rect.y=@old_pos.y
      end
    end

    if @move_y>0
      # Move down
      @rect.move!(0, @move_y)
      if $window_size[:map].bottom-@rect.bottom<128
          $window_size[:map].move!(0, @move_y)
      end

      if !$game.ship.deck.floor?(@rect.bottomleft) || !$game.ship.deck.floor?(@rect.bottomright)
        @move_y=0
        @rect.y=@old_pos.y
      end
    end
    
    # Check if we hit another robot
    $game.ship.deck.robot_sprites.collide_sprite(self).each { |robot|
      if @capture
        $game.change_view(:transfer, $game.player, robot)
      else
        $game.play_sound(:bump)
        damage(10)
        robot.damage(10)
        restore_position()
        @move_x=0
        @move_y=0
      end
    }
    
    # Check if we hit a laser
    $game.ship.deck.laser_sprites.collide_sprite(self).each { |laser| 
      if laser.owner==self
        restore_position()
        @move_x=0
        @move_y=0
        @key_up=false if @move_y<0
        @key_down=false if @move_y>0
        @key_left=false if @move_x<0
        @key_right=false if @move_x>0      
      end
    }
  end
end
