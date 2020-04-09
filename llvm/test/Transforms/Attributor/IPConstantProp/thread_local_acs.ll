; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes
; RUN: opt -attributor -attributor-manifest-internal -attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=1 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal -attributor-disable=false -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=1 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -attributor-manifest-internal -attributor-disable=false -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal -attributor-disable=false -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM
;
;    #include <threads.h>
;    thread_local int gtl = 0;
;    int gsh = 0;
;
;    static int callee(int *thread_local_ptr, int *shared_ptr) {
;      return *thread_local_ptr + *shared_ptr;
;    }
;
;    void broker(int *, int (*callee)(int *, int *), int *);
;
;    void caller() {
;      broker(&gtl, callee, &gsh);
;    }
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

@gtl = dso_local thread_local global i32 0, align 4
@gsh = dso_local global i32 0, align 4

define internal i32 @callee(i32* %thread_local_ptr, i32* %shared_ptr) {
; CHECK-LABEL: define {{[^@]+}}@callee
; CHECK-SAME: (i32* nocapture nofree nonnull readonly align 4 dereferenceable(4) [[THREAD_LOCAL_PTR:%.*]], i32* nocapture nofree nonnull readonly align 4 dereferenceable(4) [[SHARED_PTR:%.*]])
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP:%.*]] = load i32, i32* [[THREAD_LOCAL_PTR]], align 4
; CHECK-NEXT:    [[TMP1:%.*]] = load i32, i32* @gsh, align 4
; CHECK-NEXT:    [[ADD:%.*]] = add nsw i32 [[TMP]], [[TMP1]]
; CHECK-NEXT:    ret i32 [[ADD]]
;
entry:
  %tmp = load i32, i32* %thread_local_ptr, align 4
  %tmp1 = load i32, i32* %shared_ptr, align 4
  %add = add nsw i32 %tmp, %tmp1
  ret i32 %add
}

define dso_local void @caller() {
; IS__TUNIT____-LABEL: define {{[^@]+}}@caller()
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    call void @broker(i32* nofree nonnull readonly align 4 dereferenceable(4) @gtl, i32 (i32*, i32*)* nonnull @callee, i32* nofree nonnull readonly align 4 dereferenceable(4) undef)
; IS__TUNIT____-NEXT:    ret void
;
; IS__CGSCC____-LABEL: define {{[^@]+}}@caller()
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    call void @broker(i32* nofree nonnull readonly align 4 dereferenceable(4) @gtl, i32 (i32*, i32*)* nonnull @callee, i32* nofree nonnull readonly align 4 dereferenceable(4) @gsh)
; IS__CGSCC____-NEXT:    ret void
;
entry:
  call void @broker(i32* nonnull @gtl, i32 (i32*, i32*)* nonnull @callee, i32* nonnull @gsh)
  ret void
}

declare !callback !0 dso_local void @broker(i32*, i32 (i32*, i32*)*, i32*)

!1 = !{i64 1, i64 0, i64 2, i1 false}
!0 = !{!1}
