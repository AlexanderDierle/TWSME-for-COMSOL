# TWSME-for-COMSOL

Electro-thermo-mechanical simulation of shape memory alloy (SMA) composite structures in COMSOL Multiphysics, using the finite-strain SMA model of Xu et al. with transformation-induced plasticity (TRIP) and the intrinsic two-way shape memory effect (TWSME).

This repository contains the code used in

> A. Dierle, T. Seifert, T. M. Wendt, *Electro-Thermo-Mechanical Finite Element Modeling of Shape Memory Composite Structures: Material Model, Training, and Actuation*, Smart Materials and Structures (under review).

It documents how the Fortran user material subroutine (UMAT) of Xu et al. is connected to COMSOL through an extended version of the UMAT4COMSOL wrapper, and how to build the external material library.

The UMAT of Xu et al. is not included in this repository. It has to be obtained from the authors (see below). This repository provides a patch that adds the required routine to it and corrects several errors in the original code (see `patch/FIXES.md`).

## Contents

| Path | Description |
|---|---|
| `src/UMAT4COMSOLfinite-TWSME.c` | Finite-strain UMAT4COMSOL wrapper (Lucarini and Martínez-Pañeda), extended by a thermal interface |
| `src/CMakeLists.txt` | Build configuration for the external material library `TWSME-COMSOL.dll` |
| `patch/UMAT-TWSME.diff` | Patch that turns the original UMAT of Xu et al. into the version used in the paper |
| `patch/rotsig.f90` | The routine `ROTSIG` added by the patch, for reading or manual insertion |
| `patch/FIXES.md` | Errors in the original UMAT that are corrected by the patch |
| `THIRD_PARTY_NOTICES.md` | Origin and copyright of the third-party code |
| `CITATION.cff` | Citation metadata |

## Based on

