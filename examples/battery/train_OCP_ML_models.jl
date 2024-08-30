using BattMo, Flux, Statistics, ProgressMeter, Plots, BSON, CUDA

# data and training parameters
train_samples = 200000
test_samples = 1000
epochs = 3000
batch_size = 20000
lr = 0.0005
mkpath("hybrid_output")


function generate_training_data_neg_electrode(train_samples, cmax, T, min_theta, max_theta)
    theta_values = sort(min_theta .+ (max_theta - min_theta) .* rand(train_samples))
    input = theta_values'
    output = BattMo.computeOCP_Graphite_Torchio.(theta_values .* cmax, T, cmax)'
    return input, output
end

function generate_training_data_pos_electrode(train_samples, cmax, T, min_theta, max_theta)
    theta_values = sort(min_theta .+ (max_theta - min_theta) .* rand(train_samples))
    input = theta_values'
    output = BattMo.computeOCP_NMC111.(theta_values .* cmax, T, cmax)'
    return input, output
end

function create_model()
    return f64(Chain(
        Dense(1 => 64, tanh; init=Flux.glorot_normal),
        Dense(64 => 64, tanh; init=Flux.glorot_normal),
        Dense(64 => 64, tanh; init=Flux.glorot_normal),
        Dense(64 => 64, tanh; init=Flux.glorot_normal),
        Dense(64 => 1; init=Flux.glorot_normal)
    ))
end

function train_model(model, training_input, training_output, epochs, batch_size)
    model = f64(gpu(model))
    training_input = f64(gpu(training_input))
    training_output = f64(gpu(training_output))

    loader = Flux.DataLoader((training_input, training_output), batchsize=batch_size, shuffle=true)
    opt = Flux.setup(Flux.Adam(lr), model)

    losses = []
    @showprogress for epoch in 1:epochs
        for (x, y) in loader
            loss, grads = Flux.withgradient(model) do m
                y_hat = m(x)
                Flux.mse(y_hat, y)
            end
            Flux.update!(opt, model, grads[1])
            push!(losses, loss)
        end
    end

    model = f64(cpu(model))
    training_input = f64(cpu(training_input))
    training_output = f64(cpu(training_output))
    return model, losses
end

function plot_input_data(theta_values, output_values, electrode)
    p = plot(vec(theta_values), vec(output_values), 
        xlabel="θ", 
        ylabel="OCP", 
        title="Input Data: θ vs OCP for $electrode",
        label="Training Data",
        alpha=0.5)
    savefig(p, "hybrid_output/input_data_$electrode.png")
end

function plot_loss_curve(epochs, losses, electrode)
    p = plot(losses, xlabel="Iteration", ylabel="Loss", label="per batch", yscale=:log10)
    plot!(epochs:epochs:length(losses), mean.(Iterators.partition(losses, epochs)),
    label="epoch mean", dpi=200)
    title!(p, "Training Loss for $electrode")
    savefig(p, "hybrid_output/training_loss_$electrode.png")
end

function plot_comparison(theta_values, analytical_output, predicted_output, electrode)
    p = plot(vec(theta_values), vec(analytical_output), label="Analytical", xlabel="θ", ylabel="OCP")
    plot!(p, vec(theta_values), vec(predicted_output), label="ML Model")
    title!(p, "OCP: Analytical vs ML Model for $electrode")
    savefig(p, "hybrid_output/ocp_model_output_comparison_$electrode.png")
end

function plot_relative_error(theta_values, relative_error, electrode)
    p = plot(vec(theta_values), vec(relative_error), label="Relative Error", xlabel="θ", ylabel="Relative Error")
    title!(p, "Relative Error of ML Model for $electrode")
    savefig(p, "hybrid_output/relative_error_$electrode.png")
end


