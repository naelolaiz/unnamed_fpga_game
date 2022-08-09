library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.VgaUtils.all;
use work.definitions.all;

entity top_level_vga_test is
  port (
    clk   : in std_logic; -- Pin 23, 50MHz from the onboard oscilator.
    rgb   : out std_logic_vector (2 downto 0); -- Pins 106, 105 and 104
    hsync : out std_logic; -- Pin 101
    vsync : out std_logic -- Pin 103
  );
end entity top_level_vga_test;

architecture rtl of top_level_vga_test is
  constant SQUARE_SIZE  : integer := 30; -- In pixels
  constant SQUARE_SPEED : integer := 100_000;

  -- VGA Clock - 25 MHz clock derived from the 50MHz built-in clock
  signal vga_clk : std_logic;

  signal rgb_input, rgb_output : std_logic_vector(2 downto 0);
  signal rgb_square_color : std_logic_vector (2 downto 0) := COLOR_YELLOW;
  signal vga_hsync, vga_vsync  : std_logic;
  signal hpos, vpos            : integer;

  signal square_x           : integer range HDATA_BEGIN to HDATA_END := HDATA_BEGIN + H_HALF - SQUARE_SIZE/2;
  signal square_y           : integer range VDATA_BEGIN to VDATA_END := VDATA_BEGIN + V_HALF - SQUARE_SIZE/2;

  signal cursorPosition      : Pos2D;
  signal hPosVector, vPosVector : std_logic_vector(15 downto 0) := (others => '0');
  signal spritePosition      : Pos2D;

  signal square_speed_count : integer range 0 to SQUARE_SPEED        := 0;
  signal should_move_square : boolean;
  signal should_draw_square1 : boolean;
  signal should_draw_square2 : boolean;

  -- nael
  signal counterForSpritePositionUpdate : integer range 0 to 180E3  := 0;
  signal ticksForSpritePositionUpdate : std_logic := '0';
  signal ticksForDynamicTextPositionUpdate : std_logic := '0';
  signal xPosSprite, yPosSprite : integer := 0;
  signal xPosNael, yPosNael : integer := 5;
  signal xDirectionSprite, yDirectionSprite : boolean := true; 
  signal xDirectionText, yDirectionText : boolean := true; 

  signal sRotation : AngleType := (others=>'0');
  signal sRotationClockwise : boolean := true;
  signal sCounterForRotationChange : integer range 0 to 85E6:= 0;
  signal sSmiley1Enabled : boolean := true;

  component VgaController is
    port (
      clk     : in std_logic;
      rgb_in  : in std_logic_vector (2 downto 0);
      rgb_out : out std_logic_vector (2 downto 0);
      hsync   : out std_logic;
      vsync   : out std_logic;
      hpos    : out integer;
      vpos    : out integer
    );
  end component;
begin

cursorPosition <= (hpos, vpos);
spritePosition <= (square_x, square_y);

TickProcess : process (clk)
begin
    if (rising_edge(clk)) then
       if counterForSpritePositionUpdate = counterForSpritePositionUpdate'HIGH then
          counterForSpritePositionUpdate <= 0;
	  ticksForSpritePositionUpdate <= not ticksForSpritePositionUpdate;
       else
          counterForSpritePositionUpdate <= counterForSpritePositionUpdate + 1;
       end if;
    end if;
end process;

rotateSprite : process  (clk, sRotationClockwise)
variable counterForSpriteRotationUpdate : integer range 0 to 10E6 := 0;
variable indexForSpriteRotation : integer range 0 to TRIGONOMETRIC_FUNCTIONS_TABLE'LENGTH-1;
begin
    if rising_edge(clk) then
       if counterForSpriteRotationUpdate = counterForSpriteRotationUpdate'HIGH then
          counterForSpriteRotationUpdate := 0;
          if sRotationClockwise then
              if indexForSpriteRotation = indexForSpriteRotation'HIGH-1 then
                 indexForSpriteRotation := 0;
                 sRotation <= TRIGONOMETRIC_FUNCTIONS_TABLE(indexForSpriteRotation).angle;
              else
                 indexForSpriteRotation := indexForSpriteRotation + 1;
              end if;
          else
              if indexForSpriteRotation = 1 then
                 indexForSpriteRotation := indexForSpriteRotation'HIGH;
                 sRotation <= TRIGONOMETRIC_FUNCTIONS_TABLE(indexForSpriteRotation).angle;
              else
                 indexForSpriteRotation := indexForSpriteRotation - 1;
              end if;
          end if;
       else
          counterForSpriteRotationUpdate := counterForSpriteRotationUpdate + 1;
       end if;

       if sCounterForRotationChange = sCounterForRotationChange'HIGH then
          sCounterForRotationChange <= 0;
          sRotationClockwise <= not sRotationClockwise;
          sSmiley1Enabled <= not sSmiley1Enabled;
       else
          sCounterForRotationChange <= sCounterForRotationChange + 1;
       end if;
    end if;
