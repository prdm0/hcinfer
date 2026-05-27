# plot() errors on unknown parm name

    Code
      plot(result, parm = "nonexistent")
    Condition
      Error in `plot()`:
      ! Unknown coefficient name in `parm`.
      x Unknown term: "nonexistent".

# plot() for covariance objects validates label_top

    Code
      plot(cov, label_top = -1)
    Condition
      Error in `plot()`:
      ! Invalid argument `label_top`.
      x It must be one nonnegative whole number.

---

    Code
      plot(cov, label_top = 1.5)
    Condition
      Error in `plot()`:
      ! Invalid argument `label_top`.
      x It must be one nonnegative whole number.

