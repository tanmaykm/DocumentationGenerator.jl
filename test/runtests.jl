using Test, DocumentationGenerator
using Pkg

const julia = first(Base.julia_cmd())

@test length(keys(DocumentationGenerator.installable_on_version())) > 1500

@test DocumentationGenerator.maybe_redirect("https://docs.julialang.org/") == "https://docs.julialang.org/en/v1"

@testset "Running code with a timeout" begin
    let
        tempfile = tempname()
        str = """
        sleep(4)
        sleep(4)
        write("$tempfile", "hi")
        sleep(3)
        """
        proc, _ = DocumentationGenerator.run_with_timeout(`$julia -e $str`, timeout=7)
        wait(proc)
        @test !success(proc)
        @test !isfile(tempfile)
    end

    let
        tempfile = tempname()
        str = """
        for i = 1:10
        sleep(1)
        println(i)
        end
        write("$tempfile", "hi")
        """
        proc, _ = DocumentationGenerator.run_with_timeout(`$julia -e $str`, timeout=6)
        wait(proc)
        @test success(proc)
        @test String(read(tempfile)) == "hi"
    end

    let
        tempfile = tempname()
        logfile = tempname()
        str = """
        for i in 1:10
        println(i)
        sleep(1)
        end
        write("$tempfile", "hi")
        """
        proc, task = DocumentationGenerator.run_with_timeout(`$julia -e $str`, timeout=3, log=logfile)
        wait(proc)
        @test success(proc)
        @test String(read(tempfile)) == "hi"
        logstr = ""
        for i in 1:10
            logstr *= "$i"
        end
        wait(task)
        @test isfile(logfile)
        @test replace(String(read(logfile)), '\n' => "") == logstr
    end
end

@testset "Documentation Generation" begin
    packages = [
        # without docs
        (
            name = "FixedPointNumbers",
            uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93",
            url = "https://github.com/JuliaMath/FixedPointNumbers.jl.git",
            versions = [v"0.5.3"],
            installs = [true],
            success = [true],
            doctype = ["fallback_autodocs"],
        ),
        (
            name = "ReactionNetworkImporters",
            url = "https://github.com/isaacsas/ReactionNetworkImporters.jl.git",
            uuid = "b4db0fb7-de2a-5028-82bf-5021f5cfa881",
            versions = [v"0.1.5"],
            installs = [true],
            success = [true],
            doctype = ["fallback_autodocs"],
        ),
        # with docs
        (
            name = "Example",
            url = "https://github.com/JuliaLang/Example.jl.git",
            uuid = "7876af07-990d-54b4-ab0e-23690620f79a",
            versions = [v"0.5.1", v"0.5.3"],
            installs = [true, true],
            success = [true, true],
            doctype = ["fallback_autodocs", "documenter"],
        ),
        (
            name = "DynamicHMC",
            url = "https://github.com/tpapp/DynamicHMC.jl.git",
            uuid = "bbc10e6e-7c05-544b-b16e-64fede858acb",
            versions = [v"2.1.1"],
            installs = [true],
            success = [true],
            doctype = ["documenter"],
        ),
        (
            name = "jlpkg",
            url = "https://github.com/fredrikekre/jlpkg",
            uuid = "c4c688b2-6cc8-11e9-1c12-6d20b663313d",
            versions = [v"1.0.2"],
            installs = [true],
            success = [true],
            doctype = ["fallback_autodocs"],
        ),
        # with fancy docs
        (
            name = "Flux",
            url = "https://github.com/FluxML/Flux.jl.git",
            uuid = "587475ba-b771-5e3f-ad9e-33799f191a9c",
            versions = [v"0.2.2", v"0.9.0"],
            installs = [false, true],
            success = [false, true],
            doctype = ["missing", "documenter"],
        ),
        # with hosted docs
        (
            name = "Juno",
            url = "https://github.com/JunoLab/Juno.jl.git",
            uuid = "e5e0dc1b-0480-54bc-9374-aad01c23163d",
            versions = [v"0.7.0"],
            installs = ["missing"],
            success = [true],
            hosted_uri = ["https://docs.junolab.org/latest"],
            doctype = ["hosted"]
        ),
        # Julia
        (
            name = "julia",
            url = "https://github.com/JuliaLang/julia",
            uuid = "1222c4b2-2114-5bfd-aeef-88e4692bbb3e",
            versions = [v"1.2.0", v"1.3.0"],
            installs = ["missing", "missing"],
            hosted_uri = ["https://docs.julialang.org/en/v1", "https://docs.julialang.org/en/v1"],
            success = [true, true],
            doctype = ["hosted", "hosted"]
        ),
        # git-dir docs
        (
            name = "DifferentialEquations",
            url = "https://github.com/JuliaDiffEq/DifferentialEquations.jl.git",
            uuid = "0c46a032-eb83-5123-abaf-570d42b7fbaa",
            versions = [v"6.9.0"],
            installs = [true],
            success = [true],
            doctype = ["git-repo"],
        )
    ]

    basepath = @__DIR__
    rm(joinpath(basepath, "logs"), force = true, recursive = true)
    rm(joinpath(basepath, "build"), force = true, recursive = true)

    DocumentationGenerator.build_documentation(
        packages, basepath = basepath, filter_versions = identity, processes = 1
    )

    build = joinpath(basepath, "build")
    @testset "build folder" begin
        for pkg in packages
            pkgbuild = joinpath(build, DocumentationGenerator.get_docs_dir(pkg.name, pkg.uuid))
            @test isdir(pkgbuild)
            @testset "$(pkg.name): $(version)" for (i, version) in enumerate(pkg.versions)
                log = joinpath(basepath, "logs", string(pkg.name, "-", pkg.uuid, "-", version, ".log"))
                @test isfile(log)

                println("\n---- LOG $(pkg.name)@$(version) START ----\n")
                println(read(log, String))
                println("\n---- LOG $(pkg.name)@$(version) END ----\n")

                versiondir = joinpath(pkgbuild, string(version))
                @test isdir(versiondir)
                toml_path = joinpath(versiondir, "meta.toml")
                @test isfile(toml_path)
                if isfile(toml_path)
                    toml = Pkg.TOML.parsefile(toml_path)
                    pkginstalls = get(toml, "installable", false)
                    pkgsuccess = get(toml, "success", false)
                    pkgdoctype = get(toml, "doctype", "")
                    @test pkginstalls == pkg.installs[i]
                    @test pkgsuccess == pkg.success[i]
                    @test pkgdoctype == pkg.doctype[i]

                    if pkg.doctype[i] == "hosted"
                        @test get(toml, "hosted_uri", "") == pkg.hosted_uri[i]
                    end

                    if pkginstalls == true
                        doctype = get(toml, "doctype", nothing)
                        @test doctype == pkg.doctype[i]
                        @test isfile(joinpath(versiondir, "index.html"))
                        if doctype == "default"
                            @test isdir(joinpath(versiondir, "autodocs"))
                        end
                    end
                end
            end
        end
    end
end

@testset "Documentation Registry" begin
    mktempdir() do dir
        reg = DocumentationGenerator.get_registry(dir)
        @test isfile(reg)
        toml = Pkg.TOML.parsefile(reg)
        @test length(keys(toml)) > 0
        @test haskey(toml, "e5e0dc1b-0480-54bc-9374-aad01c23163d")
        junosettings = toml["e5e0dc1b-0480-54bc-9374-aad01c23163d"]
        @test junosettings["method"] == "hosted"
    end
end
