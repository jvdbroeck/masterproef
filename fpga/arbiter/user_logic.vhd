------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Tue Apr  2 15:15:59 2013 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.srl_fifo_f;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_AWIDTH                 -- Slave interface address bus width
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_MST_AWIDTH                 -- Master interface address bus width
--   C_MST_DWIDTH                 -- Master interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--   C_NUM_MEM                    -- Number of memory spaces
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Addr                  -- Bus to IP address bus
--   Bus2IP_CS                    -- Bus to IP chip select for user logic memory selection
--   Bus2IP_RNW                   -- Bus to IP read/not write
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
--   IP2Bus_MstRd_Req             -- IP to Bus master read request
--   IP2Bus_MstWr_Req             -- IP to Bus master write request
--   IP2Bus_Mst_Addr              -- IP to Bus master address bus
--   IP2Bus_Mst_BE                -- IP to Bus master byte enables
--   IP2Bus_Mst_Lock              -- IP to Bus master lock
--   IP2Bus_Mst_Reset             -- IP to Bus master reset
--   Bus2IP_Mst_CmdAck            -- Bus to IP master command acknowledgement
--   Bus2IP_Mst_Cmplt             -- Bus to IP master transfer completion
--   Bus2IP_Mst_Error             -- Bus to IP master error response
--   Bus2IP_Mst_Rearbitrate       -- Bus to IP master re-arbitrate
--   Bus2IP_Mst_Cmd_Timeout       -- Bus to IP master command timeout
--   Bus2IP_MstRd_d               -- Bus to IP master read data bus
--   Bus2IP_MstRd_src_rdy_n       -- Bus to IP master read source ready
--   IP2Bus_MstWr_d               -- IP to Bus master write data bus
--   Bus2IP_MstWr_dst_rdy_n       -- Bus to IP master write destination ready
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here

    -- Maximum number of successive reads from, respectively writes to
    -- the SRAM memory.
    C_MAX_BURST_READ               : integer              := 5;
    C_MAX_BURST_WRITE              : integer              := 5;

    -- Size of the SRAM memory in bytes.
    C_SRAM_SIZE                    : integer              := 262144;

    -- Size of one sample in bytes.
    C_SAMPLE_SIZE                  : integer              := 4;

    -- The SRAM memory can contain this many samples.
    C_MAX_SRAM_SAMPLES             : integer              := 65535;

    -- Largest addressible byte in SRAM (the address bus is 18 bits wide).
    C_MAX_SRAM_ADDRESS             : integer              := 262143;

    C_FIFO_DEPTH                   : integer              := 4096;
    C_DMA_LENGTH                   : integer              := 2048;

    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_AWIDTH                   : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32;
    C_MST_AWIDTH                   : integer              := 32;
    C_MST_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 5;
    C_NUM_MEM                      : integer              := 1
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here

    -- SAMPLER
    sampler_clk                    : in std_logic;
    sampler_input                  : in std_logic_vector(7 downto 0);
    isolation                      : out std_logic_vector(5 downto 0);

    -- ARBITER
    arbiter_clk                    : in std_logic;

    -- SRAM
    sram_address                   : out std_logic_vector(0 to 17);
    sram_adv                       : out std_logic;
    sram_we                        : out std_logic;
    sram_ce                        : out std_logic;
    sram_bwa                       : out std_logic;
    sram_bwb                       : out std_logic;
    sram_bwc                       : out std_logic;
    sram_bwd                       : out std_logic;
    sram_oe                        : out std_logic;
    sram_dqa_I                     : in std_logic_vector(7 downto 0);
    sram_dqa_O                     : out std_logic_vector(7 downto 0);
    sram_dqa_T                     : out std_logic;
    sram_dqb_I                     : in std_logic_vector(7 downto 0);
    sram_dqb_O                     : out std_logic_vector(7 downto 0);
    sram_dqb_T                     : out std_logic;
    sram_dqc_I                     : in std_logic_vector(7 downto 0);
    sram_dqc_O                     : out std_logic_vector(7 downto 0);
    sram_dqc_T                     : out std_logic;
    sram_dqd_I                     : in std_logic_vector(7 downto 0);
    sram_dqd_O                     : out std_logic_vector(7 downto 0);
    sram_dqd_T                     : out std_logic;

    -- MSI Interrupt Request
    msi_request                    : out std_logic;

    -- DMA Interrupt
    dma_interrupt                  : in std_logic;

    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Addr                    : in  std_logic_vector(0 to C_SLV_AWIDTH-1);
    Bus2IP_CS                      : in  std_logic_vector(0 to C_NUM_MEM-1);
    Bus2IP_RNW                     : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_Burst                   : in  std_logic;
    Bus2IP_BurstLength             : in  std_logic_vector(0 to 8);
    Bus2IP_RdReq                   : in  std_logic;
    Bus2IP_WrReq                   : in  std_logic;
    IP2Bus_AddrAck                 : out std_logic;
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Reset  : signal is "RST";
  attribute max_fanout of Bus2IP_Reset : signal is "REDUCE";

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of sampler_clk   : signal is "CLK";
  attribute SIGIS of arbiter_clk   : signal is "CLK";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  --USER signal declarations added here, as needed for user logic

  -- GEHEUGENCONTROLLER
  component sram_controller
    generic(
      SRAM_AW                      : integer := 18;
      SRAM_DW                      : integer := 8;

      AW                           : integer := 18;
      DW                           : integer := 32
    );

    port(
      clk                          : in std_logic;
      rst                          : in std_logic;
      rstinv                       : in std_logic;
      address                      : in std_logic_vector(AW-1 downto 0);
      data_in                      : in std_logic_vector(DW-1 downto 0);
      data_out                     : out std_logic_vector(DW-1 downto 0);
      data_ready                   : out std_logic;
      cmd_read                     : in std_logic;
      cmd_write                    : in std_logic;
      cmd_burst                    : in std_logic;
      ctrl2sram_a                  : out std_logic_vector(SRAM_AW-1 downto 0);
      ctrl2sram_adv                : out std_logic;
      ctrl2sram_we                 : out std_logic;
      ctrl2sram_ce                 : out std_logic;
      ctrl2sram_bwa                : out std_logic;
      ctrl2sram_bwb                : out std_logic;
      ctrl2sram_bwc                : out std_logic;
      ctrl2sram_bwd                : out std_logic;
      ctrl2sram_oe                 : out std_logic;
      sram_dqa_I                   : in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqa_O                   : out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqa_T                   : out std_logic;
      sram_dqb_I                   : in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqb_O                   : out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqb_T                   : out std_logic;
      sram_dqc_I                   : in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqc_O                   : out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqc_T                   : out std_logic;
      sram_dqd_I                   : in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqd_O                   : out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqd_T                   : out std_logic
    );
  end component;
  for all: sram_controller use entity work.sram_controller(behaviour);

  -- FIFO SAMPLER-ARBITER
  component sampler_fifo
    PORT (
      rst                          : IN STD_LOGIC;
      wr_clk                       : IN STD_LOGIC;
      rd_clk                       : IN STD_LOGIC;
      din                          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      wr_en                        : IN STD_LOGIC;
      rd_en                        : IN STD_LOGIC;
      dout                         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      full                         : OUT STD_LOGIC;
      empty                        : OUT STD_LOGIC;
      valid                        : out std_logic
    );
  end component;
  for all: sampler_fifo use entity work.sampler_fifo(behaviour);

  -- FIFO ARBITER-PLB
  component arbiter_fifo
    PORT (
        rst                        : in std_logic;
        wr_clk                     : in std_logic;
        rd_clk                     : in std_logic;
        din                        : in std_logic_vector(31 downto 0);
        wr_en                      : in std_logic;
        rd_en                      : in std_logic;
        dout                       : out std_logic_vector(31 downto 0);
        full                       : out std_logic;
        empty                      : out std_logic;
        valid                      : out std_logic
    );
  end component;
  for all: arbiter_fifo use entity work.arbiter_fifo(behaviour);

  -- SAMPLER
  component sampler
    PORT (
      clk                          : in std_logic;
      rst                          : in std_logic;
      rstinv : in std_logic;
      data                         : in std_logic_vector(7 downto 0);
      enable                       : in std_logic;
      out_write                    : out std_logic;
      out_data                     : out std_logic_vector(31 downto 0);
      fifo_full                    : in std_logic
    );
  end component;
  for all: Sampler use entity work.Sampler(RTL);

  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal slv_reg0                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg1                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg2                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg3                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg4                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg_write_sel              : std_logic_vector(0 to 4);
  signal slv_reg_read_sel               : std_logic_vector(0 to 4);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

  ------------------------------------------
  -- Signals for SRAM-controller logic
  ------------------------------------------
  signal ctrl_address                   : std_logic_vector(17 downto 0);
  signal ctrl_in                        : std_logic_vector(31 downto 0);
  signal ctrl_out                       : std_logic_vector(31 downto 0);
  signal ctrl_ready                     : std_logic;
  signal ctrl_read                      : std_logic;
  signal ctrl_write                     : std_logic;
  signal ctrl_burst                     : std_logic;

  type sram_ctrl_state_type is (CTRL_WRITING, CTRL_READING, CTRL_IDLE);
  signal ctrl_expecting_read            : std_logic;

  ------------------------------------------
  -- Signals for sampler FIFO logic: sampler side
  ------------------------------------------
  signal fifo_input                     : std_logic_vector(0 to 31);
  signal fifo_wre                       : std_logic;
  signal fifo_full                      : std_logic;
  signal fifo_afull                     : std_logic;
  signal fifo_pfull                     : std_logic;
  signal fifo_sampler_clk               : std_logic;

  ------------------------------------------
  -- Signals for sampler FIFO logic: arbiter side
  ------------------------------------------
  signal fifo_output                    : std_logic_vector(0 to 31);
  signal fifo_rde                       : std_logic;
  signal fifo_empty                     : std_logic;
  signal fifo_valid                     : std_logic;
  signal fifo_arbiter_clk               : std_logic;

  ------------------------------------------
  -- Signals for arbiter FIFO logic
  ------------------------------------------
  signal arbiterff_wrclk                : std_logic;
  signal arbiterff_rdclk                : std_logic;
  signal arbiterff_din                  : std_logic_vector(0 to 31);
  signal arbiterff_wre                  : std_logic;
  signal arbiterff_rde                  : std_logic;
  signal arbiterff_dout                 : std_logic_vector(0 to 31);
  signal arbiterff_full                 : std_logic;
  signal arbiterff_empty                : std_logic;
  signal arbiterff_valid                : std_logic;

  signal temp_sampler_input             : std_logic_vector(0 to 7);

  type XFER_STATE is (XFER_IDLE, XFER_WAIT_DATA, XFER_WAIT_DMA_INTERRUPT, XFER_WAIT_DMA_RESET, XFER_WAIT_DMA_INTERRUPT_MSI, XFER_WAIT_DATA_MSI);
  signal current_xfer_state             : XFER_STATE;
  type XFER_FORCE_STATE is (XFER_FORCE_IDLE, XFER_FORCE_DONE);
  signal current_xfer_force_state : XFER_FORCE_STATE;

  signal msireq_buf1 : std_logic;
  signal msireq_buf2 : std_logic;
  signal msireq_buf3 : std_logic;

  signal sampler_enable : std_logic;
  signal requestmsi : std_logic;
  signal fifo_full_buffer : std_logic;

  signal plbfifo_databuf : std_logic_vector(0 to 31);
  signal arbiterff_output : std_logic_vector(0 to 31);

  signal plbfifo_rdackbuf : std_logic;
  signal arbiterff_rdack : std_logic;

  signal msigen_prev : std_logic;
  signal msigen : std_logic;

  signal msidone : std_logic;
  signal msigenerated : std_logic;

  signal msigenmanual : std_logic;
  signal msigen2 : std_logic;

  signal msigenauto : std_logic;



  signal reset_fifo : std_logic;
  signal reset_msi : std_logic;

  signal reset_arbiter : std_logic;
  signal reset_arbiter_inv : std_logic;

  signal reset_sram : std_logic;
  signal reset_sram_inv : std_logic;

  signal reset_sampler : std_logic;
  signal reset_sampler_inv : std_logic;

  signal reset_component : std_logic;

  signal subtract_from_fifo : std_logic;

  signal nr_in_fifo : integer range 0 to C_FIFO_DEPTH;

  signal sram_full : std_logic;
  signal sram_empty : std_logic;

  signal forced_transfer : std_logic;

  -- voorkom het verwijderen van equivalente registers...
  -- ondanks de commandoregel wordt dit signaal wel verwijderd!
  attribute equivalent_register_removal : string;
  attribute keep : string;
  attribute equivalent_register_removal of reset_sampler : signal is "no";
  attribute keep of reset_sampler : signal is "true";
  attribute equivalent_register_removal of reset_sampler_inv : signal is "no";
  attribute keep of reset_sampler_inv : signal is "true";
  attribute equivalent_register_removal of reset_component : signal is "no";
  attribute keep of reset_component : signal is "true";
  attribute equivalent_register_removal of reset_msi : signal is "no";
  attribute keep of reset_msi : signal is "true";
  attribute equivalent_register_removal of reset_fifo : signal is "no";
  attribute keep of reset_fifo : signal is "true";
  attribute equivalent_register_removal of reset_sram : signal is "no";
  attribute keep of reset_sram_inv : signal is "true";


