% MATLAB R2025b — syntax showcase: warehouse inventory analysis (no MATLAB or Octave installed here; written against the language reference). This file DETECTS AS OBJECTIVE-C (.m is shared) —
% pick MATLAB from the language picker.
%% ── Section break (cell mode) ──
% Line comment. TODO: vectorise the loop. FIXME: handle NaN prices.
%{
Block comment
spanning lines
%}
%% Constants and numbers
REORDER_POINT = 25;
integer = 42; negative = -17; float = 3.14159; exponent = 6.022e23; small = 1E-9;
hexNum = 0xFF; binNum = 0b1010; unsigned8 = uint8(200); int16v = int16(-5);
complexNum = 3 + 4i; complexJ = 2.5e3j;
specials = [Inf, -Inf, NaN, pi, eps, realmax, realmin, intmax('int32')];
flags = [true, false];
emptyArr = [];

%% Strings
single = 'It''s a ''pallet'' with %d format';
double = "Tab\t newline\n quote "" backslash \\ unicode: Zürich → 東京 ✓";
concat = ['SKU-' num2str(100) '-A'];
strArr = ["alpha", "beta"; "gamma", "delta"];
charMat = ['abc'; 'def'];
fmt = sprintf('%5.2f|%-8s|%d|%e|%x\n', 3.14159, 'ab', 42, 1000, 255);

%% Matrices, ranges, indexing
v = [1, 2, 3, 4];
col = [1; 2; 3];
M = [1 2 3; 4 5 6; 7 8 9];
range = 1:2:10;
down = 10:-3:0;
lin = linspace(0, 1, 5);
sub = M(2:end, [1 3]);
lastRow = M(end, :);
logicalIdx = v(v > 2 & v < 4);
M(2, :) = [];
M(:, end+1) = [10; 11; 12];
transposed = M';
dotT = M.';
cellArr = {1, 'two', [3 4 5]; {6}, @sin, true};
firstCell = cellArr{1, 2};
structArr = struct('sku', {'A-100', 'B-200'}, 'qty', {5, 0});
s.sku = 'A-100'; s.qty = 5; s.tags = {'small', 'fast'};
dyn = s.('sku');

%% Operators
a = 7; b = 3;
arith = a + b - a * b / 2 ^ 2;
elementwise = v .* v ./ 2 .^ 2;
leftDiv = M \ [1; 2; 3];
cmp = (a < b) || (a >= b) && (a ~= b) | (a == b) & ~(a > b);
shortCircuit = xor(true, false) && any(v) || all(v);
incr = a; incr = incr + 1; incr = incr - 1; incr = incr * 2; incr = incr / 2;
transposeOps = v' * v;
ternary = ifelse(a > b, 'greater', 'not greater');

%% Control flow
if a > b
    disp('greater');
elseif a == b
    disp('equal');
else
    disp('less');
end

for i = 1:3
    if i == 2, continue; end
    fprintf('i = %d\n', i);
end

for k = [10 20 30]
    if k > 20, break, end
end

n = 0;
while n < 3
    n = n + 1;
end

switch lower('Paid')
    case {'paid', 'settled'}
        status = 1;
    case 'pending'
        status = 2;
    otherwise
        status = 0;
end

try
    error('Warehouse:negativeStock', 'Negative stock for %s', 'A-100');
catch ME
    fprintf('%s: %s\n', ME.identifier, ME.message);
    rethrow(ME);
end

parfor idx = 1:4
    squares(idx) = idx^2;
end

%% Tables and data
orders = table([1; 2; 3; 4], [120.5; 42; 0; 88.25], categorical({'paid'; 'pending'; 'cancelled'; 'paid'}), ...
    'VariableNames', {'number', 'total', 'status'});
paid = orders(orders.status == 'paid', :);
revenue = sum(paid.total);
fprintf('%d paid orders, revenue %.2f\n', height(paid), revenue);
byStatus = groupsummary(orders, 'status', 'sum', 'total');
disp(byStatus);
dt = datetime(2026, 1, 31, 12, 0, 0);
fh = @(x, y) x.^2 + y;
mapped = arrayfun(@(x) x * 2, v);
cellMapped = cellfun(@numel, {'ab', 'cde'}, 'UniformOutput', false);

%% Functions
function s = describe(o)
    % DESCRIBE Summarise an order.
    %   S = DESCRIBE(O) returns a label.
    if o.total > 100
        s = sprintf('#%d large', o.number);
    else
        s = sprintf('#%d small', o.number);
    end
end

