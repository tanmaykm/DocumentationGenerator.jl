using Pkg
using Pkg: TOML
using DocumentationGenerator

Pkg.status()

function build(uuid, name, url, version, buildpath, registry, deployment_url, src_prefix, href_prefix, build_pdf, args...)
    build_pdf = build_pdf == "true"
    packagespec = PackageSpec(uuid = uuid, name = name, version = VersionNumber(version))
    withenv(
        "DOCUMENTATIONGENERATOR" => "true",
        "CI" => "true",
        "DOCUMENTATIONGENERATOR_BASE_URL" => DocumentationGenerator.docs_url(deployment_url, name, uuid, version)
    ) do
        metadata = DocumentationGenerator.package_metadata(packagespec, url)
        build_meta = DocumentationGenerator.build_package_docs(packagespec, buildpath, registry; src_prefix=src_prefix, href_prefix=href_prefix, build_pdf=build_pdf)
        if build_pdf
            merge!(metadata, Dict("pdf" => build_meta))
        else
            merge!(metadata, build_meta)
        end

        isdir(buildpath) || mkpath(buildpath)

        pkgsource = DocumentationGenerator.copy_package_source(packagespec, buildpath)
        if pkgsource ≠ nothing && isdir(pkgsource)
            DocumentationGenerator.render_readme_html(pkgsource, buildpath, src_prefix, href_prefix)
        else
            @error("Could not render readme because we don't have the source files.")
        end

        if pkgsource !== nothing && ispath(pkgsource)
            metadata["license"], metadata["license_url"] = DocumentationGenerator.license(joinpath(buildpath, "_packagesource"))
        end

        @info "opening meta.toml"
        open(joinpath(buildpath, "meta.toml"), "w") do io
            @info "writing meta.toml"
            TOML.print(io, metadata)
        end
    end
end

function update_metadata(uuid, name, url, version, buildpath, registry, deployment_url, args...)
    metapath = joinpath(buildpath, "meta.toml")
    packagespec = PackageSpec(uuid = uuid, name = name, version = version)
    withenv(
        "DOCUMENTATIONGENERATOR" => "true",
        "CI" => "true",
        "DOCUMENTATIONGENERATOR_BASE_URL" => DocumentationGenerator.docs_url(deployment_url, name, uuid, version)
    ) do
        if isfile(joinpath(buildpath, "meta.toml"))
            metadata = TOML.parsefile(metapath)
            updated_metadata = DocumentationGenerator.package_metadata(packagespec, url)
            merge!(metadata, updated_metadata)

            @info "opening meta.toml"
            open(metapath, "w") do io
                @info "writing meta.toml"
                TOML.print(io, metadata)
            end
        else
            @error("Tried updating metadata, but did not find an existing `meta.toml` at `$(metapath)`.")
        end
    end
end

if ARGS[end] === "update"
    update_metadata(ARGS...)
else
    build(ARGS...)
end
