// SystemVerilog IEEE 1800-2023 — syntax showcase
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


// ── Directives: every compiler directive ──
`begin_keywords "1800-2023"
`pragma protect begin
`pragma reset
`line 100 "generated.sv" 0
`celldefine
`define STR(x) `"x`"
`define CAT(a, b) a``b
`define MULTI(a) \
    $display("%s", `STR(a)); \
    $display("%s", `"a`")
`define PRINT_LOCATION $display("%s:%0d", `__FILE__, `__LINE__)
`endcelldefine
`unconnected_drive pull1
`nounconnected_drive
`include <vendor_macros.svh>
`ifdef SYNTHESIS
    `define IS_SYNTH 1
`elsif SIMULATION
    `define IS_SYNTH 0
`endif
`undefineall
`end_keywords

// ── Packages: exports, nets, user types, let ──
package types_pkg;
    typedef enum logic [2:0] { RED, GREEN[3], BLUE = 3'd7 } colour_e;   // ranged enum names
    typedef enum { A = 1, B, C = 10 } plain_e;
    typedef enum bit [1:0] { P0, P1, P2, P3 } prio_e;
    typedef struct { int a; string b; real c; } unpacked_s;
    typedef struct packed signed { logic [3:0] hi; logic [3:0] lo; } packed_s;
    typedef union tagged { void Invalid; int Valid; } tagged_u;
    typedef union { int i; shortreal f; } plain_u;
    typedef class forward_class;
    typedef int unsigned uint_t;
    typedef logic [3:0][7:0] matrix_t;
    typedef bit [7:0] byte_queue_t [$];
    typedef type(uint_t) alias_t;
    function automatic logic [7:0] bus_resolve(input logic [7:0] drivers []);
        bus_resolve = drivers[0];
    endfunction
    nettype real real_net_t;
    nettype logic [7:0] bus_net_t with bus_resolve;
    let max2(a, b) = (a > b) ? a : b;
    let clamp3(x, lo = 0, hi = 255) = (x < lo) ? lo : (x > hi) ? hi : x;
    parameter bit DEBUG = 1'b0;
    const string VERSION = "1.0";
    export *::*;
endpackage : types_pkg

package derived_pkg;
    import types_pkg::*;
    import types_pkg::colour_e;
    export types_pkg::colour_e;
endpackage

// ── Net types and data types ──
module data_types;
    timeunit 1ns;
    timeprecision 1ps;
    wire        w;
    wand        wa;
    wor         wo;
    tri         t;
    tri0        t0;
    tri1        t1;
    triand      tand;
    trior       tor;
    trireg (small) cap;
    supply0     gnd;
    supply1     vdd;
    uwire       uw;
    interconnect ic;
    wire [7:0] vec;
    wire signed [3:0] svec;
    wire (strong1, weak0) driven = 1'b1;
    wire #(1, 2, 3) delayed = w;
    var logic [3:0] explicit_var;
    logic   [7:0] packed_vec;
    logic   [3:0][7:0] two_dim_packed;
    int     unpacked [4][2];
    int     unpacked_c [0:3];
    bit     [31:0] word;
    byte unsigned ub;
    shortreal sr = 1.5;
    real    r = 3.14e2;
    realtime rt = 1.5ns;
    chandle ch;
    event   ev, ev2;
    string  str = "hello";
    string  triple = """multi
line
string""";
    string  esc = "tab\t newline\n quote\" backslash\\ octal\101 hex\x41 percent%%";
    int     dyn [];
    int     queue [$];
    int     bounded [$:7];
    int     assoc_int [int];
    int     assoc_str [string];
    int     assoc_any [*];
    int     assoc_class [stock_txn];
    colour_e colour = GREEN1;
    packed_s ps = '{hi: 4'hF, lo: 4'h0};
    unpacked_s us = '{a: 1, b: "x", c: 2.0};
    unpacked_s defaults = '{default: 0};
    tagged_u tu = tagged Valid 42;
    matrix_t mat = '{default: 8'h00};

    // number literals: every base, size, sign, unknown
    localparam [63:0] NUMS [0:15] = '{
        64'd0, 'd10, 8'sh7F, -4'sd3, 12'b1010_1100_0011, 3'o7, 16'hDEAD, 'hx, 'bz, 4'bx01z, 8'hX?, '0, '1, 'x, 'z, 8'h?F
    };
    localparam real REALS [0:3] = '{1.0, 2.5e3, 1_000.5, 3E-2};
    localparam time TIMES [0:4] = '{1s, 100ms, 10us, 5ns, 1ps};
    localparam time FEMTO = 1fs;
    localparam time STEP = 1step;
