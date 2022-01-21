###############################################################################
###############################################################################
### Iterators
###############################################################################
###############################################################################

rays(as::Type{RayVector{T}}, C::Cone) where T = SubObjectIterator{as}(pm_object(C), _ray_cone, nrays(C))

_ray_cone(::Type{T}, C::Polymake.BigObject, i::Base.Integer) where T = T(C.RAYS[i, :])

_vector_matrix(::Val{_ray_cone}, C::Polymake.BigObject; homogenized=false) = C.RAYS

_matrix_for_polymake(::Val{_ray_cone}) = _vector_matrix

rays(::Type{RayVector}, C::Cone{T}) where T<:scalar_types = rays(RayVector{T}, C)

@doc Markdown.doc"""
    rays(C::Cone)

Return the rays of `C`.

# Examples
Here a cone is constructed from three rays. Calling `rays` reveals that one of these was redundant:
```jldoctest
julia> R = [1 0; 0 1; 0 2];

julia> PO = positive_hull(R);

julia> rays(PO)
2-element SubObjectIterator{RayVector{Polymake.Rational}}:
 [1, 0]
 [0, 1]
```
"""
rays(C::Cone{T}) where T<:scalar_types = rays(RayVector{T}, C)

@doc Markdown.doc"""
    faces(C::Cone, face_dim::Int)

Return an iterator over the faces of `C` of dimension `face_dim`.

# Examples
Each 2-dimensional face of the 3-dimensional positive orthant is generated by
two pairwise distinct unit vectors.
```jldoctest
julia> PO = cone_from_inequalities([-1 0 0; 0 -1 0; 0 0 -1])
A polyhedral cone in ambient dimension 3

julia> for f in faces(PO, 2)
       println(rays(f))
       end
RayVector{Polymake.Rational}[[0, 1, 0], [0, 0, 1]]
RayVector{Polymake.Rational}[[1, 0, 0], [0, 0, 1]]
RayVector{Polymake.Rational}[[1, 0, 0], [0, 1, 0]]
```
"""
function faces(C::Cone{T}, face_dim::Int) where T<:scalar_types
   face_dim == dim(C) - 1 && return SubObjectIterator{Cone{T}}(pm_object(C), _face_cone_facet, nfacets(C))
   n = face_dim - length(lineality_space(C))
   n < 1 && return nothing
   return SubObjectIterator{Cone{T}}(C.pm_cone, _face_cone, size(Polymake.polytope.faces_of_dim(pm_object(C), n), 1), (f_dim = n,))
end

function _face_cone(::Type{Cone{T}}, C::Polymake.BigObject, i::Base.Integer; f_dim::Int = 0) where T<:scalar_types
   return Cone{T}(Polymake.polytope.Cone{scalar_type_to_polymake[T]}(RAYS = C.RAYS[collect(Polymake.to_one_based_indexing(Polymake.polytope.faces_of_dim(C, f_dim)[i])), :], LINEALITY_SPACE = C.LINEALITY_SPACE))
end

function _ray_indices(::Val{_face_cone}, C::Polymake.BigObject; f_dim::Int = 0)
   f = Polymake.to_one_based_indexing(Polymake.polytope.faces_of_dim(C, f_dim))
   return IncidenceMatrix([collect(f[i]) for i in 1:length(f)])
end

function _face_cone_facet(::Type{Cone{T}}, C::Polymake.BigObject, i::Base.Integer) where T<:scalar_types
   return Cone{T}(Polymake.polytope.Cone{scalar_type_to_polymake[T]}(RAYS = C.RAYS[collect(C.RAYS_IN_FACETS[i, :]), :], LINEALITY_SPACE = C.LINEALITY_SPACE))
end

_ray_indices(::Val{_face_cone_facet}, C::Polymake.BigObject) = C.RAYS_IN_FACETS

###############################################################################
###############################################################################
### Access properties
###############################################################################
###############################################################################

###############################################################################
## Scalar properties
###############################################################################
@doc Markdown.doc"""
    nfacets(C::Cone)

Return the number of facets of a cone `C`.

# Examples
The cone over a square at height one has four facets.
```jldoctest
julia> C = positive_hull([1 0 0; 1 1 0; 1 1 1; 1 0 1])
A polyhedral cone in ambient dimension 3

julia> nfacets(C)
4
```
"""
nfacets(C::Cone) = pm_object(C).N_FACETS::Int

@doc Markdown.doc"""
    nrays(C::Cone)

Return the number of rays of `C`.

# Examples
Here a cone is constructed from three rays. Calling `nrays` reveals that one of these was redundant:
```jldoctest
julia> R = [1 0; 0 1; 0 2];

julia> PO = positive_hull(R);

julia> nrays(PO)
2
```
"""
nrays(C::Cone) = pm_object(C).N_RAYS::Int

