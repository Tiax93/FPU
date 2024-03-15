module ha (
    input a, b,
    output s, c
);

    assign {c, s} = a + b;
    
endmodule



module hac (
    input clk, enable,
    input a, b,
    output reg s, c
);

    always @(posedge clk) begin
        if (enable) begin
            {c, s} <= a + b;
        end
    end
    
endmodule