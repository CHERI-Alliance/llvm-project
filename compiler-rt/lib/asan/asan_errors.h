//===-- asan_errors.h -------------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is a part of AddressSanitizer, an address sanity checker.
//
// ASan-private header for error structures.
//===----------------------------------------------------------------------===//
#ifndef ASAN_ERRORS_H
#define ASAN_ERRORS_H

#include "asan_descriptions.h"
#include "asan_scariness_score.h"
#include "sanitizer_common/sanitizer_common.h"

namespace __asan {

struct ErrorBase {
  ErrorBase() = default;
  explicit ErrorBase(u32 tid_) : tid(tid_) {}
  ErrorBase(u32 tid_, int initial_score, const char *reason) : tid(tid_) {
    scariness.Clear();
    scariness.Scare(initial_score, reason);
  }
  ScarinessScoreBase scariness;
  u32 tid;
};

struct ErrorDeadlySignal : ErrorBase {
  SignalContext signal;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorDeadlySignal() = default;
  ErrorDeadlySignal(u32 tid, const SignalContext &sig)
      : ErrorBase(tid), signal(sig) {
    scariness.Clear();
    if (signal.IsStackOverflow()) {
      scariness.Scare(10, "stack-overflow");
    } else if (!signal.is_memory_access) {
      scariness.Scare(10, "signal");
    } else if (signal.addr < GetPageSizeCached()) {
      scariness.Scare(10, "null-deref");
    } else if (signal.addr == signal.pc) {
      scariness.Scare(60, "wild-jump");
    } else if (signal.write_flag == SignalContext::WRITE) {
      scariness.Scare(30, "wild-addr-write");
    } else if (signal.write_flag == SignalContext::READ) {
      scariness.Scare(20, "wild-addr-read");
    } else {
      scariness.Scare(25, "wild-addr");
    }
  }
  void Print();
};

struct ErrorDoubleFree : ErrorBase {
  // ErrorDoubleFree doesn't own the stack trace.
  const BufferedStackTrace *second_free_stack;
  HeapAddressDescription addr_description;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorDoubleFree() = default;
  ErrorDoubleFree(u32 tid, BufferedStackTrace *stack, uptr addr)
      : ErrorBase(tid), second_free_stack(stack) {
    CHECK_GT(second_free_stack->size, 0);
    GetHeapAddressInformation(addr, 1, &addr_description);
    scariness.Clear();
    scariness.Scare(42, "double-free");
  }
  void Print();
};

struct ErrorNewDeleteTypeMismatch : ErrorBase {
  // ErrorNewDeleteTypeMismatch doesn't own the stack trace.
  const BufferedStackTrace *free_stack;
  HeapAddressDescription addr_description;
  uptr delete_size;
  uptr delete_alignment;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorNewDeleteTypeMismatch() = default;
  ErrorNewDeleteTypeMismatch(u32 tid, BufferedStackTrace *stack, uptr addr,
                             uptr delete_size_, uptr delete_alignment_)
      : ErrorBase(tid), free_stack(stack), delete_size(delete_size_),
        delete_alignment(delete_alignment_) {
    GetHeapAddressInformation(addr, 1, &addr_description);
    scariness.Clear();
    scariness.Scare(10, "new-delete-type-mismatch");
  }
  void Print();
};

struct ErrorFreeNotMalloced : ErrorBase {
  // ErrorFreeNotMalloced doesn't own the stack trace.
  const BufferedStackTrace *free_stack;
  AddressDescription addr_description;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorFreeNotMalloced() = default;
  ErrorFreeNotMalloced(u32 tid, BufferedStackTrace *stack, uptr addr)
      : ErrorBase(tid),
        free_stack(stack),
        addr_description(addr, /*shouldLockThreadRegistry=*/false) {
    scariness.Clear();
    scariness.Scare(40, "bad-free");
  }
  void Print();
};

struct ErrorAllocTypeMismatch : ErrorBase {
  // ErrorAllocTypeMismatch doesn't own the stack trace.
  const BufferedStackTrace *dealloc_stack;
  HeapAddressDescription addr_description;
  AllocType alloc_type, dealloc_type;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorAllocTypeMismatch() = default;
  ErrorAllocTypeMismatch(u32 tid, BufferedStackTrace *stack, uptr addr,
                         AllocType alloc_type_, AllocType dealloc_type_)
      : ErrorBase(tid),
        dealloc_stack(stack),
        alloc_type(alloc_type_),
        dealloc_type(dealloc_type_) {
    GetHeapAddressInformation(addr, 1, &addr_description);
    scariness.Clear();
    scariness.Scare(10, "alloc-dealloc-mismatch");
  };
  void Print();
};

struct ErrorMallocUsableSizeNotOwned : ErrorBase {
  // ErrorMallocUsableSizeNotOwned doesn't own the stack trace.
  const BufferedStackTrace *stack;
  AddressDescription addr_description;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorMallocUsableSizeNotOwned() = default;
  ErrorMallocUsableSizeNotOwned(u32 tid, BufferedStackTrace *stack_, uptr addr)
      : ErrorBase(tid),
        stack(stack_),
        addr_description(addr, /*shouldLockThreadRegistry=*/false) {
    scariness.Clear();
    scariness.Scare(10, "bad-malloc_usable_size");
  }
  void Print();
};

struct ErrorSanitizerGetAllocatedSizeNotOwned : ErrorBase {
  // ErrorSanitizerGetAllocatedSizeNotOwned doesn't own the stack trace.
  const BufferedStackTrace *stack;
  AddressDescription addr_description;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorSanitizerGetAllocatedSizeNotOwned() = default;
  ErrorSanitizerGetAllocatedSizeNotOwned(u32 tid, BufferedStackTrace *stack_,
                                         uptr addr)
      : ErrorBase(tid),
        stack(stack_),
        addr_description(addr, /*shouldLockThreadRegistry=*/false) {
    scariness.Clear();
    scariness.Scare(10, "bad-__sanitizer_get_allocated_size");
  }
  void Print();
};

struct ErrorCallocOverflow : ErrorBase {
  const BufferedStackTrace *stack;
  uptr count;
  uptr size;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorCallocOverflow() = default;
  ErrorCallocOverflow(u32 tid, BufferedStackTrace *stack_, uptr count_,
                      uptr size_)
      : ErrorBase(tid, 10, "calloc-overflow"),
        stack(stack_),
        count(count_),
        size(size_) {}
  void Print();
};

struct ErrorPvallocOverflow : ErrorBase {
  const BufferedStackTrace *stack;
  uptr size;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorPvallocOverflow() = default;
  ErrorPvallocOverflow(u32 tid, BufferedStackTrace *stack_, uptr size_)
      : ErrorBase(tid, 10, "pvalloc-overflow"),
        stack(stack_),
        size(size_) {}
  void Print();
};

struct ErrorInvalidAllocationAlignment : ErrorBase {
  const BufferedStackTrace *stack;
  uptr alignment;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorInvalidAllocationAlignment() = default;
  ErrorInvalidAllocationAlignment(u32 tid, BufferedStackTrace *stack_,
                                  uptr alignment_)
      : ErrorBase(tid, 10, "invalid-allocation-alignment"),
        stack(stack_),
        alignment(alignment_) {}
  void Print();
};

struct ErrorInvalidPosixMemalignAlignment : ErrorBase {
  const BufferedStackTrace *stack;
  uptr alignment;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorInvalidPosixMemalignAlignment() = default;
  ErrorInvalidPosixMemalignAlignment(u32 tid, BufferedStackTrace *stack_,
                                     uptr alignment_)
      : ErrorBase(tid, 10, "invalid-posix-memalign-alignment"),
        stack(stack_),
        alignment(alignment_) {}
  void Print();
};

struct ErrorAllocationSizeTooBig : ErrorBase {
  const BufferedStackTrace *stack;
  uptr user_size;
  uptr total_size;
  uptr max_size;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorAllocationSizeTooBig() = default;
  ErrorAllocationSizeTooBig(u32 tid, BufferedStackTrace *stack_,
                            uptr user_size_, uptr total_size_, uptr max_size_)
      : ErrorBase(tid, 10, "allocation-size-too-big"),
        stack(stack_),
        user_size(user_size_),
        total_size(total_size_),
        max_size(max_size_) {}
  void Print();
};

struct ErrorRssLimitExceeded : ErrorBase {
  const BufferedStackTrace *stack;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorRssLimitExceeded() = default;
  ErrorRssLimitExceeded(u32 tid, BufferedStackTrace *stack_)
      : ErrorBase(tid, 10, "rss-limit-exceeded"),
        stack(stack_) {}
  void Print();
};

struct ErrorOutOfMemory : ErrorBase {
  const BufferedStackTrace *stack;
  uptr requested_size;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorOutOfMemory() = default;
  ErrorOutOfMemory(u32 tid, BufferedStackTrace *stack_, uptr requested_size_)
      : ErrorBase(tid, 10, "out-of-memory"),
        stack(stack_),
        requested_size(requested_size_) {}
  void Print();
};

struct ErrorStringFunctionMemoryRangesOverlap : ErrorBase {
  // ErrorStringFunctionMemoryRangesOverlap doesn't own the stack trace.
  const BufferedStackTrace *stack;
  uptr length1, length2;
  AddressDescription addr1_description;
  AddressDescription addr2_description;
  const char *function;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorStringFunctionMemoryRangesOverlap() = default;
  ErrorStringFunctionMemoryRangesOverlap(u32 tid, BufferedStackTrace *stack_,
                                         uptr addr1, uptr length1_, uptr addr2,
                                         uptr length2_, const char *function_)
      : ErrorBase(tid),
        stack(stack_),
        length1(length1_),
        length2(length2_),
        addr1_description(addr1, length1, /*shouldLockThreadRegistry=*/false),
        addr2_description(addr2, length2, /*shouldLockThreadRegistry=*/false),
        function(function_) {
    char bug_type[100];
    internal_snprintf(bug_type, sizeof(bug_type), "%s-param-overlap", function);
    scariness.Clear();
    scariness.Scare(10, bug_type);
  }
  void Print();
};

struct ErrorStringFunctionSizeOverflow : ErrorBase {
  // ErrorStringFunctionSizeOverflow doesn't own the stack trace.
  const BufferedStackTrace *stack;
  AddressDescription addr_description;
  uptr size;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorStringFunctionSizeOverflow() = default;
  ErrorStringFunctionSizeOverflow(u32 tid, BufferedStackTrace *stack_,
                                  uptr addr, uptr size_)
      : ErrorBase(tid),
        stack(stack_),
        addr_description(addr, /*shouldLockThreadRegistry=*/false),
        size(size_) {
    scariness.Clear();
    scariness.Scare(10, "negative-size-param");
  }
  void Print();
};

struct ErrorBadParamsToAnnotateContiguousContainer : ErrorBase {
  // ErrorBadParamsToAnnotateContiguousContainer doesn't own the stack trace.
  const BufferedStackTrace *stack;
  uptr beg, end, old_mid, new_mid;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorBadParamsToAnnotateContiguousContainer() = default;
  // PS4: Do we want an AddressDescription for beg?
  ErrorBadParamsToAnnotateContiguousContainer(u32 tid,
                                              BufferedStackTrace *stack_,
                                              uptr beg_, uptr end_,
                                              uptr old_mid_, uptr new_mid_)
      : ErrorBase(tid),
        stack(stack_),
        beg(beg_),
        end(end_),
        old_mid(old_mid_),
        new_mid(new_mid_) {
    scariness.Clear();
    scariness.Scare(10, "bad-__sanitizer_annotate_contiguous_container");
  }
  void Print();
};

struct ErrorODRViolation : ErrorBase {
  __asan_global global1, global2;
  u32 stack_id1, stack_id2;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorODRViolation() = default;
  ErrorODRViolation(u32 tid, const __asan_global *g1, u32 stack_id1_,
                    const __asan_global *g2, u32 stack_id2_)
      : ErrorBase(tid),
        global1(*g1),
        global2(*g2),
        stack_id1(stack_id1_),
        stack_id2(stack_id2_) {
    scariness.Clear();
    scariness.Scare(10, "odr-violation");
  }
  void Print();
};

struct ErrorInvalidPointerPair : ErrorBase {
  uptr pc, bp, sp;
  AddressDescription addr1_description;
  AddressDescription addr2_description;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorInvalidPointerPair() = default;
  ErrorInvalidPointerPair(u32 tid, uptr pc_, uptr bp_, uptr sp_, uptr p1,
                          uptr p2)
      : ErrorBase(tid),
        pc(pc_),
        bp(bp_),
        sp(sp_),
        addr1_description(p1, 1, /*shouldLockThreadRegistry=*/false),
        addr2_description(p2, 1, /*shouldLockThreadRegistry=*/false)  {
    scariness.Clear();
    scariness.Scare(10, "invalid-pointer-pair");
  }
  void Print();
};

struct ErrorGeneric : ErrorBase {
  AddressDescription addr_description;
  uptr pc, bp, sp;
  uptr access_size;
  const char *bug_descr;
  bool is_write;
  u8 shadow_val;
  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  ErrorGeneric() = default;
  ErrorGeneric(u32 tid, uptr addr, uptr pc_, uptr bp_, uptr sp_, bool is_write_,
               uptr access_size_);
  void Print();
};

// clang-format off
#define ASAN_FOR_EACH_ERROR_KIND(macro)         \
  macro(DeadlySignal)                           \
  macro(DoubleFree)                             \
  macro(NewDeleteTypeMismatch)                  \
  macro(FreeNotMalloced)                        \
  macro(AllocTypeMismatch)                      \
  macro(MallocUsableSizeNotOwned)               \
  macro(SanitizerGetAllocatedSizeNotOwned)      \
  macro(CallocOverflow)                         \
  macro(PvallocOverflow)                        \
  macro(InvalidAllocationAlignment)             \
  macro(InvalidPosixMemalignAlignment)          \
  macro(AllocationSizeTooBig)                   \
  macro(RssLimitExceeded)                       \
  macro(OutOfMemory)                            \
  macro(StringFunctionMemoryRangesOverlap)      \
  macro(StringFunctionSizeOverflow)             \
  macro(BadParamsToAnnotateContiguousContainer) \
  macro(ODRViolation)                           \
  macro(InvalidPointerPair)                     \
  macro(Generic)
// clang-format on

#define ASAN_DEFINE_ERROR_KIND(name) kErrorKind##name,
#define ASAN_ERROR_DESCRIPTION_MEMBER(name) Error##name name;
#define ASAN_ERROR_DESCRIPTION_CONSTRUCTOR(name) \
  ErrorDescription(Error##name const &e) : kind(kErrorKind##name), name(e) {}
#define ASAN_ERROR_DESCRIPTION_PRINT(name) \
  case kErrorKind##name:                   \
    return name.Print();

enum ErrorKind {
  kErrorKindInvalid = 0,
  ASAN_FOR_EACH_ERROR_KIND(ASAN_DEFINE_ERROR_KIND)
};

struct ErrorDescription {
  ErrorKind kind;
  // We're using a tagged union because it allows us to have a trivially
  // copiable type and use the same structures as the public interface.
  //
  // We can add a wrapper around it to make it "more c++-like", but that would
  // add a lot of code and the benefit wouldn't be that big.
  union {
    ErrorBase Base;
    ASAN_FOR_EACH_ERROR_KIND(ASAN_ERROR_DESCRIPTION_MEMBER)
  };

  ErrorDescription() { internal_memset(this, 0, sizeof(*this)); }
  ASAN_FOR_EACH_ERROR_KIND(ASAN_ERROR_DESCRIPTION_CONSTRUCTOR)

  bool IsValid() { return kind != kErrorKindInvalid; }
  void Print() {
    switch (kind) {
      ASAN_FOR_EACH_ERROR_KIND(ASAN_ERROR_DESCRIPTION_PRINT)
      case kErrorKindInvalid:
        CHECK(0);
    }
    CHECK(0);
  }
};

#undef ASAN_FOR_EACH_ERROR_KIND
#undef ASAN_DEFINE_ERROR_KIND
#undef ASAN_ERROR_DESCRIPTION_MEMBER
#undef ASAN_ERROR_DESCRIPTION_CONSTRUCTOR
#undef ASAN_ERROR_DESCRIPTION_PRINT

}  // namespace __asan

#endif  // ASAN_ERRORS_H