@doc Markdown.doc"""
    dim(C::Cone)

Return the dimension of `C`.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```jldoctest
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> dim(C)
2
```
"""
dim(C::Cone) = pm_object(C).CONE_DIM::Int

@doc Markdown.doc"""
    ambient_dim(C::Cone)

Return the ambient dimension of `C`.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```jldoctest
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> ambient_dim(C)
3
```
"""
ambient_dim(C::Cone) = pm_object(C).CONE_AMBIENT_DIM::Int

@doc Markdown.doc"""
    codim(C::Cone)

Return the codimension of `C`.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```jldoctest
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> codim(C)
1
```
"""
codim(C::Cone) = ambient_dim(C)-dim(C)


@doc Markdown.doc"""
    f_vector(C::Cone)

Compute the vector $(f₁,f₂,...,f_{(dim(C)-1))$` where $f_i$ is the number of
faces of $C$ of dimension $i$.

# Examples
Take the cone over a square, then the f-vector of the cone is the same as of the square.
```jldoctest
julia> C = positive_hull([1 0 0; 1 1 0; 1 1 1; 1 0 1])
A polyhedral cone in ambient dimension 3

julia> f_vector(C)
2-element Vector{Polymake.Integer}:
 4
 4

julia> square = cube(2)
A polyhedron in ambient dimension 2

julia> f_vector(square)
2-element Vector{Int64}:
 4
 4
```
"""
function f_vector(C::Cone)
    pmc = pm_object(C)
    ldim = pmc.LINEALITY_DIM
    return vcat(fill(0,ldim),pmc.F_VECTOR)
end


@doc Markdown.doc"""
    lineality_dim(C::Cone)

Compute the dimension of the lineality space of $C$, i.e. the largest linear
subspace contained in $C$.

# Examples
A cone is pointed if and only if the dimension of its lineality space is zero.
```jldoctest
julia> C = positive_hull([1 0 0; 1 1 0; 1 1 1; 1 0 1])
A polyhedral cone in ambient dimension 3

julia> ispointed(C)
true

julia> lineality_dim(C)
0

julia> C1 = Cone([1 0],[0 1; 0 -1])
A polyhedral cone in ambient dimension 2

julia> ispointed(C1)
false

julia> lineality_dim(C1)
1
```
"""
lineality_dim(C::Cone) = pm_object(C).LINEALITY_DIM::Int



###############################################################################
## Boolean properties
###############################################################################
@doc Markdown.doc"""
    ispointed(C::Cone)

Determine whether `C` is pointed, i.e. whether the origin is a face of `C`.

# Examples
A cone with lineality is not pointed, but a cone only consisting of a single ray is.
```jldoctest
julia> C = Cone([1 0], [0 1]);

julia> ispointed(C)
false

julia> C = Cone([1 0]);

julia> ispointed(C)
true
```
"""
ispointed(C::Cone) = pm_object(C).POINTED::Bool

@doc Markdown.doc"""
    isfulldimensional(C::Cone)

Determine whether `C` is full-dimensional.

# Examples
The cone `C` in this example is 2-dimensional within a 3-dimensional ambient space.
```jldoctest
julia> C = Cone([1 0 0; 1 1 0; 0 1 0]);

julia> isfulldimensional(C)
false
```
"""
isfulldimensional(C::Cone) = pm_object(C).FULL_DIM::Bool

###############################################################################
## Points properties
###############################################################################

# TODO: facets as `Vector`? or `Matrix`?
@doc Markdown.doc"""
    facets(as::Type{T} = LinearHalfspace, C::Cone)

Return the facets of `C` in the format defined by `as`.

The allowed values for `as` are
* `Halfspace`,
* `Cone.

# Examples
```jldoctest
julia> c = positive_hull([1 0 0; 0 1 0; 1 1 1])
A polyhedral cone in ambient dimension 3

julia> f = facets(Halfspace, c)
3-element SubObjectIterator{LinearHalfspace}:
 The Halfspace of R^3 described by
1: -x₃ ≦ 0

 The Halfspace of R^3 described by
1: -x₁ + x₃ ≦ 0

 The Halfspace of R^3 described by
1: -x₂ + x₃ ≦ 0
```
"""
facets(as::Type{<:Union{AffineHalfspace{T}, LinearHalfspace{T}, Polyhedron{T}, Cone{T}}}, C::Cone) where T<:scalar_types = SubObjectIterator{as}(pm_object(C), _facet_cone, pm_object(C).N_FACETS)

