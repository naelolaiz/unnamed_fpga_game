library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

package myPackage is
--type SPRITE_CONTENT is array (ORIGINAL_HEIGHT-1 downto 0) of std_logic_vector (ORIGINAL_WIDTH-1 downto 0);
--  type my_arr is array(natural range <>) of std_logic_vector;
end package myPackage;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;

library work;
use work.myPackage.all;

entity sprite is
   generic (ORIGINAL_WIDTH : integer := 7;
            SCALE          : integer := 3;
            SPRITE_CONTENT : std_logic_vector := "1001001"
                                               & "0101010"
                                               & "0011100"
                                               & "1111111"
                                               & "0011100"
                                               & "0101010"
                                               & "1001001");
   port( inClock : in  std_logic;
         inSpritePosX  : in std_logic_vector(15 downto 0);  -- center position of sprite in X
         inSpritePosY  : in std_logic_vector(15 downto 0);  -- center position of sprite in Y
         inCursorX     : in std_logic_vector(15 downto 0);
         inCursorY     : in std_logic_vector(15 downto 0);
         outShouldDraw : out boolean);
end;

architecture logic of sprite is
   
   constant ORIGINAL_HEIGHT        : integer := SPRITE_CONTENT'length / ORIGINAL_WIDTH;
   type SPRITE_CONTENT_TYPE is array (ORIGINAL_HEIGHT-1 downto 0) of std_logic_vector (ORIGINAL_WIDTH-1 downto 0);
   signal sSpriteContent  : SPRITE_CONTENT_TYPE;

   signal sCenterPosX     : integer := 0;
   signal sCenterPosY     : integer := 0;
   constant C_WIDTH       : integer := ORIGINAL_WIDTH * SCALE;
   constant C_HALF_WIDTH  : integer :=  C_WIDTH / 2;
   constant C_HEIGHT      : integer := ORIGINAL_HEIGHT * SCALE;
   constant C_HALF_HEIGHT : integer := C_HEIGHT / 2;
begin

  RefreshsSpriteContent : process (inClock)
    variable oneDimensionalPointer: integer := 0;
  begin
    -- TODO : assert proper height and width
    for i in ORIGINAL_HEIGHT-1 downto 0 loop
       oneDimensionalPointer := i*ORIGINAL_WIDTH;
       sSpriteContent(i) <= SPRITE_CONTENT(oneDimensionalPointer to oneDimensionalPointer+ORIGINAL_WIDTH-1);
    end loop;
  end process;
  ProcessPosition : process(inClock,
                            inSpritePosX,
                            inSpritePosY,
                            inCursorX,
                            inCursorY)
    variable vCursorX, vCursorY : integer := 0;
    variable vTranslatedCursorX, vTranslatedCursorY : integer := 0;
  begin
      if rising_edge(inClock) then
          sCenterPosX <= to_integer(unsigned(inSpritePosX));
          sCenterPosY <= to_integer(unsigned(inSpritePosY));

          vCursorX := to_integer(unsigned(inCursorX));
          vCursorY := to_integer(unsigned(inCursorY));

          if   vCursorX < (sCenterPosX - C_HALF_WIDTH)
            or vCursorX > (sCenterPosX + C_HALF_WIDTH)
            or vCursorY < (sCenterPosY - C_HALF_HEIGHT)
            or vCursorY > (sCenterPosY + C_HALF_HEIGHT)
            then
              outShouldDraw <= false;
          else
             vTranslatedCursorX := (vCursorX - (sCenterPosX - C_HALF_WIDTH))  / SCALE;
             vTranslatedCursorY := (vCursorY - (sCenterPosY - C_HALF_HEIGHT)) / SCALE;
             if sSpriteContent(vTranslatedCursorY)(vTranslatedCursorX) = '1' then
                outShouldDraw <= true;
             else
                outShouldDraw <= false;
             end if;
          end if;
      end if;
  end process;
end logic;
