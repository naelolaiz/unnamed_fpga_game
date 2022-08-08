library ieee;
use ieee.std_logic_1164;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

package definitions is

   type Pos2D is
   record
      x: integer;
      y: integer;
   end record;

   type AngleType is ufixed (2 downto -5); -- unsigned q3.5 for angle (enough for 0..2*PI)

   type TrigonometricFunctionsRecord is
   record
       angle : AngleType;
       sin   : sfixed (1 downto -6); -- signed q2.6 (2. including sign) for sin result
       cos   : sfixed (1 downto -6); -- signed q2.6 for cos result
   end record;

   constant TrigonometricFunctionsTable is array (natural range <>) of TrigonometricFunctionsRecord :=
   (
   (ZERO,           to_sfixed(0.0,  1, -6), to_sfixed(1.0,  1, -6),
   (HALF_PI,        to_sfixed(1.0,  1, -6), to_sfixed(0.0,  1, -6),
   (PI,             to_sfixed(0.0,  1, -6), to_sfixed(-1.0, 1, -6),
   (THREE_HALFS_PI, to_sfixed(-1.0, 1, -6), to_sfixed(0.0,  1, -6)
   );

-- created with python:
-- import math
-- table_size = 16
-- # first element (integer) includes sign.
-- angle_q_size = (3,5)
-- output_q_size = (2,6)
-- float_angles = [ 2 * math.pi * t / table_size for t in range(table_size) ]
-- sinTable     = [ round(math.sin(angle) * (2**output_q_size[1] - 1)) for angle in float_angles ]
-- cosTable     = [ round(math.cos(angle) * (2**output_q_size[1] - 1)) for angle in float_angles ]
-- q_angles     = [ round(angle * (2**angle_q_size[1] - 1)) for angle in float_angles ]
-- print list(zip(q_angles, sinTable, cosTable))


-- ((0, 0, 63),
--  (12, 24, 58),
--  (24, 45, 45),
--  (37, 58, 24),
--  (49, 63, 0),
--  (61, 58, -24),
--  (73, 45, -45),
--  (85, 24, -58),
--  (97, 0, -63),
--  (110, -24, -58),
--  (122, -45, -45),
--  (134, -58, -24),
--  (146, -63, 0),
--  (158, -58, 24),
--  (170, -45, 45),
--  (183, -24, 58))



end package;
