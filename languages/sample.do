* Stata: load orders, summarise by status, and a small program.
clear all
set more off

import delimited "orders.csv", varnames(1) clear
label variable total "Order total (GBP)"

gen paid = (status == "paid")
gen big = total > 100 if !missing(total)

bysort status: egen revenue = total(total)
tabstat total, by(status) statistics(n mean max)

program define describe_order
    args number status
    display "#`number' `status'"
end

forvalues i = 1/3 {
    describe_order `i' "checked"
}

regress total number if paid
predict yhat, xb
summarize yhat, detail
