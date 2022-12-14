-------------------------------------------
-- Company:        SRS
-- Engineer:       Kamil Rudnicki
-- Create Date:    07/05/2017
-- Project Name:   MPALU
-- Design Name:    core
-- Module Name:    mult_acc_ip_64
-------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

use work.pro_pack.all;
--use work.common_pack.all;

-------------------------------------------
-------------------------------------------
--
-- TO DO:
--
--
-------------------------------------------
-------------------------------------------

entity mult_acc_ip_64 is
generic (
	g_data_width					: natural := 64;
	g_addr_width					: natural := 9
);
port(
	CLK								: in std_logic;
	BYPASS							: in std_logic;
	B									: in std_logic_vector(g_data_width-1 downto 0);
	Q									: out std_logic_vector(g_data_width+g_addr_width-1 downto 0)
);
end mult_acc_ip_64;

architecture mult_acc_ip_64 of mult_acc_ip_64 is

	constant c_data_hi_width				: natural := g_data_width+g_addr_width-C_DSP_DATA_WIDTH;

	signal s_bypass_n							: std_logic;
	signal r_BYPASS_n							: std_logic;

	signal s_carry								: std_logic;
	signal s_carry_sel						: std_logic_vector(2 downto 0);
	signal s_opmode_lo						: std_logic_vector(6 downto 0);
	signal s_opmode_hi						: std_logic_vector(6 downto 0);

	signal s_data_lo							: std_logic_vector(47 downto 0);
	signal s_data_lo_dly						: std_logic_vector(47 downto 0);

	signal s_data_hi							: std_logic_vector(c_data_hi_width-1 downto 0);
	signal s_data_hi_open					: std_logic_vector(C_DSP_DATA_WIDTH-c_data_hi_width-1 downto 0);
	signal s_data_hi_dly						: std_logic_vector(c_data_hi_width-1 downto 0);

