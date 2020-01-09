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
The model has a few manual settings that change how the model performs. These can be changed prior to running the simulation for vaying the operation.

1. **Drive Trace Settings**
The "manual switch" selectors allow to switch between drive trace source and road grade source. For this study as we assumed road grade to be *zero*, do select the Constant with the value *zero* as input for all simulations.

<img src = "https://github.com/avk4714/EREV-EM-Algorithm/blob/master/Drive_Trace_Settings.png" width="500" height="400">

2. **Battery EPO Block Removal**
This particular block in the model is only to trigger an Emergency Power Off (EPO) signal when discharge current is beyond acceptable limits. As the data controlling this behavior is propreitary, it has not been shared on this repository. Hence, delete this block from the model. **There is no change in the behavior of the model without this block.**

<img src = "https://github.com/avk4714/EREV-EM-Algorithm/blob/master/Battery_EPO_Block.png" width="500" height="400">

3. **Choosing between Conventional and Proposed algorithm simulations**
As we have evaluated two separate algorithms in our study, in order to simulate them, we need to manually comment out certain blocks and change certain constant values.
   * *If simulating the Conventional algorithm*
      * Comment out the "Proposed Algorithm" block as shown in figure below.
      * Change the "Algroithm Switch" constant block value to 1.
      * Have the "Fault Insert" block Inactive by "Unchecking" the option in the subsystem mask.
      * If you run into a missing value error, comment that block out from the model too.
   * *If simulating the Proposed algorithm*
      * Run the *runOptSHEV_DP_FwdProp.m* script with the correct drive trace and Re-Optimization = 0 settings to generate the optimal solution before the drive. 
      * Save "OptResults" structure generated in MATLAB Workspace under a new structure name "N_OptResults".
      * Open the Simulink model and select the same drive trace and other parameters used for initial optimization.
      * Uncomment the "Proposed Algorithm" block as shown in figure below.
      * Change the "Algroithm Switch" constant block value to 2.
      * In the *runOptSHEV_DP_FwdProp.m* script change Re-Optimization = 1, so that the script can be operated by the model.
      * Have the "Fault Insert" block Inactive by "Unchecking" the option in the subsystem mask.
      * Run the simulation. The simulation **pauses** everytime a re-optimization occurs. As the simulation cannot *automatically* unpause, we have to manually keep clicking the "Run" switch in Simulink until the simulation is done.
   
<img src = "https://github.com/avk4714/EREV-EM-Algorithm/blob/master/ReOpt_Settings.png" width="800" height="500">


## How to: Get Average Speed Trace from Google Directions API
This application was built using MATLAB scripts and Google APIs. Before this application can be used you would need to **generate your personal Google API key using Google Console**. Once you have your key add it to the functions/scripts in **Google API Caller** in the line:
> key = "";

.. then continue with the following steps:
1. Open and run the MATLAB script *GenGoogleDriveTrace.m*.
2. This will open a GUI as shown in the figure. The default "Origin" and "Destination" locations are already loaded but new ones can be added.
3. Once the information is provided, Click *Ok* to proceed.
4. In most cases all the data needed will be obtained and the *average speed* vector will be generated based on Live Traffic Information.


**P.S.**: *In certain cases the function returns an error due to empty data variables during the API call. These issues can be fixed by the user if desired or try a different set of locations.*

<img src = "https://github.com/avk4714/EREV-EM-Algorithm/blob/master/Route_Selector_App.png" width="300" height="400">


## External Open-Source Data Links
Argonne National Laboratory (ANL) Dataset (Requires SignUp):
* Energy Systems D3 2014 BMW i3-REX - [BMWi3Data](https://www.anl.gov/es/energy-systems-d3-2014-bmw-i3rex)
* Energy Systems D3 2016 Chevrolet Volt - [ChevroletVoltData](https://www.anl.gov/es/energy-systems-d3-2016-chevrolet-volt)

## Author Contact
If there are any outstanding questions on how to use the model, please send an email to: *avkalia[at]uw[dot]edu* with the Subject line: **[EREV Algorithm - GitHub]:**
