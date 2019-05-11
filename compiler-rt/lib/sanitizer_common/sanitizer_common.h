//===-- sanitizer_common.h --------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is shared between run-time libraries of sanitizers.
//
// It declares common functions and classes that are used in both runtimes.
// Implementation of some functions are provided in sanitizer_common, while
// others must be defined by run-time library itself.
//===----------------------------------------------------------------------===//
#ifndef SANITIZER_COMMON_H
#define SANITIZER_COMMON_H

#include "sanitizer_flags.h"
#include "sanitizer_interface_internal.h"
#include "sanitizer_internal_defs.h"
#include "sanitizer_libc.h"
#include "sanitizer_list.h"
#include "sanitizer_mutex.h"

#if defined(_MSC_VER) && !defined(__clang__)
extern "C" void _ReadWriteBarrier();
#pragma intrinsic(_ReadWriteBarrier)
#endif

namespace __sanitizer {

struct AddressInfo;
struct BufferedStackTrace;
struct SignalContext;
struct StackTrace;

// Constants.
const uptr kWordSize = SANITIZER_WORDSIZE / 8;
const uptr kWordSizeInBits = 8 * kWordSize;

const uptr kCacheLineSize = SANITIZER_CACHE_LINE_SIZE;

const uptr kMaxPathLength = 4096;

const uptr kMaxThreadStackSize = 1 << 30;  // 1Gb

static const uptr kErrorMessageBufferSize = 1 << 16;

// Denotes fake PC values that come from JIT/JAVA/etc.
// For such PC values __tsan_symbolize_external_ex() will be called.
const u64 kExternalPCBit = 1ULL << 60;

extern const char *SanitizerToolName;  // Can be changed by the tool.

extern atomic_uint32_t current_verbosity;
INLINE void SetVerbosity(int verbosity) {
  atomic_store(&current_verbosity, verbosity, memory_order_relaxed);
}
INLINE int Verbosity() {
  return atomic_load(&current_verbosity, memory_order_relaxed);
}

#if SANITIZER_ANDROID
INLINE usize GetPageSize() {
// Android post-M sysconf(_SC_PAGESIZE) crashes if called from .preinit_array.
  return 4096;
}
INLINE usize GetPageSizeCached() {
  return 4096;
}
#else
usize GetPageSize();
extern usize PageSizeCached;
INLINE usize GetPageSizeCached() {
  if (!PageSizeCached)
    PageSizeCached = GetPageSize();
  return PageSizeCached;
}
#endif
usize GetMmapGranularity();
vaddr GetMaxVirtualAddress();
vaddr GetMaxUserVirtualAddress();
// Threads
tid_t GetTid();
int TgKill(pid_t pid, tid_t tid, int sig);
uptr GetThreadSelf();
void GetThreadStackTopAndBottom(bool at_initialization, uptr *stack_top,
                                uptr *stack_bottom);
void GetThreadStackAndTls(bool main, uptr *stk_addr, usize *stk_size,
                          uptr *tls_addr, usize *tls_size);

// Memory management
void *MmapOrDie(usize size, const char *mem_type, bool raw_report = false);
INLINE void *MmapOrDieQuietly(usize size, const char *mem_type) {
  return MmapOrDie(size, mem_type, /*raw_report*/ true);
}
void UnmapOrDie(void *addr, usize size);
// Behaves just like MmapOrDie, but tolerates out of memory condition, in that
// case returns nullptr.
void *MmapOrDieOnFatalError(usize size, const char *mem_type);
bool MmapFixedNoReserve(uptr fixed_addr, usize size, const char *name = nullptr)
     WARN_UNUSED_RESULT;
void *MmapNoReserveOrDie(usize size, const char *mem_type);
void *MmapFixedOrDie(uptr fixed_addr, usize size, const char *name = nullptr);
// Behaves just like MmapFixedOrDie, but tolerates out of memory condition, in
// that case returns nullptr.
void *MmapFixedOrDieOnFatalError(uptr fixed_addr, usize size,
                                 const char *name = nullptr);
void *MmapFixedNoAccess(uptr fixed_addr, usize size, const char *name = nullptr);
void *MmapNoAccess(usize size);
// Map aligned chunk of address space; size and alignment are powers of two.
// Dies on all but out of memory errors, in the latter case returns nullptr.
void *MmapAlignedOrDieOnFatalError(usize size, usize alignment,
                                   const char *mem_type);
// Disallow access to a memory range.  Use MmapFixedNoAccess to allocate an
// unaccessible memory.
bool MprotectNoAccess(uptr addr, usize size);
bool MprotectReadOnly(uptr addr, usize size);

void MprotectMallocZones(void *addr, int prot);

// Find an available address space.
uptr FindAvailableMemoryRange(usize size, usize alignment, usize left_padding,
                              uptr *largest_gap_found, uptr *max_occupied_addr);

// Used to check if we can map shadow memory to a fixed location.
bool MemoryRangeIsAvailable(uptr range_start, uptr range_end);
// Releases memory pages entirely within the [beg, end] address range. Noop if
// the provided range does not contain at least one entire page.
void ReleaseMemoryPagesToOS(uptr beg, uptr end);
void IncreaseTotalMmap(usize size);
void DecreaseTotalMmap(usize size);
usize GetRSS();
bool NoHugePagesInRegion(uptr addr, usize length);
bool DontDumpShadowMemory(uptr addr, usize length);
// Check if the built VMA size matches the runtime one.
void CheckVMASize();
void RunMallocHooks(const void *ptr, usize size);
void RunFreeHooks(const void *ptr);

class ReservedAddressRange {
 public:
  uptr Init(usize size, const char *name = nullptr, uptr fixed_addr = 0);
  uptr Map(uptr fixed_addr, usize size, const char *name = nullptr);
  uptr MapOrDie(uptr fixed_addr, usize size, const char *name = nullptr);
  void Unmap(uptr addr, usize size);
  void *base() const { return base_; }
  usize size() const { return size_; }

