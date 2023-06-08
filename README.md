
# What is MatlabPNM?

![GitHub](https://img.shields.io/github/license/leilahashemi/MatlabPNM)
[![codecov](https://codecov.io/gh/leilahashemi/MatlabPNM/branch/master/graph/badge.svg?token=68C8WTS8OW)](https://codecov.io/gh/leilahashemi/MatlabPNM)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/leilahashemi/MatlabPNM/documentation.yaml)](https://leilahashemi.github.io/MatlabPNM/)
<!-- ![GitHub all releases](https://img.shields.io/github/downloads/leilahashemi/MatlabPNM/total) -->

MatlabPNM is an open-source software developed for flow simulation at micro-scale through porous media using a quasi-static pore-network modelling approach. It includes modules for generating various common network topologies, pore and throat geometry models, pore scale physics models, and fluid property estimation. It also contains a growing set of algorithms for running various simulations such drainage and Imbibition curves, permeability, and more. MatlabPNM is written in Matlab.

<p align="center">
  <img src="./results/PNM.gif" width="500"/>
</p>
<!-- 
## Quasi-static package graph
<p align="center">
  <img src="./results/quasi.png" width="700"/>
</p>

## Quasi-static drainage flowchart
<p align="center">
  <img src="./results/drain.png" width="600"/>
</p>

## Quasi-static imbibition flowchart
<p align="center">
  <img src="./results/imb.png" width="800"/>
</p> -->

## Installation
* Download the repository as a zip file. For the latest release, please check [releases page](https://github.com/mhgolestan/MatlabPNM/releases/) for available downloads.
* Extract the zip archive on your computer.

### MATLAB installation
User has access to MATLAB version 2016 or higher. The code does not require any scpecific toolbox to be installed.We are planning to make a plugging or python rapper that makes it possible to run the code without Matlab being installed. 

## User documentation
To run the codes, start with the main.m file and update simulation setting throught the main file. Therefore a little bit knowledge of Matlan is required however we are aiming to make a setting file that can make it easier to run the simulations without knowing Matlab. 
For a detailed explanation about installing and using the software, please look at out [user documentation](https://github.com/mhgolestan/MatlabPNM/blob/master/doc/User_Manual.md).
 
## Contributing
Our goal is to help other scientists and engineers harness the power and intuitive pore network modeling approach, so if you are interested in this package, please contact us through Github. You are welcome to contribute as a developer to the code via pull requests. Please look at the contribution [guidelines](??).


### Prerequisites
* MATLAB 2016 or higher.

### Installation
* Download the MatlabPNM repository via a terminal:
```
git clone https://github.com/mhgolestan/MatlabPNM.git
```
* All source code can be found in the src directory.

## Licensing
The source code and data of MatlabPNM are licensed under the MIT License. 
