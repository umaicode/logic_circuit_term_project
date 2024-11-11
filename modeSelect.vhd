signal mode : std_logic_vector(1 downto 0);
signal sw0_node : std_logic;

process(reset, clk, sw0)
begin
    if reset = '0' then
        sw0_node <= '0';
    elsif rising_edge(clk) then
        sw0_node <= sw0;
    end if;
end process;

process(reset, sw0_node)
begin
    if reset = '0' then
        mode <= "00";
    elsif rising_edge(sw0_node) then
        mode <= mode + 1;
    end if;
end process;