end process;

moveSprite : process (ticksForSpritePositionUpdate)
begin
   if rising_edge(ticksForSpritePositionUpdate) then
      if xDirectionSprite then
         if xPosSprite = HDATA_END - SQUARE_SIZE then
	    xDirectionSprite <= not xDirectionSprite;
	    rgb_square_color <= rgb_square_color(1 downto 0) & rgb_square_color(2);
	 else
	    xPosSprite <= xPosSprite + 1;
	 end if;
      else
         if xPosSprite = HDATA_BEGIN then -- 300 then --HDATA_BEGIN + HSYNC_END then
	    xDirectionSprite <= not xDirectionSprite;
	    rgb_square_color <= rgb_square_color(0) & rgb_square_color(2 downto 1);
	 else
	    xPosSprite <= xPosSprite - 1;
	 end if;
      end if;
      if yDirectionSprite then
         if yPosSprite = VDATA_END - SQUARE_SIZE - 30 then
	    -- yPosSprite <= 220;
	    yDirectionSprite <= not yDirectionSprite;
	    rgb_square_color <= rgb_square_color(2) & rgb_square_color(0) & rgb_square_color(1);
	 else
	    yPosSprite <= yPosSprite + 1;
	 end if;
      else
         if yPosSprite = VDATA_BEGIN then
	    -- yPosSprite <= 360;
	    yDirectionSprite <= not yDirectionSprite;
	    rgb_square_color <= rgb_square_color(1) & rgb_square_color(2) & rgb_square_color(0);
	 else
	    yPosSprite <= yPosSprite - 1;
	 end if;
      end if;
      should_move_square <= true;
   else
      should_move_square <= false;
   end if;
end process;

mySprite : entity work.sprite(logic)
generic map(SPRITE_WIDTH => 11,
            SCALE => 16,
            SPRITE_CONTENT => "00011111000"
                             &"00100000100"
                             &"01000000010"
                             &"10010001001"
                             &"10000000001"
                             &"10000100001"
                             &"10100000101"
                             &"10010001001"
                             &"01001110010"
                             &"00100000100"
                             &"00011111000")
port map (inClock       => vga_clk,
          inEnabled     => true,
          inSpritePos   => spritePosition,
          inCursorPos   => cursorPosition,
          outShouldDraw => should_draw_square1,
          inRotation => sRotation);

mySprite2 : entity work.sprite(logic)
generic map(SPRITE_WIDTH => 11,
            SCALE => 16,
            SPRITE_CONTENT => "00011111000"
                             &"00100000100"
                             &"01000000010"
                             &"10010001001"
                             &"10000100001"
                             &"10000000001"
                             &"10011111001"
                             &"10100000101"
                             &"01000000010"
                             &"00100000100"
                             &"00011111000")
           --  SPRITE_CONTENT => "00011111000"
           --                   &"00100000100"
           --                   &"01000000010"
           --                   &"10010001001"
           --                   &"10000100001"
           --                   &"10000000001"
           --                   &"10001110001"
           --                   &"10010001001"
           --                   &"01001110010"
           --                   &"00100000100"
           --                   &"00011111000")
port map (inClock       => vga_clk,
          inEnabled     => not sSmiley1Enabled,
          inSpritePos   => spritePosition,
          inCursorPos   => cursorPosition,
          outShouldDraw => should_draw_square2,
          inRotation => sRotation);
square_x <= xPosSprite;
square_y <= yPosSprite;

  controller : VgaController port map(
    clk     => vga_clk,
    rgb_in  => rgb_input,
    rgb_out => rgb_output,
    hsync   => vga_hsync,
    vsync   => vga_vsync,
    hpos    => hpos,
    vpos    => vpos
  );

  rgb   <= rgb_output;
  hsync <= vga_hsync;
  vsync <= vga_vsync;

  -- We need 25MHz for the VGA so we divide the input clock by 2
  process (clk)
  begin
    if (rising_edge(clk)) then
      vga_clk <= not vga_clk;
    end if;
  end process;

  process (vga_clk, should_draw_square1, should_draw_square2)
  variable tempColorSum : std_logic_vector(2 downto 0) := "000";
  begin
    if rising_edge(vga_clk) then
      tempColorSum := "000";
      if should_draw_square1 then
        tempColorSum := "010";
      end if;
      if should_draw_square2 then
        tempColorSum := tempColorSum or "001";
      end if;
    end if;
    rgb_input <= tempColorSum; 
  end process;

end architecture;
