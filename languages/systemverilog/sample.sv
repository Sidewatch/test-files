// ── Comments ──
// SystemVerilog: warehouse stock controller, FIFO, interface, class-based testbench.
/* Block comment
   spanning lines. */
// TODO: add parity to the ledger
// FIXME: coverage hole on simultaneous push/pop

`timescale 1ns / 1ps
`default_nettype none
`include "uvm_macros.svh"
`define WIDTH 8
`define MAX(a, b) ((a) > (b) ? (a) : (b))
`define DEBUG_ON
`ifdef DEBUG_ON
    `define LOG(msg) $display("[%0t] %s", $time, msg)
`elsif TRACE
    `define LOG(msg) $display("trace: %s", msg)
`else
    `define LOG(msg)
`endif
`ifndef FIFO_DEPTH
    `define FIFO_DEPTH 16
`endif
`undef TRACE
`resetall
`timescale 1ns / 1ps

// ── Packages ──
package stock_pkg;
    typedef enum logic [1:0] { IDLE = 2'b00, RECEIVE = 2'b01, SHIP = 2'b10, ERROR } state_e;
    typedef enum int { LOW = 1, MEDIUM, HIGH } level_e;
    typedef enum bit { OFF, ON } sw_e;

    typedef struct packed {
        logic [7:0]  sku;
        logic [15:0] qty;
        logic        valid;
    } entry_t;

    typedef union packed {
        logic [24:0] raw;
        entry_t      entry;
    } entry_u;

    typedef logic [`WIDTH-1:0] word_t;
    typedef int unsigned       count_t;
    parameter int REORDER_POINT = 25;
    localparam string NAME = "stock";
    localparam real SCALE = 1.5e-3;

    function automatic int clamp(int v, int lo, int hi);
        return (v < lo) ? lo : (v > hi) ? hi : v;
    endfunction

    task automatic log_entry(input entry_t e);
        $display("sku=%0d qty=%0d valid=%b", e.sku, e.qty, e.valid);
    endtask
endpackage

import stock_pkg::*;