 private:
  void* base_;
  usize size_;
  const char* name_;
  uptr os_handle_;
};

typedef void (*fill_profile_f)(uptr start, usize rss, bool file,
                               /*out*/usize *stats, usize stats_size);

// Parse the contents of /proc/self/smaps and generate a memory profile.
// |cb| is a tool-specific callback that fills the |stats| array containing
// |stats_size| elements.
void GetMemoryProfile(fill_profile_f cb, usize *stats, usize stats_size);

// Simple low-level (mmap-based) allocator for internal use. Doesn't have
// constructor, so all instances of LowLevelAllocator should be
// linker initialized.
class LowLevelAllocator {
 public:
  // Requires an external lock.
  void *Allocate(usize size);
 private:
  char *allocated_end_;
  char *allocated_current_;
};
// Set the min alignment of LowLevelAllocator to at least alignment.
void SetLowLevelAllocateMinAlignment(usize alignment);
typedef void (*LowLevelAllocateCallback)(uptr ptr, usize size);
// Allows to register tool-specific callbacks for LowLevelAllocator.
// Passing NULL removes the callback.
void SetLowLevelAllocateCallback(LowLevelAllocateCallback callback);

// IO
void CatastrophicErrorWrite(const char *buffer, usize length);
void RawWrite(const char *buffer);
bool ColorizeReports();
void RemoveANSIEscapeSequencesFromString(char *buffer);
void Printf(const char *format, ...);
void Report(const char *format, ...);
void SetPrintfAndReportCallback(void (*callback)(const char *));
#define VReport(level, ...)                                              \
  do {                                                                   \
    if ((usize)Verbosity() >= (level)) Report(__VA_ARGS__); \
  } while (0)
#define VPrintf(level, ...)                                              \
  do {                                                                   \
    if ((usize)Verbosity() >= (level)) Printf(__VA_ARGS__); \
  } while (0)

// Lock sanitizer error reporting and protects against nested errors.
class ScopedErrorReportLock {
 public:
  ScopedErrorReportLock();
  ~ScopedErrorReportLock();

