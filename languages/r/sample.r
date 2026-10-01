#!/usr/bin/env Rscript
# ── Comments ──
# R showcase: warehouse inventory analysis.
# TODO: read orders from the database. FIXME: handle NA totals.

#' Summarise stock by status
#'
#' Roxygen documentation comment with tags.
#'
#' @param orders A data frame of orders.
#' @param by Column to group by. See \code{\link{summarise}} and \emph{dplyr}.
#' @param ... Further arguments passed on.
#' @return A data frame with one row per group.
#' @examples
#' summarise_orders(orders, "status")
#' @export
#' @importFrom dplyr group_by summarise
#' @seealso \url{https://example.com/docs}
NULL

# ── Packages ──
library(dplyr)
library("ggplot2")
require(stats)
suppressPackageStartupMessages(library(tidyr))
requireNamespace("jsonlite", quietly = TRUE)
dplyr::filter
stats:::internal_function
source("helpers.R")

# ── Constants and numbers ──
REORDER_POINT <- 25
int_val <- 42L
neg <- -7
hex <- 0xFF
hex_long <- 0xFFL
float <- 3.14
exp1 <- 1.5e-3
exp2 <- 6.022E23
dot <- .5
big <- 1e5L
cplx <- 3 + 4i
cplx2 <- 2.5i
special <- c(NA, NA_integer_, NA_real_, NA_character_, NA_complex_, NaN, Inf, -Inf, NULL, TRUE, FALSE, T, F)
pi_val <- pi
letters_vec <- c(LETTERS[1:3], letters[24:26], month.name[1], month.abb[12])

# ── Strings ──
single <- 'single quoted "with" double'
double <- "double quoted 'with' single, escapes: \n \t \\ \" \x41 \u00e9 \U0001F4E6 \101"
raw1 <- r"(raw string with \n and "quotes")"
raw2 <- R"---[raw with brackets ]--- inside]---"
raw3 <- r"{curly raw}"
backtick_name <- `my variable`
`my variable` <- 5
multi <- "a string
spanning lines"
fmt <- sprintf("#%d paid %.2f %s %5.1f%% %e", 7L, 120.5, "ok", 42.5, 1e4)
pasted <- paste("a", "b", sep = "-")
pasted0 <- paste0("sku-", 1:3, collapse = ", ")
cat(sprintf("%-10s|%10s|\n", "left", "right"))
regex <- gsub("^(\\w+)-(\\d+)$", "\\2-\\1", "AC-1001", perl = TRUE)
grepl("[[:alpha:]]+", "abc")

# ── Vectors, lists, matrices ──
v <- c(1, 2, 3)
seq1 <- 1:10
seq2 <- seq(0, 1, by = 0.25)
rep1 <- rep(c("a", "b"), times = 3)
named <- c(first = 1, second = 2, `third item` = 3)
lst <- list(sku = "AC-1001", qty = 25L, tags = c("new", "sale"), nested = list(a = 1))
m <- matrix(1:6, nrow = 2, ncol = 3, byrow = TRUE)
arr <- array(0, dim = c(2, 2, 2))
v[2]; v[-1]; v[v > 1]; v[c(TRUE, FALSE)]
lst$sku; lst[["qty"]]; lst[c("sku", "qty")]; lst$nested$a
m[1, ]; m[, 2]; m[1, 2, drop = FALSE]
slot_value <- obj@slot
fac <- factor(c("paid", "pending", "cancelled"), levels = c("pending", "paid", "cancelled"))

orders <- data.frame(
  number = 1:6,
  total  = c(120.5, 42, 0, 88.25, 15, 230),
  status = factor(c("paid", "pending", "cancelled", "paid", "paid", "paid")),
  stringsAsFactors = FALSE
)
orders$margin <- orders$total * 0.2
orders[["flag"]] <- orders$total > 50
orders[orders$status == "paid" & orders$total > 20, c("number", "total")]

# ── Operators ──
a <- 5; b <- 3
a -> c1
c2 <<- 7
8 ->> c3
assign("x", 10)
a = 6
arith <- a + b - a * b / a %% b %/% 2 ^ 2
power <- a ** 2
cmp <- a < b | a <= b & a > b || a >= b && a == b
neg_cmp <- !(a != b)
membership <- 3 %in% v
matmul <- m %*% t(m)
outer_prod <- v %o% v
xor_val <- xor(TRUE, FALSE)
custom <- `%+%` <- function(x, y) paste(x, y)
"a" %+% "b"
pipe_native <- orders |> subset(total > 0) |> nrow()
pipe_lambda <- v |> (\(x) x * 2)()
pipe_magrittr <- orders %>% filter(total > 0) %>% nrow()
pipe_tee <- orders %T>% print() %$% mean(total)
pipe_assign <- orders %<>% arrange(total)
formula1 <- total ~ number + I(number^2) | status
formula2 <- ~ x
unary_minus <- -a
colon_expr <- 1:3 + 1
help_op <- ?mean
tilde_op <- y ~ .

