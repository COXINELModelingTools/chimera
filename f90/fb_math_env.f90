! This file is a part of CHIMERA software
! CHIMERA is a simulation code for FEL and laser plasma simulations
! Copyright (C)  2016 Igor A. Andriyash <igor.andriyash@gmail.com>
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

subroutine fb_grad_env(vec_fb_loc,scl_fb,DpS2S,DmS2S,kx,nkx,nkr,nkO,nkr_loc)
implicit none
integer, intent(in) :: nkx,nkr,nkO,nkr_loc
complex(kind=8),intent(in) :: scl_fb(nkx,nkr,-nkO:nkO)
real (kind=8), intent(in)  :: DpS2S(nkr,nkr_loc,-nkO-1:nkO+1),&
                              DmS2S(nkr,nkr_loc,-nkO-1:nkO+1),kx(nkx)
complex(kind=8),intent(inout):: vec_fb_loc(nkx,nkr_loc,-nkO:nkO,3)
integer         :: ik_loc,ik,iO
complex(kind=8) :: sliceKR(nkx), ii=(0.0d0,1.0d0)

!f2py intent(in) :: scl_fb,DpS2S,DmS2S,kx
!f2py intent(in,out) :: vec_fb_loc
!f2py intent(hide) :: nkx,nkr,nkO,nkr_loc

vec_fb_loc = 0.0d0

!$omp parallel default(shared), private(iO,sliceKR,ik,ik_loc)
do iO=-nkO,nkO
  !$omp do schedule(static)
  do ik_loc=1,nkr_loc
    vec_fb_loc(:,ik_loc,iO,1) = vec_fb_loc(:,ik_loc,iO,1) &
                              + ii*kx*scl_fb(:,ik_loc,iO)

    if (iO>-nkO) then
      sliceKR = 0.0d0
      do ik=1,nkr
        sliceKR = sliceKR + DmS2S(ik,ik_loc,iO)*scl_fb(:,ik,iO-1)
      enddo
      vec_fb_loc(:,ik_loc,iO,2) = vec_fb_loc(:,ik_loc,iO,2) -    sliceKR
      vec_fb_loc(:,ik_loc,iO,3) = vec_fb_loc(:,ik_loc,iO,3) + ii*sliceKR
    endif
    if (iO<nkO) then
      sliceKR = 0.0d0
      do ik=1,nkr
        sliceKR = sliceKR + DpS2S(ik,ik_loc,iO)*scl_fb(:,ik,iO+1)
      enddo
      vec_fb_loc(:,ik_loc,iO,2) = vec_fb_loc(:,ik_loc,iO,2) +    sliceKR
      vec_fb_loc(:,ik_loc,iO,3) = vec_fb_loc(:,ik_loc,iO,3) + ii*sliceKR
    endif
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine fb_div_env(scl_fb_loc,vec_fb,DpS2S,DmS2S,kx,nkx,nkr,nkO,nkr_loc)
implicit none
integer, intent(in) :: nkx,nkr,nkO,nkr_loc
complex(kind=8),intent(in) :: vec_fb(nkx,nkr,-nkO:nkO,3)
real (kind=8), intent(in)  :: DpS2S(nkr,nkr_loc,-nkO-1:nkO+1),&
                              DmS2S(nkr,nkr_loc,-nkO-1:nkO+1),kx(nkx)
complex(kind=8),intent(inout):: scl_fb_loc(nkx,nkr_loc,-nkO:nkO)
integer         :: ik_loc,ik,iO
complex(kind=8) :: sliceKR(nkx), ii=(0.0d0,1.0d0)

!f2py intent(in) :: vec_fb,DpS2S,DmS2S,kx
!f2py intent(in,out) :: scl_fb_loc
!f2py intent(hide) :: nkx,nkr,nkO,nkr_loc

scl_fb_loc = 0.0d0