function [total, avg] = stats(varargin)
    arguments (Repeating)
        varargin double
    end
    vals = [varargin{:}];
    total = sum(vals);
    if nargout > 1
        avg = mean(vals);
    end
end

function result = nested(x)
    result = helper(x);
    function y = helper(z)
        y = z + 1;
    end
end

%% Classes
classdef Item < handle
    properties (Access = public, Constant)
        MAX = 1000;
    end
    properties
        sku (1,1) string
        quantity (1,1) double {mustBeNonnegative} = 0
    end
    properties (Dependent)
        label
    end
    methods
        function obj = Item(sku, quantity)
            arguments
                sku string
                quantity double = 0
            end
            obj.sku = sku;
            obj.quantity = quantity;
        end
        function value = get.label(obj)
            value = obj.sku + " x" + obj.quantity;
        end
    end
    methods (Static)
        function item = empty()
            item = Item("", 0);
        end
    end
    events
        Restocked
    end
    enumeration
        Default ('none', 0)
    end
end

%% Plotting
p = polyfit(paid.number, paid.total, 1);
figure('Name', 'Totals', 'Color', 'w');
plot(paid.number, paid.total, 'o', paid.number, polyval(p, paid.number), '-');
hold on; grid on;
title('Paid order totals'); xlabel('order'); ylabel('GBP');
legend({'data', 'fit'}, 'Location', 'northwest');
global counter
persistent cache
format long g
clear all; close all; clc
!echo shell escape

%% Rare constructs
% numbers and literals
nums = [1e3, 1E-3, .5, 5., 0x1F, 0b101, 0xFFu8, 0b11s16, 3i, 3.5j, 1e3i, 0.1e+2, Inf, -Inf, NaN, eps(1), pi, e];
types = {int8(1), uint16(2), int32(3), uint64(4), single(1.5), double(2), logical(1), char(65), string("s"), 'c', true, false};
strs = {'single ''quoted'' \n not escaped', "double ""quoted"" \n escaped\t", ['con' 'cat'], ["con" + "cat"], 'it''s', "it's", 'say "hi"', "say 'hi'", ''};
cmd_syntax_a = 1;

