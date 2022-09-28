------------------------------------------------------------------------------
--
-- Description :  Simple Axi to Axi-Stream
--
------------------------------------------------------------------------------
--
-- History :
--  05/02/2020 Radoslaw Wrobel                                  : version 1.0
--             Created
--
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.numeric_std.all;

entity Axi2AxiStream is
	generic (
		AXI4_DATA_WIDTH			: integer := 64;
		AXI_STREAM_DATA_WIDTH	: integer := 64;
		AXI4_ID_WIDTH			: integer := 8
	);
	port (
		S00_AXI_araddr		: in STD_LOGIC_VECTOR ( 47 downto 0 );
		S00_AXI_arburst		: in STD_LOGIC_VECTOR ( 1 downto 0 );
		S00_AXI_arcache		: in STD_LOGIC_VECTOR ( 3 downto 0 );
		S00_AXI_arid			: in STD_LOGIC_VECTOR ( AXI4_ID_WIDTH-1 downto 0 );
		S00_AXI_arlen		: in STD_LOGIC_VECTOR ( 7 downto 0 );
		S00_AXI_arlock		: in STD_LOGIC_VECTOR ( 0 to 0 );
		S00_AXI_arprot		: in STD_LOGIC_VECTOR ( 2 downto 0 );
		S00_AXI_arqos		: in STD_LOGIC_VECTOR ( 3 downto 0 );
		S00_AXI_arready		: out STD_LOGIC;
		S00_AXI_arregion		: in STD_LOGIC_VECTOR ( 3 downto 0 );
		S00_AXI_arsize		: in STD_LOGIC_VECTOR ( 2 downto 0 );
		S00_AXI_arvalid		: in STD_LOGIC;
		S00_AXI_awaddr		: in STD_LOGIC_VECTOR ( 47 downto 0 );
		S00_AXI_awburst		: in STD_LOGIC_VECTOR ( 1 downto 0 );
		S00_AXI_awcache		: in STD_LOGIC_VECTOR ( 3 downto 0 );
		S00_AXI_awid			: in STD_LOGIC_VECTOR ( AXI4_ID_WIDTH-1 downto 0 );
		S00_AXI_awlen		: in STD_LOGIC_VECTOR ( 7 downto 0 );
		S00_AXI_awlock		: in STD_LOGIC_VECTOR ( 0 to 0 );
		S00_AXI_awprot		: in STD_LOGIC_VECTOR ( 2 downto 0 );
		S00_AXI_awqos		: in STD_LOGIC_VECTOR ( 3 downto 0 );
		S00_AXI_awready		: out STD_LOGIC;
		S00_AXI_awregion		: in STD_LOGIC_VECTOR ( 3 downto 0 );
		S00_AXI_awsize		: in STD_LOGIC_VECTOR ( 2 downto 0 );
		S00_AXI_awvalid		: in STD_LOGIC;
		S00_AXI_bid			: out STD_LOGIC_VECTOR ( AXI4_ID_WIDTH-1 downto 0 );
		S00_AXI_bready		: in STD_LOGIC;
		S00_AXI_bresp		: out STD_LOGIC_VECTOR ( 1 downto 0 );
		S00_AXI_bvalid		: out STD_LOGIC;
		S00_AXI_rdata		: out STD_LOGIC_VECTOR ( AXI4_DATA_WIDTH-1 downto 0 );
		S00_AXI_rid			: out STD_LOGIC_VECTOR ( AXI4_ID_WIDTH-1 downto 0 );
		S00_AXI_rlast		: out STD_LOGIC;
		S00_AXI_rready		: in STD_LOGIC;
		S00_AXI_rresp		: out STD_LOGIC_VECTOR ( 1 downto 0 );
		S00_AXI_rvalid		: out STD_LOGIC;
		S00_AXI_wdata		: in STD_LOGIC_VECTOR ( AXI4_DATA_WIDTH-1 downto 0 );
		S00_AXI_wlast		: in STD_LOGIC;
		S00_AXI_wready		: out STD_LOGIC;
		S00_AXI_wstrb		: in STD_LOGIC_VECTOR ( (AXI4_DATA_WIDTH/8)-1 downto 0 );
		S00_AXI_wvalid		: in STD_LOGIC;

		s_axis_mm2s_tvalid	: out std_logic;
		s_axis_mm2s_tdata	: out std_logic_vector(AXI_STREAM_DATA_WIDTH-1 downto 0);
		s_axis_mm2s_tkeep	: out std_logic_vector(3 downto 0);
		s_axis_mm2s_tlast	: out std_logic;
		s_axis_mm2s_tuser	: out std_logic_vector ( 0 to 0 );
		s_axis_mm2s_tready	: in  std_logic;

		clk 					: in std_logic;
		rstn					: in std_logic
	);