!$omp parallel default(shared), private(iO,sliceKR,ik,ik_loc)
do iO=-nkO,nkO
  !$omp do schedule(static)
  do ik_loc=1,nkr_loc
    scl_fb_loc(:,ik_loc,iO) = scl_fb_loc(:,ik_loc,iO)&
                            + ii*kx*vec_fb(:,ik_loc,iO,1)

    sliceKR = 0.0d0
    if (iO>-nkO) then      
      do ik=1,nkr
        sliceKR = sliceKR - DmS2S(ik,ik_loc,iO)*(vec_fb(:,ik,iO-1,2) &
                                                  -ii*vec_fb(:,ik,iO-1,3))
      enddo
    endif
    if (iO<nkO) then
      do ik=1,nkr
        sliceKR = sliceKR + DpS2S(ik,ik_loc,iO)*(vec_fb(:,ik,iO+1,2)+ &
                                                 ii*vec_fb(:,ik,iO+1,3))
      enddo
    endif
    scl_fb_loc(:,ik_loc,iO) = scl_fb_loc(:,ik_loc,iO) + sliceKR
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine fb_rot_env(vec_fb_loc,vec_fb,DpS2S,DmS2S,kx,nkx,nkr,nkO,nkr_loc)
implicit none
integer, intent(in) :: nkx,nkr,nkO,nkr_loc
complex(kind=8),intent(in) :: vec_fb(nkx,nkr,-nkO:nkO,3)
real (kind=8), intent(in)  :: DpS2S(nkr,nkr_loc,-nkO-1:nkO+1),&
                              DmS2S(nkr,nkr_loc,-nkO-1:nkO+1),kx(nkx)
complex(kind=8),intent(inout):: vec_fb_loc(nkx,nkr_loc,-nkO:nkO,3)
integer         :: ik_loc,ik,iO
complex(kind=8) :: sliceKR(nkx), ii=(0.0d0,1.0d0)

!f2py intent(in) :: vec_fb,DpS2S,DmS2S,kx
!f2py intent(in,out) :: vec_fb_loc
!f2py intent(hide) :: nkx,nkr,nkO,nkr_loc

vec_fb_loc = 0.0d0

!$omp parallel default(shared), private(iO,sliceKR,ik,ik_loc)
do iO=-nkO,nkO
  !$omp do schedule(static)
  do ik_loc=1,nkr_loc
    vec_fb_loc(:,ik_loc,iO,2) = vec_fb_loc(:,ik_loc,iO,2) &
                              - ii*kx*vec_fb(:,ik_loc,iO,3)
    vec_fb_loc(:,ik_loc,iO,3) = vec_fb_loc(:,ik_loc,iO,3) &
                              + ii*kx*vec_fb(:,ik_loc,iO,2)

    if (iO<nkO) then
      sliceKR = 0.0d0
      do ik=1,nkr
        sliceKR = sliceKR - DpS2S(ik,ik_loc,iO)*(ii*vec_fb(:,ik,iO+1,2) &
                                                 -vec_fb(:,ik,iO+1,3))
      enddo
      vec_fb_loc(:,ik_loc,iO,1) = vec_fb_loc(:,ik_loc,iO,1) + sliceKR
      sliceKR = 0.0d0
      do ik=1,nkr
        sliceKR = sliceKR + DpS2S(ik,ik_loc,iO)*vec_fb(:,ik,iO+1,1)
      enddo
      vec_fb_loc(:,ik_loc,iO,2) = vec_fb_loc(:,ik_loc,iO,2) + ii*sliceKR
      vec_fb_loc(:,ik_loc,iO,3) = vec_fb_loc(:,ik_loc,iO,3) -    sliceKR
    endif
    if (iO>-nkO) then
      sliceKR = 0.0d0
      do ik=1,nkr
        sliceKR = sliceKR - DmS2S(ik,ik_loc,iO)*(ii*vec_fb(:,ik,iO-1,2) &
                                                 +vec_fb(:,ik,iO-1,3))
      enddo
      sliceKR = 0.0d0
      do ik=1,nkr
        sliceKR = sliceKR + DmS2S(ik,ik_loc,iO)*vec_fb(:,ik,iO-1,1)
      enddo
      vec_fb_loc(:,ik_loc,iO,2) = vec_fb_loc(:,ik_loc,iO,2) + ii*sliceKR
      vec_fb_loc(:,ik_loc,iO,3) = vec_fb_loc(:,ik_loc,iO,3) +    sliceKR
    endif
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine

subroutine fb_graddiv_env(vec_fb,DpS2S,DmS2S,kx,nkx,nkr,nkO,nkr_loc)
implicit none
integer, intent(in) :: nkx,nkr,nkO,nkr_loc
complex(kind=8),intent(inout) :: vec_fb(nkx,nkr,-nkO:nkO,3)
real (kind=8), intent(in)  :: DpS2S(nkr,nkr_loc,-nkO-1:nkO+1),&
                              DmS2S(nkr,nkr_loc,-nkO-1:nkO+1),kx(nkx)
complex(kind=8) :: scl_fb_loc(nkx,nkr_loc,-nkO-1:nkO+1)
integer         :: ik_loc,ik,iO
complex(kind=8) :: sliceKR(nkx), ii=(0.0d0,1.0d0)

!f2py intent(in) :: DpS2S,DmS2S,kx
!f2py intent(in,out) :: vec_fb
!f2py intent(hide) :: nkx,nkr,nkO,nkr_loc

scl_fb_loc = 0.0d0

!$omp parallel default(shared), private(iO,sliceKR,ik,ik_loc)
do iO=-nkO-1,nkO+1
  !$omp do schedule(static)
  do ik_loc=1,nkr_loc
    if ((iO>=-nkO) .and. (iO<=nkO)) then
      scl_fb_loc(:,ik_loc,iO) = scl_fb_loc(:,ik_loc,iO) &
                              + ii*kx*vec_fb(:,ik_loc,iO,1)
    endif

    sliceKR = 0.0d0
    if (iO>-nkO) then      
      do ik=1,nkr
        sliceKR = sliceKR - DmS2S(ik,ik_loc,iO)*(vec_fb(:,ik,iO-1,2) &
                                                 -ii*vec_fb(:,ik,iO-1,3))
      enddo
    endif
    if (iO<nkO) then
      do ik=1,nkr
        sliceKR = sliceKR + DpS2S(ik,ik_loc,iO)*(vec_fb(:,ik,iO+1,2) &
                                                 +ii*vec_fb(:,ik,iO+1,3))
      enddo
    endif
    scl_fb_loc(:,ik_loc,iO) = scl_fb_loc(:,ik_loc,iO) + sliceKR
  enddo
  !$omp end do
enddo
!$omp end parallel

vec_fb = 0.0d0

!$omp parallel default(shared), private(iO,sliceKR,ik,ik_loc)
do iO=-nkO,nkO
  !$omp do schedule(static)
  do ik_loc=1,nkr_loc
    vec_fb(:,ik_loc,iO,1) = vec_fb(:,ik_loc,iO,1) &
                          + ii*kx*scl_fb_loc(:,ik_loc,iO)

    sliceKR = 0.0d0
    do ik=1,nkr
      sliceKR = sliceKR + DmS2S(ik,ik_loc,iO)*scl_fb_loc(:,ik,iO-1)
    enddo
    vec_fb(:,ik_loc,iO,2) = vec_fb(:,ik_loc,iO,2) -    sliceKR
    vec_fb(:,ik_loc,iO,3) = vec_fb(:,ik_loc,iO,3) + ii*sliceKR
    sliceKR = 0.0d0
    do ik=1,nkr
      sliceKR = sliceKR + DpS2S(ik,ik_loc,iO)*scl_fb_loc(:,ik,iO+1)
    enddo
    vec_fb(:,ik_loc,iO,2) = vec_fb(:,ik_loc,iO,2) +    sliceKR
    vec_fb(:,ik_loc,iO,3) = vec_fb(:,ik_loc,iO,3) + ii*sliceKR
  enddo
  !$omp end do
enddo
!$omp end parallel
end subroutine