% operators
ops = {a + b, a - b, a * b, a / b, a \ b, a ^ b, a .* b, a ./ b, a .\ b, a .^ b, a', a.', a == b, a ~= b, a < b, a <= b, a > b, a >= b, ...
       a & b, a | b, ~a, a && b, a || b, xor(a, b), a:b, a:s:b, a(:), a(:, 1), a(end), a(end-1:end), a(:, end+1), a(1, :) , a{1}, a{end}, a.field, a.(name), ...
       @sin, @(x) x.^2, @(x, y) x + y, @() disp('hi'), @plus, (1:3)', [1, 2; 3, 4]', {1, 'a'; 2, 'b'}', a(a > 2 & a < 5), a(~isnan(a))};
ranged = 1:10; stepped = 0:0.5:5; downward = 10:-2:0; empty_range = 5:1;
continued = [1, 2, ...  comment after continuation
             3, 4];
matrices = [1 2 3; 4 5 6; 7 8 9];
spaces_matter = [1 - 2, 1 -2, 1 - 2, a' b', a'*b'];
cells = {1, 'two', [3 4]; {5}, @six, struct('s', 7)};
nested = {{1, {2, {3}}}};

% structs, maps, tables
st = struct('a', 1, 'b', {{1, 2}});
st(2).a = 5; st(end+1).a = 6;
st.nested.deep.field = 'value';
dynamic = st.('a');
m = containers.Map({'a', 'b'}, [1 2]); m('c') = 3; keys(m); values(m); isKey(m, 'a');
m2 = containers.Map('KeyType', 'double', 'ValueType', 'any');
tbl = table((1:3)', ["a"; "b"; "c"], 'VariableNames', {'n', 's'});
tbl.n(2) = 10; tbl(tbl.n > 1, :); tbl{:, 'n'}; height(tbl); width(tbl);
tt = timetable(seconds(1:3)', [4; 5; 6]); ds = datetime('now'); du = duration(1, 2, 3); cal = caldays(2); cat = categorical({'a', 'b'});

% control flow, all keywords
for i = 1:3, disp(i), end
for k = [1 2; 3 4], disp(k), end
for c = {1, 'a'}, disp(c), end
parfor (i = 1:4, 2), x(i) = i; end
while true, break; end
if a, elseif b, else, end
switch x, case {1, 2}, case 'str', case "str2", otherwise, end
try, error('MyPkg:id', 'Message %d', 1); catch ME, disp(ME.message); end
try; catch; end
try
    x = 1;
catch err
    switch err.identifier
        case 'MATLAB:nonExistentField'
            rethrow(err)
        otherwise
            throw(MException('A:b', 'c'))
    end
end
spmd, labindex, end
return
continue
global G1 G2
persistent P1
clearvars -except keep
close all force
hold on; hold off; axis equal; grid minor; format short g; more off; clc; clear all; warning off all; diary off; echo off;
x = 3; %#ok<NASGU>
y = 4; % TODO: remove  FIXME: check

%{
Nested block comment start
%{
inner block
%}
still inside outer
%}

% functions of every kind
function varargout = flex(varargin)
    narginchk(0, Inf); nargoutchk(0, 2);
    p = inputParser; addRequired(p, 'x', @isnumeric); addOptional(p, 'y', 1); addParameter(p, 'Name', 'v', @ischar); addParamValue(p, 'Old', 0); addSwitch(p, 'flag'); parse(p, varargin{:});
    varargout{1} = nargin; varargout{2} = nargout; inputname(1); exist('x', 'var'); isa(x, 'double');
    assert(true, 'MyPkg:id', 'msg'); validateattributes(1, {'numeric'}, {'positive', 'scalar'}); validatestring('a', {'apple'});
end
function result = early(x), if x, result = 1; return, end, result = 2; end
function [] = noout(), end
function [a, ~, c] = ignore(), a = 1; c = 3; end
function r = defaults(a, b), arguments, a (1,1) double = 1, b string {mustBeMember(b, ["x", "y"])} = "x", end, r = a; end
function nestedOuter(), function nestedInner(), end, nestedInner(), end

% classdef-like keywords (class files only; shown here for highlighting)
classdef (Abstract, Sealed, Hidden) Base < handle & matlab.mixin.Copyable
    properties (Access = private, SetAccess = protected, GetAccess = public, Constant, Dependent, Transient, Hidden, SetObservable, AbortSet, NonCopyable)
        P (1,:) double {mustBePositive, mustBeFinite} = 5
        Q
    end
    properties (Abstract), A, end
    methods (Static, Access = protected, Abstract, Sealed, Hidden)
        r = s(obj)
    end
    methods
        function obj = Base(varargin), obj@handle(); end
        function set.P(obj, v), obj.P = v; end
        function v = get.Q(obj), v = obj.P; end
        function r = plus(a, b), r = a; end
        function delete(obj), end
    end
    events (ListenAccess = public, NotifyAccess = protected), Changed, end
    enumeration, Low (1), High (2), end
end
mc = ?Base; mc.PropertyList; ev = Base.empty; notify(obj, 'Changed'); addlistener(obj, 'Changed', @(s, e) disp(e));
import matlab.unittest.*; import pkg.*; import pkg.sub.Class;
eval('x = 1'); evalc('disp(1)'); evalin('base', 'x'); assignin('base', 'y', 2); feval(@sin, 0); arrayfun(@(x) x, 1:3); cellfun(@numel, {1}, 'UniformOutput', false); structfun(@(v) v, st);
fprintf('%d %s %f %g %e %x %c %5.2f %-8s %+d %%\n', 1, 'a', 1.5, 2.5, 1e3, 255, 'c', pi, 'left', 3);
sprintf("%s", "string"); disp(num2str(pi, 8)); mat2str([1 2; 3 4]); int2str(3.7); str2double('1.5'); regexp('abc', '(?<n>b)', 'names'); regexprep('abc', 'b', 'x'); strsplit('a,b', ','); strjoin({'a', 'b'}, ', ');
x(2, :) = []; x(:) = 0; x(x > 1) = []; [m, i] = max(x); [~, idx] = sort(x, 'descend'); [q, r] = deal(1, 2); [a, b, c] = size(x);
!echo shell escape line

%% Name=Value arguments, string functions and newer syntax (R2021a onwards)
figure; plot(1:10, (1:10).^2, LineWidth=2, Color="red", Marker="o");
title("Name=Value syntax", FontSize=14);
opts = struct(Name="stock", Count=3);
words = ["alpha" "beta" "gamma"];
joined = join(words, ", ") + "!";
contains(words, "a") | startsWith(words, "g");
tf = isempty(words) || strlength(words(1)) > 3;
cleanup = onCleanup(@() disp("cleaned up"));
result = arrayfun(@(k) k^2, 1:3, UniformOutput=false);
A = magic(4);  B = A(2:end, :) .* (A(1:end-1, :) > 5);
z = 3 + 4i; mag = abs(z); angleDeg = rad2deg(angle(z));