  static void CheckLocked();
};

extern pid_t stoptheworld_tracer_pid;
extern pid_t stoptheworld_tracer_ppid;

bool IsAccessibleMemoryRange(uptr beg, usize size);

// Error report formatting.
const char *StripPathPrefix(const char *filepath,
                            const char *strip_file_prefix);
// Strip the directories from the module name.
const char *StripModuleName(const char *module);

// OS
usize ReadBinaryName(/*out*/char *buf, usize buf_len);
usize ReadBinaryNameCached(/*out*/char *buf, usize buf_len);
usize ReadLongProcessName(/*out*/ char *buf, usize buf_len);
const char *GetProcessName();
void UpdateProcessName();
void CacheBinaryName();
void DisableCoreDumperIfNecessary();
void DumpProcessMap();
void PrintModuleMap();
const char *GetEnv(const char *name);
bool SetEnv(const char *name, const char *value);

u32 GetUid();
void ReExec();
void CheckASLR();
void CheckMPROTECT();
char **GetArgv();
char **GetEnviron();
void PrintCmdline();
bool StackSizeIsUnlimited();
void SetStackSizeLimitInBytes(usize limit);
bool AddressSpaceIsUnlimited();
void SetAddressSpaceUnlimited();
void AdjustStackSize(void *attr);
void PlatformPrepareForSandboxing(__sanitizer_sandbox_arguments *args);
void SetSandboxingCallback(void (*f)());

void InitializeCoverage(bool enabled, const char *coverage_dir);

void InitTlsSize();
usize GetTlsSize();

// Other
void SleepForSeconds(int seconds);
void SleepForMillis(int millis);
u64 NanoTime();
u64 MonotonicNanoTime();
int Atexit(void (*function)(void));
bool TemplateMatch(const char *templ, const char *str);

// Exit
void NORETURN Abort();
void NORETURN Die();
void NORETURN
CheckFailed(const char *file, int line, const char *cond, u64 v1, u64 v2);
void NORETURN ReportMmapFailureAndDie(usize size, const char *mem_type,
                                      const char *mmap_type, error_t err,
                                      bool raw_report = false);

// Specific tools may override behavior of "Die" and "CheckFailed" functions
// to do tool-specific job.
typedef void (*DieCallbackType)(void);

// It's possible to add several callbacks that would be run when "Die" is
// called. The callbacks will be run in the opposite order. The tools are
// strongly recommended to setup all callbacks during initialization, when there
// is only a single thread.
bool AddDieCallback(DieCallbackType callback);
bool RemoveDieCallback(DieCallbackType callback);

void SetUserDieCallback(DieCallbackType callback);

typedef void (*CheckFailedCallbackType)(const char *, int, const char *,
                                       u64, u64);
void SetCheckFailedCallback(CheckFailedCallbackType callback);

// Callback will be called if soft_rss_limit_mb is given and the limit is
// exceeded (exceeded==true) or if rss went down below the limit
// (exceeded==false).
// The callback should be registered once at the tool init time.
void SetSoftRssLimitExceededCallback(void (*Callback)(bool exceeded));

// Functions related to signal handling.
typedef void (*SignalHandlerType)(int, void *, void *);
HandleSignalMode GetHandleSignalMode(int signum);
void InstallDeadlySignalHandlers(SignalHandlerType handler);

// Signal reporting.
// Each sanitizer uses slightly different implementation of stack unwinding.
typedef void (*UnwindSignalStackCallbackType)(const SignalContext &sig,
                                              const void *callback_context,
                                              BufferedStackTrace *stack);
// Print deadly signal report and die.
void HandleDeadlySignal(void *siginfo, void *context, u32 tid,
                        UnwindSignalStackCallbackType unwind,
                        const void *unwind_context);

// Part of HandleDeadlySignal, exposed for asan.
void StartReportDeadlySignal();
// Part of HandleDeadlySignal, exposed for asan.
void ReportDeadlySignal(const SignalContext &sig, u32 tid,
                        UnwindSignalStackCallbackType unwind,
                        const void *unwind_context);

// Alternative signal stack (POSIX-only).
void SetAlternateSignalStack();
void UnsetAlternateSignalStack();

// We don't want a summary too long.
const int kMaxSummaryLength = 1024;
// Construct a one-line string:
//   SUMMARY: SanitizerToolName: error_message
// and pass it to __sanitizer_report_error_summary.
// If alt_tool_name is provided, it's used in place of SanitizerToolName.
void ReportErrorSummary(const char *error_message,
                        const char *alt_tool_name = nullptr);
// Same as above, but construct error_message as:
//   error_type file:line[:column][ function]
void ReportErrorSummary(const char *error_type, const AddressInfo &info,
                        const char *alt_tool_name = nullptr);
// Same as above, but obtains AddressInfo by symbolizing top stack trace frame.
void ReportErrorSummary(const char *error_type, const StackTrace *trace,
                        const char *alt_tool_name = nullptr);

void ReportMmapWriteExec(int prot);

// Math
#if SANITIZER_WINDOWS && !defined(__clang__) && !defined(__GNUC__)
extern "C" {
unsigned char _BitScanForward(unsigned long *index, unsigned long mask);  // NOLINT
unsigned char _BitScanReverse(unsigned long *index, unsigned long mask);  // NOLINT
#if defined(_WIN64)
unsigned char _BitScanForward64(unsigned long *index, unsigned __int64 mask);  // NOLINT
unsigned char _BitScanReverse64(unsigned long *index, unsigned __int64 mask);  // NOLINT
#endif
}
#endif

INLINE usize MostSignificantSetBitIndex(usize x) {
  CHECK_NE(x, 0U);
  unsigned long up;  // NOLINT
#if !SANITIZER_WINDOWS || defined(__clang__) || defined(__GNUC__)
# ifdef _WIN64
  up = SANITIZER_WORDSIZE - 1 - __builtin_clzll(x);
# else
  up = SANITIZER_WORDSIZE - 1 - __builtin_clzl(x);
# endif
#elif defined(_WIN64)
  _BitScanReverse64(&up, x);
#else
  _BitScanReverse(&up, x);
#endif
  return up;
}
#ifdef __CHERI_PURE_CAPABILITY__
usize MostSignificantSetBitIndex(uptr x) = delete;
INLINE usize MostSignificantSetBitIndex(u64 x) {
  return MostSignificantSetBitIndex((usize)x);
}
#endif

INLINE usize LeastSignificantSetBitIndex(usize x) {
  CHECK_NE(x, 0U);
  unsigned long up;  // NOLINT
#if !SANITIZER_WINDOWS || defined(__clang__) || defined(__GNUC__)
# ifdef _WIN64
  up = __builtin_ctzll(x);
# else
  up = __builtin_ctzl(x);
# endif
#elif defined(_WIN64)
  _BitScanForward64(&up, x);
#else
  _BitScanForward(&up, x);
#endif
  return up;
}
#ifdef __CHERI_PURE_CAPABILITY__
usize LeastSignificantSetBitIndex(uptr x) = delete;
INLINE usize LeastSignificantSetBitIndex(u64 x) {
  return LeastSignificantSetBitIndex((usize)x);
}
#endif

INLINE bool IsPowerOfTwo(u64 x) {
  return (x & (x - 1)) == 0;
}
#ifdef __CHERI_PURE_CAPABILITY__
bool IsPowerOfTwo(uptr x) = delete;
INLINE bool IsPowerOfTwo(usize x) {
  return IsPowerOfTwo((u64)x);
}
#endif

INLINE u64 RoundUpToPowerOfTwo(u64 size) {
  CHECK(size);
  if (IsPowerOfTwo(size)) return size;

  usize up = MostSignificantSetBitIndex(size);
  CHECK_LT(size, (1ULL << (up + 1)));
  CHECK_GT(size, (1ULL << up));
  return 1ULL << (up + 1);
}
#ifdef __CHERI_PURE_CAPABILITY__
uptr RoundUpToPowerOfTwo(uptr size) = delete;
INLINE usize RoundUpToPowerOfTwo(usize x) {
  return (usize)RoundUpToPowerOfTwo((u64)x);
}
#endif

INLINE uptr RoundUpTo(uptr p, usize boundary) {
  RAW_CHECK(IsPowerOfTwo(boundary));
#if __has_builtin(__builtin_align_up)
  return __builtin_align_up(p, boundary);
#else
  return (p + boundary - 1) & ~(boundary - 1);
#endif
}
template <typename T>
INLINE T *RoundUpTo(T *p, usize boundary) {
  RAW_CHECK(IsPowerOfTwo(boundary));
#if __has_builtin(__builtin_align_up)
  return __builtin_align_up(p, boundary);
#else
  return (T *)RoundUpTo((uptr)p, boundary);
#endif
}

INLINE uptr RoundDownTo(uptr x, usize boundary) {
#if __has_builtin(__builtin_align_down)
  return __builtin_align_down(x, boundary);
#else
  return x & ~(boundary - 1);
#endif
}
template <typename T>
INLINE T *RoundDownTo(T *p, usize boundary) {
  RAW_CHECK(IsPowerOfTwo(boundary));
#if __has_builtin(__builtin_align_down)
  return __builtin_align_down(p, boundary);
#else
  return (T *)RoundDownTo((uptr)p, boundary);
#endif
}

INLINE bool IsAligned(uptr a, usize alignment) {
#if __has_builtin(__builtin_is_aligned)
  return __builtin_is_aligned(a, alignment);
#else
  return (a & (alignment - 1)) == 0;
#endif
}

INLINE bool IsAligned(const void *ptr, usize alignment) {
  return IsAligned((uptr)ptr, alignment);
}

INLINE u64 Log2(u64 x) {
  CHECK(IsPowerOfTwo(x));
  return LeastSignificantSetBitIndex(x);
}
#ifdef __CHERI_PURE_CAPABILITY__
uptr Log2(uptr x) = delete;
INLINE usize Log2(usize x) {
  return (usize)Log2((u64)x);
}
#endif

// Don't use std::min, std::max or std::swap, to minimize dependency
// on libstdc++.
template<class T> T Min(T a, T b) { return a < b ? a : b; }
template<class T> constexpr T Max(T a, T b) { return a > b ? a : b; }
template<class T> void Swap(T& a, T& b) {
  T tmp = a;
  a = b;
  b = tmp;
}

// Char handling
INLINE bool IsSpace(int c) {
  return (c == ' ') || (c == '\n') || (c == '\t') ||
         (c == '\f') || (c == '\r') || (c == '\v');
}
INLINE bool IsDigit(int c) {
  return (c >= '0') && (c <= '9');
}
INLINE int ToLower(int c) {
  return (c >= 'A' && c <= 'Z') ? (c + 'a' - 'A') : c;
}

// A low-level vector based on mmap. May incur a significant memory overhead for
// small vectors.
// WARNING: The current implementation supports only POD types.
template<typename T>
class InternalMmapVectorNoCtor {
 public:
  void Initialize(usize initial_capacity) {
    capacity_bytes_ = 0;
    size_ = 0;
    data_ = 0;
    reserve(initial_capacity);
  }
  void Destroy() { UnmapOrDie(data_, capacity_bytes_); }
  T &operator[](usize i) {
    CHECK_LT(i, size_);
    return data_[i];
  }
  const T &operator[](usize i) const {
    CHECK_LT(i, size_);
    return data_[i];
  }
  void push_back(const T &element) {
    CHECK_LE(size_, capacity());
    if (size_ == capacity()) {
      usize new_capacity = RoundUpToPowerOfTwo(size_ + 1);
      Realloc(new_capacity);
    }
    internal_memcpy(&data_[size_++], &element, sizeof(T));
  }
  T &back() {
    CHECK_GT(size_, 0);
    return data_[size_ - 1];
  }
  void pop_back() {
    CHECK_GT(size_, 0);
    size_--;
  }
  usize size() const {
    return size_;
  }
  const T *data() const {
    return data_;
  }
  T *data() {
    return data_;
  }
  usize capacity() const { return capacity_bytes_ / sizeof(T); }
  void reserve(usize new_size) {
    // Never downsize internal buffer.
    if (new_size > capacity())
      Realloc(new_size);
  }
  void resize(usize new_size) {
    if (new_size > size_) {
      reserve(new_size);
      internal_memset(&data_[size_], 0, sizeof(T) * (new_size - size_));
    }
    size_ = new_size;
  }

