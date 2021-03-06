%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Student		:	Tjalling Haije
% Student ID	: 	s1011759
% Course		:	BCI Practical
% Assignment	: 	Tutorial Feature Attention BCI - stimulus / calibration
% Date			: 	31-10-2017 
% Description   :   This file does the signal processing of the calibration
%                   phase. It saves all target events after being
%                   triggered, and writes these to a file. 
%                           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;


alphabetDuration = 2600;
% these extra ms are added to ensure that when the cue is showed last, the 
% P300 signal is also caught
interLetterDuration = 500;

trlen_ms= alphabetDuration + interLetterDuration;
dname  ='calibration_data';

% check buffer for events which start with 'startSet' event and record
% events for 'trlen_ms' ms. Stop when 'exitSet' is received
[data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'exitSet',{'stimulus.training' 'end'})

% Only use stimulus.target events
mi=matchEvents(devents,'stimulus.target'); 
devents = devents(mi); 
data = data(mi); 

fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
save(dname,'data','devents');
