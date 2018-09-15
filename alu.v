`timescale 10 ns / 1 ns

`define DATA_WIDTH 32
module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [3:0] ALUop,
	output Overflow,
	output CarryOut,
	output Zero,
	output [`DATA_WIDTH - 1:0] Result
);

	//result of 'or''and'
	wire [`DATA_WIDTH - 1:0] aorb;
	wire [`DATA_WIDTH - 1:0] aandb;
	assign aorb=A|B;
	assign aandb=A&B;
	//result of sub,plus
	wire [`DATA_WIDTH - 1:0] bused;
	assign bused=(ALUop==4'b0111 || ALUop==4'b0110)?(~B+1):B;//for sub and slt,use complement of b
	wire [`DATA_WIDTH - 1:0] aplusbused;
	assign aplusbused=A+bused;
	//result of slt
	wire [`DATA_WIDTH -1:0] avsb;
	assign avsb=(A[`DATA_WIDTH-1]==0 && B[`DATA_WIDTH-1]==1)?0:
			    (A[`DATA_WIDTH-1]==1 && B[`DATA_WIDTH-1]==0)?1:
				{31'b0, aplusbused[`DATA_WIDTH-1]};
	//result of shift
	wire [31:0] b_shift_left_by_a;
	assign b_shift_left_by_a=(B<< (A[4:0]));  //a[4:0]=a%32
	//result of arithmetically shift right
	wire [31:0] b_shift_arith_right_by_a;
	assign b_shift_arith_right_by_a=( (B>>(A[4:0])) | ({{31{B[31]}},1'b0} << (~(A[4:0]))) ); 
    //result of logically shift right
	wire [31:0] b_shift_logic_right_by_a;
	assign b_shift_logic_right_by_a=(B>>(A[4:0]));
	//result of exclusive or
	wire [31:0] axorb;
	assign axorb=(A&(~B))|((~A)&B);
	//decide the result
	assign Result=(ALUop==4'b0000)?aandb:
		          (ALUop==4'b0001)?aorb:
				  (ALUop==4'b0010 || ALUop==4'b0110)?aplusbused:
				  (ALUop==4'b0111)?avsb:
				  (ALUop==4'b0011)?b_shift_left_by_a:
				  (ALUop==4'b0100)?b_shift_arith_right_by_a:
				  (ALUop==4'b0101)?b_shift_logic_right_by_a:
				  (ALUop==4'b1000)?axorb:
				  0;
	//decide the zero
	assign Zero=(Result==0)?1:0;
	//decide the overflow
	assign Overflow=((((A[`DATA_WIDTH-1]&&bused[`DATA_WIDTH-1]&&~Result[`DATA_WIDTH-1]) || (~A[`DATA_WIDTH-1]&&~bused[`DATA_WIDTH-1]&&Result[`DATA_WIDTH-1]))&&(B!=32'h80000000|| ALUop!=4'b0110))
			||(B==32'h80000000 && ALUop==4'b0110 && A[`DATA_WIDTH-1]==0))
	?1:0;
	//decide the carryout
	assign CarryOut=(((~ALUop[2]&&A[`DATA_WIDTH-1]&&bused[`DATA_WIDTH-1]) || (~ALUop[2]&&A[`DATA_WIDTH-1]&&~bused[`DATA_WIDTH-1]&&~Result[`DATA_WIDTH-1])
			|| (~ALUop[2]&&~A[`DATA_WIDTH-1]&&bused[`DATA_WIDTH-1]&&~Result[`DATA_WIDTH-1])
			|| (ALUop[2]&&~A[`DATA_WIDTH-1]&&~bused[`DATA_WIDTH-1]) || (ALUop[2]&&A[`DATA_WIDTH-1]&&~bused[`DATA_WIDTH-1]&&Result[`DATA_WIDTH-1])
			|| (ALUop[2]&&~A[`DATA_WIDTH-1]&&bused[`DATA_WIDTH-1]&&Result[`DATA_WIDTH-1])
	)&&(B!=0))?1:0;//handle the situation b==0 seperatly
endmodule
