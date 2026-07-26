# boot_pairs() rejects invalid input

    Code
      boot_pairs("not a model")
    Condition
      Error in `boot_pairs()`:
      ! `object` must be a linear model fitted by `stats::lm()`.
      x You supplied an object with class <character>.

---

    Code
      boot_pairs(fit, B = 0)
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `B`.
      x It must be one positive integer.

---

    Code
      boot_pairs(fit, B = 100, level = 1)
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `level`.
      x It must be in the interval "(0, 1)".

---

    Code
      boot_pairs(fit, B = 100, cores = 0)
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `cores`.
      x It must be a single number greater than or equal to 1.

---

    Code
      boot_pairs(fit, B = 100, cores = "two")
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `cores`.
      x It must be a single number greater than or equal to 1.

