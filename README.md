# Beamforming
 MATLAB code for my 2020 Audio Tech Project.

## Prerequisites
* MATLAB 
	* Phased Array Toolbox 
	* Digital Signal Processing Toolbox 
	* Audio Toolbox 
 
*(The rest is only required for code in Experiment folder)*
* Audio Interface (>= 2 inputs)
* Driver for audio interface ([I used the MOTU 8pre USB](https://motu.com/techsupport/technotes/driverlog))
* Microphones (>= 2)
* [ASIO4ALL Drivers](http://www.asio4all.org/)
  
## Quick Start
1. [Fork this repository](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/fork-a-repo)
2. Open Simulation/SimAcousticBeamforming in MATLAB OR Open Simulation/SimAcousticDOAEstimation in MATLAB
3. OPTIONAL: Change the simulated audio environment
	* Record 3 audio files (>= 3 seconds) and move them to Beamforming/Simulation folder
	* Change angles of arrival by adjusting *ang_target*, *ang_1*, *ang_2*
	* Adjust *fs* and *NSampPerFrame* to match your audio files
	* Adjust *FileReaderTarget*, *FileReader1*, and *FileReader2* to match your audio files (i.e. dsp.AudioFileReader('{your_file_name}','SamplesPerFrame',NSampPerFrame);)
4. Run (F5)
 
## Code Walkthroughs
* Connecting an audio interface with MATLAB
* Recording and reading audio in MATLAB
* How to run simulation scripts
* Experiment Demo