begin

	--------------------
	-- ACCUMULATOR LO --
	--------------------

	ACC_48_LO_INST: DSP48E1 generic map (
		-- Feature Control Attributes: Data Path Selection
		A_INPUT					=> "DIRECT",							-- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
		B_INPUT					=> "DIRECT",							-- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
		USE_DPORT				=> FALSE,								-- Select D port usage (TRUE or FALSE)
		USE_MULT					=> "NONE",								-- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
		USE_SIMD					=> "ONE48",								-- SIMD selection ("ONE48", "TWO24", "FOUR12")
																				-- Pattern Detector Attributes: Pattern Detection Configuration
		AUTORESET_PATDET		=> "NO_RESET",							-- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
		MASK						=> X"3fffffffffff",					-- 48-bit mask value for pattern detect (1=ignore)
		PATTERN					=> X"000000000000",					-- 48-bit pattern match for pattern detect
		SEL_MASK					=> "MASK",								-- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
		SEL_PATTERN				=> "PATTERN",							-- Select pattern value ("PATTERN" or "C")
		USE_PATTERN_DETECT	=> "NO_PATDET",						-- Enable pattern detect ("PATDET" or "NO_PATDET")
																				-- Register Control Attributes: Pipeline Register Configuration
		ACASCREG					=> 1,										-- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
		ADREG						=> 0,										-- Number of pipeline stages for pre-adder (0 or 1)
		ALUMODEREG				=> 1,										-- Number of pipeline stages for ALUMODE (0 or 1)
		AREG						=> 1,										-- Number of pipeline stages for A (0, 1 or 2)
		BCASCREG					=> 1,										-- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
		BREG						=> 1,										-- Number of pipeline stages for B (0, 1 or 2)
		CARRYINREG				=> 0,										-- Number of pipeline stages for CARRYIN (0 or 1)
		CARRYINSELREG			=> 0,										-- Number of pipeline stages for CARRYINSEL (0 or 1)
		CREG						=> 0,										-- Number of pipeline stages for C (0 or 1)
		DREG						=> 0,										-- Number of pipeline stages for D (0 or 1)
		INMODEREG				=> 0,										-- Number of pipeline stages for INMODE (0 or 1)
		MREG						=> 0,										-- Number of multiplier pipeline stages (0 or 1)
		OPMODEREG				=> 1,										-- Number of pipeline stages for OPMODE (0 or 1)
		PREG						=> 1										-- Number of pipeline stages for P (0 or 1)
	)
	port map (
		-- Cascade: 30-bit (each) output: Cascade Ports
		ACOUT							=> open,												-- 30-bit output: A port cascade output
		BCOUT							=> open,												-- 18-bit output: B port cascade output
		CARRYCASCOUT				=> s_carry,											-- 1-bit output: Cascade carry output
		MULTSIGNOUT					=> open,												-- 1-bit output: Multiplier sign cascade output
		PCOUT							=> open,												-- 48-bit output: Cascade output
																								-- Control: 1-bit (each) output: Control Inputs/Status Bits
		OVERFLOW						=> open,												-- 1-bit output: Overflow in add/acc output
		PATTERNBDETECT 			=> open,												-- 1-bit output: Pattern bar detect output
		PATTERNDETECT				=> open,												-- 1-bit output: Pattern detect output
		UNDERFLOW					=> open,												-- 1-bit output: Underflow in add/acc output
																								-- Data: 4-bit (each) output: Data Ports
		CARRYOUT						=> open,												-- 4-bit output: Carry output
		P								=> s_data_lo,										-- 48-bit output: Primary data output
																								-- Cascade: 30-bit (each) input: Cascade Ports
		ACIN							=> (others=>'0'),									-- 30-bit input: A cascade data input
		BCIN							=> (others=>'0'),									-- 18-bit input: B cascade input
		CARRYCASCIN					=> '0',												-- 1-bit input: Cascade carry input
		MULTSIGNIN					=> '0',												-- 1-bit input: Multiplier sign input
		PCIN							=> (others=>'0'),									-- 48-bit input: P cascade input
																								-- Control: 4-bit (each) input: Control Inputs/Status Bits
		ALUMODE						=> "0000",											-- 4-bit input: ALU control input
		CARRYINSEL					=> (others=>'0'),									-- 3-bit input: Carry select input
		CLK							=> CLK,												-- 1-bit input: Clock input
		INMODE						=> (others=>'0'),									-- 5-bit input: INMODE control input
		OPMODE						=> s_opmode_lo,									-- 7-bit input: Operation mode input
																								-- Data: 30-bit (each) input: Data Ports
		A								=> B(47 downto 18),								-- 30-bit input: A data input
		B								=> B(17 downto 0),								-- 18-bit input: C data input
		C								=> (others=>'0'),									-- 48-bit input: C data input
		CARRYIN						=> '0',												-- 1-bit input: Carry input signal

		D								=> (others=>'0'),									-- 25-bit input: D data input
																								-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
		CEA1							=> '0',								-- 1-bit input: Clock enable input for 1st stage AREG
		CEA2							=> '1',								-- 1-bit input: Clock enable input for 2nd stage AREG
		CEAD							=> '0',								-- 1-bit input: Clock enable input for ADREG
		CEALUMODE					=> '0',								-- 1-bit input: Clock enable input for ALUMODE
		CEB1							=> '0',								-- 1-bit input: Clock enable input for 1st stage BREG
		CEB2							=> '1',								-- 1-bit input: Clock enable input for 2nd stage BREG
		CEC							=> '0',								-- 1-bit input: Clock enable input for CREG
		CECARRYIN					=> '0',								-- 1-bit input: Clock enable input for CARRYINREG
		CECTRL						=> '1',								-- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
		CED							=> '0',								-- 1-bit input: Clock enable input for DREG
		CEINMODE						=> '0',								-- 1-bit input: Clock enable input for INMODEREG
		CEM							=> '0',								-- 1-bit input: Clock enable input for MREG
		CEP							=> '1',								-- 1-bit input: Clock enable input for PREG
		RSTA							=> '0',								-- 1-bit input: Reset input for AREG
		RSTALLCARRYIN				=> '0',								-- 1-bit input: Reset input for CARRYINREG
		RSTALUMODE					=> '0',								-- 1-bit input: Reset input for ALUMODEREG
		RSTB							=> '0',								-- 1-bit input: Reset input for BREG
		RSTC							=> '0',								-- 1-bit input: Reset input for CREG
		RSTCTRL						=> '0',								-- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
		RSTD							=> '0',								-- 1-bit input: Reset input for DREG and ADREG
		RSTINMODE					=> '0',								-- 1-bit input: Reset input for INMODEREG
		RSTM							=> '0',								-- 1-bit input: Reset input for MREG
		RSTP							=> '0'								-- 1-bit input: Reset input for PREG
	);

	s_opmode_lo <= '0' & s_BYPASS_n & "00011";

	--------------------
	-- ACCUMULATOR HI --
	--------------------

	ACC_48_HI_INST: DSP48E1 generic map (
		-- Feature Control Attributes: Data Path Selection
		A_INPUT					=> "DIRECT",							-- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
		B_INPUT					=> "DIRECT",							-- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
		USE_DPORT				=> FALSE,								-- Select D port usage (TRUE or FALSE)
		USE_MULT					=> "NONE",								-- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
		USE_SIMD					=> "ONE48",								-- SIMD selection ("ONE48", "TWO24", "FOUR12")
																				-- Pattern Detector Attributes: Pattern Detection Configuration
		AUTORESET_PATDET		=> "NO_RESET",							-- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH"
		MASK						=> X"3fffffffffff",					-- 48-bit mask value for pattern detect (1=ignore)
		PATTERN					=> X"000000000000",					-- 48-bit pattern match for pattern detect
		SEL_MASK					=> "MASK",								-- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2"
		SEL_PATTERN				=> "PATTERN",							-- Select pattern value ("PATTERN" or "C")
		USE_PATTERN_DETECT	=> "NO_PATDET",						-- Enable pattern detect ("PATDET" or "NO_PATDET")
																				-- Register Control Attributes: Pipeline Register Configuration
		ACASCREG					=> 0,										-- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
		ADREG						=> 0,										-- Number of pipeline stages for pre-adder (0 or 1)
		ALUMODEREG				=> 0,										-- Number of pipeline stages for ALUMODE (0 or 1)
		AREG						=> 0,										-- Number of pipeline stages for A (0, 1 or 2)
		BCASCREG					=> 2,										-- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
		BREG						=> 2,										-- Number of pipeline stages for B (0, 1 or 2)
		CARRYINREG				=> 0,										-- Number of pipeline stages for CARRYIN (0 or 1)
		CARRYINSELREG			=> 1,										-- Number of pipeline stages for CARRYINSEL (0 or 1)
		CREG						=> 1,										-- Number of pipeline stages for C (0 or 1)
		DREG						=> 0,										-- Number of pipeline stages for D (0 or 1)
		INMODEREG				=> 0,										-- Number of pipeline stages for INMODE (0 or 1)
		MREG						=> 0,										-- Number of multiplier pipeline stages (0 or 1)
		OPMODEREG				=> 1,										-- Number of pipeline stages for OPMODE (0 or 1)
		PREG						=> 1										-- Number of pipeline stages for P (0 or 1)
	)
	port map (
		-- Cascade: 30-bit (each) output: Cascade Ports
		ACOUT							=> open,												-- 30-bit output: A port cascade output
		BCOUT							=> open,												-- 18-bit output: B port cascade output
		CARRYCASCOUT				=> open,												-- 1-bit output: Cascade carry output
		MULTSIGNOUT					=> open,												-- 1-bit output: Multiplier sign cascade output
		PCOUT							=> open,												-- 48-bit output: Cascade output
																								-- Control: 1-bit (each) output: Control Inputs/Status Bits
		OVERFLOW						=> open,												-- 1-bit output: Overflow in add/acc output
		PATTERNBDETECT 			=> open,												-- 1-bit output: Pattern bar detect output
		PATTERNDETECT				=> open,												-- 1-bit output: Pattern detect output
		UNDERFLOW					=> open,												-- 1-bit output: Underflow in add/acc output
																								-- Data: 4-bit (each) output: Data Ports
		CARRYOUT						=> open,												-- 4-bit output: Carry output
		P(47 downto 25)		=> s_data_hi_open,					-- 48-bit output: Primary data output
		P(25-1 downto 0)		=> s_data_hi,							-- 48-bit output: Primary data output
																								-- Cascade: 30-bit (each) input: Cascade Ports
		ACIN							=> (others=>'0'),									-- 30-bit input: A cascade data input
		BCIN							=> (others=>'0'),									-- 18-bit input: B cascade input
		CARRYCASCIN					=> s_carry,											-- 1-bit input: Cascade carry input
		MULTSIGNIN					=> '0',												-- 1-bit input: Multiplier sign input
		PCIN							=> (others=>'0'),									-- 48-bit input: P cascade input
																								-- Control: 4-bit (each) input: Control Inputs/Status Bits
		ALUMODE						=> "0000",											-- 4-bit input: ALU control input
		CARRYINSEL					=> s_carry_sel,									-- 3-bit input: Carry select input
		CLK							=> CLK,												-- 1-bit input: Clock input
		INMODE						=> (others=>'0'),									-- 5-bit input: INMODE control input
		OPMODE						=> s_opmode_hi,									-- 7-bit input: Operation mode input
																								-- Data: 30-bit (each) input: Data Ports
		A								=> (others=>'0'),									-- 30-bit input: A data input
		B(17 downto 16)			=> (others=>'0'),									-- 18-bit input: B data input
		B(15 downto 0)				=> B(63 downto 48),								-- 18-bit input: B data input
		C								=> (others=>'0'),									-- 48-bit input: C data input
		CARRYIN						=> '0',												-- 1-bit input: Carry input signal

		D								=> (others=>'0'),									-- 25-bit input: D data input
																								-- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
		CEA1							=> '0',								-- 1-bit input: Clock enable input for 1st stage AREG
		CEA2							=> '0',								-- 1-bit input: Clock enable input for 2nd stage AREG
		CEAD							=> '0',								-- 1-bit input: Clock enable input for ADREG
		CEALUMODE					=> '0',								-- 1-bit input: Clock enable input for ALUMODE
		CEB1							=> '1',								-- 1-bit input: Clock enable input for 1st stage BREG
		CEB2							=> '1',								-- 1-bit input: Clock enable input for 2nd stage BREG
		CEC							=> '0',								-- 1-bit input: Clock enable input for CREG
		CECARRYIN					=> '0',								-- 1-bit input: Clock enable input for CARRYINREG
		CECTRL						=> '1',								-- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
		CED							=> '0',								-- 1-bit input: Clock enable input for DREG
		CEINMODE						=> '0',								-- 1-bit input: Clock enable input for INMODEREG
		CEM							=> '0',								-- 1-bit input: Clock enable input for MREG
		CEP							=> '1',								-- 1-bit input: Clock enable input for PREG
		RSTA							=> '0',								-- 1-bit input: Reset input for AREG
		RSTALLCARRYIN				=> '0',								-- 1-bit input: Reset input for CARRYINREG
		RSTALUMODE					=> '0',								-- 1-bit input: Reset input for ALUMODEREG
		RSTB							=> '0',								-- 1-bit input: Reset input for BREG
		RSTC							=> '0',								-- 1-bit input: Reset input for CREG
		RSTCTRL						=> '0',								-- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
		RSTD							=> '0',								-- 1-bit input: Reset input for DREG and ADREG
		RSTINMODE					=> '0',								-- 1-bit input: Reset input for INMODEREG
		RSTM							=> '0',								-- 1-bit input: Reset input for MREG
		RSTP							=> '0'								-- 1-bit input: Reset input for PREG
	);

	s_opmode_hi <= '0' & r_BYPASS_n & "00011";

	s_BYPASS_n <= not BYPASS;

	s_carry_sel <= '0' & r_BYPASS_n & '0';


	ACC_LO_DELAYER_INST: entity work.data_delayer generic map (
		g_data_width			=> C_DSP_DATA_WIDTH,								--: natural := 1;
		g_delay					=> 2									--: natural := 15
	)
	port map (
		pi_clk					=> CLK,								--: in std_logic;
		pi_data					=> s_data_lo,						--: in std_logic_vector(g_data_width-1 downto 0);
		po_data					=> s_data_lo_dly					--: out std_logic_vector(g_data_width-1 downto 0)
	);

	ACC_HI_DELAYER_INST: entity work.data_delayer generic map (
		g_data_width			=> c_data_hi_width,				--: natural := 1;
		g_delay					=> 1									--: natural := 15
	)
	port map (
		pi_clk					=> CLK,								--: in std_logic;
		pi_data					=> s_data_hi,						--: in std_logic_vector(g_data_width-1 downto 0);
		po_data					=> s_data_hi_dly					--: out std_logic_vector(g_data_width-1 downto 0)
	);

	Q <= s_data_hi_dly & s_data_lo_dly;


	process(CLK)
	begin
		if(rising_edge(CLK)) then

			----------------
			-- R_BYPASS_N --
			----------------
			r_BYPASS_n <= s_BYPASS_n;

		end if;
	end process;


end architecture;
