! Fortran 2023 — syntax showcase (gfortran is not installed locally; `assign`/`pause` removed forms dropped)
! ── Comments ──
! Line comment. TODO: parallelise the loops. FIXME: check array bounds.
!> Doxygen-style comment for the module.
!! Continuation of a documentation comment.
!$omp parallel
!$acc kernels
#define WAREHOUSE_VERSION "1.0"
#ifdef USE_MPI
#include "mpif.h"
#endif

! ── Module with types, interfaces and procedures ──
module warehouse_stock
  use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64, error_unit, output_unit
  use, intrinsic :: iso_c_binding
  use, intrinsic :: ieee_arithmetic
  implicit none
  private
  public :: item_t, bin_t, assignment(=), operator(.stocked.)
  public :: clamp, total_value, describe, status_code

  ! ── Parameters and literals ──
  integer, parameter :: dp = real64
  integer, parameter :: max_bins = 64
  integer(int64), parameter :: big = 1000000_int64
  integer, parameter :: hex = z'FF', octal = o'755', binary = b'10101010'
  real(dp), parameter :: pi = 3.14159265358979_dp
  real(dp), parameter :: avogadro = 6.02214076e23_dp
  real(real32), parameter :: small = 1.5E-10
  real(dp), parameter :: dexp = 2.5d3
  complex(dp), parameter :: imag = (1.0_dp, -2.0_dp)
  logical, parameter :: yes = .true., no = .false.
  character(len=*), parameter :: greeting = "Warehouse ""north"" ready"
  character(len=*), parameter :: single = 'It''s a ''single'' string'
  character(len=1), parameter :: tab = achar(9), newline = new_line('a')
  character(kind=c_char, len=*), parameter :: c_text = c_char_"c string"//c_null_char
  integer, parameter :: array_lit(3) = [1, 2, 3]
  integer, parameter :: old_array(3) = (/ 1, 2, 3 /)

  ! ── Derived types ──
  type :: item_t
     character(len=16) :: sku = ''
     integer :: qty = 0
     real(dp) :: price = 0.0_dp
     character(len=:), allocatable :: notes
     real(dp), dimension(3) :: dims = [0.0_dp, 0.0_dp, 0.0_dp]
   contains
     procedure :: total => item_total
     procedure, pass(self) :: restock
     procedure, nopass :: version
     generic :: operator(+) => add_items
     procedure, private :: add_items
     final :: item_cleanup
  end type item_t

  type, extends(item_t) :: bin_t
     integer :: capacity = 500
     type(item_t), allocatable :: items(:)
     class(item_t), pointer :: head => null()
  end type bin_t

  type, abstract :: auditable
   contains
     procedure(audit_iface), deferred :: audit
  end type auditable

  type :: matrix_t(k, n)
     integer, kind :: k = real64
     integer, len :: n = 3
     real(k) :: data(n, n)
  end type matrix_t

  enum, bind(c)
     enumerator :: tools = 1, fasteners, safety = 10
  end enum

  ! ── Interfaces ──
  interface operator(.stocked.)
     module procedure is_stocked
  end interface

  interface assignment(=)
     module procedure assign_item
  end interface

  interface clamp
     module procedure clamp_int, clamp_real
  end interface clamp

  abstract interface
     subroutine audit_iface(self)
       import :: auditable
       class(auditable), intent(in) :: self
     end subroutine audit_iface
  end interface

  interface
     function c_strlen(s) bind(c, name="strlen") result(n)
       import :: c_char, c_size_t
       character(kind=c_char), intent(in) :: s(*)
       integer(c_size_t) :: n
     end function c_strlen
  end interface