_facet_cone(::Type{T}, C::Polymake.BigObject, i::Base.Integer) where {U<:scalar_types, T<:Union{Polyhedron{U}, AffineHalfspace{U}}} = T(-C.FACETS[[i], :], 0)

_facet_cone(::Type{LinearHalfspace{T}}, C::Polymake.BigObject, i::Base.Integer) where T<:scalar_types = LinearHalfspace{T}(-C.FACETS[[i], :])

_facet_cone(::Type{Cone{T}}, C::Polymake.BigObject, i::Base.Integer) where T<:scalar_types = cone_from_inequalities(-C.FACETS[[i], :]; scalar = fmpq)

_linear_inequality_matrix(::Val{_facet_cone}, C::Polymake.BigObject) = -C.FACETS

_linear_matrix_for_polymake(::Val{_facet_cone}) = _linear_inequality_matrix

_ray_indices(::Val{_facet_cone}, C::Polymake.BigObject) = C.RAYS_IN_FACETS

facets(C::Cone{T}) where T<:scalar_types = facets(LinearHalfspace{T}, C)

facets(::Type{Halfspace}, C::Cone{T}) where T<:scalar_types = facets(LinearHalfspace{T}, C)

@doc Markdown.doc"""
    lineality_space(C::Cone)

Return a basis of the lineality space of `C`.

# Examples
Three rays are used here to construct the upper half-plane. Actually, two of these rays point in opposite directions.
This gives us a 1-dimensional lineality.
```jldoctest
julia> UH = Cone([1 0; 0 1; -1 0]);

julia> lineality_space(UH)
1-element SubObjectIterator{RayVector{Polymake.Rational}}:
 [1, 0]
```
"""
lineality_space(C::Cone{T}) where T<:scalar_types = SubObjectIterator{RayVector{T}}(pm_object(C), _lineality_cone, lineality_dim(C))

_lineality_cone(::Type{RayVector{T}}, C::Polymake.BigObject, i::Base.Integer) where T<:scalar_types = RayVector{T}(C.LINEALITY_SPACE[i, :])

_generator_matrix(::Val{_lineality_cone}, C::Polymake.BigObject; homogenized=false) = C.LINEALITY_SPACE

_matrix_for_polymake(::Val{_lineality_cone}) = _generator_matrix

@doc Markdown.doc"""
    linear_span(C::Cone)

Return the (linear) hyperplanes generating the linear span of `C`.

# Examples
This 2-dimensional cone in $\mathbb{R}^3$ lives in exactly one hyperplane $H$, with
$H = \{ (x_1, x_2, x_3) | x_3 = 0 \}$.
```jldoctest
julia> c = Cone([1 0 0; 0 1 0]);

julia> linear_span(c)
1-element SubObjectIterator{LinearHyperplane}:
 The Hyperplane of R^3 described by
1: x₃ = 0

```
"""
linear_span(C::Cone{T}) where T<:scalar_types = SubObjectIterator{LinearHyperplane{T}}(pm_object(C), _linear_span, size(pm_object(C).LINEAR_SPAN, 1))

_linear_span(::Type{LinearHyperplane{T}}, C::Polymake.BigObject, i::Base.Integer) where T<:scalar_types = LinearHyperplane{T}(C.LINEAR_SPAN[i, :])

_linear_equation_matrix(::Val{_linear_span}, C::Polymake.BigObject) = C.LINEAR_SPAN

_linear_matrix_for_polymake(::Val{_linear_span}) = _linear_equation_matrix

@doc Markdown.doc"""
    hilbert_basis(C::Cone)

Return the Hilbert basis of a pointed cone `C` as the rows of a matrix.

# Examples
This (non-smooth) cone in the plane has a hilbert basis with three elements.
```jldoctest; filter = r".*"
julia> C = Cone([1 0; 1 2])
A polyhedral cone in ambient dimension 2

julia> matrix(ZZ, hilbert_basis(C))
[1   0]
[1   2]
[1   1]

```
"""
function hilbert_basis(C::Cone)
   if ispointed(C)
      return SubObjectIterator{PointVector{fmpz}}(pm_object(C), _hilbert_generator, size(pm_object(C).HILBERT_BASIS_GENERATORS[1], 1))
   else
      throw(ArgumentError("Cone not pointed."))
   end
end

_hilbert_generator(::Type{PointVector{fmpz}}, C::Polymake.BigObject, i::Base.Integer) = PointVector{fmpz}(C.HILBERT_BASIS_GENERATORS[1][i, :])

_generator_matrix(::Val{_hilbert_generator}, C::Polymake.BigObject; homogenized=false) = C.HILBERT_BASIS_GENERATORS[1]

_matrix_for_polymake(::Val{_hilbert_generator}) = _generator_matrix