begin

  --USER logic implementation added here
  sram_controller_inst : entity work.sram_controller port map(
    clk                            => arbiter_clk,
    rst                            => reset_sram,
    rstinv                         => reset_sram_inv,
    address                        => ctrl_address,
    data_in                        => ctrl_in,
    data_out                       => ctrl_out,
    data_ready                     => ctrl_ready,
    cmd_read                       => ctrl_read,
    cmd_write                      => ctrl_write,
    cmd_burst                      => ctrl_burst,
    ctrl2sram_a                    => sram_address,--
    ctrl2sram_adv                  => sram_adv,--
    ctrl2sram_we                   => sram_we,--
    ctrl2sram_ce                   => sram_ce,--
    ctrl2sram_bwa                  => sram_bwa,--
    ctrl2sram_bwb                  => sram_bwb,--
    ctrl2sram_bwc                  => sram_bwc,--
    ctrl2sram_bwd                  => sram_bwd,--
    ctrl2sram_oe                   => sram_oe,--
    sram_dqa_I                     => sram_dqa_I,
    sram_dqa_O                     => sram_dqa_O,
    sram_dqa_T                     => sram_dqa_T,
    sram_dqb_I                     => sram_dqb_I,
    sram_dqb_O                     => sram_dqb_O,
    sram_dqb_T                     => sram_dqb_T,
    sram_dqc_I                     => sram_dqc_I,
    sram_dqc_O                     => sram_dqc_O,
    sram_dqc_T                     => sram_dqc_T,
    sram_dqd_I                     => sram_dqd_I,
    sram_dqd_O                     => sram_dqd_O,
    sram_dqd_T                     => sram_dqd_T
  );