contains

  ! ── Functions and subroutines ──
  pure function item_total(self) result(total)
    class(item_t), intent(in) :: self
    real(dp) :: total
    total = self%qty * self%price
  end function item_total

  elemental function clamp_real(x, lo, hi) result(y)
    real(dp), intent(in) :: x, lo, hi
    real(dp) :: y
    y = max(lo, min(hi, x))
  end function clamp_real

  elemental integer function clamp_int(x, lo, hi)
    integer, intent(in) :: x, lo, hi
    clamp_int = max(lo, min(hi, x))
  end function clamp_int

  recursive function factorial(n) result(f)
    integer, intent(in) :: n
    integer(int64) :: f
    if (n <= 1) then
       f = 1
    else
       f = n * factorial(n - 1)
    end if
  end function factorial

  subroutine restock(self, delta)
    class(item_t), intent(inout) :: self
    integer, intent(in) :: delta
    self%qty = self%qty + delta
  end subroutine restock

  function version() result(v)
    character(len=:), allocatable :: v
    v = WAREHOUSE_VERSION
  end function version

  function add_items(a, b) result(c)
    type(item_t), intent(in) :: a, b
    type(item_t) :: c
    c = a
    c%qty = a%qty + b%qty
  end function add_items

  subroutine assign_item(lhs, rhs)
    type(item_t), intent(out) :: lhs
    character(len=*), intent(in) :: rhs
    lhs%sku = rhs
  end subroutine assign_item

  logical function is_stocked(item)
    type(item_t), intent(in) :: item
    is_stocked = item%qty > 0
  end function is_stocked

  subroutine item_cleanup(self)
    type(item_t), intent(inout) :: self
    if (allocated(self%notes)) deallocate(self%notes)
  end subroutine item_cleanup

  pure function total_value(items) result(v)
    type(item_t), intent(in) :: items(:)
    real(dp) :: v
    v = sum(items%qty * items%price)
  end function total_value

  function describe(item) result(text)
    type(item_t), intent(in) :: item
    character(len=:), allocatable :: text
    character(len=64) :: buffer
    write(buffer, '(A, ": ", I0, " @ ", F8.2)') trim(item%sku), item%qty, item%price
    text = trim(buffer)
  end function describe

  integer function status_code(item) result(code)
    type(item_t), intent(in) :: item
    select case (item%qty)
    case (0)
       code = 0
    case (1:4)
       code = 1
    case (5:)
       code = 2
    case default
       code = -1
    end select
  end function status_code

end module warehouse_stock

! ── Main program ──
program sample
  use warehouse_stock
  use, intrinsic :: iso_fortran_env, only: output_unit
  implicit none

  integer, parameter :: n = 3
  type(item_t) :: swarm(n)
  type(item_t) :: obj_holder
  integer :: i, j, k, ios, unit
  integer, allocatable :: counts(:)
  real(8) :: total, matrix(3, 3), vec(3)
  character(len=32) :: line, fmt
  logical :: flag
  integer, target :: tgt
  integer, pointer :: ptr => null()
  real, dimension(:,:), allocatable :: grid
  external :: legacy_routine
  intrinsic :: sin, cos
  data vec /1.0, 2.0, 3.0/
  namelist /config/ n, flag
  integer :: coarray[*]
  real, volatile :: vol
  real, asynchronous :: asyn
  integer, save :: counter = 0

  ! ── Assignment and expressions ──
  do i = 1, n
     swarm(i)%sku = 'A-100'
     swarm(i)%qty = i * 5
     swarm(i)%price = 4.5d0 * i
  end do
  total = total_value(swarm)
  flag = (total > 10.0d0) .and. .not. (n == 0) .or. (n /= 3) .eqv. .true.
  flag = flag .neqv. (total <= 5.0d0 .and. total >= 1.0d0)
  vec = vec ** 2 + 2.0 * vec - vec / 2.0
  matrix = reshape([(real(k), k = 1, 9)], [3, 3])
  matrix(:, 1) = vec
  matrix(2, :) = 0.0
  matrix(1:2, 2:3) = transpose(matrix(2:3, 1:2))
  allocate(counts(10), grid(4, 4), stat=ios)
  counts = [(i * i, i = 1, 10)]
  counts(2:10:2) = 0
  where (counts > 50) counts = 50
  forall (i = 1:3, j = 1:3, i /= j) matrix(i, j) = 0.0
  tgt = 5
  ptr => tgt
  associate (first => swarm(1), qty => swarm(1)%qty)
     print *, first%sku, qty
  end associate

  ! ── Control flow ──
  if (total > 100.0d0) then
     print *, 'large'
  else if (total > 10.0d0) then
     print *, 'medium'
  else
     print *, 'small'
  end if

  if (flag) print *, 'flagged'

  select case (n)
  case (1)
     print *, 'one'
  case (2, 3)
     print *, 'few'
  case default
     print *, 'many'
  end select

  outer: do i = 1, 3
     inner: do j = 1, 3
        if (j == 2) cycle inner
        if (i == 3) exit outer
     end do inner
  end do outer

  do while (n > 0)
     n = n - 1
  end do

  do concurrent (i = 1:3)
     total = total + swarm(i)%total()
  end do

  do 100 i = 1, 3
100  continue

  block
     integer :: scratch
     scratch = 1
  end block

  ! ── I/O ──
  print '(A, F8.3)', 'Total kinetic energy: ', total
  print *, 'list-directed', total, n
  write(*, '(A, I0, 1X, ES12.4)') 'value ', n, total
  write(output_unit, "(2(I4, 1X), T10, 'text', /, F6.2)") 1, 2, 3.14159
  open(newunit=unit, file='stock.txt', status='replace', action='write', iostat=ios)
  if (ios /= 0) stop 'open failed'
  write(unit, *) swarm(1)%sku
  rewind(unit)
  read(unit, '(A)', iostat=ios, end=900) line
  close(unit)
