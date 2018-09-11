module ALU_control(
	input [5:0] func,
	input [2:0] ALUop,
	output [3:0] ALU_ctr  //ctr is the abbr of 'control'
);

	assign ALU_ctr=(ALUop==3'b000 || ALUop==3'b011 && func==6'b100001)?4'b0010:  //add
				   (ALUop==3'b001 || 
				   ALUop==3'b011 && (func==6'b100011 || func==6'b101011))?4'b0110:  //sub
				   (ALUop==3'b100 ||ALUop==3'b011 && func==6'b100100)?4'b0000:  //and
				   (ALUop==3'b101 || 
				   ALUop==3'b011 && (func==6'b100101 || func==6'b100111))?4'b0001:  //or
				   (ALUop==3'b010 || ALUop==3'b011 && func==6'b101010)?4'b0111:  //slt
				   (ALUop==3'b011 && (func==6'b000000 || func==6'b000100))?4'b0011:  //shift_left
				   (ALUop==3'b011 && (func==6'b000011 || func==6'b000111))?4'b0100:
				                                                           //shift_right_arith
			       (ALUop==3'b011 && (func==6'b000010 || func==6'b000110))?4'b0101:
					                                                       //shift_right_logic
				   (ALUop==3'b110 || ALUop==3'b011 && func==6'b100110)?4'b1000:  //xor
				   3'b000;

endmodule
