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

% p300 duration
targetDuration = 600;
trlen_ms=targetDuration;
dname  ='calibration_data';

% check buffer for events which start with 'startSet' event and record
% events for 'trlen_ms' ms. Stop when 'exitSet' is received
[data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{'stimulus.target'},'trlen_ms',trlen_ms,'exitSet',{'stimulus.training' 'end'})

% remove the end task from the events
mi=matchEvents(devents,'stimulus.target'); 
devents=devents(mi); 
data=data(mi); 

fprintf('Saving %d epochs to : %s\n',numel(devents),dname);
save(dname,'data','devents');
