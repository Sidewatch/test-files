% MATLAB: load orders, summarise by status, and fit a line.
% This file DETECTS AS OBJECTIVE-C (.m is shared) — pick MATLAB from the language picker.
REORDER_POINT = 25;

orders = table([1; 2; 3; 4], [120.5; 42; 0; 88.25], categorical({'paid'; 'pending'; 'cancelled'; 'paid'}), ...
    'VariableNames', {'number', 'total', 'status'});

paid = orders(orders.status == 'paid', :);
revenue = sum(paid.total);
fprintf('%d paid orders, revenue %.2f\n', height(paid), revenue);

byStatus = groupsummary(orders, 'status', 'sum', 'total');
disp(byStatus);

function s = describe(o)
    if o.total > 100
        s = sprintf('#%d large', o.number);
    else
        s = sprintf('#%d small', o.number);
    end
end

p = polyfit(paid.number, paid.total, 1);
plot(paid.number, paid.total, 'o', paid.number, polyval(p, paid.number), '-');
title('Paid order totals'); xlabel('order'); ylabel('GBP');
