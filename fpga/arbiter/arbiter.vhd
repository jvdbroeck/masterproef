------------------------------------------------------------------------------
-- arbiter.vhd - entity/architecture pair
------------------------------------------------------------------------------
-- IMPORTANT:
-- DO NOT MODIFY THIS FILE EXCEPT IN THE DESIGNATED SECTIONS.
--
-- SEARCH FOR --USER TO DETERMINE WHERE CHANGES ARE ALLOWED.
--
-- TYPICALLY, THE ONLY ACCEPTABLE CHANGES INVOLVE ADDING NEW
-- PORTS AND GENERICS THAT GET PASSED THROUGH TO THE INSTANTIATION
-- OF THE USER_LOGIC ENTITY.
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
-- Filename:          arbiter.vhd
-- Version:           1.00.a
-- Description:       Top level design, instantiates library components and user logic.
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;
use proc_common_v3_00_a.ipif_pkg.all;

library rdpfifo_v4_02_a;
use rdpfifo_v4_02_a.rdpfifo_top;

library plbv46_slave_burst_v1_01_a;
use plbv46_slave_burst_v1_01_a.plbv46_slave_burst;

library plbv46_master_single_v1_01_a;
use plbv46_master_single_v1_01_a.plbv46_master_single;

library arbiter_v1_00_a;
use arbiter_v1_00_a.user_logic;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_BASEADDR                   -- PLBv46 slave: base address
--   C_HIGHADDR                   -- PLBv46 slave: high address
--   C_SPLB_AWIDTH                -- PLBv46 slave: address bus width
--   C_SPLB_DWIDTH                -- PLBv46 slave: data bus width
--   C_SPLB_NUM_MASTERS           -- PLBv46 slave: Number of masters
--   C_SPLB_MID_WIDTH             -- PLBv46 slave: master ID bus width
--   C_SPLB_NATIVE_DWIDTH         -- PLBv46 slave: internal native data bus width
--   C_SPLB_P2P                   -- PLBv46 slave: point to point interconnect scheme
--   C_SPLB_SUPPORT_BURSTS        -- PLBv46 slave: support bursts
--   C_SPLB_SMALLEST_MASTER       -- PLBv46 slave: width of the smallest master
--   C_SPLB_CLK_PERIOD_PS         -- PLBv46 slave: bus clock in picoseconds
--   C_INCLUDE_DPHASE_TIMER       -- PLBv46 slave: Data Phase Timer configuration; 0 = exclude timer, 1 = include timer
--   C_FAMILY                     -- Xilinx FPGA family
--   C_MPLB_AWIDTH                -- PLBv46 master: address bus width
--   C_MPLB_DWIDTH                -- PLBv46 master: data bus width
--   C_MPLB_NATIVE_DWIDTH         -- PLBv46 master: internal native data width
--   C_MPLB_P2P                   -- PLBv46 master: point to point interconnect scheme
--   C_MPLB_SMALLEST_SLAVE        -- PLBv46 master: width of the smallest slave
--   C_MPLB_CLK_PERIOD_PS         -- PLBv46 master: bus clock in picoseconds
--   C_MEM0_BASEADDR              -- User memory space 0 base address
--   C_MEM0_HIGHADDR              -- User memory space 0 high address
--
-- Definition of Ports:
--   SPLB_Clk                     -- PLB main bus clock
--   SPLB_Rst                     -- PLB main bus reset
--   PLB_ABus                     -- PLB address bus
--   PLB_UABus                    -- PLB upper address bus
--   PLB_PAValid                  -- PLB primary address valid indicator
--   PLB_SAValid                  -- PLB secondary address valid indicator
--   PLB_rdPrim                   -- PLB secondary to primary read request indicator
--   PLB_wrPrim                   -- PLB secondary to primary write request indicator
--   PLB_masterID                 -- PLB current master identifier
--   PLB_abort                    -- PLB abort request indicator
--   PLB_busLock                  -- PLB bus lock
--   PLB_RNW                      -- PLB read/not write
--   PLB_BE                       -- PLB byte enables
--   PLB_MSize                    -- PLB master data bus size
--   PLB_size                     -- PLB transfer size
--   PLB_type                     -- PLB transfer type
--   PLB_lockErr                  -- PLB lock error indicator
--   PLB_wrDBus                   -- PLB write data bus
--   PLB_wrBurst                  -- PLB burst write transfer indicator
--   PLB_rdBurst                  -- PLB burst read transfer indicator
--   PLB_wrPendReq                -- PLB write pending bus request indicator
--   PLB_rdPendReq                -- PLB read pending bus request indicator
--   PLB_wrPendPri                -- PLB write pending request priority
--   PLB_rdPendPri                -- PLB read pending request priority
--   PLB_reqPri                   -- PLB current request priority
--   PLB_TAttribute               -- PLB transfer attribute
--   Sl_addrAck                   -- Slave address acknowledge
--   Sl_SSize                     -- Slave data bus size
--   Sl_wait                      -- Slave wait indicator
--   Sl_rearbitrate               -- Slave re-arbitrate bus indicator
--   Sl_wrDAck                    -- Slave write data acknowledge
--   Sl_wrComp                    -- Slave write transfer complete indicator
--   Sl_wrBTerm                   -- Slave terminate write burst transfer
--   Sl_rdDBus                    -- Slave read data bus
--   Sl_rdWdAddr                  -- Slave read word address
--   Sl_rdDAck                    -- Slave read data acknowledge
--   Sl_rdComp                    -- Slave read transfer complete indicator
--   Sl_rdBTerm                   -- Slave terminate read burst transfer
--   Sl_MBusy                     -- Slave busy indicator
--   Sl_MWrErr                    -- Slave write error indicator
--   Sl_MRdErr                    -- Slave read error indicator
--   Sl_MIRQ                      -- Slave interrupt indicator
--   MPLB_Clk                     -- PLB main bus Clock
--   MPLB_Rst                     -- PLB main bus Reset
--   MD_error                     -- Master detected error status output
--   M_request                    -- Master request
--   M_priority                   -- Master request priority
--   M_busLock                    -- Master buslock
--   M_RNW                        -- Master read/nor write
--   M_BE                         -- Master byte enables
--   M_MSize                      -- Master data bus size
--   M_size                       -- Master transfer size
--   M_type                       -- Master transfer type
--   M_TAttribute                 -- Master transfer attribute
--   M_lockErr                    -- Master lock error indicator
--   M_abort                      -- Master abort bus request indicator
--   M_UABus                      -- Master upper address bus
--   M_ABus                       -- Master address bus
--   M_wrDBus                     -- Master write data bus
--   M_wrBurst                    -- Master burst write transfer indicator
--   M_rdBurst                    -- Master burst read transfer indicator
--   PLB_MAddrAck                 -- PLB reply to master for address acknowledge
--   PLB_MSSize                   -- PLB reply to master for slave data bus size
--   PLB_MRearbitrate             -- PLB reply to master for bus re-arbitrate indicator
--   PLB_MTimeout                 -- PLB reply to master for bus time out indicator
--   PLB_MBusy                    -- PLB reply to master for slave busy indicator
--   PLB_MRdErr                   -- PLB reply to master for slave read error indicator
--   PLB_MWrErr                   -- PLB reply to master for slave write error indicator
--   PLB_MIRQ                     -- PLB reply to master for slave interrupt indicator
--   PLB_MRdDBus                  -- PLB reply to master for read data bus
--   PLB_MRdWdAddr                -- PLB reply to master for read word address
--   PLB_MRdDAck                  -- PLB reply to master for read data acknowledge
--   PLB_MRdBTerm                 -- PLB reply to master for terminate read burst indicator
--   PLB_MWrDAck                  -- PLB reply to master for write data acknowledge
--   PLB_MWrBTerm                 -- PLB reply to master for terminate write burst indicator
------------------------------------------------------------------------------

