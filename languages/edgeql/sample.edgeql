# ── Comments ──
# Line comment. TODO: add access policies. FIXME: backfill the migration.

# ── Module, scalar types, aliases ──
module default {
    scalar type Sku extending str {
        constraint regexp(r'^[A-Z]-[0-9]{3}$');
        constraint min_len_value(5);
    }

    scalar type Quantity extending int32 {
        constraint min_value(0);
    }

    scalar type Money extending decimal;

    scalar type Priority extending sequence;

    scalar type Category extending enum<Tools, Fasteners, Safety, Bulk>;

    abstract constraint positive {
        using (__subject__ > 0);
        errmessage := 'must be positive';
    }

    function discounted(price: Money, pct: float64 = 10.0) -> Money
        using (price * <Money>(1 - pct / 100));

    function stock_label(qty: int32) -> str {
        using (
            'out' if qty = 0 else
            'low' if qty < 5 else
            'ok'
        );
    }

    # ── Abstract types and mixins ──
    abstract type Auditable {
        created := datetime_of_statement();
        updated: datetime {
            default := datetime_current();
            readonly := false;
            rewrite insert, update using (datetime_of_statement());
        }
    }

    abstract annotation display_name;

    # ── Object types ──
    type Supplier extending Auditable {
        required name: str {
            constraint exclusive;
            annotation title := 'Supplier name';
        }
        contact: tuple<email: str, phone: str>;
        rating: float32;
        multi items := .<supplier[is Item];
    }

    type Bin {
        required code: str { constraint exclusive; }
        capacity: Quantity { default := 500; }
        index on (.code);
    }

    type Item extending Auditable {
        required sku: Sku { constraint exclusive; }
        required name: str;
        qty: Quantity { default := 0; }
        price: Money;
        category: Category;
        tags: array<str>;
        dimensions: tuple<w: float64, h: float64, d: float64>;
        notes: str;
        required supplier: Supplier {
            on target delete restrict;
        }
        multi bins: Bin {
            quantity: int32;
            on source delete allow;
        }
        single link primary_bin -> Bin;
        property total := .qty * .price;
        property label := .name ++ ' (' ++ <str>.qty ++ ')';
        constraint exclusive on ((.sku, .supplier));
        index on (.sku);
        index fts::index on (fts::with_options(.name, language := fts::Language.eng));
        trigger log_change after update for each do (
            insert AuditLog { item := __new__, at := datetime_current() }
        );
        access policy everyone_read allow select;
        access policy owner_write allow insert, update write using (global current_user_id ?= .supplier.id);
    }

    type AuditLog {
        required item: Item;
        required at: datetime;
    }

    global current_user_id: uuid;

    alias LowStock := (select Item filter .qty < 5);
}

# ── Migrations ──
start migration to {
    module default {
        type Temp { name: str; }
    }
};
populate migration;
commit migration;

create type Temp2 { create property name -> str; };
alter type Temp2 { create property count -> int64; };
drop type Temp2;
create database inventory;
configure current database set query_execution_timeout := <duration>'30 seconds';

# ── Inserts ──
insert Supplier { name := 'Acme Tools', rating := 4.5 };

insert Item {
    sku := 'A-100',
    name := 'Claw hammer',
    qty := 42,
    price := <Money>12.50n,
    category := Category.Tools,
    tags := ['steel', 'hand tool'],
    dimensions := (w := 30.0, h := 12.5, d := 3.0),
    supplier := (select Supplier filter .name = 'Acme Tools'),
    bins := (insert Bin { code := 'B-07' }),
    notes := 'quoted "string" with \'escapes\' and \n newline',
}
unless conflict on .sku else (select Item);

with new_bin := (insert Bin { code := 'B-08' })
insert Item { sku := 'A-101', name := 'Bolt', bins := new_bin, supplier := (select Supplier limit 1) };

# ── Selects ──
select Item {
    sku,
    name,
    total,
    label,
    supplier: { name, rating },
    bins: { code, @quantity },
    project_count := count(.bins),
    big := (select .bins filter .capacity > 100) { code },
    tag_count := len(.tags),
    first_tag := .tags[0],
    last_tag := .tags[-1],
    slice := .tags[0:2],
    w := .dimensions.w,
    all_dims := .dimensions.0,
}
filter .qty > 10 and not exists .notes and .category in {Category.Tools, Category.Safety}
    or .name ilike '%hammer%' or .sku like 'A-%' or .name ?= <str>{}
order by .name asc empty last then .qty desc
offset 5
limit 10;

select Item filter .id = <uuid>$id;
select Item filter .sku = <str>$sku and .qty >= <optional int32>$min_qty ?? 0;
select Item { name } filter .supplier.name = 'Acme Tools' and exists .bins;
select Item.name union Supplier.name;
select (Item, Bin) filter .0.qty > .1.capacity;
select distinct Item.category;

