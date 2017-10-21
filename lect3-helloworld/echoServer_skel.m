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
% set the real-time-clock to use
initgetwTime;
initsleepSec;

% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% wait for new events of a particular type
 % initial state
%[events,state]=buffer_newevents(buffhost,buffport,state,'echo') % wait for next echo event

state = [];
continueWhile = true;

while continueWhile
    [events, state] = buffer_newevents(buffhost, buffport, state, [], []);
    
    % check events, if one is exit stop
    for ei=1:numel(events);
        if(strcmp(events(ei).type,'exit'))
            continueWhile = false;
        elseif~(strcmp(events(ei).type,'echo'))
            sendEvent('echo',events(ei).value);
        end
    end
end