sampler_fifo_inst : entity work.sampler_fifo port map(
    rst                            => reset_component,
    wr_clk                         => fifo_sampler_clk,
    rd_clk                         => fifo_arbiter_clk,
    din                            => fifo_input,
    wr_en                          => fifo_wre,
    rd_en                          => fifo_rde,
    dout                           => fifo_output,
    full                           => fifo_full,
    empty                          => fifo_empty,
    valid                          => fifo_valid
  );

arbiter_fifo_inst : entity work.arbiter_fifo port map(
    rst                            => reset_component,
    wr_clk                         => arbiterff_wrclk,
    rd_clk                         => arbiterff_rdclk,
    din                            => arbiterff_din,
    wr_en                          => arbiterff_wre,
    rd_en                          => arbiterff_rde,
    dout                           => arbiterff_dout,
    full                           => arbiterff_full,
    empty                          => arbiterff_empty,
    valid                          => arbiterff_valid
  );

sampler_inst : entity work.Sampler port map(
    clk                            => sampler_clk,
    rst                            => reset_sampler,
    rstinv                         => reset_sampler_inv,
    --TODO: herstellen naar sampler_input
    data                           => sampler_input,
    --data                           => temp_sampler_input,
    enable                         => sampler_enable,
    out_write                      => fifo_wre,
    out_data                       => fifo_input,
    fifo_full                      => fifo_full
  );


  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  --
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four  32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  --
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  --
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 4);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 4);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4);

  -- implement slave model software accessible register(s)
  WriteSlaveRegisterProcess : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        msigenmanual <= '0';
        --slv_reg0 <= (others => '0');
      else

        -- maak het mogelijk de sampler te resetten
        if slv_reg0(2)='1' then
          slv_reg0(29) <= '0';
        else
          slv_reg0(29) <= (slv_reg0(29) or fifo_full);
        end if;

        case current_xfer_state is
          when XFER_IDLE                    => slv_reg0(21 to 23) <= "000";
          when XFER_WAIT_DATA               => slv_reg0(21 to 23) <= "001";
          when XFER_WAIT_DMA_INTERRUPT      => slv_reg0(21 to 23) <= "010";
          when XFER_WAIT_DMA_RESET          => slv_reg0(21 to 23) <= "100";
          when others                       => slv_reg0(21 to 23) <= "111";
        end case;

        slv_reg0(4 to 19) <= std_logic_vector(to_unsigned(nr_in_fifo,16));

        case slv_reg_write_sel is
          when "10000" =>
            -- dit zijn de BOVENSTE bits!
            -- bit 31: 1=sampler enable, 0=sampler disable
            slv_reg0(0) <= Bus2IP_Data(0);
            -- bit 30: 1=force DMA transfer
            slv_reg0(1) <= Bus2IP_Data(1);
            -- bit 29: 1=reset sampler
            slv_reg0(2) <= Bus2IP_Data(2);

          when others => null;
        end case;
      end if;
    end if;

  end process WriteSlaveRegisterProcess;
  sampler_enable <= slv_reg0(0);
        slv_reg0(31) <= arbiterff_full;
        slv_reg0(30) <= arbiterff_empty;

        slv_reg0(28) <= fifo_full;
        slv_reg0(27) <= fifo_empty;
        slv_reg0(26) <= sram_full;
        slv_reg0(25) <= sram_empty;



