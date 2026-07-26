# boot_pairs() rejects invalid input

    Code
      boot_pairs("not a model")
    Condition
      Error in `boot_pairs()`:
      ! `object` must be a linear model fitted by `stats::lm()`.
      x You supplied an object with class <character>.

---

    Code
      boot_pairs(fit, R = 0)
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `R`.
      x It must be one positive integer.

---

    Code
      boot_pairs(fit, R = 100, level = 1)
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `level`.
      x It must be in the interval "(0, 1)".

---

    Code
      boot_pairs(fit, R = 100, parallel = "yes")
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `parallel`.
      x It must be TRUE or FALSE.

---

    Code
      boot_pairs(fit, R = 100, cores = -1)
    Condition
      Error in `boot_pairs()`:
      ! Invalid argument `cores`.
      x It must be one positive integer.