endmodule

// ── Operators: the full table ──
module operators;
    logic [7:0] a, b, c;
    logic       x, y;
    int         i, j;
    initial begin
        c = +a; c = -a; c = !a; c = ~a;
        c = &a; c = |a; c = ^a; c = ~&a; c = ~|a; c = ~^a; c = ^~a;
        c = a + b; c = a - b; c = a * b; c = a / b; c = a % b; c = a ** b;
        c = a & b; c = a | b; c = a ^ b; c = a ~^ b; c = a ^~ b;
        c = a << 1; c = a >> 1; c = a <<< 1; c = a >>> 1;
        x = a < b; x = a <= b; x = a > b; x = a >= b;
        x = a == b; x = a != b; x = a === b; x = a !== b; x = a ==? b; x = a !=? b;
        x = x && y; x = x || y; x = x -> y; x = x <-> y;
        c = x ? a : b;
        c = {a[3:0], b[3:0]};
        c = {2{a[3:0]}};
        c = a[3-:4]; c = a[0+:4]; c = a[7:4];
        x = a inside {1, 2, [4:8]};
        x = a inside {b, c};
        x = !(a inside {[0:3]});
        i += 1; i -= 1; i *= 2; i /= 2; i %= 3; i &= 1; i |= 1; i ^= 1; i <<= 1; i >>= 1; i <<<= 1; i >>>= 1;
        i++; i--; ++i; --i;
        j = (i = 5) + 1;
        j = i++ + ++i;
        j = int'(a); j = signed'(a); j = unsigned'(j); j = 8'(i); j = type(i)'(a);
        j = $cast(c, a);
        void'($urandom());
        a = {<<{b}};
        a = {>>8{b}};
        b = {<<4{a}};
    end
endmodule