# ── Sets, operators, expressions ──
select {
    arithmetic := (1 + 2) * 3 - 4 / 2 // 3 % 2 ^ 2,
    concat := 'a' ++ 'b',
    compare := 1 < 2 and 2 <= 3 or 3 > 2 and 3 >= 2 and 1 != 2 and 1 = 1,
    optional_eq := 1 ?!= <int64>{},
    coalesce := <str>{} ?? 'default',
    ternary := 'yes' if true else 'no',
    in_set := 1 in {1, 2, 3},
    not_in := 1 not in {4, 5},
    cast := <int64>'42' + <float64>'1.5',
    typed_empty := <array<int64>>[],
    array := [1, 2, 3],
    array_idx := [1, 2, 3][1],
    tuple := (1, 'two', 3.0),
    named_tuple := (a := 1, b := 'two'),
    json := to_json('{"sku": "A-100"}'),
    json_get := to_json('{"a": 1}')['a'],
    type_intersect := (select Item[is Item]),
    detached := (select detached Item limit 1),
    uuid_lit := <uuid>'00000000-0000-0000-0000-000000000000',
    datetime := <datetime>'2026-03-01T08:30:00Z',
    local := <cal::local_date>'2026-03-01',
    dur := <duration>'1 hour 30 minutes',
    rel := <cal::relative_duration>'P1Y2M',
    bytes := b'bytes\x00\xff',
    big := 1_000_000n,
    hexish := 0xFF,
    float := 6.02e23,
    neg := -1.5e-10,
    bool := true and not false,
    emptyset := <int64>{},
    raw := r'raw \n string',
    dollar := $$dollar quoted$$,
    named := $tag$tagged dollar quote$tag$,
    backtick := `reserved word`.field,
    enum_val := Category.Tools,
    func := str_upper('stock'),
    agg := sum({1, 2, 3}) + count(Item) + max({1, 2}) + array_agg(Item.sku)[0],
    std := std::len('abc'),
    module_fn := default::discounted(<Money>10),
};

# ── Updates, deletes, for, with ──
update Item filter .sku = 'A-100' set { qty := .qty + 10, tags += ['new'], bins -= (select Bin filter .code = 'B-08') };
update Item filter .qty = 0 set { notes := {} };
delete Item filter .qty = 0 and .updated < datetime_current() - <duration>'365 days';

for item in (select Item filter .qty < 5) union (
    update item set { notes := 'reorder' }
);

for x in {1, 2, 3} union (insert Bin { code := 'B-' ++ <str>x });

with
    module default,
    threshold := 5,
    low := (select Item filter .qty < threshold)
select low { sku, qty } order by .qty;

group Item { name, qty }
using category := .category
by category;

select Item { name } filter .id in array_unpack(<array<uuid>>$ids);

# ── Transactions ──
start transaction;
rollback;
declare savepoint sp1;
release savepoint sp1;
commit;
analyze select Item;
describe type Item as sdl;
explain select Item;

# ── Further constructs ──
# SDL features
type Mixed extending Auditable, Bin {
    overloaded required property code -> str;
    overloaded link supplier extending Supplier;
    required multi link neighbours -> Bin {
        constraint exclusive;
        on target delete delete source;
        default := (select Bin limit 1);
    }
    property computed := count(.neighbours) using (count(.neighbours));
    readonly: bool { readonly := true; }
    deferred_unique: int32 {
        constraint exclusive;
        constraint expression on (__subject__ > 0) except (.readonly);
    }
    annotation title := 'Mixed';
    annotation description := 'Mixed type for highlighting';
    constraint expression on (.code != '');
    access policy deny_all deny all;
    access policy allow_own allow all using (.owner ?= global current_user) {
        errmessage := 'forbidden';
        using (true);
    }
}

