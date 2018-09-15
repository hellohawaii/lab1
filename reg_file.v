`timescale 10 ns / 1 ns

`define DATA_WIDTH 32
`define ADDR_WIDTH 5
`define REG_NUM 32

module reg_file(
	input clk,
	input resetn,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);


	
	//Definition
	reg [`DATA_WIDTH-1:0] mem [`REG_NUM-1:0];

	//Input
	always @(posedge clk)
	begin
		if(resetn==0)
		begin
			mem [0]<=0;
			if(wen==1 && waddr!=0)
			begin
				mem[waddr]<=wdata;
			end
			else
				;
		end
		else
		begin
			if(wen==1 && waddr!=0)
			begin
				mem[waddr]<=wdata;
			end
			else
				;
		end
	end
	
	//Output
	assign rdata1 = mem[raddr1];
	assign rdata2 = mem[raddr2];
endmodule
