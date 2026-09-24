// SystemVerilog: a parameterised FIFO with an assertion and a testbench snippet.
module fifo #(parameter int WIDTH = 8, DEPTH = 16) (
    input  logic             clk, rst_n,
    input  logic             push, pop,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic             full, empty
);
    localparam int AW = $clog2(DEPTH);
    logic [WIDTH-1:0] mem [DEPTH];
    logic [AW:0] wr_ptr, rd_ptr;

    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    assign dout  = mem[rd_ptr[AW-1:0]];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0; rd_ptr <= '0;
        end else begin
            if (push && !full) begin mem[wr_ptr[AW-1:0]] <= din; wr_ptr <= wr_ptr + 1'b1; end
            if (pop && !empty) rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Never push into a full FIFO
    property no_overflow; @(posedge clk) disable iff (!rst_n) full |-> !push; endproperty
    assert property (no_overflow) else $error("push while full at %0t", $time);
endmodule

module tb;
    logic clk = 0; always #5 clk = ~clk;
    initial begin
        $display("fifo tb start");
        #100 $finish;
    end
endmodule