end Axi2AxiStream;

architecture rtl of Axi2AxiStream is

	type AXIS_StateMachine is (IDLE, SEND_DATA, WAITING, FINISH);
	type AXI4_StateMachine is (IDLE, GET_DATA, WAITING,WAITING64, FINISH);
	signal AXIS_BUS : AXIS_StateMachine;
	signal AXI4_BUS : AXI4_StateMachine;

	type MEM_TYPE is array (0 to 16) of std_logic_vector(7 downto 0);
	signal DATAi : MEM_TYPE;
	signal DATAi64out : MEM_TYPE;
	signal bytes_to_transfer : integer range 0 to 2*8 := 0;
	signal data_ctr : integer range 0 to 2 := 0;

	--signal DATAi					: std_logic_vector(AXI_STREAM_DATA_WIDTH-1 downto 0);
	signal AWREADYi					: std_logic := '0';
	signal ARREADYi					: std_logic := '0';
	signal WREADYi					: std_logic := '0';
	signal AWADDRi					: std_logic_vector(47 downto 0);
	signal ARADDRi					: std_logic_vector(47 downto 0);
	signal WRITEi					: std_logic := '0';
	signal READi						: std_logic := '0';
	signal LASTi						: std_logic := '0';
	signal AWIDi						: std_logic_vector(AXI4_ID_WIDTH-1 downto 0);
	signal ARIDi						: std_logic_vector(AXI4_ID_WIDTH-1 downto 0);
	signal tvalid_int				: std_logic;
	signal bvalid_int				: std_logic;
	signal counterD					: integer range 0 to 2 := 0;
	signal bytes_to_transfer64out	: integer range 0 to 2*8 := 0;

