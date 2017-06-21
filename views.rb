class View
  # This method is called before the view is (re-)displayed
  def init(*args)
  end
  
  def paint(screen)
    raise "View.paint is not overridden!"
  end
  
  def process(event)
    raise "View.process is not overridden!"
  end
  
  def update(time)
    raise "View.update is not overridden!"
  end
  
  protected 
  
  def draw_text_box(screen, pos, color, msg)
    words=Array.new
    msg=msg.gsub("\n", " | ") # trick to split newlines too
    msg.split.each { |word|
      image=$font.render(word+" ", true, $color[color])
      words.push([word, image])
    }
    
    x=pos[0]
    y=pos[1]
    w=pos[2]
    dw=0
    dh=0
    words.each { |word|
      dh=word[1].height if dh<word[1].height
      dw+=word[1].width
      if word[0]=="|"
        # NEW LINE
        x=pos[0]
        y+=dh
        dw=0
        dh=0        
      else
        if dw>w
          # too wide, insert line break
          x=pos[0]
          y+=dh
          dw=0
          dh=0
          word[1].blit(screen, [x,y])
          x+=word[1].width
        else
          word[1].blit(screen, [x,y])
          x+=word[1].width
        end
      end
    }
  end
  
  def draw_text(screen, pos, color, msg, *args)
    msg=msg%args
    
    if pos.length==4
      draw_text_box(screen, pos, color, msg)
    else
      $font.render(msg, true, $color[color]).blit(screen, pos)
      #$font.render(msg).blit(screen, pos)
    end
  end
  
  def DrawHLine(screen, x1, x2, y, color)
    screen.draw_line([x1,y], [x2, y], color)
    #Rubygame::Draw.line(screen, [x1,y], [x2, y], color)
  end
  
  def DrawVLine(screen, x, y1, y2, color)
    screen.draw_line([x,y1], [x, y2], color)
    #Rubygame::Draw.line(screen, [x,y1], [x, y2], color)
  end
  
  def FillRect(screen, x, y, w, h, color)
    screen.draw_box_s([x, y], [x+w, y+h], color)
    #Rubygame::Draw.filled_box(screen, [x, y], [x+w, y+h], color)
  end
  
  def DrawRect(screen, x, y, w, h, color)
    screen.draw_box([x, y], [x+w, y+h], color)
    #Rubygame::Draw.box(screen, [x, y], [x+w, y+h], color)
  end
  
  def DrawCircle(screen, center, r, color)
    screen.draw_circle(center, r, color)
    #Rubygame::Draw.box(screen, [x, y], [x+w, y+h], color)
  end
end

class SplashView < View
  def paint(screen)
    $graphics[:splash].blit(screen,$window_size[:game])
  end

  def process(event)
    $game.change_view(:game) if event.class==Rubygame::KeyDownEvent
  end
  
  def update(time)
  end
end

class WinView < View
  def init(*args)
    $game.play_sound(:win)
  end
  
  def paint(screen)
    $graphics[:win].blit(screen,$window_size[:game])
  end

  def process(event)
    return unless event.class==Rubygame::KeyDownEvent
    raise Interrupt if event.key>0
  end
  
  def update(time)
  end
end

class FailView < View
  def init(*args)
    $game.play_sound(:fail)
  end
  
  def paint(screen)
    $graphics[:fail].blit(screen,$window_size[:game])
  end

  def process(event)
    return unless event.class==Rubygame::KeyDownEvent
    raise Interrupt if event.key>0
  end
  
  def update(time)
  end
end

class GameView < View
  def init(*args)
    @deck=nil
    $game.player.clear_keys()
  end
  
  def paint(screen)
    if @deck!=$game.ship.deck
      # Create a surface to draw sprites on
      @map=Rubygame::Surface.new($game.ship.deck.image.size,$SURFACE_FLAGS)
      @deck=$game.ship.deck
    end
    
    $game.ship.deck.image.blit(@map, [0,0])
    @map.set_colorkey(@map.get_at(0,0))
    
    # Draw the sprites
    $game.ship.deck.door_sprites.draw(@map)
    $game.ship.deck.robot_sprites.draw(@map)
    $game.ship.deck.laser_sprites.draw(@map)
    $game.ship.deck.explosion_sprites.draw(@map)
    $game.player.draw(@map)      

    # Draw the screen
    if $game.ship.deck.robot_sprites.length==0 || $game.ship.deck.flash>0
      $game.ship.deck.flash-=1 if $game.ship.deck.flash>0
      screen.fill($color[:darkGray],$window_size[:game])
    else
      screen.fill($game.ship.deck.color,$window_size[:game])
    end
    @map.blit(screen,$window_size[:game],$window_size[:map])
  end
  
  def process(event)
    $game.player.process(event)
    if event.class==Rubygame::KeyDownEvent
      if event.key==Rubygame::K_SPACE
        x,y=$game.player.rect.center
        t=$game.ship.deck.map[y/64][x/64]
        if t==42
          $game.change_view(:console)
        elsif t==64
          $game.change_view(:elevator, x/64, y/64)
        else
          $game.player.shoot()
        end
      elsif event.key==Rubygame::K_RETURN
          $game.player.capture=!$game.player.capture 
      end
    end
  end  
  
  def update(time)
    x,y=$game.player.rect.center
    if $game.ship.deck.map[y/64][x/64]==35
      if $game.player.strength<100 && $game.statusview.score>0
        # Health
        $game.play_sound(:health)
        $game.statusview.score-=1
        $game.player.strength+=1
      end
    end
    
    $game.ship.deck.door_sprites.update()    
    $game.ship.deck.robot_sprites.update()    
    $game.ship.deck.laser_sprites.update()    
    $game.ship.deck.explosion_sprites.update()    
    $game.player.update
  end
