# =============================================================================
# TWSME-COMSOL
#
# Build configuration for the COMSOL Multiphysics external material library
# implementing the finite-strain SMA model by Xu et al., extended for coupled
# electro-thermo-mechanical simulation of the intrinsic two-way shape memory
# effect (TWSME).
#
# The library is compiled from:
#   - UMAT-TWSME.for                 Fortran UMAT (SMA material model, Xu et al.,
#                                    patched with ROTSIG, not included)
#   - UMAT4COMSOLfinite-TWSME.c      C wrapper (UMAT4COMSOL, extended)
#
# Output:
#   - TWSME-COMSOL.dll               dynamic library loaded by COMSOL as an
#                                    external material
#
# Toolchain (Windows, x64):
#   - Intel oneAPI Fortran compiler (ifx)
#   - Microsoft Visual C++ (cl), Visual Studio 2022
#   - CMake >= 3.20
#
# Build:
#   mkdir build && cd build
#   cmake -G "NMake Makefiles" -DCMAKE_Fortran_COMPILER=ifx ^
#         -DCMAKE_C_COMPILER=cl -DCMAKE_BUILD_TYPE=Release ..
#   nmake
#
# Author:  Alexander Dierle, Offenburg University of Applied Sciences
# =============================================================================

cmake_minimum_required(VERSION 3.20)
project(TWSME-COMSOL LANGUAGES C Fortran)

# -----------------------------------------------------------------------------
# Source files
# -----------------------------------------------------------------------------
set(SRC_FORTRAN ${CMAKE_CURRENT_LIST_DIR}/UMAT-TWSME.for)
set(SRC_C       ${CMAKE_CURRENT_LIST_DIR}/UMAT4COMSOLfinite-TWSME.c)

# The UMAT of Xu et al. is not part of this repository. Create it from the
# original file and the patch in ../patch (see README).
if(NOT EXISTS ${SRC_FORTRAN})
  message(FATAL_ERROR "UMAT-TWSME.for not found in ${CMAKE_CURRENT_LIST_DIR}. "
                      "Obtain the UMAT of Xu et al. and apply ../patch/UMAT-TWSME.diff (see README).")
endif()

# -----------------------------------------------------------------------------
# Target library
# -----------------------------------------------------------------------------
add_library(TWSME-COMSOL SHARED ${SRC_FORTRAN} ${SRC_C})

# Place the compiled library in the directory containing this CMakeLists,
# i.e. one level above the "build" folder.
set(_OUTDIR "${CMAKE_CURRENT_LIST_DIR}")

set_target_properties(TWSME-COMSOL PROPERTIES
  OUTPUT_NAME       TWSME-COMSOL
  # ifx performs the link step, pulling in the Intel Fortran runtimes.
  LINKER_LANGUAGE   Fortran
  C_STANDARD        99

  # Emit all build artifacts (dll, import lib, pdb) into the source directory,
  # independent of the selected configuration.
  RUNTIME_OUTPUT_DIRECTORY         "${_OUTDIR}"
  ARCHIVE_OUTPUT_DIRECTORY         "${_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY         "${_OUTDIR}"
  PDB_OUTPUT_DIRECTORY             "${_OUTDIR}"
  RUNTIME_OUTPUT_DIRECTORY_RELEASE "${_OUTDIR}"
  RUNTIME_OUTPUT_DIRECTORY_DEBUG   "${_OUTDIR}"
  ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${_OUTDIR}"
  ARCHIVE_OUTPUT_DIRECTORY_DEBUG   "${_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY_RELEASE "${_OUTDIR}"
  LIBRARY_OUTPUT_DIRECTORY_DEBUG   "${_OUTDIR}"
  PDB_OUTPUT_DIRECTORY_RELEASE     "${_OUTDIR}"
  PDB_OUTPUT_DIRECTORY_DEBUG       "${_OUTDIR}"
)

# -----------------------------------------------------------------------------
# Compiler options
#
# The Fortran flags define the symbol-naming and double-precision conventions
# expected by COMSOL's external material interface. Do not change them unless
# you know the interface still matches:
#   /names:lowercase /assume:underscore   symbol naming expected by the wrapper
#   /real-size:64                         promote default reals to double
#   /Qsave                                static local storage (SAVE semantics)
#   /libs:dll /threads                    link against the threaded DLL runtime
#   /fp:precise                           reproducible floating-point behavior
# -----------------------------------------------------------------------------
target_compile_options(TWSME-COMSOL PRIVATE
  $<$<COMPILE_LANGUAGE:Fortran>:/O2 /fp:precise /Qsave /threads /libs:dll /names:lowercase /assume:underscore /real-size:64>
  $<$<COMPILE_LANGUAGE:C>:/O2 /MD /TC>
)

# -----------------------------------------------------------------------------
# Linker options
# -----------------------------------------------------------------------------
target_link_options(TWSME-COMSOL PRIVATE /INCREMENTAL:NO)

# Link against the Windows API (harmless if the wrapper uses a mutex etc.).
if (WIN32)
  target_link_libraries(TWSME-COMSOL PRIVATE kernel32)
endif()
