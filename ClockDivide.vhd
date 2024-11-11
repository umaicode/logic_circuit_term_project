process(clk, clk1hz)
    variable cnt1hz : integer := 0;

begin
    if rising_edge(clk) then
        if cnt1hz >= 499999 then
            cnt1hz := 0;
            clk1hz <= not clk1hz;
        else
            cnt1hz := cnt1hz + 1;
        end if;
    end if;
end process;