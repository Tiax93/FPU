`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.01.2024 18:01:55
// Design Name: 
// Module Name: rounder
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

module rounder #(parameter W_IN = 25, W_OUT = 23)(
    input clk,
    input enable,
	input [2:0] mode,
	input sign,
    input [W_IN-1:0] d_in,
    output [W_OUT-1:0] d_out,
    output overflow
    );

	reg [W_OUT-1:0] r_dout;
	reg overflow_reg;
	wire [W_IN:0] w_halfeven;
	wire [W_IN:0] w_halfup;
	wire [W_IN:0] w_up;
	wire [W_OUT-1:0] w_truncate;

    assign w_halfup = d_in
		+ { {(W_OUT){1'b0}}, 1'b1, {(W_IN-W_OUT-1){1'b0}} };

	assign w_halfeven = d_in   
		+ { {(W_OUT){1'b0}},
			d_in[(W_IN-W_OUT)],
			{(W_IN-W_OUT-1){!d_in[(W_IN-W_OUT)]}}};

	assign w_up = d_in
		+ { {(W_OUT){1'b0}}, {(W_IN-W_OUT){1'b1}}};

	assign w_truncate = d_in[(W_IN-1):(W_IN-W_OUT)];

	assign d_out = r_dout;
    assign overflow = overflow_reg;

    always @(posedge clk) begin
		if (enable == 1'b1) begin
			case (mode)
				3'b001 : begin //RTZ
					r_dout <= w_truncate;
					overflow_reg <= 1'b0;
				end
				3'b010 : begin //RDN
					if (sign == 1'b0) begin
						r_dout <= w_truncate;
						overflow_reg <= 1'b0;
					end else begin
						r_dout <= w_up[(W_IN-1):(W_IN-W_OUT)];
						overflow_reg <= w_up[W_IN];
					end
				end
				3'b011 : begin //RUP
					if (sign == 1'b0) begin
						r_dout <= w_up[(W_IN-1):(W_IN-W_OUT)];
						overflow_reg <= w_up[W_IN];
					end else begin
						r_dout <= w_truncate;
						overflow_reg <= 1'b0;
					end
				end
				3'b100 : begin //RMM
					r_dout <= w_halfup[(W_IN-1):(W_IN-W_OUT)];
					overflow_reg <= w_halfup[W_IN];	
				end
				default: begin //RNE
					r_dout <= w_halfeven[(W_IN-1):(W_IN-W_OUT)];
					overflow_reg <= w_halfeven[W_IN];
				end
			endcase	
		end
	    
    end

endmodule


