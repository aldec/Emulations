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
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity AxiStream2Axi is
generic (
    AXI4_BASE_ADDRESS		: std_logic_vector(47 downto 0) := X"0000_0000_0000";
	AXI4_DATA_WIDTH			: integer := 256;
    AXI_STREAM_DATA_WIDTH	: integer := 32;
	AWSIZE					: std_logic_vector ( 2 downto 0 ) := "010"
    );
 port (
	M00_AXI_araddr		: out STD_LOGIC_VECTOR ( 47 downto 0 );
	M00_AXI_arburst		: out STD_LOGIC_VECTOR ( 1 downto 0 );
	M00_AXI_arcache		: out STD_LOGIC_VECTOR ( 3 downto 0 );
	M00_AXI_arid		: out STD_LOGIC_VECTOR ( 7 downto 0 );
	M00_AXI_arlen		: out STD_LOGIC_VECTOR ( 7 downto 0 );
	M00_AXI_arlock		: out STD_LOGIC_VECTOR ( 0 to 0 );
	M00_AXI_arprot		: out STD_LOGIC_VECTOR ( 2 downto 0 );
	M00_AXI_arready		: in STD_LOGIC;
	M00_AXI_arsize		: out STD_LOGIC_VECTOR ( 2 downto 0 );
	M00_AXI_arvalid		: out STD_LOGIC;
	M00_AXI_awaddr		: out STD_LOGIC_VECTOR ( 47 downto 0 );
	M00_AXI_awburst		: out STD_LOGIC_VECTOR ( 1 downto 0 );
	M00_AXI_awcache		: out STD_LOGIC_VECTOR ( 3 downto 0 );
	M00_AXI_awid		: out STD_LOGIC_VECTOR ( 7 downto 0 );
	M00_AXI_awlen		: out STD_LOGIC_VECTOR ( 7 downto 0 );
	M00_AXI_awlock		: out STD_LOGIC_VECTOR ( 0 to 0 );
	M00_AXI_awprot		: out STD_LOGIC_VECTOR ( 2 downto 0 );
	M00_AXI_awready		: in STD_LOGIC;
	M00_AXI_awsize		: out STD_LOGIC_VECTOR ( 2 downto 0 );
	M00_AXI_awvalid		: out STD_LOGIC;
	M00_AXI_bid			: in STD_LOGIC_VECTOR ( 7 downto 0 );
	M00_AXI_bready		: out STD_LOGIC;
	M00_AXI_bresp		: in STD_LOGIC_VECTOR ( 1 downto 0 );
	M00_AXI_bvalid		: in STD_LOGIC;
	M00_AXI_rdata		: in STD_LOGIC_VECTOR ( AXI4_DATA_WIDTH-1 downto 0 );
	M00_AXI_rid			: in STD_LOGIC_VECTOR ( 7 downto 0 );
	M00_AXI_rlast		: in STD_LOGIC;
	M00_AXI_rready		: out STD_LOGIC;
	M00_AXI_rresp		: in STD_LOGIC_VECTOR ( 1 downto 0 );
	M00_AXI_rvalid		: in STD_LOGIC;
	M00_AXI_wdata		: out STD_LOGIC_VECTOR ( AXI4_DATA_WIDTH-1 downto 0 );
	M00_AXI_wlast		: out STD_LOGIC;
	M00_AXI_wready		: in STD_LOGIC;
	M00_AXI_wstrb		: out STD_LOGIC_VECTOR ( (AXI4_DATA_WIDTH/8)-1 downto 0 );
	M00_AXI_wvalid		: out STD_LOGIC;	
	
	m_axis_mm2s_tvalid 	: in  std_logic;
	m_axis_mm2s_tdata 	: in  std_logic_vector(AXI_STREAM_DATA_WIDTH-1 downto 0);
	m_axis_mm2s_tkeep 	: in  std_logic_vector(3 downto 0);
	m_axis_mm2s_tlast 	: in  std_logic;
	m_axis_mm2s_tuser	: in  std_logic_vector ( 0 to 0 );	
	m_axis_mm2s_tready 	: out std_logic;	
	
	clk 				: in std_logic;
	rstn				: in std_logic;
	IRQ					: out std_logic
 );
end AxiStream2Axi;

