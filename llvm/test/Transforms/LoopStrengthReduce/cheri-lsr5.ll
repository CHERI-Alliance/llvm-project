; RUN: %riscv32_cheri_purecap_llc --filetype=asm -o - %s | FileCheck %s
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128-pf200:64:64:64:32-A200-P200-G200"

; CHECK-NOT: cincoffset	{{.*}}, sp, 16

%struct.__Sealed_____default_malloc_capability_type = type { i32, i32, %struct.AllocatorCapabilityState }
%struct.AllocatorCapabilityState = type { i32, i32, [2 x ptr addrspace(200)] }
%struct.Timeout = type { i32, i32 }

@.str.2 = external hidden unnamed_addr addrspace(200) constant [18 x i8], align 1
@.str.3 = external hidden unnamed_addr addrspace(200) constant [25 x i8], align 1
@__default_malloc_capability = external dso_local addrspace(200) global %struct.__Sealed_____default_malloc_capability_type, section ".sealed_objects", align 8 #0

define hidden fastcc void @_ZN12_GLOBAL__N_124test_sub_quota_semanticsEv() unnamed_addr addrspace(200) #1 {
for.cond5.preheader:
  %t = alloca %struct.Timeout, align 4, addrspace(200)
  %quotas = alloca [4 x ptr addrspace(200)], align 8, addrspace(200)
  store i32 0, ptr addrspace(200) %t, align 4
  %remaining.i = getelementptr inbounds nuw i8, ptr addrspace(200) %t, i32 4
  store i32 -1, ptr addrspace(200) %remaining.i, align 4
  store ptr addrspace(200) @__default_malloc_capability, ptr addrspace(200) %quotas, align 8
  %0 = getelementptr inbounds nuw i8, ptr addrspace(200) %quotas, i32 8
  %call = notail call addrspace(200) ptr addrspace(200) @_Z15split_sub_quotaP7TimeoutU19__sealed_capabilityP24AllocatorCapabilityStatej(ptr addrspace(200) noundef nonnull %t, ptr addrspace(200) noundef nonnull @__default_malloc_capability, i32 noundef 528) #7
  store ptr addrspace(200) %call, ptr addrspace(200) %0, align 8
  %1 = getelementptr inbounds nuw i8, ptr addrspace(200) %quotas, i32 16
  %call.1 = notail call addrspace(200) ptr addrspace(200) @_Z15split_sub_quotaP7TimeoutU19__sealed_capabilityP24AllocatorCapabilityStatej(ptr addrspace(200) noundef nonnull %t, ptr addrspace(200) noundef %call, i32 noundef 352) #7
  store ptr addrspace(200) %call.1, ptr addrspace(200) %1, align 8
  %2 = getelementptr inbounds nuw i8, ptr addrspace(200) %quotas, i32 24
  %call.2 = notail call addrspace(200) ptr addrspace(200) @_Z15split_sub_quotaP7TimeoutU19__sealed_capabilityP24AllocatorCapabilityStatej(ptr addrspace(200) noundef nonnull %t, ptr addrspace(200) noundef %call.1, i32 noundef 176) #7
  store ptr addrspace(200) %call.2, ptr addrspace(200) %2, align 8
  br label %for.cond5

for.cond5:                                        ; preds = %for.cond5.preheader, %_ZN12_GLOBAL__N_116ConditionalDebugIXtlNS_26DebugLevelTemplateArgumentEEEXtlNS_12DebugContextILj15EEEtlA15_cLc65ELc108ELc108ELc111ELc99ELc97ELc116ELc111ELc114ELc32ELc116ELc101ELc115ELc116EEEELb1ELb1EE9InvariantIJRjRiEEC2EbPKcS7_S8_NS_14SourceLocationE.exit
  %storemerge = phi i32 [ %sub15, %_ZN12_GLOBAL__N_116ConditionalDebugIXtlNS_26DebugLevelTemplateArgumentEEEXtlNS_12DebugContextILj15EEEtlA15_cLc65ELc108ELc108ELc111ELc99ELc97ELc116ELc111ELc114ELc32ELc116ELc101ELc115ELc116EEEELb1ELb1EE9InvariantIJRjRiEEC2EbPKcS7_S8_NS_14SourceLocationE.exit ], [ 3, %for.cond5.preheader ]
  %cmp6.not = icmp eq i32 %storemerge, 0
  br i1 %cmp6.not, label %for.cond.cleanup7, label %for.body8

