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

subroutine push_velocs(momenta,Fld,dt,np)
implicit none
integer, intent(in) :: np
real (kind=8), intent(inout) :: momenta(3,np)
real (kind=8), intent(in)    :: Fld(6,np), dt
real (kind=8) :: gamma, Um(3), t(3), t2,s(3), U0(3), Up(3),momenta_p(3),Fld_p(6),dt_2
integer:: ip

!f2py intent(in,out) :: momenta
!f2py intent(in) :: Fld,dt
!f2py intent(hide) :: np

!$omp parallel default(shared) private(gamma,Um,t,t2,s,U0,Up,ip,momenta_p,Fld_p,dt_2)
dt_2 = 0.5*dt
!$omp do schedule(static)
do ip=1,np
  momenta_p = momenta(:,ip)
  Fld_p = Fld(:,ip)

  Um = momenta_p + dt_2*Fld_p(1:3)
  gamma = SQRT(1.0+SUM(Um*Um))
  t =  dt_2*Fld_p(4:6)/gamma
  t2 = SUM(t*t)
  s = 2*t/(1+t2)

  U0(1) = Um(1) + Um(2)*t(3) - Um(3)*t(2)
  U0(2) = Um(2) - Um(1)*t(3) + Um(3)*t(1)
  U0(3) = Um(3) + Um(1)*t(2) - Um(2)*t(1)

  Up(1) = Um(1) +  U0(2)*s(3) - U0(3)*s(2)
  Up(2) = Um(2) -  U0(1)*s(3) + U0(3)*s(1)
  Up(3) = Um(3) +  U0(1)*s(2) - U0(2)*s(1)

  momenta_p = Up + dt_2*Fld_p(1:3)
  momenta(:,ip) = momenta_p
enddo
!$omp end do
!$omp end parallel
end subroutine

subroutine push_coords(coord,momenta,coord_cntr,dt,np)
implicit none
integer, intent(in) :: np
real (kind=8), intent(inout) :: coord(3,np), coord_cntr(3,np)
real (kind=8), intent(in) :: momenta(3,np), dt
real (kind=8) :: coord_p(3),coord_cntr_p(3),momenta_p(3),dt_gp
integer:: ip

!f2py intent(in,out) :: coord,coord_cntr
!f2py intent(in) :: momenta,dt
!f2py intent(hide) :: np

!$omp parallel do default(shared) private(ip,coord_p,coord_cntr_p,momenta_p,dt_gp)
do ip=1,np
  coord_p = coord(:,ip)
  momenta_p = momenta(:,ip)
  coord_cntr_p = coord_p
  dt_gp = dt/DSQRT(1.0+SUM(momenta_p*momenta_p))
  coord_p = coord_p + momenta_p*dt_gp
  coord_cntr_p = 0.5*(coord_cntr_p + coord_p)
  coord(:,ip) = coord_p
  coord_cntr(:,ip) = coord_cntr_p
enddo
!$omp end parallel do
end subroutine

subroutine genparts(coord,indPart,Xgrid,Rgrid,RandPackO,PackX,PackR,PackO,np,nx,nr,PPC)
implicit none
integer, intent(in)          :: np,nx,nr,PPC
real (kind=8), intent(in)    :: Xgrid(nx), Rgrid(nr),PackX(PPC),PackR(PPC),RandPackO(nx,nr)
complex (kind=8), intent(in) :: PackO(PPC)
real (kind=8), intent(inout) :: coord(4,np)
integer, intent(out)         :: indPart
integer                      :: ip,ir,ix
real (kind=8)                :: x0,x1,r0,r1,dr_2,pi=4.d0*DATAN(1.d0),&
                                coords_cell(2,PPC), Rgrid_shft(nr)
complex (kind=8)             :: Ocell(PPC),Oshft, ii=(0.0d0,1.0d0)

!f2py intent(in) :: Xgrid,Rgrid,PackX,PackR,PackO,RandPackO
!f2py intent(in,out) :: coord
!f2py intent(out) :: indPart
!f2py intent(hide) :: np,nx,nr,PPC

coord  = 0.0
dr_2 = 0.5*(Rgrid(2)-Rgrid(1))
Rgrid_shft = Rgrid + dr_2

