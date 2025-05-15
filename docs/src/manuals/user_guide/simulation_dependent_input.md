

# Simulation-Dependent Input Parameters

## Overview

In BattMo, several key input parameters—such as **open-circuit voltage (OCV) curves**, **electrolyte diffusivity**, and **conductivity**—can vary based on material properties and operating conditions like concentration and temperature. To allow flexibility, these parameters can be specified in one of three supported formats: **real number**, **string-based expression**, or **dictionary-based arrays**.

This page outlines how each type is used and can be specified within a JSON cell parameter set using the diffusion coefficient of the electrolyte as an example.

---

## Supported Parameter Types

### 1. `Real` — Constant Value

A single numeric value is interpreted as a constant, independent of state-of-charge (SOC), concentration (`c`), temperature (`T`), etc.

**Example:**

```JSON 
"DiffusionCoefficient": 2.5e-10 
```


### 2. `String` — Expression-Based Function

String parameters represent mathematical expressions that may depend on:

- `c` – Local concentration  
- `cmax` – Maximum concentration  
- `T` – Temperature (K)
- `refT` – Reference temperature (K)

The string is parsed into a function during initialization and can be evaluated dynamically.

**Example:**

```JSON
"DiffusionCoefficient": "8.794*10^(-11)*(c/1000)^2 - 3.972*10^(-10)*(c/1000) + 4.862*10^(-10)"
```

**Supported variables:**

| Parameter                 | Supported variables  | Battery component |
|---------------------------|----------------------|-------------------|
| `OpenCircuitPotential`    | `c,cmax,T,refT`      | `ActiveMaterial`  |
| `IonicConductivity`       | `c,T`                | `Electrolyte`     |
| `DiffusionCoefficient`    | `c,T`                | `Electrolyte`     |





### 3. `Dict` — Tabular data

For parameters like OCV curves, a dictionary with pre-tabulated data can be used. The dictionary must contain two keys:

- `x` – Representing the data of the dependent variable 
- `y` – Representing the data of the input parameter

**Example:**

```JSON
"DiffusionCoefficient": {
    "x": [0.01, 0.05, 0.10, 0.15, 0.20],
    "y": [0.0, 0.25, 0.5, 0.75, 1.0]}
```

The simulation uses interpolation to evaluate the y-quantity at any given x during the run.

> **Note:** Ensure that both arrays are of equal length.

**Supported data:**

| Parameter                 | Supported x data                  | Battery component |
|---------------------------|-----------------------------------|-------------------|
| `OpenCircuitPotential`    | `StoichiometricCoefficient`       | `ActiveMaterial`  |
| `IonicConductivity`       | `Concentration`                   | `Electrolyte`     |
| `DiffusionCoefficient`    | `Concentration`                   | `Electrolyte`     |