for.cond.cleanup7:                                ; preds = %for.cond5
  ret void

for.body8:                                        ; preds = %for.cond5
  %arrayidx9 = getelementptr inbounds nuw ptr addrspace(200), ptr addrspace(200) %quotas, i32 %storemerge
  %3 = load ptr addrspace(200), ptr addrspace(200) %arrayidx9, align 8
  %arrayidx11 = getelementptr i8, ptr addrspace(200) %arrayidx9, i32 -8
  %4 = load ptr addrspace(200), ptr addrspace(200) %arrayidx11, align 8
  %call12 = notail call addrspace(200) i32 @_Z19recombine_sub_quotaU19__sealed_capabilityP24AllocatorCapabilityStateS0_(ptr addrspace(200) noundef %3, ptr addrspace(200) noundef %4) #7
  %cmp13 = icmp eq i32 %call12, 0
  br i1 %cmp13, label %_ZN12_GLOBAL__N_116ConditionalDebugIXtlNS_26DebugLevelTemplateArgumentEEEXtlNS_12DebugContextILj15EEEtlA15_cLc65ELc108ELc108ELc111ELc99ELc97ELc116ELc111ELc114ELc32ELc116ELc101ELc115ELc116EEEELb1ELb1EE9InvariantIJRjRiEEC2EbPKcS7_S8_NS_14SourceLocationE.exit, label %if.then.i

if.then.i:                                        ; preds = %for.body8
  call fastcc addrspace(200) void @_ZN12_GLOBAL__N_116ConditionalDebugIXtlNS_26DebugLevelTemplateArgumentEEEXtlNS_12DebugContextILj15EEEtlA15_cLc65ELc108ELc108ELc111ELc99ELc97ELc116ELc111ELc114ELc32ELc116ELc101ELc115ELc116EEEELb1ELb1EE14report_failureIJjiEEEvPKcS8_S8_iS8_DpT_(ptr addrspace(200) noundef nonnull @.str.2, ptr addrspace(200) noundef nonnull @.str.3, i32 noundef 1509, i32 noundef %storemerge, i32 noundef %call12) #8
  call addrspace(200) void @llvm.trap()
  unreachable

_ZN12_GLOBAL__N_116ConditionalDebugIXtlNS_26DebugLevelTemplateArgumentEEEXtlNS_12DebugContextILj15EEEtlA15_cLc65ELc108ELc108ELc111ELc99ELc97ELc116ELc111ELc114ELc32ELc116ELc101ELc115ELc116EEEELb1ELb1EE9InvariantIJRjRiEEC2EbPKcS7_S8_NS_14SourceLocationE.exit: ; preds = %for.body8
  %sub15 = add nsw i32 %storemerge, -1
  br label %for.cond5
}

; Function Attrs: minsize optsize
declare dso_local ptr addrspace(200) @_Z15split_sub_quotaP7TimeoutU19__sealed_capabilityP24AllocatorCapabilityStatej(ptr addrspace(200) noundef, ptr addrspace(200) noundef, i32 noundef) local_unnamed_addr addrspace(200) #3

; Function Attrs: minsize optsize
declare dso_local i32 @_Z19recombine_sub_quotaU19__sealed_capabilityP24AllocatorCapabilityStateS0_(ptr addrspace(200) noundef, ptr addrspace(200) noundef) local_unnamed_addr addrspace(200) #3

; Function Attrs: inlinehint minsize mustprogress nounwind optsize
declare hidden fastcc void @_ZN12_GLOBAL__N_116ConditionalDebugIXtlNS_26DebugLevelTemplateArgumentEEEXtlNS_12DebugContextILj15EEEtlA15_cLc65ELc108ELc108ELc111ELc99ELc97ELc116ELc111ELc114ELc32ELc116ELc101ELc115ELc116EEEELb1ELb1EE14report_failureIJjiEEEvPKcS8_S8_iS8_DpT_(ptr addrspace(200) noundef, ptr addrspace(200) noundef, i32 noundef, i32 noundef, i32 noundef) unnamed_addr addrspace(200) #4 align 2

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() addrspace(200) #5

attributes #0 = { "cheriot_sealed_value" }
attributes #1 = { minsize mustprogress noinline nounwind optsize}
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { minsize optsize}
attributes #4 = { inlinehint minsize mustprogress nounwind optsize}
attributes #5 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #6 = { nounwind }
attributes #7 = { minsize nounwind optsize}
attributes #8 = { minsize optsize}
