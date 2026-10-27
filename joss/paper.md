---
title: "BattMo.jl: A Julia package for battery cell modelling"
tags:
  - Julia
  - battery modeling
authors:
  - name: Lorena Hendrix
    orcid: 0009-0006-9621-6122
    affiliation: 1
  - name: Xavier Raynaud
    orcid: 0000-0002-4100-3035
    affiliation: 2
  - name: Olav Møyner
    orcid: 0000-0001-9993-3879
    affiliation: 2
  - name: Eibar Flores
    orcid: 0000-0003-2954-1233
    affiliation: 1
  - name: Halvor Møll Nilsen
    orcid: 0000-0002-2153-0962
    affiliation: 2
  - name: August Johansson
    orcid: 0000-0001-6950-6016
    affiliation: 2
  - name: Francesca Watson
    orcid: 0000-0002-4391-4166
    affiliation: 2
  - name: Sridevi Krishnamurthi
    orcid: 0009-0006-0805-6713
    affiliation: 1
  - name: Simon Clark^[corresponding author]
    orcid: 0000-0002-8758-6109
    affiliation: 1
affiliations:
  - name: SINTEF Industry, Dept. of Sustainable Energy Technology, Norway
    index: 1
  - name: SINTEF Digital, Dept. of Mathematics and Cybernetics, Norway
    index: 2
date: 17 November 2025
bibliography: paper.bib
---

<!-- To compile this file, after installing docker, from this directory, run : docker run --rm --volume $PWD:/data --user $(id -u):$(id -g) --env JOURNAL=joss openjournals/inara  -->

# Summary

This paper introduces BattMo.jl, an open-source Julia framework for continuum-scale simulation of electrochemical devices. Using a finite-volume approach, BattMo.jl supports pseudo-2-dimensional (P2D) models for fast screening on a reduced-order mesh, as well as more comprehensive pseudo-four-dimensional (P4D) models that incorporate the 3D design of realistic geometries, including cylindrical cells and pouch cells.

The toolbox combines high-performance solvers, built-in libraries of battery designs and cycling protocols, calculation of cell KPI's, quick plotting tools, and an intuitive programmatic and graphical interface. It further includes an adjoint-based optimization framework for parameter estimation and model calibration, enabling close integration of modelling with experimental workflows. The [BattMoTeam](https://batterymodel.com/our-team/) collaborates closely with the [SINTEF Battery Lab](https://www.sintef.no/en/all-laboratories/sintef-battery-lab/), gaining valuable input from experienced battery researchers and helping to bridge the gap between academic modelling and industrial innovation. This partnership helps ensure that the toolbox remains relevant and effective in real-world applications, driving innovation and advancing the field of energy storage technology.

# Statement of need

Physics-based battery cell modelling has a wide range of applications across the battery field. It provides insight into the electrochemical and transport processes occurring inside a battery cell, helping researchers and engineers understand performance limitations and degradation mechanisms. Such models can be used to improve cell design, evaluate long-term performance without extensive testing campaigns, optimize operating conditions to extend cell lifetime, and support advanced battery management strategies. They can also act as virtual twins during laboratory testing, helping to monitor, interpret, and guide experiments in real time.

Ultimately, physics-based battery cell models enable faster and more cost-effective evaluation of battery designs and operating strategies, making them valuable tools throughout the battery industry. Their impact extends beyond research and development into education, where they help students and early-career researchers understand battery operation, electrochemical processes, and performance characteristics across both commercial and emerging chemistries. In this way, modelling tools contribute to educating the next generation of battery scientists and cell designers.

To support these applications, BattMo.jl places a strong emphasis on usability and accessibility. The software provides an open-source command-line API for advanced users alongside an open-source graphical user interface designed for ease of use. This enables researchers, engineers, educators, and students to explore battery behaviour without extensive programming experience. In educational settings, the graphical interface can be incorporated into teaching activities, providing interactive virtual experiments that complement theory and improve understanding of battery science.

# State of the field

BattMo.jl originates from the BattMo framework, which was initially developed in MATLAB. Rather than extending an existing platform, BattMo.jl was created to provide the same modelling capabilities in a fully open-source, non-proprietary programming language. Julia was chosen both to improve accessibility and to leverage its high-performance scientific computing ecosystem, enabling efficient large-scale battery simulations without sacrificing flexibility or usability.

