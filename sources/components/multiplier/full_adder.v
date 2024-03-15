`timescale 1ns / 1ps

module fa (
    input a, b, cin,
    output s, cout
);

    assign {cout, s} = a + b + cin;
    
endmodule

module fac (
    input clk, enable,
    input a, b, cin,
    output reg s, cout
);

    always @(posedge clk) begin
        if (enable) begin
            {cout, s} <= a + b + cin;
        end
    end
    
endmodule
