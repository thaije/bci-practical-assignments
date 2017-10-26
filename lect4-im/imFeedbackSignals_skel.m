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



trlen_ms=3000;

% load classifier
clsfr = load('clsfr.mat');

% convert ms to samples
trlen_samp=trlen_ms/1000*hdr.fsample; 

endTest = false;

startType = 'stimulus.target';
endType = 'stimulus.training';
endValue = 'end';



while( ~endTest )
    % wait for data to apply the classifier to
    [data,devents,state]=buffer_waitData(buffhost,buffport,[],'startSet',{startType},'trlen_ms',trlen_ms,'exitSet',{'data' {endType endValue}})

    % process these events
    for ei=1:numel(devents)

        if ( matchEvents(devents(ei), endType, endValue) ) % end training
          endTest=true;

        elseif ( matchEvents(devents(ei),startType) ) % flash, apply the classifier

          [f,fraw,p]=buffer_apply_ersp_clsfr(data(ei).buf, clsfr);

          sendEvent('classifier.prediction',f,devents(ei).sample);
         

            fprintf('Sent classifier prediction = %s.\n',sprintf('%g ',f));
            fprintf('Sent classifier prediction score = %s.\n',sprintf('%g ',logsig(f)));
            
        else

          fprintf('Unmatched event : %s\n',ev2str(devents(ei)));

        end
    end % devents 
end

