`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.12.2023 17:29:18
// Design Name: 
// Module Name: Radix-16_Divider_uint
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


module radix_16_divider_uint(
        input clk,
        input nreset,
        input enable_input,
        input [23 : 0] dividend,
        input [23 : 0] divisor,
        output [51 : 0] quotient,
        output [23 : 0] reminder,
        output reg done,
        output busy
        );
     
    parameter D_END_W = 52; 
    parameter D_OR_W = 24;
    parameter REM_W = D_OR_W + D_END_W + 1;
        
    reg [2 : 0] ctrl;
    
    reg [3 : 0] it;
    reg [REM_W - 1: 0] reminder_reg;
    reg [D_END_W - 1 : 0] quot;
    
    reg [D_OR_W + 4 : 0] dor1dor;
    reg [D_OR_W + 4 : 0] dor3dor2;
    
    reg [D_OR_W + 4 : 0] dor[1 : 14]; 
    wire [D_OR_W + 4 : 0] dor0;
    wire [D_OR_W + 4 : 0] s[0 : 14];

    generate genvar i;
        for(i=1; i<15; i=i+1) begin 
            assign s[i] = (reminder_reg[REM_W - 1 : D_END_W - 4] - dor[i]);
        end                                                   
    endgenerate
    
    assign s[0] = (reminder_reg[REM_W - 1 : D_END_W - 4] - dor0);
    assign dor0 = {5'd0, divisor};
    assign busy = ctrl[2] || ctrl[1] || ctrl[0];
    assign quotient = quot;
    assign reminder = reminder_reg[REM_W - 2 : D_END_W];
    
    always @(posedge clk, negedge nreset) begin
        if(!nreset) begin
            ctrl <= 3'd0;
            done <= 1'b0;
        end
        else begin 
            if(enable_input && !busy) begin
                if(divisor[23]) begin
                    reminder_reg[REM_W - 1 : 72] <= 5'd0; 
                    reminder_reg[71 : 0] <= {dividend, 48'b0};
                    it <= 4'd8;
                    quot <= 52'd0;
                end else begin
                    reminder_reg[REM_W - 1 : D_END_W] <= 25'd0; 
                    reminder_reg[D_END_W - 1 : 0] <= {dividend, 28'b0};
                    it <= 4'd13;
                    end
                dor1dor <= (dor0 << 1) + dor0;
                dor3dor2 <= (dor0 << 3) + (dor0 << 2);
            
                ctrl <= 3'b001;
            end
            else if(ctrl[0]) begin
                ctrl <= 3'b010;
                dor[1] <= dor0 << 1;
                dor[2] <= dor1dor;
                dor[3] <= (dor0 << 2);
                dor[4] <= (dor0 << 2) + dor0;
                dor[5] <= (dor0 << 2) + (dor0 << 1);
                dor[6] <= (dor0 << 2) + dor1dor;
                dor[7] <= (dor0 << 3);
                dor[8] <= (dor0 << 3) + dor0;
                dor[9] <= (dor0 << 3) + (dor0 << 1);
                dor[10] <= (dor0 << 3) + dor1dor;
                dor[11] <= dor3dor2;
                dor[12] <= dor3dor2 + dor0;
                dor[13] <= dor3dor2 + (dor0 << 1);
                dor[14] <= dor3dor2 + dor1dor; 
            end
           
            else if(ctrl[1]) begin
                if(it == 4'b0001) begin
                    ctrl <= 3'b000;
                    done <= 1'b1;
                end
                it <= it - 1;
    
                if(s[14][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[14][D_OR_W : 0];
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1111;
                end
                else if(s[13][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[13][D_OR_W : 0]; 
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1110;
                end
                else if(s[12][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[12][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1101; 
                end
                else if(s[11][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[11][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1100;
                end
                else if(s[10][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[10][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1011; 
                end
                else if(s[9][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[9][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1010;
                     
                end
                else if(s[8][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[8][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1001; 
                end
                else if(s[7][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[7][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b1000; 
                end
                else if(s[6][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[6][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0111; 
                end
                else if(s[5][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[5][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0110; 
                end
                else if(s[4][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[4][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0101; 
                end
                else if(s[3][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[3][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0100; 
                end
                else if(s[2][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[2][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0011; 
                end
                else if(s[1][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[1][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0010; 
                end
                else if(s[0][D_OR_W + 4] == 0) begin
                    reminder_reg[REM_W - 1 : D_END_W] <= s[0][D_OR_W : 0];  
                    reminder_reg[D_END_W - 1 : 4] <= reminder_reg[D_END_W - 5 : 0];
                    quot[(4*it) - 1 -: 4] <= 4'b0001; 
                end else begin
                        reminder_reg <= reminder_reg << 4;
                        quot[(4*it) - 1 -: 4] <= 4'b0000;
                end
            end
            if(done)
                done <= 1'b0;
        end    
    end
endmodule