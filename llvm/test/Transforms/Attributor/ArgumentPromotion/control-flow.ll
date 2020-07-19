; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --check-attributes
; RUN: opt -attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=1 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=1 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM

; Don't promote around control flow.
define internal i32 @callee(i1 %C, i32* %P) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind readonly willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@callee
; IS__TUNIT____-SAME: (i1 [[C:%.*]], i32* nocapture nofree readonly [[P:%.*]])
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    br i1 [[C]], label [[T:%.*]], label [[F:%.*]]
; IS__TUNIT____:       T:
; IS__TUNIT____-NEXT:    ret i32 17
; IS__TUNIT____:       F:
; IS__TUNIT____-NEXT:    [[X:%.*]] = load i32, i32* [[P]], align 4
; IS__TUNIT____-NEXT:    ret i32 [[X]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree norecurse nosync nounwind readonly willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@callee
; IS__CGSCC____-SAME: (i1 [[C:%.*]], i32* nocapture nofree readonly [[P:%.*]])
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    br i1 [[C]], label [[T:%.*]], label [[F:%.*]]
; IS__CGSCC____:       T:
; IS__CGSCC____-NEXT:    ret i32 17
; IS__CGSCC____:       F:
; IS__CGSCC____-NEXT:    [[X:%.*]] = load i32, i32* [[P]], align 4
; IS__CGSCC____-NEXT:    ret i32 [[X]]
;
entry:
  br i1 %C, label %T, label %F

T:
  ret i32 17

F:
  %X = load i32, i32* %P
  ret i32 %X
}

define i32 @foo(i1 %C, i32* %P) {
; IS__TUNIT____: Function Attrs: argmemonly nofree nosync nounwind readonly willreturn
; IS__TUNIT____-LABEL: define {{[^@]+}}@foo
; IS__TUNIT____-SAME: (i1 [[C:%.*]], i32* nocapture nofree readonly [[P:%.*]])
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[X:%.*]] = call i32 @callee(i1 [[C]], i32* nocapture nofree readonly [[P]])
; IS__TUNIT____-NEXT:    ret i32 [[X]]
;
; IS__CGSCC____: Function Attrs: argmemonly nofree norecurse nosync nounwind readonly willreturn
; IS__CGSCC____-LABEL: define {{[^@]+}}@foo
; IS__CGSCC____-SAME: (i1 [[C:%.*]], i32* nocapture nofree readonly [[P:%.*]])
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[X:%.*]] = call i32 @callee(i1 [[C]], i32* nocapture nofree readonly [[P]])
; IS__CGSCC____-NEXT:    ret i32 [[X]]
;
entry:
  %X = call i32 @callee(i1 %C, i32* %P)
  ret i32 %X
}

