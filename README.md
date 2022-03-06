This is a solver for iojoe's game ["10"](https://play.google.com/store/apps/details?id=air.com.iojoe.A10). It uses the A* search algorithm, which uses a heuristics function to more efficiently explore the game tree.

Current status: Simpler boards can be solved, but more complex boards take 15 minutes or more to solve.

This is basically the [multiple subset-sum problem](https://en.wikipedia.org/wiki/Knapsack_problem#Subset-sum_problem), which is [strongly NP-hard](https://en.wikipedia.org/wiki/Strongly_NP-complete) and has no FPTAS (fully polynomial-time approximation scheme), so it can become very expensive to solve.

![screenshot](http://deenewcum.github.io/iojoe10_solver/iojoe10_solver.png)