begin

	S00_AXI_awready	<= AWREADYi;
	S00_AXI_arready	<= ARREADYi;
	S00_AXI_wready	<= WREADYi;

	-- Addres --
	ADDRES_PROC: process(clk, rstn)
	begin
		if rstn = '0' then
			ARREADYi	<= '1';
			READi		<= '0';
			WRITEi		<= '0';
			counterD    <= 0;
		elsif rising_edge(clk) then
			if S00_AXI_awvalid = '1' and AWREADYi = '1' then
				counterD    <= 0;
				AWADDRi		<= S00_AXI_awaddr;
				WRITEi		<= '1';
				AWIDi	 	<= S00_AXI_awid;
				if S00_AXI_awburst = "01" and S00_AXI_awlen = x"00" and S00_AXI_awaddr(2) = '0'  then
					counterD <= 1;
				end if;
				if S00_AXI_awburst = "01" and S00_AXI_awlen = x"00" and S00_AXI_awaddr(2) = '1'  then
					counterD <= 2;
				end if;
			end if;
			if S00_AXI_arvalid = '1' and ARREADYi = '1' then
				ARADDRi		<= S00_AXI_araddr;
				READi		<= '1';
				ARIDi		<= S00_AXI_arid;
			end if;
			if READi = '1' and S00_AXI_rready = '1' then
				READi <= '0';
			end if;
			if WRITEi = '1' and S00_AXI_wvalid = '1' and WREADYi = '1' then
				WRITEi <= '0';
			end if;
		end if;
	end process;

	-- DATA READ---
	DATA_READ_PROC: process(clk, rstn)
	begin
		if rstn = '0' then
			S00_AXI_rvalid	<= '0';
			S00_AXI_rid		<= (others=>'0');
			S00_AXI_rresp	<= (others=>'0');
			S00_AXI_rlast	<= '0';
			S00_AXI_rdata	<= (others=>'0');
		elsif rising_edge(clk) then
			if S00_AXI_rready = '1' and READi = '1' then
				S00_AXI_rlast	<= '1';
				S00_AXI_rdata	<= (others=>'0');
				S00_AXI_rvalid	<= '1';
				S00_AXI_rid		<= ARIDi;
			else
				S00_AXI_rlast	<= '0';
				S00_AXI_rvalid	<= '0';
				S00_AXI_rdata	<= (others=>'0');
			end if;
		end if;
	end process;

	-- DATA WRITE---
	DATA_WRITE_PROC: process(clk, rstn)
		variable byte_ctr : integer range 0 to 8*256 := 0;
	begin
		if rstn = '0' then
			WREADYi <= '0';
			bvalid_int <= '0';
			byte_ctr := 0;
			bytes_to_transfer <= 0;
			AXI4_BUS <= IDLE;
			AWREADYi	<= '1';
		elsif rising_edge(clk) then
			case AXI4_BUS is
				when IDLE =>
					AWREADYi <= '1';
					WREADYi <= '1';
					LASTi	<= '0';
					bvalid_int <= '0';
					byte_ctr := 0;
					bytes_to_transfer <= 0;
					AXI4_BUS <= IDLE;
					if S00_AXI_wvalid = '1' and WREADYi = '1' then
						AWREADYi <= '0';
						for i in 0 to (AXI4_DATA_WIDTH/8)-1 loop
							if (S00_AXI_wstrb(i) = '1') then
								DATAi(bytes_to_transfer+byte_ctr) <= S00_AXI_wdata((i+1)*8 -1 downto i*8 );
								DATAi64out(bytes_to_transfer64out+bytes_to_transfer+byte_ctr) <= S00_AXI_wdata((i+1)*8 -1 downto i*8 );
								byte_ctr := byte_ctr + 1;
							end if;
						end loop;
						bytes_to_transfer <= bytes_to_transfer + byte_ctr;
						LASTi <= S00_AXI_wlast;
						if S00_AXI_wlast = '1' then
							AXI4_BUS	<= WAITING64;
							bvalid_int	<= '1';
							WREADYi		<= '0';
						else
							AXI4_BUS	<= GET_DATA;
						end if;
					end if;
				when GET_DATA =>
					AXI4_BUS <= GET_DATA;
					LASTi	 <= '0';
					byte_ctr := 0;
					if S00_AXI_wvalid = '1' and WREADYi = '1' then
						for i in 0 to (AXI4_DATA_WIDTH/8)-1 loop
							if (S00_AXI_wstrb(i) = '1') then
								DATAi(bytes_to_transfer+byte_ctr) <= S00_AXI_wdata((i+1)*8 -1 downto i*8 ) ;
								byte_ctr := byte_ctr + 1;
							end if;
						end loop;
						bytes_to_transfer <= bytes_to_transfer + byte_ctr;
						LASTi		<= S00_AXI_wlast;
						if S00_AXI_wlast = '1' then
							AXI4_BUS 	<= WAITING;
							AWREADYi	<= '0';
							bvalid_int <= '1';
						else
							AXI4_BUS 	<= GET_DATA;
						end if;
					end if;
				when WAITING =>
					bytes_to_transfer64out <= 0;
					if AXIS_BUS = FINISH then
						AXI4_BUS 	<= FINISH;
					else
						AXI4_BUS 	<= WAITING;
					end if;
				when WAITING64 =>
					bytes_to_transfer64out <= bytes_to_transfer;
					if counterD = 1 then
						AXI4_BUS <= FINISH;
					else
						AXI4_BUS <= WAITING;
					end if;
					WREADYi <= '0';
					LASTi <= S00_AXI_wlast;
					bvalid_int <= '0';
				when FINISH =>
					LASTi <= '0';
					WREADYi <= '0';
					AXI4_BUS <= IDLE;
				when others =>
					WREADYi <= '0';
					LASTi <= '0';
					AXI4_BUS <= IDLE;
			end case;
		end if;
	end process;

	-- BVALID---
	BVALID_PROC: process(clk, rstn)
	begin
		if rstn = '0' then
			S00_AXI_bvalid 	<= '0';
			S00_AXI_bid 	<= (others=>'0');
			S00_AXI_bresp 	<= (others=>'0');
		elsif rising_edge(clk) then
			if S00_AXI_bready = '1' then
				S00_AXI_bvalid	<= '0';
			end if;
			if bvalid_int = '1' then
				S00_AXI_bvalid 	<= '1';
				S00_AXI_bid 	<= AWIDi;
			end if;
		end if;
	end process;



	PRODUCE_AXIS_SLAVE: process(clk, rstn)
	begin
		if rstn = '0' then
			s_axis_mm2s_tvalid 	<= '0';
			s_axis_mm2s_tdata 	<= (others=>'0');
			s_axis_mm2s_tkeep	<= (others=>'0');
			s_axis_mm2s_tlast	<= '0';
			s_axis_mm2s_tuser 	<= "0";
			tvalid_int <= '0';
			data_ctr <= 0;
			AXIS_BUS <= IDLE;
		elsif rising_edge(clk) then
			case AXIS_BUS is
				when IDLE =>
					s_axis_mm2s_tvalid	<= '0';
					s_axis_mm2s_tkeep	<= (others=>'0');
					s_axis_mm2s_tuser	<= "0";
					s_axis_mm2s_tlast	<= '0';
					tvalid_int			<= '0';
					data_ctr			<= 0;
					if AXI4_BUS = WAITING then
						if s_axis_mm2s_tready = '1' then
							AXIS_BUS <= SEND_DATA;
						else
							AXIS_BUS <= WAITING;
						end if;
						for i in 0 to (AXI_STREAM_DATA_WIDTH/8)-1 loop
							if counterD = 2 then
								s_axis_mm2s_tdata((i+1)*8 -1 downto i*8) <= DATAi64out(i);
							else
								s_axis_mm2s_tdata((i+1)*8 -1 downto i*8) <= DATAi(i);
							end if;
						end loop;
						if ( (AXI_STREAM_DATA_WIDTH/8) * (data_ctr + 1) ) > (bytes_to_transfer-1) then
							s_axis_mm2s_tlast <= '1';
							if s_axis_mm2s_tready = '1' then
								AXIS_BUS <= FINISH;
							else
								AXIS_BUS <= WAITING;
							end if;
						else
							s_axis_mm2s_tlast <= '0';
						end if;
						s_axis_mm2s_tuser <= "0";
						s_axis_mm2s_tvalid <= '1';
						s_axis_mm2s_tkeep <= (others=>'1');
						tvalid_int <= '1';
						data_ctr <= data_ctr + 1;
					else
						AXIS_BUS <= IDLE;
					end if;
				when SEND_DATA =>
					for i in 0 to (AXI_STREAM_DATA_WIDTH/8)-1 loop
						s_axis_mm2s_tdata((i+1)*8 -1 downto i*8) <= DATAi((AXI_STREAM_DATA_WIDTH/8) * data_ctr + i);
					end loop;
					s_axis_mm2s_tuser <= "0";
					s_axis_mm2s_tvalid <= '1';
					s_axis_mm2s_tkeep <= (others=>'1');
					tvalid_int <= '1';
					if s_axis_mm2s_tready = '1' then
						if ( (AXI_STREAM_DATA_WIDTH/8) * (data_ctr + 1) ) > (bytes_to_transfer - 1) then
							s_axis_mm2s_tlast <= '1';
							AXIS_BUS <= FINISH;
						else
							s_axis_mm2s_tlast <= '0';
							data_ctr <= data_ctr + 1;
							AXIS_BUS <= SEND_DATA;
						end if;
					else
						AXIS_BUS <= WAITING;
					end if;
				when WAITING =>
					if s_axis_mm2s_tready = '1' then
						for i in 0 to (AXI_STREAM_DATA_WIDTH/8)-1 loop
							s_axis_mm2s_tdata((i+1)*8 -1 downto i*8) <= DATAi((AXI_STREAM_DATA_WIDTH/8) * data_ctr + i);
						end loop;
						if ( (AXI_STREAM_DATA_WIDTH/8) * (data_ctr + 1) ) > (bytes_to_transfer - 1) then
							s_axis_mm2s_tlast <= '1';
							AXIS_BUS <= FINISH;
						else
							s_axis_mm2s_tlast <= '0';
							data_ctr <= data_ctr + 1;
							AXIS_BUS <= SEND_DATA;
						end if;
						s_axis_mm2s_tuser <= "0";
						s_axis_mm2s_tvalid <= '1';
						s_axis_mm2s_tkeep <= (others=>'1');
						tvalid_int <= '1';
					else
						AXIS_BUS <= WAITING;
					end if;
				when FINISH =>
					s_axis_mm2s_tvalid 	<= '0';
					s_axis_mm2s_tdata	<= (others=>'0');
					s_axis_mm2s_tkeep 	<= (others=>'0');
					s_axis_mm2s_tuser 	<= "0";
					s_axis_mm2s_tlast 	<= '0';
					tvalid_int 			<= '0';
					AXIS_BUS 			<= IDLE;
				when others =>
					AXIS_BUS 			<= IDLE;
					s_axis_mm2s_tvalid 	<= '0';
					tvalid_int 			<= '0';
			end case;
		end if;
	end process;

end architecture rtl;
