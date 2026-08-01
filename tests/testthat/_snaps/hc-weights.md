# HCbeta rejects epsilon as a method argument

    Code
      vcov_hc(fit, "hcbeta", epsilon = 0.02)
    Condition
      Error in `vcov_hc()`:
      ! Invalid argument in `...`.
      x Unexpected name: `epsilon`.
      i Allowed names: `c1`, `c2`, `lower`, `upper`, `a_max`, and `b_max`.

# HCbeta cap bounds are inclusive

    Code
      vcov_hc(fit, "hcbeta", a_max = 49)
    Condition
      Error in `vcov_hc()`:
      ! Invalid argument `a_max`.
      x It must be in the interval "[50, 25000]".

---

    Code
      vcov_hc(fit, "hcbeta", a_max = 25001)
    Condition
      Error in `vcov_hc()`:
      ! Invalid argument `a_max`.
      x It must be in the interval "[50, 25000]".

---

    Code
      vcov_hc(fit, "hcbeta", b_max = 49)
    Condition
      Error in `vcov_hc()`:
      ! Invalid argument `b_max`.
      x It must be in the interval "[50, 25000]".

---

    Code
      vcov_hc(fit, "hcbeta", b_max = 25001)
    Condition
      Error in `vcov_hc()`:
      ! Invalid argument `b_max`.
      x It must be in the interval "[50, 25000]".

# HC leverage-one guards are method-specific

    Code
      vcov_hc(fit, "hc3")
    Condition
      Error in `vcov_hc()`:
      ! At least one leverage value is too close to 1.
      i HC leverage corrections require positive `1 - h_t`.