entity arbiter is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_BASEADDR                     : std_logic_vector     := X"FFFFFFFF";
    C_HIGHADDR                     : std_logic_vector     := X"00000000";
    C_SPLB_AWIDTH                  : integer              := 32;
    C_SPLB_DWIDTH                  : integer              := 128;
    C_SPLB_NUM_MASTERS             : integer              := 8;
    C_SPLB_MID_WIDTH               : integer              := 3;
    C_SPLB_NATIVE_DWIDTH           : integer              := 32;
    C_SPLB_P2P                     : integer              := 0;
    C_SPLB_SUPPORT_BURSTS          : integer              := 1;
    C_SPLB_SMALLEST_MASTER         : integer              := 32;
    C_SPLB_CLK_PERIOD_PS           : integer              := 10000;
    C_INCLUDE_DPHASE_TIMER         : integer              := 1;
    C_FAMILY                       : string               := "virtex6";
    C_MPLB_AWIDTH                  : integer              := 32;
    C_MPLB_DWIDTH                  : integer              := 128;
    C_MPLB_NATIVE_DWIDTH           : integer              := 32;
    C_MPLB_P2P                     : integer              := 0;
    C_MPLB_SMALLEST_SLAVE          : integer              := 32;
    C_MPLB_CLK_PERIOD_PS           : integer              := 10000;
    C_MEM0_BASEADDR                : std_logic_vector     := X"FFFFFFFF";
    C_MEM0_HIGHADDR                : std_logic_vector     := X"00000000"
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

    -- ARITER
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
    dma_interrupt                  : in std_logic;

    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    SPLB_Clk                       : in  std_logic;
    SPLB_Rst                       : in  std_logic;
    PLB_ABus                       : in  std_logic_vector(0 to 31);
    PLB_UABus                      : in  std_logic_vector(0 to 31);
    PLB_PAValid                    : in  std_logic;
    PLB_SAValid                    : in  std_logic;
    PLB_rdPrim                     : in  std_logic;
    PLB_wrPrim                     : in  std_logic;
    PLB_masterID                   : in  std_logic_vector(0 to C_SPLB_MID_WIDTH-1);
    PLB_abort                      : in  std_logic;
    PLB_busLock                    : in  std_logic;
    PLB_RNW                        : in  std_logic;
    PLB_BE                         : in  std_logic_vector(0 to C_SPLB_DWIDTH/8-1);
    PLB_MSize                      : in  std_logic_vector(0 to 1);
    PLB_size                       : in  std_logic_vector(0 to 3);
    PLB_type                       : in  std_logic_vector(0 to 2);
    PLB_lockErr                    : in  std_logic;
    PLB_wrDBus                     : in  std_logic_vector(0 to C_SPLB_DWIDTH-1);
    PLB_wrBurst                    : in  std_logic;
    PLB_rdBurst                    : in  std_logic;
    PLB_wrPendReq                  : in  std_logic;
    PLB_rdPendReq                  : in  std_logic;
    PLB_wrPendPri                  : in  std_logic_vector(0 to 1);
    PLB_rdPendPri                  : in  std_logic_vector(0 to 1);
    PLB_reqPri                     : in  std_logic_vector(0 to 1);
    PLB_TAttribute                 : in  std_logic_vector(0 to 15);
    Sl_addrAck                     : out std_logic;
    Sl_SSize                       : out std_logic_vector(0 to 1);
    Sl_wait                        : out std_logic;
    Sl_rearbitrate                 : out std_logic;
    Sl_wrDAck                      : out std_logic;
    Sl_wrComp                      : out std_logic;
    Sl_wrBTerm                     : out std_logic;
    Sl_rdDBus                      : out std_logic_vector(0 to C_SPLB_DWIDTH-1);
    Sl_rdWdAddr                    : out std_logic_vector(0 to 3);
    Sl_rdDAck                      : out std_logic;
    Sl_rdComp                      : out std_logic;
    Sl_rdBTerm                     : out std_logic;
    Sl_MBusy                       : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MWrErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MRdErr                      : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    Sl_MIRQ                        : out std_logic_vector(0 to C_SPLB_NUM_MASTERS-1);
    PLB_MAddrAck                   : in  std_logic;
    PLB_MSSize                     : in  std_logic_vector(0 to 1);
    PLB_MRearbitrate               : in  std_logic;
    PLB_MTimeout                   : in  std_logic;
    PLB_MBusy                      : in  std_logic;
    PLB_MRdErr                     : in  std_logic;
    PLB_MWrErr                     : in  std_logic;
    PLB_MIRQ                       : in  std_logic;
    PLB_MRdDBus                    : in  std_logic_vector(0 to (C_MPLB_DWIDTH-1));
    PLB_MRdWdAddr                  : in  std_logic_vector(0 to 3);
    PLB_MRdDAck                    : in  std_logic;
    PLB_MRdBTerm                   : in  std_logic;
    PLB_MWrDAck                    : in  std_logic;
    PLB_MWrBTerm                   : in  std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of SPLB_Clk      : signal is "CLK";
  attribute SIGIS of SPLB_Rst      : signal is "RST";

