library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sram_tester is
	port(
		clk : in std_logic;
		rst : in std_logic;

		ctrl_address : in std_logic_vector(17 downto 0);
		ctrl_in : in std_logic_vector(31 downto 0);
		ctrl_out : out std_logic_vector(31 downto 0);
		ctrl_rdy : out std_logic;
		ctrl_read : in std_logic;
		ctrl_write : in std_logic;
		ctrl_burst : in std_logic
	);
end sram_tester;

architecture behaviour of sram_tester is

	component tristatebuffer
		port(
			I : in std_logic_vector(7 downto 0);
			databus : out std_logic_vector(7 downto 0);
			enable : std_logic
		);
	end component;

	component mt55l256l32p
		port(
			Dq 		: inout std_logic_vector(31 downto 0);
			Addr 	: in std_logic_vector(17 downto 0);
			Lbo_n	: in std_logic;
			Clk 	: in std_logic;
			Cke_n 	: in std_logic;
			Ld_n 	: in std_logic;
			Bwa_n 	: in std_logic;
			Bwb_n 	: in std_logic;
			Bwc_n 	: in std_logic;
			Bwd_n 	: in std_logic;
			Rw_n	: in std_logic;
			Oe_n	: in std_logic;
			Ce_n	: in std_logic;
			Ce2_n 	: in std_logic;
			Ce2 	: in std_logic;
			Zz 		: in std_logic
		);
	end component;

	component sram_controller
		generic(
			SRAM_AW	: integer := 18;
			SRAM_DW	: integer := 8;

			AW 		: integer := 18;
			DW 		: integer := 32
		);

		port(
			clk 			: in std_logic;
			rst				: in std_logic;
			address 		: in std_logic_vector(AW-1 downto 0);
			data_in			: in std_logic_vector(DW-1 downto 0);
			data_out		: out std_logic_vector(DW-1 downto 0);
			data_ready		: out std_logic;
			cmd_read		: in std_logic;
			cmd_write		: in std_logic;
			cmd_burst		: in std_logic;
			ctrl2sram_a		: out std_logic_vector(SRAM_AW-1 downto 0);
			ctrl2sram_adv	: out std_logic;
			ctrl2sram_we	: out std_logic;
			ctrl2sram_clk	: out std_logic;
			ctrl2sram_clken	: out std_logic;
			ctrl2sram_ce 	: out std_logic;
			ctrl2sram_ce2	: out std_logic;
			ctrl2sram_ce22	: out std_logic;
			ctrl2sram_bwa	: out std_logic;
			ctrl2sram_bwb	: out std_logic;
			ctrl2sram_bwc	: out std_logic;
			ctrl2sram_bwd	: out std_logic;
			ctrl2sram_oe 	: out std_logic;
			ctrl2sram_zz	: out std_logic;
			ctrl2sram_mode	: out std_logic;
			ctrl2sram_tck	: out std_logic;
			ctrl2sram_tdi	: in std_logic;
			ctrl2sram_tdo	: out std_logic;
			ctrl2sram_tms	: out std_logic;
      sram_dqa_I:in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqa_O:out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqa_T:out std_logic;
      sram_dqb_I:in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqb_O:out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqb_T:out std_logic;
      sram_dqc_I:in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqc_O:out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqc_T:out std_logic;
      sram_dqd_I:in std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqd_O:out std_logic_vector(SRAM_DW-1 downto 0);
      sram_dqd_T:out std_logic;
			sram_dqap		: inout std_logic;
			sram_dqbp		: inout std_logic;
			sram_dqcp		: inout std_logic;
			sram_dqdp		: inout std_logic
		);
	end component;

	for all: mt55l256l32p use entity work.mt55l256l32p(behave);
	for all: sram_controller use entity work.sram_controller(behaviour);

	signal top_data : std_logic_vector(31 downto 0);
	signal top_address : std_logic_vector(17 downto 0);
	signal top_mode : std_logic;
	signal top_clk : std_logic;
	signal top_cke : std_logic;
	signal top_adv : std_logic;
	signal top_bwa : std_logic;
	signal top_bwb : std_logic;
	signal top_bwc : std_logic;
	signal top_bwd : std_logic;
	signal top_write : std_logic;
	signal top_oe : std_logic;
	signal top_ce : std_logic;
	signal top_ce2 : std_logic;
	signal top_ce22 : std_logic;
	signal top_zz : std_logic;

	signal top_dqa_I : std_logic_vector(7 downto 0);
	signal top_dqb_I : std_logic_vector(7 downto 0);
	signal top_dqc_I : std_logic_vector(7 downto 0);
	signal top_dqd_I : std_logic_vector(7 downto 0);
	signal top_dqa_O : std_logic_vector(7 downto 0);
	signal top_dqb_O : std_logic_vector(7 downto 0);
	signal top_dqc_O : std_logic_vector(7 downto 0);
	signal top_dqd_O : std_logic_vector(7 downto 0);
	signal top_dqa_T : std_logic;
	signal top_dqb_T : std_logic;
	signal top_dqc_T : std_logic;
	signal top_dqd_T : std_logic;

