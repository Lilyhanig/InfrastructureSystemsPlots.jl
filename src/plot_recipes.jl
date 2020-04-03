### PlotlyJS set up
function set_seriescolor(seriescolor::Array, gens::Array)
    colors = []
    for i in 1:length(gens)
        count = i % length(seriescolor)
        if count == 0
            count = length(seriescolor)
        end
        colors = vcat(colors, seriescolor[count])
    end
    return colors
end

function plotly_stack_gen(
    stacked_gen::StackedGeneration,
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = stacked_gen.labels
    seriescolor = set_seriescolor(seriescolor, gens)
    for gen in 1:length(gens)
        push!(
            traces,
            PlotlyJS.scatter(;
                name = gens[gen],
                x = stacked_gen.time_range,
                y = stacked_gen.data_matrix[:, gen],
                stackgroup = "one",
                mode = "lines",
                fill = "tonexty",
                line_color = seriescolor[gen],
                fillcolor = seriescolor[gen],
            ),
        )
    end
    p = PlotlyJS.plot(traces, PlotlyJS.Layout(title = title, yaxis_title = ylabel))
    set_display && Plots.display(p)
    if !isnothing(save_fig)
        if title == " "
            title = "Stack_Generation"
        end
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        PlotlyJS.savefig(p, joinpath(save_fig, "$title.$format"); width = 630, height = 630)
    end
end

function plotly_stack_gen(
    stacks::Array{StackedGeneration},
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    plots = []
    for stack in 1:length(stacks)
        trace = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = stacks[stack].labels
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            if stack == 1
                leg = true
            else
                leg = false
            end
            push!(
                trace,
                PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = stacks[stack].time_range,
                    y = stacks[stack].data_matrix[:, gen],
                    stackgroup = "one",
                    mode = "lines",
                    fill = "tonexty",
                    line_color = seriescolor[gen],
                    fillcolor = seriescolor[gen],
                ),
            )
        end
        p = PlotlyJS.plot(trace, PlotlyJS.Layout(title = title, yaxis_title = ylabel))
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    if !isnothing(save_fig)
        if title == " "
            title = "Stack_Generation"
        end
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
end

function _check_matching_variables(results::Array)
    variables = DataFrames.DataFrame()
    first_keys = collect(keys(IS.get_variables(results[1])))
    for res in 2:length(results)
        var = collect(keys(IS.get_variables(results[res])))
        if var != first_keys
            throw(IS.ConflictingInputsError("The given results do not have matching variable lists."))
        end
    end
end

function plotly_stack_plots(
    results::IS.Results,
    seriescolor::Array,
    ylabel::String;
    kwargs...,
)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    for (key, var) in IS.get_variables(results)
        traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        var = IS.get_variables(results)[key]
        gens = collect(names(var))
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            push!(
                traces,
                PlotlyJS.scatter(;
                    name = gens[gen],
                    x = results.time_stamp[:, 1],
                    y = convert(Matrix, var)[:, gen],
                    stackgroup = "one",
                    mode = "lines",
                    fill = "tonexty",
                    line_color = seriescolor[gen],
                    fillcolor = seriescolor[gen],
                ),
            )
        end
        p = PlotlyJS.plot(traces, PlotlyJS.Layout(title = "$key", yaxis_title = ylabel))
        set_display && Plots.display(p)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            PlotlyJS.savefig(
                p,
                joinpath(save_fig, "$(key)_Stack.$format");
                width = 630,
                height = 630,
            )
        end
    end
end

function plotly_stack_plots(results::Array, seriescolor::Array, ylabel::String; kwargs...)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    _check_matching_variables(results)
    for key in collect(keys(IS.get_variables(results[1, 1])))
        plots = []
        for res in 1:size(results, 2)
            traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            var = IS.get_variables(results[1, res])[key]
            gens = collect(names(var))
            seriescolor = set_seriescolor(seriescolor, gens)
            for gen in 1:length(gens)
                if res == 1
                    leg = true
                else
                    leg = false
                end
                push!(
                    traces,
                    PlotlyJS.scatter(;
                        name = gens[gen],
                        showlegend = leg,
                        x = results[1, res].time_stamp[:, 1],
                        y = convert(Matrix, var)[:, gen],
                        stackgroup = "one",
                        mode = "lines",
                        fill = "tonexty",
                        line_color = seriescolor[gen],
                        fillcolor = seriescolor[gen],
                    ),
                )
            end
            p = PlotlyJS.plot(
                traces,
                PlotlyJS.Layout(
                    title = "$key",
                    yaxis_title = ylabel,
                    grid = (rows = 3, columns = 1, pattern = "independent"),
                ),
            )
            plots = vcat(plots, p)
        end
        plots = vcat(plots...)
        set_display && Plots.display(plots)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            PlotlyJS.savefig(
                plots,
                joinpath(save_fig, "$(key)_Stack.$format");
                width = 630,
                height = 630,
            )
        end
    end
end

function plotly_bar_gen(
    bar_gen::BarGeneration,
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    time_range = bar_gen.time_range
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
    gens = bar_gen.labels
    seriescolor = set_seriescolor(seriescolor, gens)
    for gen in 1:length(gens)
        push!(
            traces,
            PlotlyJS.scatter(;
                name = gens[gen],
                x = ["$time_span, $(time_range[1])"],
                y = bar_gen.bar_data[:, gen],
                type = "bar",
                marker_color = seriescolor[gen],
            ),
        )
    end
    p = PlotlyJS.plot(
        traces,
        PlotlyJS.Layout(
            title = title,
            yaxis_title = ylabel,
            color = seriescolor,
            barmode = "stack",
        ),
    )
    set_display && Plots.display(p)
    if !isnothing(save_fig)
        if title == " "
            title = "Bar_Generation"
        end
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        PlotlyJS.savefig(p, joinpath(save_fig, "$title.$format"); width = 630, height = 630)
    end
end

function plotly_bar_gen(
    bar_gen::Array{BarGeneration},
    seriescolor::Array,
    title::String,
    ylabel::String;
    kwargs...,
)
    time_range = bar_gen[1].time_range
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2] - time_range[1]) * length(time_range),
    )
    seriescolor = set_seriescolor(seriescolor, bar_gen[1].labels)
    plots = []
    for bar in 1:length(bar_gen)
        traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = bar_gen[bar].labels
        for gen in 1:length(gens)
            if bar == 1
                leg = true
            else
                leg = false
            end
            push!(
                traces,
                PlotlyJS.scatter(;
                    name = gens[gen],
                    showlegend = leg,
                    x = ["$time_span, $(time_range[1])"],
                    y = bar_gen[bar].bar_data[:, gen],
                    type = "bar",
                    barmode = "stack",
                    marker_color = seriescolor[gen],
                ),
            )
        end
        p = PlotlyJS.plot(
            traces,
            PlotlyJS.Layout(
                title = title,
                yaxis_title = ylabel,
                color = seriescolor,
                barmode = "stack",
                stackgroup = "one",
            ),
        )
        plots = vcat(plots, p)
    end
    plots = vcat(plots...)
    set_display && Plots.display(plots)
    if !isnothing(save_fig)
        if title == " "
            title = "Bar_Generation"
        end
        format = get(kwargs, :format, "html")
        title = replace(title, " " => "_")
        PlotlyJS.savefig(
            plots,
            joinpath(save_fig, "$title.$format");
            width = 630,
            height = 630,
        )
    end
