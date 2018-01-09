// RUN: %clang_cc1 -verify -fopenmp -o - %s

// RUN: %clang_cc1 -verify -fopenmp-simd -o - %s

void foo();

int main(int argc, char **argv) {
  int i;
#pragma omp parallel for simd default // expected-error {{expected '(' after 'default'}}
  for (i = 0; i < argc; ++i)
    foo();
#pragma omp parallel for simd default( // expected-error {{expected 'none' or 'shared' in OpenMP clause 'default'}} expected-error {{expected ')'}} expected-note {{to match this '('}}
  for (i = 0; i < argc; ++i)
    foo();
#pragma omp parallel for simd default() // expected-error {{expected 'none' or 'shared' in OpenMP clause 'default'}}
  for (i = 0; i < argc; ++i)
    foo();
#pragma omp parallel for simd default(none // expected-error {{expected ')'}} expected-note {{to match this '('}}
  for (i = 0; i < argc; ++i) // expected-error {{variable 'argc' must have explicitly specified data sharing attributes}}
    foo();
#pragma omp parallel for simd default(shared), default(shared) // expected-error {{directive '#pragma omp parallel for simd' cannot contain more than one 'default' clause}}
  for (i = 0; i < argc; ++i)
    foo();
#pragma omp parallel for simd default(x) // expected-error {{expected 'none' or 'shared' in OpenMP clause 'default'}}
  for (i = 0; i < argc; ++i)
    foo();

#pragma omp parallel for simd default(none)
  for (i = 0; i < argc; ++i)  // expected-error {{variable 'argc' must have explicitly specified data sharing attributes}}
    foo();

#pragma omp parallel default(none)
#pragma omp parallel for simd default(shared)
  for (i = 0; i < argc; ++i)
    foo();

  return 0;
}
