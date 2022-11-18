LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
----------------------------------------------------------------------------------------------------
ENTITY toplevel_testbench IS
END toplevel_testbench;
----------------------------------------------------------------------------------------------------
ARCHITECTURE behavior OF toplevel_testbench IS

	CONSTANT clock_cycle : TIME := 8.333 ns; -- 120 MHz system clock
	SIGNAL freq_in_cycle : TIME := 12 ns; -- cycle time of the measurable frequency

	SIGNAL clk : STD_LOGIC := '0'; -- system clock
	SIGNAL reset : STD_LOGIC := '1'; -- system reset
	SIGNAL freq_in : STD_LOGIC := '0'; -- signal, whose frequency has to be measured															-- a value computed by the test environment based on the output of the frequency measurement circuit

	SIGNAL alarm : STD_LOGIC := '0'; -- signal, whose frequency has to be measured															-- a value computed by the test environment based on the output of the frequency measurement circuit
BEGIN

	top_level_inst : ENTITY work.top_level
		GENERIC MAP(
			counting_time_window => 10,
			maximum_frequency => 100,
            threshold_frequency => 2,
			alarm_on_time => 2)
		
		PORT MAP(
			clk => clk,
			reset => reset,
			freq_input => freq_in,
			alarm => alarm
		);
		
	
	-- TEST SEQUENCES --
	L_FREQ_IN_CYCLE : PROCESS
	BEGIN
		WAIT FOR 10 ns;
		reset <= '0';

		WAIT FOR 10 ns;
--
		freq_in_cycle <= 10 ns;
		WAIT FOR 90 ns;

		freq_in_cycle <= 16 ns;
		WAIT FOR 90 ns;

		freq_in_cycle <= 16 ns;
		WAIT FOR 90 ns;

		freq_in_cycle <= 16 ns;
		WAIT FOR 90 ns;

		freq_in_cycle <= 16 ns;
		WAIT FOR 90 ns;
		

		freq_in_cycle <= 15 ns;
		WAIT FOR 10 ns;

		freq_in_cycle <= 20 ns;
		WAIT FOR 10 ns;

	freq_in_cycle <= 25 ns;
	WAIT FOR 10 ns;
	
	freq_in_cycle <= 30 ns;
 		WAIT FOR 10 ns;

	freq_in_cycle <= 12 ns;
		WAIT FOR 40 ns;

		freq_in_cycle <= 10 ns;
 		WAIT FOR 40 ns;

		freq_in_cycle <= 12 ns;
	WAIT FOR 40 ns;

		freq_in_cycle <= 10 ns;
		WAIT FOR 40 ns;

	 freq_in_cycle <= 12 ns;
		 WAIT FOR 50 ns;
		 
		 freq_in_cycle <= 22 ns;
		 WAIT FOR 50 ns;
		 
		 freq_in_cycle <= 32 ns;
		 WAIT FOR 50 ns;

		WAIT;
	END PROCESS;

	-- generating the clock and the measurable frequency --
	L_CLOCK : PROCESS
	BEGIN
		WAIT FOR clock_cycle/2;
		clk <= NOT clk;
	END PROCESS;

	L_FREQ_IN : PROCESS
	BEGIN
		WAIT FOR freq_in_cycle/2;
		freq_in <= NOT freq_in;
	END PROCESS;

END behavior;
----------------------------------------------------------------------------------------------------