end

function plotly_bar_plots(results::Array, seriescolor::Array, ylabel::String; kwargs...)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_range = results[1].time_stamp
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2, 1] - time_range[1, 1]) *
        size(time_range, 1),
    )
    for key in collect(keys(IS.get_variables(results[1])))
        plots = []
        for res in 1:length(results)
            var = IS.get_variables(results[res])[key]
            traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
            gens = collect(names(var))
            seriescolor = set_seriescolor(seriescolor, gens)
            for gen in 1:length(gens)
                if res == 1
                    leg = true
                else
                    leg = false
                end
                push!(
                    traces,
                    PlotlyJS.scatter(;
                        name = gens[gen],
                        showlegend = leg,
                        x = ["$time_span, $(time_range[1, 1])"],
                        y = sum(convert(Matrix, var)[:, gen], dims = 1),
                        type = "bar",
                        barmode = "stack",
                        stackgroup = "one",
                        marker_color = seriescolor[gen],
                    ),
                )
            end
            p = PlotlyJS.plot(
                traces,
                PlotlyJS.Layout(title = "$key", yaxis_title = ylabel, barmode = "stack"),
            )
            plots = vcat(plots, p)
        end
        plots = vcat(plots...)
        set_display && Plots.display(plots)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            PlotlyJS.savefig(
                plots,
                joinpath(save_fig, "$(key)_Bar.$format");
                width = 630,
                height = 630,
            )
        end
    end
end

