-- process for 7-segment display
    process(clk, hour_buf0, hour_buf1, min_buf0, min_buf1, sec_buf0, sec_buf1)
    begin
        if rising_edge(clk) then
            case hour_buf0 is --abcdefg-
                when 0 => seg_hour0 <= "1111110";
                when 1 => seg_hour0 <= "0110000";
                when 2 => seg_hour0 <= "1101101";
                when 3 => seg_hour0 <= "1111001";
                when 4 => seg_hour0 <= "0110011";
                when 5 => seg_hour0 <= "1011011";
                when 6 => seg_hour0 <= "1011111";
                when 7 => seg_hour0 <= "1110000";
                when 8 => seg_hour0 <= "1111111";
                when 9 => seg_hour0 <= "1110011";
                when others => null;
            end case;