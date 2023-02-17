This is a solver for iojoe's games ["10"](https://www.youtube.com/watch?v=2kKs6eu5WnM) and ["10 Is Again"](https://www.youtube.com/watch?v=4SzI-6jcMCE). It uses the A\* search algorithm, which uses a heuristics function to more efficiently explore the game tree.

(As of 2023, this game is difficult to access. The developer's website, iojoe.com [[Wayback Machine]](https://web.archive.org/web/20170605051653/http://iojoe.com/games/), disappeared around 2018. The [Android version](https://play.google.com/store/apps/details?id=air.com.iojoe.A10) is still available, but is reported to be broken on other newer devices... though it works fine on my Google Pixel 6. The [Flash versions](https://iojoe.newgrounds.com/games/) are available, but on modern browsers require [the old Flash player](https://www.newgrounds.com/flash/player) to be installed.)

Current status: Simpler boards can be solved, but more complex boards take 15 minutes or more to solve.

This is basically the [multiple subset-sum problem](https://en.wikipedia.org/wiki/Knapsack_problem#Subset-sum_problem), which is [strongly NP-hard](https://en.wikipedia.org/wiki/Strongly_NP-complete) and has no FPTAS (fully polynomial-time approximation scheme), so it can become very computationally expensive to solve.

![screenshot](http://deenewcum.github.io/iojoe10_solver/iojoe10_solver.png)
