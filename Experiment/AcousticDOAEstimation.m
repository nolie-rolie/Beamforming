% AcousticDOAEstimation.m
% Author: Nolan Fey
% 11/3/2020

% This script records acoustic signal from nMics connected to an audio
% interface and outputs it to experiment.wav. Then, it uses a time delay
% beamformer to determine the direction of arrival of a sound source. It
% outputs a plot of the maximum amplitude of audio at each angle. The peak
% corresponds to the location of a sound source. The direction of arrival
% is displayed in the command window. 


clc;
clear;
close all;

%% Model a Uniform Linear Array of Microphones

% model omnindirectional microphone, operating range 20 Hz - 20 kHz
microphone = ...
    phased.OmnidirectionalMicrophoneElement('FrequencyRange',[20 20e3]);

nMics = 5;
ula = phased.ULA(nMics,0.05,'Element',microphone); % spacing = 5 cm
c = 343; % speed of sound in air, in m/s

%% Data Acquisition

Driver = 'ASIO';
Device = 'MOTU Audio ASIO';
nSampPerFrame = 1024;
fs = 96000;
BitDepth = "24-bit integer";


AudioInterface = audioDeviceReader('Driver',Driver,'Device',Device,...
    'NumChannels',nMics,'ChannelMappingSource',"Property",...
    'ChannelMapping',1:nMics,'SamplesPerFrame',nSampPerFrame,...
    'SampleRate',fs,'BitDepth',BitDepth);
setup(AudioInterface);

fileWriter = dsp.AudioFileWriter('experiment.wav','FileFormat','WAV',...
    'SampleRate',fs);

duration = 3; %s
disp('Start recording.')
tic
while toc < duration
    acquiredAudio = AudioInterface();
    fileWriter(acquiredAudio);
end
disp('Recording complete.')

release(AudioInterface)
release(fileWriter)

%% Read Files

experimentFileReader = dsp.AudioFileReader('experiment.wav',...
    'SamplesPerFrame',nSampPerFrame);

audioWriter = audioDeviceWriter('SampleRate',fs, ...
        'SupportVariableSizeInput', true);
    
isAudioSupported = (length(getAudioDevices(audioWriter))>1);

nSamples = fs * duration;
signal = zeros(nSamples,nMics);

for m = 1:nSampPerFrame:nSamples
    sig_idx = m:m+nSampPerFrame-1;
    temp = experimentFileReader();
    if isAudioSupported
        play(audioWriter,temp(:,2));
    end
    signal(sig_idx,:) = temp;
end

%signal(:,1) = signal(:,1)/100;
%signal(:,5) = signal(:,1)/10;
%% Beamscan DOA Estimator

beamformer = phased.TimeDelayBeamformer('SensorArray',ula,...
    'SampleRate',fs,'DirectionSource','Input port','PropagationSpeed',c);

range = -90:90;
size = length(range);

maxLevels = zeros(length(range));

bfOut = zeros();

for iter = 1:size
    
    bfOut = step(beamformer,signal,[range(iter); 0]);
    
    maxLevels(iter) = max(bfOut);
    
end


test = 0;
for iter = 1:size
    if(test < maxLevels(iter))
       DOA = range(iter); 
       test = maxLevels(iter);
    end
end

disp(['The direction or arrival was ',num2str(DOA),' degrees.']);

% plot in new figure window
figure
plot(range,maxLevels);
xlabel('Angle (deg)'); ylabel ('Amplitude (V)');
title('Max Level at Each Angle');







