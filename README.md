# benefit_transitions_and_wellbeing

An analysis on the effect of transitions from benefit to employment on overall well-being of individuals using a combination of GSS Survey and IDI Administrative data.

## Overview
This analysis presents the second application of the Social Investment Agency's (SIA's) wellbeing measurement approach to a policy issue. Our first application was social housing tenancy.

The analysis uses the New Zealand General Social Survey data in the IDI, combined with administrative data to look at how the transition from benefit to employment impacts the wellbeing of people.

The method adopted in this paper (and code) aims to move beyond a simple descriptive approach, to instead identify the difference in wellbeing outcomes for people before and after making the transition off benefit and into employment. While this is not as good an estimate of the causal impact as a genuine experimental evaluation, by providing a dynamic picture of the change in wellbeing outcomes associated with the transition, it significantly enriches the available evidence base.

## Dependencies
* It is necessary to have an IDI project if you wish to run the code. Visit the Stats NZ website for more information about this.
* While we have attempted to capture all the code dependencies in this project, several other SIA repositories may be required to successfully run this project, these repositories are:
	* `social_investment_analytical_layer (SIAL)` 
	* `social_investment_data_foundation (SIDF)` 
	* `SIAtoolbox`
Instructions for the installation of each repository can be found in their respective readme files.

## Folder descriptions

**documentation:** This folder contains key documentation, including code flow diagram, and notes on combining the first 5 waves of the GSS.

**include:** This folder contains generic formatting scripts.

**sasautos:** This folder contains supporting SAS macros.

**sasprogs:** This folder contains SAS programs.

**rprogs:** This folder contains all the necessary R scripts that are required to perform the analysis on the dataset created by the SAS code.

**sql:** This folder contains several key sql scripts.

## Running the benefit transitions and wellbeing project

The process for running the project is outlined in the document code_flowchart.docx contained in the documentation folder. This shows the key scripts that need to be run, along with the key tables that are produced along the way.

Please note, that the SAS environment has been upgraded to SAS GRID since this code was first written. Hence parts of the code may require updating to match the new environment.

## Getting Help
If you have any questions email info@sia.govt.nz

