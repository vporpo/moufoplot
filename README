 MoufoPlot README
 Copyright (C) 2012,2013 Vasileios Porpodas <v DOT porpodas AT ed.ac.uk>

 MoufoPlot is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free
 Software Foundation; either version 3, or (at your option) any later
 version.

 MoufoPlot is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.

 You should have received a copy of the GNU General Public License
 along with MoufoPlot; see the file COPYING3.  If not see
 <http://www.gnu.org/licenses/>.


About
-----
 MoufoPlot is an easy-to-use terminal based gnuplot front-end. 

 Why is it easy?
 1. No need to know gnuplot or to write any gnuplot related scripts.
 2. No need to worry about data files or their format.
 3. Control all important plot attributes using command line switches.

 It completely decouples the process of generating the measurements from the
 process of plotting them. 

 Official page: https://github.com/vporpo/moufoplot

Features
--------
 1. Completely decouple the process of generating data from plotting them.
 2. Use a single MoufoPlot command to select data and plot them.
 3. Select between several plot types:
    Bar graphs (simple, stacked, clustered, stacked & clustered)
    Line graphs 
    2D Heat maps
 4. Platform independent (bash script).
 5. On-the-fly generation of average/normalized values. (EXPERIMENTAL).


Installation
------------
 If you don't want to install MoufoPlot, just run it straight away:
 $ ./moufoplot [OPTIONS]

 If you insist on installing it, just copy it to a directory in your path:
 $ sudo cp moufoplot /usr/local/bin/

 OR (if you are lazy enough) just run the install script:
 ./install


Basic Concepts
--------------
 1. Generate Data
   There are two ways:
   A) Using lots of files, each with a single number in it.
   B) Using a single file with all the data

   In A) the input of MoufPlot should be placed in a directory (let's say data/).
   Each data number should be placed in a single file. 
   The file name is crucial:
    a. Obviously each file name should be unique
    b. It should encode the parameters used to generate this data, 
       separated by '_'
   For example: size4k_assoc8_cycles is a valid name that corresponds to the 
   simulating cycles of a processor with a 4k sized cache of associativity 8.
   Similarly an energy measurement of a size:2k,assoc:8 configuration would be
   size2k_assoc8_energy.

   In B) the input of MoufoPlot is a simple text file (say data.txt).
   Each line of the file is in the format: "name:value".
   The "name" should be encoded in the same way as the files in A).
   That is:
    a. It should be unique
    b. It should encode the parameters used to generate this data, 
       separated by '_'
   For example: size4k_assoc8_cycles is a valid name that corresponds to the 
   simulating cycles of a processor with a 4k sized cache of associativity 8.
   Similarly an energy measurement of a size:2k,assoc:8 configuration would be
   size2k_assoc8_energy.
   The data.txt file might then look like this:
      size4k_assoc8_cycles: 377823
      size2k_assoc8_energy: 428032

2. Select Data
  a. Select what to put on each axis:
     Place the cache size on X:
     -x size4k,size8k 
     Place the associativity on Y:
     -y assoc2,assoc4,assoc8 
  b. Filter out the unwanted data, by selecting which ones to keep
     -f cycles
     This will let only the cycles to get through (the energy numbers will not).
  
3. Plot
  moufoplot lets you control the output figure in many ways
  Type: moufoplot --help   to get all the options.
  o plot type: --bar, --stack, --line, --hmap
  o title    : --title "This is the title"
  o legend   : --legend in,right,box,...
  o labels   : --xlabel "Description of the X axis", --ylabel
  o size     : --size 1.0x0.8   (width x height)
  These options get updated frequently, as MoufoPlot gets updated, so please
  check the --help option for an exhaustive list.


Example
-------
 1. Scenario
 - - - - - - -
  In this example I will show how to use moufoplot in the common scenario of
  generating and plotting data that are the output of simulations.
  Each simulation run is controlled by say 3 parameters: A, B and C.
  The values of A are 1,2,3
  The values of B are 100,200,300,400,500
  The values of C are 4.1, 4.2

  The simulator outputs 3 results: TIME, ENERGY, AREA.

 2. Generating data
 - - - - - - - - - - 
  Each simulation run is therefore encoded as Ax_By_Cz_<TYPE>, where:
  1) x,y,z are numbers in {1,2,3}, {100,200,300,400,500}, {4.1, 4.2} 
     respectively
  2) <TYPE> is one of {TIME,ENERGY,AREA}

  We use this exact encoding as 
  A) the line name or
  B) the file name 
  where each of the simulation will be placed.
  For example the simulation results for A=1, B=300, C=4.2 will be placed in:
  A) the data.txt file as in:
    A1_B300_C4.2_TIME: 123
    A1_B300_C4.2_ENERGY: 456
    A1_B300_C4.2_AREA: 789

  B) the data/ directory should contain the following files:
    A1_B300_C4.2_TIME
    A1_B300_C4.2_ENERGY
    A1_B300_C4.2_AREA
  each one containing the numbers 123, 456, 789 respectively.


 3. Plotting using MoufoPlot
 - - - - - - - - - - - - - -
  A. Let's say we want to plot TIME for A in {1,2,3} and B=200, C=4.1
    A) moufoplot -d data.txt -x A1,A2,A3 -f "B200 C4.1 TIME"
    B) moufoplot -d data/ -x A1,A2,A3 -f "B200 C4.1 TIME"
  B. Let's say we want to plot TIME for A in {1,2,3} and B in {100,200}, C=4.1
    A) moufoplot -d data.txt -x A1,A2,A3 -y B100,B200 -f "C4.1 TIME"
    A) moufoplot -d data/ -x A1,A2,A3 -y B100,B200 -f "C4.1 TIME"

More Examples/Documentation
---------------------------
 Check out the examples/index.html using your favourite web browser.
