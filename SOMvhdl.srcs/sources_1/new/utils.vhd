library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;

package utils is


    function n_bits(x: natural) return natural;
    
    function max(a: natural; b: natural) return natural;
    function min(a: natural; b: natural) return natural;

end utils;

package body utils is

    function n_bits(x: natural) return natural is
        variable temp: natural := max(x, 1);
        variable n:    natural := 1;
    begin

        while temp > 1 loop
            temp := temp / 2;
            n    := n + 1;
        end loop;

        return n;
    end function;


    function max(a: natural; b: natural) return natural is
    begin

        if (a > b) then
            return a;
        else
            return b;
        end if;

    end function;

    function min(a: natural; b: natural) return natural is
    begin

        if (a < b) then
            return a;
        else
            return b;
        end if;

    end function;

end utils;