900 continue
  inquire(file='stock.txt', exist=flag)
  fmt = '(I5, 2F10.3)'
  write(*, fmt) 1, 2.0, 3.0
  read(line, *) k
  write(line, '(I0)') k

  ! ── Intrinsics and misc ──
  print *, size(counts), shape(matrix), lbound(counts, 1), ubound(counts, 1)
  print *, sum(vec), product(vec), maxval(vec), minloc(vec), dot_product(vec, vec)
  print *, sqrt(2.0), exp(1.0), log(10.0), sin(pi / 2), abs(-1), mod(7, 3), modulo(-7, 3)
  print *, trim(adjustl('  padded  ')), len_trim('abc'), index('stock', 'oc'), 'a' // 'b'
  print *, huge(1), tiny(1.0), epsilon(1.0d0), selected_real_kind(15, 307)
  print *, ieee_is_nan(0.0), merge(1, 2, flag)
  call random_number(vec)
  call system_clock(count=k)
  call legacy_routine(n)
  call move_alloc(counts, counts)
  deallocate(counts, grid)
  nullify(ptr)
  ! ── Less common statements ──
  entry_demo: if (.true.) then
     print *, 'construct name'
  end if entry_demo
  critical
     print *, 'critical section'
  end critical
  sync all
  sync memory
  lock_demo: block
     print *, 'locked'
  end block lock_demo
  select type (obj => swarm(1))
  type is (item_t)
     print *, 'item'
  class is (item_t)
     print *, 'class'
  class default
     print *, 'default'
  end select
  select rank (vec)
  rank (1)
     print *, 'rank one'
  rank default
     print *, 'other'
  end select
  if (n > 0) goto 20
20 continue
  arith: if (k > 0) then
     k = k - 1
  elseif (k < 0) then
     k = k + 1
  endif arith
  print *, 1.0e0, 1.0d0, .5, 5., 1_int32, 2_8, 1.0_real64, (1.0, 2.0), .TRUE., .FALSE.
  print *, 'concat' // " both " // 'quotes'
  print *, 5 .eq. 5, 5 .ne. 4, 3 .lt. 4, 3 .le. 4, 5 .gt. 4, 5 .ge. 4
  print *, [integer :: 1, 2, 3], [character(len=3) :: 'a', 'bb']
  print *, z'1F', o'17', b'101', x'FF'
  print *, achar(65), iachar('A'), char(66), ichar('B'), ishft(1, 3), iand(5, 3), ior(5, 3), ieor(5, 3), not(5)
  open(unit=10, file='log.txt', form='formatted', access='sequential', position='append', action='write')
  flush(10)
  backspace(10)
  endfile(10)
  close(10, status='delete')
  allocate(character(len=10) :: line)
  write(*, nml=config)
  read(*, nml=config, iostat=ios)
  call execute_command_line('echo hello', wait=.true.)
  call get_command_argument(1, line)
  call date_and_time(date=line)
  call cpu_time(total)
  call co_sum(total)
  print *, this_image(), num_images()
  continue
  error stop 'fatal'
  stop
end program sample

subroutine legacy_routine(n)
  integer n
  goto 10
10 continue
  n = n + 1
  return
end subroutine legacy_routine

! ── Fortran 2008-2023 and legacy forms ──
module extras_m
  use, intrinsic :: iso_fortran_env, only: team_type, event_type, lock_type, atomic_int_kind
  use, intrinsic :: iso_c_binding, only: c_ptr, c_funptr, c_f_pointer, c_loc, c_int, c_double
  implicit none
  private
  public :: shape_t, simple_add, procedure_pointer_demo, teams_demo, stmt_demo

  abstract interface
     real function binary_op(a, b)
       real, intent(in) :: a, b
     end function binary_op
  end interface

  type, abstract :: shape_t
     real :: scale = 1.0
   contains
     procedure(area_i), deferred :: area
     procedure, non_overridable :: name => shape_name
  end type shape_t

  abstract interface
     function area_i(self) result(a)
       import :: shape_t
       class(shape_t), intent(in) :: self
       real :: a
     end function area_i
  end interface

  interface
     module function sub_total(x) result(r)
       real, intent(in) :: x(:)
       real :: r
     end function sub_total
  end interface

  integer, protected :: protected_count = 0
  real, contiguous, pointer :: window(:) => null()
  integer, parameter :: wide = selected_int_kind(18)
  common /legacy_block/ legacy_a, legacy_b
  real :: legacy_a, legacy_b
  equivalence (legacy_a, alias_a)
  real :: alias_a
  save :: protected_count
  parameter (legacy_limit = 10)

