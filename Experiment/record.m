% record.m
% Author: Nolan Fey
% 11/6/2020

% Records an audio signal from an audio interface, and outputs it to
% recording.wav.

clear
clc

% copy and past the next two lines into command window to get names of 
% available audio devices

% deviceReader = audioDeviceReader;
% devices = getAudioDevices(deviceReader)

Driver = 'ASIO';
Device = 'MOTU Audio ASIO';
nSampPerFrame = 1024;
fs = 96000;
BitDepth = "24-bit integer";
nMics = 2;


AudioInterface = audioDeviceReader('Driver',Driver,'Device',Device,...
    'NumChannels',nMics,'ChannelMappingSource',"Property",...
    'ChannelMapping',1:nMics,'SamplesPerFrame',nSampPerFrame,...
    'SampleRate',fs,'BitDepth',BitDepth);
setup(AudioInterface);

fileWriter = dsp.AudioFileWriter('recording.wav','FileFormat','WAV',...
    'SampleRate',fs);

% fileWriterc1 = dsp.AudioFileWriter('channel1.wav','FileFormat','WAV',...
%     'SampleRate',fs);
% 
% fileWriterc2 = dsp.AudioFileWriter('channel2.wav','FileFormat','WAV',...
%     'SampleRate',fs);

duration = 3; %s
disp('Start recording.')
tic
while toc < duration
    acquiredAudio = AudioInterface();
    fileWriter(acquiredAudio);
%     fileWriterc1(acquiredAudio(:,1));
%     fileWriterc2(acquiredAudio(:,2));
end
disp('Recording complete.')

release(AudioInterface)
release(fileWriter)
% release(fileWriterc1)
% release(fileWriterc2)