library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sram_controller is
	generic(
		SRAM_AW	: integer := 18;
		SRAM_DW	: integer := 8;

		AW 		: integer := 18;
		DW 		: integer := 32
	);

	port(
		-- #### GENERAL PORT DEFINITIONS ...
		-- Klok- en resetsignaal van deze controller.
		clk 			: in std_logic;
		rst				: in std_logic;

		-- Adres waarop gelezen moet worden, of
		-- waarnaar geschreven moet worden.
		address 		: in std_logic_vector(AW-1 downto 0);

		-- Te schrijven data.
		-- Er wordt enkel rekening mee gehouden wanneer een
		-- WRITE-commando gegeven wordt.
		data_in			: in std_logic_vector(DW-1 downto 0);

		-- Uitgelezen data.
		-- Permanent doorgekoppeld met het SRAM, het "data_ready"-
		-- signaal geeft aan of de data op deze lijn geldig,
		-- dan wel ongeldig is.
		data_out		: out std_logic_vector(DW-1 downto 0);

		-- Geeft aan wanneer er geldige data beschikbaar is voor
		-- de gebruiker.
		data_ready		: out std_logic;

		cmd_read		: in std_logic;
		cmd_write		: in std_logic;
		cmd_burst		: in std_logic;
		-- #### ... GENERAL PORT DEFINITIONS

		-- #### ZBT SRAM PORT DEFINITIONS ...
		-- Clock
		ctrl2sram_clk 	: out std_logic;
		-- Address inputs
		ctrl2sram_a		: out std_logic_vector(SRAM_AW-1 downto 0);
		-- Synchronous Burst Address Advance/Load
		ctrl2sram_adv	: out std_logic;
		-- Synchronous Read/Write Control Input, active LOW
		ctrl2sram_we	: out std_logic;
		-- Synchronous Clock
		--ctrl2sram_clk	: out std_logic;
		-- Clock Enable, active LOW
		ctrl2sram_clken	: out std_logic;
		-- Synchronous Chip Enable, active LOW
		ctrl2sram_ce 	: out std_logic;
		ctrl2sram_ce2	: out std_logic;
		-- Synchronous Chip Enable, active HIGH
		ctrl2sram_ce22	: out std_logic;
		-- Synchronous Byte Write Inputs, active LOW
		ctrl2sram_bwa	: out std_logic;
		ctrl2sram_bwb	: out std_logic;
		ctrl2sram_bwc	: out std_logic;
		ctrl2sram_bwd	: out std_logic;
		-- Output Enable, active LOW
		ctrl2sram_oe 	: out std_logic;
		-- Power Sleep Mode
		ctrl2sram_zz	: out std_logic;
		-- Burst Sequence Selection
		ctrl2sram_mode	: out std_logic;
		-- JTAG Pins
		ctrl2sram_tck	: out std_logic;
		ctrl2sram_tdi	: in std_logic;
		ctrl2sram_tdo	: out std_logic;
		ctrl2sram_tms	: out std_logic;
		-- Datalijnen
		--sram_dqa		: inout std_logic_vector(SRAM_DW-1 downto 0);
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
		--sram_dqb		: inout std_logic_vector(SRAM_DW-1 downto 0);
		--sram_dqc		: inout std_logic_vector(SRAM_DW-1 downto 0);
		--sram_dqd		: inout std_logic_vector(SRAM_DW-1 downto 0);
		-- Parity Data Outputs
		-- TODO: deze worden nog niet aangestuurd...
		sram_dqap		: inout std_logic;
		sram_dqbp		: inout std_logic;
		sram_dqcp		: inout std_logic;
		sram_dqdp		: inout std_logic
		-- #### ... ZBT SRAM PORT DEFINITIONS
	);
end entity sram_controller;

