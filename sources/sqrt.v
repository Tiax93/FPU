`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.03.2024 06:08:19
// Design Name: 
// Module Name: sqrt
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


module sqrt(
    input clk,
    input nreset,
    input enable,
    input [69 : 0] value,
    output reg [34 : 0] root,
    output reg nx, //Inexact Root
    output busy,
    output reg done
    );
    
    reg [1 : 0] ctrl;
    reg [69 : 0] value_r;
    reg [69 : 0] rest;
    reg [69 : 0] bit_n;
    wire [69 : 0] sum; 
    
    assign busy = ctrl[0] || ctrl[1];
    assign sum = rest + bit_n;

    always @(posedge clk, negedge nreset) begin
        if(!nreset) begin
            ctrl <= 8'd0;
            done <= 1'b0;
        end 
        else begin
            if(enable && !busy) begin
                rest <= 70'd0;
                nx <= 1'b0;
                bit_n[69 : 68] <= 2'b01;
                bit_n[67 : 0] <= 68'd0;
                ctrl <= 2'b01;
                value_r <= value;                    
            end
            else if(ctrl == 2'b01) begin
                if(bit_n > value_r)
                    bit_n <= bit_n >> 2;
                else
                    ctrl <= 2'b10;
            end
            else if(ctrl == 2'b10) begin
                if(bit_n != 70'd0) begin
                    bit_n <= bit_n >> 2; 
                    if(value_r >= sum) begin
                        value_r <= value_r - sum;
                        rest <= (rest >> 1) + bit_n;
                    end else
                        rest <= rest >> 1;
                   
                end else begin
                    if(value_r > 0)
                        nx <= 1'b1;
                    done <= 1'b1;
                    root <= rest[34 : 0];
                    ctrl <= 2'b00;
                end
            end
            if(done)
                done <= 1'b0;
        end        
    end
    
endmodule
