
!! boundary conditions are employed in the case of subsonic flow. Conservative
!! variables are inter- / extrapolated in the case of supersonic flow. Vortex
!! correction is optionally applied to the flow variables (subsonic only).
!!
!! @param ibegn  indirect pointer to first node of the boundary
!! @param iendn  indirect pointer to last node of the boundary
!! @param rhof   work array for density at the boundary
!! @param uf     work array for u-velocity at the boundary
!! @param vf     work array for v-velocity at the boundary
!! @param pf     work array for pressure at the boundary
!!
subroutine BcondFarfield2( ibegn,iendn,rhof,uf,vf,pf )
  use ModDataTypes
  use prmflow
  use ModInterfaces
  implicit none

! parameters
  integer, intent(in) :: ibegn, iendn
  real(rtype) :: rhof(:), uf(:), vf(:), pf(:)

! local variables
  integer     :: ib, ibn, idn, ie
  real(rtype) :: gmr, gmg, bet, cir, xa, ya, dist, angle, sn, dn, vc, qv2
  real(rtype) :: ds, sxn, syn, rhoe, ue, ve, qqe, pe, qn, crho0, &
                 rhoa, ua, va, pa, ul, vl, pl, sgn, pb, gam1, ggm1
  real(rtype) :: rhop, rhoT, hT, a1, ra1g, a4, a5, cs

! *****************************************************************************
! free-stream values (optionally corrected by a vortex) -----------------------
! values corrected

  if (lvort == 1) then
    call Forces

    bet = Sqrt(1.D0-machinf*machinf)
    cir = 0.25D0*cref*cl*qinf/pi

    do ib=ibegn,iendn
      ibn      = bnode(1,ib)         ! boundary node
      gam1     = dv(4,ibn) - 1.D0
      ggm1     = dv(4,ibn)/gam1
      gmr      = 1.D0/dv(4,ibn)
      gmg      = gam1/dv(4,ibn)
      xa       = x(ibn) - xref
      ya       = y(ibn) - yref
      dist     = Sqrt(xa*xa+ya*ya)
      angle    = Atan2(ya,xa)
      sn       = Sin(angle-alpha)
      dn       = 1.D0 - machinf*machinf*sn*sn
      vc       = cir*bet/(dn*dist)
      uf(ib)   = uinf + vc*Sin(angle)
      vf(ib)   = vinf - vc*Cos(angle)
      qv2      = uf(ib)*uf(ib) + vf(ib)*vf(ib)
      pf(ib)   = (pinf**gmg+gmg*rhoinf*(qinf*qinf-qv2)/(2.D0*pinf**gmr))**ggm1
      rhof(ib) = rhoinf*(pf(ib)/pinf)**gmr
    enddo

! not corrected

  else
    do ib=ibegn,iendn
      rhof(ib) = rhoinf
      uf(ib)   = uinf
      vf(ib)   = vinf
      pf(ib)   = pinf
    enddo
  endif

! computation of the boundary values ------------------------------------------

  do ib=ibegn,iendn

    ibn = bnode(1,ib)         ! boundary node
    idn = bnode(2,ib)         ! dummy node
    ie  = bnode(3,ib)         ! edge to dummy node

    ds  = Sqrt(sij(1,ie)**2+sij(2,ie)**2)
    sxn = sij(1,ie)/ds
    syn = sij(2,ie)/ds

    gam1  = dv(4,ibn) - 1.D0
    rhoe  = cv(1,ibn)
    ue    = cv(2,ibn)/rhoe
    ve    = cv(3,ibn)/rhoe
    qqe   = ue*ue + ve*ve
    pe    = dv(1,ibn)

    if (machinf < 1.D0) then

! --- subsonic flow (qn<0: inflow / qn>0: outflow)

      qn = sxn*ue + syn*ve
      crho0 = dv(3,ibn)*rhoe

      if (qn < 0.D0) then
        rhoa = rhof(ib)
        ua   = uf(ib)
        va   = vf(ib)
        pa   = pf(ib)
        ul   = ue
        vl   = ve
        pl   = pe
        sgn  = -1.D0
        pb   = 0.5D0*(pa+pl-crho0*(sxn*(ua-ul)+syn*(va-vl)))
      else
        rhoa = rhoe
        ua   = ue
        va   = ve
        pa   = pe
        ul   = uf(ib)
        vl   = vf(ib)
        pl   = pf(ib)
        sgn  = +1.D0
        pb   = pf(ib)
      endif
      cv(1,idn) = rhoa + (pb-pa)/(dv(3,ibn)**2)
      cv(2,idn) = cv(1,idn)*(ua+sgn*sxn*(pa-pb)/crho0)
      cv(3,idn) = cv(1,idn)*(va+sgn*syn*(pa-pb)/crho0)
      cv(4,idn) = pb/gam1 + 0.5D0*(cv(2,idn)**2+cv(3,idn)**2)/cv(1,idn)

    else

! --- supersonic flow (qn<0: inflow / qn>0: outflow)

      qn = sxn*ue + syn*ve
      if (qn < 0.D0) then
        cv(1,idn) = rhoinf
        cv(2,idn) = rhoinf*uinf
        cv(3,idn) = rhoinf*vinf
        cv(4,idn) = pinf/gam1 + 0.5D0*rhoinf*qinf*qinf
      else
        cv(1,idn) = rhoe
        cv(2,idn) = rhoe*ue
        cv(3,idn) = rhoe*ve
        cv(4,idn) = pe/gam1 + 0.5D0*rhoe*qqe
      endif
    endif

    call DependentVarsOne( idn )

  enddo  ! ib

end subroutine BcondFarfield2