architecture rtl of AxiStream2Axi is

	type MEM_TYPE is array (0 to 255) of std_logic_vector(AXI4_DATA_WIDTH-1 downto 0);
	type AXI4_StateMachine is (IDLE, WR_ADDR, WR_DATA, WR_RESP, FINISH);
	type AXIS_StateMachine is (IDLE, GET_DATA, WAITING, FINISH);	
	signal AXIS_BUS : AXIS_StateMachine;
	signal AXI4_BUS : AXI4_StateMachine;	
	signal MEM : MEM_TYPE;
	signal burst_ctr : integer range 0 to 256 := 0;
	signal data_ctr : integer range 0 to 256 := 0;
	signal start : std_logic;

	signal DATAi		: std_logic_vector(AXI4_DATA_WIDTH-1 downto 0);
	signal AWVALIDi 	: std_logic := '0';
	signal ARVALIDi 	: std_logic := '0';
	signal WVALIDi	 	: std_logic := '0';	
	signal RREADYi	 	: std_logic := '0';	
	signal WRITEi	 	: std_logic := '0';
	signal READi	 	: std_logic := '0';
	signal LASTi	 	: std_logic := '0';
	signal AWIDi		: std_logic_vector(7 downto 0);
	signal ARIDi		: std_logic_vector(7 downto 0);
	signal TREADYi		: std_logic;	
	