function train_model_neg_electrode()
    # parameters for negative electrode
    cmax_neg = 30555.0
    T_neg = 298.15
    min_theta_neg = 5037.26861129033/cmax_neg
    max_theta_neg = 27056.75805/cmax_neg

    training_input, training_output = generate_training_data_neg_electrode(train_samples, cmax_neg, T_neg, min_theta_neg, max_theta_neg)
    test_input, test_output = generate_training_data_neg_electrode(test_samples, cmax_neg, T_neg, min_theta_neg, max_theta_neg)

    OCP_ML_model_negative_electrode = create_model()

    plot_input_data(training_input, training_output, "negative_electrode")
    OCP_ML_model_negative_electrode, losses = train_model(OCP_ML_model_negative_electrode,
                                                          training_input,
                                                          training_output,
                                                          epochs,
                                                          batch_size)

    # Save the model to file
    BSON.@save "OCP_ML_model_negative_electrode.bson" OCP_ML_model_negative_electrode

    # Test the model
    predicted_output = OCP_ML_model_negative_electrode(test_input)[1,:]

    # Calculate metrics for the training set
    predicted_output_train = OCP_ML_model_negative_electrode(training_input)[1,:]
    training_output = vec(training_output)
    mae_train = mean(abs.(training_output .- predicted_output_train))
    mse_train = mean((training_output .- predicted_output_train).^2)
    println("Training Set - Mean Absolute Error for negative electrode: ", mae_train)
    println("Training Set - Mean Squared Error for negative electrode: ", mse_train)

    # Calculate metrics for the test set
    test_output = vec(test_output)
    mae_test = mean(abs.(test_output .- predicted_output))
    mse_test = mean((test_output .- predicted_output).^2)
    relative_error_test = abs.(vec(test_output) .- vec(predicted_output)) ./ vec(test_output)
    println("Test Set - Mean Absolute Error for negative electrode: ", mae_test)
    println("Test Set - Mean Squared Error for negative electrode: ", mse_test)

    # plot the data
    plot_loss_curve(epochs, losses, "negative_electrode")
    plot_comparison(test_input, test_output, predicted_output, "negative_electrode")
    plot_relative_error(test_input, relative_error_test, "negative_electrode")

end

function train_model_pos_electrode()
    # parameters for positive electrode
    cmax_pos = 55554.0
    T_pos = 298.15
    min_theta_pos = 27527.007/cmax_pos
    max_theta_pos = 55095.12396/cmax_pos

    training_input, training_output = generate_training_data_pos_electrode(train_samples, cmax_pos, T_pos, min_theta_pos, max_theta_pos)
    test_input, test_output = generate_training_data_pos_electrode(test_samples, cmax_pos, T_pos, min_theta_pos, max_theta_pos)

    OCP_ML_model_positive_electrode = create_model()
    plot_input_data(training_input, training_output, "positive_electrode")

    OCP_ML_model_positive_electrode, losses = train_model(OCP_ML_model_positive_electrode,
                                                          training_input,
                                                          training_output,
                                                          epochs,
                                                          batch_size)

    # Save the model to file
    BSON.@save "OCP_ML_model_positive_electrode.bson" OCP_ML_model_positive_electrode

    # Test the model
    predicted_output = OCP_ML_model_positive_electrode(test_input)[1,:]

    # Calculate metrics for the training set
    predicted_output_train = OCP_ML_model_positive_electrode(training_input)[1,:]
    training_output = vec(training_output)
    mae_train = mean(abs.(training_output .- predicted_output_train))
    mse_train = mean((training_output .- predicted_output_train).^2)
    println("Training Set - Mean Absolute Error for positive electrode: ", mae_train)
    println("Training Set - Mean Squared Error for positive electrode: ", mse_train)

    # Calculate metrics for the test set
    test_output = vec(test_output)
    mae_test = mean(abs.(test_output .- predicted_output))
    mse_test = mean((test_output .- predicted_output).^2)
    relative_error_test = abs.(vec(test_output) .- vec(predicted_output)) ./ vec(test_output)
    println("Test Set - Mean Absolute Error for positive electrode: ", mae_test)
    println("Test Set - Mean Squared Error for positive electrode: ", mse_test)

    # plot the data
    plot_loss_curve(epochs, losses, "positive_electrode")
    plot_comparison(test_input, test_output, predicted_output, "positive_electrode")
    plot_relative_error(test_input, relative_error_test, "positive_electrode")
end

train_model_neg_electrode()
train_model_pos_electrode()