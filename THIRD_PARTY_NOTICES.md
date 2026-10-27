# Third-party notices

## UMAT4COMSOL (src/UMAT4COMSOLfinite-TWSME.c)

Copyright (C) 2023 Sergio Lucarini.
Original code: https://github.com/sergiolucarini/UMAT4COMSOL (MIT License).

S. Lucarini, E. Martínez-Pañeda, UMAT4COMSOL: An Abaqus user material (UMAT)
subroutine wrapper for COMSOL, Advances in Engineering Software 190 (2024)
103610, https://doi.org/10.1016/j.advengsoft.2024.103610

The file was extended in this work by a thermal interface (TEMP/DTEMP and
reference temperature in state variable 42) and passes the step and increment
information to the UMAT.

## Finite-strain SMA UMAT with TRIP and TWSME (not included)

The UMAT of Lei Xu, Alexandros Solomou, Theocharis Baxevanis and Dimitris
Lagoudas is not part of this repository. It is available from the authors at
https://github.com/Aero-tomato/SMA-UMAT

L. Xu, A. Solomou, T. Baxevanis, D. Lagoudas, Finite strain constitutive
modeling for shape memory alloys considering transformation-induced plasticity
and two-way shape memory effect, International Journal of Solids and
Structures 221 (2021) 42-59, https://doi.org/10.1016/j.ijsolstr.2020.03.009

The routine ROTSIG in patch/rotsig.f90 and patch/UMAT-TWSME.diff is original
work of this repository and is meant to be added to that UMAT. The diff
contains a few unchanged lines of the original UMAT as context.