end

class StatusView < View
  attr_accessor :score
  
  def initialize
    @score=0
    @message="Active"
  end
  
  def paint(screen)
    screen.fill($color[:white],$window_size[:status])
    $graphics[:logo].blit(screen,[($window_size[:status][2]-$graphics[:logo].width)/2,0])
    draw_text(screen,[10,10], :blue, @message)
    draw_text(screen,[10,30], :blue, "ROBOTS: %d/%d", $game.ship.deck.num_robots, $game.ship.num_robots) if !$game.ship.nil?
    draw_text(screen,[500,10], :blue, "SCORE: %d", @score)
    draw_text(screen,[500,30], :blue, "STRENGTH: %d", $game.player.strength) if !$game.player.nil?
  end
  
  def update(time)
    # No dynamic content
  end
  
  def message=(message)
    @message=message
  end
end

class ElevatorView < View
  def init(*args)
    x, y=args[0], args[1]
    @deck_no=$game.ship.deck.index
    for i in 0...$game.ship.elevators[@deck_no].length
      pos=$game.ship.elevators[@deck_no][i]
      @elevator_no=i if !pos.nil? && x==pos[0] && y==pos[1]
    end
  end
  
  def paint(screen)
    $game.consoleview.paint_ship(screen, @deck_no, @elevator_no)
  end

  def process(event)
    return unless event.class==Rubygame::KeyDownEvent
    
    # Update menu
    i=@deck_no
    if event.key==Rubygame::K_UP
      @deck_no-=1 if @deck_no>0
      while @deck_no>0 && $game.ship.elevators[@deck_no][@elevator_no].nil?
        @deck_no-=1
      end
      @deck_no=i if $game.ship.elevators[@deck_no][@elevator_no].nil?
    elsif event.key==Rubygame::K_DOWN
      @deck_no+=1 if @deck_no<$game.ship.elevators.length-1
      while @deck_no<($game.ship.elevators.length-1) && $game.ship.elevators[@deck_no][@elevator_no].nil?
        @deck_no+=1
      end
      @deck_no=i if $game.ship.elevators[@deck_no][@elevator_no].nil?
    elsif event.key>0
      $game.ship.change_deck(@deck_no)
      x=$game.ship.elevators[@deck_no][@elevator_no][0]
      y=$game.ship.elevators[@deck_no][@elevator_no][1]
      $game.player.move_to(x,y)
      $game.change_view(:game)
    end

  end
  
  def update(time)
  end
end

