% record.m
% Author: Nolan Fey
% 11/6/2020

% Records an audio signal from an audio interface, and outputs it to
% recording.wav.

clear
clc

Driver = 'ASIO';
Device = 'MOTU Audio ASIO';
nSampPerFrame = 512;
fs = 44100;
BitDepth = "24-bit integer";


AudioInterface = audioDeviceReader('Driver',Driver,'Device',Device,...
    'NumChannels',1,'ChannelMappingSource',"Property",...
    'ChannelMapping',1,'SamplesPerFrame',nSampPerFrame,...
    'SampleRate',fs,'BitDepth',BitDepth);
setup(AudioInterface);

fileWriter = dsp.AudioFileWriter('recording.wav','FileFormat','WAV');

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