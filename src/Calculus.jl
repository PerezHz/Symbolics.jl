# [[file:~/Documents/Julia/scrap.org::*Calculus.jl][Calculus.jl:1]]
#---------------------------------------------------------------
#---------------------------------------------------------------
# Addition of Differentials

function Base.:+(x::Differential, y::Number)
    x + Differential([DTag()], [y])
end

function Base.:+(x::Number, y::Differential)
    Differential([DTag()], [x]) + y
end


function Base.:+(x::Differential, y::Differential)
    tags = tagUnion(x,y)
    values = [((try x[tag] catch; 0 end) + (try y[tag] catch; 0 end)) for tag in tags]
    Differential(tags, values)
end

#---------------------------------------------------------------
#---------------------------------------------------------------
# Multiplication of Differentials

function Base.:*(x::Differential, y::Number)
    Differential(tag => value * y for (tag, value) in x.terms)
end

function Base.:*(y::Number, x::Differential)
    Differential(tag => y * value for (tag, value) in x.terms)
end

function Base.:*(x::Differential, y::Differential)
    out = Differential([],[0])
    for (k1,v1) in x.terms
        for (k2,v2) in y.terms
            out += Differential([k1*k2], [v1*v2])
        end
    end
    out
end

function Base.:*(t1::DTag,t2::DTag)
    if vcat(t1.tag,t2.tag) |> hasDuplicates
        DTag(-1)
    else
        DTag(vcat(t1.tag,t2.tag) |> sort)
    end
end

#---------------------------------------------------------------
#---------------------------------------------------------------
# constructors for new unary and binary operations

function unaryOp(f::T, Df::U) where {T<:Union{Function,SymExpr},U<:Union{Function,SymExpr}}
    function (Dx::Differential)
        f(Dx[1:end-1]) + Df(Dx[1:end-1])*Dx[end]
    end
end

function binaryOp(f::Function, Dfx::Function, Dfy::Function)
    function (Dx::Differential, Dy::Differential)
        f(Dx[1:end-1],Dy[1:end-1]) + Dfx(Dx[1:end-1], Dy[1:end-1])*Dx[end] + Dfy(Dx[1:end-1], Dy[1:end-1])*Dy[end]
    end
end

Base.:-(Dx::Differential, y::Number) = unaryOp(x -> x - y, x -> 1)(Dx)
Base.:-(x::Number, Dy::Differential) = unaryOp(y -> x - y, y -> -1)(Dy)
Base.:-(Dx::Differential, Dy::Differential) = binaryOp((x,y) -> x - y,
                                                       (x,y) -> 1,
                                                       (x,y) -> -1)(Dx,Dy)

Base.:/(Dx::Differential,y::Number) = unaryOp(Dx -> Dx/y, Dx -> 1/y)(Dx)
Base.:/(x::Number,Dy::Differential) = unaryOp(Dy -> x/Dy, Dy -> -1/(Dy)^2)(Dy)
Base.:/(Dx::Differential,Dy::Differential) = binaryOp((x,y) -> x/y,
                                                      (x,y) -> 1/y,
                                                      (x,y) -> -x/y^2)(Dx,Dy)

Base.:^(Dx::Differential,y::Number) = unaryOp(Dx -> Dx^y, Dx -> y*Dx^(y-1))(Dx)
Base.:^(Dx::Differential,y::Int) = unaryOp(Dx -> Dx^y, Dx -> y*Dx^(y-1))(Dx)
Base.:^(x::Number,Dy::Differential) = unaryOp(Dy -> x^Dy, Dy -> log(x)*x^Dy)(Dy)

Base.exp(Dx::Differential) = unaryOp(exp, exp)(Dx)

Base.log(Dx::Differential) = unaryOp(log, x -> 1/x)(Dx)


#---------------------------------------------------------------
#---------------------------------------------------------------
# Derivatives

function makeDiff()
    global tagCount += 1
    Differential([DTag(tagCount)],[1])
end

function extractDiff(Dx::Differential, ϵ::Differential)
    tag = (ϵ |> getTagList)[1]
    out = Differential(tagRemove(t, tag) => v for (t, v) in Dx.terms)
    if getTagList(out) == [DTag()]
        out[1]
    else
        out
    end
end
extractDiff(ex::Symbolic, ϵ::Differential) = 0

function D(f::Function)
    ϵ = makeDiff()
    x -> extractDiff(f(x + ϵ), ϵ)
end

D(f::T) where{T<:Symbolic} = promote(T)(:D, [f])
(f::Sym)(Dt::Differential) = f(Dt[1:end-1]) + D(f)(Dt[1:end-1])*Dt[end]
(ex::SymExpr)(Dx::Differential) = unaryOp(ex, D(ex))(Dx)

function D(ex::Symbolic, s::AbstractSym)
    ϵ = makeDiff()
    Dex = ex(s => s + ϵ) |> Expr |> eval
    extractDiff(Dex, ϵ)
end


function ∂(i)
    function (f)
        ϵ = makeDiff()
        arg -> extractDiff(f(UpTuple(Tuple(i==j ? arg[j]+ϵ 
                                                : arg[j] for j in eachindex(arg)))),ϵ)
    end
end
        
function Base.:*(x::Differential, y::Differential)
    out = Differential([],[0])
    for (k1,v1) in x.terms
        for (k2,v2) in y.terms
            out += Differential([k1*k2], [v1*v2])
        end
    end
    out
end
# Calculus.jl:1 ends here
