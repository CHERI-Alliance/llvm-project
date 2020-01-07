; RUN: opt -attributor -attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=2 -S < %s | FileCheck %s
;
; This file is the same as noreturn_sync.ll but with a personality which
; indicates that the exception handler *can* catch asynchronous exceptions. As
; a consequence, invokes to noreturn and nounwind functions are not translated
; to calls followed by an unreachable but the unwind edge is considered live.
;
; https://reviews.llvm.org/D59978#inline-586873
;
; Make sure we handle invoke of a noreturn function correctly.
;
; This test is also a reminder of how we handle (=ignore) stackoverflow exception handling.
;
target datalayout = "e-m:w-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.16.27032"

@"??_C@_0BG@CMNEKHOP@Exception?5NOT?5caught?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [22 x i8] c"Exception NOT caught\0A\00", align 1
@"??_C@_0BC@NKPAGFFJ@Exception?5caught?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [18 x i8] c"Exception caught\0A\00", align 1
@"??_C@_0BK@JHJLGDKL@Done?5execution?5result?$DN?$CFi?6?$AA@" = linkonce_odr dso_local unnamed_addr constant [26 x i8] c"Done execution result=%i\0A\00", align 1
@"?_OptionsStorage@?1??__local_stdio_printf_options@@9@4_KA" = linkonce_odr dso_local global i64 0, align 8


define dso_local void @"?overflow@@YAXXZ"() {
entry:
; CHECK:      Function Attrs: nofree noreturn nosync nounwind
; CHECK-NEXT: define
; CHECK-NEXT:   entry:
; CHECK-NEXT:   call void @"?overflow@@YAXXZ"()
; CHECK-NEXT:   unreachable
  call void @"?overflow@@YAXXZ"()
  %call3 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([18 x i8], [18 x i8]* @"??_C@_0BC@NKPAGFFJ@Exception?5caught?6?$AA@", i64 0, i64 0))
  ret void
}


; CHECK-NOT:    nounwind
; CHECK-NOT:    noreturn
; CHECK:        define
; CHECK-SAME:   @"?catchoverflow@@YAHXZ"()
define dso_local i32 @"?catchoverflow@@YAHXZ"()  personality i8* bitcast (i32 (...)* @__C_specific_handler to i8*) {
entry:
  %retval = alloca i32, align 4
  %__exception_code = alloca i32, align 4
; CHECK: invoke void @"?overflow@@YAXXZ"()
; CHECK:          to label %invoke.cont unwind label %catch.dispatch
  invoke void @"?overflow@@YAXXZ"()
          to label %invoke.cont unwind label %catch.dispatch

invoke.cont:                                      ; preds = %entry
; CHECK:      invoke.cont:
; CHECK-NEXT: unreachable
  br label %invoke.cont1

catch.dispatch:                                   ; preds = %invoke.cont, %entry
  %0 = catchswitch within none [label %__except] unwind to caller

__except:                                         ; preds = %catch.dispatch
  %1 = catchpad within %0 [i8* null]
  catchret from %1 to label %__except2

__except2:                                        ; preds = %__except
  %2 = call i32 @llvm.eh.exceptioncode(token %1)
  store i32 1, i32* %retval, align 4
  br label %return

invoke.cont1:                                     ; preds = %invoke.cont
  store i32 0, i32* %retval, align 4
  br label %return

__try.cont:                                       ; No predecessors!
  store i32 2, i32* %retval, align 4
  br label %return

return:                                           ; preds = %__try.cont, %__except2, %invoke.cont1
  %3 = load i32, i32* %retval, align 4
  ret i32 %3
}


define dso_local void @"?overflow@@YAXXZ_may_throw"()  {
entry:
; CHECK:      Function Attrs: noreturn
; CHECK-NOT:  nounwind
; CHECK-NEXT: define
; CHECK-NEXT:   entry:
; CHECK-NEXT:   %call3 = call i32 (i8*, ...) @printf(i8* nonnull dereferenceable(18) getelementptr inbounds ([18 x i8], [18 x i8]* @"??_C@_0BC@NKPAGFFJ@Exception?5caught?6?$AA@", i64 0, i64 0))
; CHECK-NEXT:   call void @"?overflow@@YAXXZ_may_throw"()
; CHECK-NEXT:   unreachable
  %call3 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([18 x i8], [18 x i8]* @"??_C@_0BC@NKPAGFFJ@Exception?5caught?6?$AA@", i64 0, i64 0))
  call void @"?overflow@@YAXXZ_may_throw"()
  ret void
}


; CHECK-NOT:    nounwind
; CHECK-NOT:    noreturn
; CHECK:        define
; CHECK-SAME:   @"?catchoverflow@@YAHXZ_may_throw"()
define dso_local i32 @"?catchoverflow@@YAHXZ_may_throw"()  personality i8* bitcast (i32 (...)* @__C_specific_handler to i8*) {
entry:
  %retval = alloca i32, align 4
  %__exception_code = alloca i32, align 4
; CHECK: invoke void @"?overflow@@YAXXZ_may_throw"()
; CHECK:          to label %invoke.cont unwind label %catch.dispatch
  invoke void @"?overflow@@YAXXZ_may_throw"()
          to label %invoke.cont unwind label %catch.dispatch

invoke.cont:                                      ; preds = %entry
; CHECK:      invoke.cont:
; CHECK-NEXT: unreachable
  br label %invoke.cont1

catch.dispatch:                                   ; preds = %invoke.cont, %entry
  %0 = catchswitch within none [label %__except] unwind to caller

__except:                                         ; preds = %catch.dispatch
  %1 = catchpad within %0 [i8* null]
  catchret from %1 to label %__except2

__except2:                                        ; preds = %__except
  %2 = call i32 @llvm.eh.exceptioncode(token %1)
  store i32 1, i32* %retval, align 4
  br label %return

invoke.cont1:                                     ; preds = %invoke.cont
  store i32 0, i32* %retval, align 4
  br label %return

__try.cont:                                       ; No predecessors!
  store i32 2, i32* %retval, align 4
  br label %return

return:                                           ; preds = %__try.cont, %__except2, %invoke.cont1
  %3 = load i32, i32* %retval, align 4
  ret i32 %3
}

declare dso_local i32 @__C_specific_handler(...)

declare dso_local i32 @printf(i8* %_Format, ...)

declare i32 @llvm.eh.exceptioncode(token)
