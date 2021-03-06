'':::::::[ Driver Object for the Scribbler 2 ]:::::::::::::::::::::::::::::::::
 
{{{
┌───────────────────────────────────────┐
│          Scribbler S2 Object          │
│(c) Copyright 2010 Bueno Systems, Inc. │
│   See end of file for terms of use.   │
└───────────────────────────────────────┘
This object provides both high- and low-level drivers for the
Parallax Scribbler S2 robot.

Version History
───────────────

2010.09.16: Initial Version 1(M) release
2010.09.28: Version 1(N) release:
              Fixed bug in _ee* Spin routines.
              Upped size of sound buffer to 1200.
              Added calibration methods for light sensors.
              Added 1/2 sec. delay to start routine.
2010.10.18:   Added check for zero time in play_tone.
2010.10.25:   Added log response method for light sensors.
2010.10.27: Version 1(O) release:
              Added methods to save default line sensor threshold.
2010.10.28:   Fixed bugs in calibration methods.
2010.11.15: Version 1(P) release:
              Added self-documentation features.
              Added sensitivity setting for obstacle detection.
}}

{{=======[ Introduction ]=========================================================

S2.spin provides low-level drivers for the S2 Robot's various functions, as well as
top-level access functions to interface with those drivers. Driver functions are
separated into four additional cogs:
''
''  1. Analog, button, and LED drivers.
''  2. Motor driver.
''  3. Sound sequencer and synthesizer.
''  4. Microphone envelope detector.
''
Driver #1 is required and is started with the S2 object's main `start method. The
other drivers are optional, depending upon the user's requirements, and have their
own start methods (`start_motors, `start_tones, `start_mic_env). The S2 object's
`stop method stops all driver cogs which have been started.

The analog, button, and LED drivers are the heartbeat of the system. The analog
driver continuously cycles through sixteen analog inputs and updates their states
with a one-millisecond cycle time. The button driver monitors the state
of the S2's single pushbutton and, depending on the user-selected button mode, can
cause it to reset the S2, while displaying the button-press count on the LEDs, and
record the number of button presses in EEPROM for use by the newly-restarted user
program. The LED driver manages the LEDs' polarity and PWMing to provide various
shades and hues from the S2's red/green LEDs and blue power LED. It doesn this via
the LEDs' shift register port.

}}


''=======[ Constants... ]=========================================================

CON

  ''-[ Version, etc. ]-
  {{ Version numbers and miscellaneous other constants. }}

  VERSION         = 1                   'Major version ID.
  SUBVERSION      = "P"                 'Minor version ID.

  _TONE_Q_SIZE = 1200                   'Sets the size of the sound buffer (words).

  NO_CHANGE       = -1          
  FOREVER         = $7fff_ffff  
  UNDEF           = $8000_0000

  ACK             = true
  NAK             = false

  #0, NONE, LEFT, RIGHT, CENTER, POWER  'Used with LEDs, light sensors, line sensors,
                                        'obstacle sensors, and wheels.
  
  ''-[ Button and LEDs ]-
  {{ The button constants are used internally for setting and testing button modes.
     The LED constansts can be used for turning the LEDs on and off and for setting intensity, blinking, and colors. }}

  'Button constants:

 { RST_ENA         = $02         'Bit selector for button reset enable.
  LED_ENA         = $01         'Bit selector for button reset LED indicator enable.

  'LED constants: 

  OFF             = 0           'Applies to all LEDs.
  
  RED             = $f0         'Apply to red/green LEDs only...
  ORANGE          = $b4
  YELLOW          = $78
  CHARTREUSE      = $4b
  GREEN           = $0f
  DIM_RED         = $70
  DIM_GREEN       = $07
  BLINK_RED       = $f1
  BLINK_GREEN     = $1f
  ALT_RED_GREEN   = $ff
  
  BLUE            = $f0         'Apply to power LED only...
  BLINK_BLUE      = $f1
  DIM_BLUE        = $70  }

  ''-[ Tone generator ]-
  {{ These constants are used to set the voices in the tone player and to form its commands. }}

  #0, SQU, SAW, TRI, SIN        'Square, sawtooth, triangle, sine.

  #1, STOP, PAUSE, PLAY         'Tone player immediate commands.
  #0, TONE, VOLU, SYNC, PAUS    'Tone player sequence commands.

  ''-[ Result array indices ]-
  {{ These constants can be used to reference the various values in the Results array. }}

 { ADC_VSS         =  0
  ADC_VDD         =  1
  ADC_5V          =  2
  ADC_5V_DIV      =  3
  ADC_VBAT        =  4
  ADC_VTRIP       =  5
  ADC_IDD         =  6

  ADC_RIGHT_LGT   =  7
  ADC_CENTER_LGT  =  8
  ADC_LEFT_LGT    =  9

  ADC_RIGHT_LIN   = 10
  ADC_LEFT_LIN    = 11

  ADC_P6          = 12
  ADC_P7          = 13

  ADC_IMOT        = 14
  ADC_IDLER       = 15
  CNT_IDLER       = 16

  LED_BYTES       = 18 'and 19
  TIMER           = 20 'and 21
  BUTTON_CNT      = 22    }

  ''-[ Propeller pins ]-
  {{ Port names for pins A0 through A31. }}

 { P0              =  0          'Hacker ports 0 - 5.
  P1              =  1
  P2              =  2
  P3              =  3
  P4              =  4
  P5              =  5  
  OBS_TX_LEFT     =  6          'Output to left obstacle IRED.
  LED_DATA        =  7          'Output to LED shift register data pin.
  LED_CLK         =  8          'Output to LED shift register clock pin.
  MIC_ADC_OUT     =  9          'Output (feedback) for microphone sigma-delta ADC.
  MIC_ADC_IN      = 10          'Input for microphone sigma-delta ADC.
  BUTTON          = 11          'Input for pushbutton.
  IDLER_TX        = 12          'Output to idler wheel encoder IRED.
  MOT_LEFT_ENC    = 13          'Input from left motor encoder.
  MOT_RIGHT_ENC   = 14          'Input from right motor encoder.
  OBS_TX_RIGHT    = 15          'Output to right obstacle IRED.
  MOT_LEFT_DIR    = 16          'Output to left motor controller direction pin.
  MOT_RIGHT_DIR   = 17          'Output to right motor controller direction pin.
  MOT_LEFT_PWM    = 18          'Output to left motor controller PWM pin.
  MOT_RIGHT_PWM   = 19          'Output to right motor controller PWM pin.
  OBS_RX          = 20          'Input from obstacle detector IR receiver.  }
  SPEAKER         = 26 '21          'Output to speaker amplifier.
 { MUX0            = 22          'Outputs to analog multiplexer address pins.
  MUX1            = 23
  MUX2            = 24
  MUX3            = 25
  _MUX_ADC_OUT    = 26          'Output (feedback) from main sigma-delta ADC.
  _MUX_ADC_IN     = 27          'Input to main sigma-delta ADC.
  SCL             = 28          'Output clock to EEPROMs.
  SDA             = 29          'Input/Output data from/to EEPROMs.
  TX              = 30          'Output to RS232.
  RX              = 31          'Input from RS232.

  ''-[ ADC constants ]-
  {{ These are the analog multiplexer addresses controlled by pins MUX0 to MUX3. }}

  _MUX_IMOT       =  0          'Motor current.
  _MUX_VTRIP      =  1          '
  _MUX_VBAT       =  2          'Battery voltage.
  _MUX_IDLER      =  3          'Idler encoder.
  _MUX_VSS        =  4          'Vss reference.
  _MUX_5V_DIV     =  5          '               
  _MUX_5V         =  6          '+5V reference.
  _MUX_VDD        =  7          '+3.3V reference.
  _MUX_P7         =  8          'Hacker port P7 analog input.
  _MUX_RIGHT_LGT  =  9          'Right light sensor.
  _MUX_CENTER_LGT = 10          'Center light sensor.
  _MUX_P6         = 11          'Hacker port P6 analog input.
  _MUX_IDD        = 12          'Vdd current.
  _MUX_LEFT_LGT   = 13          'Left ligth sensor.
  _MUX_RIGHT_LIN  = 14          'Right line sensor.
  _MUX_LEFT_LIN   = 15          'Left line sensor.
   
  _VSS            = _MUX_VSS << 12 | ADC_VSS << 8
  _VDD            = _MUX_VDD << 12 | ADC_VDD << 8
  _5V             = _MUX_5V << 12 | ADC_5V << 8
  _5V_DIV         = _MUX_5V_DIV << 12 | ADC_5V_DIV << 8
  _VBAT           = _MUX_VBAT << 12 | ADC_VBAT << 8
  _IDD            = _MUX_IDD << 12 | ADC_IDD << 8
  _IMOT           = _MUX_IMOT << 12 | ADC_IMOT << 8
  _VTRIP          = _MUX_VTRIP << 12 | ADC_VTRIP << 8
  _IDLER          = _MUX_IDLER << 12 | ADC_IDLER << 8
  _RIGHT_LGT      = _MUX_RIGHT_LGT << 12 | ADC_RIGHT_LGT << 8
  _LEFT_LGT       = _MUX_LEFT_LGT << 12 | ADC_LEFT_LGT << 8
  _CENTER_LGT     = _MUX_CENTER_LGT << 12 | ADC_CENTER_LGT << 8
  _RIGHT_LIN      = _MUX_RIGHT_LIN << 12 | ADC_RIGHT_LIN << 8
  _LEFT_LIN       = _MUX_LEFT_LIN << 12 | ADC_LEFT_LIN << 8
  _P6             = _MUX_P6 << 12 | ADC_P6 << 8
  _P7             = _MUX_P7 << 12 | ADC_P7 << 8
   
  ''-[ EEPROM addresses ]-
  

  EE_BASE          = 0                     'Base address for EEPROM data area.

  EE_RESET_CNT     = EE_BASE + 0           '[1 byte]  Reset count address.
  EE_WHEEL_CALIB   = EE_BASE + 1           '[5 bytes] Wheel calibration data.
  EE_LIGHT_CALIB   = EE_BASE + 6           '[4 bytes] Light sensor calibration data.
  EE_LINE_THLD     = EE_BASE + 10          '[2 bytes] Line sensor threshold data.
  EE_OBSTACLE_THLD = EE_BASE + 12          '[2 bytes] Obstacle threshold data.
  
  EE_USER_AREA     = EE_BASE + $400        'Beginning of unreserved user area.

  ''-[ ADC Soak times ]-

  _SOAK_1us       = 0 << 4
  _SOAK_2us       = 1 << 4
  _SOAK_4us       = 2 << 4
  _SOAK_8us       = 3 << 4
  _SOAK_16us      = 4 << 4
  _SOAK_32us      = 5 << 4
  _SOAK_64us      = 6 << 4
  _SOAK_128us     = 7 << 4
  _SOAK_256us     = 8 << 4
  _SOAK_512us     = 9 << 4
  _SOAK_1ms       = 10 << 4
  _SOAK_2ms       = 11 << 4
  _SOAK_4ms       = 12 << 4
  _SOAK_8ms       = 13 << 4
  _SOAK_16ms      = 14 << 4
  _SOAK_32ms      = 15 << 4
                    
  ''-[ Filter values ]-

  _LPF_NONE       = 0 << 1
  _LPF_1ms        = 1 << 1
  _LPF_2ms        = 2 << 1
  _LPF_4ms        = 3 << 1
  _LPF_8ms        = 4 << 1
  _LPF_16ms       = 5 << 1
  _LPF_32ms       = 6 << 1
  _LPF_64ms       = 7 << 1

  ''-[ Reference values ]-

  _REF_3V3         = 0
  _REF_5V0         = 1

  ''-[ Default values ]-
  {{ These values are assigned to their respective variables on startup, unless overriding values are stored
     in EEPROM. }}

  DEFAULT_FULL_CIRCLE   = 955
  DEFAULT_WHEEL_SPACE   = 153
  DEFAULT_LIGHT_SCALE   = 0
  DEFAULT_LINE_THLD     = 32
  DEFAULT_OBSTACLE_THLD = 1             

  ''-[ Motor constants ]-
  {{ Command, status bits, and indices into the motor debug array. }}

  'Command bits:

  MOT_IMM         = %001        'Sets immediate (preemptive) mode for motor command.
  MOT_CONT        = %010        'Sets continuous (non-distance) mode for motor command.
  MOT_TIMED       = %100        'Sets timeout mode for motor command.

  'Status bits:

  MOT_RUNNING     = %01
  MOT_STOPPED     = %00

  'Debug indices:
  'These are indices into the motor debug array.
  'Offsets are in bytes counting from @Motor_stat.
  'The prefix indicates size of each value (Byte, Word, Long)

  L_ALL_VEL       = 4           'All four control velocities.                                   
  B_TARG_VEL      = 4           'Target velocity.                        
  B_CUR_VEL       = 5           'Current (measured) velocity.
  B_END_VEL       = 6           'End velocity for this stroke.
  B_MAX_VEL       = 7           'Maximum velocity for this stroke.
  L_BOTH_DIST     = 8           'Both left and right stroke distances.
  W_RIGHT_DIST    = 8           'Right stroke distance.
  W_LEFT_DIST     = 10          'Left stroke distance.
  L_RIGHT_COUNT   = 12          'Right coordinated countdown value.
  L_LEFT_COUNT    = 16          'Left coordinated countdown value.
  L_DOM           = 20          'Dominant distance and count.
  W_DOM_DIST      = 20          'Total distance for dominant wheel to travel.
  W_DOM_COUNT     = 22          'Distance the dominant wheel has traveled.
   }
''=======[ Public Spin methods... ]===============================================
''
''-------[ Start and stop methods... ]--------------------------------------------
''
'' Start and stop methods are used for starting individual cogs or stopping all
'' of them at once.

'PUB start | i

  '' Main start routine for S2 object. Stops ALL cogs, so
  '' IT MUST BE CALLED FIRST, before starting other cogs.
  ''
  '' Example: s2.start 'Start s2 object.
    
  'stop_all
  'results_addr := @Results
  'wordfill(results_addr, 0, 40)
  'seq_addr := @Adc_sequence
  {if (Adc_cog := cognew(@adc_all, 0) + 1)
    outa := constant(1 << SCL)
    dira := constant(1 << SPEAKER | 1 << SCL)
    _i2c_stop
    if (Reset_count := _ee_rdbyte(EE_RESET_CNT))
      _ee_wrbyte(EE_RESET_CNT, 0)
    if Reset_count > 8
      Reset_count~
    read_wheel_calibration
    read_light_calibration
    read_line_threshold
    set_led(POWER, BLUE)
    delay_tenths(5)
    return true
  else
    return false  }

{PUB start_motors

  '' Start motor control cog.
  ''
  '' Example: s2.start_motors 'Start the motor controller.

  ifnot (Motor_cog)
    Motor_cmd~~
    midler_addr := @Results + (CNT_IDLER << 1)
    result := (Motor_cog := cognew(@motor_driver, @Motor_cmd) + 1) > 0
    repeat while Motor_cmd
    In_path~
    here_is(0, 0)
    heading_is(Qtr_circle)
    set_speed(7)
       }
PUB start_tones

  '' Start tone sequencer.
  ''
  '' Example: s2.start_tones 'Start the tone sequencer/generator.
  'dira[SPEAKER] := 1
  
  ifnot (Tone_cog)
    wordfill(@Tone_queue, 0, _TONE_Q_SIZE + 4)
    dttime := clkfreq / $1_0000 * 2
    queue_addr := @Tone_queue
    result := (Tone_cog := cognew(@tone_seq, 0) + 1) > 0
    command_tone(PLAY)
     
{PUB start_mic_env

  '' Start microphone Envelope detector.
  ''
  '' Example: s2.start_mic_env 'Start the microphone Envelope detector.

  ifnot (Mic_cog)
    mic_dt := clkfreq / 8000
    mic_cyc := 8000 / 20
    return (Mic_cog := cognew(@env_det, @Envelope) + 1) > 0
       
PUB stop_all

  '' Stop ALL cogs.
  ''
  '' Example: s2.stop_all 'Stop all S2 cogs.

  if (Adc_cog)
    cogstop(Adc_cog~ - 1)
  if (Tone_cog)
    cogstop(Tone_cog~ - 1)
  if (Mic_cog)
    cogstop(Mic_cog~ - 1)
  if (Motor_cog)
    cogstop(Motor_cog~ - 1)
}
{{
---------[ Microphone methods... ]---------------------------------------------

   Microphone methods provide data from the S2's built-in microphone.
}}
{ 
PUB get_mic_env

  '' Get the average loudness (Envelope) value of the microphone input.
  ''
  '' Example: loudness := s2.get_mic_env 'Set loudness equal to current mic level.

  return Envelope

{{
---------[ Drawing methods... ]---------------------------------------------------

   Drawing methods can be used for drawing with the S2 or for any application
   that requires keeping track of the robot's position and heading.
}}
 
PUB begin_path

  '' Begin a path of connected movements.
  ''
  '' Example: s2.begin_path

  ifnot (In_path)
    In_path := 1 
     
PUB end_path

  '' Output the last movement in the path, if there is one, and end the path.
  '' NOTE: Omitting this statement may cause the last path segment not to be drawn.
  ''
  '' Example: s2.end_path

  if (In_path == 2)
    run_motors(0, Path_Ldist, Path_Rdist, Path_time, Path_max_spd, 0)
  In_path~

PUB set_speed(spd)

  '' Set the speed (0 - 15) for the drawing methods, along with the "go_", "turn_",
  '' and "arc_" motion methods.
  ''
  '' Example: set_speed(7) 'Set the speed to half of maximum velocity.

  Current_spd := spd

PUB move_to(x, y)

  '' Move directly to the point (x, y).
  '' Units are approximately 0.5mm.
  ''
  '' Example: s2.move_to(1000, 50) 'Move to a point 500 mm to the right and 25mm above the origin.

  move_by(x - Current_x, y - Current_y)

PUB arc_to(x, y, radius)

  '' Move to the point (x, y) via an arc of the specified radius (+radius is CCW; -radius is CW).
  '' The Cartesian distance from the current location to the target position must be no more than
  '' 2 * radius. If it's greater than that, the robot will move in a straight line to the target
  '' position first to make up the difference, then perform the arc.
  '' Units are approximately 0.5mm.
  ''
  '' Example: s2.arc_to(1000, 50, -100) 'Move to the point 500 mm to the right and 25mm above the origin
  ''                                    '  in a clockwise arc of radius 25mm.

  arc_by(x - Current_x, y - Current_y, radius)

PUB move_by(dx, dy) | angle

  '' Move from the current location by the displacement (dx, dy).
  '' Units are approximately 0.5mm.
  ''
  '' Example: s2.move_by(100, 50) 'Move to a point 50 mm to the right and 25mm above the current location.

  turn_to(angle := _atan2(dy, dx))
  go_forward(^^(dx * dx + dy * dy))
  here_is(Current_x + dx, Current_y + dy)

PUB arc_by(dx, dy, radius) | dist2, dist, diam, half_angle, tilt

  '' Move from the current location byt the displacement (dx, dy) via an arc of the specified radius
  '' (+radius is CCW; -radius is CW). The Cartesian length of the displacement must be no more than
  '' 2 * radius. If it's greater than that, the robot will move in a straight line to the target
  '' position first to make up the difference, then perform the arc. Units are approximately 0.5mm.
  ''
  '' Example: s2.arc_by(50, 50, -100) 'Move to the point 25 mm to the right of and 25mm above the 
  ''                                  '  current location in a clockwise arc of radius 50mm.

  dist2 := dx * dx + dy * dy
  dist := ^^dist2
  tilt := _atan2(dy, dx)
  diam := ||radius << 1
  if (dist > diam)
    turn_to(tilt)
    go_forward(dist - diam)
    dist := diam
    dist2 := dist * dist
  half_angle := _atan2(dist >> 1, ^^(radius * radius - (dist2 >> 2)))
  if (radius < 0)
    half_angle := - half_angle
  
  turn_to(tilt - half_angle)  
  arc(half_angle << 1, radius)
  here_is(Current_x + dx, Current_y + dy)
  heading_is(tilt + half_angle)

PUB align_with(heading) | dw

  '' Turn so that the robot is pointed parallel to the desired heading (S2 angle units),
  '' either in the selected direction (returns 1) or opposite the selected direction
  '' (returns -1), whichever requires the shortest turn to achieve.
  ''
  '' Example: dir := s2.align_with(150) 'Point the robot to angle 150 (S2 angle units)
  ''                                    '  or opposite that angle. Set dir to ±1, accordingly.

  dw := (heading - Current_w) // Full_circle
  dw += Full_circle & (dw < 0)
  if (dw > Half_circle)
    dw -= Full_circle
  if (||dw =< Qtr_circle)
    result := 1
  else
    dw := dw - Half_circle + Full_circle & (dw < 0)
    result := -1
  turn(dw)
  heading_is(Current_w + dw)

PUB turn_to_deg(heading)

  '' Turn the robot to the desired heading (degrees).
  ''
  '' Example: s2.turn_to(135) 'Point the robot to an angle of 135 degrees.

  turn_to(heading * Full_circle / 360)

PUB turn_to(heading)

  '' Turn the robot to the desired heading (S2 angle units).
  ''
  '' Example: s2.turn_to(500) 'Point the robot to an angle of 500 S2 angle units.

  turn_by(heading - Current_w)

PUB turn_by_deg(dw)

  '' Turn the robot by the desired amount (degrees). +dw is CCW; -dw is CW.
  '' If the net turn angle is greater than 180 degrees, the shorter rotation
  '' in the opposite direction is used instead.
  ''
  '' Example: s2.turn_by_deg(90) 'Rotate the robot by an angle of 90 degrees CCW.

  turn_by(dw * Full_circle / 360)    

PUB turn_by(dw)

  '' Turn the robot by the desired amount (S2 angle units). +dw is CCW; -dw is CW.
  '' If the net turn angle is greater than Full_circle / 2, the shorter rotation
  '' in the opposite direction is used instead.
  ''
  '' Example: s2.turn_by(500) 'Rotate the robot by an angle of 500 S2 angle units CCW.

  dw //= Full_circle
  dw += Full_circle & (dw < 0)
  if (dw > Half_circle)
    dw -= Full_circle
  turn(dw)
  heading_is(Current_w + dw)
  return 1    

PUB here_is(x, y)

  '' Reset the current position to (x,y). Units are approximately 0.5mm.
  ''
  '' Example: s2.here_is(0, 0) 'Reset the origin to the current location.

  Current_x := x
  Current_y := y

PUB heading_is_deg(w)

  '' Reset the current heading to w degrees.
  ''
  '' Example: s2.heading_is_deg(90) 'Reset the current heading to 90 degrees.

  heading_is(w * Full_circle / 360)

PUB heading_is(w)

  '' Reset the current heading to w.
  ''
  '' Example: s2.heading_is(567) 'Reset the current heading to 567.

  Current_w := w // Full_circle
  Current_w += Full_circle & (Current_w < 0)

{{
---------[ Motion methods... ]-------------------------------------------------

   Motion methods control the movement of the S2 robot. MOTION METHODS DO NOT
   KEEP TRACK OF THE S2'S POSITION AND HEADING, unless called from one of the
   drawing methods. As such, they should NOT be mixed with calls to drawing
   methods.
}}

PUB read_wheel_calibration | circle, space

  '' Read calibration values from EEPROM, and use them if they're reasonable.
  '' Returns a packed long containing the calibration values. If no valid values
  '' exist in EEPROM, sets (and returns) the default values.
  ''
  '' Example: s2.read__wheel_calibration 'Get previously-written wheel calibration values.

  if (_ee_rdblock(@circle, EE_WHEEL_CALIB, 4))
    space := circle >> 16
    circle &= $ffff
    if (circle > 900 and circle < 1000 and space > 100 and space < 200)
      return set_wheel_calibration(circle, space)
  return default_wheel_calibration

PUB write_wheel_calibration

  '' Write current wheel calibration values to EEPROM.
  '' Returns true on success, false on failure.
  ''
  '' Example: s2.write_wheel_calibration 'Write Full_circle and Wheel_space to EEPROM.

  return  _ee_wrblock(@Full_circle, EE_WHEEL_CALIB, 4)

PUB default_wheel_calibration

  '' Restore calibration to default values. DOES NOT SAVE IN EEPROM.
  '' This method is optional unless read_calibration or set_calibration
  '' have been called.
  ''
  '' Example: s2.default_calibration 'Restore calibration defaults.

  return set_wheel_calibration(DEFAULT_FULL_CIRCLE, DEFAULT_WHEEL_SPACE)

PUB set_wheel_calibration(circle, space)

  '' Set calibration values to method's arguments, if they're reasonable.
  '' DOES NOT SAVE IN EEPROM.
  ''
  '' Example: s2.set_wheel_calibration(960, 160) 'Set Full_circle to 960 and
  ''                                             'Wheel_space to 160.
  
  Full_circle := circle
  Wheel_space := space
  _compute_calibration
  return get_wheel_calibration

PUB get_wheel_calibration

  '' Gets current calibration values: Full_circle in top 16 bits;
  '' Wheel_space in bottom 16 bits.

  return Full_circle << 16 | Wheel_space

PUB go_left(dist)

  '' Turn left and go forward from there by the indicated distance. Units are
  '' approximately 0.5mm.
  ''
  '' Example: s2.go_left(500) 'Turn left and move forward 250mm.

  turn_deg(90)
  go_forward(dist)

PUB go_right(dist)

  '' Turn right and go forward from there by the indicated distance. Units are
  '' approximately 0.5mm.
  ''
  '' Example: s2.go_right(500) 'Turn right and move forward 250mm.

  turn_deg(-90)
  go_forward(dist)

PUB go_forward(dist)

  '' Go forward by the indicated distance. Units are approximately 0.5mm.
  ''
  '' Example: s2.go_forward(500) 'Move forward 250mm.

  if (||dist == FOREVER)
    move(100, 100, 0, Current_spd, 1)
  else
    move(dist, dist, 0, Current_spd, 0)

PUB go_back(dist)

  '' Go backward by the indicated distance. Units are approximately 0.5mm.
  ''
  '' Example: s2.go_back(500) 'Move back 250mm.

  if (||dist == FOREVER)
    move(-100, -100, 0, Current_spd, 1)
  else
    move(-dist, -dist, 0, Current_spd, 0)

PUB turn_deg(ccw_degrees)

  '' Turn in place counter-clockwise by the indicated number of degrees.
  '' Negative values will turn clockwise.
  ''
  '' Example: s2.turn_deg(-90) 'Turn right.
   
  arc_deg(ccw_degrees, 0)   

PUB arc_deg(ccw_degrees, radius) | r, l

  '' Move in a counter-clockwise arc of the indicated radius by the specified
  '' number of degrees. Radius units are approximately 0.5mm. Negative angles
  '' result in a clockwise arc.
  ''
  '' Example: s2.arc_deg(90, 500) 'Make a sweeping left turn with a radius of 250mm.

  arc(Full_circle * ccw_degrees / 360, radius)

PUB turn(ccw_units)

  '' Turn in place counter-clockwise by the indicated number of degrees.
  '' Negative values will turn clockwise.
  ''
  '' Example: s2.turn(-50) 'Turn a bit to the right by 50 S2 angle units.
   
  arc(ccw_units, 0)  

PUB arc(ccw_units, radius) | r, l

  '' Move in a counter-clockwise arc of the indicated radius by the specified
  '' number of S2 angle units. Radius units are approximately 0.5mm. Negative angles
  '' result in a clockwise arc.
  ''
  '' Example: s2.arc(100, 50) 'Arc a bit to the left by 100 S2 angle units with
  ''                          '  a 25mm radius.

  r := ccw_units * (radius + WHEEL_SPACE) / WHEEL_SPACE
  l := ccw_units * (radius - WHEEL_SPACE) / WHEEL_SPACE
  move(l, r, 0, Current_spd, 0)

PUB turn_deg_now(ccw_degrees)

  '' Turn in place counter-clockwise by the indicated number of degrees.
  '' Negative values will turn clockwise.
  '' Preempts current motion in progress.
  ''
  '' Example: s2.turn_deg_now(-90) 'Immediate turn right.
   
  arc_deg_now(ccw_degrees, 0)   

PUB arc_deg_now(ccw_degrees, radius) | r, l

  '' Move in a counter-clockwise arc of the indicated radius by the specified
  '' number of degrees. Radius units are approximately 0.5mm. Negative angles
  '' result in a clockwise arc.
  '' Preempts current motion in progress.
  ''
  '' Example: s2.arc_deg_now(90, 500) 'Make an immediate sweeping left turn
  ''                                  'with a radius of 250mm.

  arc_now(Full_circle * ccw_degrees / 360, radius)

PUB turn_now(ccw_units)

  '' Turn in place counter-clockwise by the indicated number of degrees.
  '' Negative values will turn clockwise.
  '' Preempts current motion in progress.
  ''
  '' Example: s2.turn_now(-50) 'Immediately turn a bit to the right by 50 S2 angle units.
   
  arc_now(ccw_units, 0)  

PUB arc_now(ccw_units, radius) | r, l

  '' Move in a counter-clockwise arc of the indicated radius by the specified
  '' number of S2 angle units. Radius units are approximately 0.5mm. Negative angles
  '' result in a clockwise arc.
  '' Preempts current motion in progress.
  ''
  '' Example: s2.arc_now(100, 50) 'Immediately arc a bit to the left by 100 S2 angle
  ''                              'units with a 25mm radius.

  r := ccw_units * (radius + WHEEL_SPACE) / WHEEL_SPACE
  l := ccw_units * (radius - WHEEL_SPACE) / WHEEL_SPACE
  move_now(l, r, 0, Current_spd, 0)

PUB move(left_distance, right_distance, move_time, max_speed, no_stop) | max_d, max_pd, max_rvel, max_lvel, end_spd

  '' Base-level non-reactive user move routine. Does not interrupt motion in progress.
  '' If called during path construction, velocities will blend. If no path, velocity ramps to zero at end.
  '' This method may not return right away if it has to wait for current motion to complete.
  ''
  '' left_distance: Amount to move left wheel (-32767 - 32767) in 0.5mm (approx.) increments.
  '' right_distance: Amount to move right wheel (-32767 - 32767) in 0.5mm (approx.) increments.
  '' move_time: If non-zero, time (ms) after which to stop, regardless of distance traveled.
  '' max_speed (0 - 15): Maximum speed (after ramping).
  '' no_stop: If non-zero, keep running, regardless of distance traveled unless/until timeout or a preemptive change.
  ''
  '' Example: s2.move(10000, 5000, 10000, 7, 0) 'Move in a clockwise arc for 10000/2 mm on outside, or until 10 seconds elapse,
  ''                                            '  whichever occurs first, at half speed.

  left_distance := -32767 #> left_distance <# 32767
  right_distance := -32767 #> right_distance <# 32767
  max_speed := 0 #> max_speed <# 15
  Current_spd := max_speed
  
  if (In_path == 2)
    if ((left_distance ^ Path_Ldist) & $8000 or (right_distance ^ Path_Rdist) & $8000)
      end_spd~
    else
      max_d := ||left_distance #> ||right_distance
      max_pd := ||Path_Ldist #> ||Path_Rdist
      max_rvel := ((||right_distance * max_speed + (max_d >> 1))/ max_d <# (||Path_Rdist * Path_max_spd + (max_pd >> 1))/ max_pd) {
        }         * max_d / (||right_distance #> 1)
      max_lvel := ((||left_distance * max_speed + (max_d >> 1))/ max_d <# (||Path_Ldist * Path_max_spd + (max_pd >> 1))/ max_pd) {
        }         * max_d / (||left_distance #> 1)
      end_spd := max_rvel <# max_lvel
    run_motors(0, Path_Ldist, Path_Rdist, Path_time, Path_max_spd, end_spd)
    result := end_spd
  if (In_path => 1)
    if (no_stop and move_time == 0)
      run_motors(MOT_CONT, left_distance, right_distance, move_time, max_speed, 0)
      In_path~
    else
      Path_Ldist := left_distance
      Path_Rdist := right_distance
      Path_time := move_time
      Path_max_spd := max_speed
      In_path := 2
  else
    run_motors(MOT_CONT & (no_stop <> 0), left_distance, right_distance, move_time, max_speed, 0)

PUB wheels_now(left_velocity, right_velocity, move_time)

  '' Set the wheel speeds preemptively to left_velocity and right_velocity (-255 to 255).
  '' If move_time > 0, time out after move_time ms.
  '' Interrupts any movement in progress and deletes all path information.
  '' This method always returns immediately.
  ''
  '' Example: s2.wheels_now(-255, 255, 5000) 'Turn left, in place, at maximum speed, for five seconds. 

  move_now(left_velocity, right_velocity, move_time, (||left_velocity #> ||right_velocity <# 255) >> 4, 1)

PUB move_now(left_distance, right_distance, move_time, max_speed, no_stop)

  '' Base-level preemptive user routine for reactive movements (e.g. for line following).
  '' Interrupts any movement in progress and deletes all path information.
  '' This method always returns immediately. 
  ''
  '' left_distance: Amount to move left wheel (-32767 - 32767) in 0.5mm (approx.) increments.
  '' right_distance: Amount to move right wheel (-32767 - 32767) in 0.5mm (approx.) increments.
  '' move_time: If non-zero, time (ms) after which to stop, regardless of distance traveled.
  '' max_speed (0 - 15): Maximum speed (after ramping).
  '' no_stop: If non-zero, keep running, regardless of distance traveled unless/until timeout or another preemptive change.
  ''
  '' Example: s2.move_now(1000, -1000, 0, 15, 1) 'Rotate in place clockwise at full speed until preempted.  

  In_path~
  run_motors(MOT_IMM | MOT_CONT & (no_stop <> 0), left_distance, right_distance, move_time, max_speed, 0)

PUB stop_now

  '' Stops movement immediately and deletes all path information.
  ''
  '' Example: s2.stop_now.

  In_path~
  run_motors(MOT_IMM, 0, 0, 0, 0, 0)

PUB wait_stop

  '' Wait for all current and pending motions to complete.
  ''
  '' Example: s2.wait_stop

  repeat while moving

PUB stalled | stat, mvel, ivel, itime, vstall, istall

  '' Checks whether the S2 is stalled by testing both the motor current
  '' and the activitity of the idler wheel encoder.
  '' Returns true if stalled; false if not.
  ''
  '' Example: repeat until s2.stalled 'Execute the repeat block as long as the bot is not stalled.

  if ((stat := Motor_stat) & $03)
    mvel := ||(stat ~> 24 + stat << 8 ~> 24)
    itime := (stat >> 8) & $ff
    ifnot (ivel := (stat & $fc) << 3)
      ivel := 512 / itime
    if (vstall := mvel * 14 / ivel > 20 + Stall_hyst)
      Stall_hyst := -2
    else
      Stall_hyst := 2
    istall := get_adc_results(ADC_IMOT) > (75 * get_adc_results(ADC_VBAT)) >> 7
    return vstall or istall

PUB moving

  '' Return TRUE if motion in progress or pending, FALSE if stopped with no pending motions.
  ''
  '' Example: repeat while s2.moving 'Continuously execute the following repeat block until motions are finished.

  return Motor_stat & $03 <> 0

PUB motion

  '' Return current motion status:
  ''
  ''' 31            24 23           16 15            8 7         2 1 0
  ''' ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
  ''' │±  Left wheel  │±  Right wheel │  Idler timer  │ Idler spd │Mov│ , where
  ''' └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
  ''
  '' Left wheel and right wheel are signed, twos complement eight bit velocity values,
  '' Idler timer is the time in 1/10 second since the last idler edge,
  '' Idler spd is an unsigned six-bit velocity value, and
  '' Mov is non-zero iff one or more motors are turning.
  '' Left and right wheel velocities are instanteous encoder counts over a 1/10-second interval.
  '' Idler wheel wheel velocity is updated every 1/10 second and represents the idler encoder count during the last 1.6 seconds.
  ''
  '' Example: left_vel := s2.motion ~> 24 'Get the current left wheel velocity as a signed 32-bit value.
  
  return Motor_stat

PUB motion_addr

  '' Return the address of the status and debug array.
  ''
  '' Example: longmove(@my_stats, s2.motion_addr, 6) 'Copy all status data to the local array my_stats.

  return @Motor_stat

PUB move_ready

  '' Return TRUE if a new motion command can be accepted without waiting, FALSE if a command is still pending.
  ''
  '' Example: repeat until s2.move_ready 'Continuously execute the following repeat block until a new move can be accepted.

  return Motor_cmd == 0

PUB run_motors(command, left_distance, right_distance, timeout, max_speed, end_speed)

  {{ Base level motor activation routine. Normally, this method is not called by the user but is called by the
     several convenience methods available to the user.
  }}
  ''
  '' `command: the OR of any or all of the following:
  ''
  ''   MOT_IMM:   Commanded motion starts immediately, without wating for prior motion to finish.
  ''   MOT_CONT:  Commanded motion will continue to run at wheel ratio given by left and right distances,
  ''                even after distances are covered.
  ''
  '' `left_distance, `right_distance (-32767 to 32767):
  ''
  ''
  ''   The distances to be covered by the left and right wheels, respectively. Units are approximately 0.5mm.
  ''
  '' `timeout (0 - 65535): If non-zero, time limit (ms) after which motion stops, regardless of distance covered.
  ''
  '' `max_speed (0 - 15): Peak velocity to be reached during motion profile.
  ''
  '' `end_speed (0 - 15):
  ''
  ''   Velocity to be attained at end of motion profile. If non-zero, this is the velocity needed to
  ''   segue smoothly into the next motion profile. end_speed should never be greater than max_speed.
  ''
  '' `Example: s2.run_motors(s2#MOT_CONT | s2#MOT_TIMED, 100, -100, 5000, 8, 0) 'Turn in place clockwise for 5 seconds at half speed. 

  if (command & MOT_IMM)
    long[@Motor_Rdist]~
    long[@Motor_cmd]~
  else
    repeat while long[@Motor_cmd]
  Motor_Rdist := -32767 #> right_distance <# 32767
  Motor_Ldist := -32767 #> left_distance <# 32767
  long[@Motor_cmd] := timeout << 16 | (0 #> max_speed <# 15) << 8 | (0 #> end_speed <# 15) << 4 | command & (MOT_IMM | MOT_CONT)
  if (left_distance or right_distance)
    timeout := cnt
    repeat until moving or cnt - timeout > 800_000

''
''
''-------[ Sensor methods... ]-------------------------------------------------
''
'' Sensor methods return information about the S2's various onboard sensors.
''
{{ `NOTE: The following obstacle threshold methods affect only the obstacle sensor threshold used when
   `obstacle is called with a threshold value of zero.}}

PUB read_obstacle_threshold | thld

  {{ Read the obstacle threshold value from EEPROM, and substitute it for the
     default if the checksum is correct and the value is within reasonable bounds.
     Returns the threshold value read on success.
     If no valid calibration values exist in EEPROM, sets to (and returns) the
     default value, DEFAULT_OBSTACLE_THLD.
  ''
  '' `Example: s2.read_obstacle_threshold
  ''
  ''     Get previously-written obstacle threshold value.
  }}

  if (_ee_rdblock(@thld, EE_OBSTACLE_THLD, 1))
    thld &= $ff
    if (thld > 0 and thld =< 100)
      return set_obstacle_threshold(thld)
  return default_obstacle_threshold
 
PUB write_obstacle_threshold

  {{ Write the current obstacle threhsold value to EEPROM.
     Returns true on a successful write; false otherwise.
  ''
  '' `Example: s2.write_obstacle_threshold
  ''
  ''     Write current obstacle threshold value to EEPROM.
  }}

  return _ee_wrblock(@Obstacle_thld, EE_OBSTACLE_THLD, 1)

PUB default_obstacle_threshold

  {{ Restore the obstacle threshold to its default value. DOES NOT SAVE IN EEPROM.
     This method is optional unless `read_obstacle_threshold or `set_obstacle_threshold
     has been called successfully. Returns the default value, DEFAULT_OBSTACLE_THRESHOLD.
  ''
  '' `Example: s2.default_obstacle_threshold
  ''
  ''     Restore calibration default.
  }}

  return set_obstacle_threshold(DEFAULT_OBSTACLE_THLD)

PUB set_obstacle_threshold(thld)  

  {{ Set the obstacle sensor threshold to thld. DOES NOT SAVE IN EEPROM. Returns the value set.
  ''  
  '' `Example: s2.set_obstacle_threhsold(10)
  ''
  ''     Set obstacle sensor threshold to 10.
  ''
     This becomes the value used when the `obstacle method is called with an argument of zero.
  }}
  
  return Obstacle_thld := thld

PUB get_obstacle_threshold

  '' Returns the current obstacle sensor threshold.
  ''
  '' `Example: Thld := s2.get_obstacle_threshold
  ''
  ''     Set `Thld to the current obstacle threshold.
  
  return Obstacle_thld  
  
PUB obstacle(side, threshold)

  '' Return the value of the obstacle detection: `true = obstacle; `false = no obstacle.
  '' 
  '' `side (LEFT or RIGHT): Select the side to check.
  '' `threshold (0 - 100): Set the threshold of the  detection. At high threshold values,
  ''     only very close objects will be detected. At low values, farther objects (and possibly
  ''     the rolling surface itself) will be detected. If `threshold == 0 the default (or
  ''     calibration) threshold setting will be used. 
  ''
  '' `Example: obstacle_both := s2.obstacle(s2#LEFT, 0) and s2.obstacle(s2#RIGHT, 0)
  ''
  ''     Obstacle_both is set on left AND right obstacles, using the default sensitivity.

  ifnot (threshold)
    threshold := Obstacle_thld
  threshold := threshold #> 1 <# 100
  frqa := 14000 * threshold + 20607 * (100 - threshold)
  if (side == LEFT)
    ctra := %00100 << 26 | OBS_TX_LEFT
    dira[OBS_TX_LEFT]~~
  elseif (side == RIGHT)
    ctra := %00100 << 26 | OBS_TX_RIGHT
    dira[OBS_TX_RIGHT]~~
  waitcnt(cnt + 24000)
  result := ina[OBS_RX] == 0
  dira[OBS_TX_LEFT]~
  dira[OBS_TX_RIGHT]~
  ctra~
  waitcnt(cnt + clkfreq / 1000)

{{ `NOTE: The following line_threshold methods affect only the line sensor threshold used when
   line_sensor is called with a threshold value of zero.}}

PUB read_line_threshold | thld

  '' Read the line threshold value from EEPROM, and substitute it for the default
  '' if checksum is correct and value is reasonable.
  '' Returns the threshold value read on success.
  '' If no valid calibration values exist in EEPROM, sets to (and returns)the
  '' default value DEFAULT_LINE_THLD.
  ''
  '' Example: s2.read_line threshold 'Get previously-written line threshold value.

  if (_ee_rdblock(@thld, EE_LINE_THLD, 1))
    thld &= $ff
    if (thld > 5 and thld < 100)
      return set_line_threshold(thld)
  return default_line_threshold

PUB write_line_threshold

  '' Write current line threhsold value to EEPROM.
  '' Returns true on a successful write; false otherwise.
  ''
  '' Example: s2.write_line_threshold 'Write current line threshold value to EEPROM.

  return _ee_wrblock(@Line_thld, EE_LINE_THLD, 1)

PUB default_line_threshold

  '' Restore line threshold to default value. DOES NOT SAVE IN EEPROM.
  '' This method is optional unless read_line_threshold or set_line_threshold
  '' have been called successfully.
  '' Returns the default value.
  ''
  '' Example: s2.default_line_threshold 'Restore calibration default.

  return set_line_threshold(DEFAULT_LINE_THLD)

PUB set_line_threshold(thld)  

  '' Set line sensor threshold to thld.
  '' DOES NOT SAVE IN EEPROM. Returns the value set.
  ''
  '' Example: s2.set_line_threhsold(32) 'Set line sensor threshold to 32.
  ''
  '' This becomes the value used when the line_sensor method is called with an argument of zero.
  
  return Line_thld := thld

PUB get_line_threshold

  '' Returns the current line sensor threshold.
  ''
  '' Example: Thld := s2.get_line_threshold
  
  return Line_thld  
  
PUB line_sensor(side, threshold)

  '' If threshold => 0
  ''   Return the value of the line sensor on side (LEFT or RIGHT),
  ''   compared to the threshold. (If threshold is zero, substitute 40.)
  ''   Return: false == dark; true == light
  '' If threshold < 0
  ''   Return analog value of line sensor.
  ''
  '' Example: if (s2.line_sensor(s2#LEFT, 0)) 'IF block executed if left line sensor seeing default bright reflection.

  if (side == LEFT)
    result := word[results_addr][ADC_LEFT_LIN] >> 8
  elseif (side == RIGHT)
    result := word[results_addr][ADC_RIGHT_LIN] >> 8
  if (threshold == 0)
    result =>= Line_thld
  elseif (threshold > 0)
    result =>= threshold

PUB read_light_calibration | cal

  '' Read light calibration values from EEPROM, and use them if they're reasonable.
  '' Returns the calibration values (packed long) on success.
  '' If no valid calibration values exist in EEPROM, sets to (and returns)the
  '' default values.
  ''
  '' Example: s2.read_light_calibration 'Get previously-written light calibration values.

  if (_ee_rdblock(@cal, EE_LIGHT_CALIB, 3))
    return set_light_calibration(cal << 24 ~> 24, cal << 16 ~> 24, cal << 8 ~> 24)
  else
    return default_light_calibration

PUB write_light_calibration | cal

  '' Write current light calibration values to EEPROM.
  '' Returns true on a successful write; false otherwise.
  ''
  '' Example: s2.write_light_calibration 'Write current light calibration values to EEPROM.

  cal := get_light_calibration
  return _ee_wrblock(@cal, EE_LIGHT_CALIB, 3)

PUB default_light_calibration

  '' Restore light calibration to default values. DOES NOT SAVE IN EEPROM.
  '' This method is optional unless read_light_calibration or set_light_calibration
  '' have been called successfully.
  '' Returns a packed long containing the default values.
  ''
  '' Example: s2.default_light_calibration 'Restore calibration defaults.

  return set_light_calibration(DEFAULT_LIGHT_SCALE, DEFAULT_LIGHT_SCALE, DEFAULT_LIGHT_SCALE)

PUB set_light_calibration(left_scale, center_scale, right_scale) | i

  '' Set light calibration values to method's arguments (-128 to 127).
  '' DOES NOT SAVE IN EEPROM. Returns a packed long containing the new values.
  ''
  '' Example: s2.set_light_calibration(-5, 25, 0) 'Set left scale to -5,
  ''                                              'center scale to 25, and
  ''                                              'right scale to 0.
  ''
  '' Calibration values are signed and are added to the results of the light_sensor_log method.

  repeat i from 0 to 2
    Light_scale[i] := left_scale[i] #> -128 <# 127
  return get_light_calibration

PUB get_light_calibration

  '' Returns a packed long containing the current light calibration values:
  ''
  '''  31          24 23          16 15           8 7           0
  ''' ┌──────────────┬──────────────┬──────────────┬─────────────┐    
  ''' │       0      │  Right Scale │ Center Scale │  Left Scale │
  ''' └──────────────┴──────────────┴──────────────┴─────────────┘
  ''
  '' Example: CenterCal := (s2.get_light_calibration >> 8) & $ff
  
  return Light_Scale[0] | Light_Scale[1] << 8 | Light_Scale[2] << 16  
  
PUB light_sensor(side)

  '' Return the square root (0 .. 255) of the value of the light sensor on side (LEFT, CENTER, or RIGHT).
  '' The square-root-scaled value provides a wider dynamic range over a small numerical range than the
  '' raw values do.
  ''
  '' Example: if (s2.light_sensor(s2#LEFT) > s2.light_sensor(s2#RIGHT)) 'IF block executed if uncalibrated left is brighter than right.

  if ((result := light_sensor_word(side)) == UNDEF)
    return 0
  ^^result

PUB light_sensor_log(side) | wsense, lsense, ssense, mant, char

  '' Return a log-like function (0 .. 255) of the value of the light sensor on side (LEFT, CENTER, or RIGHT).
  '' The log-scaled value provides a wider dynamic range over a small numerical range than the
  '' raw values do and more sensitivity to change at lower light levels than the square-root funciton above.
  ''
  '' Example: if (s2.light_sensor_log(s2#LEFT) > s2.light_sensor_log(s2#RIGHT)) 'IF block executed if calibrated left is brighter than right.

  if ((wsense := light_sensor_word(side)) == UNDEF)
    return 0
  if ((char := >| wsense - 1) < 0)
    return 0
  lsense := wsense << (31 - char) >> 20
  mant := word[$C000 + (lsense & $7ff) << 1]
  lsense := (((char << 4 | mant >> 12) << 8) / 245) <# 255
  ssense := ^^(((wsense << 15) / 30000) <# $ffff)
  result := ((ssense * (255 - ssense) + lsense * ssense) / 255) + (Light_Scale[lookdownz(side : LEFT, CENTER, RIGHT)] << 24 ~> 24) #> 0 <# 255
     
PUB light_sensor_raw(side)

  '' Return the raw value (0 .. 4095) of the light sensor on side (LEFT, CENTER, or RIGHT).
  ''
  '' Example: if (s2.light_sensor_raw(s2#LEFT) > s2.light_sensor(s2#RIGHT)) 'IF block executed if left is brighter than right.

  if ((result := light_sensor_word(side)) == UNDEF)
    return 0
  result >>= 4

PUB light_sensor_word(side)

  if (side == LEFT)
    return word[results_addr][ADC_LEFT_LGT]
  elseif (side == CENTER)
    return word[results_addr][ADC_CENTER_LGT]
  elseif (side == RIGHT)
    return word[results_addr][ADC_RIGHT_LGT]
  else
    return UNDEF

PUB get_results(index)

  '' General accessor for ADC Results array: returns the full word value.
  ''
  '' Example: battery_level := s2.get_adc_results(s2#ADC_VBAT) 'Query the battery voltage and save in battery_level.

  return word[results_addr][index]

PUB get_adc_results(index)

  '' General accessor for ADC Results array: returns upper eight bits of word value.
  ''
  '' Example: battery_level := s2.get_adc_results(s2#ADC_VBAT) 'Query the battery voltage and save in battery_level.

  return word[results_addr][index] >> 8

''
''
''-------[ Button methods... ]-------------------------------------------------
''
'' Button methods control and sense the user's interaction with the S2's push button.
 
PUB button_press

  '' Return true if button is down, false if button is up.
  ''
  '' Example: if(s2.button_press) 'IF block executed if button is down.

  return ina[BUTTON] == 0

PUB button_count

  '' Get the last count of button presses (0 - 8). Then zero the count.
  ''
  '' Example: button_presses := s2.button_count 'Button_presses is set to the recent button press count, which is then zeroed.

  if(result := byte[results_addr][constant(BUTTON_CNT << 1)])
    byte[results_addr][constant(BUTTON_CNT << 1)]~

PUB reset_button_count

  '' Return the reset button count (0- 8). Zero indicates a power-on or PC-initiated reset.
  ''
  '' Example: reset_button_presses := s2.reset_button_count 'Reset_button_presses is set to the button press count that caused the reset.

  return Reset_count       

PUB button_mode(led_enable, reset_enable)

  '' Set button LED and reset modes:
  ''
  '' led_enable == TRUE: Take over LEDs to echo button press number.
  ''
  '' reset_enable == TRUE: Record number of presses in EEPROM (up to 8),
  ''                       and reset Propeller after 1 second of no presses.
  ''
  '' Example: s2.button_mode(TRUE, FALSE) 'Set the button mode, enabling the LED indicator, but disabling resets.

  byte[results_addr][constant((BUTTON_CNT << 1) + 1)] := LED_ENA & (led_enable <> 0) | RST_ENA & (reset_enable <> 0)

''
''
''-------[ LED methods... ]----------------------------------------------------
''
'' LED methods control the red/green user LEDs and blue power LED.
 
PUB set_leds(left_color, center_color, right_color, power_color)

  '' Sets all LEDs for which the color argument <> NO_CHANGE (-1).
  '' See the above constants for predefined indices and colors.
  ''
  '' Example: s2.set_leds(s2#RED, s2#NO_CHANGE, s2#BLINK_GREEN, s2#OFF) 'Set LEDs (L to R): RED, same, blinking GREEN, off.

  if (left_color <> NO_CHANGE)
    set_led(LEFT, left_color)
  if (center_color <> NO_CHANGE)
    set_led(CENTER, center_color)
  if (right_color <> NO_CHANGE)
    set_led(RIGHT, right_color)
  if (power_color <> NO_CHANGE)
    set_led(POWER, power_color)

PUB set_led(index, color) | shift

  '' Light up a user LED using color value as follows:

  '' Index = 0 or 4:Power, 1:Left, 2:Right, 3:Center
  '' Color:  
  ''' ┌───┬───┬───┬───┬───┬───┬───┬───┐
  ''' │      Red      │     Green     │
  ''' └───┴───┴───┴───┴───┴───┴───┴───┘
  '''   7   6   5   4   3   2   1   0
  ''
  '' Each nybble represents the intensity (0-15) of the
  '' chosen color. If Red + Green =< 15, the colors are blended.
  '' If red + green => 15, they're alternated at about 2 Hz.
  '' An intensity value of 1 is the same as 0. This allows blinking
  '' a single color, e.g. $1f or $f1.
  '' The power LED lights blue whenever red > 0.
  '' See the above constants for predefined indices and colors.
  ''
  '' Example: s2.set_led(s2#CENTER, s2#YELLOW) 'Set center LED to yellow.

  byte[results_addr + (LED_BYTES << 1) + (index & 3)] := color 
}
''
''
''-------[ Sound methods... ]--------------------------------------------------
''
'' Sound methods control the output from the S2's built-in speaker.
 
PUB beep

  '' Set volume level to 50%, and send a 150ms 1 KHz tone, followed by a 350ms pause.
  ''
  '' Example: s2.beep 'Make the speaker beep.

  set_volume(50)
  set_voices(SIN, SIN)
  play_tone(150, 1000, 0)
  return play_tone(350, 0, 0)

PUB command_tone(cmd_tone)

'' Send an immediate command (cmd_tone) to the sound cog:
''
''   STOP:  Stops sound production immediately, then clears the sound queue.
''   PAUSE: Pauses sound production after the note currently being played.
''   PLAY:  Resumes sound production from the queue.
''
'' Example: s2.command_tone(STOP) 'Cause sounds to cease immediately.

  case cmd_tone
    STOP, PAUSE, PLAY:
      Tone_cmd := cmd_tone
      repeat while Tone_cmd
      if (cmd_tone == STOP)
        Tone_enq_ptr := Tone_deq_ptr        

PUB set_volume(vol)

  '' Set the current volume level to vol (0 - 100) percent.
  ''
  '' Example: s2.set_volume(50) 'Set volume level to 50%.

  return _enqueue_tone(constant(VOLU << 13) | ((vol #> 0 <# 100) * $1fff / 100))

PUB set_voices(v1, v2)

  '' Set voices for both channels (SQU, SAW, TRI, SIN)
  ''
  '' Example: s2.set_voices(s2#SIN, s2#TRI) 'Set voice 1 to sine wave; voice 2 to triangle wave.

  Tone_voice1 := v1 & 3
  Tone_voice2 := v2 & 3

PUB play_sync(value)

  '' Insert a SYNC command into the sound queue.
  '' When the sound processor encounters it, it writes value (0 - 255) to
  '' the hub variable Tone_sync, then continues. This method can be used to
  '' synchronize motion to the sound being played.
  ''
  '' Example: s2.play_sync(12)    'Insert a SYNC 12 into the tone queue.
  ''                              'When encountered during play, player will set the sync value to 12
  ''                              '(for get_sync) and continue with the next command.
  
  return _enqueue_tone(constant(SYNC << 13) | value & $ff)

PUB play_pause(value)

  '' Insert a PAUS command into the sound queue.
  '' When the sound processor encounters it, it writes value (0 - 255) to
  '' the hub variable Tone_sync, then pauses.
  ''
  '' Example: s2.play_pause(12)   'Insert a PAUS 12 into the tone queue.
  ''                              'When encountered during play, player will set the sync value to 12
  ''                              '(for get_sync) and wait for a PLAY command to resume.

    return _enqueue_tone(constant(PAUS << 13) | value & $ff)

PUB get_sync

  '' Get the current Tone_sync value.
  ''
  '' Example: current_sync := s2.get_sync 'Get the latest sync value written from tone queue while playing,
  ''                                      'then zero the value if it was non-zero.
  
  if (result := Tone_sync)
    Tone_sync~
      
PUB play_tone(time, frq1, frq2)

  '' Send sound to speaker, mixing frq1 & frq2 (1 - 10000 Hz),
  '' using current voices and volume for time (0 - 8191 milliseconds).
  ''
  '' Example: s2.play_tone(1000, 440, 880) 'Play an A440 and A880 for 1000 milliseconds.

  ifnot (time)
    return false
  _enqueue_tone(time & $1fff)
  _enqueue_tone(Tone_voice1 << 14 | frq1 & $3fff)
  return _enqueue_tone(Tone_voice2 << 14 | frq2 & $3fff)

PUB play_tones(addr)

  '' Add a command sequence to the tone queue. Commands are of the
  '' following format:
  ''
  ''' 15  13 12                      0
  ''' ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
  ''' │ Cmd │          Data           │
  ''' └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
  ''
  '' Cmd: %000
  ''
  ''   Play tone for duration Data (0 - 8192ms),using the following TWO words as
  ''   the voices, each having the following format:
  ''
  '''    15 14 13                        0
  '''     ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐
  '''     │Voc│         Frequency         │
  '''     └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘
  ''
  ''      Voc (voice):
  ''
  ''        00 = square wave
  ''        01 = sawtooth wave
  ''        10 = triangle wave
  ''        11 = sine wave
  ''
  ''     Frequency : 0 (no sound) to 16363 Hz.
  ''
  '' Cmd: %001
  ''
  ''   Set volume to Data << 3 (range 0 - 0.9998)
  ''
  '' Cmd: %010
  ''
  ''   Set sync to Data & $ff
  ''
  '' Cmd: %011
  ''
  ''   Set sync to Data & $ff, then PAUSE.
  ''
  '' Example: s2.play_tones(@tone_buffer) 'Add tones from tone_buffer (word array) to tone queue until a zero word is encountered.         

  repeat while word[addr]
    result := _enqueue_tone(word[addr])
    addr += 2
   
PUB wait_sync(value)

  '' Wait for sync in queue to echo (value <> 0) or for queue to become empty (value == 0).
  ''
  '' Example: s2.wait_sync(12) 'Wait until a sync value of 12 is returned from the tone queue.

  if (Tone_cog)
    if (value)
      repeat until Tone_sync == value
    else
      repeat until Tone_deq_ptr == Tone_enq_ptr
{
''
''
''-------[ Time methods... ]---------------------------------------------------
''
'' Time methods control and sense the S2's built-in millisecond timers and provide
'' a convenient delay function.
 
PUB start_timer(number)

  '' Start a 1 KHz count-up timer number (0 - 7), which counts up from zero
  '' by one every millisecond.
  ''
  '' Example: s2.start_timer(4) 'Restarts timer number four from zero.

  if (number => 0 and number < 8) 
    Timers[number] := long[results_addr + constant(TIMER >> 1)]

PUB get_timer(number)

  '' Return the time (in milliseconds, up to 2 million seconds ~ 24 days) from the 1 KHz count-up timer number (0 - 7).
  '' If number is outside the range 0 - 7, return the value of the master timer, which starts at 0 when s2 is started.
  ''
  '' Example: elapsed_time := s2.get_timer(4) 'Get time elapsed since Propeller reset or timer restart.

  return long[results_addr + constant(TIMER << 1)] - (Timers[number] & (number => 0 and number < 8))

PUB delay_tenths(time) | time0

  '' Time delay in tenths of a second.
  ''
  '' Example: s2.delay_tenths(20) 'Wait a couple seconds.

  time0 := cnt
  repeat time
    waitcnt(time0 += clkfreq / 10)

''
''
''-------[ EEPROM methods... ]-------------------------------------------------
''
'' EEPROM methods allow read/write access to the auxilliary 32Kbyte EEPROM.
 
PUB ee_read_byte(addr)

  '' Read byte from aux EEPROM at addr.
  ''
  '' Example: my_data := s2.ee_read_byte($2000) 'Set my_data equal to byte at location $2000 in auxilliary EEPROM.

  return _ee_rdbyte(addr)

PUB ee_write_byte(addr, data)

  '' Write byte to aux EEPROM at addr, if addr is in user area.
  ''
  '' Example: s2.ee_write_byte(s2#EE_USER_AREA + 5, 35) 'Write the value 35 to the sixth byte in the auxilliary EEPROM's user area.

  if (addr => EE_USER_AREA)
    _ee_wrbyte(addr, data)
    return true
  else
    return false

''
''
''=======[ Private Spin methods... ]==============================================
''
'' These private methods are used internally and are not accessible to the user.
''
''-------[ Miscellaneous... ]--------------------------------------------------

PRI _compute_calibration

  '' Compute other values dependent on Full_circle to save time in methods.

  Half_circle := Full_circle >> 1
  Qtr_circle := Full_circle >> 2
  Atan_circle := Full_circle * 56841 / 100000
 
PRI _atan2(y, x) | arg, adder, n

  '' Four-quadrant arctangent. Y and X are signed integers.
  '' Full_circle is an integer equal to the number of units in a full circle.

  if ((n := >|(||x <# ||y)) > 21)
    x ~>= n - 21
    y ~>= n - 21 
  if (||x > ||y)                      
    arg := y << 10 / x 
    adder := (Half_circle) & (x < 0)
  else
    arg := -x << 10 / y
    adder := Qtr_circle + Half_circle & (y < 0)
  result := (||arg * Atan_circle / (914 + (arg * arg) >> 12) + 1) >> 2 - (||arg => 960)
  if (arg < 0)
    - result 
  result += adder
  result += Full_circle & (result < 0)     
}                                         
PRI _enqueue_tone(tone_word) | next_ptr

  '' Wait for tone queue to become non-full,
  '' then add tone_word to it.

  if (Tone_cog)
    next_ptr := Tone_enq_ptr + 1
    next_ptr &= (next_ptr < _TONE_Q_SIZE)
    repeat until Tone_deq_ptr <> next_ptr
    Tone_queue[Tone_enq_ptr] := tone_word
    Tone_enq_ptr := next_ptr
    return Tone_enq_ptr << 16 | Tone_deq_ptr
     
''-------[ I2C Methods... ]----------------------------------------------------
{
PRI _ee_rdblock(dest_addr, addr, size) | i, csum 

  csum := _ee_rdbyte(addr + size)
  repeat i from 0 to size - 1
    csum += (byte[dest_addr][i] := _ee_rdbyte(addr + i))
  return csum & $ff == 0

PRI _ee_wrblock(src_addr, addr, size) | i, data, csum

  csum~
  result~~
  repeat i from 0 to size - 1
    data := byte[src_addr][i]
    csum -= data
    result &= _ee_wrbyte(addr + i, data)
  result &= _ee_wrbyte(addr + size, csum & $ff)     

PRI _ee_rdbyte(addr)

  _i2c_waddr(addr)
  _i2c_start
  _i2c_wr(%1010_001_1)
  result := _i2c_rd(NAK)
  _i2c_stop

PRI _ee_wrbyte(addr, data)

  _i2c_waddr(addr)
  result := _i2c_wr(data)
  _i2c_stop

PRI _i2c_waddr(addr)

  repeat
    _i2c_start
  until _i2c_wr(%1010_001_0)
  _i2c_wr(addr >> 8)
  _i2c_wr(addr & $ff)

PRI _i2c_rd(acknak)

  repeat 8
    outa[SCL]~~
    result := result << 1 | ina[SDA]
    outa[SCL]~
  dira[SDA] := acknak <> 0
  outa[SCL]~~
  outa[SCL]~
  dira[SDA]~

PRI _i2c_wr(data)

  repeat 8
    dira[SDA] := (data <<= 1) & $100 == 0
    outa[SCL]~~
    outa[SCL]~
  dira[SDA]~
  outa[SCL]~~
  result := ina[SDA] == 0
  outa[SCL]~

PRI _i2c_start

  dira[SDA]~
  outa[SCL]~~
  dira[SDA]~~
  outa[SCL]~

PRI _i2c_stop

  outa[SCL]~
  dira[SDA]~~
  outa[SCL]~~
  dira[SDA]~
 }
''=======[ Assembly Cogs... ]==================================================
  
DAT

''-------[ Tone Player ]-------------------------------------------------------

              org       0
              
tone_seq      mov       ctra,tctra0             'Initialize counter for DUTY mode.
              mov       tacc,queue_addr
              add       tacc,queue_size
              add       tacc,queue_size
              mov       enq_ptr_addr,tacc
              add       tacc,#2
              mov       deq_ptr_addr,tacc
              add       tacc,#2
              mov       cmd_addr,tacc
              add       tacc,#1
              mov       sync_addr,tacc
              mov       ttime,cnt
              add       ttime,dttime

:get_cmd      call      #dequeue                'Get the next word from queue.
              mov       cmd,tacc                'Copy word to command.
              and       tacc,data_bits          'Isolate the 13 data bits.
              shr       cmd,#13 wz              'Isolate command bits. Is command == TONE?
        if_z  jmp       #:tone                  '  Yes: Go make some noise. 

              cmp       cmd,#VOLU wz            'Is command a set volume?
        if_nz jmp       #:try_sync

              shl       tacc,#3                 '  Yes: Normalize the volume value,
              mov       volume,tacc             '         and save it.
              jmp       #:get_cmd               '       Back for anohter command.

:try_sync     cmp       cmd,#SYNC wz            'Is command a sync?            
        if_z  jmp       #:do_sync               '  Yes: go do it.

              cmp       cmd,#PAUS wz            'Is command a pause-and-sync?
        if_nz jmp       #:get_cmd               '  No:  Invalid command; just skip it.

              mov       playing,#0              '  Yes: Stop playing.
:do_sync      wrbyte    tacc,sync_addr          '       Copy the sync value back to hub variable.
              jmp       #:get_cmd               '       Back for another command.              

:tone         mov       duration,tacc           'Multiply duration by 65 to get
              shl       tacc,#6                 '  approx milliseconds (within 1%)
              add       duration,tacc
              shr       duration,#1

              call      #dequeue                'Get the freq1 value.
              mov       freq1,tacc
              shl       freq1,#18 wz            'Isolate the frequency part.
              shr       freq1,#1                'Is it zero?
        if_z  mov       phase1,#0               '  Yes: Zero the phase, too.
              mov       voice1,tacc             'Isolate the voice part.
              shr       voice1,#14              
              call      #dequeue                'Get the freq2 value and process the same.
              mov       freq2,tacc
              shl       freq2,#18 wz
              shr       freq2,#1
        if_z  mov       phase2,#0
              mov       voice2,tacc
              shr       voice2,#14
              or        dira,tdira0

:tone_lp      rdbyte    tacc,cmd_addr           'Tone generation: first check for a STOP.
              cmp       tacc,#STOP wz           'Is it a STOP?
        if_z  jmp       #:get_cmd               '  Yes: Quit, and let dequeue handle it.
        
              add       phase1,freq1            'Tone generation: Increment the phases.
              add       phase2,freq2

              mov       phase,phase1            'Get the first phase and voice.
              mov       voice,voice1
              call      #get_amp                'Compute current amplitude.
              mov       amp,tacc                'Copy amplitude to amp.
              mov       phase,phase2            'Get the second phase and voice.
              mov       voice,voice2            
              call      #get_amp                'Compute the current amplitude.
              add       amp,tacc                'Add to the first amplitude.
              abs       tacc,amp                'Multiply the instantenous abs amplitude by the volume.
              mov       taccx,volume
              call      #fmult
              shl       amp,#1 wc               'Get the original sign of amp in carry.
              mov       amp,amp0                'Zero level is Vdd/2.
              sumc      amp,tacc                'Fix the sign and add to zero level.
              waitcnt   ttime,dttime            'Wait for sample interval.
              mov       frqa,amp                'Output the amplitude to DUTY-mode counter.
              djnz      duration,#:tone_lp      'Count down the duration and repeat.

              jmp       #:get_cmd               'Get the next command.

'-------[ Compute the instantaneous amplitude for one component. ]-------------              
              
get_amp       test      voice,#2 wc             'Test for waveform type.
              test      voice,#1 wz
        if_c  jmp       #:tri_sin               'Jump to appropriate sections based on waveform.
        
        if_nz jmp       #:saw

:squ          shl       phase,#1 wc,nr          'Square wave: Test sign bit of phase.
              negc      tacc,maxamp             'Add or subtract max based on sign
              jmp       get_amp_ret             'Return.
              
:saw          mov       tacc,phase              'Sawtooth wave: Get the phase.
              add       tacc,amp0               'Convert to signed.
              sar       tacc,#1                 'Signed divide by two.
              jmp       get_amp_ret             'Return.

:tri_sin
        if_nz jmp       #:sin

:tri          abs       tacc,phase              'Triangle wave: Get abs value.
              sub       tacc,maxamp               'Convert to pos and neg values.
              jmp       get_amp_ret             'Return.

:sin          shr       phase,#32-13            'Get 13-bit angle.
              test      phase,_0x1000 wz        'Get sine quadrant 3|4 into nz.
              test      phase,_0x0800 wc        'Get sine quadrant 2|4 into c.
              negc      phase,phase             'If sine quadrant 2|4, negate table offset.
              or        phase,_0x7000           'Insert sine table base address >> 1.
              shl       phase,#1                'Shift left to get final word address.
              rdword    tacc,phase              'Read sine word from table.
              negnz     tacc,tacc               'If quadrant 3|4, negate word.
              shl       tacc,#14                'Msb-justify result.
get_amp_ret   ret
              

'-------[ Dequeue next word in sequence. ]-------------------------------------

dequeue       rdbyte    tacc,cmd_addr           'Check for an immediate command first.
              cmp       tacc,#PAUSE wz          'Is it a PAUSE?
        if_nz cmp       tacc,#STOP wz           '  No:  Is it a STOP?
        if_z  mov       playing,#0              '  Yes:   Yes: Clear Playing flag.
        if_z  jmp       #:zapcmd                '              Go clear command.
        
              cmp       tacc,#PLAY wz           '         No:  Is it a PLAY?
        if_z  mov       playing,#1              '                Yes: Set playing flag.
:zapcmd if_z  wrbyte    zero,cmd_addr           '       Clear the command.

              test      playing,playing wz      'Are we playing something?
        if_z  jmp       #:decay                 '  No:  Go decay frqa for shutdown.
        
              rdword    enq_ptr,enq_ptr_addr    '  Yes: Get the queue pointers.
              rdword    deq_ptr,deq_ptr_addr
              cmp       enq_ptr,deq_ptr wz      '       Is the queue empty?
        if_nz jmp       #:get_it                 '         No:  Go get some data.
        
:decay        cmpsub    frqa,#511 wc            'Decay the output while waiting,
        if_nc andn      dira,tdira0             '  until it can be turned off without popping.
              mov       ttime,cnt               'Reinitialize ttime, so it's always current.
              add       ttime,dttime
              jmp       #dequeue                'Go check for a new command or data.

:get_it       shl       deq_ptr,#1
              add       deq_ptr,queue_addr      'Convert deq_ptr to an address.
              rdword    tacc,deq_ptr            'Get the data at the address.
              sub       deq_ptr,queue_addr      'Convert deq_ptr back to an index.
              shr       deq_ptr,#1
              add       deq_ptr,#1              'Bump the pointer by one word.
              cmpsub    deq_ptr,queue_size      'Return pointer to zero if over the end.
              wrword    deq_ptr,deq_ptr_addr    'Write the deq pointer back to hub.
dequeue_ret   ret                               'Return with new data.
       

'-------[ Fixed point multiply. ]----------------------------------------------

'    32 x 16.16 fixed-point unsigned multiply.

'    in:      tacc = 32-bit integer multiplicand
'             taccx = 32-bit fixed-point multiplier
              
'    out:     tacc = 32-bit product

fmult         mov       t0,#0                   'Initialize high long of product.
              mov       t1,#32                  'Need 32 adds and shifts.
              shr       tacc,#1 wc              'Seed the first carry.

:loop   if_c  add       t0,taccx wc             'If multiplier was a one bit, add multiplicand.
              rcr       t0,#1 wc                'Shift carry and 64-bit product right.
              rcr       tacc,#1 wc
              djnz      t1,#:loop               'Back for another bit.

              shr       tacc,#16                'Fractional product is middle 32 bits of the 64.
              shl       t0,#16
              or        tacc,t0
fmult_ret     ret

'-------[ Constants and hub-assigned parameters ]------------------------------

dttime        long      0-0
queue_addr    long      0-0
tctra0        long      %00110 << 26 | SPEAKER
tdira0        long      1 << SPEAKER
zero          long      0
amp0          long      $8000_0000
maxamp        long      $3fff_ffff
data_bits     long      $1fff
_0x1000       long      $1000
_0x0800       long      $0800
_0x7000       long      $7000
volume        long      $8000
playing       long      0
queue_size    long      _TONE_Q_SIZE

'-------[ Variables ]----------------------------------------------------------

enq_ptr_addr  res       1
deq_ptr_addr  res       1
cmd_addr      res       1
sync_addr     res       1
enq_ptr       res       1
deq_ptr       res       1
phase1        res       1
phase2        res       1
phase         res       1
freq1         res       1
freq2         res       1
voice1        res       1
voice2        res       1
voice         res       1
duration      res       1
ttime         res       1
amp           res       1
cmd           res       1
tacc          res       1
taccx         res       1
t0            res       1
t1            res       1

              fit
DAT


DAT


'=======[ Default ADC sequence ]===============================================

'Sequence array format. Values can be changed in real time if external.

'MUX addr[4] | Result index[4] | Soak time [4] | Filter[3] | Scale[1]

'MUX addr is the address of the MUX input (0 - 15).
'Actual soak time is 1 << value, in microseconds.
'Actual filter time constant is 1 << value, in milliseconds.
'Scale is 0 for 3.3V ref; 1 for 5V ref.

{Adc_sequence  word      _VSS|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _VDD|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _5V |_SOAK_1us|_LPF_64ms|_REF_5V0
              word      _5V_DIV|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _VBAT|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _VTRIP|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _IDD|_SOAK_1us|_LPF_64ms|_REF_5V0
              word      _IMOT|_SOAK_1us|_LPF_4ms|_REF_3V3
              word      _IDLER|_SOAK_64us|_LPF_4ms|_REF_3V3
              word      _RIGHT_LGT|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _CENTER_LGT|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _LEFT_LGT|_SOAK_1us|_LPF_64ms|_REF_3V3
              word      _RIGHT_LIN|_SOAK_64us|_LPF_4ms|_REF_3V3
              word      _LEFT_LIN|_SOAK_64us|_LPF_4ms|_REF_3V3
              word      _P6|_SOAK_16us|_LPF_4ms|_REF_5V0
              word      _P7|_SOAK_16us|_LPF_4ms|_REF_5V0
              word      0

'=======[ Hub variables ]======================================================

Timers        long      0[8]
Envelope      long      0
Current_x     long      0-0
Current_y     long      0-0
Current_w     long      0-0
Stall_hyst    long      0
Full_circle   word      DEFAULT_FULL_CIRCLE
Wheel_space   word      DEFAULT_WHEEL_SPACE
Half_circle   word      DEFAULT_FULL_CIRCLE / 2
Qtr_circle    word      DEFAULT_FULL_CIRCLE / 4
Atan_circle   long      DEFAULT_FULL_CIRCLE * 56841 / 100000
Light_scale   byte      DEFAULT_LIGHT_SCALE[3]
Line_thld     byte      DEFAULT_LINE_THLD
Obstacle_thld byte      DEFAULT_OBSTACLE_THLD
_filler       byte      0[3]
Motor_cmd     word      0                       ' ┐
Motor_time    word      0                       ' │
Motor_Rdist   word      0                       ' ├─ Must begin on a long boundary and be contiguous in this order.
Motor_Ldist   word      0                       ' │
Motor_stat    long      0[6]                    ' ┘
Path_Rdist    long      0
Path_Ldist    long      0
Path_time     long      0
Path_max_spd  long      0  }
Results       word      0[24]                   'Must begin on a long boundary.
Tone_queue    word      0[_TONE_Q_SIZE]         ' ┐
Tone_enq_ptr  word      0                       ' │
Tone_deq_ptr  word      0                       ' │
Tone_cmd      byte      0                       ' ├─ Must be contiguous and in this order.
Tone_sync     byte      0                       ' │
Tone_voice1   byte      0                       ' │
Tone_voice2   byte      0                       ' ┘
In_path       byte      0

Adc_cog       byte      0
Tone_cog      byte      0
Mic_cog       byte      0
Motor_cog     byte      0
Reset_count   byte      0
Current_spd   byte      0


''=======[ License ]===========================================================
{{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                            TERMS OF USE: MIT License                                 │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │
│                                                                                      │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  │
│OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}


              