begin

	M00_AXI_arvalid	<= ARVALIDi;
	M00_AXI_rready	<= RREADYi;	

	-- DATA READ---
	DATA_READ_PROC: process(clk, rstn)
	begin
		if rstn = '0' then
			ARVALIDi <= '0';
			M00_AXI_araddr <= (others => '0');
			M00_AXI_arburst <= (others => '0');
			M00_AXI_arcache <= (others => '0');
			M00_AXI_arid <= (others => '0');
			M00_AXI_arlen <= (others => '0');
			M00_AXI_arlock <= (others => '0');
			M00_AXI_arprot <= (others => '0');
			M00_AXI_arsize <= (others => '0');			
		elsif rising_edge(clk) then
			--TO DO READ CHANNEL
			RREADYi <= '0';
		end if;
	end process;

	-- DATA WRITE---
	DATA_WRITE_PROC: process(clk, rstn)
	begin
		if rstn = '0' then	
			M00_AXI_awaddr 		<= (others => '0');	
			M00_AXI_awburst 	<= (others => '0');	
			M00_AXI_awcache 	<= (others => '0');	
			M00_AXI_awid 		<= (others => '0');	
			M00_AXI_awlen 		<= (others => '0');	
			M00_AXI_awlock 		<= (others => '0');	
			M00_AXI_awprot 		<= (others => '0');	
			M00_AXI_awsize 		<= (others => '0');	
			M00_AXI_bready		<= '0';
			M00_AXI_wdata 		<= (others => '0');
			M00_AXI_wlast 		<= '0';
			M00_AXI_wstrb 		<= (others => '0');		
			M00_AXI_awvalid		<= '0';
			M00_AXI_wvalid		<= '0';
			data_ctr			<= 0;
			IRQ					<= '0';
			AXI4_BUS 			<= IDLE;
		elsif rising_edge(clk) then
			case AXI4_BUS is
				when IDLE =>
					M00_AXI_awvalid		<= '0';
					M00_AXI_wvalid		<= '0';	
					M00_AXI_awaddr 		<= (others => '0');
					M00_AXI_bready		<= '0';
					M00_AXI_wdata 		<= (others => '0');
					M00_AXI_wlast 		<= '0';
					M00_AXI_wstrb 		<= (others => '0');
					data_ctr			<= 0;
					IRQ					<= '0';
					if start = '1' then
		                if (M00_AXI_awready = '1') then
							AXI4_BUS		<= WR_DATA;
		                else
							AXI4_BUS		<= WR_ADDR;
						end if;					
						M00_AXI_awvalid		<= '1';
						M00_AXI_awaddr		<= AXI4_BASE_ADDRESS;
		                M00_AXI_awid     	<= "00000100";
		                M00_AXI_awburst		<= "01";
		                M00_AXI_awsize	   	<= AWSIZE;
		                M00_AXI_awlen    	<= conv_std_logic_vector((burst_ctr-1), 8);												
					else
						AXI4_BUS 		<= IDLE;
					end if;	
				when WR_ADDR =>
		                if (M00_AXI_awready = '1') then
							M00_AXI_awvalid		<= '0';
							M00_AXI_awid		<= (others => '0');
							M00_AXI_awburst		<= (others => '0');
							M00_AXI_awsize		<= (others => '0');
							M00_AXI_awlen		<= (others => '0');
							M00_AXI_awaddr		<= (others => '0');
							M00_AXI_wvalid   	<= '1';
							M00_AXI_wstrb		<= (others => '1');	
							M00_AXI_wdata    	<= MEM(data_ctr);
			            	if ( data_ctr = ( burst_ctr - 1 ) ) then 
								M00_AXI_wlast <= '1';
								AXI4_BUS <= WR_RESP;
			            	else 
								M00_AXI_wlast <= '0';
								AXI4_BUS <= WR_DATA;
							end if;
							data_ctr 			<= data_ctr + 1;
		                else
							AXI4_BUS		<= WR_ADDR;
						end if;											
		        when WR_DATA =>
					if (M00_AXI_wready = '1') then
		            	if ( data_ctr = ( burst_ctr - 1 ) ) then 
							M00_AXI_wlast <= '1';
							AXI4_BUS <= WR_RESP;
		            	else 
							M00_AXI_wlast <= '0';
							AXI4_BUS <= WR_DATA;
						end if;
		                M00_AXI_wvalid   	<= '1';
		                M00_AXI_wstrb		<= (others => '1');	
	                	M00_AXI_wdata    	<= MEM(data_ctr);
						data_ctr 			<= data_ctr + 1;							
					end if;
	                M00_AXI_awvalid  	<= '0';
	                M00_AXI_awid     	<= (others => '0');
	                M00_AXI_awburst  	<= (others => '0');
	                M00_AXI_awsize   	<= (others => '0');
	                M00_AXI_awlen   	<= (others => '0');
					M00_AXI_awaddr   	<= (others => '0');							
		        when WR_RESP =>
					if (M00_AXI_wready = '1') then	
		                M00_AXI_awvalid		<= '0';
		                M00_AXI_awid		<= (others => '0');
		                M00_AXI_awburst		<= (others => '0');
		                M00_AXI_awsize		<= (others => '0');
		                M00_AXI_awlen		<= (others => '0');
		                M00_AXI_awaddr		<= (others => '0');
		                M00_AXI_wvalid      <= '0';
		                M00_AXI_wlast       <= '0';
		                M00_AXI_wstrb       <= (others => '0');
		                M00_AXI_wdata       <= (others => '0');
					end if;
		            if (M00_AXI_bvalid = '1') then
		                AXI4_BUS 		<= FINISH;
		                M00_AXI_bready	<= '1';
						IRQ				<= '1';
		            end if;				
				when FINISH =>
					if(start = '0') then
						AXI4_BUS <= IDLE;
					else
						AXI4_BUS <= FINISH;
					end if;
					M00_AXI_bready	<= '0';
				when others =>		
					AXI4_BUS <= IDLE;
			end case;	
		end if;
	end process;

	PRODUCE_AXIS_MASTER: process(clk, rstn)
	begin
	  	if rstn = '0' then
			AXIS_BUS <= IDLE;
			m_axis_mm2s_tready 	<= '0';
	  	elsif rising_edge( clk) then
			case AXIS_BUS is
			    when IDLE => 
					m_axis_mm2s_tready <= '0';
					AXIS_BUS <= IDLE;
					burst_ctr <= 0;				
					if m_axis_mm2s_tvalid = '1' then
						AXIS_BUS <= GET_DATA;
						m_axis_mm2s_tready <= '1';
					end if; 
			    when GET_DATA => 
					AXIS_BUS <= GET_DATA;
					if (m_axis_mm2s_tvalid = '1') then
						AXIS_BUS <= GET_DATA;
						m_axis_mm2s_tready <= '1';
						if(burst_ctr < 256) then
							MEM(burst_ctr) <= m_axis_mm2s_tdata; 
							burst_ctr <= burst_ctr + 1;
						end if;
					end if;
					if(m_axis_mm2s_tlast = '1') then
						start <= '1';
						m_axis_mm2s_tready <= '0';
						AXIS_BUS <= WAITING;
					end if;			
			    when WAITING =>  
					if (AXI4_BUS = FINISH) then 
						AXIS_BUS <= IDLE;
						start <= '0';
					else 
						AXIS_BUS <= WAITING;
						start <= '1';
						m_axis_mm2s_tready <= '0' ;
					end if;
				when others => 	
					AXIS_BUS <= IDLE;
					start <= '0';
					m_axis_mm2s_tready <= '0';
			end case; 
		end if;
	end process;

end architecture rtl;