abstract link friendship { property since: datetime; }
abstract property tag_prop { annotation title := 'tag'; }
scalar type short_str extending str { constraint max_len_value(8); }
scalar type seq_num extending sequence;
abstract scalar type base_scalar extending int64;
type Tuple_holder { pair: tuple<int64, str>; named: tuple<a: int64, b: str>; arr: array<tuple<int32, str>>; rng: range<int64>; mrng: multirange<int64>; }
extension pgvector version '0.5';
using extension graphql;
future simple_scoping;
global current_user -> uuid;
global is_admin := (select exists (select User filter .id = global current_user and .admin));
function add(a: int64, b: int64 = 0) -> int64 using (a + b);
function double_all(variadic xs: int64) -> set of int64 using (xs * 2);
function with_sql(x: int32) -> int32 using sql $$ SELECT x + 1 $$;
function with_sql_fn(x: int32) -> int32 { using sql function 'my_fn'; }
function opt_param(named only n: optional str) -> str using (n ?? 'none');
function volatile_fn() -> int64 { volatility := 'Volatile'; using (random()); }
function with_annotation() -> str { annotation title := 'annot'; using ('x'); }
abstract constraint max_two on (len(<str>__subject__)) { using (__subject__ <= 2); }
scalar type Ordered extending int32 { constraint expression on (__subject__ > 0) { errmessage := 'positive'; } }
abstract inheritable annotation display_hint;
inheritable annotation hint := 'x';
index on (.code) except (.readonly);
type WithIdx { name: str; index pg::btree on (.name); index pg::gin on (.name); index pg::spgist on (.name); index pg::brin on (.name); index fts::index on (fts::with_options(.name, language := fts::Language.eng, weight_category := fts::Weight.A)); index ext::pgvector::ivfflat_euclidean(lists := 100) on (.embedding); }
migration m1ab2cd { create type Gen { create property v -> int64; }; };
migration m1ab2cd onto m0xyz { alter type Gen { drop property v; }; };

# DDL
create module scratch if not exists;
drop module scratch;
create scalar type tmp_scalar extending str;
create abstract type tmp_abs;
create type tmp { create required property p -> str { create constraint exclusive; }; create index on (.p); };
alter type tmp { rename to tmp2; alter property p { set required := false; set default := 'x'; reset default; create annotation title := 't'; drop constraint exclusive; set type int64 using (<int64>.p); }; extending Auditable first; drop extending Auditable; create link l -> tmp2; create multi property m -> str; };
drop type tmp2;
create function tmp_fn() -> str using ('x');
alter function tmp_fn() { rename to tmp_fn2; set volatility := 'Immutable'; };
drop function tmp_fn2();
create alias tmp_alias := (select Item);
create global tmp_global -> str;
create role app_role { set password := 'example-not-a-real-password'; set superuser := false; set permissions := {}; };
configure instance set listen_port := 5656;
configure session set allow_user_specified_id := true;
configure current database insert cfg::Auth { priority := 1, method := (insert cfg::SCRAM {}) };
configure current database reset query_execution_timeout;
reset module;
set module default;
set alias trial as module default;
describe schema as sdl;
describe module default as ddl;
describe type Item as text verbose;
administer statistics_update(Item);
administer vacuum();
create branch dev from main;
drop branch dev;
rollback to savepoint sp1;
start transaction isolation serializable, read only, deferrable;
start transaction isolation repeatable read, read write;

# Edge-case expressions
select (select Item limit 1).name ?? '<none>';
select assert_single((select Item filter .sku = 'A-100'));
select assert_exists((select Item limit 1));
select assert_distinct({1, 2});
select assert(true, message := 'msg');
select enumerate({'a', 'b'});
select array_get([1, 2], 5, default := 0);
select re_match(r'a(b)', 'ab');
select str_split('a,b', ',');
select to_str(<datetime>'2026-03-01T00:00:00Z', 'YYYY-MM-DD');
select to_datetime(2026, 3, 1, 0, 0, 0, 'UTC');
select <cal::local_datetime>'2026-03-01T08:30:00';
select <cal::local_time>'08:30:00';
select <cal::date_duration>'1 month';
select <bigint>12345678901234567890n;
select <decimal>1.5n;
select <bytes>b'\x00';
select <range<int64>>range(1, 10);
select range_unpack(range(1, 5));
select <array<json>>[];
select 1 if true else 2;
select len('abc') + len([1, 2]);
select [1, 2, 3][1:];
select [1, 2, 3][:-1];
select 'abc'[1:2];
select 'A\x41\'"';
select 'multi
line';
select ([1, 2], 'x').0;
select exists {} or not exists {1};
select {1, 2} union {3} except {1} intersect {2, 3};
select distinct {1, 1, 2};
select Item.name limit 1 offset 0;
select (for x in {1, 2} union (x * 2));
select (with x := 1 select x + 1);
select (insert Bin { code := 'tmp' }) { code };
select introspect Item { name, properties: { name } };
select schema::ObjectType { name } filter .name = 'default::Item';
select sys::get_version();
select cfg::Config.query_execution_timeout;
select ext::auth::Identity;
select std::datetime_current();
select math::ln(2.718);
select Item filter .category = <Category>'Tools';
select Item filter 'steel' in .tags;
select Item filter .dimensions.w > 1.0 and .tags[0] = 'a';
select Item order by .name desc empty first;
select Item { name, @quantity := 5 };
select Item.<supplier[is Supplier];
select Item.supplier.items.name;
select <str>Item.id;
select <Item>$id;
select <optional Item>$maybe;
select Item { ** };
select Item { * };
select Item { name, ** } limit 1;