# ── Functions ──
describe <- function(o) {
  ifelse(o$status == "paid", sprintf("#%d paid %.2f", o$number, o$total), sprintf("#%d %s", o$number, o$status))
}

summarise_orders <- function(orders, by = "status", ..., verbose = FALSE) {
  stopifnot(is.data.frame(orders), is.character(by))
  if (verbose) message("summarising by ", by)
  result <- orders %>%
    group_by(.data[[by]]) %>%
    summarise(n = n(), revenue = sum(total), .groups = "drop") %>%
    arrange(desc(revenue))
  invisible(result)
}

square <- function(x) x^2
lambda <- \(x, y = 2) x + y
compose <- function(f, g) function(...) f(g(...))
vararg <- function(...) {
  args <- list(...)
  dots_len <- ...length()
  first <- ..1
  names(args)
}
defaults <- function(x, y = x * 2, z = NULL) {
  if (is.null(z)) z <- missing(y)
  on.exit(cat("exiting\n"), add = TRUE)
  return(x + y)
}
`%||%` <- function(a, b) if (is.null(a)) b else a
"replace<-" <- function(x, value) { x[1] <- value; x }
`second<-` <- function(x, value) { x[2] <- value; x }
second(v) <- 99

# ── Control flow ──
if (nrow(orders) > 3) {
  print("many")
} else if (nrow(orders) > 0) {
  print("few")
} else {
  print("none")
}

x <- if (a > 3) "big" else "small"

for (i in seq_len(nrow(orders))) {
  if (orders$total[i] == 0) next
  if (orders$total[i] > 200) break
  cat(describe(orders[i, ]), sep = "\n")
}

n <- 0
while (n < 3) n <- n + 1
repeat {
  n <- n - 1
  if (n <= 0) break
}

result <- switch(as.character(orders$status[1]),
  paid = "settled",
  pending = ,
  cancelled = "open",
  "unknown"
)

res <- tryCatch({
  warning("careful")
  log(-1)
}, warning = function(w) {
  message("warning: ", conditionMessage(w))
  NA
}, error = function(e) {
  stop("failed: ", conditionMessage(e), call. = FALSE)
}, finally = {
  cat("done\n")
})

withCallingHandlers(
  expr = { message("hello"); 10 },
  message = function(m) invokeRestart("muffleMessage")
)
try(stop("oops"), silent = TRUE)
signalCondition(simpleCondition("custom"))

# ── Apply family and functional ──
sapply(v, function(x) x * 2)
lapply(lst, class)
vapply(v, \(x) x + 1, numeric(1))
Map(function(a, b) a + b, 1:3, 4:6)
Reduce(`+`, 1:5, accumulate = TRUE)
Filter(function(x) x > 1, v)
do.call(rbind, list(1:3, 4:6))
mapply(rep, 1:3, 3:1)
apply(m, 1, sum)
tapply(orders$total, orders$status, mean)

# ── S3, S4 and R6 ──
product <- structure(list(sku = "AC-1001", price = 19.99), class = "product")
print.product <- function(x, ...) cat("<product", x$sku, ">\n")
format.product <- function(x, ...) paste0("product:", x$sku)
toString.product <- function(x, ...) format(x)
summary.product <- function(object, ...) UseMethod("summary")

setClass("Warehouse", representation(name = "character", bins = "numeric"), prototype(bins = 0))
setGeneric("capacity", function(object, ...) standardGeneric("capacity"))
setMethod("capacity", "Warehouse", function(object, ...) object@bins * 100)
setValidity("Warehouse", function(object) if (object@bins < 0) "negative bins" else TRUE)
w <- new("Warehouse", name = "north", bins = 12)
isVirtualClass("Warehouse")

Stack <- R6::R6Class("Stack",
  public = list(
    items = list(),
    push = function(x) { self$items[[length(self$items) + 1]] <- x; invisible(self) },
    size = function() length(self$items)
  ),
  private = list(secret = 1),
  active = list(top = function() private$secret)
)

# ── Modelling and plotting ──
paid <- orders[orders$status == "paid", ]
fit <- lm(total ~ number, data = paid)
cat("slope:", round(coef(fit)[["number"]], 3), "\n")
summary(fit)$r.squared

if (nrow(paid) > 3) {
  p <- ggplot(paid, aes(number, total)) +
    geom_point(colour = "#336699", size = 2) +
    geom_smooth(method = "lm", se = FALSE) +
    labs(title = "Revenue", x = "Order", y = expression(alpha[1]^2)) +
    theme_minimal()
  ggsave("revenue.png", p, width = 5, height = 3)
}

# ── Environment and meta-programming ──
e <- new.env()
local({ y <- 1; y + 1 })
f_quote <- quote(a + b)
f_bquote <- bquote(.(a) + b)
f_sub <- substitute(x + y, list(x = 1))
eval(parse(text = "1 + 1"))
expr <- expression(a * b)
body(square)
formals(defaults)
Sys.setenv(INVENTORY_HOME = "/opt/inventory")
Sys.getenv("HOME")
exists("orders")
get("orders")
invisible(gc())
