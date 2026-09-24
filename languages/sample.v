// Verilog-2001: a parameterised counter with enable and synchronous reset.
`timescale 1ns / 1ps
`define MAX_COUNT 255

module counter #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    output reg  [WIDTH-1:0] count,
    output wire             wrapped
);
    assign wrapped = (count == `MAX_COUNT);

    always @(posedge clk) begin
        if (rst)
            count <= {WIDTH{1'b0}};
        else if (en)
            count <= count + 1'b1;
    end
endmodule

module tb_counter;
    reg clk = 0, rst = 1, en = 0;
    wire [7:0] count;
    wire wrapped;

    counter #(.WIDTH(8)) dut (.clk(clk), .rst(rst), .en(en), .count(count), .wrapped(wrapped));

    always #5 clk = ~clk;
    initial begin
        #12 rst = 0; en = 1;
        #2600 $display("count=%0d wrapped=%b", count, wrapped);
        $finish;
    end
endmodule