  void clear() { size_ = 0; }
  bool empty() const { return size() == 0; }

  const T *begin() const {
    return data();
  }
  T *begin() {
    return data();
  }
  const T *end() const {
    return data() + size();
  }
  T *end() {
    return data() + size();
  }

  void swap(InternalMmapVectorNoCtor &other) {
    Swap(data_, other.data_);
    Swap(capacity_bytes_, other.capacity_bytes_);
    Swap(size_, other.size_);
  }

 private:
  void Realloc(usize new_capacity) {
    CHECK_GT(new_capacity, 0);
    CHECK_LE(size_, new_capacity);
    usize new_capacity_bytes =
        RoundUpTo(new_capacity * sizeof(T), GetPageSizeCached());
    T *new_data = (T *)MmapOrDie(new_capacity_bytes, "InternalMmapVector");
    internal_memcpy(new_data, data_, size_ * sizeof(T));
    UnmapOrDie(data_, capacity_bytes_);
    data_ = new_data;
    capacity_bytes_ = new_capacity_bytes;
  }

  T *data_;
  usize capacity_bytes_;
  usize size_;
};

template <typename T>
bool operator==(const InternalMmapVectorNoCtor<T> &lhs,
                const InternalMmapVectorNoCtor<T> &rhs) {
  if (lhs.size() != rhs.size()) return false;
  return internal_memcmp(lhs.data(), rhs.data(), lhs.size() * sizeof(T)) == 0;
}

template <typename T>
bool operator!=(const InternalMmapVectorNoCtor<T> &lhs,
                const InternalMmapVectorNoCtor<T> &rhs) {
  return !(lhs == rhs);
}

template<typename T>
class InternalMmapVector : public InternalMmapVectorNoCtor<T> {
 public:
  InternalMmapVector() { InternalMmapVectorNoCtor<T>::Initialize(1); }
  explicit InternalMmapVector(usize cnt) {
    InternalMmapVectorNoCtor<T>::Initialize(cnt);
    this->resize(cnt);
  }
  ~InternalMmapVector() { InternalMmapVectorNoCtor<T>::Destroy(); }
  // Disallow copies and moves.
  InternalMmapVector(const InternalMmapVector &) = delete;
  InternalMmapVector &operator=(const InternalMmapVector &) = delete;
  InternalMmapVector(InternalMmapVector &&) = delete;
  InternalMmapVector &operator=(InternalMmapVector &&) = delete;
};

class InternalScopedString : public InternalMmapVector<char> {
 public:
  explicit InternalScopedString(usize max_length)
      : InternalMmapVector<char>(max_length), length_(0) {
    (*this)[0] = '\0';
  }
  usize length() { return length_; }
  void clear() {
    (*this)[0] = '\0';
    length_ = 0;
  }
  void append(const char *format, ...);

