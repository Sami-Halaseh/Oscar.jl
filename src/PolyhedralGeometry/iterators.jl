const scalar_types = Union{fmpq, fmpz}

const scalar_type_to_oscar = Dict{String, Type}([("Rational", fmpq)])

struct Polyhedron{T} #a real polymake polyhedron
    pm_polytope::Polymake.BigObject
    boundedness::Symbol # Values: :unknown, :bounded, :unbounded
    
    # only allowing scalar_types;
    # can be improved by testing if the template type of the `BigObject` corresponds to `T`
    Polyhedron{T}(p::Polymake.BigObject, b::Symbol) where T<:scalar_types = new(p, b)
end

# default scalar type: `fmpq`
Polyhedron(x...) = Polyhedron{fmpq}(x...)

Polyhedron(p::Polymake.BigObject) = Polyhedron{detect_scalar_type(Polyhedron, p)}(p)
Polyhedron(p::Polymake.BigObject, b::Symbol) = Polyhedron{detect_scalar_type(Polyhedron, p)}(p, b)

struct Cone{T} #a real polymake polyhedron
    pm_cone::Polymake.BigObject
    
    # only allowing scalar_types;
    # can be improved by testing if the template type of the `BigObject` corresponds to `T`
    Cone{T}(c::Polymake.BigObject) where T<:scalar_types = new(c)
end

# default scalar type: `fmpq`
Cone(x...) = Cone{fmpq}(x...)

Cone(p::Polymake.BigObject) = Cone{detect_scalar_type(Cone, p)}(p)

# actually name length + 2, corresponding to the index of the first character of the scalar type
const pm_name_length = Dict{Type, Int}([(Polyhedron, 10), (Cone, 6)])

function detect_scalar_type(n::Type{T}, p::Polymake.BigObject) where T<:Union{Polyhedron, Cone}
    typename = Polymake.type_name(p)[pm_name_length[n]:end-1]
    return scalar_type_to_oscar[typename]
end

const scalar_type_to_polymake = Dict{Type, Type}([(fmpq, Polymake.Rational)])

struct PointVector{U} <: AbstractVector{U}
    p::AbstractVector{U}
    
    PointVector{U}(p::AbstractVector) where U<:scalar_types = new{U}(p)
    PointVector(p::AbstractVector) = new{fmpq}(p)
end

# Base.eltype(::PointVector{U}) where U = U

Base.IndexStyle(::Type{<:PointVector}) = IndexLinear()

Base.getindex(po::PointVector{T}, i::Base.Integer) where T<:scalar_types  = convert(T, po.p[i])

function Base.setindex!(po::PointVector, val, i::Base.Integer)
    @boundscheck checkbounds(po.p, i)
    po.p[i] = val
    return val
end

Base.firstindex(::PointVector) = 1
Base.lastindex(iter::PointVector) = length(iter)
Base.size(po::PointVector) = size(po.p)

# PointVector(x...) = PointVector{fmpq}(x...)

PointVector{U}(n::Base.Integer) where U = PointVector{U}(zeros(U, n))

function Base.similar(X::PointVector, ::Type{S}, dims::Dims{1}) where S <: scalar_types
    return PointVector{S}(dims...)
end

Base.BroadcastStyle(::Type{<:PointVector}) = Broadcast.ArrayStyle{PointVector}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{PointVector}}, ::Type{ElType}) where ElType
    return PointVector{ElType}(axes(bc)...)
end

struct RayVector{U} <: AbstractVector{U}
    p::AbstractVector{U}
    
    RayVector{U}(p::AbstractVector) where U<:scalar_types = new{U}(p)
    RayVector(p::AbstractVector) = new{fmpq}(p)
end

# Base.eltype(::RayVector{U}) where U = U

Base.IndexStyle(::Type{<:RayVector}) = IndexLinear()

Base.getindex(po::RayVector{T}, i::Base.Integer) where T<:scalar_types  = convert(T, po.p[i])

function Base.setindex!(po::RayVector, val, i::Base.Integer)
    @boundscheck checkbounds(po.p, i)
    po.p[i] = val
    return val