function plotly_bar_plots(res::IS.Results, seriescolor::Array, ylabel::String; kwargs...)
    set_display = get(kwargs, :display, true)
    save_fig = get(kwargs, :save, nothing)
    time_range = IS.get_time_stamp(res)
    time_span = IS.convert_compound_period(
        convert(Dates.TimePeriod, time_range[2, 1] - time_range[1, 1]) *
        size(time_range, 1),
    )
    for (key, var) in IS.get_variables(res)
        traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]
        gens = collect(names(var))
        seriescolor = set_seriescolor(seriescolor, gens)
        for gen in 1:length(gens)
            push!(
                traces,
                PlotlyJS.scatter(;
                    name = gens[gen],
                    x = ["$time_span, $(time_range[1, 1])"],
                    y = sum(convert(Matrix, var)[:, gen], dims = 1),
                    type = "bar",
                    barmode = "stack",
                    marker_color = seriescolor[gen],
                ),
            )
        end
        p = PlotlyJS.plot(
            traces,
            PlotlyJS.Layout(barmode = "stack", title = "$key", yaxis_title = ylabel),
        )
        set_display && Plots.display(p)
        if !isnothing(save_fig)
            format = get(kwargs, :format, "html")
            PlotlyJS.savefig(
                p,
                joinpath(save_fig, "$(key)_Bar.$format");
                width = 630,
                height = 630,
            )
        end
    end
end
## TODO
RecipesBase.@recipe function StackedPlot(
    results::StackedArea,
    variable::String,
    seriescolor::Array,
)
    seriescolor := seriescolor
    time = convert.(Dates.DateTime, results.time_range)
    n = length(time)
    data = results.data_matrix
    z = cumsum(data, dims = 2)
    # Plot attributes
    grid := false
    title := variable
    if size(results.labels, 2) == 1 # work-around for a weird glitch in recipes
        label := results.labels[1]
    else
        label := results.labels
    end
    legend := :outerright
    interval = time[2] - time[1]
    time_interval = convert(Dates.Hour, interval * n)
    xlabel := "$time_interval"
    xtick := [time[1], time[n]]
    # create filled polygon
    sy = vcat(z[:, 1], zeros(n))
    sx = [time[1:n]; reverse(time[1:n])]
    for c in 1:size(z, 2)
        if c !== 1
            sy = hcat(sy, vcat(z[:, c], reverse(z[:, c - 1])))
        end
    end
    RecipesBase.@series begin
        seriestype := :shape
        sx, sy
    end
end

RecipesBase.@recipe function StackedPlot(
    results::Array{StackedArea},
    variable::String,
    seriescolor::Array,
)
    layout := (length(results), 1)
    for i in 1:length(results)
        res = results[i]
        time = convert.(Dates.DateTime, res.time_range)
        n = length(time)
        data = res.data_matrix
        z = cumsum(data, dims = 2)
        # Plot attributes
        grid := false
        title := variable
        if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
            label := res.labels[1]
        else
            label := res.labels
        end
        legend := :outerright
        interval = time[2] - time[1]
        time_interval = convert(Dates.Hour, interval * n)
        xlabel := "$time_interval"
        xtick := [time[1], time[n]]
        # create filled polygon
        sy = vcat(z[:, 1], zeros(n))
        sx = [time[1:n]; reverse(time[1:n])]
        for c in 1:size(z, 2)
            if c !== 1
                sy = hcat(sy, vcat(z[:, c], reverse(z[:, c - 1])))
            end
        end
        RecipesBase.@series begin
            subplot := i
            seriestype := :shape
            seriescolor := seriescolor[:, 1:size(sy, 2)]
            sx, sy
        end
    end
end

RecipesBase.@recipe function StackedGeneration(res::StackedGeneration, seriescolor::Array)
    seriescolor := seriescolor
    time = convert.(Dates.DateTime, res.time_range)
    n = length(time)
    data = res.data_matrix
    z = cumsum(data, dims = 2)
    # Plot Attributes
    grid := false
    if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
        label := res.labels[1]
    else
        label := res.labels
    end
    legend := :outerright
    interval = time[2] - time[1]
    time_interval = convert(Dates.Hour, interval * n)
    xlabel := "$time_interval"
    xtick := [time[1], time[n]]
    # Create filled polygon
    sy = vcat(z[:, 1], zeros(n))
    sx = [time[1:n]; reverse(time[1:n])]
    for c in 2:size(z, 2)
        if c !== 1
            sy = hcat(sy, vcat(z[:, c], reverse(z[:, c - 1])))
        end
    end
    RecipesBase.@series begin
        seriestype := :shape
        sx, sy
    end

end

RecipesBase.@recipe function StackedGeneration(
    results::Array{StackedGeneration},
    seriescolor::Array,
)
    layout := (length(results), 1)
    for i in 1:length(results)
        res = results[i]
        time = convert.(Dates.DateTime, res.time_range)
        n = length(time)
        data = res.data_matrix
        z = cumsum(data, dims = 2)
        # Plot Attributes
        grid := false
        if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
            label := res.labels[1]
        else
            label := res.labels
        end
        legend := :outerright
        interval = time[2] - time[1]
        time_interval = convert(Dates.Hour, interval * n)
        xlabel := "$time_interval"
        xtick := [time[1], time[n]]
        # Create filled polygon
        sy = vcat(z[:, 1], zeros(n))
        sx = [time[1:n]; reverse(time[1:n])]
        for c in 2:size(z, 2)
            if c !== 1
                sy = hcat(sy, vcat(z[:, c], reverse(z[:, c - 1])))
            end
        end
        RecipesBase.@series begin
            subplot := i
            seriestype := :shape
            seriescolor := seriescolor[:, 1:size(sy, 2)]
            sx, sy
        end
    end
