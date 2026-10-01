-- ── Comments ───────────────────────────────────────────────
-- VHDL-2008: a warehouse stock counter, a package and a testbench.
-- TODO: add parity checking. FIXME: reset polarity.
/* VHDL-2008 delimited
   comment spanning lines */

-- ── Libraries and contexts ─────────────────────────────────
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;
use work.warehouse_pkg.all;

-- ── Package ────────────────────────────────────────────────
package warehouse_pkg is
    constant REORDER_POINT : natural := 25;
    constant APP_NAME      : string  := "Warehouse";
    constant RATIO         : real    := 0.75;
    constant BIG           : integer := 1_000_000;
    constant HEX           : integer := 16#FF#;
    constant BIN           : integer := 2#1010_1010#;
    constant EXPONENT      : real    := 1.5e-3;
    constant BASED_REAL    : real    := 16#F.8#E1;
    constant TIMEOUT       : time    := 10 ns;
    constant LONG_WAIT     : time    := 1.5 ms;

    type status_t is (pending, paid, cancelled);
    type item_t is record
        sku   : string(1 to 7);
        qty   : natural range 0 to 9999;
        price : real;
        state : status_t;
    end record item_t;
    type item_array_t is array (natural range <>) of item_t;
    type matrix_t is array (0 to 3, 0 to 3) of integer;
    type byte_t is range 0 to 255;
    type word_vector is array (natural range <>) of std_logic_vector(15 downto 0);
    type mem_t is array (0 to 255) of std_logic_vector(7 downto 0);
    subtype small_t is integer range 0 to 15;
    subtype nibble_t is std_logic_vector(3 downto 0);
    type ptr_t is access item_t;
    type file_t is file of integer;
    type unit_t is range 0 to 1000000
        units
            mm;
            cm = 10 mm;
            m  = 100 cm;
        end units;

    function clog2 (n : positive) return natural;
    function "+" (a, b : item_t) return item_t;
    procedure show (v : in std_logic_vector; signal done : out boolean);
    component counter is
        generic (WIDTH : positive := 8);
        port (clk, rst, en : in std_logic;
              count : out unsigned(WIDTH - 1 downto 0));
    end component counter;
    attribute keep : boolean;
    alias word_alias : std_logic_vector(15 downto 0) is word_vector(0);
end package warehouse_pkg;