end

Base.firstindex(::RayVector) = 1
Base.lastindex(iter::RayVector) = length(iter)
Base.size(po::RayVector) = size(po.p)

# RayVector(x...) = RayVector{fmpq}(x...)

RayVector{U}(n::Base.Integer) where U = RayVector{U}(zeros(U, n))

function Base.similar(X::RayVector, ::Type{S}, dims::Dims{1}) where S <: scalar_types
    return RayVector{S}(dims...)
end

Base.BroadcastStyle(::Type{<:RayVector}) = Broadcast.ArrayStyle{RayVector}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{RayVector}}, ::Type{ElType}) where ElType
    return RayVector{ElType}(axes(bc)...)
end

Base.:*(k::scalar_types, po::Union{PointVector, RayVector}) = k .* po

abstract type Halfspace{T} end

@doc Markdown.doc"""
    Halfspace(a, b)

One halfspace `H(a,b)` is given by a vector `a` and a value `b` such that
$$H(a,b) = \{ x | ax ≤ b \}.$$
"""
struct AffineHalfspace{T} <: Halfspace{T}
    a::AbstractVector{T}
    b::T
    
    AffineHalfspace{T}(a::Union{MatElem, AbstractMatrix, AbstractVector}, b=0) where T = new{T}(vec(a), b)
    AffineHalfspace(a::Union{MatElem, AbstractMatrix, AbstractVector}, b=0) = new{fmpq}(vec(a), b)
end

# AffineHalfspace(a) = AffineHalfspace(a, 0)

Halfspace(a, b) = AffineHalfspace(a, b)
Halfspace{T}(a, b) where T<:scalar_types = AffineHalfspace{T}(a, b)

struct LinearHalfspace{T} <: Halfspace{T}
    a::AbstractVector{T}
    
    LinearHalfspace{T}(a::Union{MatElem, AbstractMatrix, AbstractVector}) where T = new{T}(vec(a))
    LinearHalfspace(a::Union{MatElem, AbstractMatrix, AbstractVector}) = new{fmpq}(vec(a))
end

Halfspace(a) = LinearHalfspace(a)
Halfspace{T}(a) where T<:scalar_types = LinearHalfspace{T}(a)

abstract type Hyperplane{T} end

@doc Markdown.doc"""
    AffineHyperplane(a, b)

One hyperplane `H(a,b)` is given by a vector `a` and a value `b` such that
$$H(a,b) = \{ x | ax = b \}.$$
"""
struct AffineHyperplane{T} <: Hyperplane{T}
    a::AbstractVector{T}
    b::T
    
    AffineHyperplane{T}(a::Union{MatElem, AbstractMatrix, AbstractVector}, b=0) where T = new{T}(vec(a), b)
    AffineHyperplane(a::Union{MatElem, AbstractMatrix, AbstractVector}, b=0) = new{fmpq}(vec(a), b)
end

# AffineHyperplane(a) = AffineHyperplane(a, 0)

Hyperplane(a, b) = AffineHyperplane(a, b)
Hyperplane{T}(a, b) where T<:scalar_types = AffineHyperplane{T}(a, b)

struct LinearHyperplane{T} <: Hyperplane{T}
    a::AbstractVector{T}
    
    LinearHyperplane{T}(a::Union{MatElem, AbstractMatrix, AbstractVector}) where T = new{T}(vec(a))
    LinearHyperplane(a::Union{MatElem, AbstractMatrix, AbstractVector}) = new{fmpq}(vec(a))
end

# LinearHyperplane(a::Union{MatElem, AbstractMatrix}) = LinearHyperplane(vec(a))

Hyperplane(a) = LinearHyperplane(a)
Hyperplane{T}(a) where T<:scalar_types = LinearHyperplane{T}(a)

negbias(H::Union{AffineHalfspace{T}, AffineHyperplane{T}}) where T<:scalar_types = H.b
negbias(H::Union{LinearHalfspace{T}, LinearHyperplane{T}}) where T<:scalar_types = T(0)
normal_vector(H::Union{Halfspace{T}, Hyperplane{T}}) where T <: scalar_types = Vector{T}(H.a)

