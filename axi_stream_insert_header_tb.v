`timescale 		1ns/1ns
module axi_stream_insert_header_tb(

    );
parameter 								DATA_DEPTH =256;
parameter 								DATA_WD = 32;
parameter 								DATA_BYTE_WD = DATA_WD / 8;
parameter 								BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

reg										clk;
reg										rst_n;

// data_in
reg 										valid_in	;
reg	 	[DATA_WD-1 : 0] 			data_in	;
reg 		[DATA_BYTE_WD-1 : 0]		keep_in	;
reg 										last_in	;
wire 										ready_in ;

// data_out
wire 										valid_out;
wire 		[DATA_WD-1 : 0] 			data_out	;
wire 		[DATA_BYTE_WD-1 : 0] 	keep_out	;
wire 										last_out	;
reg 										ready_out;

// header
reg 										valid_insert ;
reg 		[DATA_WD-1 : 0] 			data_insert;
reg 		[DATA_BYTE_WD-1 : 0]		keep_insert  ;
wire 										ready_insert ;





axi_stream_insert_header axi_stream_insert_header_u(
	.clk									( clk				),
	.rst_n								( rst_n			),
	
	// data_in
	.valid_in							( valid_in		),
	.data_in								( data_in		),
	.keep_in								( keep_in		),
	.last_in								( last_in		),
	.ready_in							( ready_in		),
	
	// data_out
	.valid_out							( valid_out		),
	.data_out							( data_out		),
	.keep_out							( keep_out		),
	.last_out							( last_out		),
	.ready_out							( ready_out		),
	
	//header
	.valid_insert						( valid_insert	),
	.data_insert						( data_insert),
	.keep_insert						( keep_insert	),
	.byte_insert_cnt					(					),
	.ready_insert						( ready_insert	)
);	



always #10 clk = !clk;
initial begin
											clk				= 'd0;
											rst_n				= 'd0;
											//data_in
											valid_in			= 'd1;
											data_in			= 'd0;
											keep_in			= 4'b1111;
											last_in			= 'd0;
											//header
											valid_insert	= 'd0;
											data_insert		= 'd0;
											keep_insert 	= 'd0;
											
									#20	rst_n = 'd1;
end

/*
********************************data channel singal*****************************
*/
//data valid in gen
reg [2:0]random1;
always@(posedge clk)begin
										  random1 = $random %8;
										  repeat (random1) @(posedge clk);
										  valid_in <= 'd0;
										  repeat (1) @(posedge clk);
										  valid_in <= 'd1;
end

//data in gen
always@(posedge clk or negedge rst_n)begin
if(!rst_n)
										  data_in <= 'd0;
else if(valid_in && ready_in)	
										  data_in <= {$random}%2**(DATA_WD-1)-1;    
end


//last in gen
reg 		[3:0]						  cnt0	;

always@(posedge clk or negedge rst_n)begin
if(!rst_n)
										  cnt0 <= 'd0;
    else  
										  cnt0 <= (cnt0>='d12 )? 'd0 : cnt0+'d1;
end
   

always@(posedge clk or negedge rst_n)begin
if(!rst_n)
										  last_in = 'd0;
else if(cnt0 >= 'd12)  
										  last_in = 'd1;
else  
										  last_in = 'd0;
end

/*
********************************header channel singal*****************************
*/
//valid insert and	data insert
reg		[3:0]						  cnt1	;


always@(posedge clk or negedge rst_n)begin
if(!rst_n)
										  cnt1 <= 'd0;
else   
										  cnt1 <= (cnt1>='d10) ? 'd0 : cnt1+'d1;
end
   
always@(posedge clk or negedge rst_n)begin
if(!rst_n)
										  data_insert	<= {$random}%2**(DATA_WD-1)-1;
else if(cnt1 == 'd1)  
										  valid_insert	<= 'd1;
else if(cnt1 == 'd3)				  begin
										  data_insert 	<= {$random}%2**(DATA_WD-1)-1;
										  valid_insert	<= 'd0;
										  end
end

//keep insert gen
reg			[1:0]					  random2;
always@(posedge clk or negedge  rst_n)begin
if(!rst_n) 
										  random2 <= 'd0;
else 
										  random2 <= $random %4;
end


always@(posedge clk or negedge rst_n)begin
if(!rst_n)
										  keep_insert <= 'd0;
else	case(random2) 
					4'd0 :			  keep_insert <= 'd0001;	
					4'd1 :			  keep_insert <= 'd0011;	
					4'd2 :			  keep_insert <= 'd0111;	
					4'd3 :			  keep_insert <= 'd1111;	
					default:										;
		endcase
end

/*
********************************header channel singal*****************************
*/
//ready_out gen
reg 		[2:0]						  random3;
always@(posedge clk)begin
										  random3 = $random %8;
										  repeat (random3) @(posedge clk);
										  ready_out <= 'd0;
										  repeat (1) @(posedge clk);
										  ready_out <= 'd1;
end




endmodule 