// ── Procedural: every statement form ──
module procedural (input logic clk, rst_n, input logic [3:0] sel);
    logic [7:0] data, mem [16];
    int i, count;
    event e1, e2;
    process p;

    // blocking vs nonblocking with delays and intra-assignment controls
    always @(posedge clk) begin : block_label
        data <= #1 data + 1;
        data <= @(posedge clk) 8'h00;
        data  = #2 8'hFF;
        data  = repeat (2) @(negedge clk) 8'h0F;
        count++;
    end : block_label

    always @(posedge clk, negedge rst_n) if (!rst_n) count <= 0; else count <= count + 1;
    always @(sel or data or e1) count = sel;
    always @(*) count = data;
    always @* count = data;
    always @(posedge clk iff rst_n) count <= 0;
    always #10 data = ~data;

    // conditional forms
    initial begin
        if (sel == 0) count = 1;
        else if (sel == 1) count = 2;
        else count = 3;
        unique if (sel == 0) count = 1; else if (sel == 1) count = 2;
        unique0 if (sel == 0) count = 1; else if (sel == 1) count = 2;
        priority if (sel == 0) count = 1; else count = 2;
        case (sel)
            4'd0, 4'd1: count = 0;
            4'd2:       begin count = 1; end
            default:    count = 2;
        endcase
        casez (sel)
            4'b1???: count = 0;
            4'b01zz: count = 1;
            default: ;
        endcase
        casex (sel)
            4'b1xx0: count = 0;
            default: count = 1;
        endcase
        unique case (sel) 0: count = 0; 1: count = 1; default: count = 2; endcase
        unique0 case (sel) 0: count = 0; 1: count = 1; endcase
        priority case (sel) 0: count = 0; default: count = 1; endcase
        case (sel) inside
            [0:3]:   count = 0;
            4'b1???: count = 1;
            default: count = 2;
        endcase
        case (data) matches
            tagged Valid .v: count = v;
            default: count = 0;
        endcase
        if (tu matches tagged Valid .n &&& n > 3) count = n;
    end

    // loops
    initial begin
        for (int k = 0; k < 4; k++) count += k;
        for (int k = 0, m = 10; k < m; k += 2, m--) count += k;
        for (i = 0; i < 4; i = i + 1) begin count++; end
        foreach (mem[idx]) mem[idx] = idx;
        foreach (unpacked_array[a, b]) unpacked_array[a][b] = a + b;
        while (count < 10) count++;
        do count--; while (count > 0);
        repeat (4) count++;
        repeat (4) @(posedge clk);
        forever begin
            @(posedge clk);
            if (count > 100) break;
            if (count == 50) continue;
        end
    end

    // timing controls and events
    initial begin
        #10;
        #(1.5);
        #1ns;
        @(posedge clk);
        @(negedge clk or posedge rst_n);
        @(e1);
        wait (rst_n == 1);
        wait (e1.triggered);
        -> e1;
        ->> e2;
        wait_order (e1, e2) else $error("order");
        @e1;
        @(posedge clk iff rst_n);
    end

    // fork and join variants, process control
    initial begin
        fork
            #1 $display("1");
            #2 $display("2");
        join
        fork
            #1 $display("any");
        join_any
        fork
            #1 $display("none");
        join_none
        wait fork;
        disable fork;
        fork : label_fork
            begin : inner #1; end : inner
        join : label_fork
        p = process::self();
        void'(p.status());
        p.kill();
        p.await();
        p.suspend();
        p.resume();
        disable block_label;
    end

    // force, release, assign
    initial begin
        force data = 8'hAA;
        release data;
    end
    reg r1;
    always @(posedge clk) begin
        assign r1 = 1'b1;
        deassign r1;
    end

    // system tasks
    initial begin
        $display("display %0d %b %h %o %s %t %m %e %f %g %c", 1, 2, 3, 4, "five", $time, 1.0, 2.0, 3.0, 65);
        $write("write ");
        $strobe("strobe");
        $monitoron; $monitoroff;
        $info("info"); $warning("warning"); $error("error"); $fatal(2, "fatal");
        $sformat(str, "%0d", count);
        str = $sformatf("%0d-%s", count, "x");
        $fopen("out.txt", "w");
        $fclose(fd);
        $fdisplay(fd, "line");
        $fwrite(fd, "no newline");
        $fscanf(fd, "%d", count);
        $fgets(str, fd);
        $feof(fd);
        $readmemb("data.bin", mem);
        $writememh("dump.hex", mem);
        $dumpfile("wave.vcd"); $dumpvars(0, procedural); $dumpon; $dumpoff; $dumpflush;
        $test$plusargs("DEBUG");
        $value$plusargs("SEED=%d", seed);
        $random; $random(seed); $urandom; $urandom(seed); $urandom_range(10, 0); $srandom(1);
        $time; $stime; $realtime; $timeformat(-9, 3, " ns", 10);
        $bits(data); $size(mem); $left(mem); $right(mem); $low(mem); $high(mem); $increment(mem);
        $dimensions(mem); $unpacked_dimensions(mem); $countones(data); $onehot(data); $onehot0(data);
        $isunknown(data); $clog2(100); $ln(1.0); $log10(100.0); $exp(1.0); $sqrt(4.0); $pow(2.0, 3.0);
        $floor(1.5); $ceil(1.5); $sin(0.0); $cos(0.0); $tan(0.0); $atan2(1.0, 1.0); $hypot(3.0, 4.0);
        $itor(1); $rtoi(1.5); $realtobits(1.0); $bitstoreal(64'd0); $shortrealtobits(1.0); $bitstoshortreal(32'd0);
        $signed(data); $unsigned(data); $typename(data); $typeof(data);
        $assertoff; $asserton; $assertkill; $assertcontrol(3);
        $stop; $finish(0);
        $root.tb.clk = 0;
        $unit::global_var = 1;
    end

    // functions and tasks: every argument style
    function automatic int add(int a, int b = 1, const ref int c, ref int d, input int e, output int f, inout int g);
        return a + b;
    endfunction : add
    function void no_return(); endfunction
    function logic [7:0] vec_ret(); return 8'hFF; endfunction
    function static int static_fn(); static int counter = 0; return counter++; endfunction
    function int factorial(int n); return (n <= 1) ? 1 : n * factorial(n - 1); endfunction
    function int implicit_return(); implicit_return = 42; endfunction
    task automatic wait_cycles(input int n = 1);
        repeat (n) @(posedge clk);
    endtask : wait_cycles
    task static static_task; endtask
    import "DPI-C" function int c_add(input int a, input int b);
    import "DPI-C" context task c_wait(input int ns);
    import "DPI-C" pure function real c_sqrt(input real x);
    import "DPI-C" function void c_alias = c_actual_name();
    export "DPI-C" function sv_callback;
    function int sv_callback(int x); return x; endfunction
endmodule

