#!/usr/bin/env Rscript
# R 4.5 — syntax showcase
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

# ── Native pipe placeholder, lambdas and recent syntax (R 4.1 to 4.5) ──
orders |> lm(total ~ number, data = _)
orders |> _$total
orders |> subset(total > 0) |> _[["total"]] |> mean()
c(1, 4, 9) |> sqrt() |> sum()
sq <- \(x) x^2
(\(x, y = 2) x + y)(1)
Map(\(a, b) a * b, 1:3, 4:6)
NULL %||% "default"
r"(C:\path\no\escapes)"
r"-[dashes and [brackets]]-"
R"---(three dashes)---"
0x1.8p3
0xAbCdEfL
1e-3L
100000L
.5e2
1i^2
TRUE && FALSE || !TRUE
if (TRUE) 1 else 2
f <- function(x) -x
g <- function(a,
              b = c("one", "two"),
              ...) {
  b <- match.arg(b)
  extras <- list(...)
  n <- ...length()
  second <- ...elt(2)
  names(extras)
}

# ── Assignment forms ──
x1 <- 1; x2 = 2; 3 -> x3; x4 <<- 4; 5 ->> x5
assign("x6", 6); delayedAssign("lazy", stop("never"))
`my-name` <- 7
names(v)[2] <- "b"
attr(v, "units") <- "kg"
levels(fac)[1] <- "new"
dim(m) <- c(3, 2)
body(square) <- quote(x^3)
environment(square) <- globalenv()
is.na(v) <- 2
substr(single, 1, 1) <- "S"
lst$new$deep <- 1
lst[["k"]][["j"]] <- 2
m[m > 3] <- 0
obj@slot <- 1
x <- y <- z <- 0

# ── Indexing: every form ──
v[1]; v[[1]]; v[-1]; v[c(-1, -2)]; v[v > 1 & !is.na(v)]; v["a"]; v[]; v[0]
lst[1]; lst[[1]]; lst$a; lst$`odd name`; lst[["a"]][["b"]]; lst[[c(1, 2)]]
m[1, 2]; m[1, ]; m[, 1]; m[-1, , drop = FALSE]; m[cbind(1, 2)]
arr[1, 2, 3]; arr[, , 1]
df <- data.frame(a = 1:3, b = letters[1:3])
df$a; df[["a"]]; df[1, ]; df[, "a"]; df[df$a > 1, "b"]; df[order(df$a, decreasing = TRUE), ]
df[["c"]] <- df$a * 2
with(df, a + 1)
within(df, d <- a + 1)
transform(df, e = a * 2)

# ── Formulas, tidy evaluation, data.table ──
y ~ x
y ~ x1 + x2 + x1:x2 + x1 * x2 + I(x1^2) + log(x2) - 1
~ x | g
lhs ~ .
. ~ rhs
orders |> group_by(status) |> summarise(n = n(), mean_total = mean(total, na.rm = TRUE))
orders |> mutate(total2 = total * 2, .keep = "all") |> select(starts_with("t"), -number)
my_fn <- function(data, col) data |> summarise(m = mean({{ col }}))
by_var <- function(data, var) data |> group_by(.data[[var]])
dyn <- function(df, name, value) df |> mutate("{name}" := value)
splice_args <- function(...) rlang::list2(!!!list(...))
!!sym("total")
.x + .y
..1 + ..2
purrr::map(1:3, ~ .x * 2)
purrr::map2(1:3, 4:6, ~ .x + .y)
glue::glue("sku {orders$number[1]} total {orders$total[1]}")
library(data.table)
DT <- as.data.table(orders)
DT[total > 20, .(n = .N, avg = mean(total)), by = status]
DT[, new := total * 2]
DT[, `:=`(a = 1, b = 2)]
DT[order(-total)][1:3]
DT[.N]
DT[, .SD, .SDcols = c("number", "total")]

# ── Classes: S3, S4, RC and S7 ──
print.stack <- function(x, ...) { cat("<stack of", length(unclass(x)), ">\n"); invisible(x) }
"+.money" <- function(e1, e2) structure(unclass(e1) + unclass(e2), class = "money")
"[.myvec" <- function(x, i) structure(unclass(x)[i], class = "myvec")
"$.record" <- function(x, name) unclass(x)[[name]]
"==.money" <- function(e1, e2) unclass(e1) == unclass(e2)
Ops.temperature <- function(e1, e2) { v <- get(.Generic)(unclass(e1), unclass(e2)); if (.Generic %in% c("+", "-")) structure(v, class = "temperature") else v }
as.character.money <- function(x, ...) paste0("$", format(unclass(x)))
length.stack <- function(x) length(unclass(x))
area <- function(shape, ...) UseMethod("area")
area.default <- function(shape, ...) stop("unknown shape")
area.circle <- function(shape, ...) pi * shape$r^2
area.square <- function(shape, ...) { NextMethod() }

setClass("Base", representation("VIRTUAL", id = "integer"))
setClass("Derived", contains = "Base", slots = c(label = "character"), prototype = list(label = "x"))
setGeneric("describe", function(x, ...) standardGeneric("describe"), valueClass = "character")
setMethod("describe", signature("Derived"), function(x, ...) paste("derived", x@label))
setMethod("show", "Derived", function(object) cat("<Derived>\n"))
setMethod("+", signature("Derived", "Derived"), function(e1, e2) e1)
setMethod("initialize", "Derived", function(.Object, ...) { .Object <- callNextMethod(.Object, ...); .Object })
setRefClass("Account", fields = list(balance = "numeric"), methods = list(
  deposit = function(x) { balance <<- balance + x; invisible(.self) }
))
Person <- S7::new_class("Person", properties = list(name = S7::class_character, age = S7::class_numeric))
S7::method(print, Person) <- function(x, ...) cat(x@name, "\n")
greet <- S7::new_generic("greet", "x")
S7::method(greet, Person) <- function(x) paste("Hello", x@name)

# ── Conditions, environments, and language objects ──
cond <- structure(class = c("custom_error", "error", "condition"), list(message = "boom", call = sys.call(-1)))
tryCatch(stop(cond), custom_error = function(e) conditionMessage(e))
withRestarts(invokeRestart("myRestart", 1), myRestart = function(x) x)
warning("careful", call. = FALSE, immediate. = TRUE)
rlang::abort("typed", class = "my_error")
stopifnot("x must be positive" = x1 > 0)
on.exit(close(con), add = TRUE, after = FALSE)
Recall
sys.function()
match.call()
do.call("sum", list(1, 2))
Reduce(function(a, b) paste0(a, b), letters[1:3], accumulate = TRUE, right = TRUE)
Negate(is.na)(1)
Vectorize(function(a, b) a + b)(1:3, 1:3)
local({ a <- 1; function() a })()
env <- new.env(parent = emptyenv())
assign("k", 1, envir = env); get("k", envir = env); exists("k", envir = env, inherits = FALSE)
with(env, k)
e <- quote(f(x, y = 2))
e[[1]]; as.list(e); as.call(list(as.name("sum"), 1, 2))
deparse(e)
eval(e, list(f = function(x, y) x + y, x = 1))
bquote(.(x1) + .(x2))
substitute(a + b, list(a = 1, b = quote(z)))
expression(a, b + 1)[[2]]
function(x, ...) NULL
(function() invisible(NULL))()
`if`(TRUE, "yes", "no")
`for`(i, 1:2, print(i))
`[`(v, 2)
sapply(1:3, `-`)