package body warehouse_pkg is
    function clog2 (n : positive) return natural is
        variable v : natural := n - 1;
        variable r : natural := 0;
    begin
        while v > 0 loop
            v := v / 2;
            r := r + 1;
        end loop;
        return r;
    end function clog2;

    function "+" (a, b : item_t) return item_t is
        variable r : item_t := a;
    begin
        r.qty := a.qty + b.qty;
        return r;
    end function "+";

    procedure show (v : in std_logic_vector; signal done : out boolean) is
        variable l : line;
    begin
        write(l, string'("value="));
        write(l, to_integer(unsigned(v)));
        writeline(output, l);
        done <= true;
    end procedure show;
end package body warehouse_pkg;

-- ── Entity ─────────────────────────────────────────────────
entity counter is
    generic (
        WIDTH : positive := 8;
        INIT  : natural  := 0
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        en      : in  std_logic;
        load    : in  std_logic_vector(WIDTH - 1 downto 0);
        count   : out unsigned(WIDTH - 1 downto 0);
        wrapped : out std_logic;
        bus_io  : inout std_logic_vector(7 downto 0);
        buf_o   : buffer std_logic
    );
end entity counter;

-- ── Architecture ───────────────────────────────────────────
architecture rtl of counter is
    signal q       : unsigned(WIDTH - 1 downto 0) := (others => '0');
    signal next_q  : unsigned(WIDTH - 1 downto 0);
    signal state   : status_t := pending;
    signal flags   : std_logic_vector(3 downto 0) := "0000";
    signal chars   : string(1 to 5) := "hello";
    signal tick    : boolean := false;
    shared variable shared_count : integer := 0;
    constant ZERO  : unsigned(WIDTH - 1 downto 0) := (others => '0');
    constant OCT   : bit_vector(8 downto 0) := O"777";
    constant HEXV  : std_logic_vector(7 downto 0) := X"DE";
    constant BINV  : std_logic_vector(7 downto 0) := B"1010_1010";
    constant CH    : character := 'A';
    constant ESC   : string := "double ""quoted"" string";
    constant NL    : string := "line" & LF & "break" & CR;
    constant ONE   : std_logic := '1';
    constant Z     : std_logic := 'Z';
    constant DC    : std_logic := '-';
    constant U     : std_logic := 'U';
    constant X     : std_logic := 'X';
    attribute keep of q : signal is true;
    attribute syn_encoding : string;
    attribute syn_encoding of state : signal is "onehot";

    component helper is
        port (a : in std_logic; b : out std_logic);
    end component;
begin
    count   <= q;
    wrapped <= '1' when q = (q'range => '1') else '0';

    -- concurrent assignments
    buf_o <= '1' when en = '1' and rst = '0' else
             '0' when rst = '1' or en = 'X' else
             'Z';

    with flags select
        bus_io(0) <= '1' when "0001",
                     '0' when "0010" | "0100",
                     'Z' when others;

    next_q <= q + 1 after 1 ns;
    tick   <= transport true after 5 ns;
    flags  <= reject 1 ns inertial "1010" after 3 ns;

    -- sequential process
    seq : process (clk, rst) is
        variable v : integer range 0 to 255 := 0;
        variable item : item_t;
    begin
        if rst = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                q <= q + 1;
            elsif en = '0' and load /= (load'range => '0') then
                q <= unsigned(load);
            end if;
        end if;
        if falling_edge(clk) then
            null;
        end if;
        case state is
            when pending   => state <= paid;
            when paid      => state <= cancelled;
            when cancelled => state <= pending;
        end case;
        for i in 0 to 3 loop
            next when i = 1;
            exit when i = 3;
            v := v + i;
        end loop;
        for i in flags'reverse_range loop
            flags(i) <= not flags(i);
        end loop;
        while v > 0 loop
            v := v - 1;
        end loop;
        loop
            exit;
        end loop;
        assert v >= 0 report "v must not be negative" severity warning;
        report "count=" & integer'image(to_integer(q)) severity note;
        assert false report "failure" severity failure;
    end process seq;

    comb : process (all) is
    begin
        flags <= std_logic_vector(q(3 downto 0));
    end process comb;

    sensitivity : process
    begin
        wait until rising_edge(clk);
        wait for 10 ns;
        wait on clk;
        wait;
    end process sensitivity;

    -- generate
    gen_bits : for i in 0 to 3 generate
        signal t : std_logic;
    begin
        t <= flags(i);
    end generate gen_bits;

    gen_if : if WIDTH > 4 generate
        flags(0) <= '1';
    end generate gen_if;

    gen_case : case WIDTH generate
        when 8 => flags(1) <= '1';
        when others => flags(1) <= '0';
    end generate gen_case;

    -- instantiation
    u1 : helper port map (a => clk, b => open);
    u2 : entity work.counter(rtl)
        generic map (WIDTH => 4)
        port map (clk => clk, rst => rst, en => en, load => load(3 downto 0), count => open, wrapped => open, bus_io => open, buf_o => open);
    u3 : component helper port map (clk, open);

    -- block and guarded signal
    blk : block (en = '1') is
        signal g : std_logic;
    begin
        g <= guarded '1';
    end block blk;
end architecture rtl;

-- ── Configuration ──────────────────────────────────────────
configuration cfg_counter of counter is
    for rtl
        for u1 : helper
            use entity work.helper(behav);
        end for;
    end for;
end configuration cfg_counter;

-- ── Testbench with operators and attributes ────────────────
entity tb_counter is
end entity tb_counter;

architecture sim of tb_counter is
    signal clk, rst, en : std_logic := '0';
    signal count : unsigned(7 downto 0);
    signal wrapped : std_logic;
    signal load : std_logic_vector(7 downto 0) := (others => '0');
    signal bus_io : std_logic_vector(7 downto 0);
    signal buf_o : std_logic;
    signal done : boolean := false;
begin
    dut : entity work.counter
        generic map (WIDTH => 8)
        port map (clk, rst, en, load, count, wrapped, bus_io, buf_o);

    clk <= not clk after 5 ns when not done else '0';

    stimulus : process
        variable a, b : integer := 0;
        variable l : line;
        file f : text open write_mode is "log.txt";
    begin
        rst <= '1';
        wait for 12 ns;
        rst <= '0';
        en  <= '1';
        wait for 2600 ns;
        a := 7 + 3 - 2 * 4 / 2;
        a := a mod 3;
        a := a rem 3;
        a := abs(a) ** 2;
        a := -a;
        b := (a + 1) / 2;
        assert (a = b) or (a /= b) or (a < b) or (a <= b) or (a > b) or (a >= b);
        assert (a = b) and (a = b) nand (a = b) nor (a = b) xor (a = b) xnor (a = b);
        assert ?? (clk = '1');
        assert clk ?= '1' and clk ?/= '0' and clk ?< '1';
        assert std_logic_vector'("0101") sll 1 = "1010";
        assert std_logic_vector'("0101") srl 1 = "0010";
        assert std_logic_vector'("0101") rol 1 = "1010";
        assert std_logic_vector'("0101") ror 1 = "1010";
        write(l, string'("done: ") & to_string(count));
        writeline(f, l);
        report "image: " & integer'image(a) & time'image(now) & clk'image;
        report "attrs: " & integer'image(count'length) & integer'image(count'high) & integer'image(count'low) & boolean'image(clk'event) & boolean'image(clk'stable);
        done <= true;
        wait;
    end process stimulus;

    finish_proc : process
    begin
        wait until done;
        std.env.finish;
    end process finish_proc;
