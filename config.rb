# Debug mode flag

$debug_mode=false
#$debug_mode=true # Show fps information

# Sound mode flag

#$sound_enabled=false # no sound
#$sound_enabled=:aplay # Use Linux aplay command to play sound files
$sound_enabled=:SDL # Use SDL to play sound files

# Music flag
# Rubygame does not support music, but can be patched to include music playback.
$music_enabled=false
#$music_enabled=true # only if the music patch is used


# Theme selection 

$datapath="themes/pokemon/"   # Erika's version
#$datapath="themes/modern/"   # hires robot pictures
#$datapath="themes/c64/"      # C64 original graphics

# Flags to use when creating surfaces
# Any combination of SWSURFACE, HWSURFACE, SRCCOLORKEY 
# See the Rubygame:Surface.new documentation for more information

$SURFACE_FLAGS=nil # default (SWSURFACE)
#$SURFACE_FLAGS=Rubygame::HWSURFACE # Put surface in graphic card memory if possible

# Screen size scaling
$scale=1.0
#$scale=2

# Colors
$color={
  :black=>[0, 0, 0],
  :white=>[0xfd, 0xfe, 0xfc],
  :red=>[0xbe, 0x1a, 0x24],
  :cyan=>[0x30, 0xe6, 0xc6],
  :purple=>[0xb4, 0x1a, 0xe2],
  :green=>[169,255,152], #[0x1f, 0xd2, 0x1e],
  :blue=>[0x21, 0x1b, 0xae],
  :yellow=>[0xdf, 0xf6, 0x0a],
  :orange=>[0xb8, 0x41, 0x04],
  :brown=>[0x6a, 0x33, 0x04],
  :lightRed=>[0xfe, 0x4a, 0x57],
  :darkGray=>[0x42, 0x45, 0x40],
  :middleGray=>[0x70, 0x74, 0x6f],
  :lightGreen=>[0x59, 0xfe, 0x59],
  :lightBlue=>[0x5f, 0x53, 0xfe],
  :lightGray=>[0xa4, 0xa7, 0xa2]
}

