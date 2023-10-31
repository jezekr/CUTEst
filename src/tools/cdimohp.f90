! THIS VERSION: CUTEST 2.1 - 2023-10-31 AT 08:30 GMT.

!-*-*-*-*-*-*-  C U T E S T    C D I M C O P    S U B R O U T I N E  -*-*-*-*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   modern fortran version released in CUTEst, 31st October 2023

      SUBROUTINE CUTEST_cdimohp( status, nnzohp )
      USE CUTEST

!  dummy arguments

      INTEGER, INTENT( OUT ) :: status, nnzohp

!  -----------------------------------------------------------------
!  compute the space required to store the matrix of products of the 
!  constraint Hessians with a vector of a problem initially written 
!  in Standard Input Format (SIF)
!  -----------------------------------------------------------------

      CALL CUTEST_cdimohp_threadsafe( CUTEST_data_global,                      &
                                      CUTEST_work_global( 1 ),                 &
                                      status, nnzohp )
      RETURN

!  end of sunroutine CUTEST_cdimohp

      END SUBROUTINE CUTEST_cdimohp

!-  C U T E S T   C D I M C O P _ t h r e a d s a f e   S U B R O U T I N E  -

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   modern fortran version released in CUTEst, 31st October 2023

      SUBROUTINE CUTEST_cdimohp_threadsafe( data, work, status, nnzohp )
      USE CUTEST

!  dummy arguments

      TYPE ( CUTEST_data_type ), INTENT( IN ) :: data
      TYPE ( CUTEST_work_type ), INTENT( INOUT ) :: work
      INTEGER, INTENT( OUT ) :: status, nnzohp

!  -----------------------------------------------------------------
!  compute the space required to store the matrix of products of the 
!  constraint Hessians with a vector of a problem initially written 
!  in Standard Input Format (SIF)
!  -----------------------------------------------------------------

!  local variables

      INTEGER ::  ii, iel, iell, ig, j, k, l, ll

!  record the total space is stored in nnzohp

      nnzohp = 0

!  loop over all the groups, but ignore those that are constraints

      DO ig = 1, data%ng
        IF ( data%KNDOFC( ig ) == 0 ) THEN

!  store the nonzeros of the Hessian-vector product in W_ws

!  =========================== rank-one terms ============================

!  if the ig-th group is non-trivial, the indices of its rank-one term
!  grad h_ig * g''(h_ig) * grad(trans) h_ig, occur in the sparsity pattern
!  of H * v

          IF ( .NOT. data%GXEQX( ig ) ) THEN
            DO l = data%ISTAGV( ig ), data%ISTAGV( ig + 1 ) - 1
              j = data%ISVGRP( l )
              IF ( work%IUSED( j ) == 0 ) THEN
                work%IUSED( j ) = 1
                nnzohp = nnzohp + 1
              END IF
            END DO

!  ======================= second-order terms =======================

!  otherwise the indices of the second order term g'(h_ig) * Hess h_ig
!  (which is a subset of those for the rank-one term) occur in the 
!  sparsity pattern of H * v

          ELSE

!  consider all nonlinear elements for the group

            DO iell = data%ISTADG( ig ), data%ISTADG( ig + 1 ) - 1
              iel = data%IELING( iell )
               DO l = data%ISTAEV( iel ), data%ISTAEV( iel + 1 ) - 1
                 j = data%IELVAR( l )
                 IF ( work%IUSED( j ) == 0 ) THEN
                   work%IUSED( j ) = 1
                   nnzohp = nnzohp + 1
                 END IF
               END DO
            END DO
          END IF
        END IF
      END DO

!  reset IUSED to zero

      DO ig = 1, data%ng
        IF ( data%KNDOFC( ig ) == 0 )                                          &
          work%IUSED( data%ISVGRP( data%ISTAGV( ig ) :                         &
                                   data%ISTAGV( ig + 1 ) - 1 ) ) = 0
      END DO

      status = 0
      RETURN

!  end of sunroutine CUTEST_cdimohp_threadsafe

      END SUBROUTINE CUTEST_cdimohp_threadsafe