IsolationProcess : process(sampler_clk, Bus2IP_Reset) is
begin
  if Bus2IP_Reset='1' then
    isolation <= (others => '0');
  elsif rising_edge(sampler_clk) then
    isolation <= "010101";
  end if;
end process IsolationProcess;





ForcedTransferProcess : process(arbiter_clk) is
begin
  if rising_edge(arbiter_clk) then

    if reset_arbiter='1' then
      current_xfer_force_state <= XFER_FORCE_IDLE;
      forced_transfer <= '0';
    end if;

    if reset_arbiter_inv='1' then
      forced_transfer <= '0';

      case current_xfer_force_state is
        when XFER_FORCE_IDLE =>
          if slv_reg0(1)='1' then
            forced_transfer <= '1';
            current_xfer_force_state <= XFER_FORCE_DONE;
          else
            current_xfer_force_state <= XFER_FORCE_IDLE;
          end if;

        when XFER_FORCE_DONE =>
          if slv_reg0(1)='0' then
            current_xfer_force_state <= XFER_FORCE_IDLE;
          else
            current_xfer_force_state <= XFER_FORCE_DONE;
          end if;

        when others =>
          current_xfer_force_state <= XFER_FORCE_IDLE;
      end case;

    end if;

  end if;
end process ForcedTransferProcess;






