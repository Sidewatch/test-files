! Fortran 2008: a module with a derived type and a program that uses it.
module particles
  implicit none
  private
  public :: particle, kinetic_energy

  type :: particle
     real(8) :: mass = 1.0d0
     real(8) :: velocity(3) = 0.0d0
  end type particle

contains

  pure function kinetic_energy(p) result(e)
    type(particle), intent(in) :: p
    real(8) :: e
    e = 0.5d0 * p%mass * sum(p%velocity**2)
  end function kinetic_energy

end module particles

program sample
  use particles
  implicit none
  integer, parameter :: n = 3
  type(particle) :: swarm(n)
  integer :: i
  real(8) :: total

  do i = 1, n
     swarm(i)%mass = real(i, 8)
     swarm(i)%velocity = [1.0d0, 0.5d0 * i, 0.0d0]
  end do

  total = 0.0d0
  do concurrent (i = 1:n)
     total = total + kinetic_energy(swarm(i))
  end do
  print '(A, F8.3)', 'Total kinetic energy: ', total
end program sample
