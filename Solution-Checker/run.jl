using ArgParse, Printf, Random

include("types.jl")
include("data.jl")
include("solution.jl")
include("tsp.jl")

function parse_commandline(args_array::Array{String,1}, appfolder::String)
   s = ArgParseSettings(usage="##### VRPSolver #####\n\n"*
   "  On interactive mode, call main([\"arg1\", ..., \"argn\"])", exit_after_help=false)
   @add_arg_table s begin
      "instance"
         help = "Instance file path"
      "--noround","-r"
         help = "Does not round the distance matrix"
         action = :store_true
      "--sol","-s"
         help = "Solution file path (CVRPLIB format. See the example sol/X-n101-k25.vrp)"
      "--out","-o"
         help = "Path to write the solution found"
      "--batch","-b" 
         help = "batch file path" 
      "--tsp"
         help = "TSP Concorde to try improve the initial solution"
         action = :store_true
   end
   return parse_args(args_array, s)
end

function run_cvrp(app::Dict{String,Any}, appfolder::String)

   app["name"] = string(split(basename(app["instance"]), ".")[1])
   println(app["instance"])

   data = readVRPData(app) # read VRP instance

   bestsol = Solution(Inf, []) # global best solution
   if app["sol"] !== nothing
      bestsol = readsolution(app) # read solution in app["sol"]
      try
         checksolution(data, bestsol) # checks the solution feasibility
      catch e
         bt = backtrace()
         msg = sprint(showerror, e, bt)
         println("Solution infeasible! ", msg)
         exit(0)
      end
      println("Start solution $(bestsol.cost) read from $(app["sol"])")
   end

   if app["tsp"] && !app["noround"] # Try to improve the initial solution with TSP solver (only for integer matrix)
      print("TSP Concorde for individual routes...")
      prev_cost = bestsol.cost
      target_sol = opt_indidual_routes(bestsol, data, appfolder, app)  
      if (target_sol.cost) < prev_cost
         checksolution(data, target_sol)
         target_sol.cost < bestsol.cost && (bestsol = deepcopy(target_sol))
         println("solution improved: $prev_cost -> $(target_sol.cost)")
      else
         println("no improvement")
      end
   end

   if bestsol.cost != Inf # Is there a solution?
      print_routes(bestsol)
      println("Cost $(bestsol.cost)")
      if app["out"] != nothing
         writesolution(app, bestsol)
         println("Final solution was written at $(app["out"])")
      end
   end
end

function main(args)
   appfolder = dirname(@__FILE__)
   app = parse_commandline(args, appfolder)
   isnothing(app) && return
   if app["batch"] != nothing
      for line in readlines(app["batch"])
         if isempty(strip(line)) || strip(line)[1] == '#'
            continue
         end
         args_array = [String(s) for s in split(line)]
         app_line = parse_commandline(args_array, appfolder)
         run_cvrp(app_line, appfolder)
      end
   else
      run_cvrp(app, appfolder)
   end
end

if isempty(ARGS)
   main(["--help"])
else
   main(ARGS)
end