 private:
  usize length_;
};

template <class T>
struct CompareLess {
  bool operator()(const T &a, const T &b) const { return a < b; }
};

// HeapSort for arrays and InternalMmapVector.
template <class T, class Compare = CompareLess<T>>
void Sort(T *v, usize size, Compare comp = {}) {
  if (size < 2)
    return;
  // Stage 1: insert elements to the heap.
  for (usize i = 1; i < size; i++) {
    usize j, p;
    for (j = i; j > 0; j = p) {
      p = (j - 1) / 2;
      if (comp(v[p], v[j]))
        Swap(v[j], v[p]);
      else
        break;
    }
  }
  // Stage 2: swap largest element with the last one,
  // and sink the new top.
  for (usize i = size - 1; i > 0; i--) {
    Swap(v[0], v[i]);
    usize j, max_ind;
    for (j = 0; j < i; j = max_ind) {
      usize left = 2 * j + 1;
      usize right = 2 * j + 2;
      max_ind = j;
      if (left < i && comp(v[max_ind], v[left]))
        max_ind = left;
      if (right < i && comp(v[max_ind], v[right]))
        max_ind = right;
      if (max_ind != j)
        Swap(v[j], v[max_ind]);
      else
        break;
    }
  }
}

// Works like std::lower_bound: finds the first element that is not less
// than the val.
template <class Container, class Value, class Compare>
usize InternalLowerBound(const Container &v, usize first, usize last,
                        const Value &val, Compare comp) {
  while (last > first) {
    usize mid = (first + last) / 2;
    if (comp(v[mid], val))
      first = mid + 1;
    else
      last = mid;
  }
  return first;
}

enum ModuleArch {
  kModuleArchUnknown,
  kModuleArchI386,
  kModuleArchX86_64,
  kModuleArchX86_64H,
  kModuleArchARMV6,
  kModuleArchARMV7,
  kModuleArchARMV7S,
  kModuleArchARMV7K,
  kModuleArchARM64
};

// Opens the file 'file_name" and reads up to 'max_len' bytes.
// The resulting buffer is mmaped and stored in '*buff'.
// Returns true if file was successfully opened and read.
bool ReadFileToVector(const char *file_name,
                      InternalMmapVectorNoCtor<char> *buff,
                      usize max_len = 1 << 26, error_t *errno_p = nullptr);

// Opens the file 'file_name" and reads up to 'max_len' bytes.
// This function is less I/O efficient than ReadFileToVector as it may reread
// file multiple times to avoid mmap during read attempts. It's used to read
// procmap, so short reads with mmap in between can produce inconsistent result.
// The resulting buffer is mmaped and stored in '*buff'.
// The size of the mmaped region is stored in '*buff_size'.
// The total number of read bytes is stored in '*read_len'.
// Returns true if file was successfully opened and read.
bool ReadFileToBuffer(const char *file_name, char **buff, usize *buff_size,
                      usize *read_len, usize max_len = 1 << 26,
                      error_t *errno_p = nullptr);

// When adding a new architecture, don't forget to also update
// script/asan_symbolize.py and sanitizer_symbolizer_libcdep.cc.
inline const char *ModuleArchToString(ModuleArch arch) {
  switch (arch) {
    case kModuleArchUnknown:
      return "";
    case kModuleArchI386:
      return "i386";
    case kModuleArchX86_64:
      return "x86_64";
    case kModuleArchX86_64H:
      return "x86_64h";
    case kModuleArchARMV6:
      return "armv6";
    case kModuleArchARMV7:
      return "armv7";
    case kModuleArchARMV7S:
      return "armv7s";
    case kModuleArchARMV7K:
      return "armv7k";
    case kModuleArchARM64:
      return "arm64";
  }
  CHECK(0 && "Invalid module arch");
  return "";
}

const usize kModuleUUIDSize = 16;
const usize kMaxSegName = 16;

// Represents a binary loaded into virtual memory (e.g. this can be an
// executable or a shared object).
class LoadedModule {
 public:
  LoadedModule()
      : full_name_(nullptr),
        base_address_(0),
        max_executable_address_(0),
        arch_(kModuleArchUnknown),
        instrumented_(false) {
    internal_memset(uuid_, 0, kModuleUUIDSize);
    ranges_.clear();
  }
  void set(const char *module_name, uptr base_address);
  void set(const char *module_name, uptr base_address, ModuleArch arch,
           u8 uuid[kModuleUUIDSize], bool instrumented);
  void clear();
  void addAddressRange(uptr beg, uptr end, bool executable, bool writable,
                       const char *name = nullptr);
  bool containsAddress(uptr address) const;

