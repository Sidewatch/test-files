* Stata 19 (StataNow) do-file — syntax showcase
* ── Comments ──
* Stata do-file: warehouse stock analysis.
// Double-slash comment on its own line
** Double-star comment, also a whole-line comment
*! version 1.0.0 star-bang version comment (kept by which/ado describe)
display "trailing // comment" // after a command
display "continued " ///
    "across lines"
display "line one" /* inline block */ " line two"
/* Block comment
   spanning lines */
* TODO: add the supplier panel
* FIXME: reorder flag ignores backorders

version 19
clear all
set more off
set seed 20260924
set linesize 100
capture log close
log using "stock_analysis.log", replace text

* ── Macros ──
local datafile "stock.csv"
local reorder = 25
local varlist sku qty price status
global DATA "data/inventory"
global threshold 0.05
tempvar scratch
tempname handle
tempfile cleaned
display "`datafile' has reorder point `reorder' and global $DATA"
display "Nested: `=`reorder' * 2' and ${threshold}"
local n : word count `varlist'
local first : word 1 of `varlist'
local lbl : variable label qty
local up = upper("`first'")

* ── Import and labels ──
import delimited "`datafile'", varnames(1) clear encoding("utf-8")
import excel using "orders.xlsx", sheet("Orders") firstrow clear
use "stock.dta", clear
sysuse auto, clear

label variable qty "Quantity on hand"
label variable price "Unit price (GBP)"
label define statuslbl 1 "Pending" 2 "Paid" 3 "Shipped" 4 "Cancelled"
label values status statuslbl
notes qty: counted at the last stocktake
rename (old_qty old_price) (qty price)
rename sku* item_*
order sku name qty price, first
describe
codebook status, compact

* ── Generate and replace ──
generate paid = (status == 2)
gen byte big = qty > 100 if !missing(qty)
gen double revenue = qty * price
gen str20 label = name + " (" + string(qty) + ")"
gen log_qty = ln(qty + 1)
gen sqrt_price = sqrt(price)
gen rounded = round(price, 0.01)
gen cat = cond(qty < `reorder', "low", "ok")
gen lag_qty = qty[_n-1]
gen first_obs = (_n == 1)
gen total_obs = _N
replace qty = 0 if missing(qty)
replace price = . if price < 0
replace name = trim(lower(name))
replace status = .a if status == 99
recode status (1 = 10) (2/3 = 20) (else = 99), gen(status_group)
egen mean_qty = mean(qty), by(status)
egen rank_qty = rank(qty)
egen tag = tag(sku)
bysort status (qty): gen running = sum(qty)
by status: egen status_total = total(qty)
drop if missing(sku)
keep if inrange(qty, 0, 10000)
drop scratch_*
destring price, replace ignore("£,")
tostring sku, replace
encode name, gen(name_id)
decode status, gen(status_text)
format price %9.2f
format qty %10.0fc
format placed %td

* ── Numeric literals and operators ──
display 42 -7 3.14 1.5e10 2E-3 .5 0x1F
display 1 + 2 - 3 * 4 / 5 ^ 2
display mod(17, 5) 17 / 5 int(17 / 5)
display (1 < 2) & (2 <= 3) | (3 > 4) & !(4 >= 5)
display (1 == 1) (1 != 2) (1 ~= 2)
display "string" + " concatenation"
display missing(.) . .a .z
display c(pi) c(current_date) c(os)
display _N _n _rc _b[qty] _se[qty]
display `"compound "quoted" string"'

* ── Strings and functions ──
display strlen("warehouse") substr("warehouse", 1, 4) upper("abc") lower("ABC")
display strpos("a-b", "-") subinstr("a-b", "-", "_", .) regexm("ABC-1", "^[A-Z]+-[0-9]+$")
display string(1234.5, "%9.2fc") real("3.5") trim("  x  ") word("a b c", 2)
display ustrlen("Zürich ✓") ustrupper("zürich")
display date("2026-09-24", "YMD") mdy(9, 24, 2026) year(td(24sep2026)) month(td(24sep2026))
display td(24sep2026) tc(24sep2026 13:45:00) tm(2026m9) tq(2026q3) tw(2026w39)

* ── Control flow ──
if `reorder' > 20 {
    display "high reorder point"
}
else if `reorder' > 10 {
    display "medium"
}
else {
    display "low"
}

forvalues i = 1/3 {
    display "pass `i'"
}
forvalues j = 10(-2)0 {
    display `j'
}

foreach v of varlist qty price {
    summarize `v', detail
}
foreach item in alpha beta gamma {
    display "`item'"
}
foreach n of numlist 1 3 5 7/9 {
    display `n'
}
foreach l of local varlist {
    display "`l'"
}
foreach g of global DATA {
    display "`g'"
}

