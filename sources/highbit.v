`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.01.2024 18:15:55
// Design Name: 
// Module Name: highbit
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

module highbit #(
    parameter OUT_WIDTH = 6, // out uses one extra bit for not-found
    parameter IN_WIDTH = 1<<(OUT_WIDTH-1)
) (
    input [IN_WIDTH-1:0]in,
    output [OUT_WIDTH-1:0]out
);

    wire [OUT_WIDTH-1:0]out_stage[0:IN_WIDTH];
    assign out_stage[0] = ~0; // desired default output if no bits set
    
    generate genvar i;
        for(i=0; i<IN_WIDTH; i=i+1) begin 
            assign out_stage[i+1] = in[i] ? i : out_stage[i];
        end                                                     
    endgenerate                                               
    
    assign out = out_stage[IN_WIDTH];

endmodule