  const char *full_name() const { return full_name_; }
  uptr base_address() const { return base_address_; }
  uptr max_executable_address() const { return max_executable_address_; }
  ModuleArch arch() const { return arch_; }
  const u8 *uuid() const { return uuid_; }
  bool instrumented() const { return instrumented_; }

  struct AddressRange {
    AddressRange *next;
    uptr beg;
    uptr end;
    bool executable;
    bool writable;
    char name[kMaxSegName];

    AddressRange(uptr beg, uptr end, bool executable, bool writable,
                 const char *name)
        : next(nullptr),
          beg(beg),
          end(end),
          executable(executable),
          writable(writable) {
      internal_strncpy(this->name, (name ? name : ""), ARRAY_SIZE(this->name));
    }
  };

  const IntrusiveList<AddressRange> &ranges() const { return ranges_; }

 private:
  char *full_name_;  // Owned.
  uptr base_address_;
  uptr max_executable_address_;
  ModuleArch arch_;
  u8 uuid_[kModuleUUIDSize];
  bool instrumented_;
  IntrusiveList<AddressRange> ranges_;
};

// List of LoadedModules. OS-dependent implementation is responsible for
// filling this information.
class ListOfModules {
 public:
  ListOfModules() : initialized(false) {}
  ~ListOfModules() { clear(); }
  void init();
  void fallbackInit();  // Uses fallback init if available, otherwise clears
  const LoadedModule *begin() const { return modules_.begin(); }
  LoadedModule *begin() { return modules_.begin(); }
  const LoadedModule *end() const { return modules_.end(); }
  LoadedModule *end() { return modules_.end(); }
  usize size() const { return modules_.size(); }
  const LoadedModule &operator[](usize i) const {
    CHECK_LT(i, modules_.size());
    return modules_[i];
  }