// ── Interface ──
interface fifo_if #(parameter int WIDTH = 8) (input logic clk, rst_n);
    logic             push, pop, full, empty;
    logic [WIDTH-1:0] din, dout;

    clocking cb @(posedge clk);
        default input #1step output #1;
        output push, pop, din;
        input  full, empty, dout;
    endclocking

    modport dut (input clk, rst_n, push, pop, din, output full, empty, dout);
    modport tb  (clocking cb, input rst_n);

    property p_no_overflow;
        @(posedge clk) disable iff (!rst_n) full |-> !push;
    endproperty
    assert property (p_no_overflow) else $error("push while full at %0t", $time);
    cover property (@(posedge clk) push ##1 pop);
endinterface

// ── Module with parameters and ports ──
module fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = `FIFO_DEPTH,
    parameter type T = logic [WIDTH-1:0]
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             push, pop,
    input  T                 din,
    output T                 dout,
    output logic             full, empty,
    output logic [$clog2(DEPTH):0] level
);
    localparam int AW = $clog2(DEPTH);
    T mem [DEPTH];
    logic [AW:0] wr_ptr, rd_ptr;
    wire  [AW:0] diff = wr_ptr - rd_ptr;
    tri1  pull_up;
    reg   legacy_reg;
    integer i;
    real    ratio = 3.14;
    time    last;
    string  tag = "fifo";
    bit signed [7:0] signed_val = -8'sd5;
    byte    b = 8'hFF;
    shortint si = 16'd1000;
    longint  li = 64'hDEAD_BEEF_CAFE_F00D;

    // ── Number literals ──
    localparam logic [7:0] LITERALS [0:7] = '{
        8'b1010_1010, 8'o377, 8'd255, 8'hFF, 8'bxxxx_zzzz, 'h1F, 'b1, '1
    };

    // ── Continuous assignment ──
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    assign dout  = mem[rd_ptr[AW-1:0]];
    assign level = diff;
    assign #2 pull_up = 1'b1;

    // ── Sequential logic ──
    always_ff @(posedge clk or negedge rst_n) begin : seq_block
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (push && !full) begin
                mem[wr_ptr[AW-1:0]] <= din;
                wr_ptr              <= wr_ptr + 1'b1;
            end
            if (pop && !empty) rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // ── Combinational logic ──
    state_e state, next;
    always_comb begin
        next = state;
        unique case (state)
            IDLE:    if (push) next = RECEIVE; else if (pop) next = SHIP;
            RECEIVE: next = full ? ERROR : IDLE;
            SHIP:    next = empty ? ERROR : IDLE;
            default: next = IDLE;
        endcase
    end

    always_latch begin
        if (clk) legacy_reg = push;
    end

    always @(posedge clk) begin
        if (rst_n) state <= next; else state <= IDLE;
    end

    always @* begin
        priority casez (din)
            8'b1???_????: last = 1;
            8'b01??_????: last = 2;
            default:      last = 0;
        endcase
    end

    // ── Operators ──
    logic [7:0] a, c, r;
    initial begin
        r = a + c - a * c / 3 % 5;
        r = a ** 2;
        r = a & c | a ^ c ^~ ~a;
        r = ~&a | ~|a ^ ^~a;
        r = a << 2 >> 1;
        r = a <<< 2 >>> 1;
        r = (a == c) ? a : c;
        r = {a, c[3:0]};
        r = {4{a[1:0]}};
        r = a inside {[1:5], 8'hFF};
        r += 1; r -= 1; r *= 2; r /= 2; r %= 8; r &= 8'h0F; r |= 8'h01; r ^= 8'hFF; r <<= 1; r >>= 1;
        r++; r--;
        r = a === c ? 1 : a !== c ? 2 : a ==? c ? 3 : a !=? c ? 4 : 0;
        r = (a && c) || !a;
        r = c[7-:4]; r = c[0+:4];
    end

    // ── Generate ──
    genvar g;
    generate
        for (g = 0; g < 4; g++) begin : gen_loop
            wire [7:0] slice = mem[g];
        end
        if (WIDTH > 8) begin : gen_wide
            initial $display("wide");
        end else begin : gen_narrow
            initial $display("narrow");
        end
        case (DEPTH)
            16: begin : gen_16 end
            default: begin : gen_other end
        endcase
    endgenerate

    // ── Procedural statements ──
    initial begin
        $display("fifo start: %s %0d %0t", tag, DEPTH, $time);
        $monitor("level=%0d", level);
        $readmemh("init.hex", mem);
        #10 last = $time;
        wait (rst_n);
        @(posedge clk);
        repeat (3) @(negedge clk);
        for (int k = 0; k < DEPTH; k++) mem[k] = '0;
        foreach (mem[idx]) mem[idx] = idx;
        i = 0;
        while (i < 4) i++;
        do i--; while (i > 0);
        forever begin
            #5;
            if ($time > 1000) break;
            else continue;
        end
        fork
            begin #1 $display("a"); end
            begin #2 $display("b"); end
        join_any
        disable fork;
        fork : named_fork
            #3 $display("c");
        join
        $fatal(1, "fatal %s", "error");
        $finish;
    end

    // ── Final, tasks and functions ──
    final $display("fifo done");

    function automatic logic [AW:0] next_ptr(input logic [AW:0] p);
        return p + 1'b1;
    endfunction

    task automatic push_word(input T w);
        @(posedge clk);
        mem[wr_ptr[AW-1:0]] = w;
    endtask

    // ── Assertions ──
    property no_overflow;
        @(posedge clk) disable iff (!rst_n) full |-> !push;
    endproperty
    assert property (no_overflow) else $error("push while full at %0t", $time);

    sequence s_push_pop;
        push ##[1:3] pop;
    endsequence
    cover property (@(posedge clk) s_push_pop);

    a_nonempty: assert property (@(posedge clk) pop |-> !empty);
    assume property (@(posedge clk) !(push && pop));
    a_stable: assert property (@(posedge clk) $stable(dout) or $rose(push) or $fell(pop) or $past(full));
endmodule

// ── Classes and randomisation ──
virtual class base_txn;
    rand bit [7:0] sku;
    pure virtual function void print();
endclass

class stock_txn extends base_txn;
    rand int unsigned qty;
    rand sw_e         kind;
    randc bit [3:0]   lane;
    static int        count = 0;
    local int         secret;
    protected int     guarded;
    const int         MAX = 100;

    constraint c_qty  { qty inside {[1:100]}; qty dist { 1 := 5, [2:50] :/ 3 }; }
    constraint c_kind { kind == ON -> qty > 10; solve kind before qty; }

    function new(string name = "txn");
        super.new();
        count++;
    endfunction

    virtual function void print();
        $display("txn sku=%0d qty=%0d kind=%s", sku, qty, kind.name());
    endfunction

    extern function int total();
endclass

function int stock_txn::total();
    return qty * 2;
endfunction

// ── Testbench ──
program automatic test (fifo_if.tb vif);
    stock_txn txn;
    mailbox #(stock_txn) mbx = new();
    semaphore sem = new(1);
    event done;
    int queue [$];
    int assoc [string];
    int dyn [];

    covergroup cg @(vif.cb);
        cp_push: coverpoint vif.cb.push;
        cp_lvl:  coverpoint vif.cb.dout { bins low = {[0:3]}; bins high = {[4:$]}; }
        x: cross cp_push, cp_lvl;
    endgroup

    initial begin
        txn = new("first");
        assert (txn.randomize() with { qty > 5; }) else $error("randomize failed");
        queue.push_back(txn.qty);
        assoc["a"] = 1;
        dyn = new[4];
        mbx.put(txn);
        -> done;
        `uvm_info("TB", "finished", UVM_LOW)
        `LOG("test complete")
    end
endprogram

// ── Top ──
module tb;
    logic clk = 0;
    logic rst_n;
    always #5 clk = ~clk;

    fifo_if #(.WIDTH(8)) intf (.clk, .rst_n);
    fifo #(.WIDTH(8), .DEPTH(16)) dut (
        .clk(clk), .rst_n(rst_n), .push(intf.push), .pop(intf.pop),
        .din(intf.din), .dout(intf.dout), .full(intf.full), .empty(intf.empty), .level()
    );

    initial begin
        rst_n = 0;
        #20 rst_n = 1;
        #1000 $finish;
    end
endmodule

`default_nettype wire
