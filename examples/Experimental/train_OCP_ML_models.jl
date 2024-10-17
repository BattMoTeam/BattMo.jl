using BattMo
using Lux, ADTypes, Zygote, Optimisers, Random, Plots, JLD2

# data and training parameters
train_samples = 1000
test_samples = 1000
epochs = 20000
lr = 0.0005

folder = string(dirname(pathof(BattMo)), "/../examples/Experimental")
mkpath(joinpath(folder, "hybrid_output"))

# set random seed
rng = Random.MersenneTwister()
Random.seed!(rng, 42)

# set loss function
const loss_function = Lux.MSELoss()

function generate_training_data_neg_electrode(train_samples, cmax, T, min_theta, max_theta)
    theta_values = sort(min_theta .+ (max_theta - min_theta) .* rand(train_samples))
    input = reshape(theta_values, 1, :)  # Create a 1xN matrix
    output = reshape(BattMo.computeOCP_Graphite_Torchio.(theta_values .* cmax, T, cmax), 1, :)  # Reshape to 1xN matrix
    return input, output
end

function generate_training_data_pos_electrode(train_samples, cmax, T, min_theta, max_theta)
    theta_values = sort(min_theta .+ (max_theta - min_theta) .* rand(train_samples))
    input = reshape(theta_values, 1, :)
    output = reshape(BattMo.computeOCP_NMC111.(theta_values .* cmax, T, cmax), 1, :)
    return input, output
end

function create_model()
    return Lux.Chain(
        Lux.Dense(1 => 32, Lux.tanh),
        Lux.Dense(32 => 32, Lux.tanh),
        Lux.Dense(32 => 32, Lux.tanh),
        Lux.Dense(32 => 32, Lux.tanh),
        Lux.Dense(32 => 1)
    )
end

function train_model(model, train_x, train_y, epochs)

    opt = Optimisers.Adam(lr)
    ps, st = Lux.setup(rng, model)
    ps = ps |> f64
    tstate = Training.TrainState(model, ps, st, opt)
    vjp_rule = ADTypes.AutoZygote()

    losses = []
    for epoch in 1:epochs
        epoch_losses = []
        _, loss, _, tstate = Training.single_train_step!(vjp_rule, loss_function, (train_x, train_y), tstate)
        push!(epoch_losses, loss)
        append!(losses, epoch_losses)
        if epoch % 50 == 1 || epoch == epochs
            println("Epoch: $(lpad(epoch, 3)) \t Loss: $(round(mean(epoch_losses), sigdigits=5))")
        end
    end

    return tstate.parameters, tstate.states, losses
end

function plot_input_data(theta_values, output_values, electrode)
    p = plot(vec(theta_values), vec(output_values),
        xlabel="θ",
        ylabel="OCP",
        title="Input Data: θ vs OCP for $electrode",
        label="Training Data",
        alpha=0.5)
    savefig(p, joinpath(folder, "hybrid_output/input_data_$electrode.png"))
end

function plot_loss_curve(epochs, losses, electrode)
    p = plot(losses, xlabel="Iteration", ylabel="Loss", label="per batch", yscale=:log10)
    plot!(epochs:epochs:length(losses), mean.(Iterators.partition(losses, epochs)),
    label="epoch mean", dpi=200)
    title!(p, "Training Loss for $electrode")
    savefig(p, joinpath(folder, "hybrid_output/training_loss_$electrode.png"))
end

function plot_comparison(theta_values, analytical_output, predicted_output, electrode)
    p = plot(vec(theta_values), vec(analytical_output), label="Analytical", xlabel="θ", ylabel="OCP")
    plot!(p, vec(theta_values), vec(predicted_output), label="ML Model")
    title!(p, "OCP: Analytical vs ML Model for $electrode")
    savefig(p, joinpath(folder, "hybrid_output/ocp_model_output_comparison_$electrode.png"))
end

function plot_relative_error(theta_values, relative_error, electrode)
    p = plot(vec(theta_values), vec(relative_error), label="Relative Error", xlabel="θ", ylabel="Relative Error")
    title!(p, "Relative Error of ML Model for $electrode")
    savefig(p, joinpath(folder, "hybrid_output/relative_error_$electrode.png"))
end


