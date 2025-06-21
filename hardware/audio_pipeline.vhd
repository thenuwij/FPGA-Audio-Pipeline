library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library work;
use work.aud_param.all;

entity audio_pipeline is
    generic(
        PCM_PRECISION : integer := 18;
        PCM_WIDTH : integer := 24;
        DATA_WIDTH : integer := 32;
        FIFO_DEPTH : integer := 12;
        TRANSFER_LEN : integer := 5;
		C_S00_AXI_DATA_WIDTH    : integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
    );
    port(
        clk: in std_logic;
        clk_1: in  std_logic;
        rst: in std_logic;
        
        -- testing ports -------------------------------------------------------------------------------------
        signal_write_fifo_speaker : out std_logic_vector(DATA_WIDTH-1 downto 0);
        fifo_data_out_speaker : out std_logic_vector(DATA_WIDTH-1 downto 0);
        fifo_wr_speaker : out std_logic;
        fifo_full_speaker : out std_logic;
        speaker_enable : out std_logic;
        control_reg : out std_logic_vector(DATA_WIDTH-1 downto 0);
        -------------------------------------------------------------------------------------------------------------

        --------------------------------------------------
        -- I2S
        --------------------------------------------------
        i2s_bclk        : out std_logic;
        i2s_lrcl        : out std_logic;
        i2s_dout        : in  std_logic;
        
        --------------------------------------------------
        -- I2S for Speaker
        --------------------------------------------------
        i2s_bclk_speaker : out std_logic;
        i2s_lrcl_speaker : out std_logic;
        i2s_din_speaker : out std_logic;
        
        --------------------------------------------------
        -- AXI4-Stream
        --------------------------------------------------
        axis_tdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
        axis_tvalid     : out std_logic;
        axis_tready     : in  std_logic;
        axis_tlast      : out std_logic;
        
        -- Speaker  
        axis_tdata_s : in std_logic_vector(DATA_WIDTH-1 downto 0);
        axis_tvalid_s : in std_logic;
        axis_tready_s : out std_logic;
        axis_tlast_s : in std_logic;
        --------------------------------------------------
        -- Control interface (AXI4-Lite)
        --------------------------------------------------
		s00_axi_aclk	: in  std_logic;
		s00_axi_aresetn	: in  std_logic;
		s00_axi_awaddr	: in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in  std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in  std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in  std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in  std_logic;
		s00_axi_araddr	: in  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in  std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in  std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in  std_logic
    );
end audio_pipeline;

architecture Behavioural of audio_pipeline is
    --------------------------------------------------
    -- FIFO
    --------------------------------------------------
    signal sig_fifo_rst             : std_logic;
    signal sig_fifo_wr              : std_logic;
    signal sig_fifo_rd              : std_logic;
    signal sig_fifo_full            : std_logic;
    signal sig_fifo_empty           : std_logic;
    signal sig_fifo_data_w          : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_fifo_data_r          : std_logic_vector(DATA_WIDTH-1 downto 0);
  
    
    --------------------------------------------------
    -- FIFO for Speaker
    --------------------------------------------------
    signal sig_fifo_rst_speaker : std_logic;
    signal sig_fifo_wr_speaker : std_logic;
    signal sig_fifo_rd_speaker : std_logic;
    signal sig_fifo_full_speaker : std_logic;
    signal sig_fifo_empty_speaker : std_logic;
    signal sig_fifo_data_w_speaker : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_fifo_data_r_speaker : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    --------------------------------------------------
    -- AXI4-Stream
    --------------------------------------------------
    signal sig_axis_tdata           : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_axis_tvalid          : std_logic;
    signal sig_axis_tready          : std_logic;
    signal sig_axis_tlast           : std_logic;

    --------------------------------------------------
    -- Control interface (AXI4-Lite)
    --------------------------------------------------
    signal sig_control_reg          : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_status_reg           : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_gain_reg             : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sig_mic_enable : std_logic := '0'; -- Enable signal for microphone
    signal sig_speaker_enable : std_logic := '0'; -- Enable signal for speaker
    