# TODO: abstract notion of equality
Base.:(==)(x::AffineHalfspace, y::AffineHalfspace) = x.a == y.a && x.b == y.b

Base.:(==)(x::LinearHalfspace, y::LinearHalfspace) = x.a == y.a

Base.:(==)(x::AffineHyperplane, y::AffineHyperplane) = x.a == y.a && x.b == y.b

Base.:(==)(x::LinearHyperplane, y::LinearHyperplane) = x.a == y.a

####################

scalar_type(::Union{Polyhedron{T}, Cone{T}, Hyperplane{T}, Halfspace{T}}) where T<:scalar_types = T

####################

@doc Markdown.doc"""
    SubObjectIterator(Obj, Acc, n, [options])

An iterator over a designated property of `Obj::Polymake.BigObject`.

`Acc::Function` will be used internally for `getindex`. Further this uniquely
determines the context the iterator operates in, allowing to extend specific
methods like `point_matrix`.

The length of the iterator is hard set with `n::Int`. This is because it is
fixed and to avoid redundant computations: when data has to be pre-processed
before creating a `SubObjectIterator`, the length can usually easily be derived.

Additional data required for specifying the property can be given using
`options::NamedTuple`. A typical example for this is `dim` in the context of
`facets`. The `NamedTuple` is passed to `Acc` (and the specific methods) as
keyword arguments.
"""
struct SubObjectIterator{T} <: AbstractVector{T}
    Obj::Polymake.BigObject
    Acc::Function
    n::Int
    options::NamedTuple
end

SubObjectIterator{T}(Obj::Polymake.BigObject, Acc::Function, n::Base.Integer) where T = SubObjectIterator{T}(Obj, Acc, n, NamedTuple())

Base.IndexStyle(::Type{<:SubObjectIterator}) = IndexLinear()

function Base.getindex(iter::SubObjectIterator{T}, i::Base.Integer) where T
    @boundscheck 1 <= i && i <= iter.n
    return iter.Acc(T, iter.Obj, i; iter.options...)
end

Base.firstindex(::SubObjectIterator) = 1
Base.lastindex(iter::SubObjectIterator) = length(iter)
Base.size(iter::SubObjectIterator) = (iter.n,)

# Incidence matrices
for (sym, name) in (("ray_indices", "Incidence Matrix resp. rays"), ("vertex_indices", "Incidence Matrix resp. vertices"))
    M = Symbol(sym)
    _M = Symbol(string("_", sym))
    @eval begin
        $M(iter::SubObjectIterator) = $_M(Val(iter.Acc), iter.Obj; iter.options...)
        $_M(::Any, ::Polymake.BigObject) = throw(ArgumentError(string($name, " not defined in this context.")))
    end
end

# Matrices with rational only elements
for (sym, name) in (("linear_inequality_matrix", "Linear Inequality Matrix"), ("affine_inequality_matrix", "Affine Inequality Matrix"), ("linear_equation_matrix", "Linear Equation Matrix"), ("affine_equation_matrix", "Affine Equation Matrix"))
    M = Symbol(sym)
    _M = Symbol(string("_", sym))
    @eval begin
        $M(iter::SubObjectIterator) = matrix(QQ, Matrix{fmpq}($_M(Val(iter.Acc), iter.Obj; iter.options...)))
        $_M(::Any, ::Polymake.BigObject) = throw(ArgumentError(string($name, " not defined in this context.")))
    end
end

# Matrices with rational or integer elements
for (sym, name) in (("point_matrix", "Point Matrix"), ("vector_matrix", "Vector Matrix"), ("generator_matrix", "Generator Matrix"))
    M = Symbol(sym)
    _M = Symbol(string("_", sym))
    @eval begin
        $M(iter::SubObjectIterator{<:AbstractVector{fmpq}}) = matrix(QQ, Matrix{fmpq}($_M(Val(iter.Acc), iter.Obj; iter.options...)))
        $M(iter::SubObjectIterator{<:AbstractVector{fmpz}}) = matrix(ZZ, $_M(Val(iter.Acc), iter.Obj; iter.options...))
        $_M(::Any, ::Polymake.BigObject) = throw(ArgumentError(string($name, " not defined in this context.")))
    end