function train_model_neg_electrode()
    # parameters for negative electrode
    cmax_neg = 30555.0
    T_neg = 298.15
    min_theta_neg = 5037.26861129033/cmax_neg
    max_theta_neg = 27056.75805/cmax_neg

    train_x, train_y = generate_training_data_neg_electrode(train_samples, cmax_neg, T_neg, min_theta_neg, max_theta_neg)
    test_x, test_y = generate_training_data_neg_electrode(test_samples, cmax_neg, T_neg, min_theta_neg, max_theta_neg)

    OCP_ML_model_neg_electrode = create_model()
    plot_input_data(train_x, train_y, "negative_electrode")

    ps_neg, st_neg, losses = train_model(OCP_ML_model_neg_electrode,
                                         train_x,
                                         train_y,
                                         epochs)

    # Calculate metrics for the training set
    train_y_pred = Lux.apply(OCP_ML_model_neg_electrode, train_x, ps_neg, st_neg)
    train_y_pred = vec(train_y_pred[1])
    train_y = vec(train_y)

    mae_train = mean(abs.(train_y .- train_y_pred))
    mse_train = mean((train_y .- train_y_pred).^2)
    println("Training Set - Mean Absolute Error for negative electrode: ", mae_train)
    println("Training Set - Mean Squared Error for negative electrode: ", mse_train)

    # Calculate metrics for the test set
    test_y_pred = Lux.apply(OCP_ML_model_neg_electrode, test_x, ps_neg, st_neg)
    test_y_pred = vec(test_y_pred[1])
    test_y = vec(test_y)

    mae_test = mean(abs.(test_y .- test_y_pred))
    mse_test = mean((test_y .- test_y_pred).^2)
    relative_error_test = abs.(vec(test_y) .- vec(test_y_pred)) ./ vec(test_y)
    println("Test Set - Mean Absolute Error for negative electrode: ", mae_test)
    println("Test Set - Mean Squared Error for negative electrode: ", mse_test)

    # Save the model to file
    @save joinpath(folder, "OCP_ML_model_negative_electrode.jld2") OCP_ML_model_neg_electrode ps_neg st_neg

    # plot the data
    plot_loss_curve(epochs, losses, "negative_electrode")
    plot_comparison(test_x, test_y, test_y_pred, "negative_electrode")
    plot_relative_error(test_x, relative_error_test, "negative_electrode")

end

function train_model_pos_electrode()
    # parameters for positive electrode
    cmax_pos = 55554.0
    T_pos = 298.15
    min_theta_pos = 27527.007/cmax_pos
    max_theta_pos = 55095.12396/cmax_pos

    train_x, train_y = generate_training_data_pos_electrode(train_samples, cmax_pos, T_pos, min_theta_pos, max_theta_pos)
    test_x, test_y = generate_training_data_pos_electrode(test_samples, cmax_pos, T_pos, min_theta_pos, max_theta_pos)

    OCP_ML_model_pos_electrode = create_model()
    plot_input_data(train_x, train_y, "positive_electrode")

    ps_pos, st_pos, losses = train_model(OCP_ML_model_pos_electrode,
                                         train_x,
                                         train_y,
                                         epochs)

    # Calculate metrics for the training set
    train_y_pred = Lux.apply(OCP_ML_model_pos_electrode, train_x, ps_pos, st_pos)
    train_y_pred = vec(train_y_pred[1])
    train_y = vec(train_y)

    mae_train = mean(abs.(train_y .- train_y_pred))
    mse_train = mean((train_y .- train_y_pred).^2)
    println("Training Set - Mean Absolute Error for positive electrode: ", mae_train)
    println("Training Set - Mean Squared Error for positive electrode: ", mse_train)

    # Calculate metrics for the test set
    test_y_pred = Lux.apply(OCP_ML_model_pos_electrode, test_x, ps_pos, st_pos)
    test_y_pred = vec(test_y_pred[1])
    test_y = vec(test_y)

    mae_test = mean(abs.(test_y .- test_y_pred))
    mse_test = mean((test_y .- test_y_pred).^2)
    relative_error_test = abs.(vec(test_y) .- vec(test_y_pred)) ./ vec(test_y)
    println("Test Set - Mean Absolute Error for positive electrode: ", mae_test)
    println("Test Set - Mean Squared Error for positive electrode: ", mse_test)

    # Save the model to file
    @save joinpath(folder, "OCP_ML_model_positive_electrode.jld2") OCP_ML_model_pos_electrode ps_pos st_pos

    # plot the data
    plot_loss_curve(epochs, losses, "positive_electrode")
    plot_comparison(test_x, test_y, test_y_pred, "positive_electrode")
    plot_relative_error(test_x, relative_error_test, "positive_electrode")
end