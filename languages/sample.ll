; LLVM IR: sum the integers 1..n, with a loop and a call to printf.
target triple = "arm64-apple-macosx14.0.0"

@.fmt = private unnamed_addr constant [12 x i8] c"sum = %lld\0A\00", align 1

declare i32 @printf(ptr, ...)

define i64 @sum_to(i64 %n) {
entry:
  br label %loop

loop:
  %i   = phi i64 [ 1, %entry ], [ %i.next, %loop ]
  %acc = phi i64 [ 0, %entry ], [ %acc.next, %loop ]
  %acc.next = add nsw i64 %acc, %i
  %i.next   = add nuw i64 %i, 1
  %done = icmp sgt i64 %i.next, %n
  br i1 %done, label %exit, label %loop

exit:
  ret i64 %acc.next
}

define i32 @main() {
  %s = call i64 @sum_to(i64 100)
  %r = call i32 (ptr, ...) @printf(ptr @.fmt, i64 %s)
  ret i32 0
}
