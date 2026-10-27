!=======================================================================
! ROTSIG for the finite-strain SMA UMAT of Xu et al. (2021) in COMSOL
!
! The UMAT calls the Abaqus utility routine ROTSIG in ROTATION_PROCEDURE
! to rotate its tensorial state variables. COMSOL does not provide this
! routine. This file implements it with the Abaqus interface
!     CALL ROTSIG(S, R, SPRIME, LSTR, NDI, NSHR)
! LSTR = 1: stress-like quantity (tensor shear components)
! LSTR = 2: strain-like quantity (engineering shear components)
!
! Copyright (C) 2026 Alexander Dierle, Offenburg University of Applied
! Sciences. MIT License.
!=======================================================================
SUBROUTINE ROTSIG(S, R, SPRIME, LSTR, NDI, NSHR)
  IMPLICIT NONE
  INTEGER, INTENT(IN) :: LSTR, NDI, NSHR
  REAL*8 , INTENT(IN) :: S(NDI+NSHR), R(3,3)
  REAL*8 , INTENT(OUT):: SPRIME(NDI+NSHR)

  REAL*8 :: T(3,3), Srot(3,3), Rt(3,3)
  REAL*8 :: fin, fout
  INTEGER :: i,j, key

! Abaqus convention: INDEX1=1 stress-like, INDEX1=2 strain-like (engineering shear)
  IF (LSTR .EQ. 2) THEN          
     fin  = 0.5D0    ! engineering -> tensor
     fout = 2.0D0    ! tensor -> engineering
  ELSE
     fin  = 1.0D0
     fout = 1.0D0
  END IF

  ! Voigt -> Tensor
  T = 0.0D0
  key = 10*NDI + NSHR
  SELECT CASE (key)
  CASE (33)    ! 3D: [11,22,33,12,13,23]
     T(1,1)=S(1); T(2,2)=S(2); T(3,3)=S(3)
     T(1,2)=fin*S(4); T(2,1)=T(1,2)
     T(1,3)=fin*S(5); T(3,1)=T(1,3)
     T(2,3)=fin*S(6); T(3,2)=T(2,3)
  CASE (31)    ! plane strain: [11,22,33,12]
     T(1,1)=S(1); T(2,2)=S(2); T(3,3)=S(3)
     T(1,2)=fin*S(4); T(2,1)=T(1,2)
  CASE (21)    ! plane stress: [11,22,12]
     T(1,1)=S(1); T(2,2)=S(2); T(3,3)=0.0D0
     T(1,2)=fin*S(3); T(2,1)=T(1,2)
  CASE DEFAULT ! Fallback
     IF (NDI+NSHR>=1) T(1,1)=S(1)
     IF (NDI+NSHR>=2) T(2,2)=S(2)
     IF (NDI     >=3) T(3,3)=S(3)
     IF (NDI+NSHR>=4) THEN; T(1,2)=fin*S(4); T(2,1)=T(1,2); END IF
     IF (NDI+NSHR>=5) THEN; T(1,3)=fin*S(5); T(3,1)=T(1,3); END IF
     IF (NDI+NSHR>=6) THEN; T(2,3)=fin*S(6); T(3,2)=T(2,3); END IF
  END SELECT

  ! Rotation: Srot = R * T * R^T
  DO i=1,3
    DO j=1,3
      Rt(i,j) = R(j,i)   ! transpose
    END DO
  END DO
  Srot = MATMUL( R, MATMUL(T, Rt) )

  ! Null Ausgang
  DO i=1,NDI+NSHR
    SPRIME(i) = 0.0D0
  END DO

  ! Tensor -> Voigt
  SELECT CASE (key)
  CASE (33)    ! 3D
     SPRIME(1)=Srot(1,1); SPRIME(2)=Srot(2,2); SPRIME(3)=Srot(3,3)
     SPRIME(4)=fout*Srot(1,2)
     SPRIME(5)=fout*Srot(1,3)
     SPRIME(6)=fout*Srot(2,3)
  CASE (31)    ! plane strain
     SPRIME(1)=Srot(1,1); SPRIME(2)=Srot(2,2); SPRIME(3)=Srot(3,3)
     SPRIME(4)=fout*Srot(1,2)
  CASE (21)    ! plane stress
     SPRIME(1)=Srot(1,1); SPRIME(2)=Srot(2,2)
     SPRIME(3)=fout*Srot(1,2)
  CASE DEFAULT
     IF (NDI+NSHR>=1) SPRIME(1)=Srot(1,1)
     IF (NDI+NSHR>=2) SPRIME(2)=Srot(2,2)
     IF (NDI     >=3) SPRIME(3)=Srot(3,3)
     IF (NDI+NSHR>=4) SPRIME(4)=fout*Srot(1,2)
     IF (NDI+NSHR>=5) SPRIME(5)=fout*Srot(1,3)
     IF (NDI+NSHR>=6) SPRIME(6)=fout*Srot(2,3)
  END SELECT
END SUBROUTINE ROTSIG