local k = 0
while `k' < 3 {
    local ++k
    if `k' == 2 continue
    display "k=`k'"
}

quietly {
    regress qty price
}
noisily display "done"
capture noisily confirm variable qty
if _rc != 0 {
    display as error "qty missing"
    exit 111
}
capture {
    assert qty >= 0
}
assert price > 0 if !missing(price)
confirm numeric variable qty
confirm new variable fresh

* ── Delimiters, tokens, macro functions ──
#delimit ;
regress revenue qty price
    i.status,
    vce(robust);
#delimit cr
tokenize `varlist'
local second "`2'"
gettoken head tail : varlist
levelsof status, local(levels)
local nlev : list sizeof levels
local combined : list varlist | levels
local common : list varlist & levels
local diff : list varlist - levels
local sorted : list sort varlist
local fmt : format qty
local vtype : type qty
local lblname : value label status
display "`: word 2 of `varlist''"
display "`=trim("  padded  ")'"
display "`c(username)' on `c(os)' / `c(machine_type)' " _newline
display _col(10) "indented" _skip(3) "gap" _dup(5) "-"
display as text "a" as result "b" as error "c" as input "d"
display in smcl "{bf:bold} {it:italic} {hline 20} {c -(}braces{c )-}"
display %9.2f 3.14159 %td td(01jan2026) %tc clock("01jan2026 10:00", "DMY hm")
display "Item " 1 `"with "nested" quotes"'
display "scalar: " scalar(myscalar)
scalar myscalar = 3.5
scalar drop myscalar
matrix A = (1, 2 \ 3, 4)
matrix B = A' * A
matrix list B
matrix rownames A = first second
mat colnames A = c1 c2
display A[1, 2] det(A) trace(A) rowsof(A) colsof(A)
global i = 0
local ++i
local --i
if inlist(status, 1, 2) & inrange(qty, 1, 9) | !missing(price) {
    display "in-list"
}
if "`first'" != "" & regexm("`first'", "^s") display "starts with s"
else display "no match"
forvalues y = 2020(2)2026 {
    local years `years' `y'
}
foreach var of varlist qty price {
    capture confirm numeric variable `var'
    if _rc continue
}
foreach x of newlist a b c {
    display "`x'"
}
foreach v of varlist _all {
    if "`v'" == "sku" continue
    quietly count if missing(`v')
}
while 0 {
    break
}
set varabbrev off
set type double
set rmsg on
set maxvar 10000
set linesize 120
set scheme s2color
set graphics off
set cformat %9.3f
adopath + "ado"
which regress
help summarize
about
display `"`:display %tdCCYY-NN-DD td(24sep2026)'"'

* ── Frames ──
frame create details
frame details: use "details.dta", clear
frame change details
frame change default
frlink m:1 sku, frame(details)
frget supplier, from(details)
frame copy default backup, replace
frame rename backup archive
frame drop archive
frame pwf
cwf default
frame default: summarize qty
frame details {
    list in 1/3
}

* ── Tables and collect (Stata 17+) ──
table (status) (paid), statistic(mean qty) statistic(sd qty) nformat(%9.2f)
table status paid, stat(frequency) stat(percent) totals
dtable qty price i.status, by(paid) nformat(%9.2f mean sd) export("summary.docx", replace)
collect clear
collect: regress revenue qty price
collect layout (colname) (result[_r_b _r_se])
collect style cell, nformat(%9.3f)
collect export "results.docx", replace
collect get r(mean), tags(var[qty])
etable, estimates(m1 m2) mstat(N) mstat(r2) column(estimates) export("models.xlsx", replace)
estimates store m1
estimates restore m1
estimates table m1 m2, b(%7.3f) se stats(N r2)
eststo clear
nlcom (ratio: _b[qty] / _b[price])
lincom qty + price
testparm i.status
contrast status, effects
marginsplot, recast(line)

* ── Documents, Excel and Python ──
putdocx begin, pagesize(A4)
putdocx paragraph, style(Heading1)
putdocx text ("Stock report"), bold
putdocx table tbl1 = data(sku qty), varnames
putdocx save "report.docx", replace
putexcel set "results.xlsx", sheet("Summary") replace
putexcel A1 = "SKU" B1 = "Qty" C1 = formula("=SUM(B2:B10)")
putexcel A2 = matrix(A), names nformat(number_d2)
putexcel close
putpdf begin
putpdf paragraph
putpdf text ("Hello")
putpdf save "report.pdf", replace
python:
import sfi
import numpy as np
data = np.array(sfi.Data.get(var="qty"))
sfi.Macro.setLocal("avg", str(data.mean()))
end
python: print("one-line python")
python script "helper.py", args(1 2)
jupyter notebook "analysis.ipynb"

* ── Postfile, simulation, Bayes, multiple imputation ──
tempname memhold
postfile `memhold' double(mean sd) using "sims.dta", replace
forvalues r = 1/10 {
    quietly summarize qty
    post `memhold' (r(mean)) (r(sd))
}
postclose `memhold'
set rng mt64
set rngstream 2
bayes, rseed(19): regress revenue qty price
bayesstats summary
mi set mlong
mi register imputed price
mi impute chained (regress) price = qty i.status, add(5) rseed(19)
mi estimate: regress revenue qty price
teffects ipw (revenue) (paid qty price)
sem (revenue <- qty price)
stcox qty price
stset time, failure(event)
xtreg revenue qty, re
mixed revenue qty || warehouse_id:
glm paid qty, family(binomial) link(logit)
poisson visits qty, irr
didregress (revenue) (treated), group(warehouse_id) time(period)
cate po (revenue qty price) (paid), group(status)
lasso linear revenue qty price
dsregress revenue paid, controls(qty price)

* ── Programs ──
capture program drop describe_item
program define describe_item, rclass
    version 19
    syntax varlist(min=1 max=3) [if] [in] [, Detail Format(string) Level(cilevel)]
    marksample touse
    quietly summarize `varlist' if `touse', `detail'
    return scalar mean = r(mean)
    return scalar n = r(N)
    return local first : word 1 of `varlist'
    display as text "n = " as result r(N) as text ", mean = " as result %9.2f r(mean)
end

program define greet
    args name greeting
    if "`greeting'" == "" local greeting "Hello"
    display "`greeting', `name'!"
end

program define tally, eclass sortpreserve byable(recall)
    syntax anything(name=expr) [if] [in], BY(varname) [REplace]
    tempvar grp
    egen `grp' = group(`by')
    ereturn clear
end

describe_item qty price, detail
greet "warehouse"

* ── Mata ──
mata:
mata clear
mata set matastrict on
real matrix stock_matrix(real colvector q, real colvector p)
{
    real matrix M
    M = (q, p, q :* p)
    return(M)
}
void report(string scalar name)
{
    real scalar n
    n = st_nobs()
    printf("{txt}%s has %g observations\n", name, n)
}

real scalar loops(real scalar n)
{
    real scalar i, total
    string scalar s
    transmorphic A
    pointer(real scalar) p
    total = 0
    for (i = 1; i <= n; i++) {
        if (i == 3) continue
        else if (i > 8) break
        total = total + i
    }
    do {
        total--
    } while (total > 100)
    while (total < 0) total++
    A = asarray_create()
    asarray(A, "key", 1)
    s = sprintf("%s=%g", "total", total)
    p = &total
    st_numscalar("result", *p)
    st_local("msg", s)
    st_store(., "qty", st_data(., "qty") :+ 1)
    printf("%s\n", s)
    return(total > 0 ? total : -total)
}
end

* ── Analysis ──
summarize qty price, detail
tabulate status, missing
tabulate status paid, row chi2
tabstat qty price, by(status) statistics(n mean sd min max) columns(statistics)
correlate qty price
pwcorr qty price, sig star(0.05)
regress revenue qty price i.status c.qty#c.price, vce(robust)
logit paid qty price, or
predict yhat, xb
predict resid, residuals
estat vif
test qty = price
margins status, atmeans
ttest qty, by(paid)
anova revenue status
xtset warehouse_id period
xtreg revenue qty, fe cluster(warehouse_id)
ivregress 2sls revenue (price = cost) qty
collapse (sum) qty (mean) price, by(status)
reshape wide qty, i(sku) j(period)
merge 1:1 sku using "prices.dta", keep(match master) nogenerate
append using "more.dta"
joinby sku using "details.dta", unmatched(master)
sort status qty
gsort -qty
duplicates drop sku, force
preserve
    keep if paid
    save "paid.dta", replace
restore
bootstrap r(mean), reps(200): summarize qty
simulate mean = r(mean), reps(100): mysim

* ── Graphs and output ──
histogram qty, bin(20) normal title("Quantity") name(h1, replace)
twoway (scatter price qty) (lfit price qty), legend(off) ytitle("Price") xtitle("Qty")
graph bar (mean) qty, over(status) blabel(bar)
graph export "qty.png", replace width(1200)
export delimited using "out.csv", replace quote
export excel using "out.xlsx", firstrow(variables) replace
outsheet using "legacy.txt", replace
save "stock_clean.dta", replace
saveold "stock_v13.dta", version(13) replace
file open `handle' using "notes.txt", write text replace
file write `handle' "line one" _n "line two" _n
file close `handle'
set trace off
timer clear
timer on 1
timer off 1
timer list
log close
exit, clear
