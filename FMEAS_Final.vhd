LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
----------------------------------------------------------------------------------------------------

ENTITY top_level IS
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
ARCHITECTURE behavior OF top_level IS

	--------------------------------------------------------------------------------------------------
	--edge counter resources ------------------------------------------------------------------------
	TYPE counter_states IS (wait_for_counting, counting);
	SIGNAL edge_counter_state : counter_states := wait_for_counting;
	SIGNAL edge_counter : INTEGER RANGE 0 TO maximum_frequency := 0;
	SIGNAL frequency_count : INTEGER RANGE 0 TO maximum_frequency := 0;

	-- edge counter <-> measure timer ----------------------------------------------------------------
	SIGNAL enable_edge_counter : STD_LOGIC := '0';
	SIGNAL enable_edge_counter_ack : STD_LOGIC := '0';

	--------------------------------------------------------------------------------------------------

	-- measure timer resources -----------------------------------------------------------------------
	TYPE measure_timer_states IS (wait_for_enable_measure, wait_for_counting_started_ack, measure_timing, wait_for_disable_measure, wait_for_counting_stopped_ack);
	SIGNAL measure_timer_state : measure_timer_states := wait_for_enable_measure;
	SIGNAL time_counter : INTEGER RANGE 0 TO counting_time_window := 0;
	SIGNAL enable_measure : STD_LOGIC := '0';
	--------------------------------------------------------------------------------------------------
	---Decision Stage resources
	TYPE state IS (standby, one, two, three, four, five);
	SIGNAL pr_state, nx_state : state;
	SIGNAL alarm_signal : STD_LOGIC;
BEGIN

	L_EDGE_COUNTER : PROCESS (freq_input, reset)
	BEGIN
		IF (reset = '1') THEN
			edge_counter_state <= wait_for_counting;
			edge_counter <= 0;
			enable_edge_counter_ack <= '0';
		ELSIF (rising_edge(freq_input)) THEN
			CASE edge_counter_state IS
				WHEN wait_for_counting => enable_measure <= '1';
					IF (enable_edge_counter = '1') THEN
						edge_counter <= 0;
						enable_edge_counter_ack <= '1';
						edge_counter_state <= counting;
					ELSE
						edge_counter_state <= wait_for_counting;
					END IF;
				WHEN counting => IF (enable_edge_counter = '0') THEN
					enable_edge_counter_ack <= '0';
					edge_counter_state <= wait_for_counting;
					enable_measure <= '0';
				ELSE
					IF (edge_counter < maximum_frequency) THEN
						edge_counter <= edge_counter + 1;
						edge_counter_state <= counting;
					END IF;

			END IF;
			WHEN OTHERS => edge_counter_state <= wait_for_counting;
		END CASE;
	END IF;
END PROCESS;
--------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
L_MEASURE_TIMER : PROCESS (clk, reset)
BEGIN
	IF (reset = '1') THEN
		measure_timer_state <= wait_for_enable_measure;
		enable_edge_counter <= '0';
		time_counter <= 0;

	ELSIF (rising_edge(clk)) THEN
		CASE measure_timer_state IS
			WHEN wait_for_enable_measure => IF (enable_measure = '1') THEN
				enable_edge_counter <= '1';
				measure_timer_state <= wait_for_counting_started_ack;
			ELSE
				measure_timer_state <= wait_for_enable_measure;
		END IF;
		WHEN wait_for_counting_started_ack => IF (enable_edge_counter_ack = '1') THEN
		measure_timer_state <= measure_timing;
	ELSE
		measure_timer_state <= wait_for_counting_started_ack;
	END IF;
	WHEN measure_timing => IF (time_counter = counting_time_window) THEN
	time_counter <= 0;
	enable_edge_counter <= '0';
	measure_timer_state <= wait_for_counting_stopped_ack;
	frequency_count <= edge_counter;
ELSE
	time_counter <= time_counter + 1;
	measure_timer_state <= measure_timing;
END IF;
WHEN wait_for_counting_stopped_ack => IF (enable_edge_counter_ack = '0') THEN

measure_timer_state <= wait_for_enable_measure;
ELSE
measure_timer_state <= wait_for_counting_stopped_ack;
END IF;
WHEN OTHERS => measure_timer_state <= wait_for_enable_measure;
END CASE;
END IF;
END PROCESS;
--------------------------------------------------------------------------------------------------

ALARM_STATES : PROCESS (reset, clk)
BEGIN
	IF (reset = '1') THEN
		pr_state <= standby;
	ELSIF (clk'EVENT AND clk = '1') THEN
		pr_state <= nx_state;
	END IF;
END PROCESS;

DECISON_STAGE : PROCESS (frequency_count)
BEGIN
	CASE pr_state IS
		WHEN standby =>
			IF (frequency_count >= threshold_frequency) THEN
				nx_state <= one;
			ELSE
				nx_state <= standby;
			END IF;
		WHEN one =>
			IF (frequency_count >= threshold_frequency) THEN
				nx_state <= two;
			ELSE
				nx_state <= standby;
			END IF;
		WHEN two =>
			IF (frequency_count >= threshold_frequency) THEN
				nx_state <= three;
			ELSE
				nx_state <= standby;
			END IF;
		WHEN three =>
			IF (frequency_count >= threshold_frequency) THEN
				nx_state <= four;
			ELSE
				nx_state <= standby;
			END IF;
		WHEN four =>
			IF (frequency_count >= threshold_frequency) THEN
				nx_state <= five;
			ELSE
				nx_state <= standby;
			END IF;

		WHEN five =>
			nx_state <= standby;
	END CASE;

END PROCESS;

alarm_signal <= '1' WHEN pr_state = five ELSE
	'0';

ALARM_TRIGGER : PROCESS (clk)
	VARIABLE alarm_time_count : INTEGER := 5;

BEGIN
	IF (clk 'event AND clk = '1') THEN

		IF alarm_signal = '1' THEN
			alarm_time_count := 0;
		END IF;
		IF alarm_time_count < alarm_on_time THEN
			alarm_time_count := alarm_time_count + 1;
			alarm <= '1';
		ELSE
			alarm <= '0';
		END IF;
	END IF;
END PROCESS;

END behavior;