contains

  function shape_name(self) result(n)
    class(shape_t), intent(in) :: self
    character(len=:), allocatable :: n
    n = 'shape'
  end function shape_name

  ! F2023: SIMPLE procedures
  simple function simple_add(a, b) result(c)
    real, intent(in) :: a, b
    real :: c
    c = a + b
  end function simple_add

  subroutine procedure_pointer_demo()
    procedure(binary_op), pointer :: op => null()
    procedure(real), pointer :: unary => null()
    op => plus
    print *, op(1.0, 2.0)
  contains
    real function plus(a, b)
      real, intent(in) :: a, b
      plus = a + b
    end function plus
  end subroutine procedure_pointer_demo

  subroutine teams_demo()
    type(team_type) :: team
    type(event_type) :: ev[*]
    type(lock_type) :: lk[*]
    integer(atomic_int_kind) :: counter[*]
    integer :: value, status
    character(len=128) :: msg
    form team (1 + mod(this_image(), 2), team, stat=status, errmsg=msg)
    change team (team, stat=status)
       sync team (team)
    end team
    event post (ev[1])
    event wait (ev, until_count=1)
    lock (lk[1])
    unlock (lk[1])
    sync images (*)
    sync images ([1, 2], stat=status)
    call atomic_define(counter[1], 5)
    call atomic_ref(value, counter[1])
    if (failed_images_exist()) fail image
    error stop 'quiet', quiet=.true.
  contains
    logical function failed_images_exist()
      failed_images_exist = size(failed_images()) > 0
    end function failed_images_exist
  end subroutine teams_demo

  subroutine stmt_demo(x, n)
    integer, intent(in) :: n
    real, intent(inout) :: x(n)
    real :: poly, t
    integer :: i
    poly(t) = 1.0 + t * (2.0 + t * 3.0)   ! statement function
    do i = 1, n
       x(i) = poly(x(i))
    end do
    ! F2023: reduce locality spec on DO CONCURRENT
    block
      real :: acc
      acc = 0.0
      do concurrent (i = 1:n) local(t) local_init(acc) reduce(+: acc)
         t = x(i)
      end do
    end block
    where (x > 10.0)
       x = 10.0
    elsewhere (x < 0.0)
       x = 0.0
    elsewhere
       x = x
    end where
    forall (i = 1:n) x(i) = x(i) + 1
    write(*, 100) n
100 format('n = ', I0)
    write(*, '(A)') 'format edit descriptors: '
    write(*, '(I5.3, F8.2, E12.4, ES10.2, EN10.2, D12.4, G12.4, L3, A5, Z8, O8, B8, 3X, T20, TL2, TR2, /, SP, SS, S, BN, BZ, DC, DP, RU, RD, RZ, RN, RC, RP)') &
         1, 2.0, 3.0, 4.0, 5.0, 6.0d0, 7.0, .true., 'abc', 255, 8, 5
  end subroutine stmt_demo

end module extras_m

submodule (extras_m) extras_impl
contains
  module function sub_total(x) result(r)
    real, intent(in) :: x(:)
    real :: r
    r = sum(x)
  end function sub_total
end submodule extras_impl

block data legacy_data
  common /legacy_block/ la, lb
  real :: la, lb
  data la /1.0/, lb /2.0/
end block data legacy_data

subroutine entry_demo(a)
  real a, b
  entry other_entry(b)
  a = 0.0
  return
end subroutine entry_demo

subroutine c_interop(arr, n) bind(c, name="c_interop")
  use, intrinsic :: iso_c_binding
  integer(c_int), value :: n
  real(c_double), intent(inout) :: arr(*)
  type(*), dimension(..) :: anything
  arr(1:n) = 0.0_c_double
end subroutine c_interop

subroutine ftn_misc(x)
  real :: x
  integer :: i
  logical :: l
  character(len=20) :: s
  import_demo: block
    implicit none (type, external)
  end block import_demo
  i = 5
  if (i > 0) then; x = 1.0; end if
  if (i < 0) x = -1.0; x = x + 1.0
  s = "double ""quoted"" and 'single'"
  l = (x .gt. 0.0) .and. (x .lt. 5.0)
  select case (s(1:1))
  case ('a':'m')
     x = 1.0
  case ('n':)
     x = 2.0
  end select
  ! computed goto and arithmetic if are obsolescent but valid
  goto (10, 20), i
10 continue
20 continue
  if (x) 30, 40, 50
30 continue
40 continue
50 continue
end subroutine ftn_misc