// ── Gate-level primitives, UDPs, switches, specify ──
primitive mux2 (output y, input s, a, b);
    table
    // s a b : y
       0 1 ? : 1;
       0 0 ? : 0;
       1 ? 1 : 1;
       1 ? 0 : 0;
       ? 1 1 : 1;
       ? 0 0 : 0;
    endtable
endprimitive

primitive dff (output reg q, input d, clk);
    initial q = 1'b0;
    table
    // d clk : q : q+
       0 (01) : ? : 0;
       1 (01) : ? : 1;
       ? (1x) : ? : -;
       * ?    : ? : -;
       ? (?0) : ? : -;
    endtable
endprimitive

module gates (input a, b, en, output y1, y2, y3, y4, y5, y6, y7, y8, y9);
    and  g1 (y1, a, b);
    nand g2 (y2, a, b);
    or   g3 (y3, a, b);
    nor  g4 (y4, a, b);
    xor  g5 (y5, a, b);
    xnor #(1, 2) g6 (y6, a, b);
    buf  g7 (y7, a);
    not  g8 (y8, a);
    bufif1 g9 (y9, a, en);
    bufif0 (y9, a, en);
    notif0 (y9, a, en);
    notif1 (y9, a, en);
    nmos  n1 (y9, a, en);
    pmos  p1 (y9, a, en);
    rnmos n2 (y9, a, en);
    cmos  c1 (y9, a, en, ~en);
    tran  t1 (a, b);
    tranif1 t2 (a, b, en);
    rtran r1 (a, b);
    pullup (y9);
    pulldown (y8);
    mux2 u_mux (.y(y1), .s(en), .a(a), .b(b));

    specify
        specparam tRise = 1.2, tFall = 1.5;
        (a => y1) = (tRise, tFall);
        (a, b *> y2) = 2;
        if (en) (a => y3) = 1;
        ifnone (a => y3) = 2;
        (posedge a => (y4 : b)) = 3;
        $setup(a, posedge b, 1);
        $hold(posedge b, a, 1);
        $setuphold(posedge b, a, 1, 1);
        $width(posedge a, 5);
        $period(posedge a, 10);
        $recovery(posedge a, posedge b, 1);
        $removal(posedge a, posedge b, 1);
        $skew(posedge a, posedge b, 1);
        $nochange(posedge a, b, 0, 0);
    endspecify
endmodule

// ── Module headers: ports, parameters, instantiation ──
module non_ansi (a, b, y, bus);
    input  a, b;
    output y;
    inout  [3:0] bus;
    wire   a, b;
    reg    y;
    parameter P = 1;
    always @* y = a & b;
endmodule

macromodule macro_mod (input wire in, output wire out);
    assign out = in;
endmodule

module ports #(
    parameter int N = 4,
    parameter type T = logic,
    localparam int W = $clog2(N)
) (
    input  wire logic [N-1:0] in,
    output var   T            out,
    inout  tri                io,
    ref    int                shared,
    interface.dut             bus_if,
    fifo_if.dut               fifo_port
);
    // instantiation styles
    macro_mod m0 (in[0], out);
    macro_mod m1 (.in(in[0]), .out(out));
    macro_mod m2 (.in, .out);
    macro_mod m3 (.*);
    macro_mod m4 (.in(in[0]), .out());
    macro_mod #(.N(2)) m5 [3:0] (.in(in[3:0]), .out());
    macro_mod m6 (.in(in[0]), .out(out)), m7 (.in(in[1]), .out());
    ports #(8, logic) nested (.in(8'h00), .out(), .io(), .shared(), .bus_if(bus_if), .fifo_port(fifo_port));
    defparam m1.P = 2;
    bind ports macro_mod bound_instance (.in(in[0]), .out());
    alias io = out;
    initial begin
        m1.out_signal = 1;
        $root.ports.m1.in = 0;
    end
endmodule

extern module declared_elsewhere (input a, output b);
extern macromodule declared_macro (input a);