architecture behaviour of sram_controller is

	-- We weten dat de weggeschreven data ALTIJD 2 cycli later aangelegd
	-- moet worden dan de cyclus waarin het WRITE commando werd gegeven.
	-- Implementeer dus een vertraging van 2 cycli.
	signal ctrl2sram_databuf1:std_logic_vector(DW-1 downto 0);
	signal ctrl2sram_databuf2:std_logic_vector(DW-1 downto 0);
	signal ctrl2sram_databuf1valid:std_logic;
	signal ctrl2sram_databuf2valid:std_logic;

	-- We weten dat de uitgelezen data ALTIJD 2 cycli later aankomt dan
	-- de cyclus waarin het READ commando werd gegeven.
	-- Implementeer dus een vertraging van 2 cycli.
	signal data_rdy_buf1	: std_logic;
	signal data_rdy_buf2	: std_logic;

	-- Hulpsignalen bij het verwerken.
	-- Geven aan of we al dan niet in een BURST mode zitten, R/W.
	signal burst_reading 	: std_logic;
	signal burst_writing 	: std_logic;

	-- Output Enable moet twee cycli later dan de READ request LAAG
	-- gebracht worden.
	-- Implementeer dus een vertraging van 2 cycli.
	signal oe_buf1			: std_logic;
	signal oe_buf2			: std_logic;

