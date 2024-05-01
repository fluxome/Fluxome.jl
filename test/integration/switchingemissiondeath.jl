using Fluxome
using Test

mktempdir() do tmpdir

    # Define the reaction network and the report path
    rn = @reaction_network begin
        σ_on * (1 - G_on), 0 --> G_on
        σ_off, G_on --> 0
        ρ, G_on --> G_on + M
        d, M --> 0
    end

    reportpath = "reports/sed/";
    reportpath = joinpath(tmpdir, reportpath)
    @info "Temporary directory for SED reports " reportpath

    # Initialize the ReactionNetworkSimulation
    u0 = zeros(2, 50);
    u0[1, 1] = 1.0;
    tspan = (0, 10.0);
    network = ReactionNetworkSimulation(rn, reportpath, u0, tspan);

    # Set up reporting environment
    @test setup_reaction_network_reports(network) == mkpath(reportpath)

    # Check the initial graph save
    save_reaction_network_graph(network, "network_petri_graph.pdf")
    @test isfile(joinpath(reportpath, "network_petri_graph.pdf"))

    # Simulate the network with given parameters
    ps = [0.25, 0.15, 15.0, 1.0]
    sol = simulate_reaction_network(network, ps)
    @test typeof(sol) == typeof(simulate_reaction_network(network, ps))

    # Check the plot and save functions for distributions at specific times
    plot_and_save_distribution_timepoints(sol, network, [10.0], "end_timepoint")
    @test isfile(joinpath(reportpath, "distributions_end_timepoint.pdf"))

    plot_and_save_distribution_timepoints(sol, network, [0.6, 4.9, 2.4, 10.0], "four_timepoints")
    @test isfile(joinpath(reportpath, "distributions_four_timepoints.pdf"))

end