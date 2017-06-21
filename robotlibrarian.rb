class RobotLibrarian
  @@data=[ 
    ["001", "001.png", :influence, 1.0, 27, :nodrive, :none,
      :laser, :none, :none, :none,
      "Robot activity influence device. This helmet is self-powered and will control any robot for a short time. Lasers are turret mounted."],
    ["123", "123.png", :disposal, 1.37, 85, :tracks, :none,
      :none, :spectral, :infrared, :none,
      "Simple rubbish disposal robot. Common device in most space craft to maintain a clean ship."],
    ["139", "139.png", :disposal, 1.22, 61, :antigrav, :none,
      :laser, :spectral, :none, :none,
      "Created by Dr. Masternak to clean up large heaps of rubbish. Its scoop is used to collect rubbish. It is then crushed internally."],
    ["247", "247.png", :servant, 1.56, 73, :antigrav, :neutronic,
      :none, :spectral, :none, :none,
      "Light duty servant robot. One of the first to use the anti-grav system."],
    ["249", "249.png", :servant, 1.63, 83, :tripedal, :neutronic,
      :none, :spectral, :none, :none,
      "Cheaper version of the anti-grav servant robot."],
    ["296", "296.png", :servant, 1.2, 47, :tracks, :neutronic,
      :none, :spectral, :none, :none,
      "This robot is mainly used for serving drinks. A tray is mounted on the head. Built by Orchard and Marsden Enterprises."],
    ["302", "302.png", :messenger, 1.07, 23, :antigrav, :none,
      :none, :spectral, :none, :none,
      "Common device for moving small packages. Clamp is mounted on the lower body."],
    ["329", "329.png", :messenger, 1.07, 31, :wheels, :none,
      :none, :spectral, :none, :none,
      "Early type messenger robot. Large :wheels impede motion on small craft."],
    ["420", "420.png", :maintenance, 1.41, 57, :tracks, :neutronic,
      :none, :spectral, :none, :none,
      "Slow maintenance robot. Confined to drive maintenance during flight."],
    ["476", "476.png", :maintenance, 1.32, 42, :antigrav, :neutronic,
      :laser, :spectral, :infrared, :none,
      "Ship maintence robot. Fitted with multiple arms to carry out repairs to the ship efficiently. All craft built after the Jupiter Incident are supplied with a team of these."],
    ["493", "493.png", :maintenance, 1.48, 51, :antigrav, :neutronic,
      :none, :spectral, :none, :none,
      "Slave maintenance droid. Standard version will carry its own toolbox."],
    ["516", "516.png", :crew, 1.57, 74, :bipedal, :neutronic,
      :none, :spectral, :none, :none,
      "Early crew droid. Able to carry out simple flight checks only. No longer supplied."],
    ["571", "571.png", :crew, 1.76, 62, :bipedal, :neutronic,
      :none, :spectral, :none, :none,
      "Standard crew droid. Supplied with the ship."],
    ["598", "598.png", :crew, 1.72, 93, :bipedal, :neutronic,
      :none, :spectral, :none, :none,
      "A highly sophisticated device. Able to control the Robo-Freighter on its own."],
    ["614", "614.png", :sentinel, 1.93, 121, :bipedal, :neutronic,
      :rifle, :spectral, :subsonic, :none,
      "Low security sentinel droid. Used to protect areas of the ship from intruders. A slow but sure device."],
    ["615", "615.png", :sentinel, 1.2, 29, :antigrav, :neutronic,
      :laser, :spectral, :infrared, :none,
      "Sophisticated sentinel droid. Only 2000 built by the Nicholson corporation. These are now very rare."],
    ["629", "629.png", :sentinel, 1.09, 59, :tracks, :neutronic,
      :laser, :spectral, :subsonic, :none,
      "Slow sentinel droid. Lasers are built into the turret. These are mounted on a small tank body. May be fitted with an auto-cannon on the Gillen version."],
    ["711", "711.png", :battle, 1.93, 102, :bipedal, :neutronic,
      :disruptor, :ultrasonic, :radar, :none,
      "Heavy duty battle droid. Disruptor is built into the head. One of the first in service with the Military."],
    ["742", "742.png", :battle, 1.87, 140, :bipedal, :neutronic,
      :disruptor, :spectral, :radar, :none,
      "This version is the one mainly used by the Military."],
    ["751", "751.png", :battle, 1.93, 227, :bipedal, :neutronic,
      :laser, :spectral, :none, :none,
      "Very heavy duty battle droid. Only a few have so far entered service. These are the most powerful battle units ever built."],
    ["821", "821.png", :security, 1.0, 28, :antigrav, :neutronic,
      :laser, :spectral, :radar, :infrared,
      "A very reliable anti-grav unit is fitted into this droid. It will patrol the ship and eliminate intruders as soon as detected by powerful sensors."],
    ["834", "834.png", :security, 1.1, 34, :antigrav, :neutronic,
      :laser, :spectral, :radar, :none,
      "Early type anti-grav security droid. Fitted with an over-driven anti-grav unit. This droid is very fast but is not reliable."],
    ["883", "883.png", :security, 1.62, 79, :wheels, :neutronic,
      :exterminator, :spectral, :radar, :none,
      "This droid was designed from archive data. For some unknown reason it instills great fear in Human adversaries."],
    ["999", "999.png", :command, 1.87, 162, :antigrav, :primode,
      :laser, :infrared, :radar, :subsonic,
      "Experimental command cyborg. Fitted with a new type of brain. Mounted on a Security Droid anti-grav unit for convenience.\n\n\nWarning: the influence device may not control a primode brain for long."]
  ]
  
  @@class_name_short={ :influence=>"Influence", :disposal=>"Disposal", :servant=>"Servant",
    :messenger=>"Messenger", :maintenance=>"Maintenance", :crew=>"Crew",
    :sentinel=>"Sentinel", :battle=>"Battle", :security=>"Security", :command=>"Command" }

  @@class_name_long={ :influence=>"Influence Device", :disposal=>"Disposal Robot",
    :servant=>"Servant Robot", :messenger=>"Messenger Robot",
    :maintenance=>"Maintenance Droid", :crew=>"Crew Droid",
    :sentinel=>"Sentinel Droid", :battle=>"Battle Droid",
    :security=>"Security Droid", :command=>"Command Cyborg" }
  
  @@drive_name={:none=>"None", :tracks=>"Tracks", :antigrav=>"Anti-grav", 
                :tripedal=>"Tripedal", :wheels=>"Wheels", :bipedal=>"Bipedal"}
  @@drive_speed={:none=>0, :tracks=>2, :antigrav=>3, 
                :tripedal=>3, :wheels=>5, :bipedal=>3}

  @@weapon_name={ :none=>"None", :laser=>"Lasers", :rifle=>"Laser Rifle",
                  :disruptor=>"Disruptor", :exterminator=>"Exterminator" }
  @@weapon_damage={ :none=>0, :laser=>30, :rifle=>50,
                  :disruptor=>80, :exterminator=>150 }
  @@brain_name={ :none=>"None", :neutronic=>"Neutronic", :primode=>"Primode" }
  
  @@sensor_name={ :none=>"-", :spectral=>"Spectral", :infrared=>"Infra-red",
                  :subsonic=>"Subsonic", :ultrasonic=>"Ultra-sonic", :radar=>"Radar" }
  
  def initialize
    @@data.each { |robot|
      # picture
      image=Rubygame::Surface.load_image($datapath+"images/"+robot[1])
      raise "Graphics file not found" if image.nil?
      robot[1]=image      
    }
    
  end
  
  def count
    @@data.length
  end
  
  def data(id)
    {
      :strength=>100,
      :drive => @@data[id][5],
      :speed=>@@drive_speed[@@data[id][5]],
      :weapon => @@data[id][7],
      :weapon_range=>5,
      :weapon_delay => 50,
      :weapon_damage=>@@weapon_damage[@@data[id][7]]    
    }
  end
  
  def name(id)
    @@data[id][0]
  end
  
  def image(id)
    @@data[id][1]
  end
  
  def class(id)
    @@class_name_short[@@data[id][2]]
  end
  
  def description(id)
    @@class_name_long[@@data[id][2]]
  end
  
  def height(id)
    @@data[id][3]
  end
  
  def weight(id)
    @@data[id][4]
  end
  
  def drive(id)
    @@drive_name[@@data[id][5]]
  end
  
  def brain(id)
    @@brain_name[@@data[id][6]]
  end
  
  def weapon(id)
    @@weapon_name[@@data[id][7]]
  end
  
  def sensor1(id)
    @@sensor_name[@@data[id][8]]
  end
  
  def sensor2(id)
    @@sensor_name[@@data[id][9]]
  end
  
  def sensor3(id)
    @@sensor_name[@@data[id][10]]
  end
  
  def notes(id)
    @@data[id][11]
  end
  
  def make_sprites(filename, captured)
    raise "No filename" if filename.nil?
    
    d=250
    image=Rubygame::Surface.new([6*d, 4*d])
    image.fill($color[:white])
    for x in 0...6
      for y in 0...4
        img=@@data[y*6+x][1]
        img.blit(image, [x*d+(d-img.w)/2, y*d+(d-img.h)/2])
        if captured && !(x==0 && y==0)
          img=@@data[0][1]
          img.set_colorkey(img.get_at(0,0))
          img.set_alpha(150)
          img.blit(image, [x*d+(d-img.w)/2, y*d+(d-img.h)/2])
        end
      end
    end
    new_image = image.zoom(64.0/d, false);
    new_image.savebmp(filename)
  end
end
