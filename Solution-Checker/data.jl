import Unicode
customers(data::DataVRP) = filter!(x->x≠data.depot_id, [i.id_vertex for i in collect(values(data.G′.V′))]) # return set of customers

# Euclidian distance
function distance(data::DataVRP, arc::Tuple{Int64, Int64})
   e = (arc[1] < arc[2]) ? arc : (arc[2],arc[1])
   if data.explicit
      return data.G′.cost[e]
   elseif data.coord
      u, v = arc
      vertices = data.G′.V′ 
      x_sq = (vertices[v].pos_x - vertices[u].pos_x)^2
      y_sq = (vertices[v].pos_y - vertices[u].pos_y)^2
      if data.round
         return floor(sqrt(x_sq + y_sq) + 0.5)
      end
      return sqrt(x_sq + y_sq)
   else
      return 0.0
   end
end

contains(p, s) = findnext(s, p, 1) != nothing

function readVRPData(app)
   str = Unicode.normalize(filter(isascii, read(app["instance"], String)); stripcc=true)
   breaks_in = [' '; ':'; '\n']
   aux = split(str, breaks_in; limit=0, keepempty=false)

   G′ = InputGraph(Dict(),[], Dict())
   data = DataVRP(G′, 0, Inf, 0, false, !app["noround"], false)
    
   dim = 0
   for i in 1:length(aux)
      if contains(aux[i], "DIMENSION")
         dim = parse(Int, aux[i+1])
      elseif contains(aux[i], "CAPACITY")
         data.Q = parse(Float64, aux[i+1])  # the method parse() convert the string to Int64
      elseif contains(aux[i], "DISTANCE")
         data.D = parse(Float64, aux[i+1])  # the method parse() convert the string to Int64
      elseif  contains(aux[i], "EDGE_WEIGHT_SECTION")
         data.explicit = true
         j = i+1
         for u in 0:(dim-1)
            for v in 0:(u-1)
               data.G′.cost[(v,u)] = parse(Float64, aux[j])
               j += 1
            end
         end
      elseif contains(aux[i], "NODE_COORD_SECTION")
         data.coord = true
         j = i+1
         while aux[j] != "DEMAND_SECTION" 
            v = Vertex(0, 0, 0, 0)
            v.id_vertex = parse(Int, aux[j])-1 # depot is forced to be 0, fisrt customer to be 1, and so on
            v.pos_x = parse(Float64, aux[j+1])
            v.pos_y = parse(Float64, aux[j+2])
            data.G′.V′[v.id_vertex] = v # add v in the vertex array
            j+=3
         end
      elseif contains(aux[i], "DEMAND_SECTION")
         j = i+1
         while aux[j] != "DEPOT_SECTION"
            pos = parse(Int, aux[j])-1
            data.G′.V′[pos].demand = parse(Float64, aux[j+1])
            j += 2
         end
         data.depot_id = 0
         break
      end
   end

   return data
end

edges(data::DataVRP) = data.G′.E # return set of edges
c(data,e) = distance(data, e) # cost of the edge e
dimension(data::DataVRP) = length(data.G′.V′) # return number of vertices
d(data::DataVRP, i) = data.G′.V′[i].demand # return demand of i
veh_capacity(data::DataVRP) = data.Q
distance_limit(data::DataVRP) = data.D
nb_customers(data::DataVRP) = length(customers(data))
min_xy(data::DataVRP) = (minimum([i.pos_x for i in values(data.G′.V′)]), minimum([i.pos_y for i in values(data.G′.V′)]))
max_xy(data::DataVRP) = (maximum([i.pos_x for i in values(data.G′.V′)]), maximum([i.pos_y for i in values(data.G′.V′)]))
pos(data::DataVRP, i::Int) = (data.G′.V′[i].pos_x, data.G′.V′[i].pos_y)

function totaldemand(data::DataVRP) 
   tot_demand = 0
   for i in values(data.G′.V′)
      tot_demand += i.demand
   end
   return tot_demand
end

function lowerBoundNbVehicles(data::DataVRP) 
   return Int(ceil(totaldemand(data)/data.Q))
end

# return incident edges of i
function δ(data::DataVRP, i::Integer)
   incident_edges = Vector{Tuple}()
   for v in values(data.G′.V′)
      j = v.id_vertex
      if i < j
         push!(incident_edges, (i,j))
      elseif i > j
         push!(incident_edges, (j,i))
      end
   end   
   return incident_edges
end

