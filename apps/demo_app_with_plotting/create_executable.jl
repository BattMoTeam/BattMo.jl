using PackageCompiler
create_app("BattMoDemoApp", "battmo_compiled",
                    precompile_execution_file = "precompile_battmo.jl", # Precompilation script
                    force = true,                                      # Delete existing files
                    incremental=true,
                    sysimage_build_args = Cmd(["-O2"]))         # Set Julia flags for precompilation
