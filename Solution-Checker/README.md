# Julia CVRP Solution Checker
This CVRP solution checker verifies the cost of the solution and makes sure no individual route has sub-optimal TSPs using Concorde (https://www.math.uwaterloo.ca/tsp/concorde/index.html which is freely available for academic use)
To run this code from an interactive Julia session:

```console
main(["data/XXL/Leuven1.vrp", "-s", "data/XXL/Leuven1.sol", "--tsp"])
```

The output looks like:

```console
data/XXL/Leuven1.vrp
Start solution 194456 read from data/XXL/Leuven1.sol
TSP Concorde for individual routes...solution improved: 194456 -> 194449
```

For instances that do not use distance rounding, there is the option "-r", and the "--tsp" option is useless in this case:

```console
main(["data/Golden/Golden_9.vrp", "-s", "Golden_9.sol", "-r"])
```


