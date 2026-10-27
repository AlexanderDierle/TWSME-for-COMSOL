# Corrections to the original UMAT

The patch `UMAT-TWSME.diff` adds the routine `ROTSIG` (see README) and corrects the following errors in the original UMAT of Xu et al. (version of 13 May 2017). Routine names refer to that file.

## 1. TRIP strain component 23 missing in the backstress update (affects results)

- **Where:** `Accumulated_zt` and `Backstress_Update`.
- **Error:** Both routines copy the TRIP strain into local variables (`ep1 = ep(1)` … `ep5 = ep(5)`). The line `ep6 = ep(6)` is missing, but `ep6` is used in the effective stress (`-e6+ep6+et6`). All other routines contain this line.
- **Effect:** The effective stress used for the backstress update and for the accumulated oriented martensite fraction lacks the 23 component of the TRIP strain. Depending on the compiler settings, `ep6` is zero (static storage, e.g. `/Qsave`) or undefined.
  - The error has no effect as long as the TRIP strain has no 23 component, e.g. for a straight wire loaded along its axis. This holds for the training and for the free-standing and anchored-only reference configurations.
  - The error becomes significant when a trained material point with a large TRIP strain rotates in the 2-3 plane, e.g. in a bending composite. The backstress is then driven towards an almost pure 23 shear state (β₂₃ ≈ σ_b/√3), although the Cauchy stress is predominantly axial.
  - With the correction, the backstress stays uniaxial and co-rotates with the wire. It then satisfies the update law β = σ_b (1 − e^(−λ₁ζ^d)) (σ + β)/‖σ + β‖_vM.
- **Fix:** add `ep6 = ep(6)` after `ep5 = ep(5)` in both routines.

## 2. Temperature `Tn` used without being set (no effect for α = 0)

- **Where:** `Accumulated_zt`, `Backstress_Update` and `N_R_JAC`.
- **Error:** The thermal strain term `alpha*(Tn - too)` uses `Tn`, which is never assigned in these routines.
- **Effect:** None if the thermal expansion coefficient α is zero, as in the paper. With α ≠ 0, the thermal strain in these routines would be wrong.
- **Fix:**
  - `Tn = TEMP + DTEMP` is passed from the main routine to `Accumulated_zt` and `Backstress_Update` as an additional argument.
  - In `N_R_JAC`, `Tn = Tn1` is set from the existing argument.

## 3. Write and read beyond the end of `PARAM` (no effect on results observed)

- **Where:** main routine and `INITIALIZATION` / `PARAM_ASSIGNMENTS`.
- **Error:** `PARAM` is declared with 35 entries (`PARAM(35)`, `NPARAM = 35`), but `PARAM(36) = kp` is written and read.
- **Effect:** `kp` is used only in the consistent tangent (`JACOBIAN_MATRIX`). The value read back is undefined and may overwrite adjacent memory. No effect on the converged results was observed.
- **Fix:** `PARAM(36)` and `NPARAM = 36`.

## 4. Undeclared temperature arguments in `JACOBIAN_MATRIX` (no effect with default-real promotion)

- **Where:** `JACOBIAN_MATRIX`.
- **Error:** `TEMP` and `DTEMP` are not declared. Under implicit typing, `DTEMP` is a default `REAL`.
- **Effect:** None if default reals are promoted to double precision (`/real-size:64`, as in `src/CMakeLists.txt`). Otherwise `DTEMP` would be read with the wrong precision in the tangent.
- **Fix:** explicit declaration `REAL*8 TEMP,DTEMP`.

## Verification

- Corrections 2 to 4 were checked by recomputing the actuator simulation of the paper. The results were identical.
- Correction 1 changes the actuation results of the composite:
  - The maximum tip deflection changes by less than 0.2 %.
  - The backstress remains uniaxial instead of becoming shear-dominated.
  - The recovery on cooling becomes complete.

## Differences that are not changed by the patch

- **Backstress evolution law.** The code evaluates β = σ_b (1 − e^(−λ₁ζ^d)) σ^eff/σ̄^eff. The factor H_cur/H_max of Eq. (41) in Xu et al. (2021) is not part of the implementation. As a result, the saturated backstress magnitude equals σ_b.
- **Stress measure.** The UMAT computes the stress from the logarithmic strain and returns it without conversion; the routine `STRESS_K_C` is not called. The wrapper treats the returned stress as Cauchy stress. The difference is a factor det F, which is negligible for the small volume changes of the wire.
