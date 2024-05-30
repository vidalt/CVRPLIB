mutable struct Vertex
   id_vertex::Int
   pos_x::Float64
   pos_y::Float64
   demand::Float64
end

# Undirected graph
mutable struct InputGraph
   V′::Dict{Int,Vertex} # set of vertices (access with id_vertex)
   E::Array{Tuple{Int64,Int64}} # set of edges
   cost::Dict{Tuple{Int64,Int64}, Float64}
end

mutable struct DataVRP
   G′::InputGraph
   Q::Float64 # vehicle capacity
   D::Float64 # Distance constraint
   depot_id::Int
   coord::Bool # instance with NODE_COORD_SECTION
   round::Bool # Is the distance matrix rounded?
   explicit::Bool
end

CostType = Union{Int, Float64}
mutable struct Solution
   cost::CostType
   routes::Array{Array{Int,1}}
end