indPart = 0
do ir=1,nr-1
  do ix=1,nx-1
    r0 = Rgrid_shft(ir)
    r1 = Rgrid_shft(ir+1)
    x0 = Xgrid(ix)
    x1 = Xgrid(ix+1)
    coords_cell(1,:) = x0+(x1-x0)*PackX
    coords_cell(2,:) = r0+(r1-r0)*PackR
    Oshft = 2.0d0*pi*RandPackO(ix,ir)
    Oshft = COS(Oshft)+ii*SIN(Oshft)
    Ocell = PackO*Oshft

    do ip=1,PPC
      if (coords_cell(2,ip)<=0) CYCLE
      indPart = indPart+1
      coord(1,indPart) = coords_cell(1,ip)
      coord(2,indPart) = coords_cell(2,ip)*AIMAG(Ocell(ip))
      coord(3,indPart) = coords_cell(2,ip)*DBLE (Ocell(ip))
      coord(4,indPart) = coords_cell(2,ip) 
    enddo
  enddo
enddo
end subroutine

subroutine sortpartsout(indx2stay,num2stay,coord,lims,np)
implicit none
integer, intent(in) :: np
real (kind=8), intent(in) :: lims(4), coord(3,np)
integer, intent(out) :: indx2stay(np), num2stay
integer :: ip
real (kind=8) :: x,r2

!f2py intent(in) :: coord,lims
!f2py intent(out)  :: indx2stay,num2stay
!f2py intent(hide) :: np

num2stay = 0
indx2stay = 0

do ip=1,np
  x = coord(1,ip)
  r2 = coord(2,ip)*coord(2,ip)+coord(3,ip)*coord(3,ip)
  if ((x>=lims(1)).and.(x<= lims(2)).and.(r2>=lims(3)).and.(r2<=lims(4))) then
    num2stay = num2stay+1
    indx2stay(num2stay) = ip-1
  endif
enddo
end subroutine

subroutine chunk_coords_boundaries(chunked_indx,IndInChnk,GoOut,coord,lims,Xgrid,nchnk,np,nx)
implicit none
integer, intent(in) :: np,nx,nchnk
real (kind=8), intent(in) :: coord(3,np),lims(4),Xgrid(0:nx)
integer, intent(out) :: IndInChnk(0:nchnk),GoOut
integer(kind=1), intent(out) :: chunked_indx(np)
real (kind=8)    :: chunk_lnght_inv,x,r2
integer  :: ip,ichnk,NumInChnk(nchnk),NumInChnk_loc(nchnk),Out_loc

!f2py intent(in) :: coord,lims,Xgrid,nchnk
!f2py intent(out) :: chunked_indx,IndInChnk,GoOut
!f2py intent(hide) :: np,nx

chunked_indx = -2
IndInChnk    = 0
NumInChnk    = 0
GoOut    = 0
if (nchnk>1) then
  chunk_lnght_inv = 1./(Xgrid((nx+1)/nchnk)-Xgrid(0))
else
  chunk_lnght_inv = 1./(Xgrid(nx)-Xgrid(0))
endif

!$omp parallel default(shared) private(NumInChnk_loc,Out_loc,ip,ichnk,x,r2)
NumInChnk_loc  = 0
Out_loc  = 0
!$omp do schedule(static)
do ip=1,np
  ichnk = floor((coord(1,ip)-Xgrid(0))*chunk_lnght_inv)
  x = coord(1,ip)
  r2 = coord(2,ip)*coord(2,ip)+coord(3,ip)*coord(3,ip)
  if ((x>=lims(1)).and.(x<= lims(2)).and.(r2>=lims(3)).and.(r2<=lims(4))) then
    NumInChnk_loc(ichnk+1) = NumInChnk_loc(ichnk+1) +1
    chunked_indx(ip) = int(ichnk,1)
  else 
    Out_loc = Out_loc +1
  endif
enddo
!$omp end do 

!$omp atomic
GoOut = GoOut+Out_loc

do ichnk=1,nchnk
  !$omp atomic
  NumInChnk(ichnk) = NumInChnk(ichnk) + NumInChnk_loc(ichnk)
enddo
!$omp end parallel

IndInChnk(0) = 0
do ichnk=1,nchnk
  IndInChnk(ichnk) = IndInChnk(ichnk-1) + NumInChnk(ichnk)
enddo
end subroutine

subroutine chunk_coords(chunked_indx,IndInChnk,OutToLeft,OutToRight,coord,Xgrid,nchnk,np,nx)
implicit none
integer, intent(in) :: np,nx,nchnk
real (kind=8), intent(in) :: coord(3,np),Xgrid(0:nx)
integer, intent(out) :: IndInChnk(0:nchnk),OutToLeft,OutToRight
integer(kind=1), intent(out) :: chunked_indx(np)
real (kind=8)    :: chunk_lnght_inv
integer  :: ip,ichnk,NumInChnk(nchnk),NumInChnk_loc(nchnk),&
            OutToLeft_loc,OutToRight_loc

