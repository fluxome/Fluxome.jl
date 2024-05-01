using Fluxome
using Test

mktempdir() do tmpdir

    # Define the reaction network and the report path
    rn = @reaction_network begin
        σ, 0 --> A
        d, A --> 0
    end

	reportpath = "reports/immigrationdeath/";
    reportpath = joinpath(tmpdir, reportpath);
    @info "Temporary directory for ID reports " reportpath

    # Initialize the ReactionNetworkSimulation
    u0 = zeros(50);
    u0[1] = 1.0;
    tspan = (0, 10.0);
    network = ReactionNetworkSimulation(rn, reportpath, u0, tspan);

    # Set up reporting environment
    @test setup_reaction_network_reports(network) == mkpath(reportpath)

    # Check the initial graph save
    save_reaction_network_graph(network, "network_petri_graph.pdf")
    @test isfile(joinpath(reportpath, "network_petri_graph.pdf"))

    # Simulate the network with given parameters
    ps = [10.0, 1.0];
    sol = simulate_reaction_network(network, ps)
    @test typeof(sol) == typeof(simulate_reaction_network(network, ps))

    # Plot and save the distributions at different time points
    plot_and_save_distribution_timepoint(sol, network, 3, "0_001")
    @test isfile(joinpath(reportpath, "distribution_t0_001.pdf"))

    plot_and_save_distribution_timepoint(sol, network, 12, "0_3")
    @test isfile(joinpath(reportpath, "distribution_t0_3.pdf"))

end
