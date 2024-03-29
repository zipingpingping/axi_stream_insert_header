module axi_stream_insert_header #(
		parameter DATA_WD = 32,
		parameter DATA_BYTE_WD = DATA_WD / 8,
		parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
		input 								clk,
		input 								rst_n,
		
		//	AXI Stream input original data
		input 								valid_in,
		input [DATA_WD-1 : 0] 			data_in,
		input [DATA_BYTE_WD-1 : 0] 	keep_in,
		input 								last_in,
		output 								ready_in,
		
		// AXI Stream output with header inserted
		output 								valid_out,
		output [DATA_WD-1 : 0] 			data_out,
		output [DATA_BYTE_WD-1 : 0] 	keep_out,
		output 								last_out,
		input 								ready_out,

		// The header to be inserted to AXI Stream input
		input 								valid_insert,
		input [DATA_WD-1 : 0] 			data_insert,
		input [DATA_BYTE_WD-1 : 0] 	keep_insert,
		input [BYTE_CNT_WD-1 : 0] 		byte_insert_cnt,
		output 								ready_insert
		);

// Your code here	
		
/*
***********************************************************************************
								  data	channel	logic	begin
***********************************************************************************
*/

//ready_in	logic				

reg	[DATA_WD-1 : 0] 					last_in1;
reg	[DATA_WD-1 : 0] 					last_in2;
always@(posedge	clk	or	negedge	rst_n)begin
if(!rst_n)begin
												last_in1 <= 'd0;
												last_in2 <= 'd0;
end
else		begin
												last_in1 <= last_in;
												last_in2 <= last_in1;
			end
end

//find the rise edge	of	tlast
wire											data_tlast_rise_edge;
assign										data_tlast_rise_edge = last_in1 & (~last_in2);

wire											ready_in_r;
assign										ready_in_r = ~data_tlast_rise_edge;
assign										ready_in   = ready_in_r;

//cache the keep_in
wire		[DATA_BYTE_WD-1 : 0] 		keep_reg;
assign										keep_reg = (!rst_n)?'d0 : (last_in1)?keep_in:keep_reg;

//data_in	logic

reg			[DATA_WD-1 : 0] 			data_in_r1;
reg			[DATA_WD-1 : 0] 			data_in_r2;	
					

always@(posedge	clk	or	negedge	rst_n)begin
if(!rst_n)begin
												data_in_r1 <= 'd0;
												data_in_r2 <= 'd0;
end
else		if(valid_in&&ready_in_r)begin
												data_in_r1 <= data_in;
												data_in_r2 <= data_in_r1;
											end
else
											begin
												data_in_r1 <= data_in_r1;
												data_in_r2 <= data_in_r2;
											end
end	

/*
***********************************************************************************
								  data	channel	logic	end
***********************************************************************************
*/


/*
***********************************************************************************
								  header	channel	logic	begin
***********************************************************************************
*/

//data_insert	logic				

reg		[DATA_WD-1 : 0] 				data_insert_r;
reg		[DATA_BYTE_WD-1 : 0] 		keep_insert_r;
reg											insert_busy;

always@(posedge	clk	or	negedge	rst_n)begin
if(!rst_n)begin
												data_insert_r <= 'd0;
												keep_insert_r    <= 'd0;
												insert_busy	  <= 'd0;

