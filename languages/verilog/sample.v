// ── Comments ───────────────────────────────────────────────
// Verilog-2001: a warehouse stock counter, FIFO and testbench.
// TODO: add parity checking. FIXME: reset polarity.
/* Block comment
   spanning lines */

// ── Compiler directives ────────────────────────────────────
`timescale 1ns / 1ps
`default_nettype none
`define MAX_COUNT 255
`define WIDTH 8
`define MAX(a, b) ((a) > (b) ? (a) : (b))
`define DEBUG
`include "defs.vh"
`ifdef DEBUG
`define LOG(msg) $display("[%0t] %s", $time, msg)
`else
`define LOG(msg)
`endif
`ifndef SIMULATION
`define SIMULATION 1
`elsif SYNTHESIS
`define SIMULATION 0
`endif
`undef DEBUG
`celldefine
`endcelldefine
`resetall

// ── User-defined primitive ─────────────────────────────────
primitive mux2 (out, sel, a, b);
    output out;
    input sel, a, b;
    table
        // sel a b : out
        0 1 ? : 1;
        0 0 ? : 0;
        1 ? 1 : 1;
        1 ? 0 : 0;
        x 0 0 : 0;
        x 1 1 : 1;
    endtable
endprimitive

// ── Parameterised counter ──────────────────────────────────
module counter #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] RESET_VALUE = {WIDTH{1'b0}}
) (
    input  wire             clk,
    input  wire             rst,
    input  wire             en,
    output reg  [WIDTH-1:0] count,
    output wire             wrapped
);
    localparam MAX = (1 << WIDTH) - 1;

    assign wrapped = (count == `MAX_COUNT);

    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= RESET_VALUE;
        else if (en)
            count <= count + 1'b1;
    end
endmodule

// ── Number literals and operators ──────────────────────────
module literals;
    reg  [7:0]  a, b;
    reg  signed [15:0] s;
    reg         flag;
    integer     i, j;
    real        r;
    realtime    rt;
    time        t;
    wire [3:0]  w;
    tri         bus;
    wand        wa;
    wor         wo;
    supply0     gnd;
    supply1     vdd;
    reg [7:0]   mem [0:255];
    genvar      g;
    event       done_evt;

    initial begin
        a = 8'hFF;
        a = 8'b1010_1010;
        a = 8'd255;
        a = 8'o377;
        a = 'hDEAD;
        a = 4'bx01z;
        a = 4'bXZ?0;
        s = -16'sd5;
        i = 42;
        i = 1_000_000;
        r = 3.14;
        r = 1.5e-3;
        r = 2E+10;
        rt = 1.5;

        // arithmetic, bitwise, logical, relational
        i = i + 1 - 2 * 3 / 4 % 5;
        i = 2 ** 8;
        a = ~a & b | a ^ b ~^ a ^~ b;
        a = a << 1;
        a = a >> 1;
        s = s <<< 1;
        s = s >>> 1;
        flag = !flag && (a > b) || (a < b) || (a >= b) || (a <= b);
        flag = (a == b) || (a != b) || (a === b) || (a !== b);
        flag = &a | ~&a | |a | ~|a | ^a | ~^a;
        a = flag ? a : b;
        a = {a[3:0], b[7:4]};
        a = {4{a[1:0]}};
        a = a[7:0];
        a = a[3 +: 4];
        a = a[7 -: 4];
        mem[0] = a;
        i = i;
    end
endmodule

// ── Functions, tasks, generate, gates ──────────────────────
module logic_blocks #(parameter N = 4) (
    input  wire [N-1:0] x,
    output reg  [N-1:0] y,
    output wire         parity
);
    function [N-1:0] reverse;
        input [N-1:0] in;
        integer k;
        begin
            for (k = 0; k < N; k = k + 1)
                reverse[k] = in[N-1-k];
        end
    endfunction

    function automatic integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    task automatic show;
        input [N-1:0] v;
        output [N-1:0] inverted;
        begin
            inverted = ~v;
            $display("value=%b inverted=%b", v, inverted);
        end
    endtask

    // gate primitives
    wire n1, n2, n3;
    and  g1 (n1, x[0], x[1]);
    or   g2 (n2, x[2], x[3]);
    nand g3 (n3, n1, n2);
    xor  #(2, 3) g4 (parity, n1, n2);
    not  g5 (n3, n1);
    buf  g6 (n2, n1);
    bufif1 g7 (n2, n1, x[0]);

    // generate
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : bit_loop
            wire inv = ~x[gi];
        end
        if (N > 2) begin : wide
            wire flag = 1'b1;
        end else begin : narrow
            wire flag = 1'b0;
        end
        case (N)
            4: begin : four
                wire f = 1'b1;
            end
            default: begin : other
                wire f = 1'b0;
            end
        endcase
    endgenerate

    // combinational always, case, casex, casez
    always @* begin
        case (x)
            4'b0000: y = 4'b1111;
            4'b0001, 4'b0010: y = 4'b0101;
            default: y = reverse(x);
        endcase
        casez (x)
            4'b1???: y = y;
            4'b01??: y = y;
            default: ;
        endcase
        casex (x)
            4'bxx01: y = y;
            default: ;
        endcase
    end

    always @(x or y) begin
        if (x == y) y = x; else y = ~x;
    end

    // attributes
    (* keep = "true" *) reg kept;
    (* synthesis, full_case, parallel_case *) wire attr_wire;

    // specify block
    specify
        specparam tRise = 1.2, tFall = 1.5;
        (x[0] => parity) = (tRise, tFall);
        (x *> y) = 2;
        $setup(x, posedge y[0], 3);
    endspecify

    defparam bit_loop[0].inv = 1;
