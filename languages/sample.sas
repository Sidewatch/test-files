/* SAS: read orders, summarise by status, and a small macro. */
%let reorder_point = 25;

data orders;
    infile datalines dlm=',';
    input number total status $;
    paid = (status = 'paid');
    datalines;
1,120.50,paid
2,42,pending
3,0,cancelled
4,88.25,paid
;
run;

proc sql;
    create table by_status as
    select status, count(*) as n, sum(total) as revenue format=comma10.2
    from orders
    group by status
    order by revenue desc;
quit;

%macro report(ds, title=);
    title "&title";
    proc print data=&ds noobs; run;
%mend report;

%report(by_status, title=Revenue by status)

proc means data=orders n mean max;
    where paid;
    var total;
run;