- **SMA material model:** L. Xu, A. Solomou, T. Baxevanis, D. Lagoudas, *Finite strain constitutive modeling for shape memory alloys considering transformation-induced plasticity and two-way shape memory effect*, International Journal of Solids and Structures 221 (2021) 42–59, [doi:10.1016/j.ijsolstr.2020.03.009](https://doi.org/10.1016/j.ijsolstr.2020.03.009). The UMAT is distributed by the authors at <https://github.com/Aero-tomato/SMA-UMAT>.
- **Wrapper:** S. Lucarini, E. Martínez-Pañeda, *UMAT4COMSOL: An Abaqus user material (UMAT) subroutine wrapper for COMSOL*, Advances in Engineering Software 190 (2024) 103610, [doi:10.1016/j.advengsoft.2024.103610](https://doi.org/10.1016/j.advengsoft.2024.103610). Original code: <https://github.com/sergiolucarini/UMAT4COMSOL>.

Please cite these works together with the paper above if you use this code.

## Changes made in this work

### Wrapper (`src/UMAT4COMSOLfinite-TWSME.c`)

- **Thermal interface.** The original wrapper passes placeholders for the temperature. The current and previous temperatures provided by COMSOL are now passed to the UMAT in the Abaqus convention. `TEMP` is the temperature at the beginning of the increment and `DTEMP` is the increment. In the first step `TEMP` equals the initial temperature and `DTEMP` is zero. The initial temperature is stored in state variable 42, which the UMAT reads as reference temperature `TOO`.
- **Step information.** The original wrapper passes placeholders for the step and increment information. `JSTEP`, `KINC`, `NPT`, `LAYER` and `KSPT` are now passed explicitly. `JSTEP(3) = 1` activates the finite-strain (NLGEOM) branch of the UMAT.
- The `umat_` interface was adapted accordingly (`JSTEP(4)` instead of `KSTEP`).

### UMAT (`patch/UMAT-TWSME.diff`)

The UMAT of Xu et al. rotates its tensorial state variables in each increment (routines `ROTATION_SDV` and `ROTATION_PROCEDURE`). The incremental rotation `RLOG` is computed from the logarithmic spin in `FIND_LOG`. For the rotation itself the UMAT calls the Abaqus utility routine `ROTSIG`, which is not available in COMSOL. The patch

- adds `ROTSIG` with the same interface as the Abaqus utility (`CALL ROTSIG(S, R, SPRIME, LSTR, NDI, NSHR)`). It computes R·S·Rᵀ. Strain-like quantities (`LSTR = 2`) are handled with engineering shear components and stress-like quantities (`LSTR = 1`) with tensor components. 3D, plane strain and plane stress layouts are supported.
- comments out the two `INCLUDE 'ABA_PARAM.INC'` statements, which only exist in an Abaqus installation.
- corrects four errors in the original UMAT (see `patch/FIXES.md`). The most important one is a missing `ep6 = ep(6)` in `Accumulated_zt` and `Backstress_Update`. It affects the backstress whenever a trained material point with TRIP strain rotates in the 2-3 plane, e.g. in a bending composite.

The constitutive equations of the model are not changed.

## Preparing the UMAT

1. Download the finite-strain UMAT from <https://github.com/Aero-tomato/SMA-UMAT>.
2. Save it as `src/UMAT-TWSME.for`.
3. Apply the patch from the repository root, either with git or with GNU patch:

```bat
git apply --ignore-whitespace patch/UMAT-TWSME.diff
```
```sh
patch --binary src/UMAT-TWSME.for < patch/UMAT-TWSME.diff
```

The patch was created against the version of 13 May 2017 (header of the file) with Windows line endings. If it does not apply to your copy, make the changes by hand. Comment out both `INCLUDE 'ABA_PARAM.INC'` lines, insert the content of `patch/rotsig.f90` directly after `SUBROUTINE ROTATION_PROCEDURE`, i.e. before `SUBROUTINE SDV_ASSIGN`, and apply the corrections listed in `patch/FIXES.md`.

`src/UMAT-TWSME.for` is listed in `.gitignore`, so the patched UMAT is not committed by accident.

## Requirements

- COMSOL Multiphysics with the Structural Mechanics Module (external material support) and the Heat Transfer and AC/DC modules for the coupled problem
- Windows x64 with Intel oneAPI Fortran compiler (`ifx`), Microsoft Visual C++ (`cl`, Visual Studio 2022) and CMake ≥ 3.20

The UMAT switches between free and fixed source form with `!DEC$ FREEFORM` / `!DEC$ NOFREEFORM` and uses further Intel extensions. It is therefore written for the Intel compiler.

## Building the external material library

Open an *Intel oneAPI command prompt for Intel 64 for Visual Studio 2022* and run in `src/`

```bat
mkdir build && cd build
cmake -G "NMake Makefiles" -DCMAKE_Fortran_COMPILER=ifx -DCMAKE_C_COMPILER=cl -DCMAKE_BUILD_TYPE=Release ..
nmake
```

The library `TWSME-COMSOL.dll` is written to `src/`. The compiler options are documented in `CMakeLists.txt`. Keep them unchanged. In particular

- `/names:lowercase /assume:underscore` gives the symbol name `umat_` that the wrapper calls,
- `/real-size:64` promotes default real constants to double precision,
- `/Qsave` gives local variables SAVE semantics.

The simulations of the paper were run with a library built with exactly these options. The exported entry point is `eval`. COMSOL needs the Intel Fortran runtime DLLs at run time. If COMSOL reports that the library cannot be loaded, add the oneAPI `redist` folder to `PATH`.

## Setting up the material in COMSOL

1. In *Solid Mechanics*, add an *External Material* node under the material of the wire and select `TWSME-COMSOL.dll`.
2. Use the general stress–deformation interface of the wrapper with function name `eval`. The wrapper receives the deformation gradient and returns the second Piola–Kirchhoff stress and its Jacobian.
3. Enter the 30 material parameters listed below in this order.
4. Set the number of states to **64**. The UMAT uses 42 state variables and the wrapper stores 22 more (time, deformation gradient, stress and strain of the last converged step), so `nstatev = nStates − 22`.
5. Couple the temperature from *Heat Transfer in Solids* as model input of the external material.
6. Activate geometric nonlinearity in the study step.

The units must be consistent with the COMSOL model. In SI units, all stress parameters and moduli are in Pa and `kt` is in 1/Pa.

### Material parameters (`PROPS`)

| No. | Name | Meaning |
|---|---|---|
| 1 | `Ea` | Young's modulus of austenite |
| 2 | `Em` | Young's modulus of martensite |
| 3 | `v` | Poisson's ratio |
| 4 | `alpha` | Thermal expansion coefficient |
| 5 | `CA` | Stress influence coefficient of austenite |
| 6 | `CM` | Stress influence coefficient of martensite |
| 7 | `Ms` | Martensite start temperature |
| 8 | `Mf` | Martensite finish temperature |
| 9 | `As` | Austenite start temperature |
| 10 | `Af` | Austenite finish temperature |
| 11 | `Hmax` | Maximum transformation strain |
| 12 | `kt` | Exponent of the transformation strain saturation |
| 13 | `SigCal` | Calibration stress at which the intermediate parameters (ρΔs₀, ρΔu₀, a₁, a₂, a₃, Y₀, D) are evaluated, see Xu et al. (2021), Appendix B. Not the critical stress σ^crit of the H_cur function |
| 14–17 | `n1`–`n4` | Smooth hardening exponents |
| 18 | `Eb` | Backstress parameter (σ_b) |
| 19 | `C1` | TRIP parameter C₁ᵖ |
| 20 | `C2` | TRIP parameter C₂ᵖ |
| 21 | `L1` | Backstress evolution parameter λ₁ |
| 22 | `X_initial` | Initial martensite volume fraction |
| 23 | `Etd` | Option flag, read but not used in this version |
| 24 | `Tube_Flag` | Tube geometry flag (0 = off), only used to compute a radius ratio |
| 25 | `Tube_Axis` | Tube axis (1, 2 or 3), only used if `Tube_Flag` = 1 |
| 26 | `Tube_Radius` | Tube radius, only used if `Tube_Flag` = 1 |
| 27 | `Elastic` | Option flag, read but not used in this version |
| 28 | `Coupling` | Option flag, read but not used in this version |
| 29 | `Model` | Option flag, read but not used in this version |
| 30 | `kp` | Exponent used in the consistent tangent stiffness (TRIP term) |

The parameter values used in the paper are given in its Table 1. The critical stress σ^crit of the H_cur function is not an input of this UMAT version. It is implicitly zero, as in the paper. A description of the calibration is given by Xu et al. (2021).

### State variables (`STATEV`)

| No. | Variable |
|---|---|
| 1 | Martensite volume fraction ξ |
| 2 | Detwinned martensite volume fraction |
| 3 | Accumulated martensite volume fraction |
| 4 | Accumulated detwinned martensite volume fraction |
| 5 | Increment of detwinned martensite volume fraction |
| 6, 7 | Flags for finished forward and reverse transformation |
| 8 | Transformation direction (0 elastic, 1 forward, −1 reverse) |
| 9–14 | Transformation strain |
| 15–20 | TRIP strain |
| 21–26 | Transformation strain at reversal |
| 27–32 | Reverse transformation direction |
| 33–38 | Backstress |
| 39 | RPLC |
| 40 | Bound reached flag |
| 41 | Newton–Raphson convergence flag |
| 42 | Reference temperature (set from the initial temperature) |

### Phase-dependent properties

The martensite volume fraction is state variable 1. In COMSOL it is available as the first state of the external material and can be used to interpolate phase-dependent properties. With the external material named `TWSME`, the thermal conductivity used in the paper reads

```
TWSME.state.elast1*8.6[W/(m*K)] + (1-TWSME.state.elast1)*18[W/(m*K)]
```

The electrical conductivity is interpolated in the same way. The latent heat enters through an apparent heat capacity, as described in the paper.

## License

See `LICENSE` and `THIRD_PARTY_NOTICES.md`. The original authors keep the copyright of their code. The UMAT of Xu et al. is not redistributed here.