end architecture sim;

-- ── Context clauses, protected types, access types ─────────
context warehouse_ctx is
    library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
end context warehouse_ctx;

library ieee;
context work.warehouse_ctx;
use ieee.std_logic_textio.all;

package counter_types is
    type counter_t is protected
        procedure increment (by : in integer := 1);
        impure function value return integer;
    end protected counter_t;

    type int_ptr is access integer;
    type str_ptr is access string;
    type list_node;
    type list_ptr is access list_node;
    type list_node is record
        data : integer;
        next_node : list_ptr;
    end record;

    type fixed_array is array (1 to 4) of integer;
    type bool_vec is array (natural range <>) of boolean;
    type real_arr is array (0 to 1) of real;
    type enum_t is (idle, 'A', 'B', running, stopped);
    attribute max_delay : time;
    attribute max_delay of enum_t : type is 10 ns;
    group pair is (signal, signal);
    group sig_pair : pair (a, b);
end package counter_types;

package body counter_types is
    type counter_t is protected body
        variable count : integer := 0;
        procedure increment (by : in integer := 1) is
        begin
            count := count + by;
        end procedure increment;
        impure function value return integer is
        begin
            return count;
        end function value;
    end protected body counter_t;
end package body counter_types;

-- ── Generic packages and subprogram generics ───────────────
package generic_stack is
    generic (type element_t; size : positive := 16;
             function to_str (e : element_t) return string);
    procedure push (e : element_t);
end package generic_stack;