end
else	if(valid_insert&&ready_insert)begin
							case(keep_insert)
									4'b1111 :begin
												data_insert_r <= data_insert;
												keep_insert_r	  <= keep_insert;
												insert_busy   <= 'd1;
												end
									
									4'b0111:	begin
												data_insert_r <= {8'd0,data_insert[23:0]};
												keep_insert_r	  <= keep_insert;
												insert_busy   <= 'd1;
												end
										
									4'b0011:	begin
												data_insert_r <= {16'd0,data_insert[15:0]};
												keep_insert_r	  <= keep_insert;
												insert_busy   <= 'd1;
												end
									
									4'b0001:	begin
												data_insert_r <= {24'd0,data_insert[7:0]};
												keep_insert_r	  <= keep_insert;
												insert_busy   <= 'd1;
												end
									
									default:	begin
												data_insert_r <= data_insert_r;
												keep_insert_r	  <= keep_insert;
												insert_busy   <= 'd1;
												end
							endcase
						end
else	
												insert_busy   <= 'd0;
												
					
end			
									
								
//ready_insert	logic			
	
reg											ready_insert_r;								
always@(posedge	clk	or	negedge	rst_n)
if(!rst_n)
												ready_insert_r <= 'd0;
else	if(valid_insert&&ready_insert)
												ready_insert_r <= 'd0;
else
												ready_insert_r <= 'd1;
												
assign										ready_insert   =   ready_insert_r;			

//cache	the keep_insert
reg			[DATA_BYTE_WD-1 : 0]		keep_insert_reg;
always@(posedge	clk	or	negedge	rst_n)
if(!rst_n)		
												keep_insert_reg <= 'd0;
else	if(insert_busy)
												keep_insert_reg <= keep_insert;
else
												keep_insert_reg <= keep_insert_reg;
		
			
/*
***********************************************************************************
								  header	channel	logic	end
***********************************************************************************
*/
							

/*
***********************************************************************************
								  header	insert in data	logic	begin
***********************************************************************************
*/

//data_in+header	logic
reg 	[DATA_WD-1 : 0] 					data_out_r;

always@(posedge	clk	or	negedge	rst_n)begin
if(!rst_n)begin
												data_out_r <= 'd0;
										end
else	if(insert_busy)begin												//insert	header	stage
								case(keep_insert)
									4'b1111 :begin
												data_out_r 	<= data_insert_r;
												end
												
									4'b0111:	begin
												data_out_r <= {data_insert[23:0],data_in_r1[31:24]};
												end
										
									4'b0011:	begin
												data_out_r <= {data_insert[15:0],data_in_r1[31:16]};
												end
									
									4'b0001:	begin
												data_out_r <= {data_insert[7:0],data_in_r1[31:8]};
												end
									
									default:	begin
												data_out_r <= data_out_r;
												end
								endcase
							end
else	begin																	//transfer	datain
								case(keep_insert_r)
									4'b1111 :begin
												data_out_r 	<= data_in_r2;
												end
												
									4'b0111:	begin
												data_out_r  <= {data_in_r2[23:0],data_in_r1[31:24]};
												end
										
									4'b0011:	begin
												data_out_r <= {data_in_r2[15:0],data_insert[31:16]};
												end
									
									4'b0001:	begin
												data_out_r <= {data_in_r2[7:0],data_insert[31:8]};
												end
									
									default:	begin
												data_out_r <= data_out_r;
												end				
												
								endcase
							end
end					

assign										data_out = ready_out?data_out_r:data_in_r2;	
						

//last_out	logic											
reg											lag_1clk_signal;
always@(posedge	clk	or	negedge	rst_n)
if(!rst_n)
												lag_1clk_signal <= 'd0;
else
												lag_1clk_signal <= data_tlast_rise_edge;
												
wire											last_out_r;
assign										last_out_r = (~data_tlast_rise_edge)&lag_1clk_signal;											
assign										last_out   = last_out_r;	

											
//keep_out	logic
reg 	[DATA_BYTE_WD-1 : 0] 			keep_out_r;
always@(posedge	clk	or	negedge	rst_n)
if(!rst_n)
												keep_out_r <= 'd0;										
else	if(valid_out)begin
			if(last_out_r)begin
								case(keep_insert_reg)
									4'b1111:	keep_out_r <= keep_reg   ;
									4'b0111:	keep_out_r <= keep_reg<<1;
									4'b0011:	keep_out_r <= keep_reg<<2;
									4'b0001:	keep_out_r <= keep_reg<<3;
									default:							 		 ;
								endcase
							end
			else
												keep_out_r <= 4'b1111;
		end
else
												keep_out_r <= 'd0;
																					
assign										keep_out = keep_out_r;


//valid_out	logic
reg											valid_out_r;
always@(posedge	clk	or	negedge	rst_n)
if(!rst_n)					
												valid_out_r<='d0;
else	if(insert_busy&&valid_out_r=='d0)
												valid_out_r<='d1;
else	if(valid_out_r=='d1&&data_tlast_rise_edge)
												valid_out_r<='d0;
else
												valid_out_r<=valid_out_r;

assign										valid_out = valid_out_r;

/*
***********************************************************************************
								  header	insert in data	logic	end
***********************************************************************************
*/


endmodule 