endmodule

// ── Old-style (non-ANSI) ports, nets and strengths ─────────
module legacy_ports (a, b, y, bus, oe);
    input a, b;
    input [3:0] bus;
    input oe;
    output y;
    inout [7:0] io;
    reg y;

    parameter DELAY = 2;
    localparam [1:0] IDLE = 2'b00, RUN = 2'b01, DONE = 2'b10;

    trireg (small) charge_node;
    tri0 pull_down_net;
    tri1 pull_up_net;
    triand wand_net;
    trior wor_net;
    wire (strong1, weak0) strength_net = a & b;
    wire (highz1, pull0) hz_net = a | b;
    wire scalared [7:0] scalar_bus;
    wire vectored [7:0] vector_bus;
    wire #(1, 2, 3) delayed = a ^ b;
    supply1 power;

    pullup  (pu_net);
    pulldown (pd_net);
    nmos   n1 (n_out, a, oe);
    pmos   p1 (p_out, a, oe);
    cmos   c1 (c_out, a, oe, ~oe);
    tranif1 t1 (io[0], io[1], oe);
    tran   t2 (io[2], io[3]);
    rnmos  rn1 (rn_out, a, oe);
    notif0 nf0 (nf_out, a, oe);
    nor    nor1 (y_nor, a, b);
    xnor   xn1 (y_xnor, a, b);
    buf    #(2) bf (y_buf, a), bf2 (y_buf2, b);

    always @(a or b) begin
        y = #DELAY a & b;
        y <= #(DELAY) a | b;
    end

    always @(posedge a, negedge b) y <= 1'b1;
    always @(edge a) y <= 1'b0;
    always @(posedge a or negedge b or oe) y <= 1'b0;

    initial begin : named_block
        reg [3:0] local_reg;
        local_reg = 4'hF;
        assign y = a;
        deassign y;
        force y = 1'b1;
        release y;
        #(DELAY * 2) y = 1'bz;
        @(posedge a) y = 1'bx;
        wait (oe == 1'b1) y = 1'b0;
        repeat (3) @(negedge a);
        while (local_reg != 0) local_reg = local_reg - 1;
        for (local_reg = 0; local_reg < 4; local_reg = local_reg + 1) ;
        if (a) ; else y = 0;
        case (local_reg)
            IDLE, RUN: y = 1;
            DONE: begin y = 0; end
            default: ;
        endcase
        fork : par_block
            #5 y = 1;
            #10 y = 0;
        join
        disable named_block;
    end
endmodule

// ── System tasks, directives and misc ──────────────────────
`begin_keywords "1364-2001"
`end_keywords
`line 10 "sample.v" 0
`pragma protect begin_protected
`pragma protect end_protected
`unconnected_drive pull1
`nounconnected_drive

module system_calls;
    reg [31:0] value;
    reg [8*20:1] text;
    reg [63:0] big;
    real  r;
    integer file, code, seed;
    reg clk;

    initial begin
        $display("display with %d %h %o %b %c %s %t %e %f %g %m %%", 1, 2, 3, 4, 65, "s", $time, 1.5, 2.5, 3.5);
        $write("no newline");
        $strobe("strobe");
        $monitoron;
        $monitoroff;
        $sformat(text, "formatted %0d", 42);
        $swrite(text, "written ", 42);
        $fwrite(file, "to file");
        $fscanf(file, "%d", value);
        $sscanf("42", "%d", value);
        code = $fgetc(file);
        code = $feof(file);
        $fflush(file);
        $rewind(file);
        $fseek(file, 0, 0);
        $readmemb("bin.mem", system_calls.value);
        $writememh("out.mem", value);
        $random(seed);
        value = $urandom;
        value = $urandom_range(10, 0);
        value = $dist_uniform(seed, 0, 10);
        r = $itor(value) + $bitstoreal(big);
        big = $realtobits(r);
        value = $rtoi(r) + $signed(value) + $unsigned(value);
        r = $sqrt(2.0) + $ln(2.0) + $log10(100.0) + $exp(1.0) + $pow(2.0, 3.0) + $sin(1.0) + $cos(1.0) + $tan(1.0) + $asin(0.5) + $acos(0.5) + $atan(1.0) + $atan2(1.0, 2.0) + $hypot(3.0, 4.0) + $sinh(1.0) + $cosh(1.0) + $tanh(1.0) + $floor(1.5) + $ceil(1.5);
        value = $clog2(1024);
        value = $test$plusargs("verbose");
        value = $value$plusargs("seed=%d", seed);
        $timeformat(-9, 2, " ns", 10);
        $printtimescale(system_calls);
        $time;
        $stime;
        $realtime;
        $showvars;
        $showscopes;
        $reset;
        $save("checkpoint");
        $restart("checkpoint");
        $incsave("inc");
        $scope(system_calls);
        $input("script.cmd");
        $key("key.log");
        $nokey;
        $log("sim.log");
        $nolog;
        $dumpon;
        $dumpoff;
        $dumpall;
        $dumpflush;
        $dumplimit(1000000);
        $dumpports(system_calls, "ports.vcd");
        $finish(2);
        $stop(1);
        $fatal(1, "fatal message");
        $error("error message");
        $warning("warning message");
        $info("info message");
    end
endmodule

// ── Configurations and libraries ───────────────────────────
config cfg;
    design work.tb_counter;
    default liblist work;
    instance tb_counter.dut use work.counter;
    cell counter use work.counter;
endconfig

// ── Specify block with all path types ──────────────────────
module specify_demo (input a, b, c, output y, z);
    specify
        specparam t_rise = 1:2:3, t_fall = 2:3:4;
        if (c) (a => y) = (t_rise, t_fall);
        ifnone (a => y) = 5;
        (posedge a => (y +: b)) = 2;
        (negedge b *> z) = (1, 2, 3);
        (a, b *> y, z) = 4;
        $setuphold(posedge a, b, 1, 2);
        $hold(posedge a, b, 1);
        $recovery(posedge a, b, 1);
        $removal(posedge a, b, 1);
        $skew(posedge a, posedge b, 1);
        $width(posedge a, 2);
        $period(posedge a, 10);
        $nochange(posedge a, b, 0, 0);
        pulsestyle_onevent y;
        pulsestyle_ondetect z;
        showcancelled y;
        noshowcancelled z;
    endspecify
    assign y = a & b;
    assign z = a | b;
endmodule

// ── Testbench ──────────────────────────────────────────────
module tb_counter;
    reg clk = 0, rst = 1, en = 0;
    wire [7:0] count;
    wire wrapped;
    integer fd;
    reg [8*12:1] label;
    reg [7:0] data [0:3];
    event done_evt;

    counter #(.WIDTH(8)) dut (.clk(clk), .rst(rst), .en(en), .count(count), .wrapped(wrapped));

    always #5 clk = ~clk;

    initial begin
        label = "Hello, world";
        $display("Label: %s \"quoted\" \\ backslash %% percent \t tab \n", label);
        $dumpfile("counter.vcd");
        $dumpvars(0, tb_counter);
        $monitor("t=%0t count=%0d wrapped=%b", $time, count, wrapped);
        $readmemh("init.hex", data);
        fd = $fopen("log.txt", "w");
        $fdisplay(fd, "start %d", $random);
        #12 rst = 0; en = 1;
        repeat (4) @(posedge clk);
        wait (wrapped);
        @(negedge clk);
        forever begin
            #100;
            if ($time > 3000) disable stop_block;
        end
    end

    initial begin : stop_block
        #2600 $display("count=%0d wrapped=%b", count, wrapped);
        fork
            #10 $display("branch a");
            #20 $display("branch b");
        join
        force dut.count = 8'h00;
        release dut.count;
        $fclose(fd);
        $stop;
        $finish;
    end

    initial begin
        while (!wrapped) begin
            @(posedge clk);
        end
        `LOG("wrapped");
        -> done_evt;
    end

    always @(done_evt) $display("done at %t", $realtime);
endmodule

`default_nettype wire