begin

	memory : entity work.mt55l256l32p port map(
		Dq => top_data,
		Addr => top_address,
		Lbo_n => top_mode,
		Clk => top_clk,
		Cke_n => top_cke,
		Ld_n => top_adv,
		Bwa_n => top_bwa,
		Bwb_n => top_bwb,
		Bwc_n => top_bwc,
		Bwd_n => top_bwd,
		Rw_n => top_write,
		Oe_n => top_oe,
		Ce_n => top_ce,
		Ce2_n => top_ce2,
		Ce2 => top_ce22,
		Zz => top_zz
	);

	tristatebuffer_a : entity work.tristatebuffer port map(
		I => top_dqa_O,
		enable => top_dqa_T,
		databus => top_dqa_I
	);

	tristatebuffer_b : entity work.tristatebuffer port map(
		I => top_dqb_O,
		enable => top_dqb_T,
		databus => top_dqb_I
	);

	tristatebuffer_c : entity work.tristatebuffer port map(
		I => top_dqc_O,
		enable => top_dqc_T,
		databus => top_dqc_I
	);

	tristatebuffer_d : entity work.tristatebuffer port map(
		I => top_dqd_O,
		enable => top_dqd_T,
		databus => top_dqd_I
	);

	controller : entity work.sram_controller port map(
		clk => clk,
		rst => rst,
		address => ctrl_address,
		data_in => ctrl_in,
		data_out => ctrl_out,
		data_ready => ctrl_rdy,
		cmd_read => ctrl_read,
		cmd_write => ctrl_write,
		cmd_burst => ctrl_burst,
		ctrl2sram_a => top_address,
		ctrl2sram_adv => top_adv,
		ctrl2sram_we => top_write,
		ctrl2sram_clk => top_clk,
		ctrl2sram_clken => top_cke,
		ctrl2sram_ce => top_ce,
		ctrl2sram_ce2 => top_ce2,
		ctrl2sram_ce22 => top_ce22,
		ctrl2sram_bwa => top_bwa,
		ctrl2sram_bwb => top_bwb,
		ctrl2sram_bwc => top_bwc,
		ctrl2sram_bwd => top_bwd,
		ctrl2sram_oe => top_oe,
		ctrl2sram_zz => top_zz,
		ctrl2sram_mode => top_mode,
		ctrl2sram_tck => open,
		ctrl2sram_tdi => '0',
		ctrl2sram_tdo => open,
		ctrl2sram_tms => open,
		sram_dqa_I => top_dqa_I,
		sram_dqb_I => top_dqb_I,
		sram_dqc_I => top_dqc_I,
		sram_dqd_I => top_dqd_I,
		sram_dqa_O => top_dqa_O,
		sram_dqb_O => top_dqb_O,
		sram_dqc_O => top_dqc_O,
		sram_dqd_O => top_dqd_O,
		sram_dqa_T => top_dqa_T,
		sram_dqb_T => top_dqb_T,
		sram_dqc_T => top_dqc_T,
		sram_dqd_T => top_dqd_T,
		sram_dqap => open,
		sram_dqbp => open,
		sram_dqcp => open,
		sram_dqdp => open
	);

	top_data <= top_dqd_I & top_dqc_I & top_dqb_I & top_dqa_I;

	process(clk) is
	begin
		if rising_edge(clk) then
			ctrl_out <= top_data;
		end if;
	end process;

end behaviour;