ResetMultiplexerProcess : process(arbiter_clk) is
begin
  if rising_edge(arbiter_clk) then
    reset_sram <= Bus2IP_Reset;
    reset_sram_inv <= not(Bus2IP_Reset);

    reset_arbiter <= Bus2IP_Reset;
    reset_arbiter_inv <= not(Bus2IP_Reset);

    reset_sampler <= Bus2IP_Reset;
    reset_sampler_inv <= not(Bus2IP_Reset);

    reset_fifo <= Bus2IP_Reset;
    reset_msi <= Bus2IP_Reset;
    reset_component <= Bus2IP_Reset;
  end if;
end process ResetMultiplexerProcess;





  SamplerFifoFullProcess : process(arbiter_clk, reset_fifo) is
  begin
    if reset_fifo='1' then
      fifo_full_buffer <= '0';
    elsif rising_edge(arbiter_clk) then
      fifo_full_buffer <= fifo_full_buffer or fifo_full;
    end if;
  end process SamplerFifoFullProcess;





-- Ervan uit gaande dat de sampler geklokt is op 100 MHz,
-- genereren we een input dat aan 100 kHz verandert.
GenerateSlowSamplerInputProcess: process(sampler_clk, Bus2IP_Reset) is
  variable counter : integer range 0 to 10000;
  variable datavalue : integer range 0 to 127;
