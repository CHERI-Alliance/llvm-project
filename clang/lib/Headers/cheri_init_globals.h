/*===---- cheri_init_globals.h - Utility function to initialize global
 *                               capabilities in the c startup code
 *
 * Copyright (c) 2017 Alex Richardson
 * Copyright (c) 2014 Robert N. M. Watson
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
\*===----------------------------------------------------------------------===*/

// FIXME: this shouldn't be here
#pragma once
#if !__has_feature(capabilities)
#error "This header requires CHERI capability support"
#endif

struct capreloc {
    __UINT64_TYPE__ capability_location;
    __UINT64_TYPE__ object;
    __UINT64_TYPE__ offset;
    __UINT64_TYPE__ size;
    __UINT64_TYPE__ permissions;
};
static const __UINT64_TYPE__ function_reloc_flag = 1ULL << 63;
static const __UINT64_TYPE__ function_pointer_permissions =
  ~0 &
  ~__CHERI_CAP_PERMISSION_PERMIT_STORE_CAPABILITY__ &
  ~__CHERI_CAP_PERMISSION_PERMIT_STORE__;
static const __UINT64_TYPE__ global_pointer_permissions =
  ~0 & ~__CHERI_CAP_PERMISSION_PERMIT_EXECUTE__;


__attribute__((weak))
extern struct capreloc __start___cap_relocs;
__attribute__((weak))
extern struct capreloc __stop___cap_relocs;

__attribute__((weak)) extern void *__capability
__cap_table_start;
__attribute__((weak)) extern void *__capability
__cap_table_end;

static __attribute__((always_inline)) void SETUP_GLOBAL_CAP_REGISTER(void) {
  __UINT64_TYPE__ cap_table_start = 0;
  __UINT64_TYPE__ cap_table_end = 0;
  __asm__ volatile (".option pic0\n\t"
      "dla %0, __cap_table_start\n\t"
      "dla %1, __cap_table_end\n\t"
      : "=r"(cap_table_start), "=r"(cap_table_end));
  if (!cap_table_start)
    return;
  void* __capability cgp = __builtin_cheri_offset_set(__builtin_cheri_global_data_get(), cap_table_start);
  cgp = __builtin_cheri_bounds_set(cgp, cap_table_end - cap_table_start);
  __asm__ volatile ("cmove $cgp, %0"::"C"(cgp));
}

static void crt_init_globals(void) {
  struct capreloc *start_relocs;
  struct capreloc *stop_relocs;
#ifndef __CHERI_CAPABILITY_TABLE__

  /* If we are not using the CHERI capability table we can just synthesize
   * the capabilities for these using the GOT and $ddc */
  start_relocs = &__start___cap_relocs;
  stop_relocs = &__stop___cap_relocs;
#else
  __UINT64_TYPE__ start_addr, end_addr;
  __UINT64_TYPE__ cap_table_length;
  __asm__ (".option pic0\n\t"
       "dla %0, __start___cap_relocs\n\t"
       "dla %1, __stop___cap_relocs\n\t"
       :"=r"(start_addr), "=r"(end_addr));
  long relocs_size = end_addr - start_addr;
  void *ddc = __builtin_cheri_global_data_get();
  start_relocs = __builtin_cheri_offset_set(__builtin_cheri_global_data_get(), start_addr);
  start_relocs = __builtin_cheri_bounds_set(start_relocs, relocs_size);
  stop_relocs = __builtin_cheri_offset_set(start_relocs, relocs_size);
#endif
  void *gdc = __builtin_cheri_global_data_get();
  void *pcc = __builtin_cheri_program_counter_get();

  gdc = __builtin_cheri_perms_and(gdc, global_pointer_permissions);
  pcc = __builtin_cheri_perms_and(pcc, function_pointer_permissions);
  for (struct capreloc *reloc = start_relocs; reloc < stop_relocs; reloc++) {
    _Bool isFunction = (reloc->permissions & function_reloc_flag) == function_reloc_flag;
    void **dest = __builtin_cheri_offset_set(gdc, reloc->capability_location);
    void *base = isFunction ? pcc : gdc;
    void *src = __builtin_cheri_offset_set(base, reloc->object);
    if (!isFunction && (reloc->size != 0)) {
      src = __builtin_cheri_bounds_set(src, reloc->size);
    }
    src = __builtin_cheri_offset_increment(src, reloc->offset);
    *dest = src;
  }
}
