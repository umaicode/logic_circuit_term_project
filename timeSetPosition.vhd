    signal set_time : std_logic_vector := "100";

    process(reset, sw1)
    begin
        if reset = '0' then
            set_time <= "100";
        elsif rising_edge(sw1) then
            case set_time is
                when "100" =>
                    set_time <= "010";
                when "010" =>
                    set_time <= "001";
                when "001" =>
                    set_time <= "100";
                when others =>
                    set_time <= null;
            end case;
        end if;
    end process;