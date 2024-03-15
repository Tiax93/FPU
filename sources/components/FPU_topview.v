`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2024 10:13:59
// Design Name: 
// Module Name: fp_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fp_unit_new(
    input clk,
    input nreset,
    input input_ready,
    input [31 : 0] a,
    input [31 : 0] b,
    input [2 : 0] round_mode,
    input [1 : 0] op, //Operation Code. 00 mult. 01 div. 10 sum. 11 sqrt.
    output reg [31 : 0] z,
    output reg done,
    output busy,
    output reg dz, //Divide By Zero
    output reg of, //Overflow
    output reg uf, //Underflow
    output reg nx, //Inexact Operation
    output reg nv //Invalid Operation
);
    reg [7 : 0] ctrl;
    
    reg [31 : 0] a_reg;
    reg [31 : 0] b_reg;
    reg [1 : 0] op_reg;
    reg [2 : 0] round_mode_reg;

    reg signed [9 : 0] result_exp; 
    reg signed [9 : 0] result_exp_temp;
    reg [24 : 0] result_f = 25'b0; //Result fraction
    reg result_s;
    
    reg signed [7 : 0] highbit_reg;
    
    reg [25 + 51 + 25 : 0] nx_reg;

    wire [31 : 0] fp_result;

    wire round_overflow; //set if rounding resulted in overflow
    wire [22 : 0] result_f_round; //Result fraction rounded

    wire hidden_bit_b;
    wire hidden_bit_a;    
    wire [7 : 0] a_reg_exp;
    wire [7 : 0] b_reg_exp;   
    wire [23 : 0] a_reg_m;
    wire [23 : 0] b_reg_m;

    wire int_op_done;
    wire int_div_done;
    wire int_mult_done;
    wire int_sqrt_done;
    wire [51 : 0] int_result;
    wire [47 : 0] int_prod;
    wire [51 : 0] int_quot;
    reg [26 : 0] int_sum;
    
    wire [23 : 0] int_rem; //int division reminder
    wire sqrt_nx;
    
    wire [25 + 51 + 25 : 0]int_result_extended;    
    wire signed [6 : 0] highbit_pos;
    
    reg [47 : 0] sel_prod;
    reg [51 : 0] sel_quot;
    reg [26 : 0] sel_sum;
    reg [24 : 0] sel_sqrt;
    
    wire signed [10 : 0] radix_exp;
    wire [34 : 0] int_sqrt;
    reg paritybit;
    reg denorm_bit;
    
    assign radix_exp = a_reg_exp + 126 + paritybit + !hidden_bit_a;

    assign int_result = (sel_quot & int_quot) | (sel_prod & {4'd0, int_prod}) | (sel_sum & {25'd0, int_sum}) | (sel_sqrt & {16'd0, int_sqrt}) ;
    
    assign int_op_done = int_mult_done || int_div_done || int_sqrt_done;
    assign fp_result[30 : 23] = result_exp;
    assign fp_result[22 : 0] = result_f_round; 
    assign fp_result[31] = result_s;

    assign int_result_extended = {25'd0, int_result, 25'd0};
    
    assign a_reg_exp = a_reg[30 : 23];
    assign b_reg_exp = b_reg[30 : 23];
    
    assign hidden_bit_a = a_reg_exp[0] || a_reg_exp[1] || a_reg_exp[2] || 
            a_reg_exp[3] || a_reg_exp[4] || a_reg_exp[5] || a_reg_exp[6] || a_reg_exp[7];
    assign hidden_bit_b = b_reg_exp[0] || b_reg_exp[1] || b_reg_exp[2] || 
            b_reg_exp[3] || b_reg_exp[4] || b_reg_exp[5] || b_reg_exp[6] || b_reg_exp[7];
    
    assign a_reg_m = {hidden_bit_a, a_reg[22 : 0]};
    assign b_reg_m = {hidden_bit_b, b_reg[22 : 0]};
    
    assign busy = ctrl[7] || ctrl[6] || ctrl[5] ||ctrl[4] || ctrl[3] || ctrl[2] || ctrl[1] || ctrl[0];

    //ADDER
    reg [25 : 0] int_a_sum;
    reg [25 : 0] int_b_sum;
    reg [25 + 24 + 2: 0] nx_reg_sum;
    wire [25 + 24 + 2: 0] a_reg_m_extended;
    wire [25 + 24 + 2: 0] b_reg_m_extended;
    //exponent difference
    wire signed [9 : 0] a_eMb_e;
    wire signed [9 : 0] b_eMa_e;   
    //significands sums
    wire signed [27 : 0] a_mPb_m; 
    wire signed [27 : 0] a_mMb_m;
    wire signed [27 : 0] b_mMa_m;
    assign a_eMb_e = a_reg_exp - b_reg_exp;
    assign b_eMa_e = b_reg_exp - a_reg_exp;
    assign a_mPb_m = int_a_sum + int_b_sum;
    assign a_mMb_m = int_a_sum - int_b_sum;
    assign b_mMa_m = int_b_sum - int_a_sum;
    assign a_reg_m_extended = {25'd0, a_reg_m, 2'b0};
    assign b_reg_m_extended = {25'd0, b_reg_m, 2'b0};

    highbit #(.IN_WIDTH(52), .OUT_WIDTH(7)) highbit_inst(
        .in(int_result),
        .out(highbit_pos)
    );

    rounder rounder_inst(
        .clk(clk),
        .enable(ctrl[3] || ctrl[6]),
        .mode(round_mode_reg),
        .sign(result_s),
        .d_in(result_f),
        .d_out(result_f_round),
        .overflow(round_overflow)
    );

    dadda24x24_sequential dadda24x24seq_inst(
        .clk(clk),
        .enable(ctrl[0] && op == 2'b00),
        .nrst(nreset),
        .a(a_reg_m), 
        .b(b_reg_m),
        .z(int_prod),
        .done(int_mult_done)
    );
    
    radix_16_divider_uint int_divider(
        .clk(clk),
        .nreset(nreset),
        .enable_input(ctrl[0] && op == 2'b01),
        .divisor(b_reg_m),
        .dividend(a_reg_m),
        .quotient(int_quot),
        .reminder(int_rem),
        .done(int_div_done)
    );
    
    sqrt sqrt_inst( 
		.clk(clk),
		.nreset(nreset),
		.enable(ctrl[1] && op == 2'b11),
		.value({20'd0,int_a_sum, 24'd0}),
		.root(int_sqrt),
		.nx(sqrt_nx),
		.done(int_sqrt_done)
	);
    
    always @(posedge clk, negedge nreset) begin
        if(!nreset) begin
         ctrl <= 8'd0;
         done <= 1'b0;
        end 
        else begin
            if(input_ready && !busy) begin
                round_mode_reg <= round_mode;
                op_reg <= op;
                nx <= 1'b0;
                of <= 1'b0;
                uf <= 1'b0;
				
                if((a[30 : 22] == 9'b111111110 && a[21 : 0] != 22'd0) || (b[30 : 22] == 9'b111111110 && b[21 : 0] != 22'd0)) begin
                    //If a or b are sNaN Invalid exception raised and result is qNaN
                    done <= 1'b1;
                    ctrl <= 8'd0;
                    nv <= 1'b1;
                    z[30 : 22] <= 9'b111111111;
                    z[21 : 0] <= 22'd0;
                    z[31] <= 1'b0;
                end 
                else if(a[30 : 22] == 9'b111111111 || b[30 : 22] == 9'b111111111) begin
                    //If a or b are qNaN result is qNaN
                    done <= 1'b1;
                    ctrl <= 8'd0;
                    //z <= NaN
                    z[30 : 22] <= 9'b111111111;
                    z[21 : 0] <= 22'd0;
                    z[31] <= 1'b0;            
                end

                else begin
					case (op)
						2'b00: begin
							sel_prod <= {(48){1'b1}};
							sel_quot <= 52'd0;
							sel_sum <= 27'd0;
							sel_sqrt <= 25'd0;
							dz <= 1'b0;
							if(a[30 : 0] != 31'd0 && b[30 : 0] != 31'd0) begin
								//If both a and b are different from 0 initialize regs     
								nv <= 1'b0;
								a_reg <= a;
								b_reg <= b;
								ctrl <= 8'b00000001;
							end else begin
								//Else if a or b are 0
								if(a[30 : 23] == 8'b11111111 || b[30 : 23] == 8'b11111111) begin
									//If a or b are infinite
									done <= 1'b1;
									ctrl <= 8'd0;
									nv <= 1'b1; //mult(0, inf) or mult(inf, 0) INVALID
									//z <= NaN
									z[30 : 22] <= 9'b111111111;
									z[21 : 0] <= 22'd0;
									z[31] <= 1'b0;
								end
								else begin
									//Else if both a and b are finite
									nv <= 1'b0;
									done <= 1'b1;
									ctrl <= 8'd0;
									z <= 32'd0; //Result is 0                      
								end
							end
						end
						
						2'b01: begin
							sel_prod <= 48'd0;
							sel_quot <= {(52){1'b1}};
							sel_sum <= 27'd0;
							sel_sqrt <= 25'd0;
							if(a[30 : 23] == 8'b11111111 && b[30 : 23] == 8'b11111111 ) begin
								nv <= 1'b1; //DIVISION INF/INF INVALID
								//z <= NaN
								z[30 : 22] <= 9'b111111111;
								z[21 : 0] <= 22'd0;
								z[31] <= 1'b0; 
								
								dz <= 1'b0;
								ctrl <= 8'b00000000; //idle
								done <= 1'b1;
							end
							else if(b[30 : 0] == 0) begin
								if(a[30 : 0] == 0) begin
									nv <= 1'b1; //DIVISION 0/0 INVALID
									//z <= NaN
                                    z[30 : 22] <= 9'b111111111;
                                    z[21 : 0] <= 22'd0;
                                    z[31] <= 1'b0; 
                                    
									dz <= 1'b0;
									ctrl <= 8'b00000000; //idle
									done <= 1'b1;
								end
								else begin
									//when the divisor is zero and the dividend is a finite non-zero number, 
									//the sign of the infinity is the exclusive OR of the operands' signs
									dz <= 1'b1; //DIVISION BY ZERO
									ctrl <= 8'b00000000; //idle
									done <= 1'b1;
									z[30 : 23] <= 8'b11111111;
									z[22 : 0] <= 23'd0;
									z[31] <= a[31]^b[31];
								end
							end
							else begin
								dz <= 1'b0;
								nv <= 1'b0;
								a_reg <= a;
								b_reg <= b;
								ctrl <= 8'b00000001;
							end
						end
						
						2'b10: begin
							sel_prod <= 48'd0;
							sel_quot <= 52'd0;
							sel_sum <= {(27){1'b1}};
							sel_sqrt <= 25'd0;
							dz <= 1'b0;
							if((a[30 : 23] == 8'b11111111 && b[30 : 23] == 8'b11111111) && a[31]^b[31] == 1'b1) begin
								nv <= 1'b1; //Addition(-INF, +INF) INVALID
								done <= 1'b1;
								ctrl <= 8'b00000000;
								z[30 : 22] <= 9'b111111111;
								z[21 : 0] <= 22'd0;
								z[31] <= 1'b0;                
							end
							else begin
								nv <= 1'b0;   
								a_reg <= a;
								b_reg <= b;
								ctrl <= 8'b00000001;
							end
						end
						
						2'b11: begin
							if(a[31]) begin
								nv <= 1'b1; //SQRT OF NEGATIVE NUMBER INVALID
								z[30 : 22] <= 9'b111111111;
								z[21 : 0] <= 22'd0;
								z[31] <= 1'b0; 
								dz <= 1'b0;
								ctrl <= 8'b00000000; //idle
								done <= 1'b1;
							
							end 
							else begin
								ctrl <= 8'b00000001;
								sel_prod <= 48'd0;
								sel_quot <= 52'd0;
								sel_sum <= 27'd0;
								sel_sqrt <= {(25){1'b1}};
								
								if(a[23] || a[30 : 23] == 8'd0)
									paritybit <= 1'b1;
								else 
									paritybit <= 1'b0;
									
								nv <= 1'b0;
								a_reg <= a;
								result_s <= 1'b0;
						   end
					   end
				   endcase
			    end
            end      

            else begin
				case (ctrl)
					//CTRL[0]
					8'b00000001: begin 
						if(op_reg == 2'b11) begin
							result_exp <= radix_exp >> 1;
							if(!paritybit) 
								int_a_sum <= a_reg_m;
							else int_a_sum <= a_reg_m << 1;
							
							ctrl <= 8'b00000010;
						end 
						else if(op_reg == 2'b10) begin
							if(a_reg[30: 23] == 1 && b_reg[30:23] == 0 || a_reg[30: 23] == 0 && b_reg[30:23] == 1) begin
								result_exp <= 1;
								int_b_sum <= {b_reg_m, 2'b0};
								int_a_sum <= {a_reg_m, 2'b0};
								ctrl <= 8'b00000010;                            
							end
							else if (a_reg[30:23] == 0 && b_reg[30:23] == 0) begin
								result_exp <= 1;
								int_b_sum <= {b_reg_m, 2'b0};  
								int_a_sum <= {a_reg_m, 2'b0};
								ctrl <= 8'b00000010;      
							end     
							else if(a_eMb_e[9] == 0) begin
								if(a_eMb_e < 26) begin
									result_exp <= {2'b0, a_reg_exp};
									int_b_sum <= b_reg_m_extended[25 + a_eMb_e -: 26]; 
									nx_reg_sum <= b_reg_m_extended;
									int_a_sum <= {a_reg_m, 2'b0};
									ctrl <= 8'b00000010;
								end else begin
									z <= a_reg;
									nx <= 1'b1;
									ctrl <= 8'b00000000; //idle
									done <= 1'b1;
								end
							end else begin
								if(b_eMa_e < 26) begin
									result_exp <= {2'b0, b_reg_exp};
									int_a_sum <= a_reg_m_extended[25 + b_eMa_e -: 26];
									nx_reg_sum <= a_reg_m_extended;
									int_b_sum <= {b_reg_m, 2'b0};
									ctrl <= 8'b00000010;
								end else begin
									z <= b_reg;
									nx <= 1'b1;
									ctrl <= 8'b00000000; //idle
									done <= 1'b1;
								end
							end
						end
						else if(op_reg == 2'b00 || op_reg == 2'b01)begin
							result_s <= a_reg[31] ^ b_reg[31]; 
							ctrl <= 8'b00000010;
							if(op_reg == 2'b00)
								result_exp <= a_reg_exp + b_reg_exp - 8'b01111111;
							else
								result_exp <= a_reg_exp - b_reg_exp + 8'b01111111;   
						end
					end
            
					//CTRL[1]
					8'b00000010: begin
						ctrl <= 8'b00000100;
						if(op_reg == 2'b10) begin 
						    if(a_eMb_e[9] == 0) nx_reg_sum[25 + a_eMb_e -: 24] <= 24'd0;
						    else nx_reg_sum[25 + b_eMa_e -: 24] <= 24'd0;
						    
							if(a_reg[31] == b_reg[31]) begin // A+B or -A-B
								int_sum <= a_mPb_m;
								result_s <= a_reg[31];    
							end
							else if(a_reg[31]) begin //B-A
								if(b_mMa_m[27] == 1'b0) begin
									int_sum <= b_mMa_m;
									result_s <= 1'b0;
								end else begin
									int_sum <= ~(b_mMa_m - 1);
									result_s <= 1'b1;
								end
							end
							else begin //A-B
								if(a_mMb_m[27] == 1'b0) begin
									int_sum <= a_mMb_m;
									result_s <= 1'b0;
								end else begin
									int_sum <= ~(a_mMb_m - 1);
									result_s <= 1'b1;
								end
							end
							result_exp_temp <= result_exp - 25; 
						end
						else if(op_reg == 2'b00) begin
							if(hidden_bit_b ^ hidden_bit_a) begin
							   result_exp <= result_exp + 1;
							   result_exp_temp <= result_exp - 45;               
							end
							else if(!hidden_bit_b && !hidden_bit_a) begin
									result_exp <= result_exp + 2;
									result_exp_temp <= result_exp - 44;               
							end else result_exp_temp <= result_exp - 46;
						end
						else if(op_reg == 2'b01) begin
							if(hidden_bit_a ^ hidden_bit_b) begin
								if(hidden_bit_b) begin
									result_exp <= result_exp + 1;
									result_exp_temp <= result_exp - 27;
								end
								if(hidden_bit_a) begin
									result_exp <= result_exp - 1;
									result_exp_temp <= result_exp - 29;
								end
							end else result_exp_temp <= result_exp - 28;
						end
						else if(op_reg == 2'b11) begin
							if(paritybit)
								result_exp_temp <= result_exp - 24;
							else result_exp_temp <= result_exp - 23;
						end
					end

					//CTRL[2]
					8'b00000100: begin					
						//INT OPERATION DONE
						if(int_op_done || op_reg == 2'b10) begin
						    if(op_reg == 2'b10 && nx_reg_sum > 0)
                                nx <= 1'b1;
						    if(op_reg == 2'b01 && int_rem > 0)
						        nx <= 1'b1;
						    else if(op_reg == 2'b11 && sqrt_nx)
						        nx <= 1'b1;
							result_exp <= result_exp_temp + highbit_pos;
							result_f <= int_result_extended[highbit_pos + 24 -: 25]; //hbp - 1 + 25
							nx_reg <= int_result_extended;
							ctrl <= 8'b00001000; //rounding
							highbit_reg <= highbit_pos + 25;
						end
					end
					
					//CTRL[3] ROUNDING
					8'b00001000: begin
					   ctrl <= 8'b00010000;
					   nx_reg[highbit_pos + 25 -: 24] <= 24'd0;
					end

					//CTRL[4] POST ROUNDING NORMALIZATION
					8'b00010000: begin
					    if(nx_reg > 0)
					       nx <= 1'b1;
						if(round_overflow) begin 
							result_exp <= result_exp + 1;
						end
						ctrl <= 8'b00100000; //check overflow
					end
							   
					//CTRL[5] OVERFLOW AND UNDERFLOW CHECK
					8'b00100000: begin		       
						if(result_exp[9 : 8] == 2'b01 || result_exp == 10'b0011111111) begin
							of <= 1'b1;
							nx <= 1'b1;
							done <= 1'b1;
							ctrl <= 8'd0;
							
							case (round_mode_reg) 
                                 3'b000, //roundTiesToEven
                                 3'b100: begin // roundTiesToAway
                                     z[31] <= result_s;
                                     z[30 : 23] <= 8'b1111111;
                                     z[22 : 0] <= 23'd0; 
                                 end
                                 3'b001: begin //roundTowardZero
                                     z[31] <= result_s;
                                     z[30 : 23] <= 8'b1111110;
                                     z[22 : 0] <= 23'b11111111111111111111111; 
                                 end
                                 3'b010: begin // roundTowardNegative
                                     if(result_s) begin
                                         z[31] <= result_s;
                                         z[30 : 23] <= 8'b1111111;
                                         z[22 : 0] <= 23'd0;
                                     end
                                     else begin
                                         z[31] <= result_s;
                                         z[30 : 23] <= 8'b1111110;
                                         z[22 : 0] <= 23'b11111111111111111111111;     
                                     end
                                         
                                 end
                                 3'b011: begin //roundTowardPositive
                                     if(!result_s) begin
                                         z[31] <= result_s;
                                         z[30 : 23] <= 8'b1111111;
                                         z[22 : 0] <= 23'd0;
                                     end
                                     else begin
                                         z[31] <= result_s;
                                         z[30 : 23] <= 8'b1111110;
                                         z[22 : 0] <= 23'b11111111111111111111111;     
                                     end
                                 end
                            endcase     
						end
			
						else if(result_exp[9 : 8] == 2'b11 || result_exp == 10'b0) begin
							if(result_exp < -22) begin              
								done <= 1'b1;
								ctrl <= 8'd0;
								uf <= 1'b1;
								nx <= 1'b1;
								z <= 32'd0;   
							end
							else begin 
								result_f <= int_result_extended[highbit_reg - result_exp -: 25]; //hbp + 24 + 1 - result_exp 
								nx_reg <= int_result_extended;
								ctrl <= 8'b01000000;  //rounding
							end       
						end else begin 
							done <= 1'b1;
							z <= fp_result;
							ctrl <= 8'd0;
						end
					end
                    //CTRL[6] ROUNDING
					8'b01000000: begin
					   ctrl <= 8'b10000000;
					   nx_reg[highbit_reg - result_exp -: 23] <= 23'd0;
					   result_exp <= 10'd0;
					   
                    end
                    //CTRL[7] POST ROUNDING NORMALIZATION
					8'b10000000: begin
					    if(nx_reg > 0) begin
					       uf <= 1'b1;
					       nx <= 1'b1;
					    end
					    else if(nx)
					       uf <= 1'b1;     
						if(round_overflow) begin 
							result_exp <= result_exp + 1;
						end
						done <= 1'b1;
						ctrl <= 8'd0;
						z <= fp_result;     
					end
				endcase
			end
			
            if(done)
                done <= 1'b0;
        end   
    end

endmodule
