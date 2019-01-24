var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Readme",
    "title": "Readme",
    "category": "page",
    "text": "(Image: Build Status) (Image: codecov)"
},

{
    "location": "#ArcadeLearningEnvironment.jl-1",
    "page": "Readme",
    "title": "ArcadeLearningEnvironment.jl",
    "category": "section",
    "text": "This package is a Julia wrapper for the ArcadeLearningEnvironment (ALE).ALE is a modified emulator for the Atari 2600 that can emulate around 50 games with additional access to game state information and in-game rewards. This is useful for learning and benchmarking artificial intelligence agents playing computer games."
},

{
    "location": "#Citation-1",
    "page": "Readme",
    "title": "Citation",
    "category": "section",
    "text": "If you use this package for research publications, please cite the following paper to acknowledge the work that went into ALE.@ARTICLE{bellemare13arcade,\n	author = {{Bellemare}, M.~G. and {Naddaf}, Y. and {Veness}, J. and {Bowling}, M.},\n	title = {The Arcade Learning Environment: An Evaluation Platform for General Agents},\n	journal = {Journal of Artificial Intelligence Research},\n	year = 2013,\n	month = 06,\n	volume = 47,\n	pages = {253--279}\n}"
},

{
    "location": "#Installation-1",
    "page": "Readme",
    "title": "Installation",
    "category": "section",
    "text": "On Mac OS and Linux the package automatically downloads and builds version 0.6.0 of the ArcadeLearningEnvironment by adding it in julia 0.6 withPkg.add(\"ArcadeLearningEnvironment\")or in the package REPL of julia 0.7.0 withadd ArcadeLearningEnvironmentOn Windows (which I have not tried yet) you can build the libale_c.dll file manually and set the LIBALE_HOME environment variable to the directory containing this file.  Then, the above two commands should work as well.  Note that this is untested and any correction or feedback is welcome."
},

{
    "location": "#Example-1",
    "page": "Readme",
    "title": "Example",
    "category": "section",
    "text": "using ArcadeLearningEnvironment\n\n\nepisodes = 50\n\nale = ALE_new()\nloadROM(ale, \"seaquest\")\n\nS = zeros(Int64, episodes)\nTR = zeros(episodes)\nfor ei = 1:episodes\n    ctr = 0.0\n\n    fc = 0\n    while game_over(ale) == false\n        actions = getLegalActionSet(ale)\n        ctr += act(ale, actions[rand(1:length(actions))])\n        fc += 1\n    end\n    reset_game(ale)\n    println(\"Game $ei ended after $fc frames with total reward $(ctr).\")\n\n    S[ei] = fc\n    TR[ei] = ctr\nend\nALE_del(ale)"
},

{
    "location": "autodocs/#",
    "page": "Docstrings",
    "title": "Docstrings",
    "category": "page",
    "text": "Package doesn\'t contain Documenter docs.Docs automatically generated by juliadocs.orgModules = [ArcadeLearningEnvironment]\nOrder = [:type, :function]"
},

]}