!f2py intent(in) :: coord,Xgrid,nchnk
!f2py intent(out) :: chunked_indx,IndInChnk,OutToLeft,OutToRight
!f2py intent(hide) :: np,nx

chunked_indx = 0
IndInChnk    = 0
NumInChnk    = 0
OutToLeft    = 0
OutToRight   = 0
if (nchnk>1) then
  chunk_lnght_inv = 1./(Xgrid((nx+1)/nchnk)-Xgrid(0))
else
  chunk_lnght_inv = 1./(Xgrid(nx)-Xgrid(0))
endif

!$omp parallel default(shared) private(NumInChnk_loc,OutToLeft_loc,OutToRight_loc,ip,ichnk)
NumInChnk_loc  = 0
OutToLeft_loc  = 0
OutToRight_loc = 0
!$omp do schedule(static)
do ip=1,np
  ichnk = floor((coord(1,ip)-Xgrid(0))*chunk_lnght_inv)
  if (ichnk<0) then
    OutToLeft_loc = OutToLeft_loc +1
  elseif (ichnk>nchnk-1) then 
    OutToRight_loc = OutToRight_loc +1
  else
    NumInChnk_loc(ichnk+1) = NumInChnk_loc(ichnk+1) +1
  endif
  chunked_indx(ip) = int(ichnk,1)
enddo
!$omp end do 

!$omp atomic
OutToRight = OutToRight+OutToRight_loc
!$omp atomic
OutToLeft = OutToLeft+OutToLeft_loc

do ichnk=1,nchnk
  !$omp atomic
  NumInChnk(ichnk) = NumInChnk(ichnk) + NumInChnk_loc(ichnk)
enddo
!$omp end parallel

IndInChnk(0) = 0
do ichnk=1,nchnk
  IndInChnk(ichnk) = IndInChnk(ichnk-1) + NumInChnk(ichnk)
enddo
end subroutine

subroutine align_data_vec(dat,chunked_indx,np,np0)
implicit none
integer, intent(in) :: np,np0
real (kind=8), intent(inout) :: dat(3,np0)
integer (kind=8), intent(in) :: chunked_indx(np)
real (kind=8), allocatable :: dat_tmp(:,:)
integer:: ip

!f2py intent(in,out) :: dat
!f2py intent(in) :: chunked_indx
!f2py intent(hide) :: np,np0

allocate(dat_tmp(3,np))
!$omp parallel default(shared) private(ip)
!$omp do
do ip=1,np
  dat_tmp(:,ip) = dat(:,chunked_indx(ip)+1)
enddo
!$omp end do
!$omp do
do ip=1,np
  dat(:,ip) = dat_tmp(:,ip)
enddo
!$omp end do
!$omp end parallel
deallocate(dat_tmp)
end subroutine

subroutine align_data_scl(dat,chunked_indx,np,np0)
implicit none
integer, intent(in) :: np,np0
real (kind=8), intent(inout) :: dat(np0)
integer (kind=8), intent(in) :: chunked_indx(np)
real (kind=8), allocatable :: dat_tmp(:)
integer:: ip

!f2py intent(in,out) :: dat
!f2py intent(in) :: chunked_indx
!f2py intent(hide) :: np,np0

allocate(dat_tmp(np))
!$omp parallel default(shared) private(ip)
!$omp do
do ip=1,np
  dat_tmp(ip) = dat(chunked_indx(ip)+1)
enddo
!$omp end do
!$omp do
do ip=1,np
  dat(ip) = dat_tmp(ip)
enddo
!$omp end do
!$omp end parallel
deallocate(dat_tmp)
end subroutine

subroutine sortoutghosts(indx2stay,num2stay,coord,np)
implicit none
integer, intent(in) :: np
real (kind=8), intent(in) :: coord(np)
integer, intent(out) :: indx2stay(np), num2stay
integer :: ip

!f2py intent(in) :: coord
!f2py intent(out)  :: indx2stay,num2stay
!f2py intent(hide) :: np

num2stay = 0
indx2stay = 0

do ip=1,np
  if (coord(ip) .ne. 0.0) then
    num2stay = num2stay+1
    indx2stay(num2stay) = ip-1
  endif
enddo
end subroutine

