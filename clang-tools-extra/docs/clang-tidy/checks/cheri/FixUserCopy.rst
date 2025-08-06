.. title:: clang-tidy - cheri-FixUserCopy

cheri-FixUserCopy
=================

Check invocations of the linux user copy functions for cases where
data with pointers is copied and suggest use fo the ..._with_ptr
variant.

The check may miss relevant calls if it cannot determine the type
of the copied data.

Additionally, there are very few false positives that result from
strange use of types in the uptream linux UABI headers.
