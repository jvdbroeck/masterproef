library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sampler is
	generic (
		DATA_WIDTH 		: integer := 9;
		TIMESTAMP_WIDTH : integer := 23
	);

	port (
		clk 		: in std_logic;
		rst 		: in std_logic;
		rstinv		: in std_logic;

--		dbg_timestamp_overflow : out std_logic;
--		dbg_timestamp_counter : out std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);
--		dbg_p1_enable : out std_logic;
--		dbg_p1_timestamp : out std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);
--		dbg_p1_data : out std_logic_vector(DATA_WIDTH-2 downto 0);
--		dbg_p2_enable : out std_logic;
--		dbg_p2_not_equal : out std_logic;
--		dbg_p2_sample : out std_logic_vector(31 downto 0);
--		dbg_p2_old_data : out std_logic_vector(DATA_WIDTH-2 downto 0);
--		dbg_p3_enable : out std_logic;

		-- 1 bit minder omdat de overflow van de timestamp counter
		-- ook in rekening gebracht moet worden!
		data 		: in std_logic_vector(DATA_WIDTH-2 downto 0);
		enable		: in std_logic;

		out_write 	: out std_logic;
		out_data  	: out std_logic_vector(31 downto 0);

		fifo_full : in std_logic
	);
end entity Sampler;

architecture RTL of Sampler is

	-- overflow van timestamp counter
	signal timestamp_overflow	: std_logic;
	signal timestamp_counter	: std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);

	-- Pijplijn stage 1
	signal p1_enable			: std_logic;
	signal p1_timestamp			: std_logic_vector(TIMESTAMP_WIDTH-1 downto 0);
	-- Niet DATA_WIDTH-1 omdat hier de overflow bit bij zit!
	signal p1_data				: std_logic_vector(DATA_WIDTH-2 downto 0);
	signal p1_overflow : std_logic;

	-- Pijplijn stage 2
	signal p2_enable			: std_logic;
	signal p2_not_equal			: std_logic;
	signal p2_sample			: std_logic_vector(31 downto 0);
	-- Niet DATA_WIDTH-1 omdat hier de overflow bit bij zit!
	signal p2_old_data			: std_logic_vector(DATA_WIDTH-2 downto 0);

	-- Pijplijn stage 3
	signal p3_enable			: std_logic;
begin

-- Verhoog te timestamp bij elke kloktik.
-- Telkens deze teller over loopt, wordt er een overflow-bit hoog gebracht.
-- Bij de tik na het overlopen, wordt de overflow-bit terug laag gebracht.
TimestampCounterProcess : process(rst, clk) is
begin

if rising_edge(clk) then

		if rst='1' then
			timestamp_counter <= (others => '0');
			timestamp_overflow <= '0';
		end if;

--			dbg_timestamp_counter <= (others => '0');
--			dbg_timestamp_overflow <= '0';
	if rstinv='1' then

		if enable='1' then
			timestamp_counter <= std_logic_vector(unsigned(timestamp_counter)+1);
--			dbg_timestamp_counter <= std_logic_vector(unsigned(timestamp_counter)+1);

			if unsigned(timestamp_counter)+1=0 then
				timestamp_overflow <= '1';
--				dbg_timestamp_overflow <= '1';
			else
				timestamp_overflow <= '0';
--				dbg_timestamp_overflow <= '0';
			end if;

		end if;
	end if;

	end if;
end process;

-- PIJPLIJN FASE 1: DATA ACQUISITIE
-- 	Genereer een nieuw sample op elke kloktik, bestaande uit:
--	 - timestamp counter
--	 - input bits
--   - overflow bit
DataAcquisitionProcess : process(rst, clk) is
begin

if rising_edge(clk) then

		if rst='1' then
			p1_enable <= '0';
			p1_data <= (others => '0');
			p1_timestamp <= (others => '0');
			p1_overflow <= '0';
--			dbg_p1_enable <= '0';
--			dbg_p1_data <= (others => '0');
--			dbg_p1_timestamp <= (others => '0');
end if;

		if rstinv='1' then
			p1_enable <= enable;
--			dbg_p1_enable <= enable;

			if enable='1' then
				p1_data <= data;-- & timestamp_overflow;
				p1_timestamp <= timestamp_counter;
				p1_overflow <= timestamp_overflow;
--				dbg_p1_data <= data;-- & timestamp_overflow;
--				dbg_p1_timestamp <= timestamp_counter;
			end if;
	end if;

		end if;
end process;

-- PIJPLIJN FASE 2: VERGELIJKEN NIEUW MET OUD SAMPLE
--  Vergelijk het nieuwe sample met het oude, gebufferde sample.
--  Indien beide gelijke data-inputs hebben, moeten we geen nieuw sample opslaan.
SampleCompareProcess : process(rst, clk) is
begin

if rising_edge(clk) then
		if rst='1' then
			p2_enable <= '0';
			p2_not_equal <= '0';
			--p2_sample <= (others => '0');
			p2_old_data <= (others => '0');
--			dbg_p2_enable <= '0';
--			dbg_p2_not_equal <= '0';
--			dbg_p2_sample <= (others => '0');
--			dbg_p2_old_data <= (others => '0');
end if;

		if rstinv='1' then
			p2_enable <= p1_enable;
--			dbg_p2_enable <= p1_enable;

			if p1_enable='1' then
				if p1_data=p2_old_data and p1_overflow='0' then
					p2_not_equal <= '0';
--					dbg_p2_not_equal <= '0';
				else
					p2_not_equal <= '1';
--					dbg_p2_not_equal <= '1';
				end if;

				p2_sample <= p1_data & p1_overflow & p1_timestamp;
				p2_old_data <= p1_data;
--				dbg_p2_sample <= p1_data & p1_overflow & p1_timestamp;
--				dbg_p2_old_data <= p1_data;
			end if;
		end if;
	end if;

end process;

-- PIJPLIJN FASE 3: OPSLAAN VAN NIEUW SAMPLE
--  Doe dit enkel en alleen als het nieuwe en het oude sample verschillend zijn in data.
--  Indien ja, schrijf een sample weg naar het geheugen.
SaveSampleProcess : process(rst, clk) is
begin

if rising_edge(clk) then

	if rst='1' then
		p3_enable <= '0';
		out_write <= '0';
			--out_data <= (others => '0');
	end if;

	if rstinv='1' then
--			dbg_p3_enable <= '0';
			p3_enable <= p2_enable;
--			dbg_p3_enable <= p2_enable;
			-- mag asynchroon gemaakt worden...
			out_data <= p2_sample;
			out_write <= '0';

			if p2_enable='1' then
				if p2_not_equal='1' and fifo_full='0' then
					out_write <= '1';
				else
					out_write <= '0';
				end if;
			end if;

	end if;
	end if;
end process;

end architecture RTL;