end entity arbiter;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of arbiter is

  ------------------------------------------
  -- Array of base/high address pairs for each address range
  ------------------------------------------
  constant ZERO_ADDR_PAD                  : std_logic_vector(0 to 31) := (others => '0');
  constant USER_SLV_BASEADDR              : std_logic_vector     := C_BASEADDR or X"00000000";
  constant USER_SLV_HIGHADDR              : std_logic_vector     := C_BASEADDR or X"000000FF";
  constant USER_MST_BASEADDR              : std_logic_vector     := C_BASEADDR or X"00000100";
  constant USER_MST_HIGHADDR              : std_logic_vector     := C_BASEADDR or X"000001FF";
  constant RFF_REG_BASEADDR               : std_logic_vector     := C_BASEADDR or X"00000200";
  constant RFF_REG_HIGHADDR               : std_logic_vector     := C_BASEADDR or X"000002FF";
  constant RFF_DAT_BASEADDR               : std_logic_vector     := C_BASEADDR or X"00000300";
  constant RFF_DAT_HIGHADDR               : std_logic_vector     := C_BASEADDR or X"000003FF";

  constant IPIF_ARD_ADDR_RANGE_ARRAY      : SLV64_ARRAY_TYPE     :=
    (
      ZERO_ADDR_PAD & USER_SLV_BASEADDR,  -- user logic slave space base address
      ZERO_ADDR_PAD & USER_SLV_HIGHADDR,  -- user logic slave space high address
      ZERO_ADDR_PAD & USER_MST_BASEADDR,  -- user logic master space base address
      ZERO_ADDR_PAD & USER_MST_HIGHADDR,  -- user logic master space high address
      ZERO_ADDR_PAD & RFF_REG_BASEADDR,   -- read pfifo register space base address
      ZERO_ADDR_PAD & RFF_REG_HIGHADDR,   -- read pfifo register space high address
      ZERO_ADDR_PAD & RFF_DAT_BASEADDR,   -- read pfifo data space base address
      ZERO_ADDR_PAD & RFF_DAT_HIGHADDR,   -- read pfifo data space high address
      ZERO_ADDR_PAD & C_MEM0_BASEADDR,    -- user logic memory space 0 base address
      ZERO_ADDR_PAD & C_MEM0_HIGHADDR     -- user logic memory space 0 high address
    );

  ------------------------------------------
  -- Array of desired number of chip enables for each address range
  ------------------------------------------
  constant USER_SLV_NUM_REG               : integer              := 5;
  constant USER_MST_NUM_REG               : integer              := 4;
  constant USER_NUM_REG                   : integer              := USER_SLV_NUM_REG+USER_MST_NUM_REG;
  constant RFF_NUM_REG_CE                 : integer              := 4;
  constant RFF_NUM_DAT_CE                 : integer              := 1;
  constant USER_NUM_MEM                   : integer              := 1;

  constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   :=
    (
      0  => pad_power2(USER_SLV_NUM_REG), -- number of ce for user logic slave space
      1  => pad_power2(USER_MST_NUM_REG), -- number of ce for user logic master space
      2  => RFF_NUM_REG_CE,               -- number of ce for read pfifo register space
      3  => RFF_NUM_DAT_CE,               -- number of ce for read pfifo data space
      4  => 1                             -- number of ce for user logic memory space 0 (always 1 chip enable)
    );

  ------------------------------------------
  -- Cache line addressing mode (for cacheline read operations)
  -- 0 = target word first on reads
  -- 1 = line word first on reads
  ------------------------------------------
  constant IPIF_CACHLINE_ADDR_MODE        : integer              := 0;

  ------------------------------------------
  -- Number of storage locations for the write buffer
  -- Valid depths are 0, 16, 32, or 64
  -- 0 = no write buffer implemented
  ------------------------------------------
  constant IPIF_WR_BUFFER_DEPTH           : integer              := 64;

  ------------------------------------------
  -- The type out of the Bus2IP_BurstLength signal
  -- 0 = length is in actual byte number
  -- 1 = length is in data beats - 1
  ------------------------------------------
  constant IPIF_BURSTLENGTH_TYPE          : integer              := 0;

  ------------------------------------------
  -- Ratio of bus clock to core clock (for use in dual clock systems)
  -- 1 = ratio is 1:1
  -- 2 = ratio is 2:1
  ------------------------------------------
  constant IPIF_BUS2CORE_CLK_RATIO        : integer              := 1;

  ------------------------------------------
  -- Width of the slave data bus (32 only)
  ------------------------------------------
  constant USER_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  constant IPIF_SLV_DWIDTH                : integer              := C_SPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Width of the master data bus (32 only)
  ------------------------------------------
  constant USER_MST_DWIDTH                : integer              := C_MPLB_NATIVE_DWIDTH;

  constant IPIF_MST_DWIDTH                : integer              := C_MPLB_NATIVE_DWIDTH;

  ------------------------------------------
  -- Read FIFO desired depth specified as a Log2(x) value (2 to 14)
  ------------------------------------------
  constant USER_RDFIFO_DEPTH              : integer              := 4096;

  constant RFF_FIFO_DEPTH_LOG2X           : integer              := log2(USER_RDFIFO_DEPTH);

  ------------------------------------------
  -- Read FIFO packet mode feature inclusion/omision
  -- true  = include packet mode features
  -- false = omit packet mode features
  ------------------------------------------
  constant RFF_INCLUDE_PACKET_MODE        : boolean              := true;

  ------------------------------------------
  -- Read FIFO vacancy calculation inclusion/omision
  -- true  = include vacancy calculation
  -- false = omit vacancy calculation
  ------------------------------------------
  constant RFF_INCLUDE_VACANCY            : boolean              := true;

  ------------------------------------------
  -- Read FIFO enable for host bus data burst support
  -- true  = support host bus data bursting
  -- false = do not support host bus data bursting
  ------------------------------------------
  constant RFF_SUPPORT_BURST              : boolean              := (C_SPLB_SUPPORT_BURSTS /= 0);

  ------------------------------------------
  -- Width of the slave address bus (32 only)
  ------------------------------------------
  constant USER_SLV_AWIDTH                : integer              := C_SPLB_AWIDTH;

  ------------------------------------------
  -- Width of the master address bus (32 only)
  ------------------------------------------
  constant USER_MST_AWIDTH                : integer              := C_MPLB_AWIDTH;

  ------------------------------------------
  -- Index for CS/CE
  ------------------------------------------
  constant USER_SLV_CS_INDEX              : integer              := 0;
  constant USER_SLV_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_SLV_CS_INDEX);
  constant USER_MST_CS_INDEX              : integer              := 1;
  constant USER_MST_CE_INDEX              : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, USER_MST_CS_INDEX);
  constant RFF_REG_CS_INDEX               : integer              := 2;
  constant RFF_REG_CE_INDEX               : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, RFF_REG_CS_INDEX);
  constant RFF_DAT_CS_INDEX               : integer              := 3;
  constant RFF_DAT_CE_INDEX               : integer              := calc_start_ce_index(IPIF_ARD_NUM_CE_ARRAY, RFF_DAT_CS_INDEX);
  constant USER_MEM0_CS_INDEX             : integer              := 4;
  constant USER_CS_INDEX                  : integer              := USER_MEM0_CS_INDEX;

  constant USER_CE_INDEX                  : integer              := USER_SLV_CE_INDEX;

  ------------------------------------------
  -- IP Interconnect (IPIC) signal declarations
  ------------------------------------------
  signal ipif_Bus2IP_Clk                : std_logic;
  signal ipif_Bus2IP_Reset              : std_logic;
  signal ipif_IP2Bus_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_IP2Bus_WrAck              : std_logic;
  signal ipif_IP2Bus_RdAck              : std_logic;
  signal ipif_IP2Bus_AddrAck            : std_logic;
  signal ipif_IP2Bus_Error              : std_logic;
  signal ipif_Bus2IP_Addr               : std_logic_vector(0 to C_SPLB_AWIDTH-1);
  signal ipif_Bus2IP_Data               : std_logic_vector(0 to IPIF_SLV_DWIDTH-1);
  signal ipif_Bus2IP_RNW                : std_logic;
  signal ipif_Bus2IP_BE                 : std_logic_vector(0 to IPIF_SLV_DWIDTH/8-1);
  signal ipif_Bus2IP_Burst              : std_logic;
  signal ipif_Bus2IP_BurstLength        : std_logic_vector(0 to log2(16*(C_SPLB_DWIDTH/8)));
  signal ipif_Bus2IP_WrReq              : std_logic;
  signal ipif_Bus2IP_RdReq              : std_logic;
  signal ipif_Bus2IP_CS                 : std_logic_vector(0 to ((IPIF_ARD_ADDR_RANGE_ARRAY'length)/2)-1);
  signal ipif_Bus2IP_RdCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_Bus2IP_WrCE               : std_logic_vector(0 to calc_num_ce(IPIF_ARD_NUM_CE_ARRAY)-1);
  signal ipif_IP2Bus_MstRd_Req          : std_logic;
  signal ipif_IP2Bus_MstWr_Req          : std_logic;
  signal ipif_IP2Bus_Mst_Addr           : std_logic_vector(0 to C_MPLB_AWIDTH-1);
  signal ipif_IP2Bus_Mst_BE             : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH/8-1);
  signal ipif_IP2Bus_Mst_Lock           : std_logic;
  signal ipif_IP2Bus_Mst_Reset          : std_logic;
  signal ipif_Bus2IP_Mst_CmdAck         : std_logic;
  signal ipif_Bus2IP_Mst_Cmplt          : std_logic;
  signal ipif_Bus2IP_Mst_Error          : std_logic;
  signal ipif_Bus2IP_Mst_Rearbitrate    : std_logic;
  signal ipif_Bus2IP_Mst_Cmd_Timeout    : std_logic;
  signal ipif_Bus2IP_MstRd_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_Bus2IP_MstRd_src_rdy_n    : std_logic;
  signal ipif_IP2Bus_MstWr_d            : std_logic_vector(0 to C_MPLB_NATIVE_DWIDTH-1);
  signal ipif_Bus2IP_MstWr_dst_rdy_n    : std_logic;
  signal user_Bus2IP_RdCE               : std_logic_vector(0 to USER_NUM_REG-1);
  signal user_Bus2IP_WrCE               : std_logic_vector(0 to USER_NUM_REG-1);
  signal user_Bus2IP_BurstLength        : std_logic_vector(0 to 8)   := (others => '0');
  signal user_IP2Bus_AddrAck            : std_logic;
  signal user_IP2Bus_Data               : std_logic_vector(0 to USER_SLV_DWIDTH-1);
  signal user_IP2Bus_RdAck              : std_logic;
  signal user_IP2Bus_WrAck              : std_logic;
  signal user_IP2Bus_Error              : std_logic;
  signal user_IP2RFIFO_WrReq            : std_logic;
  signal user_IP2RFIFO_Data             : std_logic_vector(0 to USER_SLV_DWIDTH-1);
  signal user_IP2RFIFO_WrMark           : std_logic;
  signal user_IP2RFIFO_WrRelease        : std_logic;
  signal user_IP2RFIFO_WrRestore        : std_logic;

begin

  ------------------------------------------
  -- instantiate plbv46_slave_burst
  ------------------------------------------
  PLBV46_SLAVE_BURST_I : entity plbv46_slave_burst_v1_01_a.plbv46_slave_burst
    generic map
    (
      C_ARD_ADDR_RANGE_ARRAY         => IPIF_ARD_ADDR_RANGE_ARRAY,
      C_ARD_NUM_CE_ARRAY             => IPIF_ARD_NUM_CE_ARRAY,
      C_SPLB_P2P                     => C_SPLB_P2P,
      C_CACHLINE_ADDR_MODE           => IPIF_CACHLINE_ADDR_MODE,
      C_WR_BUFFER_DEPTH              => IPIF_WR_BUFFER_DEPTH,
      C_BURSTLENGTH_TYPE             => IPIF_BURSTLENGTH_TYPE,
      C_SPLB_MID_WIDTH               => C_SPLB_MID_WIDTH,
      C_SPLB_NUM_MASTERS             => C_SPLB_NUM_MASTERS,
      C_SPLB_SMALLEST_MASTER         => C_SPLB_SMALLEST_MASTER,
      C_SPLB_AWIDTH                  => C_SPLB_AWIDTH,
      C_SPLB_DWIDTH                  => C_SPLB_DWIDTH,
      C_SIPIF_DWIDTH                 => IPIF_SLV_DWIDTH,
      C_INCLUDE_DPHASE_TIMER         => C_INCLUDE_DPHASE_TIMER,
      C_FAMILY                       => C_FAMILY
    )
    port map
    (
      SPLB_Clk                       => SPLB_Clk,
      SPLB_Rst                       => SPLB_Rst,
      PLB_ABus                       => PLB_ABus,
      PLB_UABus                      => PLB_UABus,
      PLB_PAValid                    => PLB_PAValid,
      PLB_SAValid                    => PLB_SAValid,
      PLB_rdPrim                     => PLB_rdPrim,
      PLB_wrPrim                     => PLB_wrPrim,
      PLB_masterID                   => PLB_masterID,
      PLB_abort                      => PLB_abort,
      PLB_busLock                    => PLB_busLock,
      PLB_RNW                        => PLB_RNW,
      PLB_BE                         => PLB_BE,
      PLB_MSize                      => PLB_MSize,
      PLB_size                       => PLB_size,
      PLB_type                       => PLB_type,
      PLB_lockErr                    => PLB_lockErr,
      PLB_wrDBus                     => PLB_wrDBus,
      PLB_wrBurst                    => PLB_wrBurst,
      PLB_rdBurst                    => PLB_rdBurst,
      PLB_wrPendReq                  => PLB_wrPendReq,
      PLB_rdPendReq                  => PLB_rdPendReq,
      PLB_wrPendPri                  => PLB_wrPendPri,
      PLB_rdPendPri                  => PLB_rdPendPri,
      PLB_reqPri                     => PLB_reqPri,
      PLB_TAttribute                 => PLB_TAttribute,
      Sl_addrAck                     => Sl_addrAck,
      Sl_SSize                       => Sl_SSize,
      Sl_wait                        => Sl_wait,
      Sl_rearbitrate                 => Sl_rearbitrate,
      Sl_wrDAck                      => Sl_wrDAck,
      Sl_wrComp                      => Sl_wrComp,
      Sl_wrBTerm                     => Sl_wrBTerm,
      Sl_rdDBus                      => Sl_rdDBus,
      Sl_rdWdAddr                    => Sl_rdWdAddr,
      Sl_rdDAck                      => Sl_rdDAck,
      Sl_rdComp                      => Sl_rdComp,
      Sl_rdBTerm                     => Sl_rdBTerm,
      Sl_MBusy                       => Sl_MBusy,
      Sl_MWrErr                      => Sl_MWrErr,
      Sl_MRdErr                      => Sl_MRdErr,
      Sl_MIRQ                        => Sl_MIRQ,
      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      IP2Bus_Data                    => ipif_IP2Bus_Data,
      IP2Bus_WrAck                   => ipif_IP2Bus_WrAck,
      IP2Bus_RdAck                   => ipif_IP2Bus_RdAck,
      IP2Bus_AddrAck                 => ipif_IP2Bus_AddrAck,
      IP2Bus_Error                   => ipif_IP2Bus_Error,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_Burst                   => ipif_Bus2IP_Burst,
      Bus2IP_BurstLength             => ipif_Bus2IP_BurstLength,
      Bus2IP_WrReq                   => ipif_Bus2IP_WrReq,
      Bus2IP_RdReq                   => ipif_Bus2IP_RdReq,
      Bus2IP_CS                      => ipif_Bus2IP_CS,
      Bus2IP_RdCE                    => ipif_Bus2IP_RdCE,
      Bus2IP_WrCE                    => ipif_Bus2IP_WrCE
    );

  ------------------------------------------
  -- instantiate User Logic
  ------------------------------------------
  USER_LOGIC_I : entity arbiter_v1_00_a.user_logic
    generic map
    (
      -- MAP USER GENERICS BELOW THIS LINE ---------------
      --USER generics mapped here
      -- MAP USER GENERICS ABOVE THIS LINE ---------------

      C_SLV_AWIDTH                   => USER_SLV_AWIDTH,
      C_SLV_DWIDTH                   => USER_SLV_DWIDTH,
      C_MST_AWIDTH                   => USER_MST_AWIDTH,
      C_MST_DWIDTH                   => USER_MST_DWIDTH,
      C_NUM_REG                      => USER_NUM_REG,
      C_NUM_MEM                      => USER_NUM_MEM
--      C_RDFIFO_DEPTH                 => USER_RDFIFO_DEPTH
    )
    port map
    (
      -- MAP USER PORTS BELOW THIS LINE ------------------
      --USER ports mapped here

      sampler_clk                    => sampler_clk,
      sampler_input                  => sampler_input,
      isolation                      => isolation,

      arbiter_clk                    => arbiter_clk,

      sram_address                   => sram_address,
      sram_adv                       => sram_adv,
      sram_we                        => sram_we,
      sram_ce                        => sram_ce,
      sram_bwa                       => sram_bwa,
      sram_bwb                       => sram_bwb,
      sram_bwc                       => sram_bwc,
      sram_bwd                       => sram_bwd,
      sram_oe                        => sram_oe,
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
      sram_dqd_T                     => sram_dqd_T,

      msi_request                    => msi_request,
      dma_interrupt                  => dma_interrupt,

      -- MAP USER PORTS ABOVE THIS LINE ------------------

      Bus2IP_Clk                     => ipif_Bus2IP_Clk,
      Bus2IP_Reset                   => ipif_Bus2IP_Reset,
      Bus2IP_Addr                    => ipif_Bus2IP_Addr,
      Bus2IP_CS                      => ipif_Bus2IP_CS(USER_CS_INDEX to USER_CS_INDEX+USER_NUM_MEM-1),
      Bus2IP_RNW                     => ipif_Bus2IP_RNW,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_RdCE                    => user_Bus2IP_RdCE,
      Bus2IP_WrCE                    => user_Bus2IP_WrCE,
      Bus2IP_Burst                   => ipif_Bus2IP_Burst,
      Bus2IP_BurstLength             => user_Bus2IP_BurstLength,
      Bus2IP_RdReq                   => ipif_Bus2IP_RdReq,
      Bus2IP_WrReq                   => ipif_Bus2IP_WrReq,
      IP2Bus_AddrAck                 => user_IP2Bus_AddrAck,
      IP2Bus_Data                    => user_IP2Bus_Data,
      IP2Bus_RdAck                   => user_IP2Bus_RdAck,
      IP2Bus_WrAck                   => user_IP2Bus_WrAck,
      IP2Bus_Error                   => user_IP2Bus_Error
    );

  ------------------------------------------
  -- connect internal signals
  ------------------------------------------
  IP2BUS_DATA_MUX_PROC : process( ipif_Bus2IP_CS, user_IP2Bus_Data ) is
  begin

    case ipif_Bus2IP_CS is
      when "10000" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "01000" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when "00001" => ipif_IP2Bus_Data <= user_IP2Bus_Data;
      when others => ipif_IP2Bus_Data <= (others => '0');
    end case;

  end process IP2BUS_DATA_MUX_PROC;

  ipif_IP2Bus_AddrAck <= ipif_Bus2IP_Burst and user_IP2Bus_AddrAck;
  ipif_IP2Bus_WrAck <= user_IP2Bus_WrAck;
  ipif_IP2Bus_RdAck <= user_IP2Bus_RdAck;
  ipif_IP2Bus_Error <= user_IP2Bus_Error;

  user_Bus2IP_RdCE(0 to USER_SLV_NUM_REG-1) <= ipif_Bus2IP_RdCE(USER_SLV_CE_INDEX to USER_SLV_CE_INDEX+USER_SLV_NUM_REG-1);
  user_Bus2IP_RdCE(USER_SLV_NUM_REG to USER_NUM_REG-1) <= ipif_Bus2IP_RdCE(USER_MST_CE_INDEX to USER_MST_CE_INDEX+USER_MST_NUM_REG-1);
  user_Bus2IP_WrCE(0 to USER_SLV_NUM_REG-1) <= ipif_Bus2IP_WrCE(USER_SLV_CE_INDEX to USER_SLV_CE_INDEX+USER_SLV_NUM_REG-1);
  user_Bus2IP_WrCE(USER_SLV_NUM_REG to USER_NUM_REG-1) <= ipif_Bus2IP_WrCE(USER_MST_CE_INDEX to USER_MST_CE_INDEX+USER_MST_NUM_REG-1);

  user_Bus2IP_BurstLength(8-log2(16*(C_SPLB_DWIDTH/8)) to 8) <= ipif_Bus2IP_BurstLength;

end IMP;
