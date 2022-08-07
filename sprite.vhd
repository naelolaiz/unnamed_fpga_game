library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

package MyPackage is 
   type Rotation is (ZERO, HALF_PI, PI, THREE_QUARTERS_PI);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library work;
use work.MyPackage.all;

entity sprite is
   generic (SPRITE_WIDTH   : integer := 7;
            SCALE          : integer := 3;
            SPRITE_CONTENT : std_logic_vector := "1001001"
                                               & "0101010"
                                               & "0011100"
                                               & "1111111"
                                               & "0011100"
                                               & "0101010"
                                               & "1001001");
   port( inClock : in  std_logic;
         inEnabled : in boolean;
         inSpritePosX  : in std_logic_vector(15 downto 0);  -- center position of sprite in X
         inSpritePosY  : in std_logic_vector(15 downto 0);  -- center position of sprite in Y
         inCursorX     : in std_logic_vector(15 downto 0);
         inCursorY     : in std_logic_vector(15 downto 0);
         inRotation    : in Rotation;
         outShouldDraw : out boolean);
end;

architecture logic of sprite is
   
   constant SPRITE_HEIGHT        : integer := SPRITE_CONTENT'length / SPRITE_WIDTH;
   type SPRITE_CONTENT_TYPE is array (SPRITE_HEIGHT-1 downto 0) of std_logic_vector (SPRITE_WIDTH-1 downto 0);

   signal sSpriteContent  : SPRITE_CONTENT_TYPE;

   signal sCenterPosX     : integer := 0;
   signal sCenterPosY     : integer := 0;
   constant C_SCALED_WIDTH       : integer := SPRITE_WIDTH * SCALE;
   constant C_HALF_SCALED_WIDTH  : integer := C_SCALED_WIDTH / 2;
   constant C_SCALED_HEIGHT      : integer := SPRITE_HEIGHT * SCALE;
   constant C_HALF_SCALED_HEIGHT : integer := C_SCALED_HEIGHT / 2;


    type PositionType is array (0 to 1) of integer;  

    function RotatePosition(x : integer := 0;
                            y : integer := 0;
                            rotation : Rotation := ZERO ) return PositionType is 
        variable newX,newY : integer := 0;
    begin
        newX := x;
        newY := y;
        return (newX,newY);
    end function;




begin

  RefreshsSpriteContent : process (inClock)
    variable oneDimensionalPointer: integer := 0;
  begin
    -- TODO : assert proper height and width
    for i in SPRITE_HEIGHT-1 downto 0 loop
       oneDimensionalPointer := i*SPRITE_WIDTH;
       for o in SPRITE_WIDTH-1 downto 0 loop
          sSpriteContent(i)(o) <= SPRITE_CONTENT(oneDimensionalPointer+o);
       end loop;
    end loop;
  end process;

  ProcessPosition : process(inClock,
                            inSpritePosX,
                            inSpritePosY,
                            inCursorX,
                            inCursorY)
    variable vCursorX, vCursorY : integer := 0;
    variable vTranslatedCursor: PositionType := (others => 0);
    variable sinRotationAngle: integer :=0;
    variable cosRotationAngle: integer :=1;
  begin
      if not inEnabled then
          outShouldDraw <= false;
      elsif rising_edge(inClock) then
          sCenterPosX <= to_integer(unsigned(inSpritePosX));
          sCenterPosY <= to_integer(unsigned(inSpritePosY));

          vCursorX := to_integer(unsigned(inCursorX));
          vCursorY := to_integer(unsigned(inCursorY));

          if   vCursorX < (sCenterPosX - C_HALF_SCALED_WIDTH)
            or vCursorX > (sCenterPosX + C_HALF_SCALED_WIDTH)
            or vCursorY < (sCenterPosY - C_HALF_SCALED_HEIGHT)
            or vCursorY > (sCenterPosY + C_HALF_SCALED_HEIGHT)
            then
              outShouldDraw <= false;
          else
             vTranslatedCursor := RotatePosition((vCursorX - (sCenterPosX - C_HALF_SCALED_WIDTH))  / SCALE, 
                                   (vCursorY - (sCenterPosY - C_HALF_SCALED_HEIGHT)) / SCALE);
             if sSpriteContent(vTranslatedCursor(1))(vTranslatedCursor(0)) = '1' then
                outShouldDraw <= true;
             else
                outShouldDraw <= false;
             end if;
          end if;
      end if;
  end process;
end logic;