end

function matrix_for_polymake(iter::SubObjectIterator; homogenized=false)
    if hasmethod(_matrix_for_polymake, Tuple{Val{iter.Acc}})
        return _matrix_for_polymake(Val(iter.Acc))(Val(iter.Acc), iter.Obj; homogenized=homogenized, iter.options...)
    else
        throw(ArgumentError("Matrix for Polymake not defined in this context."))
    end
end

# primitive generators only for ray based iterators
matrix(R::FlintIntegerRing, iter::SubObjectIterator{RayVector{fmpq}}) =
    matrix(R, Polymake.common.primitive(matrix_for_polymake(iter)))
matrix(R::FlintIntegerRing, iter::SubObjectIterator{<:Union{RayVector{fmpz},PointVector{fmpz}}}) =
    matrix(R, matrix_for_polymake(iter))
matrix(R::FlintRationalField, iter::SubObjectIterator{<:Union{RayVector,PointVector}}) =
    matrix(R, Matrix{fmpq}(matrix_for_polymake(iter)))

function linear_matrix_for_polymake(iter::SubObjectIterator)
    if hasmethod(_linear_matrix_for_polymake, Tuple{Val{iter.Acc}})
        return _linear_matrix_for_polymake(Val(iter.Acc))(Val(iter.Acc), iter.Obj; iter.options...)
    elseif hasmethod(_affine_matrix_for_polymake, Tuple{Val{iter.Acc}})
        res = _affine_matrix_for_polymake(Val(iter.Acc))(Val(iter.Acc), iter.Obj; iter.options...)
        iszero(res[:, 1]) || throw(ArgumentError("Input not linear."))
        return res[:, 2:end]
    end
    throw(ArgumentError("Linear Matrix for Polymake not defined in this context."))
end

function affine_matrix_for_polymake(iter::SubObjectIterator)
    if hasmethod(_affine_matrix_for_polymake, Tuple{Val{iter.Acc}})
        return _affine_matrix_for_polymake(Val(iter.Acc))(Val(iter.Acc), iter.Obj; iter.options...)
    elseif hasmethod(_linear_matrix_for_polymake, Tuple{Val{iter.Acc}})
        return homogenize(_linear_matrix_for_polymake(Val(iter.Acc))(Val(iter.Acc), iter.Obj; iter.options...), 0)
    end
    throw(ArgumentError("Affine Matrix for Polymake not defined in this context."))
end

function halfspace_matrix_pair(iter::SubObjectIterator)
    try
        h = affine_matrix_for_polymake(iter)
        return (A = matrix(QQ, Matrix{fmpq}(h[:, 2:end])), b = -h[:, 1])
    catch e
        throw(ArgumentError("Halfspace-Matrix-Pair not defined in this context."))
    end
end

Polymake.convert_to_pm_type(::Type{SubObjectIterator{RayVector{T}}}) where T = Polymake.Matrix{T}
Polymake.convert_to_pm_type(::Type{SubObjectIterator{PointVector{T}}}) where T = Polymake.Matrix{T}
Base.convert(::Type{<:Polymake.Matrix}, iter::SubObjectIterator) = matrix_for_polymake(iter; homogenized=true)

function homogenized_matrix(x::SubObjectIterator{<:PointVector}, v::Number = 1)
    if v != 1
        throw(ArgumentError("PointVectors can only be (re-)homogenized with parameter 1, please convert to a matrix first."))
    end
    return matrix_for_polymake(x; homogenized=true)
end
function homogenized_matrix(x::SubObjectIterator{<:RayVector}, v::Number = 0)
    if v != 0
        throw(ArgumentError("RayVectors can only be (re-)homogenized with parameter 0, please convert to a matrix first."))
    end
    return matrix_for_polymake(x; homogenized=true)
end
