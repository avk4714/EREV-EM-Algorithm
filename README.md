# EREV-EM-Algorithm
This repository serves as **Supplementary Data** for the Article titled *"On Implementing Optimal Energy Management for EREV using Distance Constrained Adaptive Real-Time Dynamic Programming"* submitted to MDPI Journal Electronics in **January 2020**. 
>The MATLAB/Simulink model, scripts and functions were made on *MATLAB 2018b*. It is suggested to use this version of MATLAB for easier setup.

## Repository Contents
1. **Custom Evaluation Scripts**
    * This directory contains various evaluation scripts developed during the study.
2. **Custom Functions**
    * This directory contains various functions developed during the study. 
    * They are used in different scripts and models for this study.
3. **Drive Cycles**
    * This directory contains different drive cycles used during the study.
    * The (.txt) extension files are to be used with the script version of the model.
    * The (.mat) extension files are to be used with the Simulink version of the model.
4. **EREV Simulink Model**
    * This directory contains the Simulink (.slx) model for the experimental research EREV.
    * It also contains additional files that need to be loaded into Workspace for the model to run.
5. **Google API Caller**
    * This directory contains the *Route Selector App* sub-directory, custom functions and a referenced function for plotting.
    * The *GenGoogleDriveTrace.m* script in the sub-directory helps generate the custom drive trace.
6. **Reference Dataset**
    * This directory contains (.mat) files used for data validation in the study.
7. **Additional Scripts/Functions**
    * *optimize_SHEV_DP.m* : MATLAB function version of the EREV model with Dynamic Programming energy optimizer.
    * *runOptSHEV_DP_FwdProp.m* : MATLAB parent script to call the *optimize_SHEV_DP.m* function and set parameters.
    * *SHEV_DP_FwdProp.m* : MATLAB base script for custom evaluations and modifications.

## How to: Setup the Model
Follow these steps to setup the model for simulations:

1. Download/Clone this repository on your PC.
2. Start MATLAB and "Add the downloaded Directory/Sub-Directories to path". (It is important to have all of the contents of the downloaded repository in MATLAB path.
3. Open the MATLAB script named *startPwrLossMdl.m* inside the **EREV Simulink Model** directory. Adjust the *Load Drive Cycle* parameters per available choices. Run the script.
4. If the model opens without errors or major warnings, the setup is complete.

## How to: Run/Modify the Model


## How to: Get Average Speed Trace from Google Directions API

## How to: Operate the Model with Re-Optimization

## External Open-Source Data Links
Argonne National Laboratory (ANL) Dataset (Requires SignUp):
* Energy Systems D3 2014 BMW i3-REX - [BMWi3Data](https://www.anl.gov/es/energy-systems-d3-2014-bmw-i3rex)
* Energy Systems D3 2016 Chevrolet Volt - [ChevroletVoltData](https://www.anl.gov/es/energy-systems-d3-2016-chevrolet-volt)