Computational efficiency is a key consideration, particularly when simulating long-term and 3 dimensional battery behavior. During the implementation of BattMo in Julia, substantial emphasis was placed on minimizing computational overhead and achieving fast simulation times. As a result, a simple P2D constant-current discharge simulation could be executed in approximately 0.5 seconds, compared to several seconds for the corresponding implementation in MATLAB.

# Software design

The design of the software was guided by four overarching principles: usability, interoperability, compliance with battery-domain standards, and computational efficiency. These principles informed the development of the software architecture, data structures, and user interface, ensuring a framework that is both accessible to users and suitable for high-performance battery modeling applications.

The software architecture is designed to improve usability and reduce the learning curve by organizing core workflows and input parameters into clearly defined steps and categories. By making simulation and solver settings optional, users can initially focus on constructing the virtual cell representation and defining cycling protocols, while more advanced configuration options can be introduced progressively as familiarity with the software increases. In addition, considerable effort has been devoted to ensuring consistency in the specification, modification, and retrieval of input parameters and output quantities, thereby simplifying the overall workflow.

The same design philosophy has been applied to the user-facing programming interface. The software objects are structured to interact in a logical and intuitive manner. For example, a simulation object depends on a model object that defines the underlying mathematical framework and associated assumptions. Similarly, a calibration object is built upon a simulation object, which provides the complete simulation setup required as the basis for parameter estimation. Both simulation and calibration objects can be executed through a common solve function, which dispatches to the appropriate method depending on the object type supplied. This approach results in a coherent and consistent user API, improving both usability and extensibility.

To facilitate interoperability, all input parameters for a BattMo.jl model can be provided through JSON-formatted files, making the input specification independent of the programming language used. Furthermore, to ensure compliance with standardized terminology and data structures, all model inputs, outputs, and associated units are defined according to the EMMO and BattINFO ontologies. The framework also provides functionality for inspecting input parameters, output quantities, and programmatic objects. For each entity, the corresponding ontology term and its Internationalized Resource Identifier (IRI) are available, allowing users to directly access the relevant ontology documentation. This ontology-driven approach promotes consistency, transparency, and interoperability across different modeling tools and workflows.

The development of BattMo.jl has focused on performance. BattMo.jl is built on top of Jutul.jl [@Jutul] which provides a reliable foundation for meshing intricate geometries, efficiently solving large systems of equations, and visualizing the results. For plotting, BattMo.jl and Jutul.jl rely on Makie.jl [@Makie].

# Examples

Plenty of examples can be found in the [BattMo.jl documentation](https://battmo.org/BattMo.jl/stable/) together with a set of beginner tutorials in which a user can learn the tool step by step.

# BattMo family

The following software include the BattMo family:

| Software                                             |                 Description                 |
| ---------------------------------------------------- | :-----------------------------------------: |
| [BattMo.jl](https://github.com/BattMoTeam/BattMo.jl) | Julia version presented in this publication |
| [BattMo](https://github.com/BattMoTeam/BattMo)       |    MATLAB and original version of BattMo    |
| [PyBattMo](https://github.com/BattMoTeam/PyBattMo)   |       Python wrapper around BattMo.jl       |
| [BattMoApp](https://app.battmo.org/)                 |  Web-application built on top of BattMo.jl  |

# Research impact statement

BattMo.jl has already impacted the battery research field in several ways: the graphical user interface build upon BattMo.jl has been used in lectures to show students the behaviour of a battery cell in an intuative way, developers of BattMo.jl have recieved positive feedback during multiple workshop sessions that have been organized to give people an introduction to BattMo.jl and how to incorporate it in their daily battery research, and BattMo has seen an increase in followers on LinkedIn. The toolbox BattMo has been used in several publications, BattMo specifically, has been used for hybrid optimization and neural network approaches. The BattMo team is working towards building a larger community.

# AI usage disclosure

The development of BattMo.jl started before agentic AI coding harnesses became available. Therefore, only recently, coding assistants like github copilot, claude code and codex have been used on a small part of the main code. While writing this paper, AI tools have been used to help with concising and phrasing. In all use cases, the authors have reviewed and edited the suggestions of the AI tools.

# Acknowledgements

We acknowledge contributions from the European Union, Grant agreements 101069765 (IntelLiGent), 875527 (HYDRA), 957189 (BIG-MAP), 101104013 (BATMAX) and 101103997 (DigiBatt).

# References