 private:
  void clear() {
    for (auto &module : modules_) module.clear();
    modules_.clear();
  }
  void clearOrInit() {
    initialized ? clear() : modules_.Initialize(kInitialCapacity);
    initialized = true;
  }

  InternalMmapVectorNoCtor<LoadedModule> modules_;
  // We rarely have more than 16K loaded modules.
  static const usize kInitialCapacity = 1 << 14;
  bool initialized;
};

// Callback type for iterating over a set of memory ranges.
typedef void (*RangeIteratorCallback)(uptr begin, uptr end, void *arg);

enum AndroidApiLevel {
  ANDROID_NOT_ANDROID = 0,
  ANDROID_KITKAT = 19,
  ANDROID_LOLLIPOP_MR1 = 22,
  ANDROID_POST_LOLLIPOP = 23
};

void WriteToSyslog(const char *buffer);

#if defined(SANITIZER_WINDOWS) && defined(_MSC_VER) && !defined(__clang__)
#define SANITIZER_WIN_TRACE 1
#else
#define SANITIZER_WIN_TRACE 0
#endif

#if SANITIZER_MAC || SANITIZER_WIN_TRACE
void LogFullErrorReport(const char *buffer);
#else
INLINE void LogFullErrorReport(const char *buffer) {}
#endif

#if SANITIZER_LINUX || SANITIZER_MAC
void WriteOneLineToSyslog(const char *s);
void LogMessageOnPrintf(const char *str);
#else
INLINE void WriteOneLineToSyslog(const char *s) {}
INLINE void LogMessageOnPrintf(const char *str) {}
#endif

#if SANITIZER_LINUX || SANITIZER_WIN_TRACE
// Initialize Android logging. Any writes before this are silently lost.
void AndroidLogInit();
void SetAbortMessage(const char *);
#else
INLINE void AndroidLogInit() {}
// FIXME: MacOS implementation could use CRSetCrashLogMessage.
INLINE void SetAbortMessage(const char *) {}
#endif

#if SANITIZER_ANDROID
void SanitizerInitializeUnwinder();
AndroidApiLevel AndroidGetApiLevel();
#else
INLINE void AndroidLogWrite(const char *buffer_unused) {}
INLINE void SanitizerInitializeUnwinder() {}
INLINE AndroidApiLevel AndroidGetApiLevel() { return ANDROID_NOT_ANDROID; }
#endif

INLINE usize GetPthreadDestructorIterations() {
#if SANITIZER_ANDROID
  return (AndroidGetApiLevel() == ANDROID_LOLLIPOP_MR1) ? 8 : 4;
#elif SANITIZER_POSIX
  return 4;
#else
// Unused on Windows.
  return 0;
#endif
}

void *internal_start_thread(void(*func)(void*), void *arg);
void internal_join_thread(void *th);
void MaybeStartBackgroudThread();

// Make the compiler think that something is going on there.
// Use this inside a loop that looks like memset/memcpy/etc to prevent the
// compiler from recognising it and turning it into an actual call to
// memset/memcpy/etc.
static inline void SanitizerBreakOptimization(void *arg) {
#if defined(_MSC_VER) && !defined(__clang__)
  _ReadWriteBarrier();
#else
  __asm__ __volatile__("" : : "r" (arg) : "memory");
#endif
}

struct SignalContext {
  void *siginfo;
  void *context;
  uptr addr;
  uptr pc;
  uptr sp;
  uptr bp;
  bool is_memory_access;
  enum WriteFlag { UNKNOWN, READ, WRITE } write_flag;