package int_stack is new work.generic_stack
    generic map (element_t => integer, size => 8, to_str => integer'image);

entity generic_entity is
    generic (type data_t; constant WIDTH : natural := 8; function resolve (a, b : data_t) return data_t);
    port (d : in data_t; q : out data_t);
end entity generic_entity;

-- ── Subprograms: pure, impure, postponed, external names ───
architecture behav of generic_entity is
    pure function max2 (a, b : integer) return integer is
    begin
        if a > b then return a; else return b; end if;
    end function max2;

    impure function next_id return natural is
        variable id : natural := 0;
    begin
        id := id + 1;
        return id;
    end function next_id;

    procedure swap (signal a, b : inout std_logic; variable t : inout std_logic) is
    begin
        t := a; a <= b; b <= t;
    end procedure swap;

    function "&" (l : integer; r : string) return string is
    begin
        return integer'image(l) & r;
    end function "&";

    signal ext : std_logic;
    alias ext_alias : std_logic is << signal .tb_counter.dut.q : std_logic >>;
    type int_ptr_t is access integer;
    shared variable counter : work.counter_types.counter_t;
begin
    postponed assert true report "postponed concurrent assertion";
    postponed process
    begin
        wait;
    end postponed process;

    q <= d;

    force_proc : process
        variable p : int_ptr_t;
        variable s : string(1 to 5);
        variable b : bit_vector(3 downto 0) := x"A";
        variable t : time;
        variable r : real;
        variable l : line;
        file f : text;
    begin
        p := new integer'(42);
        deallocate(p);
        <<signal .tb_counter.dut.q : unsigned(7 downto 0)>> <= force to_unsigned(3, 8);
        <<signal .tb_counter.dut.q : unsigned(7 downto 0)>> <= release;
        file_open(f, "data.txt", read_mode);
        while not endfile(f) loop
            readline(f, l);
            read(l, r);
        end loop;
        file_close(f);
        t := 5 ns + 10 us - 2 ps * 3 + 1 sec / 2 + 1 min + 1 hr + 2 fs;
        r := real(5) * 2.5 + math_pi + MATH_E;
        s := "hello";
        report to_string(t) & to_hstring(b) & to_ostring(b) & to_bstring(b) & s severity note;
        assert b'length = 4 and b'left = 3 and b'right = 0 and b'ascending = false report "attrs";
        assert enum_t'pos(idle) = 0 and enum_t'succ(idle) = 'A' and enum_t'pred('A') = idle and enum_t'val(0) = idle and enum_t'leftof('A') = idle and enum_t'rightof(idle) = 'A' report "enum";
        assert enum_t'base'left = idle and integer'high > integer'low report "base";
        assert clk'last_event > 0 ns and clk'last_value = '0' and clk'delayed(1 ns) = '1' and clk'active and clk'transaction = '1' and clk'quiet(1 ns) report "signal attrs";
        assert process_name'path_name = "" and process_name'instance_name = "" and process_name'simple_name = "" report "names";
        wait for 1 ns;
        wait on clk until rising_edge(clk) for 10 ns;
        wait;
    end process force_proc;
end architecture behav;

-- ── Guarded signals, registers, buses, disconnection ───────
entity guarded_demo is
end entity guarded_demo;

architecture arch of guarded_demo is
    signal data : std_logic bus;
    signal reg1 : std_logic register;
    signal sel : boolean;
    disconnect data : std_logic after 5 ns;
begin
    b1 : block (sel) is
    begin
        data <= guarded '1' after 1 ns;
        reg1 <= guarded unaffected;
    end block b1;
end architecture arch;

-- ── Attribute specs, PSL and VHDL-2019 interfaces ──────────
vunit check_counter (counter(rtl)) {
    default clock is rising_edge(clk);
    property never_overflows is always (en -> next (count /= (count'range => '1')));
    assert never_overflows;
    sequence reset_seq is {rst; not rst};
    assume always rst -> next not rst;
    cover {rst; not rst};
}

-- psl assert always (rst -> next (count = 0)) @ rising_edge(clk);

package ifc_pkg is
    type bus_if is record
        valid : std_logic;
        data  : std_logic_vector(7 downto 0);
    end record bus_if;
    view master_view of bus_if is
        valid : out;
        data  : out;
    end view master_view;
    alias slave_view is master_view'converse;
end package ifc_pkg;