class ConsoleView < View
  def init(*args)
    @menu_id=0
    @screen_type=:menu
    @info_id=0
    @info_cnt=0
  end
  
  def paint(screen)
    case @screen_type
    when :menu
      paint_menu(screen)
    when :deck
      paint_deck(screen)
    when :info
      paint_info(screen)
    when :ship
      paint_ship(screen, 0, 0)
    end
  end
  
  def process(event)
    key=0
    key=event.key if event.class==Rubygame::KeyDownEvent
    
    case @screen_type
    when :menu
      process_menu(key)
    when :deck
      process_deck(key)
    when :info
      process_info(key)
    when :ship
      process_ship(key)
    end
  end
  
  def update(time)
    # No dynamic content
  end
  
  def process_menu(key)
    # Update menu
    if key==Rubygame::K_UP
      @menu_id=@menu_id-1 if @menu_id>0
    elsif key==Rubygame::K_DOWN
      @menu_id=@menu_id+1 if @menu_id<3
    elsif key>0
      $game.change_view(:game) if @menu_id==0
      @screen_type=:info if @menu_id==1
      @screen_type=:deck if @menu_id==2
      @screen_type=:ship if @menu_id==3
    end
  end
  
  def process_deck(key)
    @screen_type=:menu if key>0
  end
  
  def process_ship(key)
    @screen_type=:menu if key>0
  end
 
  def process_info(key)
    if key==Rubygame::K_DOWN
      @info_id=@info_id-1 if @info_id>0
    elsif key==Rubygame::K_UP
      @info_id=@info_id+1 if @info_id<$robotdata.count-1
    elsif key==Rubygame::K_LEFT
      @info_cnt=@info_cnt-1 if @info_cnt>0
    elsif key==Rubygame::K_RIGHT
      @info_cnt=@info_cnt+1 if @info_cnt<2
    elsif key>0
      @screen_type=:menu
    end
  end
  
  def paint_menu(screen)
    screen.fill($color[:red],$window_size[:game])

    $game.player.image.blit(screen, [50, 35+$window_size[:game].y])    
    $graphics[:console].blit(screen, [50, 88+$window_size[:game].y], [0,0,64,64])
    $graphics[:console].blit(screen, [20, 155+$window_size[:game].y], [64,0,128,64])
    $graphics[:console].blit(screen, [20, 221+$window_size[:game].y], [192,0,128,64])
    
    x=$window_size[:game].w/3
    y=$window_size[:game].h/8+$window_size[:game].y;
    draw_text(screen, [x, y], :white, "Unit type %s - %s", $robotdata.name($game.player.type), $robotdata.description($game.player.type))
    draw_text(screen, [x, y+2*30], :white, "Access Granted")
    draw_text(screen, [x, y+4*30], :white, "Ship:  %s", $game.ship.name)
    draw_text(screen, [x, y+5*30], :white, "Deck: %s",$game.ship.deck.name)
    draw_text(screen, [x, y+7*30], :white, "Alert: Green")
    
    DrawRect(screen,10, 20+$window_size[:game].y+67*@menu_id,160, 66,$color[:white])
  end
  
  def paint_info(screen)
