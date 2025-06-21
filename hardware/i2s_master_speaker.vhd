library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library work;
use work.aud_param.all;

-- I2S master interface for the SPH0645LM4H MEMs mic
-- useful links:
--   - https://diyi0t.com/i2s-sound-tutorial-for-esp32/
--   - https://cdn-learn.adafruit.com/downloads/pdf/adafruit-i2s-mems-microphone-breakout.pdf
--   - https://cdn-shop.adafruit.com/product-files/3421/i2S+Datasheet.PDF

entity i2s_master_speaker is
    generic (
        DATA_WIDTH : natural := 32;
        PCM_PRECISION : natural := 18
    );
    port (
        clk             : in  std_logic;
        clk_1            : in  std_logic;

        -- I2S interface to MEMs mic
        i2s_lrcl        : out std_logic;    -- left/right clk (word sel): 0 = left, 1 = right
        i2s_din        : out  std_logic;    -- Serial data output to the speaker, MSB first
        i2s_bclk        : out std_logic;    -- Bit clock: freq = sample rate * bits per channel * number of channels
                                            -- (should run at 2-4MHz). Changes when the next bit is ready.
        -- FIFO interface to MEMs mic
         fifo_data       : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Audio data input from FIFO
        fifo_r_stb      : out std_logic;  -- Read strobe signal for FIFO: 1 = read, 0 = wait
        fifo_empty      : in  std_logic   -- FIFO empty signal: 1 = FIFO is empty, 0 = FIFO has data
    );
end i2s_master_speaker;

architecture Behavioral of i2s_master_speaker is
    --put your signals here
    signal i2s_bclk_counter : unsigned(4 downto 0) := (others => '0');  -- Corresponds to range 0 to 18
    signal i2s_lrcl_counter : unsigned(4 downto 0) := (others => '0');  -- Corresponds to range 0 to 31
    signal i2s_bclk_status  : std_logic := '0'; 
    signal i2s_lrcl_status  : std_logic := '0';
    
    signal audio_sample : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0'); -- Audio sample buffer
    
    signal fsm_counter      : unsigned(4 downto 0) := (others => '0');
    type state_type is (shift_data, fetch_data, clear_buffer);
    signal cur_state : state_type :=fetch_data;
    signal next_state : state_type;
    signal fifo_done : std_logic := '0';
begin
    -----------------------------------------------------------------------
    -- I2S Bit Clock (i2s_bclk) Generator
    -----------------------------------------------------------------------
    --implementation...:
    process (clk)
    begin
        if rising_edge(clk) then
            if i2s_bclk_counter = 18 then  -- 100MMz / 44.1KHz*32*2 /2 
                i2s_bclk_status <= not i2s_bclk_status;  -- generate the blck cycle
                i2s_bclk_counter <= (others => '0');
            else
                i2s_bclk_counter <= i2s_bclk_counter + 1;
            end if;
        end if;
    end process;
    i2s_bclk <= i2s_bclk_status;
    ------------------------------------------------------------------------
    -- I2S Left/Right Clock (i2s_lrcl) Generator
    ------------------------------------------------------------------------
    --implementation...:
    process (i2s_bclk_status)
    begin
        if rising_edge(i2s_bclk_status) then
            if i2s_lrcl_counter = 31 then  -- change the direction after every 32 blck cycle
                i2s_lrcl_status <= not i2s_lrcl_status;
                i2s_lrcl_counter <= (others => '0');
            else
                i2s_lrcl_counter <= i2s_lrcl_counter + 1;
            end if;
        end if;
    end process;
    i2s_lrcl <= i2s_lrcl_status;
    ------------------------------------------------------------------------
    -- hint: write code for I2S FSM
    ------------------------------------------------------------------------
    --implementation...:
    process (cur_state, fsm_counter)
        begin
            case cur_state is
                when fetch_data =>
                    if fifo_empty = '0' then
                        next_state <= shift_data;
                    else
                        next_state <= fetch_data;
                    end if;
                when shift_data =>
                    if fsm_counter = 31 then
                        next_state <= clear_buffer;
                    else
                        next_state <= shift_data;
                    end if;
                when clear_buffer =>
                    next_state <= fetch_data;
            end case;
    end process;

    
    process (i2s_bclk_status)
    begin
        if rising_edge(i2s_bclk_status) then
            cur_state <= next_state;
            if fsm_counter = 31 then
                fsm_counter <= (others => '0');
            else
                fsm_counter <= fsm_counter + 1;
            end if;
        end if;
    end process;
    
    process (i2s_bclk_status)
    begin
        if rising_edge (i2s_bclk_status) then
            case cur_state is
                when shift_data =>
                    i2s_din <= audio_sample(DATA_WIDTH-1 - to_integer(fsm_counter)) ;  

                when fetch_data =>
                    if fifo_empty = '0' then
                        audio_sample <= fifo_data; -- Load data from FIFO into audio_sample
                    end if;

                when clear_buffer =>
                    audio_sample <= (others => '0');   -- clear the buffer for next 32bits date

            end case;
        end if;
    end process;
    
        --------------------------------------------------
    -- hint: write code for FIFO data handshake
    --------------------------------------------------
    -- hint: Useful link: https://encyclopedia2.thefreedictionary.com/Hand+shake+signal
    --implementation...:
    process (clk)
    begin
        if rising_edge(clk) then
            if (cur_state = fetch_data) and (fifo_empty = '0') and (fifo_done = '0') then    --when the state is fetch_state, fifo is not empty and read is not done
                                                                                            -- check fifo_done because that can ensure the fifo read strobe is only asserted once per data word.
                fifo_r_stb <= '1';      -- Assert FIFO read strobe
                fifo_done <= '1';       -- Mark read as done
            else
                fifo_r_stb <= '0';      -- Deassert FIFO read strobe
            end if;
        
            if cur_state = clear_buffer then    -- reset the fifo_done when the state is clear buffer (for next cycle)
                fifo_done <= '0';
            end if;
        end if;
    end process;   

end Behavioral;