// ── Interfaces: modports with tasks, virtual interfaces, clocking ──
interface bus_if #(parameter int AW = 16, DW = 32) (input logic clk);
    logic [AW-1:0] addr;
    logic [DW-1:0] wdata, rdata;
    logic          write, valid, ready;

    clocking drv_cb @(posedge clk);
        default input #1step output #2;
        output addr, wdata, write, valid;
        input  rdata, ready;
        inout  io_signal;
    endclocking
    clocking mon_cb @(negedge clk);
        input addr, wdata, rdata, write, valid, ready;
    endclocking
    default clocking @(posedge clk);
    endclocking
    global clocking gclk @(posedge clk); endclocking
    default disable iff (!clk);

    modport master (clocking drv_cb, import task reset());
    modport slave  (input addr, wdata, write, valid, output rdata, ready, import function bit hit());
    modport monitor (clocking mon_cb);
    modport internal (output .alias_name(addr), input .rdata(rdata));

    task automatic reset(); addr = '0; endtask
    function bit hit(); return valid & ready; endfunction
    extern task send(input [DW-1:0] d);
    initial begin
        drv_cb.addr <= 0;
        ##1 drv_cb.write <= 1;
        @(drv_cb);
        @(posedge clk);
    end
endinterface : bus_if

interface class printable;
    pure virtual function void print();
endclass

interface class comparable #(type T = int);
    pure virtual function bit equals(T other);
endclass

// ── Classes: everything ──
typedef class forward_class;
virtual class abstract_base #(type T = int, int N = 4);
    protected T items [N];
    pure virtual function T get(int idx);
    pure virtual task process();
    virtual function void common(); endfunction
endclass