#    screen.fill($color[:red],$window_size[:game])
#    $robotdata.image(@info_id).set_colorkey($robotdata.image(@info_id).get_at(0,0))
#    $robotdata.image(@info_id).blit(screen, [$window_size[:game].w/20,$window_size[:game].h/4+$window_size[:game].y])
    screen.fill($color[:white],$window_size[:game])
    $robotdata.image(@info_id).blit(screen, [$window_size[:game].w/20,$window_size[:game].h/4+$window_size[:game].y])
    
    x=$window_size[:game].w/40
    y=$window_size[:game].h/8+$window_size[:game].y
    draw_text(screen, [x, y], :red, "Unit type %s - %s", $robotdata.name(@info_id), $robotdata.description(@info_id))
    
    x=$window_size[:game].w/3
    dy=25
    case @info_cnt
    when 0
      draw_text(screen, [x, y,$window_size[:game].w/2,$window_size[:game].h/2], :red, "Notes: %s", $robotdata.notes(@info_id))
    when 1
      draw_text(screen, [x, y], :red, "Entry: %d", @info_id+1)
      draw_text(screen, [x, y+dy], :red, "Class: %s", $robotdata.class(@info_id))
      draw_text(screen, [x, y+dy*2], :red, "Height: %s", $robotdata.height(@info_id).to_s)
      draw_text(screen, [x, y+dy*3], :red, "Weight: %s", $robotdata.weight(@info_id).to_s)
      draw_text(screen, [x, y+dy*4], :red, "Drive: %s", $robotdata.drive(@info_id).to_s)
      draw_text(screen, [x, y+dy*5], :red, "Brain: %s", $robotdata.brain(@info_id))
    when 2
      draw_text(screen, [x, y], :red, "Armament: %s", $robotdata.weapon(@info_id))
      draw_text(screen, [x, y+dy*2], :red, "Sensors")
      draw_text(screen, [x, y+dy*3], :red, "    1: %s", $robotdata.sensor1(@info_id).to_s)
      draw_text(screen, [x, y+dy*4], :red, "    2: %s", $robotdata.sensor2(@info_id).to_s)
      draw_text(screen, [x, y+dy*5], :red, "    3: %s", $robotdata.sensor3(@info_id).to_s)
    end
  end
  
  def paint_deck(screen)
    # Calculate cell width and offsets
    c=20;
    mx=$game.ship.deck.map[0].length
    my=$game.ship.deck.map.length
    i=$window_size[:game].w/mx;
    j=$window_size[:game].h/my;
    c=i if i<c
    c=j if j<c 
    off_x=($window_size[:game].w-mx*c)/2;
    off_y=($window_size[:game].h-my*c)/2+$window_size[:game].y;
    
    # Draw background
    screen.fill($color[:lightBlue],$window_size[:game])
    
    # Draw ship
    for i in 0...my
      for j in 0...mx
        s=$game.ship.deck.map[i][j]
        case sprintf("%c", s)
        when "?"
          # Undefined (deep space)
        when "."
          # Floor tiles
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:middleGray])
        when "*"
          # Console
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:middleGray])
          DrawCircle(screen, [off_x+j*c+c/2, off_y+i*c+c/2], c/2-1, $color[:white])
        when "-"
          # Horizontal door
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:middleGray])
          DrawHLine(screen, off_x+j*c, off_x+j*c+c, off_y+i*c+c/2, $color[:black])
        when "|"
          # Vertical door
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:middleGray])
          DrawVLine(screen, off_x+j*c+c/2, off_y+i*c, off_y+i*c+c, $color[:black])
        when "@"
          # Elevators
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:middleGray])
          DrawCircle(screen, [off_x+j*c+c/2, off_y+i*c+c/2], c/2-1, $color[:blue])
          DrawVLine(screen, off_x+j*c+c/2, off_y+i*c, off_y+i*c+c/2, $color[:blue])
          DrawHLine(screen, off_x+j*c+c/2, off_x+j*c+c, off_y+i*c+c/2, $color[:blue])
        when "W", "#"
          # Non standard floor tiles
          FillRect(screen, off_x+j*c+c/4, off_y+i*c+c/4, c/2, c/2, $color[:middleGray])
        else
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:black])
        end
      end
    end
  end

  def paint_ship(screen, deck_no, elevator_no)
    # Calculate cell width and offsets
    c=20
    mx=$game.ship.map[0].length
    my=$game.ship.map.length
    i=$window_size[:game].w/mx
    j=$window_size[:game].h/my
    c=i if i<c
    c=j if j<c 
    off_x=($window_size[:game].w-mx*c)/2
    off_y=($window_size[:game].h-my*c)/2+$window_size[:game].y
    
    # Draw background
    screen.fill($color[:lightBlue],$window_size[:game])
    
    # Draw ship
    for i in 0...my
      for j in 0...mx
        s=$game.ship.map[i][j]
        case sprintf("%c", s)
        when "."
          # Undefined (deep space)
        when "-", "|", "@"
          FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:black])
          #Rubygame::Draw.filled_box(screen, ul, lr, $color[:black])
        when "1","2","3","4","5","6","7","8","9"
          # Elevator
          if elevator_no==s-49 # "1"
            FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:yellow])
            #Rubygame::Draw.filled_box(screen, ul, lr, $color[:yellow])
          else
            FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:green])
            #Rubygame::Draw.filled_box(screen, ul, lr, $color[:green])
          end
        else
          # Level
          if deck_no==s-97 # "a"
            FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:cyan])
            #Rubygame::Draw.filled_box(screen, ul, lr, $color[:cyan])
          else
            FillRect(screen, off_x+j*c, off_y+i*c, c, c, $color[:lightBlue])
            #Rubygame::Draw.filled_box(screen, ul, lr, $color[:lightBlue])
          end
        end
      end
    end
  end
end

