// RUN: %check_clang_tidy %s cheri-FixUserCopy %t

#define __user [[clang::annotate_type("user")]]

unsigned long copy_from_user(void *to, const void __user *from,
                             unsigned long n);
unsigned long copy_to_user(void __user *to, const void *from, unsigned long n);
unsigned long __copy_from_user(void *to, const void __user *from,
                               unsigned long n);
unsigned long __copy_to_user(void __user *to, const void *from,
                             unsigned long n);
unsigned long __copy_from_user_inatomic(void *to, const void __user *from,
                                        unsigned long n);
unsigned long __copy_to_user_inatomic(void __user *to, const void *from,
                                      unsigned long n);
unsigned long copy_from_user_with_ptr(void *to, const void __user *from,
                                      unsigned long n);

struct foo {
  int x;
  union {
    void *y;
    long v;
  };
};

struct bar {
  int x;
  union {
    unsigned long y;
    long v;
  };
};

static volatile const struct foo foo1;
typedef const struct foo foo_t;
static foo_t foo2;

static volatile const struct bar bar1;
typedef const struct bar bar_t;
static bar_t bar2;

void f(struct foo *dst, struct foo __user *src, void *p, unsigned long len) {
  copy_from_user(dst, src, sizeof(*dst));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, sizeof(*dst));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, sizeof(*src));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, sizeof(struct foo));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, sizeof(foo_t));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, sizeof(foo1));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, sizeof(foo2));
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, p, len);
// NOTYETCHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Cannot determine type of user copy [cheri-FixUserCopy]
  copy_from_user(p, (struct foo __user *)p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (void __user *)(struct foo __user *)p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (char __user *)(struct foo __user *)p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, &foo1, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, &foo2, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (void __user *)&foo1, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (unsigned long __user *)&foo2, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (void __user *)&foo1, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (void __user *)&foo2, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (char __user *)&foo1, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(p, (char __user *)&foo2, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((struct foo *)p, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((void __user *)(struct foo __user *)p, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((char __user *)(struct foo __user *)p, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(&foo1, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user(&foo2, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((void __user *)&foo1, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((unsigned long __user *)&foo2, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((void __user *)&foo1, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((void __user *)&foo2, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((char __user *)&foo1, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((char __user *)&foo2, p, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user_with_ptr(dst, src, sizeof(*dst));
}

void b(struct bar *dst, struct bar __user *src, void *p, unsigned long len) {
  copy_from_user(dst, src, sizeof(*dst));
  copy_from_user(p, p, sizeof(*dst));
  copy_from_user(p, p, sizeof(*src));
  copy_from_user(p, p, sizeof(struct bar));
  copy_from_user(p, p, sizeof(bar_t));
  copy_from_user(p, p, sizeof(bar1));
  copy_from_user(p, p, sizeof(bar2));
  copy_from_user(p, p, len);
// NOTYETCHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Cannot determine type of user copy [cheri-FixUserCopy]
  copy_from_user(p, (struct bar __user *)p, len);
  copy_from_user(p, (void __user *)(struct bar __user *)p, len);
  copy_from_user(p, (char __user *)(struct bar __user *)p, len);
  copy_from_user(p, &bar1, len);
  copy_from_user(p, &bar2, len);
  copy_from_user(p, (void __user *)&bar1, len);
  copy_from_user(p, (unsigned long __user *)&bar2, len);
  copy_from_user(p, (void __user *)&bar1, len);
  copy_from_user(p, (void __user *)&bar2, len);
  copy_from_user(p, (char __user *)&bar1, len);
  copy_from_user(p, (char __user *)&bar2, len);
  copy_from_user((struct bar *)p, p, len);
  copy_from_user((void __user *)(struct bar __user *)p, p, len);
  copy_from_user((char __user *)(struct bar __user *)p, p, len);
  copy_from_user(&bar1, p, len);
  copy_from_user(&bar2, p, len);
  copy_from_user((void __user *)&bar1, p, len);
  copy_from_user((unsigned long __user *)&bar2, p, len);
  copy_from_user((void __user *)&bar1, p, len);
  copy_from_user((void __user *)&bar2, p, len);
  copy_from_user((char __user *)&bar1, p, len);
  copy_from_user((char __user *)&bar2, p, len);
  copy_from_user_with_ptr(dst, src, sizeof(*dst));
}

void g(struct foo *dst, struct foo __user *src, unsigned long len) {
  copy_from_user(src, dst, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_to_user(src, dst, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  __copy_from_user(src, dst, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  __copy_to_user(src, dst, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  __copy_from_user_inatomic(src, dst, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  __copy_to_user_inatomic(src, dst, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
}

typedef unsigned long __uptr;

void h(void __user *src, unsigned long len) {
  __uptr a[10];
  copy_from_user(a, src, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
  copy_from_user((void *)a, src, len);
// CHECK-MESSAGES: :[[@LINE-1]]:3: warning: CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead [cheri-FixUserCopy]
}
