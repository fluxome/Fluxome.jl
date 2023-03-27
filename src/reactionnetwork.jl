using FiniteStateProjection
using DifferentialEquations
using PyPlot

"""
ReactionNetworkSimulation(rn::ReactionSystem, reportpath::String, u0::Vector{Float64}, tspan::Tuple{Float64, Float64})

A composite type representing a reaction network, its initial state, time span, and report path for storing results.

# Fields
- `rn::ReactionSystem`: The reaction network defined as a Catalyst.jl ReactionSystem.
- `reportpath::String`: The path where simulation results will be saved.
- `u0::Vector{Float64}`: The initial state of the system.
- `tspan::Tuple{Float64, Float64}`: The time span for the simulation.

# Examples
```jldoctest
using FiniteStateProjection
using DifferentialEquations
using PyPlot

using fluxome

# Define the reaction network and the report path
rn = @reaction_network begin
    σ, 0 --> A
    d, A --> 0
end σ d;
reportpath = "reports/immigrationdeath/";

# Initialize the ReactionNetworkSimulation
u0 = zeros(50);
u0[1] = 1.0;
tspan = (0, 10.0);
network = ReactionNetworkSimulation(rn, reportpath, u0, tspan);
setup_reaction_network_reports(network);

# Save the graph
save_reaction_network_graph(network, "immigrationdeath_network_petri_graph.pdf")

# Simulate the network
ps = [10.0, 1.0];
sol = simulate_reaction_network(network, ps);

# Plot and save the distributions at different time points
plot_and_save_distribution_timepoint(sol, network, 3, "0_001")
plot_and_save_distribution_timepoint(sol, network, 12, "0_3")

# output

```
"""
struct ReactionNetworkSimulation
    rn::ReactionSystem
    reportpath::String
    u0::Vector{Float64}
    tspan::Tuple{Float64, Float64}
end

"""
    setup_reaction_network_reports(rn::ReactionNetworkSimulation)

Create the report directory for a given `ReactionNetworkSimulation` instance.

This function creates a directory at the specified `reportpath` of the
`ReactionNetworkSimulation` instance if it does not already exist.

# Arguments
- `rn::ReactionNetworkSimulation`: The `ReactionNetworkSimulation` instance for which
  the report directory needs to be created.
"""
function setup_reaction_network_reports(rn::ReactionNetworkSimulation)
    mkpath(rn.reportpath)
end

"""
simulate_reaction_network(rn::ReactionNetworkSimulation, p::Vector{Float64})

Simulate a given reaction network rn with parameters p.

# Arguments
rn::ReactionNetworkSimulation: The reaction network to simulate.
p::Vector{Float64}: The parameters of the reaction network.

# Returns
sol: The solution of the simulation.
"""
function simulate_reaction_network(rn::ReactionNetworkSimulation, p::Vector{Float64})
    sys = FSPSystem(rn.rn)
    prob = convert(ODEProblem, sys, rn.u0, rn.tspan, p)
    return solve(prob, Vern7(), dense=false, save_everystep=true, abstol=1e-6)
end

"""
plot_and_save_distribution_timepoint(sol, rn::ReactionNetwork, tidx::Int, filename_suffix::String)

Plot and save the distribution at a specific time index tidx for the given solution sol and reaction network rn. The plot is saved with a filename suffix filename_suffix.

Arguments
sol: The solution of the simulation.
rn::ReactionNetwork: The reaction network.
tidx::Int: The time index for the distribution to plot.
filename_suffix::String: The filename suffix for the saved plot.
"""
function plot_and_save_distribution_timepoint(sol, rn::ReactionNetworkSimulation, tidx::Int, filename_suffix::String)
    t = sol.t[tidx]
    plt.suptitle("Distribution at t = $(t)")
    plt.bar(0:length(rn.u0)-1, sol.u[tidx], width=1)
    plt.xlabel("# of Molecules")
    plt.ylabel("Probability")
    plt.xlim(-0.5, length(rn.u0)-0.5)
    plt.savefig(rn.reportpath * "immigrationdeath_t$(filename_suffix).pdf")
    plt.close()
end

"""
save_reaction_network_graph(rn::ReactionNetwork, filename::String)

Save the graph representation of the given reaction network rn with the specified filename filename.
"""
function save_reaction_network_graph(rn::ReactionNetworkSimulation, filename::String)
    g = Graph(rn.rn)
    savegraph(g, rn.reportpath * filename, "pdf")
end
