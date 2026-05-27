# tests() errors on unknown coefficient name

    Code
      tests(result, parm = "nonexistent")
    Condition
      Error in `tests()`:
      ! Unknown coefficient name in `parm`.
      x Unknown term: "nonexistent".

# tests() errors on invalid parm type

    Code
      tests(result, parm = TRUE)
    Condition
      Error in `tests()`:
      ! Invalid argument `parm`.
      x It must contain coefficient names or positions.

# tests() errors on invalid alpha

    Code
      tests(result, alpha = 1.5)
    Condition
      Error in `tests()`:
      ! Invalid argument `alpha`.
      x It must be strictly between 0 and 1.

---

    Code
      tests(result, alpha = 0)
    Condition
      Error in `tests()`:
      ! Invalid argument `alpha`.
      x It must be strictly between 0 and 1.

