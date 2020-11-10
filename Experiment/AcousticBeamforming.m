% AcousticBeamforming.m
% Author: Nolan Fey
% 11/3/2020

% This script records acoustic signal from nMics connected to an audio
% interface and outputs it to raw.wav. Then, it uses a time delay
% beamformer to steer towards towards a certain angle and eliminate noise
% from other angles. It output the beamformed output to beamed.wav.


clc;
clear;
close all;

%% Model a Uniform Linear Array of Microphones

% model omnindirectional microphone, operating range 20 Hz - 20 kHz
microphone = ...
    phased.OmnidirectionalMicrophoneElement('FrequencyRange',[20 20e3]);

nMics = 3;
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
    'ChannelMapping',2:4,'SamplesPerFrame',nSampPerFrame,...
    'SampleRate',fs,'BitDepth',BitDepth);
setup(AudioInterface);

fileWriter = dsp.AudioFileWriter('raw.wav','FileFormat','WAV',...
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

experimentFileReader = dsp.AudioFileReader('raw.wav',...
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

%% Process with Time Delay Beamformer

% define steering direction!!!
angSteer = [-45; 0]; % [angle,elevation] degrees 
beamformer = phased.TimeDelayBeamformer('SensorArray',ula,...
    'SampleRate',fs,'Direction',angSteer,'PropagationSpeed',c);

signalsource = dsp.SignalSource('Signal',signal,...
    'SamplesPerFrame',nSampPerFrame);

tdbfOut = zeros(nSamples,1);

fileWriter2 = dsp.AudioFileWriter('beamed.wav','FileFormat','WAV',...
    'SampleRate',fs);

for m = 1:nSampPerFrame:nSamples
    temp = beamformer(signalsource());
    if isAudioSupported
        play(audioWriter,temp);
        fileWriter2(temp);
    end
    tdbfOut(m:m+nSampPerFrame-1,:) = temp;
end

release(fileWriter2);
