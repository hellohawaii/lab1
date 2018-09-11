`timescale 10ns / 1ns

//main control module

module control_unit(
	input  clk,
	input  resetn,
	input  [5:0] behavior,
	input  [31:0] Result,//ALU result
	output [1:0] reg_dst,//signal for mux(where to write)
	output reg mem_read,//enable signal
	output [3:0] reg_write_value,//signal for mux(what to write reg_file)
	output [2:0] ALUop,//signal for ALU control
	output reg mem_write,//enable signal
	output [1:0] B_src,//signal for mux(what to compute)
	output reg reg_write,//enable signal
	output [3:0] data_sram_wen,//signal for 8or16-bit write
	output [2:0] mem_write_value,//signal for mux(what to write to mem)

	output reg Inst_Req_Valid, //Instruction_Request_Valid
	input  Inst_Req_Ack,   //Instruction_Request_//TODO

	input  Inst_Valid,     //Instruction_Valid
	output reg Inst_Ack,       //Instruction_//TODO

	//Here, the request can be read or write
	//Data_Req_Valid is mem_read or (mem_write and data written to memory) 
	input  Mem_Req_Ack,    //Memory_Request_//TODO
						   //just like Inst_Req_Ack

	//only have this when read from memory
	input  Read_data_Valid,//Read_data_Valid
						   //like Inst_Valid
	output reg Read_data_Ack,  //Read_data_Ack_//TODO
		                   //like Inst_Ack

	output reg PC_enable,

	output bne,
    output beq,
	output j,
	output jal,
	output R_type,
	output regimm,
	output blez,
	output bgtz,
	output [2:0] output_flag1,
	output [2:0] output_flag2,
	output [5:0] output_flag3
);

	//something related to FSM
	reg [2:0] next_state;
	reg [2:0] state;
	parameter IF    =3'b000, //Instruction fecth
		      IW    =3'b001, //Instruction wait
			  ID_EX =3'b010, //Instruction decode_execute
			  LD    =3'b011, //load data
			  RDW   =3'b100, //read data wait
			  WB    =3'b101, //write back
			  ST    =3'b110; //TODO


	//signal recording the decoded instruction
	wire addiu, lw  , sw   , nop;
	wire lui  , slti, sltiu;
	wire andi , lb  , lbu  , lh , lhu, lwl , lwr,
	     ori  , sb  , sh  , swl, swr, xori;

	//decoding
	assign addiu =(behavior==6'b001001)?1:0;
	assign lw    =(behavior==6'b100011)?1:0;
	assign sw    =(behavior==6'b101011)?1:0;
	assign bne   =(behavior==6'b000101)?1:0;
	assign R_type=(behavior==6'b000000)?1:0;
	assign beq   =(behavior==6'b000100)?1:0;
	assign j     =(behavior==6'b000010)?1:0;
	assign jal   =(behavior==6'b000011)?1:0;
	assign lui   =(behavior==6'b001111)?1:0;
	assign slti  =(behavior==6'b001010)?1:0;
	assign sltiu =(behavior==6'b001011)?1:0;
	assign andi  =(behavior==6'b001100)?1:0;
	assign regimm=(behavior==6'b000001)?1:0;
	assign blez  =(behavior==6'b000110)?1:0;
	assign bgtz  =(behavior==6'b000111)?1:0;
	assign lb    =(behavior==6'b100000)?1:0;
	assign lbu   =(behavior==6'b100100)?1:0;
	assign lh    =(behavior==6'b100001)?1:0;
	assign lhu   =(behavior==6'b100101)?1:0;
	assign lwl   =(behavior==6'b100010)?1:0;
	assign lwr   =(behavior==6'b100110)?1:0;
	assign ori   =(behavior==6'b001101)?1:0;
	assign sb    =(behavior==6'b101000)?1:0;
	assign sh    =(behavior==6'b101001)?1:0;
	assign swl   =(behavior==6'b101010)?1:0;
	assign swr   =(behavior==6'b101110)?1:0;
	assign xori  =(behavior==6'b001110)?1:0;

	//classify the instruction, used in Part 2
	wire Jump_Class, Load_Class, Store_Class;
	assign Jump_Class =(bne || beq || j   || jal || regimm || blez|| bgtz)?1:0;
	assign Load_Class =(lw  || lb  || lbu || lh  || lhu    || lwl || lwr )?1:0;
	assign Store_Class=(sw  || sb  || sh  || swl || swr                  )?1:0;

	//Part 1, update to the new state
	always @(posedge clk)
	begin
		if(~resetn)
			state<=IF;
		else
			state<=next_state;
	end

	//Part 2, decide the new state
	always @(*)
	begin
		if(resetn==0)
			next_state=IF;
		else
		begin
			case(state)
				IF     : next_state=(Inst_Req_Ack   )? IW    :IF ;
				IW     : next_state=(Inst_Valid     )? ID_EX :IW ; 
				ID_EX  : next_state=(Jump_Class     )? IF    :
									(Load_Class     )? LD    :
									(Store_Class    )? ST    :WB ;
				LD     : next_state=(Mem_Req_Ack    )? RDW   :LD ;
				RDW    : next_state=(Read_data_Valid)? WB    :RDW;
				WB     : next_state=                          IF ;
				ST     : next_state=(Mem_Req_Ack    )? IF    :ST ;
				default: next_state=                          IF ;
			endcase
        end
	end

	wire [2:0] wire_flag1;
	wire [2:0] wire_flag2;
	wire [5:0] wire_flag3;
	assign wire_flag1=flag1;
	assign wire_flag2=flag2;
	assign wire_flag3=flag2;
	assign output_flag1=wire_flag1;
	assign output_flag2=wire_flag2;
	assign output_flag3=wire_flag3;
	reg [2:0] flag1;
	reg [2:0] flag2;
	reg [5:0] flag3;
	//Part 3, decide the output register
	always @(posedge clk)
	begin
		flag1<=3'b111;
		//Enable Signal and Channel Control
        case(next_state)     //use next_state, so the value will fit the state
							 //the state and the control signals update at the
							 //same time
			IF     :
			begin
				flag2<=3'b101;
				mem_read <=0;
				mem_write<=0;
				reg_write<=0;
				PC_enable<=0;
				if(rsetn==0)
				begin
					flag3<=6'b101010;
				    Inst_Req_Valid<=0;
					Inst_Ack  <=1;
					Read_data_Ack <=1;
				end
				else
				begin
					flag3<=6'b000111;
					Inst_Req_Valid<=1;
					Inst_Ack  <=0;
					Read_data_Ack <=0;
				end
			end
			IW     :
			begin
				mem_read <=0;
				mem_write<=0;
				reg_write<=0;
				PC_enable<=0;
				Inst_Req_Valid<=0;
				Inst_Ack      <=1;
				Read_data_Ack <=0;
			end
			ID_EX  :
			begin
				mem_read <=0;
				mem_write<=0;
				reg_write<=(jal);  //reg_write=1 when jal=1
				PC_enable<=Jump_Class;
				Inst_Req_Valid<=0;
				Inst_Ack      <=0;
				Read_data_Ack <=0;
			end
			LD     :
			begin
				mem_read <=1;    //must be 1(because of the state)
				mem_write<=0;
				reg_write<=0;
				PC_enable<=0;
				Inst_Req_Valid<=0;
				Inst_Ack      <=0;
				Read_data_Ack <=0;
			end
			RDW    :
			begin
				mem_read <=0;
				mem_write<=0;
				reg_write<=0;
				PC_enable<=0;
				Inst_Req_Valid<=0;
				Inst_Ack      <=0;
				Read_data_Ack <=1;
			end
			WB     :
			begin
				mem_read <=0;
				mem_write<=0;
				reg_write<=1;    //must be 1(because of the state)
				PC_enable<=1;    //Load and Store type, update here
				                 //exactly change one time
				Inst_Req_Valid<=0;
				Inst_Ack      <=1;
				Read_data_Ack <=0;
			end
			ST     :
			begin
				mem_read <=0;
				mem_write<=1;     //must be 1(because of the state)
				reg_write<=0;
				PC_enable<=(state==ID_EX);//only at the first time enter ST
										  //change PC
				Inst_Req_Valid<=0;
				Inst_Ack      <=0;
				Read_data_Ack <=0;
			end
			default:
				flag2=3'b110;
		endcase
	end

	//Control Signal(used for make a choice)
	assign reg_dst=(R_type)? 2'b01:
				   (jal   )? 2'b10:
		                     2'b00; //2'b00 is rt
	assign reg_write_value=(lw   )? 4'b0001:
		                   (jal  )? 4'b0010:
				    	   (lui  )? 4'b0011:
						   (sltiu)? 4'b0100:
						   (lb   )? 4'b0101:
						   (lbu  )? 4'b0110:
						   (lh   )? 4'b0111:
						   (lhu  )? 4'b1000:
						   (lwl  )? 4'b1001:
						   (lwr  )? 4'b1010:
		                               4'b0000;     //4'b0000 is result
	assign ALUop=(addiu || lw    || sw    || lb   || lbu   || 
		          lh    || lhu   || lwl   || lwr  || sb    ||
			      sh    || swl   || swr                      )? 3'b000:  //add
				 (bne   || beq   || sltiu                    )? 3'b001:  //sub
				 (R_type                                     )? 3'b011:  //R
				 (slti  || regimm|| blez  || bgtz            )? 3'b010:  //slt
				 (andi                                       )? 3'b100:  //add
				 (ori                                        )? 3'b101:  //or
				 (xori                                       )? 3'b110:  //xor
				                                                3'b010;  //slt
	assign B_src=(addiu || lw    || sw    || slti || sltiu || 
				  lb    || lbu   || lh    || lhu  || lwl   ||
				  lwr   || sb    || sh    || swl  || swr     )? 2'b01:  
				                                                         //sign_extended imm
				 (regimm|| blez  || bgtz                     )? 2'b10:
				 (ori   || andi  || xori                     )? 2'b11:   //zero_extended imm
				                                                2'b00;   //rdata2
	assign mem_write_value=(sb )? 3'b001:
		                   (sh )? 3'b010:
						   (swl)? 3'b011:
						   (swr)? 3'b100:
						          3'b000;
	wire [3:0] write_strb_sb ;
	wire [3:0] write_strb_sh ;
	wire [3:0] write_strb_swl;
	wire [3:0] write_strb_swr;
	assign write_strb_sb =(Result[1:0]==2'b00)? 4'b0001:
						  (Result[1:0]==2'b01)? 4'b0010:
						  (Result[1:0]==2'b10)? 4'b0100:
						  (Result[1:0]==2'b11)? 4'b1000:
						                        4'b0000;
	assign write_strb_sh =(Result[ 1 ]==0    )? 4'b0011:
						  (Result[ 1 ]==1    )? 4'b1100:
						                        4'b0000;
	assign write_strb_swl=(Result[1:0]==2'b00)? 4'b0001:
						  (Result[1:0]==2'b01)? 4'b0011:
						  (Result[1:0]==2'b10)? 4'b0111:
						  (Result[1:0]==2'b11)? 4'b1111:
			                 			        4'b0000;
	assign write_strb_swr=(Result[1:0]==2'b00)? 4'b1111:
						  (Result[1:0]==2'b01)? 4'b1110:
						  (Result[1:0]==2'b10)? 4'b1100:
						  (Result[1:0]==2'b11)? 4'b1000:
						                        4'b0000;
	assign data_sram_wen=(sw )?        4'b1111:
		              (sb )? write_strb_sb :
					  (sh )? write_strb_sh :
					  (swl)? write_strb_swl:
					  (swr)? write_strb_swr:
					                4'b0000;
endmodule