begin

	-- Klok naar SRAM is een halve periode vertraagd, omdat wij data naar
	-- buiten brengen op de stijgflank, maar het SRAM device ook op de
	-- stijgflank werkt.
	-- Halve klokperiode vertragen = klok omkeren.
	-- FIXME: om op FPGA te kunnen implementeren, moet de klok rechtstreeks instelbaar zijn!
	-- 		: Nu werkt het simulatiemodel natuurlijk niet meer...
	ctrl2sram_clk <= not clk;

	-- Zet sleep mode UIT. Houd het SRAM permanent AAN.
	-- Meer info, zie datasheet p.10.
	ctrl2sram_zz <= '0';

	-- Zet de mode permanent op LINEAR BURST.
	-- Datasheet p.12.
	ctrl2sram_mode <= '0';

	-- Zet de JTAG poorten permanent UIT door de klok uit te schakelen.
	-- De andere poorten hebben geen belang, omdat er geen klok is.
	-- Datasheet p.23.
	ctrl2sram_tck <= '0';



	process(clk, rst) is
	begin
		if rst='1' then
			sram_dqa_T <= '1';
			sram_dqb_T <= '1';
			sram_dqc_T <= '1';
			sram_dqd_T <= '1';

			sram_dqa_O 	<= (others => '1');
			sram_dqb_O 	<= (others => '1');
			sram_dqc_O 	<= (others => '1');
			sram_dqd_O 	<= (others => '1');
		elsif rising_edge(clk) then
			if ctrl2sram_databuf2valid='1' then
				sram_dqa_T <= '0';
				sram_dqb_T <= '0';
				sram_dqc_T <= '0';
				sram_dqd_T <= '0';

				-- Splits een 32-bit input op in 4 bytes
				sram_dqd_O 			<= ctrl2sram_databuf2(31 downto 24);
				sram_dqc_O 			<= ctrl2sram_databuf2(23 downto 16);
				sram_dqb_O 			<= ctrl2sram_databuf2(15 downto  8);
				sram_dqa_O 			<= ctrl2sram_databuf2( 7 downto  0);
			else
				sram_dqa_T <= '1';
				sram_dqb_T <= '1';
				sram_dqc_T <= '1';
				sram_dqd_T <= '1';

				-- Permanent output data van SRAM doorkoppelen naar uitgang van
				-- deze controller. Het "data_ready"-signaal geeft aan of er
				-- geldige (HOOG) data aanwezig is.
				data_out(31 downto 24) <= sram_dqd_I;
				data_out(23 downto 16) <= sram_dqc_I;
				data_out(15 downto  8) <= sram_dqb_I;
				data_out( 7 downto  0) <= sram_dqa_I;

			end if;
		end if;
	end process;

	process(clk, rst) is
	begin
		if rst='1' then
			--oe_buf1 <= '1';
			oe_buf2 <= '1';
			ctrl2sram_oe <= '1';
		elsif falling_edge(clk) then
			-- OE buffer
			oe_buf2 			<= oe_buf1;
			ctrl2sram_oe 		<= oe_buf2;
		end if;
	end process;

	process(clk, rst) is

		variable command : std_logic_vector(0 to 2);

	begin

		if rst='1' then
			data_out 		<= (others => 'Z');
			data_rdy_buf1	<= '0';
			data_rdy_buf2	<= '0';
			data_ready 		<= '0';

			burst_reading 	<= '0';
			burst_writing 	<= '0';

			-- Chip deselecteren
			ctrl2sram_ce 	<= '1';--
			ctrl2sram_ce22 	<= '0';
			ctrl2sram_ce2 	<= '1';
			ctrl2sram_adv 	<= '0';--
			ctrl2sram_we 	<= '1';
			ctrl2sram_bwa	<= '1';
			ctrl2sram_bwb	<= '1';
			ctrl2sram_bwc	<= '1';
			ctrl2sram_bwd	<= '1';
			--oe_buf1 		<= '1';
			--oe_buf2 		<= '1';
			--ctrl2sram_oe 	<= '1';
			ctrl2sram_clken <= '0';--

			ctrl2sram_a 	<= (others => '0');

			ctrl2sram_databuf1<=(others=> '1');
			ctrl2sram_databuf2<=(others=> '1');
			ctrl2sram_databuf1valid<='0';
			ctrl2sram_databuf2valid<='0';

		elsif rising_edge(clk) then
			-- Kies meteen een state, om geen tijdsvertraging
			-- te veroorzaken.
			command 			:= cmd_burst & cmd_read & cmd_write;

			-- Signaal om geldigheid van data aan te tonen aan de master.
			-- Telkens wanneer Output Enable LAAG is, staat er data KLAAR.
			-- Omgekeerd, als Output Enable HOOG is, is er geen data.
			--data_ready			<= not ctrl2sram_oebuf2;
			data_rdy_buf2		<= data_rdy_buf1;
			data_ready 			<= data_rdy_buf2;

			ctrl2sram_databuf2valid <= ctrl2sram_databuf1valid;

			ctrl2sram_databuf2 	<= ctrl2sram_databuf1;

			-- Implementeer de drivers voor de verschillende stuur-
			-- signalen van het SRAM. De datasheet definieert een
			-- aantal verschillende operaties (p.9).
			-- Stel telkens alle signalen in op een gekende waarde,
			-- zodanig dat ze standaard 'uit' zijn ('1' voor actief-
			-- laag of '0' voor actief-hoog).
			-- Signalen die een bepaalde waarde MOETEN hebben,
			-- krijgen hebben lege commentaar op het einde van de
			-- regel. Andere signalen zijn 'X' (don't care).
			case command is
			when "010" | "110" =>
				-- READ
				burst_reading	<= cmd_burst;
				burst_writing	<= '0';

				ctrl2sram_ce 	<= '0';--
				ctrl2sram_ce22 	<= '1';--
				ctrl2sram_ce2 	<= '0';--
				ctrl2sram_adv 	<= '0';--
				ctrl2sram_we 	<= '1';--
				ctrl2sram_bwa	<= '1';
				ctrl2sram_bwb	<= '1';
				ctrl2sram_bwc	<= '1';
				ctrl2sram_bwd	<= '1';
				oe_buf1		 	<= '0';--
				ctrl2sram_clken <= '0';--

				ctrl2sram_a 	<= address;

				-- Te schrijven data mag slechts de tweede stijgflank na
				-- het doeladres aangelegd worden.
				-- Implementeer dus eerst buffers.
				ctrl2sram_databuf1	<= (others => 'Z');
				ctrl2sram_databuf1valid <= '0';

				data_rdy_buf1 <= '1';

			when "001" | "101" =>
				-- WRITE
				burst_reading 	<= '0';
				burst_writing 	<= cmd_burst;

				ctrl2sram_ce 	<= '0';--
				ctrl2sram_ce22 	<= '1';--
				ctrl2sram_ce2 	<= '0';--
				ctrl2sram_adv 	<= '0';--
				ctrl2sram_we 	<= '0';--
				ctrl2sram_bwa	<= '0';--
				ctrl2sram_bwb	<= '0';--
				ctrl2sram_bwc	<= '0';--
				ctrl2sram_bwd	<= '0';--
				oe_buf1		 	<= '1';
				ctrl2sram_clken <= '0';--

				ctrl2sram_a 	<= address;

				-- Te schrijven data mag slechts de tweede stijgflank na
				-- het doeladres aangelegd worden.
				-- Implementeer dus eerst buffers.
				ctrl2sram_databuf1	<= data_in;
				ctrl2sram_databuf1valid <= '1';

				data_rdy_buf1 <= '0';

			when "100" =>
				-- BURST READ of BURST WRITE (CONTINUE)
				-- Enkel "Burst" staat aan.
				-- Naargelang de begonnen state (lezen of schrijven)
				-- doen we de gepaste actie.
				if burst_reading='1' then
					ctrl2sram_ce 	<= '1';
					ctrl2sram_ce22 	<= '0';
					ctrl2sram_ce2 	<= '1';
					ctrl2sram_adv 	<= '1';--
					ctrl2sram_we 	<= '1';
					ctrl2sram_bwa	<= '1';
					ctrl2sram_bwb	<= '1';
					ctrl2sram_bwc	<= '1';
					ctrl2sram_bwd	<= '1';
					oe_buf1		 	<= '0';--
					ctrl2sram_clken <= '0';--

					-- Te schrijven data mag slechts de tweede stijgflank na
					-- het doeladres aangelegd worden.
					-- Implementeer dus eerst buffers.
					ctrl2sram_databuf1	<= (others => 'Z');
				ctrl2sram_databuf1valid <= '0';

					data_rdy_buf1 <= '1';

				elsif burst_writing='1' then
					ctrl2sram_ce 	<= '1';
					ctrl2sram_ce22 	<= '0';
					ctrl2sram_ce2 	<= '1';
					ctrl2sram_adv 	<= '1';--
					ctrl2sram_we 	<= '0';
					ctrl2sram_bwa	<= '0';--
					ctrl2sram_bwb	<= '0';--
					ctrl2sram_bwc	<= '0';--
					ctrl2sram_bwd	<= '0';--
					oe_buf1		 	<= '1';
					ctrl2sram_clken <= '0';--

					-- Te schrijven data mag slechts de tweede stijgflank na
					-- het doeladres aangelegd worden.
					-- Implementeer dus eerst buffers.
					ctrl2sram_databuf1	<= data_in;
				ctrl2sram_databuf1valid <= '1';

					data_rdy_buf1 <= '0';

				end if;

				ctrl2sram_a 	<= (others => '0');

			when others =>
				-- GEEN GELDIG COMMANDO
				-- Chip deselecteren
				burst_reading 	<= '0';
				burst_writing 	<= '0';

				ctrl2sram_ce 	<= '1';--
				ctrl2sram_ce22 	<= '0';
				ctrl2sram_ce2 	<= '1';
				ctrl2sram_adv 	<= '0';--
				ctrl2sram_we 	<= '1';
				ctrl2sram_bwa	<= '1';
				ctrl2sram_bwb	<= '1';
				ctrl2sram_bwc	<= '1';
				ctrl2sram_bwd	<= '1';
				oe_buf1		 	<= '1';
				ctrl2sram_clken <= '0';--

				ctrl2sram_a 	<= (others => '0');

				data_rdy_buf1 <= '0';

				-- Te schrijven data mag slechts de tweede stijgflank na
				-- het doeladres aangelegd worden.
				-- Implementeer dus eerst buffers.
				ctrl2sram_databuf1	<= (others => 'Z');
				ctrl2sram_databuf1valid <= '0';

			end case;

		end if;

	end process;

end behaviour;
