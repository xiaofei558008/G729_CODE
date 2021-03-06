`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Mississippi State University 
// ECE 4532-4542 Senior Design
// Engineer: Zach Thornton
// 
// Create Date:    13:21:02 10/17/2010
// Module Name:    lag_window
// Project Name: 	 ITU G.729 Hardware Implementation
// Target Devices: Virtex 5
// Tool versions:  Xilinx 9.2i
// Description: 	 A test bench to test the lag window module, which performs
//						 the computation of the r'(k) coefficients
//
// Dependencies: 	 lag_window,L_mult,L_mac,mult
//						 Verilog Test Fixture created by ISE for module: lag_window
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module lag_window_test_v;
`include "paramList.v"
	
	//Inputs
	reg clk;
	reg reset;
	reg start;	
	reg lagMuxSel;
	reg [11:0] testReadRequested;
	reg [11:0] testWriteRequested;
	reg [31:0] testWriteOut;
	reg testWriteEnable;
	
	//Outputs
	wire done;
	wire [31:0] rPrimeIn;
	//working regs
	reg [31:0] rMem [0:9999];		  
	reg [31:0] rPrimeMem [0:9999];	
	
	integer i,j;		
					
	initial 
	begin
		// samples out are samples from ITU G.729 test vectors
		$readmemh("lag_window_in.out", rMem);
		// filter results from ITU G.729 ANSI fixed point implementation
		$readmemh("lag_window_out.out", rPrimeMem);
   end
	
	//Instantiate Unit Under Test(UUT)
	Lag_Window_Top uut(
							 .clk(clk),
							 .reset(reset),
							 .start(start),
							 .lagMuxSel(lagMuxSel),
							 .testWriteEnable(testWriteEnable),
							 .testWriteOut(testWriteOut),
							 .testWriteRequested(testWriteRequested),
							 .testReadRequested(testReadRequested),
							 .done(done),
							 .rPrimeIn(rPrimeIn)
							 );
	

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		start = 0;		
		lagMuxSel = 1;
		testReadRequested = 0;
		testWriteRequested = 0;
		testWriteOut = 0;
		testWriteEnable = 0;
		
		@(posedge clk) #5; 		
		reset = 1;		
		@(posedge clk) #5; 		
		reset = 0;
		// Wait 100 ns for global reset to finish
		
		@(posedge clk); 
		@(posedge clk) #5; 		
		
		for(j=0;j<100;j=j+1)
		begin	
		
			//Test # 1
			@(posedge clk); 
			@(posedge clk) #5; 					
			for(i=0;i<11;i=i+1)
			begin			
				@(posedge clk); 
				@(posedge clk) #5; 			
				testWriteRequested = {AUTOCORR_R[10:4],i[3:0]};
				testWriteOut = rMem[j*11+i];
				testWriteEnable = 1;
				@(posedge clk); 
				@(posedge clk) #5;			
			end
			
			lagMuxSel = 0;		
			
			// Add stimulus here
			start = 1;
			@(posedge clk); 
			@(posedge clk) #5;		
			start = 0;
			@(posedge clk); 
			@(posedge clk) #5;			
			
			wait(done);
			lagMuxSel = 1;
			for(i = 0; i<11;i=i+1)
			begin			
				testReadRequested = {LAG_WINDOW_R_PRIME[10:4],i[3:0]};
				@(posedge clk); 
				@(posedge clk) #5;			
				if (rPrimeIn != rPrimeMem[j*11+i])
						$display($time, " ERROR: r'[%d] = %x, expected = %x", j*11+i, rPrimeIn, rPrimeMem[j*11+i]);
				else if (rPrimeIn == rPrimeMem[j*11+i])
					$display($time, " CORRECT:  r'[%d] = %x", j*11+i, rPrimeIn);
				@(posedge clk) #5;	
			end
		end//	for joop j
	
	end//always
   initial forever #10 clk = ~clk;     
endmodule

