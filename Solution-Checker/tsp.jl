using Glob

# Use Concorde TSP to optimize individual routes
function opt_indidual_routes(sol::Solution, data::DataVRP, appfolder::String, app::Dict{String,Any})
   
    for (rid,route) in enumerate(sol.routes)
 
       V = sort!(vcat(0, route))
       dim = string(length(V))
       length(V) <= 2 && continue
       randstr = randstring(12)
       comment, orig = "\"", Dict{Int,Int}()
       for (i,v) in enumerate(V)
          comment *= i < length(V) ? "$i:$(v+1)," : "$i:$(v+1)\""
          orig[i] = v
       end
 
       tsp_instance = "NAME : "*app["name"]*"\nCOMMENT : $comment \nTYPE : TSP\nDIMENSION : $(dim)\n"
       tsp_instance = tsp_instance * "EDGE_WEIGHT_TYPE : EXPLICIT\nEDGE_WEIGHT_FORMAT: FULL_MATRIX\nDISPLAY_DATA_TYPE: NO_DISPLAY\nEDGE_WEIGHT_SECTION\n"
 
       for i in V
          for j in V
             dist="$(trunc(Int,distance(data,(i,j)))) "
             tsp_instance *= dist * join([" " for i in 1:(7-length(dist))])
          end
          tsp_instance *= "\n"
       end
       tsp_instance *= "EOF\n"
 
       prev, cur_cost = 0, 0
       for j in route
          cur_cost += distance(data, (prev,j))
          prev = j
       end
       cur_cost += distance(data, (prev,0))
       cur_cost = trunc(Int,cur_cost)
       pathbase = "$appfolder/../tsp/"*app["name"]*"_$(cur_cost)_$randstr"
       write(pathbase*".tsp", tsp_instance)
       
       try
          run(pipeline(`$appfolder/concorde -o $pathbase.sol $pathbase.tsp`, stdout=devnull, stderr=devnull))
          if isfile("$pathbase.sol")
             str = read("$pathbase.sol", String)
             breaks_in = [' '; ':'; '\n';'\t';'\r']
             aux = split(str, breaks_in; limit=0, keepempty=false) 
             new_route = [orig[parse(Int,aux[j])+1] for j in 3:length(aux)]
             prev, cost = 0, 0
             for j in new_route
                cost += distance(data, (prev,j))
                prev = j
             end
             cost += distance(data, (prev,0))
             if cost < cur_cost
                sol.routes[rid] = new_route
                sol.cost -= cur_cost - trunc(Int,cost)
             end
             run(`rm -f $pathbase.tsp $pathbase.sol`)
             rm.(glob("*"*app["name"]*"_$(cur_cost)*"))
          else
             error("TSP solution was not found!")
          end
       catch e
          println("Error during TSP optimization! ")
       end
    
    end 
 
    return sol
 end
 