  // VS2013 doesn't implement unrestricted unions, so we need a trivial default
  // constructor
  SignalContext() = default;

  // Creates signal context in a platform-specific manner.
  // SignalContext is going to keep pointers to siginfo and context without
  // owning them.
  SignalContext(void *siginfo, void *context)
      : siginfo(siginfo),
        context(context),
        addr(GetAddress()),
        is_memory_access(IsMemoryAccess()),
        write_flag(GetWriteFlag()) {
    InitPcSpBp();
  }

  static void DumpAllRegisters(void *context);

  // Type of signal e.g. SIGSEGV or EXCEPTION_ACCESS_VIOLATION.
  int GetType() const;

  // String description of the signal.
  const char *Describe() const;

  // Returns true if signal is stack overflow.
  bool IsStackOverflow() const;

 private:
  // Platform specific initialization.
  void InitPcSpBp();
  uptr GetAddress() const;
  WriteFlag GetWriteFlag() const;
  bool IsMemoryAccess() const;
};

void InitializePlatformEarly();
void MaybeReexec();

template <typename Fn>
class RunOnDestruction {
 public:
  explicit RunOnDestruction(Fn fn) : fn_(fn) {}
  ~RunOnDestruction() { fn_(); }

 private:
  Fn fn_;
};

// A simple scope guard. Usage:
// auto cleanup = at_scope_exit([]{ do_cleanup; });
template <typename Fn>
RunOnDestruction<Fn> at_scope_exit(Fn fn) {
  return RunOnDestruction<Fn>(fn);
}

// Linux on 64-bit s390 had a nasty bug that crashes the whole machine
// if a process uses virtual memory over 4TB (as many sanitizers like
// to do).  This function will abort the process if running on a kernel
// that looks vulnerable.
#if SANITIZER_LINUX && SANITIZER_S390_64
void AvoidCVE_2016_2143();
#else
INLINE void AvoidCVE_2016_2143() {}
#endif

struct StackDepotStats {
  usize n_uniq_ids;
  usize allocated;
};

// The default value for allocator_release_to_os_interval_ms common flag to
// indicate that sanitizer allocator should not attempt to release memory to OS.
const s32 kReleaseToOSIntervalNever = -1;

void CheckNoDeepBind(const char *filename, int flag);

// Returns the requested amount of random data (up to 256 bytes) that can then
// be used to seed a PRNG. Defaults to blocking like the underlying syscall.
bool GetRandom(void *buffer, usize length, bool blocking = true);

// Returns the number of logical processors on the system.
u32 GetNumberOfCPUs();
extern u32 NumberOfCPUsCached;
INLINE u32 GetNumberOfCPUsCached() {
  if (!NumberOfCPUsCached)
    NumberOfCPUsCached = GetNumberOfCPUs();
  return NumberOfCPUsCached;
}

}  // namespace __sanitizer

inline void *operator new(__sanitizer::operator_new_size_type size,
                          __sanitizer::LowLevelAllocator &alloc) {
  return alloc.Allocate(size);
}

#endif  // SANITIZER_COMMON_H