begin
  if Bus2IP_Reset='1' then
    counter := 0;
    temp_sampler_input <= (others => '0');
  elsif falling_edge(sampler_clk) and sampler_enable='1' then
    counter := counter+1;

    if counter=25 then
      counter := 0;

      if datavalue=126 then
        datavalue := 0;
      else
        datavalue := datavalue+1;
      end if;

      temp_sampler_input <= std_logic_vector(to_unsigned(datavalue, temp_sampler_input'length));
    end if;
  end if;
end process GenerateSlowSamplerInputProcess;









fifo_arbiter_clk <= not(arbiter_clk);
fifo_sampler_clk <= not(sampler_clk);

-- arbiter FIFO
arbiterff_rdclk <= not(Bus2IP_Clk);
arbiterff_wrclk <= not(arbiter_clk);



-- ############################################################################
-- PROCESS: Read from FIFO to PLB
--
--
ReadArbiterFifoProcess : process(Bus2IP_Clk, reset_fifo) is
begin

  if reset_fifo='1' then
    --plbfifo_databuf <= (others => '0');
    --plbfifo_rdackbuf <= '0';

    --arbiterff_output <= (others => '0');
    arbiterff_rdack <= '0';

    --IP2Bus_Error <= '0';

    arbiterff_rde <= '0';

  elsif rising_edge(Bus2IP_Clk) then

    arbiterff_rdack <= '0';
    arbiterff_rde <= '0';

    -- drive data lines if selected
    -- TODO: dit zorgt ervoor dat enkel DMA mogelijk is!!!
    if slv_reg_read_sel="01000" and Bus2IP_Burst='1' then

      if arbiterff_valid='1' then
        arbiterff_rde <= '1';
        arbiterff_output <= arbiterff_dout;
        arbiterff_rdack <= '1';
      else
        arbiterff_rde <= '1';
        arbiterff_output <= (others => '1');
        arbiterff_rdack <= '1';
      end if;
    end if;

  end if;

end process ReadArbiterFifoProcess;



-- ############################################################################
-- PROCESS: Read slave register
--  Implement a read multiplexer for the slave registers.
--
ReadSlaveRegisterProcess : process(slv_reg_read_sel, slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4) is
begin
    case slv_reg_read_sel is
      when "10000"  => slv_ip2bus_data <= slv_reg0;
      -- slv_reg1 wordt gebruikt als FIFO
      when "00100"  => slv_ip2bus_data <= slv_reg2;
      when "00010"  => slv_ip2bus_data <= slv_reg3;
      when "00001"  => slv_ip2bus_data <= slv_reg4;
      when others   => slv_ip2bus_data <= (others => '0');
    end case;

end process ReadSlaveRegisterProcess;

-- ############################################################################
-- PROCESS: Generate MSI Interrupt
--  Drive the MSI_Request signal of the PCI-Express bridge.
--
--  Clock: PLB-bus; reason: MSI must be transported over PLB, and has to be high
--                          for at least 2 cycles.
GenerateMsiProcess: process(reset_msi, Bus2IP_Clk) is
  variable counter : integer range 0 to 10;
begin
  if reset_msi='1' then
    msireq_buf1 <= '0';
    msireq_buf2 <= '0';
    msi_request <= '0';
    requestmsi <= '0';

  elsif rising_edge(Bus2IP_Clk) then

    msireq_buf1 <= msigen;
    msireq_buf2 <= msireq_buf1;

    msi_request <= msigen or msireq_buf1 or msireq_buf2;
    requestmsi <= msigen or msireq_buf1 or msireq_buf2;

  end if;
end process GenerateMsiProcess;

-- ############################################################################
-- PROCESS: DMA Block Transfer
--  Finite State Machine to control the DMA transfers between the FPGA and the PC.
--
--  Clock: arbiter; reason: Data is written to the read fifo at the frequency of
--                          the arbiter. The state machine should react at the
--                          frequency of the arbiter.
DataTransferProcess : process(reset_msi, arbiter_clk) is
begin
  if reset_msi='1' then
    msigen <= '0';
    current_xfer_state <= XFER_IDLE;
    msigen2 <= '0';
    subtract_from_fifo <= '0';

  elsif rising_edge(arbiter_clk) then
    subtract_from_fifo <= '0';

    case current_xfer_state is
      when XFER_IDLE =>
        -- STATE 0: Idle until user enables the sampler.

        -- Deze state is nodig om uit reset conditie te komen.
        -- Als we niet controleren of de sampler al dan niet ingeschakeld is,
        -- en meteen naar XFER_WAIT_DATA overgaan, dan wordt er al een MSI
        -- gegenereerd nog voor er data is. Vermoedelijk komt arbiterff_full
        -- even hoog als we uit reset komen.
        msigen <= '0';

        if sampler_enable='1' then
          current_xfer_state <= XFER_WAIT_DATA;
        else
          current_xfer_state <= XFER_IDLE;
        end if;

      when XFER_WAIT_DATA =>
        -- State 1: Wait for data to be present in the buffer.

        -- Wait for the PLB Read FIFO to fill up with data.
        -- When it is full, let the PC know that data is available for transfer.

        if (nr_in_fifo>=C_DMA_LENGTH or forced_transfer='1') and requestmsi='0' then
          -- When the FIFO is full, send an MSI interrupt to request a DMA transfer.
          -- Also change states: start waiting for the DMA transfer to complete.
          msigen <= '1';
          current_xfer_state <= XFER_WAIT_DMA_INTERRUPT;

        else
          -- Keep waiting when no data is available.
          current_xfer_state <= XFER_WAIT_DATA;
        end if;

      when XFER_WAIT_DMA_INTERRUPT =>
        -- State 2: Wait for the DMA controller to raise it's completion interrupt.
        if requestmsi='1' then
          msigen <= '0';
        end if;

        -- Wait for the DMA transfer to be completed.
        -- When it is completed, let the PC know that the DMA controller is done.

        if dma_interrupt='1' and requestmsi='0' then
          -- When the DMA transfer is complete, send an MSI interrupt to
          -- let the PC know. Also change states: wait untill the PC confirms it.
          msigen <= '1';
          subtract_from_fifo <= '1';
          current_xfer_state <= XFER_WAIT_DMA_RESET;

        else
          -- Keep waiting for the DMA transfer to complete.
          current_xfer_state <= XFER_WAIT_DMA_INTERRUPT;
        end if;

      when XFER_WAIT_DMA_RESET =>
        -- State 3: Wait for the DMA controller to be reset by the PC.
        subtract_from_fifo <= '0';

        if requestmsi='1' then
          msigen <= '0';
        end if;

        -- Wait for the PC to acknowledge the DMA completion.
        -- The PC does so by resetting the DMA controller, which in turn
        -- lowers the interrupt line.

        if dma_interrupt='0' and requestmsi='0' then
          -- When the interrupt line is low, the PC has successfully resetted the
          -- DMA controller, start waiting for data again.
          --msigen <= '1';
          current_xfer_state <= XFER_WAIT_DATA;

        else
          -- Keep waiting for the PC to reset the DMA controller.
          current_xfer_state <= XFER_WAIT_DMA_RESET;
        end if;

      when others =>
        -- Generally speaking, this state should never be reached.
        -- When it does get activated, just start waiting for the FIFO to fill up.
        current_xfer_state <= XFER_IDLE;
    end case;
  end if;
end process DataTransferProcess;

-- ############################################################################
-- PROCESS: Write to PLB FIFO
--  Writes the data on the SRAM databus to the PLB Read FIFO when it is available.
--
--  Clock: arbiter; reason: Obvious.
WriteArbiterFifoProcess : process(arbiter_clk, reset_fifo) is
  variable fifocounttemp : integer range 0 to C_FIFO_DEPTH+1;
begin
  if reset_fifo='1' then
    arbiterff_wre <= '0';
    --arbiterff_din <= (others => '0');
    nr_in_fifo <= 0;

  elsif rising_edge(arbiter_clk) then
    -- Default values
    arbiterff_wre <= '0';
    arbiterff_din <= (others => '0');
    fifocounttemp := nr_in_fifo;

    if ctrl_ready='1' and arbiterff_full='0' then
      -- The SRAM controller tells us that the data on the output bus is valid.
      -- Write it to the PLB FIFO by bringing WRITE REQUEST high.
      arbiterff_wre <= '1';
      arbiterff_din <= ctrl_out;

      fifocounttemp := fifocounttemp+1;
    end if;

    if subtract_from_fifo='1' and nr_in_fifo>=C_DMA_LENGTH then
      nr_in_fifo <= fifocounttemp-C_DMA_LENGTH;
    elsif subtract_from_fifo='1' then
      nr_in_fifo <= fifocounttemp-nr_in_fifo;
    else
      nr_in_fifo <= fifocounttemp;
    end if;

  end if;
end process WriteArbiterFifoProcess;

-- ############################################################################
-- PROCESS: Arbiter
--  Links the sampler output FIFO, the PLB read FIFO and the SRAM memory
--
--  Clock: arbiter; reason: Obvious.
ArbiterProcess : process(arbiter_clk) is
  -- Holds the action to be ordered from the SRAM controller:
  --  READ, WRITE or IDLE.
  variable current_state        : sram_ctrl_state_type := CTRL_IDLE;

  -- Used in part 1, to determine which actions are possible:
  --  FIFO (sampler) to SRAM, SRAM to FIFO (PLB-bus)
  variable possible_fifo2sram   : std_logic;
  variable possible_sram2buffer : std_logic;

  -- Read and write pointers.
  --  The read pointer contains address from which the next value will be read.
  --  The write pointer contains the address to which the next value will be written.
  variable rd_address           : integer range 0 to C_MAX_SRAM_ADDRESS;
  variable wr_address           : integer range 0 to C_MAX_SRAM_ADDRESS;

  -- Number of samples between the read and write pointers.
  --  When this distance is zero, no samples are ready to be read.
  --  When this distance is C_MAX_SRAM_SAMPLES, no samples can be written anymore.
  variable rwdistance           : integer range 0 to C_MAX_SRAM_SAMPLES;

begin

  if rising_edge(arbiter_clk) then



  if reset_arbiter='1' then
    current_state         := CTRL_IDLE;

    ctrl_read             <= '0';
    ctrl_write            <= '0';
    ctrl_expecting_read   <= '0';

    fifo_rde              <= '0';

    rd_address            := 0;
    wr_address            := 0;

    rwdistance            := 0;
  end if;

  if reset_arbiter_inv='1' then



    ---------------------------------------------------------------------------
    -- PART 0: Default values
    ctrl_burst            <= '0';

    ctrl_read             <= '0';
    ctrl_write            <= '0';
    ctrl_address          <= (others => '0');

    ctrl_in               <= (others => '0');
    ctrl_expecting_read   <= '0';

    fifo_rde              <= '0';

    possible_sram2buffer  := '0';
    possible_fifo2sram    := '0';

    if rwdistance=0 then
      sram_empty <= '1';
    else
      sram_empty <= '0';
    end if;

    if rwdistance=C_MAX_SRAM_SAMPLES then
      sram_full <= '1';
    else
      sram_full <= '0';
    end if;

    ---------------------------------------------------------------------------
    -- PART 1: Arbiter logic
    if rwdistance/=0 and nr_in_fifo<C_FIFO_DEPTH-10 then
      possible_sram2buffer := '1';
    end if;

    if rwdistance<C_MAX_SRAM_SAMPLES and fifo_valid='1' then
      possible_fifo2sram := '1';
    end if;

    if possible_sram2buffer='1' and possible_fifo2sram='1' then
      -- zowel lezen van als schrijven naar SRAM mogelijk
      if current_state=CTRL_WRITING then
        -- vorige cyclus geschreven van sampler FIFO naar SRAM,
        -- lees nu een waarde van SRAM.
        current_state := CTRL_READING;
      else
        -- vorige cyclus ofwel IDLE ofwel gelezen,
        -- schrijf nu een waarde naar SRAM.
        current_state := CTRL_WRITING;
      end if;
    elsif possible_sram2buffer='1' then
      -- enkel mogelijk van SRAM naar arbiter FIFO
      current_state := CTRL_READING;
    elsif possible_fifo2sram='1' then
      -- enkel mogelijk van sampler FIFO naar SRAM
      current_state := CTRL_WRITING;
    else
      -- geen enkele actie mogelijk
      current_state := CTRL_IDLE;
    end if;


    ---------------------------------------------------------------------------
    -- PART 2: SRAM control signal driving

    case current_state is
      when CTRL_IDLE =>
        -- IDLE state
        --  Don't do anything.
        --
        --  Reset the burst counters.
        --burst_rd            := 0;
        --burst_wr            := 0;

      when CTRL_READING =>
        -- READ state
        --  Issue a read command to the SRAM controller.
        --
        --  Due to data coming from there (after some cycles),
        --  it is not possible to immediatly issue a WRITE command after this.
        --  The cause lies in the fact that a bidirectional bus is used to
        --  communicate with the SRAM memory.
        --
        --  Setting 'ctrl_expecting_read' high prevents the logic above from
        --  issueing a WRITE command right after a READ command has been executed.
        ctrl_read           <= '1';
        ctrl_address        <= std_logic_vector(to_unsigned(rd_address, ctrl_address'length));

        --  Increase the read address pointer.
        --  Decrease the distance between the last written and the last read sample.
        rd_address          := rd_address+C_SAMPLE_SIZE;
        rwdistance          := rwdistance-1;

      when CTRL_WRITING =>
        -- WRITE state
        --  Issue a write command to the SRAM controller.
        --
        --  The FIFO is a FWFT-FIFO (First Word Fall-Through).
        --  This means that new data is ready to be read, and the next data will be
        --  put on the output bus by bringing the READ-ENABLE signal high.
        ctrl_write          <= '1';
        ctrl_address        <= std_logic_vector(to_unsigned(wr_address, ctrl_address'length));
        ctrl_in             <= fifo_output;
        fifo_rde            <= '1';

        -- Increase the write address pointer (add number of bytes per sample).
        -- Increase the distance between the last written and the last read sample.
        wr_address          := wr_address+C_SAMPLE_SIZE;
        rwdistance          := rwdistance+1;

      when others =>
        -- OTHER states
        --  We should not get here in the first place, but when we do,
        --  just change to the IDLE state.
        current_state       := CTRL_IDLE;

    end case;
  end if;
  end if;
end process ArbiterProcess;

IP2Bus_Data  <= arbiterff_output when arbiterff_rdack='1' else
                slv_ip2bus_data when slv_read_ack = '1' else
                (others => '0');
IP2Bus_WrAck <= slv_write_ack;
IP2Bus_RdAck <= slv_read_ack or arbiterff_rdack;
IP2Bus_Error <= '0';

end IMP;
