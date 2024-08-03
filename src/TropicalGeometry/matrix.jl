################################################################################
#
#  Tropical matrices
#
################################################################################


################################################################################
#
#  Substraction-less tropical alternatives to generic functions
#
################################################################################

@doc raw"""
    det(A::MatrixElem{<: TropicalSemiringElem})

Return the tropical determinant of `A`.  That is, this function evaluates the tropicalization of the ordinary determinant considered as a multivariate polynomial at `A`.

That computation is equivalent to solving a linear assignment problem from combinatorial optimization.  The implementation employs the Hungarian method, which is polynomial time.  See Chapter 3 in [Jos21](@cite).

!!! note
    This function effectively overwrites the `det` command for tropical matrices.  This means that functions like `minors` will use the tropical determinant when used on a tropical matrix.

# Examples
```jldoctest
julia> A = matrix(tropical_semiring(),[1 2; 3 4])
[(1)   (2)]
[(3)   (4)]

julia> det(A)
(5)
```
"""
function det(A::MatrixElem{<:TropicalSemiringElem})
  @req nrows(A) == ncols(A) "Non-square matrix"
  T = base_ring(A)
  return T(Polymake.tropical.tdet(A))
end

function det(A::Matrix{<:TropicalSemiringElem})
  @req 0 < nrows(A) == ncols(A) "Non-square or empty matrix"
  return det(matrix(parent(first(A)),A))
end

@doc raw"""
    is_tropically_generic(A::MatrixElem{<:TropicalSemiringElem})

Check if a collection of vectors in the tropical torus (given as rows of a matrix `A`) are in tropical general position.

# Examples
```jldoctest
julia> A = matrix(tropical_semiring(),[1 0;0 1])
[(1)   (0)]
[(0)   (1)]

julia> is_tropically_generic(A)
true
```
"""
function is_tropically_generic(A::MatrixElem{<:TropicalSemiringElem})
  function helper(A,C,B)
    for b in subsets(C,B)
      Polymake.tropical.tsgn(A[b,:]) == 0 && return false
    end
    return true
  end
  nca = ncols(A)
  nra = nrows(A)
  if nca == nra
    return Polymake.tropical.tsgn(A) != 0
  elseif nra>nca
    return helper(A,nra,nca)
  else 
    return helper(transpose(A),nca,nra)
  end
end

@doc raw"""
    is_polytrope(A::MatrixElem{<:TropicalSemiringElem})

Check if a tropical polytope is ordinarily convex (ie a polytrope)

# Examples
```jldoctest
julia> A = tropical_semiring()[0 0 1; 0 1 0; 0 3 3]
[(0)   (0)   (1)]
[(0)   (1)   (0)]
[(0)   (3)   (3)]

julia> is_polytrope(A)
true
```
"""
function is_polytrope(A::MatrixElem{<:TropicalSemiringElem})
  #=Convert the matrix of tropical numbers into matrix of rational numbers in
  to pass it into polymake's tropical convex hull function =#
  ncA = ncols(A)
  nrA = nrows(A)
  QQA = zero_matrix(QQ,nrA,ncA)
  for i in 1:nrA
    for j in 1:ncA
      @req A[i,j] != zero(tropical_semiring(convention(A))) "If infty is an entry then the tropical polytope is not bounded"
      QQA[i,j] += QQ(A[i,j])
    end
  end
  #Compute the tropical convex hull 
  tempP = Polymake.tropical.Polytope{convention(A)}(POINTS=QQA)
  #=Compute the tropical convex hull again, this time with 
  the minimal generating set of vertices of tropical polytope=#
  P = Polymake.tropical.Polytope{convention(A)}(POINTS=tempP.VERTICES)
  PMCV = P.POLYTOPE_MAXIMAL_COVECTORS
  Polymake.Shell.CV = PMCV
  #Get the length out of the polymake shell
  Polymake.shell_execute(raw"""$tmp = $CV->size;""")
  l = Polymake.Shell.tmp
  l != 1 && return false
  return true
end

function is_polytrope_old(A::QQMatrix, MorM)
  tempP = Polymake.tropical.Polytope{MorM}(POINTS=A)
  P = Polymake.tropical.Polytope{MorM}(POINTS=tempP.VERTICES)
  pPMCV = P.POLYTOPE_MAXIMAL_COVECTORS
  Polymake.Shell.CV = pPMCV
  Polymake.shell_execute(raw"""$tmp = $CV->size;""")
  l = Polymake.Shell.tmp
  l != 1 && return false
  return true
end
