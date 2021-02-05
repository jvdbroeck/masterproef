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
-- Date:              Wed Apr  3 20:34:58 2013 (by Create and Import Peripheral Wizard)
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
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_MST_AWIDTH                 -- Master interface address bus width
--   C_MST_DWIDTH                 -- Master interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
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
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_DWIDTH                   : integer              := 32;
    C_MST_AWIDTH                   : integer              := 32;
    C_MST_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 5
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic;
    IP2Bus_MstRd_Req               : out std_logic;
    IP2Bus_MstWr_Req               : out std_logic;
    IP2Bus_Mst_Addr                : out std_logic_vector(0 to C_MST_AWIDTH-1);
    IP2Bus_Mst_BE                  : out std_logic_vector(0 to C_MST_DWIDTH/8-1);
    IP2Bus_Mst_Lock                : out std_logic;
    IP2Bus_Mst_Reset               : out std_logic;
    Bus2IP_Mst_CmdAck              : in  std_logic;
    Bus2IP_Mst_Cmplt               : in  std_logic;
    Bus2IP_Mst_Error               : in  std_logic;
    Bus2IP_Mst_Rearbitrate         : in  std_logic;
    Bus2IP_Mst_Cmd_Timeout         : in  std_logic;
    Bus2IP_MstRd_d                 : in  std_logic_vector(0 to C_MST_DWIDTH-1);
    Bus2IP_MstRd_src_rdy_n         : in  std_logic;
    IP2Bus_MstWr_d                 : out std_logic_vector(0 to C_MST_DWIDTH-1);
    Bus2IP_MstWr_dst_rdy_n         : in  std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";
  attribute SIGIS of IP2Bus_Mst_Reset: signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  --USER signal declarations added here, as needed for user logic

  type MASTER_SEND_STATE is (SEND_IDLE, SEND_WAITACK, SEND_WAITDATA, SEND_DONE);
  signal current_send_state : MASTER_SEND_STATE;
  signal master_data : std_logic_vector(0 to 31);
  signal master_address : std_logic_vector(0 to 31);
  signal master_error : std_logic;
  signal master_timeout : std_logic;
  signal master_done : std_logic;
  signal master_send : std_logic;
  signal master_busy : std_logic;

  signal initialised : std_logic;

begin

  --USER logic implementation added here

  CONFIG_PROC : process(Bus2IP_Clk, Bus2IP_Reset) is
  begin
    if Bus2IP_Reset='1' then
      initialised <= '0';
      master_send <= '0';
      master_address <= (others => '0');
      master_data <= (others => '0');

    elsif rising_edge(Bus2IP_Clk) then
      -- keep low for safety...
      master_send <= '0';
      master_address <= (others => '0');
      master_data <= (others => '0');

      if initialised='0' then

        if master_busy='0' then
          master_address <= x"85C00030";
          master_data <= x"00000107";
          master_send <= '1';

        elsif master_done='1' then
          initialised <= '1';
        end if;

      end if;

    end if;
  end process CONFIG_PROC;




  MASTER_SEND_PROC : process(Bus2IP_Clk, Bus2IP_Reset) is
  begin
    if(Bus2IP_Reset='1') then
      master_done <= '0';
      master_error <= '0';
      master_timeout <= '0';
      master_busy <= '1';
      current_send_state <= SEND_IDLE;

    elsif rising_edge(Bus2IP_Clk) then

      -- default values
      master_done <= '0';
      master_error <= '0';
      master_timeout <= '0';
      master_busy <= '1';

      IP2Bus_MstRd_Req <= '0';
      IP2Bus_MstWr_Req <= '0';
      IP2Bus_Mst_Addr <= (others => '0');
      IP2Bus_Mst_BE <= (others => '0');
      IP2Bus_Mst_Lock <= '0';
      IP2Bus_Mst_Reset <= '0';
      IP2Bus_MstWr_d <= (others => '0');

      case current_send_state is
      when SEND_IDLE =>
        if master_send='1' then
          current_send_state <= SEND_WAITACK;
        else
          current_send_state <= SEND_IDLE;
          master_busy <= '0';
        end if;

      when SEND_WAITACK =>
        if (Bus2IP_Mst_CmdAck='1' and Bus2IP_Mst_Cmplt='0') then
          -- Write request acknowledged.
          -- The bus is now ready to send data.
          current_send_state <= SEND_WAITDATA;

        elsif (Bus2IP_Mst_Cmplt='1') then
          current_send_state <= SEND_DONE;

          -- xfer complete before data sent:
          -- ERROR!
          if (Bus2IP_Mst_Cmd_Timeout='1') then
            -- Timeout error: slave did not respond within 128 cycles.
            master_error <= '1';
            master_timeout <= '1';
          elsif (Bus2IP_Mst_Error='1') then
            -- General error
            master_error <= '1';
          end if;

        else
          -- Normale toestand, wacht op ACK
          current_send_state <= SEND_WAITACK;

          IP2Bus_MstWr_Req <= '1';
          IP2Bus_Mst_Addr <= master_address;
          IP2Bus_Mst_BE <= (others => '1');
          IP2Bus_MstWr_d <= master_data;

        end if;

      when SEND_WAITDATA =>
        if(Bus2IP_Mst_Cmplt='1') then
          current_send_state <= SEND_DONE;

          if(Bus2IP_Mst_Cmd_Timeout='1') then
            master_error <= '1';
            master_timeout <= '1';
          elsif(Bus2IP_Mst_Error='1') then
            master_error <= '1';
          end if;
        else
          -- Normale toestand, wacht tot data
          current_send_state <= SEND_WAITDATA;
        end if;

      when SEND_DONE =>
        current_send_state <= SEND_IDLE;
        master_done <= '1';
        master_busy <= '0';

      when others =>
        current_send_state <= SEND_IDLE;
        master_busy <= '0';

      end case;

    end if;
  end process MASTER_SEND_PROC;

end IMP;
