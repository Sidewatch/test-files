# R: load orders, summarise with dplyr, and fit a small model.
library(dplyr)
library(ggplot2)

REORDER_POINT <- 25

orders <- data.frame(
  number = 1:6,
  total  = c(120.5, 42, 0, 88.25, 15, 230),
  status = factor(c("paid", "pending", "cancelled", "paid", "paid", "paid"))
)

describe <- function(o) {
  ifelse(o$status == "paid", sprintf("#%d paid %.2f", o$number, o$total), sprintf("#%d %s", o$number, o$status))
}

summary_by_status <- orders %>%
  group_by(status) %>%
  summarise(n = n(), revenue = sum(total), .groups = "drop") %>%
  arrange(desc(revenue))

print(summary_by_status)
cat(describe(orders), sep = "\n")

paid <- orders[orders$status == "paid", ]
fit <- lm(total ~ number, data = paid)
cat("slope:", round(coef(fit)[["number"]], 3), "\n")

if (nrow(paid) > 3) {
  p <- ggplot(paid, aes(number, total)) + geom_point() + geom_smooth(method = "lm", se = FALSE)
  ggsave("revenue.png", p, width = 5, height = 3)
}
