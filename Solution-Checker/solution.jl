function print_routes(solution)
   for (i,r) in enumerate(solution.routes)
      print("Route #$i: ") 
      for j in r
         print("$j ")
      end
      println()
   end
end

# checks the feasiblity of a solution
function checksolution(data::DataVRP, solution)
   dim, Q, D = maximum(customers(data)), veh_capacity(data), distance_limit(data)
   visits = [0 for i in 1:dim]
   sum_cost = 0.0
   for (i,r) in enumerate(solution.routes)
      sum_demand, sum_distance, prev = 0.0, 0.0, 0
      for j in r
         visits[j] += 1
         (visits[j] == 2) && error("Customer $j was visited more than once")
         sum_cost += distance(data, (prev,j))
         sum_demand += d(data, j)
         sum_distance += distance(data, (prev,j))
         prev = j
      end
      sum_cost += distance(data, (prev,0))
      sum_distance += distance(data, (prev,0))
      # println("Route #$i is traveling a total distance of $(sum_distance)")
      (sum_demand > Q) && error("Route #$i is violating the capacity constraint. Sum of the demands is $(sum_demand) and Q is $Q")
      (sum_distance > D) && error("Route #$i is violating the distance constraint. Sum of the distances is $(sum_distance) and D is $D")
   end
   !isempty(findall(a->a==0,visits)) && error("The following customers were not visited: $(findall(a->a==0,visits))")
   (abs(solution.cost-sum_cost) > 0.1) && error("Cost calculated from the routes ($sum_cost) is different from that passed as"*
                                                                                                  " argument ($(solution.cost)).") 
end

# read solution from file (CVRPLIB format)
function readsolution(app::Dict{String,Any})
   str = read(app["sol"], String)
   breaks_in = [' '; ':'; '\n';'\t';'\r']
   aux = split(str, breaks_in; limit=0, keepempty=false) 
   sol = Solution(0.0, [])
   j = 3
   while j <= length(aux)
      r = []
      while j <= length(aux)
         push!(r, parse(Int, aux[j]))
         j += 1
         if contains(lowercase(aux[j]), "cost") || contains(lowercase(aux[j]), "route")
            break
         end
      end
      push!(sol.routes, r)
      if contains(lowercase(aux[j]), "cost")
         if app["noround"]
            sol.cost = parse(Float64, aux[j+1])
         else
            sol.cost = trunc(Int,parse(Float64, aux[j+1]))
         end
         return sol
      end
      j += 2 # skip "Route" and "#j:" elements
   end
   error("The solution file was not read successfully. The file must be in the CVRPLIB format.")
   return sol
end

# write solution in a file
function writesolution(app, solution; suffix="")
   open(app["out"]*suffix, "w") do f
      for (i,r) in enumerate(solution.routes)
         write(f, "Route #$i: ")
         for j in r
            write(f, "$j ") 
         end
         write(f, "\n")
      end
      if app["noround"]
         write(f, "Cost $(solution.cost)\n")
      else
         write(f, "Cost $(trunc(Int,solution.cost))\n")
      end
   end
end