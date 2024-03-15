`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2024 10:13:22
// Design Name: 
// Module Name: tb_fp_unit
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


module tb_fp_unit();
    
    parameter D_WIDTH = 32;
    parameter sum_memLENGTH = 10;
    parameter prod_memLENGTH = 18; 
    parameter div_memLENGTH = 10; 
    parameter sqrt_memLENGTH = 100; 
    parameter randomOp = 200; 
    
    reg clk = 0;
    always begin
        #1
        clk <= !clk;
    end
    
    reg [D_WIDTH - 1 : 0] memory_sum [0 : sum_memLENGTH - 1];
    reg [D_WIDTH - 1 : 0] memory_prod [0 : prod_memLENGTH - 1];
    reg [D_WIDTH - 1 : 0] memory_div [0 : div_memLENGTH - 1];
    reg [D_WIDTH - 1 : 0] memory_sqrt [0 : sqrt_memLENGTH - 1];
    reg nreset = 0;
    reg input_ready = 0;
    reg [D_WIDTH - 1 : 0] a;
    reg [D_WIDTH - 1 : 0] b;
    reg [0 : 1] opCode;
    
    real current_a;
    real current_b;
    reg [0 : 1] current_op;
    real real_z;


    integer j = 0;
    integer i = 2;
    reg switch = 0;
    reg random = 0;
    
    //output
    wire [D_WIDTH - 1 : 0] z;

    wire done;
    wire busy;
    wire of;
    wire uf;
    wire nx;
    wire nv;
    wire dz;

    real correct_z;
    
    reg[63 : 0] bin_correct_z;

    integer k;
    reg found;
   
   
   //From single precision to double precision
   function automatic [63:0] to64;
        input [31:0] in;
        begin
            to64[63] = in[31];
            if(in[30 : 23] == 8'b11111111) begin
                to64[62 : 52] = 11'b11111111111;
                to64[51 : 0] = {in[22 : 0], 29'd0};
            end        
            else if(in == 32'd0)
                to64 = 64'd0;
            else if(in[30: 23] == 8'd0 && in[22: 0] != 23'd0) begin
                //Se denormalizzato
                found = 1'b0; 
                for(k = 22; k >= 0; k = k - 1) begin
                    if(in[k] && !found) begin
                        to64[62 : 52] = 897 - 23 + k;
                        to64[51 : 0] = {in[22 : 0] << (23 - k), 29'd0};
                        found = 1'b1;
                    end  
                end                   
            end else begin
                to64[62 : 52] = in[30 : 23] + 896;
                to64[51 : 0] = {in[22 : 0], 29'd0};
            end
        end
    endfunction 
    
    fp_unit_new fp_unit_inst(
        .clk(clk),
        .nreset(nreset),
        .input_ready(input_ready),
        .a(a),
        .b(b),
        .op(opCode),
        .round_mode(2'b00),
        .z(z),
        .done(done),
        .busy(busy),
        .of(of), //Overflow
        .uf(uf), //Underflow
        .dz(dz), //Division by Zero
        .nx(nx), //Inexact Operation
        .nv(nv) //Invalid Operation
    );
    
    initial $readmemb("fp_bin_mult.mem", memory_prod);
    initial $readmemb("fp_vector.mem", memory_div);
    initial $readmemb("fp_add_vector.mem", memory_sum);
    initial $readmemb("fp_sqrt_vector.mem", memory_sqrt);
    
    initial begin
        #1
        a = memory_prod[1];
        b = memory_prod[0];
        opCode = 2'b00; //prod
        #4
        input_ready <= 1'b1;
        nreset <= 1'b1;       
    end
    
    always @(negedge clk) begin
        if(done) begin
            current_a = $bitstoreal(to64(a));
            current_b = $bitstoreal(to64(b));
            current_op = opCode;
            
            if(!random) begin
                if(opCode == 2'b00) begin
                    if(i == prod_memLENGTH) begin
                        i = 0;
                        a = memory_div[i]; 
                        b = memory_div[i + 1];
                        opCode = 2'b01;
                        j = -1;
                        i = i + 2; 
          
                    end else begin
                        a = memory_prod[i]; 
                        b = memory_prod[i + 1];   
                        i = i + 2;               
                    end
                end
                else if(opCode == 2'b01) begin
                    if(i == div_memLENGTH) begin
                        i = 0;
                        a = memory_sum[i]; 
                        b = memory_sum[i + 1];
                        opCode = 2'b10;
                        j = -1;
                        i = i + 2; 
          
                    end else begin
                        a = memory_div[i]; 
                        b = memory_div[i + 1]; 
                        i = i + 2;                 
                    end
                
                end
                else if(opCode == 2'b10) begin
                    if(i == sum_memLENGTH) begin
                        i = 0;
                        a = memory_sqrt[i];
                        b = memory_sqrt[i + 1];
                        opCode = 2'b11;
                        j = -1;
                        i = i + 2; 
          
                    end else begin
                        a = memory_sum[i]; 
                        b = memory_sum[i + 1];
                        i = i + 2;                 
                    end
                end 
                else if(opCode == 2'b11) begin
                    if(i == sqrt_memLENGTH) begin
                        random = 1;
                        a = $random; 
                        b = $random;
                        opCode = {$random}%3;
                        j = -1;
          
                    end else begin
                        a = memory_sqrt[i];
                        b = memory_sqrt[i + 1]; //sqrt result
                        i = i + 2;                 
                    end
                end 
            end else begin
                if(j < randomOp) begin
                    a = $random;
                    b = $random;
                    opCode = {$random}%3; 
                end else $stop;       
            end
        end
    end
    
    always @(posedge clk) begin
        if(done) begin
            real_z = $bitstoreal(to64(z));
            
            if(current_op == 2'b00) correct_z = current_a * current_b;
            else if(current_op == 2'b01) correct_z = current_a / current_b;
            else if(current_op == 2'b10) correct_z = current_a + current_b;
            else if(current_op == 2'b11) correct_z = current_b;
            
            real_z = $bitstoreal(to64(z));
            if(!random || j == -1) begin
                if(current_op == 2'b00) begin
                    $write("F prod"); //File
                    if(j == -1) begin      
                        j = 0;
                        $display((prod_memLENGTH / 2) - 1);
                    end
                    else begin
                        $display(j);
                        if(j == (prod_memLENGTH / 2) - 1) 
                            j = 0;
                        else j = j + 1;
                    end
                end
                else if(current_op == 2'b01) begin
                    $write("F div"); //File
                    if(j == -1) begin      
                        j = 0;
                        $display((div_memLENGTH / 2) - 1);
                    end
                    else begin
                        $display(j);
                        if(j == (div_memLENGTH / 2) - 1) 
                            j = 0;
                        else j = j + 1;
                    end
                end else if(current_op == 2'b10) begin
                    $write("F sum"); //File
                    if(j == -1) begin      
                        j = 0;
                        $display((sum_memLENGTH / 2) - 1);
                    end
                    else begin
                        $display(j);
                        if(j == (sum_memLENGTH / 2) - 1) 
                            j = 0;
                        else j = j + 1;
                    end
                end else if(current_op == 2'b11) begin
                    $write("F sqrt"); //File
                    if(j == -1) begin      
                        j = 0;
                        $display((sqrt_memLENGTH / 2) - 1);
                    end
                    else begin
                        $display(j);
                        if(j == (sqrt_memLENGTH / 2) - 1) 
                            j = 0;
                        else j = j + 1;
                    end
                end       
            end else begin
                $write("R "); //Random
                $write(current_op); //Random
                $display(j);
                j = j + 1;  
            end
            
            bin_correct_z = $realtobits(correct_z);
            if(bin_correct_z[62 : 51] == 12'b111111111111 && z[31 : 22] == 9'b111111111)
                $display("CORRECT result qNaN");
            else if(current_op == 2'b00 && (current_a == 0 || current_b == 0)) begin
                if(real_z == 0) begin
                    $display("CORRECT result MULT 0");
                end
            end
            else if(bin_correct_z[62 : 52] == 11'b11111111111 && z[31 : 23] == 8'b11111111 && (bin_correct_z[63] == z[31])) begin
                $display("CORRECT result INF");
            end    
            else if(0.99999 < (real_z / correct_z) && (real_z / correct_z) < 1.00001) begin
                $display("CORRECT result");
            end
            else begin
                if(of && (correct_z >= 3.4028234663852886e+38 || correct_z <= -3.4028234663852886e+38))
                    $display("CORRECT result of");
                else if(uf && (correct_z <= 1.401298464324817e-45 || correct_z >= -1.401298464324817e-45))
                    $display("CORRECT result uf"); 
                else begin
                    if(current_op == 2'b11) begin
                        $display("WRONG Square ROOT");
                        $write("A: ");
                        $display(current_a);
                        $write("Z real: ");
                        $display(real_z);
                        $write("Correct Z: ");
                        $display(correct_z);
                    end else begin 
                        $display("WRONG result");
                        $write("A: ");
                        $display(current_a);
                        $write("B: ");
                        $display(current_b);
                        $write("Z: ");
                        $display(real_z);
                        $write("Correct Z: ");
                        $display(correct_z);
                    end
                end

            end

            if(dz) $display("Division by Zero");
            if(of) $display("Overflow");
            if(uf) $display("Underflow");
            if(nx) $display("Inexact Operation");
            if(nv) $display("Invalid Operation");
        end

    end
endmodule