begin
    
    -- for testing data transfer to speaker 
    --sig_fifo_wr_speaker_out <= sig_fifo_wr_speaker;
    --sig_fifo_full_speaker_out <= sig_fifo_full_speaker;

    sig_status_reg <= x"0ca7cafe";
    --------------------------------------------------
    -- Control bus
    --------------------------------------------------
    inst_ctrl_bus : ctrl_bus
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
        cb_control_reg  => sig_control_reg,
        cb_status_reg   => sig_status_reg,
        cb_gain_reg     => sig_gain_reg,

		S_AXI_ACLK	    => s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	    => s00_axi_wdata,
		S_AXI_WSTRB	    => s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

    process (sig_control_reg)
    begin
        sig_mic_enable <= sig_control_reg(0); -- Bit 0 enables microphone
        sig_speaker_enable <= sig_control_reg(1); -- Bit 1 enables speaker
    --    sig_speaker_enable <= '1'; -- testing
    end process;

    sig_fifo_rst <= not rst when sig_mic_enable = '1' else '1';
    sig_fifo_rst_speaker <= not rst when sig_speaker_enable = '1' else '1';

    --------------------------------------------------
    -- I2S Master
    --------------------------------------------------
    inst_i2s_master : i2s_master
    generic map (
        DATA_WIDTH      => DATA_WIDTH,
        PCM_PRECISION   => PCM_PRECISION
    )
    port map (
        clk             => clk,
        clk_1           => clk_1,

        i2s_lrcl        => i2s_lrcl,
        i2s_dout        => i2s_dout,
        i2s_bclk        => i2s_bclk,

        fifo_din        => sig_fifo_data_w,
        fifo_w_stb      => sig_fifo_wr,
        fifo_full       => sig_fifo_full
    );

    --------------------------------------------------
    -- FIFO
    --------------------------------------------------
    inst_fifo : fifo 
    generic map (
        data_width => DATA_WIDTH,
        fifo_depth => FIFO_DEPTH
    ) port map (
        clkw            => clk,
        clkr            => clk,
        rst             => sig_fifo_rst,

        wr              => sig_fifo_wr,
        din             => sig_fifo_data_w,
        full            => sig_fifo_full,

        rd              => sig_fifo_rd,
        dout            => sig_fifo_data_r,
        empty           => sig_fifo_empty
    );
    
    --------------------------------------------------
    -- FIFO for Speaker
    --------------------------------------------------
    inst_fifo_speaker : fifo 
    generic map (
        data_width => DATA_WIDTH,
        fifo_depth => FIFO_DEPTH
    )
    port map (
        clkw => clk,
        clkr => clk,
        rst => sig_fifo_rst_speaker,

        wr => sig_fifo_wr_speaker,
        din => sig_fifo_data_w_speaker,
        full => sig_fifo_full_speaker,

        rd => sig_fifo_rd_speaker,
        dout => sig_fifo_data_r_speaker,
        empty => sig_fifo_empty_speaker
    );
    
    --------------------------------------------------
    -- I2S Master for Speaker
    --------------------------------------------------
    inst_i2s_master_speaker : i2s_master_speaker
    generic map (
        DATA_WIDTH => DATA_WIDTH,
        PCM_PRECISION => PCM_PRECISION
    )
    port map (
        clk => clk,
        clk_1 => clk_1,

        i2s_lrcl => i2s_lrcl_speaker,
        i2s_din => i2s_din_speaker,
        i2s_bclk => i2s_bclk_speaker,

        fifo_data => sig_fifo_data_r_speaker,
        fifo_r_stb => sig_fifo_rd_speaker,
        fifo_empty => sig_fifo_empty_speaker
    );

    --------------------------------------------------
    -- AXIS to FIFO Interface for Speaker
    --------------------------------------------------
    sig_fifo_wr_speaker <= axis_tvalid_s and (not sig_fifo_full_speaker) and sig_speaker_enable;
    sig_fifo_data_w_speaker <= axis_tdata_s;
    axis_tready_s <= not sig_fifo_full_speaker; 
    
    -- testing 
   signal_write_fifo_speaker <= sig_fifo_data_w_speaker;
   fifo_data_out_speaker <= sig_fifo_data_r_speaker;
   fifo_wr_speaker <= sig_fifo_wr_speaker;
   fifo_full_speaker <= sig_fifo_full_speaker;
   speaker_enable <= sig_speaker_enable;
   control_reg <= sig_control_reg;
    ----------------------------------------------------

    --------------------------------------------------
    -- FIFO to AXIS
    --------------------------------------------------
    -- FIFO read
    sig_fifo_rd <= (not sig_fifo_empty) and sig_axis_tvalid and axis_tready;
    sig_axis_tvalid <= '1' when sig_fifo_empty = '0' else '0';
    axis_tvalid <= sig_axis_tvalid;
    
    -- TLAST
    process (clk)
        -- variable v_cnt : unsigned(3 downto 0) := (others => '0');
        variable v_cnt : integer := 0;
    begin
        if (rst = '0') then
            v_cnt := 0;
        elsif rising_edge(clk) then
            if ((sig_axis_tvalid and axis_tready) = '1') then
                v_cnt := v_cnt + 1;
                
                if (v_cnt = 256) then
                    axis_tlast <= '1';
                    v_cnt := 0;
                else
                    axis_tlast <= '0';
                end if;
            end if;
        end if;
    end process;
    -- axis_tlast <= '1';

    -- TDATA
    -- axis_tdata <= sig_fifo_data_r when (sig_axis_tvalid and axis_tready) = '1' else (others => '0');
    axis_tdata <= sig_fifo_data_r;


end Behavioural;
