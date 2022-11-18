LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Decision_Circuit IS
    GENERIC (
        threshold_frequency : STD_LOGIC_VECTOR (15 DOWNTO 0) := X"F0F0";
        alarm_on_time : INTEGER := 10
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        frequency_count : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        alarm : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE main OF Decision_Circuit IS
    TYPE state IS (standby, one, two, three, four, five);
    SIGNAL pr_state, nx_state : state;
    SIGNAL alarm_signal : STD_LOGIC;
BEGIN

    REG : PROCESS (reset, clk)
    BEGIN
        IF (reset = '1') THEN
            pr_state <= standby;
        ELSIF (clk'EVENT AND clk = '1') THEN
            pr_state <= nx_state;
        END IF;
    END PROCESS;

    CMB : PROCESS (frequency_count)
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

    -- alarm_signal <= '1' WHEN pr_state = five ELSE
    --     '0';

    OUTPUT : PROCESS (pr_state)
    BEGIN
        IF pr_state = five THEN
            alarm_signal <= '1';
        ELSE
            alarm_signal <= '0';
        END IF;
    END PROCESS;

    COUNTER : PROCESS (clk)
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
END ARCHITECTURE;