class concrete extends abstract_base #(int, 8) implements printable, comparable #(concrete);
    // properties: every qualifier
    static int instances;
    local int private_counter;
    protected int protected_value;
    const int CONSTANT = 7;
    static const int STATIC_CONSTANT = 9;
    rand int unsigned rnd;
    randc bit [2:0] cyclic;
    rand bit [7:0] arr [4];
    rand bit [3:0] queue_rnd [$];
    rand packed_s packed_field;
    rand concrete child;
    real not_rand;
    string name = "concrete";
    typedef enum { LEFT, RIGHT } side_e;
    typedef struct { int a; } inner_s;
    parameter int LOCAL_PARAM = 1;
    covergroup cg_inner with function sample(int v);
        option.per_instance = 1;
        option.name = "cg_inner";
        option.comment = "inner coverage";
        option.goal = 90;
        option.at_least = 2;
        option.auto_bin_max = 16;
        type_option.merge_instances = 1;
        coverpoint v {
            bins low = {[0:3]};
            bins mid[] = {[4:7]};
            bins high[4] = {[8:15]};
            bins other = default;
            bins seq = (1 => 2 => 3);
            bins rep = (1[*3]);
            bins goto = (1[->2]);
            bins nonc = (1[=2]);
            bins trans = (1, 2 => 3, 4);
            illegal_bins bad = {16};
            ignore_bins skip = {17};
            wildcard bins wc = {4'b1??0};
            bins withb = {[0:20]} with (item % 2 == 0);
        }
        cp_iff: coverpoint v iff (v > 0);
        cx: cross cp_iff, v {
            ignore_bins ib = binsof(cp_iff) intersect {1};
            illegal_bins ill = binsof(cp_iff.low) && binsof(v);
            bins sel = binsof(v) || binsof(cp_iff);
        }
    endgroup

    // constraints: every form
    constraint c_basic { rnd inside {[1:100]}; rnd != 50; }
    constraint c_dist { rnd dist { 1 := 10, [2:5] :/ 20, 6 := 1 }; }
    constraint c_impl { (cyclic > 3) -> (rnd < 10); }
    constraint c_if { if (rnd > 50) cyclic == 1; else cyclic == 2; }
    constraint c_foreach { foreach (arr[i]) arr[i] inside {[0:9]}; foreach (arr[i]) if (i > 0) arr[i] > arr[i-1]; }
    constraint c_solve { solve rnd before cyclic; }
    constraint c_soft { soft rnd == 10; soft cyclic inside {1, 2}; }
    constraint c_unique { unique {arr[0], arr[1], arr[2]}; }
    constraint c_size { queue_rnd.size() inside {[1:4]}; queue_rnd.sum() < 20; }
    constraint c_disable { disable soft rnd; }
    constraint c_func { rnd == helper(cyclic); }
    constraint c_iff { (cyclic == 0) <-> (rnd == 0); }
    constraint c_mult { rnd == a_prop * 2; rnd >= 1; rnd <= 99 || rnd == 200; }
    static constraint c_static { rnd < 1000; }
    constraint c_extern;
    constraint :initial c_init { rnd > 0; }
    constraint :final c_fin { rnd < 500; }
    constraint :extends c_ext { rnd != 0; }
    int a_prop = 3;

    function new(string name = "concrete", concrete parent = null);
        super.new();
        this.name = name;
        instances++;
        if (parent != null) child = parent;
    endfunction

    function int helper(int x); return x + 1; endfunction
    virtual function void print(); $display("%s", name); endfunction
    virtual function bit equals(concrete other); return other.rnd == rnd; endfunction
    virtual function int get(int idx); return items[idx]; endfunction
    virtual task process(); #1; endtask
    static function int count(); return instances; endfunction
    protected function void secret(); endfunction
    local function void hidden(); endfunction
    function void pre_randomize(); endfunction
    function void post_randomize(); endfunction
    function void do_copy(concrete rhs); this.rnd = rhs.rnd; endfunction
    function concrete clone(); concrete c = new(); c.do_copy(this); return c; endfunction
    extern virtual function void extern_fn(int x);
    extern static task extern_task();
    function :final void final_fn(); endfunction
    function :initial void initial_fn(); endfunction
    function :extends void extends_fn(); endfunction

    function void randomise_demo();
        concrete other = new();
        int ok;
        ok = this.randomize();
        ok = this.randomize() with { rnd > 5; };
        ok = this.randomize(rnd) with { rnd < 5; };
        ok = this.randomize(null);
        ok = std::randomize(ok) with { ok > 0; };
        void'(other.randomize());
        rnd_mode_demo();
    endfunction

    function void rnd_mode_demo();
        this.rnd.rand_mode(0);
        this.c_basic.constraint_mode(0);
    endfunction
endclass : concrete

function void concrete::extern_fn(int x); endfunction
task concrete::extern_task(); endtask
constraint concrete::c_extern { rnd > 0; }

class parameterised #(type T = int, int DEPTH = 8, string NAME = "p") extends concrete;
    T storage [$:DEPTH];
    typedef parameterised #(T, DEPTH, NAME) this_type;
    static function this_type create(); this_type t = new(); return t; endfunction
    function void push(T value); storage.push_back(value); endfunction
    function T pop(); return storage.pop_front(); endfunction
endclass

typedef parameterised #(bit [7:0], 4) byte_stack_t;

class generic_handlers;
    static function void demo();
        concrete c;
        concrete d;
        parameterised #(int) p;
        if (!$cast(c, p)) $display("cast failed");
        c = new;
        c = new();
        d = new c;
        c = null;
        if (c == null) return;
        if (c.instances > 0) c.print();
        begin : weak_block
            c = concrete::create_default();
        end
    endfunction
endclass

// ── Queues, dynamic and associative arrays: every method ──
module array_methods;
    int q [$] = '{3, 1, 2};
    int da [];
    int aa [string];
    int fixed [4] = '{1, 2, 3, 4};
    int found [$];
    string key;
    int sum_v;
    initial begin
        q.push_back(4); q.push_front(0); void'(q.pop_back()); void'(q.pop_front());
        q.insert(1, 9); q.delete(1); q.delete();
        void'(q.size());
        q = {q, 5}; q = {6, q}; q = q[1:$]; q = q[0:$-1];
        da = new[4]; da = new[8](da); da.delete(); void'(da.size());
        aa["a"] = 1; aa["b"] = 2;
        void'(aa.num()); void'(aa.size()); void'(aa.exists("a"));
        void'(aa.first(key)); void'(aa.last(key)); void'(aa.next(key)); void'(aa.prev(key));
        aa.delete("a"); aa.delete();
        found = q.find(x) with (x > 1);
        found = q.find_index(x) with (x == 2);
        found = q.find_first(x) with (x > 0);
        found = q.find_first_index(x) with (x > 0);
        found = q.find_last(x) with (x > 0);
        found = q.find_last_index(x) with (x > 0);
        found = q.min(); found = q.max(); found = q.unique(); found = q.unique_index();
        sum_v = q.sum(); sum_v = q.product(); sum_v = q.and(); sum_v = q.or(); sum_v = q.xor();
        sum_v = q.sum with (item * 2);
        q.reverse(); q.sort(); q.rsort(); q.shuffle();
        q.sort with (item % 3);
        q.rsort(x) with (x);
        foreach (aa[k]) $display("%s=%0d", k, aa[k]);
        foreach (fixed[i]) fixed[i] = fixed.size() - i;
        $display("%p", q);
    end
endmodule

// ── Strings and chandles ──
module string_methods;
    string s = "Hello", t;
    int n;
    initial begin
        n = s.len();
        t = s.toupper(); t = s.tolower();
        s.putc(0, "J");
        void'(s.getc(0));
        t = s.substr(1, 3);
        n = s.compare("x"); n = s.icompare("X");
        n = s.atoi(); n = s.atohex(); n = s.atooct(); n = s.atobin();
        s.hextoa(255); s.itoa(10);
        t = {s, " ", "world"};
        t = {3{"ab"}};
        if (s == "Hello" && s != t && s < t) $display("%s", s);
    end
endmodule

// ── Assertions and properties: every operator ──
module assertions (input logic clk, rst_n, a, b, c, req, ack, input logic [3:0] data);
    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    sequence s_basic;
        a ##1 b ##2 c;
    endsequence
    sequence s_range;
        a ##[1:3] b ##[0:$] c ##[*] a ##[+] b;
    endsequence
    sequence s_repeat;
        a [*3] ##1 b [*1:4] ##1 c [*] ##1 a [+] ##1 b [=2] ##1 c [->3] ##1 a [->1:2];
    endsequence
    sequence s_ops;
        (a ##1 b) and (c ##1 a) ;
    endsequence
    sequence s_or;      (a ##1 b) or (c ##2 a);       endsequence
    sequence s_intersect;(a ##[1:3] b) intersect (c ##[2:4] a); endsequence
    sequence s_within;  a within (b ##1 c);            endsequence
    sequence s_through; a throughout (b ##1 c);        endsequence
    sequence s_first;   first_match(a ##[1:3] b);      endsequence
    sequence s_local (logic [3:0] arg);
        logic [3:0] saved;
        (req, saved = data) ##1 (ack && data == saved + arg);
    endsequence
    sequence s_end; @(posedge clk) a ##1 b;            endsequence
    sequence s_method; s_basic.triggered ##1 s_basic.matched; endsequence
    sequence s_action (x); (x, $display("tick")) ##1 b; endsequence

    property p_impl;      a |-> b;                                 endproperty
    property p_nonover;   a |=> b;                                 endproperty
    property p_followed;  a #-# b;                                 endproperty
    property p_followed2; a #=# b;                                 endproperty
    property p_not;       not (a ##1 b);                           endproperty
    property p_and_or;    (a |-> b) and (b |-> c) or (c |-> a);    endproperty
    property p_if;        if (a) b else c;                         endproperty
    property p_if_only;   if (a) b;                                endproperty
    property p_case;      case (data) 0: a; 1: b; default: c; endcase endproperty
    property p_until;     a until b;                               endproperty
    property p_s_until;   a s_until b;                             endproperty
    property p_until_w;   a until_with b;                          endproperty
    property p_s_until_w; a s_until_with b;                        endproperty
    property p_nexttime;  nexttime a;                              endproperty
    property p_nexttime_n; nexttime [2] a;                         endproperty
    property p_s_nexttime; s_nexttime a;                           endproperty
    property p_s_nexttime_n; s_nexttime [2] a;                     endproperty
    property p_always;    always a;                                endproperty
    property p_always_r;  always [1:3] a;                          endproperty
    property p_s_always;  s_always [1:3] a;                        endproperty
    property p_eventually; eventually [1:3] a;                     endproperty
    property p_s_eventually; s_eventually a;                       endproperty
    property p_implies;   a implies b;                             endproperty
    property p_iff;       a iff b;                                 endproperty
    property p_accept;    accept_on (a) b;                         endproperty
    property p_reject;    reject_on (a) b;                         endproperty
    property p_sync_a;    sync_accept_on (a) b;                    endproperty
    property p_sync_r;    sync_reject_on (a) b;                    endproperty
    property p_disable;   disable iff (a) b |-> c;                 endproperty
    property p_args (logic x, logic y, property p);
        @(posedge clk) x |-> y ##1 p;
    endproperty
    property p_local;
        logic [3:0] v;
        (req, v = data) |=> ack ##0 (data == v);
    endproperty
    property p_instance; p_args(a, b, c);                          endproperty

    // assertion statements: every kind and action-block shape
    a_imm:   assert (a == b) else $error("immediate");
    a_def:   assert #0 (a) $display("pass"); else $display("fail");
    a_final: assert final (a) else $warning("final");
    a_obs:   assert (a) begin $display("pass"); end else begin $error("fail"); end
    ap_basic: assert property (p_impl) else $error("p_impl");
    ap_inline: assert property (@(posedge clk) disable iff (!rst_n) req |=> ack) $display("ok"); else $error("no");
    asm_a:   assume property (@(posedge clk) !(a && b));
    cov_a:   cover property (s_basic) $display("covered");
    cov_seq: cover sequence (s_range);
    cov_imm: cover (a && b);
    rst_a:   restrict property (@(posedge clk) a == 0);
    assert property (p_nonover);
    assume property (p_followed);
    cover property (p_not);

    // expect is a procedural statement
    initial begin
        expect (@(posedge clk) a ##1 b) else $error("expect");
    end

    // sampled value functions
    property p_sampled;
        $rose(a) |-> $fell(b) ##1 $stable(c) ##1 $changed(a) ##1 $past(b, 2) ##1 $sampled(c)
        ##1 $onehot(data) ##1 $onehot0(data) ##1 $isunknown(data) ##1 $countones(data) == 2;
    endproperty
    property p_gclk;
        $rising_gclk(a) |-> $falling_gclk(b) ##1 $steady_gclk(c) ##1 $changing_gclk(a) ##1 $future_gclk(b);
    endproperty
endmodule

// ── Checker ──
checker check_handshake (logic clk, req, ack, event e = $inferred_clock, logic rst = 1'b0);
    default clocking @(posedge clk); endclocking
    default disable iff rst;
    rand bit free_var;
    const bit k = 1'b1;
    a_ack: assert property (req |=> ack);
    c_req: cover property (req);
    always_ff @(posedge clk) begin
        if (free_var) $display("free");
    end
endchecker

module uses_checker (input logic clk, req, ack);
    check_handshake chk (clk, req, ack);
    check_handshake chk2 (.clk, .req, .ack);
endmodule

// ── Program, randsequence, process ──
program automatic test_prog;
    initial begin
        randsequence (main)
            main : first second third;
            first : add | dec := 3 | pop;
            second : repeat (3) add;
            third : { $display("custom"); } | if (1) add else dec;
            add : { $display("add"); };
            dec : { $display("dec"); };
            pop : case (2) 0: add; 1: dec; default: pop_one; endcase;
            pop_one : { $display("pop"); } ;
        endsequence
        randcase
            1: $display("one");
            3: $display("three");
        endcase
    end
    final $display("program done");
endprogram

// ── Configurations and libraries ──
config cfg_top;
    design work.top;
    localparam int MODE = 1;
    default liblist work lib_a;
    instance top.u1 use work.alt_impl;
    instance top.u2 liblist lib_b;
    cell work.leaf use lib_a.leaf_v2;
    cell lib_b.other liblist lib_a work;
endconfig

// ── Generate: every form ──
module generates #(parameter int N = 4, M = 2) (input logic [N-1:0] in, output logic [N-1:0] out);
    genvar i, j;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_loop
            assign out[i] = in[i];
            for (j = 0; j < M; j++) begin : g_inner
                wire w = in[i];
            end
        end
        if (N == 4) begin : g_if
            wire four = 1'b1;
        end else if (N == 8) begin : g_elseif
            wire eight = 1'b1;
        end else begin : g_else
            wire other = 1'b0;
        end
        case (N)
            2:       begin : g_two wire two = 1; end
            4, 8:    begin : g_four_eight wire x = 1; end
            default: begin : g_default end
        endcase
    endgenerate
    // generate without the keyword (allowed since SV-2005)
    for (genvar k = 0; k < 2; k++) begin : g_noparent
        initial $display("%0d", k);
    end
    if (M == 2) begin
        initial $display("two");
    end
    case (M)
        1: initial $display("one");
        default: ;
    endcase
    initial $display("%s", g_loop[0].g_inner[0].w);
endmodule

// ── Attributes, labels, and miscellany ──
(* keep = 1, mark_debug = "true", dont_touch *) module attributes;
    (* synthesis, parallel_case *) logic [3:0] state;
    (* full_case, parallel_case *) always_comb begin
        (* keep *) case (state) 0: ; default: ; endcase
    end
    initial begin : labelled_block
        automatic int local_auto = 1;
        static int local_static = 2;
        const int local_const = 3;
        $display("%0d %0d %0d", local_auto, local_static, local_const);
    end : labelled_block
endmodule : attributes

module with_timeunit;
    timeunit 1ns / 1ps;
    timeprecision 1ps;
    wire w;
    assign #(1.5:2.0:2.5) w = 1'b0;
    initial begin
        #(1:2:3) $display("min:typ:max delay");
        $printtimescale(with_timeunit);
    end
endmodule

`default_nettype wire