end

RecipesBase.@recipe function BarPlot(res::BarPlot, variable::String, seriescolor::Array)
    seriescolor := seriescolor
    time = convert.(Dates.DateTime, res.time_range)
    n = length(time)
    data_point = res.bar_data
    data = [data_point; data_point]
    z = cumsum(data, dims = 2)
    # Plot Attributes
    grid := false
    title := variable
    seriestype := :shape
    if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
        label := res.labels[1]
    else
        label := res.labels
    end

    legend := :outerright
    interval = time[2] - time[1]
    time_interval = convert(Dates.Hour, interval * n)
    xlabel := "$time_interval, $(time[1])"
    xlims := (1, 8)
    xticks := false
    n = 2
    # Create filled polygon
    for c in 1:size(z, 2)
        sx = [[4, 5]; [5, 4]]
        sy = vcat(z[:, c], c == 1 ? zeros(n) : reverse(z[:, c - 1]))
        RecipesBase.@series sx, sy
    end

end

RecipesBase.@recipe function BarPlot(
    results::Array{BarPlot},
    variable::String,
    seriescolor::Array,
)
    layout := (length(results), 1)
    for i in 1:length(results)
        res = results[i]
        time = convert.(Dates.DateTime, res.time_range)
        n = length(time)
        data_point = res.bar_data
        data = [data_point; data_point]
        z = cumsum(data, dims = 2)
        # Plot Attributes
        grid := false
        title := variable
        seriestype := :shape
        if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
            label := res.labels[1]
        else
            label := res.labels
        end

        legend := :outerright
        interval = time[2] - time[1]
        time_interval = convert(Dates.Hour, interval * n)
        xlabel := "$time_interval, $(time[1])"
        xlims := (1, 8)
        xticks := false
        n = 2
        # Create filled polygon
        seriescolor := seriescolor[:, 1:size(data_point, 2)]
        for c in 1:size(z, 2)
            subplot := i
            sx = [[4, 5]; [5, 4]]
            sy = vcat(z[:, c], c == 1 ? zeros(n) : reverse(z[:, c - 1]))
            RecipesBase.@series sx, sy
        end
    end
end

RecipesBase.@recipe function BarGen(res::BarGeneration, seriescolor::Array)
    seriescolor := seriescolor
    time = convert.(Dates.DateTime, res.time_range)
    n = 2
    data_point = res.bar_data
    data = [data_point; data_point]
    z = cumsum(data, dims = 2)
    # Plot Attributes
    grid := false
    start_time = time[1]
    interval = time[2] - time[1]
    time_interval = convert(Dates.Hour, interval * length(time))
    xlabel := "$time_interval, $(time[1])"
    seriestype := :shape
    if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
        label := res.labels[1]
    else
        label := res.labels
    end
    legend := :outerright
    xlims := (1, 8)
    xticks := false
    for c in 1:size(z, 2)
        sx = [[4, 5]; [5, 4]]
        sy = vcat(z[:, c], c == 1 ? zeros(n) : reverse(z[:, c - 1]))
        RecipesBase.@series sx, sy
    end
end

RecipesBase.@recipe function BarGen(results::Array{BarGeneration}, seriescolor::Array)
    layout := (length(results), 1)
    for i in 1:length(results)
        seriescolor := seriescolor
        res = results[i]
        time = convert.(Dates.DateTime, res.time_range)
        n = 2
        data_point = res.bar_data
        data = [data_point; data_point]
        z = cumsum(data, dims = 2)
        # Plot Attributes
        grid := false
        start_time = time[1]
        interval = time[2] - time[1]
        time_interval = convert(Dates.Hour, interval * length(time))
        xlabel := "$time_interval, $(time[1])"
        seriestype := :shape
        if size(res.labels, 2) == 1 # work-around for a weird glitch in recipes
            label := res.labels[1]
        else
            label := res.labels
        end
        legend := :outerright
        xlims := (1, 8)
        xticks := false
        seriescolor := seriescolor[:, 1:size(data_point, 2)]
        for c in 1:size(z, 2)
            subplot := i
            sx = [[4, 5]; [5, 4]]
            sy = vcat(z[:, c], c == 1 ? zeros(n) : reverse(z[:, c - 1]))
            RecipesBase.@series sx, sy
        end
    end
end
