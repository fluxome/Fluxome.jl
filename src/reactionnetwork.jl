using FiniteStateProjection
using DifferentialEquations
using PythonPlot
using Base.Iterators

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
using Fluxome

# Define the reaction network and the report path
rn = @reaction_network begin
	σ, 0 --> A
	d, A --> 0
end
reportpath = "reports/immigrationdeath/";

# Initialize the ReactionNetworkSimulation
u0 = zeros(50);
u0[1] = 1.0;
tspan = (0, 10.0);
network = ReactionNetworkSimulation(rn, reportpath, u0, tspan);
setup_reaction_network_reports(network);

# Save the graph
save_reaction_network_graph(network, "network_petri_graph.pdf")

# Simulate the network
ps = [10.0, 1.0];
sol = simulate_reaction_network(network, ps);

# Plot and save the distributions at different time points
plot_and_save_distribution_timepoint(sol, network, 3, "0_001")
plot_and_save_distribution_timepoint(sol, network, 12, "0_3")

# output
Python: None

```
"""
struct ReactionNetworkSimulation
    rn::ReactionSystem
    reportpath::String
    u0::AbstractArray{Float64}
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
    return solve(prob, Vern7(), dense = false, save_everystep = true, abstol = 1e-6)
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
function plot_and_save_distribution_timepoint(
        sol, rn::ReactionNetworkSimulation, tidx::Int, filename_suffix::String)
    t = sol.t[tidx]
    pyplot.suptitle("Distribution at t = $(t)")
    pyplot.bar(0:(length(rn.u0) - 1), sol.u[tidx], width = 1)
    pyplot.xlabel("# of Molecules")
    pyplot.ylabel("Probability")
    pyplot.xlim(-0.5, length(rn.u0) - 0.5)
    pyplot.savefig(rn.reportpath * "distribution_t$(filename_suffix).pdf")
    pyplot.close()
end

function find_closest_indices(times, target_times)
    return [argmin(abs.(times .- t)) for t in target_times]
end

"""
plot_and_save_distribution_timepoints(sol, rn::ReactionNetworkSimulation, plot_times, filename_suffix::String)

Plot and save the distributions at specific times for the given solution `sol` and reaction network `rn`. 
The times at which the distributions are to be plotted are specified in `plot_times`. 
The plot is saved with a filename suffix `filename_suffix`.

# Arguments
- `sol`: The solution of the simulation.
- `rn::ReactionNetworkSimulation`: The reaction network simulation.
- `plot_times::Vector{Float64}`: A vector of times at which the distributions are to be plotted.
- `filename_suffix::String`: The filename suffix for the saved plot.

# Example
```julia
plot_and_save_distribution_timepoints(sol, rn, [1.0, 2.0, 3.0], "suffix")
```

This will create a plot with subplots showing the distributions at times 1.0, 2.0, and 3.0 
and save it with a filename that includes the specified suffix.
"""
function plot_and_save_distribution_timepoints(
        sol, rn::ReactionNetworkSimulation, plot_times, filename_suffix::String)
    t_indices = find_closest_indices(sol.t, plot_times)

    num_plots = length(plot_times)
    nrows = ceil(Int, sqrt(num_plots))
    ncols = ceil(Int, num_plots / nrows)
    fig, axs = pyplot.subplots(nrows, ncols)

    if num_plots == 1
        axs = [axs]
    end

    for (id, (t, tidx)) in enumerate(zip(plot_times, t_indices))
        rt = round(sol.t[tidx], digits = 1)

        u_matrix = sol.u[tidx]
        dims = size(u_matrix)

        if length(dims) == 2
            bar_data = sum(u_matrix, dims = 1)[1, 1:end]
        else
            bar_data = u_matrix
        end

        if num_plots == 1
            ax = axs[id]
        else
            ax = axs.flatten()[id - 1]
        end

        ax.bar(0:(size(rn.u0)[2] - 1), Iterators.flatten(bar_data), width = 1)
        ax.set_title("Distribution at t = $(rt)")
        ax.set_xlabel("# of Molecules")
        ax.set_ylabel("Probability")
        ax.set_ylim(bottom = 0)
    end

    pyplot.subplots_adjust(wspace = 0.35, hspace = 0.5)
    pyplot.savefig(rn.reportpath * "distributions_$(filename_suffix).pdf")
    pyplot.close(fig)
end

"""
save_reaction_network_graph(rn::ReactionNetwork, filename::String)

Save the graph representation of the given reaction network rn with the specified filename filename.
"""
function save_reaction_network_graph(rn::ReactionNetworkSimulation, filename::String)
    g = Graph(rn.rn)
    savegraph(g, rn.reportpath * filename, "pdf")
end