class TransferView < View
  def init(*args)
    @player=args[0]
    @robot=args[1]
    
    @cnt=1
    @key=0
    @conn=Array.new(12)
    @side_marker=Array.new(12)
    @middle_color=Array.new(13)
    for i in 0...12
      @conn[i]=Array.new(2)
      @side_marker[i]=Array.new(2)
    end
    
    start()
  end

  def paint(screen)
    if @cnt==0
      paint_intro(screen)
    else
      paint_game(screen)
    end
  end
  
  def process(event)
    return unless event.class==Rubygame::KeyDownEvent
    @key=event.key
  end
  
  def update(time)
    if @cnt==0
      @cnt=1 if update_intro(@key)==false
    elsif @cnt==1
      if update_choose_side(@key)==-1
        @cnt=2
        @timeout=15
        @start_time=nil
      end
    else
      r=update_game(@key)
      # 0 if continue, -2 if player wins, -1 if robot wins
      if r==-1
        # Robot wins
        $game.player.demote
        $game.player.capture=false
        $game.change_view(:game)
      elsif r==-2
        # Player wins
        @robot.die
        $game.player.capture=false
        $game.player.promote(@robot)
        $game.change_view(:game)
      end
    end
    @key=0
  end
  
  def start()    
    @cnt=0
    @robot_delay=0

    @player_marker=7
    @robot_marker=4

    @player_side=0
    @robot_side=1

    @curr_player_marker=-1
    @curr_robot_marker=-1

    @middle_color[12]=$color[:black]
    for i in 0...12
      @side_marker[i][0]=@side_marker[i][1]=false
      @middle_color[i]=$color[:black]
    end
    
    @phase=0
    @start_time=nil
    @timeout=5
    for i in 0...12
       @conn[i][0]=i
       @conn[i][1]=i
    end

    # Create random obstacles
    for i in 0...2
      
      j1=rand(10)
      if rand(2)
        # Fork (narrow)
        @conn[j1][i]=j1+1
        @conn[j1+1][i]=-1
        @conn[j1+2][i]=j1-1
      else
        # Fork (wide)
        @conn[j1][i]=-1
        @conn[j1+1][i]=-3
        @conn[j1+2][i]=-1
      end

      j2=rand(10)
      loop do 
        j2=rand(10)
        break unless j2>j1-3 && j2<j1+3
      end
      
      if rand(2)
        # Fork (narrow)
        @conn[j2][i]=j2+1
        @conn[j2+1][i]=-1
        @conn[j2+2][i]=j2-1
      else
        # Fork (wide)
        @conn[j2][i]=-1
        @conn[j2+1][i]=-3
        @conn[j2+2][i]=-1
      end
      
      j3=rand(12)
      loop do
        j3=rand(12)
        break unless (j3>j1-3 && j3<j1+3) || (j3>j2-3 && j3<j2+3)
      end
      
      # Color changer
      @conn[j3][i]=-2
    end
  end
  
  def update_intro(key)
    @cnt=1 if key>0
  end
  
  def update_choose_side(key)
    @start_time=Time.new if @start_time.nil?
    t=1+(Time.now-@start_time).to_i
    
    return -1 if t==@timeout 
    $game.statusview.message=sprintf("%d", @timeout-t)

    if key==Rubygame::K_LEFT
      if @player_side==1
        @player_side=0
        @robot_side=1
      end
    elsif key==Rubygame::K_RIGHT
      if @player_side==0
        @player_side=1
        @robot_side=0
      end
    elsif key>0
      return -1
    end
    
    return 0
  end

  def update_game(key)
    # Handle countdown and end of game
    @start_time=Time.new if @start_time.nil?
    t=1+(Time.now-@start_time).to_i

    if @curr_player_marker==-1 && @player_marker==0 && @curr_robot_marker==-1 && @robot_marker==0
      @curr_player_marker=-2
      @timeout=t
    end

    if t==@timeout
      @phase=1
      update_score()
      if @player_score==@robot_score
        $game.statusview.message="Deadlock"
      elsif @player_score>@robot_score 
        $game.statusview.message="Complete"
      else
        $game.statusview.message="Rejected"
      end
    elsif t<@timeout
      $game.statusview.message=sprintf("%d", @timeout-t)
    elsif t==@timeout+2
      # Game Over
      if @player_score==@robot_score
        start();
        @cnt=1;
      elsif @player_score>@robot_score
        return -2
      else
        return -1
      end
    end

    return 0 if @phase==1

    # Handle player actions
    if @curr_player_marker==-1 && @player_marker>0
      @curr_player_marker=0;
      @player_marker-=1
    end

    if @curr_player_marker>-1
      if key==Rubygame::K_DOWN
        loop do
          @curr_player_marker+=1
          @curr_player_marker=1 if @curr_player_marker>13
          break unless @side_marker[@curr_player_marker-1][@player_side]
        end
      elsif key==Rubygame::K_UP
        loop do
          @curr_player_marker-=1
          @curr_player_marker=12 if @curr_player_marker<1
          break unless @side_marker[@curr_player_marker-1][@player_side]
        end
      elsif key>0
        if @curr_player_marker>0
          @side_marker[@curr_player_marker-1][@player_side]=true
          @curr_player_marker=-1
        end
      end
    end

    # Handle computer actions
    if @curr_robot_marker==-1 && @robot_marker>0
      @curr_robot_dir=1
      @curr_robot_dir=-1 if rand(2)==0
      @curr_robot_marker=0;
      @robot_marker-=1
    end

    @robot_delay-=1 if @robot_delay>0

    if @curr_robot_marker>-1 && @robot_delay==0
      @robot_delay=5
      @curr_robot_marker+=@curr_robot_dir
      @curr_robot_marker=12 if @curr_robot_marker<1
      @curr_robot_marker=1 if @curr_robot_marker>12
      if @side_marker[@curr_robot_marker-1][@robot_side]==false && rand(100)<30
        @side_marker[@curr_robot_marker-1][@robot_side]=true
        @curr_robot_marker=-1
      end
    end

    update_score()
    return 0;
  end

  def update_score
    @player_score=0
    @robot_score=0

    # Calculate side strength
    side=Array.new(12)
    for i in 0...12
      side[i]=Array.new(2)
      side[i][0]=false
      side[i][1]=false
    end

    for i in 0...12
      for j in 0...2
        if @side_marker[i][j] && @conn[i][j]==i
          side[i][j]=true
        elsif @side_marker[i][j] && @conn[i][j]==i+1 && i<10 && @side_marker[i+2][j]
          # narrow fork
          side[i+1][j]=true
        elsif @side_marker[i][j] && @conn[i][j]==-3
          # wide fork
          side[i-1][j]=true
          side[i+1][j]=true
        elsif @side_marker[i][j] && @conn[i][j]==-2
          # color change
          if j==0
            side[i][1]=true
          else 
            side[i][0]=true
          end
        end
      end
    end

    # Update middle colors
    for i in 0...12
      if side[i][@player_side]==true && side[i][@robot_side]==false
        if @player_side==0
          @middle_color[i]=$color[:yellow]
        else
          @middle_color[i]=$color[:purple]
        end
        @player_score+=1
      end
      if side[i][@player_side]==false && side[i][@robot_side]==true
        if @robot_side==0 
          @middle_color[i]=$color[:yellow]
        else 
          @middle_color[i]=$color[:purple]
        end
        @robot_score+=1
      end
      if side[i][@player_side]==false && side[i][@robot_side]==false
        @middle_color[i]=$color[:black]
      end
      if side[i][@player_side]==true && side[i][@robot_side]==true
        # Deadlock situation
        @middle_color[i]=$color[:middleGray]
      end
    end

    if @player_score==@robot_score
      @middle_color[12]=$color[:black]
    elsif @player_score>@robot_score
      if @player_side==0
        @middle_color[12]=$color[:yellow]
      else 
        @middle_color[12]=$color[:purple]
      end
    else
      if @robot_side==0
        @middle_color[12]=$color[:yellow]
      else 
        @middle_color[12]=$color[:purple]
      end
    end
  end

  def paint_intro(screen)
    screen.fill($color[:white],$window_size[:game])
    $robotdata.image(@robot.type).blit(screen, [$window_size[:game].w/8, $window_size[:game].y+$window_size[:game].h/4])
    draw_text(screen, [$window_size[:game].w/8, $window_size[:game].y+$window_size[:game].h/8],
      :red, "Unit type %s - %s", $robotdata.name(@robot.type), $robotdata.description(@robot.type))
    draw_text(screen, [$window_size[:game].w/2, $window_size[:game].y+$window_size[:game].h/4, $window_size[:game].w/3, $window_size[:game].h/2], 
      :red, "This is the unit that you wish to control. Prepare to transfer")
  end
    
  def paint_game(screen)
    # Background
    screen.fill($color[:red],$window_size[:game])

    # Robots
    if @player_side==0 
      x=$window_size[:game].w/4-@player.image.w
      y=$window_size[:game].h/16+$window_size[:game].y
      @player.image.blit(screen, [x,y])

      x=3*$window_size[:game].w/4
      y=$window_size[:game].h/16+$window_size[:game].y
      @robot.image.blit(screen, [x, y])
    else
      x=$window_size[:game].w/4-@player.image.w
      y=$window_size[:game].h/16+$window_size[:game].y
      @robot.image.blit(screen, [x, y])

      x=3*$window_size[:game].w/4
      y=$window_size[:game].h/16+$window_size[:game].y
      @player.image.blit(screen, [x, y])
    end

    # Middle column
    x=$window_size[:game].w/2
    y=$window_size[:game].h/16
    z=($window_size[:game].h-2*y)/14
    FillRect(screen, x-30, $window_size[:game].y+y-5, 60, $window_size[:game].h-2*y+8, $color[:black])
    FillRect(screen, x-25, $window_size[:game].y+y, 50, 2*z-2, @middle_color[12])
    for i in 0...12
      FillRect(screen, x-25, $window_size[:game].y+y+z*(i+2), 50, z-2, @middle_color[i])
    end

    # Lines
    DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/8,$window_size[:game].y+y+z+z/2, $color[:black])
    DrawHLine(screen, $window_size[:game].w-$window_size[:game].w/16, $window_size[:game].w-$window_size[:game].w/8,$window_size[:game].y+y+z+z/2, $color[:black])

    for i in 0...12
      if @conn[i][0]==i
        DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/2-30,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
      elsif @conn[i][0]==i+1
        # fork (narrow)
        DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/4,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/4,
                  $window_size[:game].y+y+z*(i+4)+z/2, $color[:black])
        DrawHLine(screen, $window_size[:game].w/4, $window_size[:game].w/2-30,
                  $window_size[:game].y+y+z*(i+3)+z/2, $color[:black])
        FillRect(screen, $window_size[:game].w/4, $window_size[:game].y+y+z*(i+2)+z/2-10,
                 10, z*3, $color[:yellow])
        DrawRect(screen, $window_size[:game].w/4, $window_size[:game].y+y+z*(i+2)+z/2-10,
                 10, z*3, $color[:black])
      elsif @conn[i][0]==-2 
        # Color change
        DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/2-30,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        FillRect(screen, $window_size[:game].w/3, $window_size[:game].y+y+z*(i+2)+z/2-5,
                 10, 10, $color[:purple])
        DrawRect(screen, $window_size[:game].w/3, $window_size[:game].y+y+z*(i+2)+z/2-5,
                 10, 10, $color[:black])
      elsif @conn[i][0]==-3
        # fork (wide)
        DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/4,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        DrawHLine(screen, $window_size[:game].w/4, $window_size[:game].w/2-30,
                  $window_size[:game].y+y+z*(i+1)+z/2, $color[:black])
        DrawHLine(screen, $window_size[:game].w/4, $window_size[:game].w/2-30,
                  $window_size[:game].y+y+z*(i+3)+z/2, $color[:black])
        FillRect(screen, $window_size[:game].w/4, $window_size[:game].y+y+z*(i+1)+z/2-5,
                 10, z*3, $color[:yellow])
        DrawRect(screen, $window_size[:game].w/4, $window_size[:game].y+y+z*(i+1)+z/2-5,
                 10, z*3, $color[:black])
      elsif @conn[i][0]==-1
        # Short
        DrawHLine(screen, $window_size[:game].w/16, $window_size[:game].w/6,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        paint_marker(screen, -1, $window_size[:game].w/6, $window_size[:game].y+y+z*(i+2)+z/2, $color[:yellow])
      end

      if @conn[i][1]==i
        DrawHLine(screen, 15*$window_size[:game].w/16, $window_size[:game].w/2+30,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
      elsif @conn[i][1]==i+1
        # fork (narrow)
        DrawHLine(screen, 15*$window_size[:game].w/16, 3*$window_size[:game].w/4,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        DrawHLine(screen, 15*$window_size[:game].w/16, 3*$window_size[:game].w/4,
                  $window_size[:game].y+y+z*(i+4)+z/2, $color[:black])
        DrawHLine(screen, 3*$window_size[:game].w/4, $window_size[:game].w/2+30,
                  $window_size[:game].y+y+z*(i+3)+z/2, $color[:black])
        FillRect(screen, 3*$window_size[:game].w/4, $window_size[:game].y+y+z*(i+2)+z/2-10,
                 10, z*3, $color[:purple])
        DrawRect(screen, 3*$window_size[:game].w/4, $window_size[:game].y+y+z*(i+2)+z/2-10,
                 10, z*3, $color[:black])
      elsif @conn[i][1]==-2
        # Color change
        DrawHLine(screen, 15*$window_size[:game].w/16, $window_size[:game].w/2+30,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        FillRect(screen, 2*$window_size[:game].w/3, $window_size[:game].y+y+z*(i+2)+z/2-5,
                 10, 10, $color[:yellow])
        DrawRect(screen, 2*$window_size[:game].w/3, $window_size[:game].y+y+z*(i+2)+z/2-5,
                 10, 10, $color[:black])
      elsif @conn[i][1]==-3
        # fork (wide)
        DrawHLine(screen, 15*$window_size[:game].w/16, 3*$window_size[:game].w/4,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        DrawHLine(screen, 3*$window_size[:game].w/4, $window_size[:game].w/2+30,
                  $window_size[:game].y+y+z*(i+1)+z/2, $color[:black])
        DrawHLine(screen, 3*$window_size[:game].w/4, $window_size[:game].w/2+30,
                  $window_size[:game].y+y+z*(i+3)+z/2, $color[:black])
        FillRect(screen, 3*$window_size[:game].w/4, $window_size[:game].y+y+z*(i+1)+z/2-10,
                 10, z*3, $color[:purple])
        DrawRect(screen, 3*$window_size[:game].w/4, $window_size[:game].y+y+z*(i+1)+z/2-10,
                 10, z*3, $color[:black])
      elsif @conn[i][1]==-1
        # Short
        DrawHLine(screen, 15*$window_size[:game].w/16, 5*$window_size[:game].w/6,
                  $window_size[:game].y+y+z*(i+2)+z/2, $color[:black])
        paint_marker(screen, -1, 5*$window_size[:game].w/6, $window_size[:game].y+y+z*(i+2)+z/2, $color[:purple])
      end
    end
    
    # Side and player markers
    for i in 0...12
      paint_marker(screen, -1, $window_size[:game].w/2-30, $window_size[:game].y+y+z*(i+2)+z/2, $color[:yellow])
      if @side_marker[i][0]
        paint_marker(screen, 1, $window_size[:game].w/8, $window_size[:game].y+y+z*(i+2)+z/2, $color[:yellow])
      end
      paint_marker(screen, 1, $window_size[:game].w/2+30, $window_size[:game].y+y+z*(i+2)+z/2, $color[:purple])
      if @side_marker[i][1]
        paint_marker(screen, -1, 7*$window_size[:game].w/8, $window_size[:game].y+y+z*(i+2)+z/2, $color[:purple])
      end
    end

    # Current player markers
    if @player_side==0
      if @curr_player_marker>-1
        paint_marker(screen, 1, $window_size[:game].w/8, $window_size[:game].y+y+z*(@curr_player_marker+1)+z/2, $color[:yellow])
      end
      if @curr_robot_marker>-1
        paint_marker(screen, -1, 7*$window_size[:game].w/8, $window_size[:game].y+y+z*(@curr_robot_marker+1)+z/2, $color[:purple])
      end
    else
      if @curr_robot_marker>-1
        paint_marker(screen, 1, $window_size[:game].w/8, $window_size[:game].y+y+z*(@curr_robot_marker+1)+z/2, $color[:yellow])
      end
      if @curr_player_marker>-1
        paint_marker(screen, -1, 7*$window_size[:game].w/8, $window_size[:game].y+y+z*(@curr_player_marker+1)+z/2, $color[:purple])
      end
    end
    
    # Left column
    x=$window_size[:game].w/16
    y=$window_size[:game].h/16
    FillRect(screen, x, $window_size[:game].y+y, 10, $window_size[:game].h-2*y, $color[:yellow])
    DrawRect(screen, x-2, $window_size[:game].y+y, 14, $window_size[:game].h-2*y, $color[:black])
    
    # Markers
    if @player_side==0
      for i in 0...@player_marker
        paint_marker(screen, 1, 10, $window_size[:game].y+y+z*(i+2), $color[:yellow])
      end
    else
      for i in 0...@robot_marker
        paint_marker(screen, 1, 10, $window_size[:game].y+y+z*(i+2), $color[:yellow])
      end
    end

    # Right column
    FillRect(screen, $window_size[:game].w-x-10, $window_size[:game].y+y,
             10, $window_size[:game].h-2*y, $color[:purple])
    DrawRect(screen, $window_size[:game].w-x-12, $window_size[:game].y+y,
             14, $window_size[:game].h-2*y, $color[:black])
             
    # Markers
    if @player_side==1
      for i in 0...@player_marker
        paint_marker(screen, -1, $window_size[:game].w-10, $window_size[:game].y+y+z*(i+2), $color[:purple])
      end
    else
      for i in 0...@robot_marker
        paint_marker(screen, -1, $window_size[:game].w-10, $window_size[:game].y+y+z*(i+2), $color[:purple])
      end
    end
  end
  
  def paint_marker(screen, direction, x, y, c)
    if direction==-1
      FillRect(screen, x-5, y-5, 5, 10, c)
      FillRect(screen, x-10, y-3, 5, 5, c)
      DrawHLine(screen, x, x-5, y-5, $color[:black])
      DrawVLine(screen, x-5, y-5, y-3, $color[:black])
      DrawHLine(screen, x-5, x-10, y-3, $color[:black])
      DrawVLine(screen, x-10, y-3, y+3, $color[:black])
      DrawHLine(screen, x-10, x-5, y+3, $color[:black])
      DrawVLine(screen, x-5, y+3, y+5, $color[:black])
      DrawHLine(screen, x-5, x, y+5, $color[:black])
      DrawVLine(screen, x, y+5, y-5, $color[:black])
    else
      FillRect(screen, x, y-5, 5, 10, c)
      FillRect(screen, x+5, y-3, 5, 5, c)
      DrawHLine(screen, x, x+5, y-5, $color[:black])
      DrawVLine(screen, x+5, y-5, y-3, $color[:black])
      DrawHLine(screen, x+5, x+10, y-3, $color[:black])
      DrawVLine(screen, x+10, y-3, y+3, $color[:black])
      DrawHLine(screen, x+10, x+5, y+3, $color[:black])
      DrawVLine(screen, x+5, y+3, y+5, $color[:black])
      DrawHLine(screen, x+5, x, y+5, $color[:black])
      DrawVLine(screen, x, y+5, y-5, $color[:black])
    end
  end
end
