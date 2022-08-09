library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.definitions.all;

entity sprite is
   generic (SPRITE_WIDTH   : integer := 7;
            SCALE          : integer := 3;
            SPRITE_CONTENT : std_logic_vector := "1001001"
                                               & "0101010"
                                               & "0011100"
                                               & "1111111"
                                               & "0011100"
                                               & "0101010"
                                               & "1001001";
            INITIAL_ROTATION         : AngleType := (others=>'0');
            ROTATION_UPDATE_PERIOD   : integer := 0 -- rotation speed: counter for input clock to increase angle. Zero for static. Negative for counterclockwise.
            );
   port( inClock : in  std_logic;
         inEnabled : in boolean;
         inSpritePos   : Pos2D; -- center position of sprite
         inCursorPos   : Pos2D; -- position to check
         --inRotation    : in AngleType;
         outShouldDraw : out boolean);
end;

architecture logic of sprite is
   constant SPRITE_SIZE          : Size2D := (SPRITE_WIDTH, SPRITE_CONTENT'length / SPRITE_WIDTH);
   type SPRITE_CONTENT_TYPE is array (SPRITE_SIZE.height-1 downto 0) of std_logic_vector (SPRITE_SIZE.width-1 downto 0);

   signal sSpriteContent  : SPRITE_CONTENT_TYPE;
   signal sCenterPos : Pos2D := (0,0);
   constant C_HALF_SCALED_WIDTH  : integer := SPRITE_SIZE.width * SCALE / 2;
   constant C_HALF_SCALED_HEIGHT : integer := SPRITE_SIZE.height * SCALE / 2;

   signal sRotation : AngleType := INITIAL_ROTATION;

begin

   rotateSprite : process  (inClock)
   variable counterForSpriteRotationUpdate : integer range 0 to ROTATION_UPDATE_PERIOD := 0;
   variable indexForSpriteRotation : integer range 0 to TRIGONOMETRIC_FUNCTIONS_TABLE'LENGTH-1;
   begin
       if rising_edge(inClock) then
          if counterForSpriteRotationUpdate = counterForSpriteRotationUpdate'HIGH then
             counterForSpriteRotationUpdate := 0;
             if ROTATION_UPDATE_PERIOD < 0 then -- counterclockwise
                 if indexForSpriteRotation = indexForSpriteRotation'HIGH then
                    indexForSpriteRotation := 0;
                 else
                    indexForSpriteRotation := indexForSpriteRotation + 1;
                 end if;
             elsif ROTATION_UPDATE_PERIOD > 0 then -- clockwise
                 if indexForSpriteRotation = 0 then
                    indexForSpriteRotation := indexForSpriteRotation'HIGH;
                 else
                    indexForSpriteRotation := indexForSpriteRotation - 1;
                 end if;
             end if;
             sRotation <= TRIGONOMETRIC_FUNCTIONS_TABLE(indexForSpriteRotation).angle;
          else
             counterForSpriteRotationUpdate := counterForSpriteRotationUpdate + 1;
          end if;
   
       end if;
   end process;

  RefreshsSpriteContent : process (inClock)
    variable oneDimensionalPointer: integer := 0;
  begin
    -- TODO : assert proper height and width
    for i in SPRITE_SIZE.height-1 downto 0 loop
       oneDimensionalPointer := i*SPRITE_WIDTH;
       for o in SPRITE_SIZE.width-1 downto 0 loop
          sSpriteContent(i)(o) <= SPRITE_CONTENT(oneDimensionalPointer+o);
       end loop;
    end loop;
  end process;

  ProcessPosition : process(inClock,
                            inSpritePos,
                            inCursorPos)
    variable vCursor : Pos2D := (0, 0);
    variable vTranslatedCursor: Pos2D := (0, 0);
  begin
      if not inEnabled then
          outShouldDraw <= false;
      elsif rising_edge(inClock) then
          sCenterPos <= inSpritePos;

          vCursor := inCursorPos;

          if   vCursor.x < (sCenterPos.x - C_HALF_SCALED_WIDTH)
            or vCursor.x > (sCenterPos.x + C_HALF_SCALED_WIDTH)
            or vCursor.y < (sCenterPos.y - C_HALF_SCALED_HEIGHT)
            or vCursor.y > (sCenterPos.y + C_HALF_SCALED_HEIGHT)
            then
              outShouldDraw <= false;
          else
             vTranslatedCursor := (((vCursor.x - (sCenterPos.x - C_HALF_SCALED_WIDTH))  / SCALE), 
                                   ((vCursor.y - (sCenterPos.y - C_HALF_SCALED_HEIGHT)) / SCALE));
             -- for rotation, first we do a translation to have the origin in the center of the sprite
             vTranslatedCursor := translateOriginToCenterOfSprite(SPRITE_SIZE, vTranslatedCursor);
             -- then we apply the rotation
             vTranslatedCursor := rotate(SPRITE_SIZE, vTranslatedCursor, sRotation);
             -- and translate the origin back
             vTranslatedCursor := translateOriginBackToFirstBitCorner(SPRITE_SIZE, vTranslatedCursor);
             -- now we check the sprite content with the transformed cursor
             if sSpriteContent(vTranslatedCursor.y)(vTranslatedCursor.x) = '1' then
                outShouldDraw <= true;
             else
                outShouldDraw <= false;
             end if;
          end if;
      end if;
  end process;
end logic;
