! THIS VERSION: CUTEST 2.1 - 2023-10-17 AT 08:00 GMT.

!-*-*-*-*-*-*-  C U T E S T    C I S G R P    S U B R O U T I N E  -*-*-*-*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   modern fortran version released in CUTEst, 17th October 2023

      SUBROUTINE CUTEST_cisgrp( status, n, iprob, nnzgr, lgr, GR_var )
      USE CUTEST

!  dummy arguments

      INTEGER, INTENT( IN ) :: n, iprob, lgr
      INTEGER, INTENT( OUT ) :: status, nnzgr
      INTEGER, INTENT( OUT ), DIMENSION( lgr ) :: GR_var

!  -------------------------------------------------------------------
!  compute the sparsity pattern of the gradient of a specified problem 
!  function (iprob = 0 is the objective function, while iprob > 0 is 
!  the iprob-th constraint) initially written in Standard Input Format
!  (SIF). The nonzero components of the iprob-th gradient occur in 
!  positions GR_var(j), j = 1,...,nnzgr.
!  -------------------------------------------------------------------

      CALL CUTEST_cisgrp_threadsafe( CUTEST_data_global,                       &
                                     CUTEST_work_global( 1 ),                  &
                                     status, n, iprob, nnzgr, lgr, GR_var )
      RETURN

!  end of subroutine CUTEST_cisgrp

      END SUBROUTINE CUTEST_cisgrp

!-*-  C U T E S T   C I S G R P _ t h r e a d s a f e   S U B R O U T I N E  -*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal authors: Ingrid Bongartz and Nick Gould

!  History -
!   modern fortran version released in CUTEst, 17th October 2023

      SUBROUTINE CUTEST_cisgrp_threadsafe( data, work, status, n, iprob,       &
                                           nnzgr, lgr, GR_var )
      USE CUTEST

!  dummy arguments

      TYPE ( CUTEST_data_type ), INTENT( IN ) :: data
      TYPE ( CUTEST_work_type ), INTENT( INOUT ) :: work
      INTEGER, INTENT( IN ) :: n, iprob, lgr
      INTEGER, INTENT( OUT ) :: status, nnzgr
      INTEGER, INTENT( OUT ), DIMENSION( lgr ) :: GR_var

!  -------------------------------------------------------------------
!  compute the sparsity pattern of the gradient of a specified problem 
!  function (iprob = 0 is the objective function, while iprob > 0 is 
!  the iprob-th constraint) initially written in Standard Input Format
!  (SIF). The nonzero components of the iprob-th gradient occur in 
!  positions GR_var(j), j = 1,...,nnzgr.
!  -------------------------------------------------------------------

!  local variables

      INTEGER :: i, j, iel, k, ig, ii, ig1, l, ll, neling
      INTEGER :: nin, nvarel, nelow, nelup, istrgv, iendgv, ifstat, igstat
      REAL :: time_in, time_out
      LOGICAL :: nontrv
      INTEGER, DIMENSION( 1 ) :: ICALCG
      EXTERNAL :: RANGE

      IF ( work%record_times ) CALL CPU_TIME( time_in )

!  check input parameters

      IF ( iprob < 0 ) THEN
        IF ( data%out > 0 ) WRITE( data%out, "( ' ** SUBROUTINE CISGRP: ',     &
       &    'invalid constraint index iprob ' )" )
        status = 2 ; GO TO 990
      END IF

!  constraint gradient required

      IF ( iprob > 0 ) THEN

!  find group index ig of constraint iprob

        ig = 0
        DO i = 1, data%ng
          IF ( data%KNDOFC( i ) == iprob ) THEN
            ig = i
            EXIT
          END IF
        END DO
        IF ( ig == 0 ) THEN
          IF ( data%out > 0 ) WRITE( data%out, "( ' ** SUBROUTINE CISGRP: ',   &
         &    'invalid constraint index iprob ' )" )
          status = 2 ; GO TO 990
        END IF
      END IF

!  Use ISWKSP to flag which variables have nonzero partial derivatives

      work%ISWKSP( : data%n ) = 0
      nnzgr = 0

!  constraint gradient required

      IF ( iprob > 0 ) THEN
        ig1 = ig + 1

!  the group has nonlinear elements

        IF ( data%ISTADG( ig ) <= data%ISTADG( ig1 ) - 1 ) THEN

!  allocate a gradient

!DIR$ IVDEP
          DO i = data%ISTAGV( ig ), data%ISTAGV( ig1 ) - 1
            ll = data%ISVGRP( i )

!  include the contributions from only the first n variables

            IF ( ll <= n ) THEN
              IF ( work%ISWKSP( ll ) == 0 ) THEN
                nnzgr = nnzgr + 1
                work%ISWKSP( ll ) = nnzgr
                GR_var( nnzgr ) = ll
              END IF
            END IF
          END DO

!  the group has only linear elements

        ELSE

!  allocate a gradient

!DIR$ IVDEP
          DO k = data%ISTADA( ig ), data%ISTADA( ig1 ) - 1
            ll = data%ICNA( k )

!  include the contributions from linear elements for only the first n
!  variables

            IF ( ll <= n ) THEN
              IF ( work%ISWKSP( ll ) == 0 ) THEN
                nnzgr = nnzgr + 1
                work%ISWKSP( ll ) = nnzgr
                GR_var( nnzgr ) = ll
              END IF
            END IF
          END DO
        END IF

!  objective gradient required

      ELSE

!  loop over the groups

        DO ig = 1, data%ng

!  consider only those groups in the objective function

          IF ( data%KNDOFC( ig ) > 0 ) CYCLE
          ig1 = ig + 1

!  the group has nonlinear elements

          IF ( data%ISTADG( ig ) <= data%ISTADG( ig1 ) - 1 ) THEN

!  allocate a gradient

!DIR$ IVDEP
            DO i = data%ISTAGV( ig ), data%ISTAGV( ig1 ) - 1
              ll = data%ISVGRP( i )

!  include the contributions from only the first n variables

              IF ( ll <= n ) THEN
                IF ( work%ISWKSP( ll ) == 0 ) THEN
                  nnzgr = nnzgr + 1
                  work%ISWKSP( ll ) = nnzgr
                  GR_var( nnzgr ) = ll
                END IF
              END IF
            END DO

!  the group has only linear elements

          ELSE

!DIR$ IVDEP
            DO k = data%ISTADA( ig ), data%ISTADA( ig1 ) - 1
              ll = data%ICNA( k )

!  include the contributions from linear elements for only the first n
!  variables

              IF ( ll <= n ) THEN
                IF ( work%ISWKSP( ll ) == 0 ) THEN
                  nnzgr = nnzgr + 1
                  work%ISWKSP( ll ) = nnzgr
                  GR_var( nnzgr ) = ll
                END IF
              END IF
            END DO
          END IF
        END DO
      END IF
      work%nbprod = 0
      work%ISWKSP( : data%n ) = 0
      status = 0

!  update elapsed CPU time if required

  990 CONTINUE
      IF ( work%record_times ) THEN
        CALL CPU_TIME( time_out )
        work%time_cisgrp = work%time_cisgrp + time_out - time_in
      END IF
      RETURN

!  end of subroutine CUTEST_cisgrp_threadsafe

      END SUBROUTINE CUTEST_cisgrp_threadsafe
