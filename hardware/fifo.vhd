library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
    generic (
        DATA_WIDTH : positive := 32;
        FIFO_DEPTH : positive := 5
    );
    port (
        clkw    : in  std_logic;
        clkr    : in  std_logic;
        rst     : in  std_logic;
        wr      : in  std_logic;
        rd      : in  std_logic;
        din     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        empty   : out std_logic;
        full    : out std_logic;
        dout    : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end fifo;

architecture arch of fifo is

    type fifo_t is array (0 to 2**FIFO_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mem : fifo_t;

    signal rdp, wrp : unsigned(FIFO_DEPTH downto 0) := (others => '0');
    signal int_rdp : unsigned(FIFO_DEPTH-1 downto 0);
    signal int_wrp : unsigned(FIFO_DEPTH-1 downto 0);

    signal sig_full : std_logic;
    signal sig_empty : std_logic;
begin
    int_rdp <= rdp(FIFO_DEPTH - 1 downto 0);    --assign the lower bits of read pointer to the int_rdp
    int_wrp <= wrp(FIFO_DEPTH - 1 downto 0);
    -- handle write operations on the rising edge of the write clock, remember to increment write pointer
    process(clkw)
    begin
        if rising_edge(clkw) then
            if rst = '1' then           -- if reset is 1, reset the write pointer
                wrp <= (others => '0');
            else
                if wr = '1' and sig_full = '0' then     -- if write is enable and fifo is not full
                    mem(to_integer(int_wrp)) <= din;   -- write the dada to the current memory location
                    wrp <= wrp + 1;                     -- increment write pointer
                end if;
            end if;
        end if;
    end process;
         
    -- handle read operations on the rising edge of the read clock, remember to increment read pointer
    process(clkr)
    begin
        if rising_edge(clkr) then
            if rst = '1' then           -- if reset is 1, reset the read pointer
                rdp <= (others => '0');
            else
                if (rd = '1' and sig_empty = '0') or sig_full = '1'  then     -- if read is enable and fifo is not empty
                    rdp <= rdp + 1;                     -- increment read pointer
                end if;
            end if;
        end if;
    end process;
    
    -- status signal and empty signal can be computed asynchronously against the read/write pointer values
    sig_full <= '1' when ((wrp(FIFO_DEPTH) /= rdp(FIFO_DEPTH)) and (int_wrp = int_rdp)) else '0';   -- fifo is full when the lower bits are equal and MSB not equal
                                                                                                    -- means the write pointer has wrapped around and arrive the same place for read pointer
    sig_empty <= '1' when wrp = rdp else '0';                                                       -- fifo is empty when before writing data(fifo is empty) or 
                                                                                                    -- finish reading data (clean the fifo)
    
    -- output value can be computed asynchronously using the read pointer
    full <= sig_full;
    empty <= sig_empty;
    dout <= mem(to_integer(int_rdp));

end arch;
