    signal hour : std_logic_vector(4 downto 0) := "00000";
    signal min, sec : std_logic_vector(5 downto 0) := "000000";

-- process for second
    process(reset, clk1hz, sec)
    begin
        if reset = '0' then
            sec <= "000000";
        elsif rising_edge(clk1hz) then
            if conv_integer(sec) = 59 then
                sec <= "000000";
            else
                sec <= sec + '1';
            end if;
        end if;
    end process;

-- process for minute
    process(reset, clk1hz, sec, min)
    begin
        if reset = '0' then
            hour <= "00000";
        elsif rising_edge(clk1hz) then
            if conv_integer(sec) >= 59 then
                if conv_integer(min) >= 59 then
                    if conv_integer(hour) >= 23 then
                        hour <= "00000";
                    else
                        hour <= hour + '1';
                    end if;
                end if;
            end if;
        end if;
    end process;