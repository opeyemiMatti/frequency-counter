LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
----------------------------------------------------------------------------------------------------

ENTITY FMEAS_Final IS
	GENERIC (
		counting_time_window : INTEGER := 65000;
		maximum_frequency : INTEGER := 100;
		threshold_frequency : INTEGER := 10;
		alarm_on_time : INTEGER := 10
	);
	PORT (
		clk : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		freq_input : IN STD_LOGIC;
		alarm : OUT STD_LOGIC := '0'
	);
END ENTITY;

----------------------------------------------------------------------------------------------------
ARCHITECTURE behavior OF FMEAS_Final IS

	--------------------------------------------------------------------------------------------------
	--edge counter resources ------------------------------------------------------------------------
	TYPE counter_states IS (wait_for_counting, counting);
	SIGNAL pr_counter_state, nx_counter_state : counter_states;
	SIGNAL edge_counter : INTEGER RANGE 0 TO maximum_frequency := 0;
	SIGNAL frequency_count : INTEGER RANGE 0 TO maximum_frequency := 0;

	-- edge counter <-> measure timer ----------------------------------------------------------------
	SIGNAL enable_edge_counter : STD_LOGIC := '0';
	SIGNAL enable_edge_counter_ack : STD_LOGIC := '0';

	--------------------------------------------------------------------------------------------------

	-- measure timer resources -----------------------------------------------------------------------
	TYPE measure_timer_states IS (wait_for_enable_measure, wait_for_counting_started_ack, measure_timing, wait_for_disable_measure, wait_for_counting_stopped_ack);
	SIGNAL pr_measure_timer_state, nx_measure_timer_state : measure_timer_states;
	SIGNAL time_counter : INTEGER RANGE 0 TO counting_time_window := 0;
	SIGNAL enable_measure : STD_LOGIC := '0';

BEGIN
	REG_COUNTER : PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
			pr_counter_state <= wait_for_counting;
		ELSIF (clk'EVENT AND clk = '1') THEN
			pr_counter_state <= nx_counter_state;
		END IF;
	END PROCESS;

	CMB_COUNTER : PROCESS (freq_input)
	BEGIN
		IF (rising_edge(freq_input)) THEN
			CASE pr_counter_state IS
				WHEN wait_for_counting =>
					enable_measure <= '1';
					IF (enable_edge_counter = '1') THEN
						edge_counter <= 0;
						enable_edge_counter_ack <= '1';
						nx_counter_state <= counting;
					ELSE
						nx_counter_state <= wait_for_counting;
					END IF;
				WHEN counting =>
					IF (enable_edge_counter = '0') THEN
						enable_edge_counter_ack <= '0';
						nx_counter_state <= wait_for_counting;
						enable_measure <= '0';
					ELSE
						IF (edge_counter < maximum_frequency) THEN
							edge_counter <= edge_counter + 1;
							nx_counter_state <= counting;
						END IF;
					END IF;
				WHEN OTHERS => nx_counter_state <= wait_for_counting;
			END CASE;
		END IF;
	END PROCESS;

	--------------------------------------------------------------------------------------------------

	REG_MEASURE : PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
			pr_measure_timer_state <= wait_for_enable_measure;
		ELSIF (clk'EVENT AND clk = '1') THEN
			pr_measure_timer_state <= nx_measure_timer_state;
		END IF;
	END PROCESS;

	CMB_MEASURE : PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			CASE pr_measure_timer_state IS
				WHEN wait_for_enable_measure =>
					IF (enable_measure = '1') THEN
						enable_edge_counter <= '1';
						nx_measure_timer_state <= wait_for_counting_started_ack;
					ELSE
						enable_edge_counter <= '0';
						time_counter <= 0;
						nx_measure_timer_state <= wait_for_enable_measure;
					END IF;
				WHEN wait_for_counting_started_ack =>
					IF (enable_edge_counter_ack = '1') THEN
						nx_measure_timer_state <= measure_timing;
					ELSE
						nx_measure_timer_state <= wait_for_counting_started_ack;
					END IF;
				WHEN measure_timing =>
					IF (time_counter = counting_time_window) THEN
						time_counter <= 0;
						enable_edge_counter <= '0';
						nx_measure_timer_state <= wait_for_counting_stopped_ack;
						frequency_count <= edge_counter;
					ELSE
						time_counter <= time_counter + 1;
						nx_measure_timer_state <= measure_timing;
					END IF;
				WHEN wait_for_counting_stopped_ack =>
					IF (enable_edge_counter_ack = '0') THEN
						nx_measure_timer_state <= wait_for_enable_measure;
					ELSE
						nx_measure_timer_state <= wait_for_counting_stopped_ack;
					END IF;
				WHEN OTHERS => nx_measure_timer_state <= wait_for_enable_measure;
			END CASE;
		END IF;
	END PROCESS;
END behavior;