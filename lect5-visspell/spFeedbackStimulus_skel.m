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

verb=0;
nSeq=6;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.1; % the length a row/col is highlighted
feedbackDuration=2; % length of time feedback is on the screen
bgCol=[.5 .5 .5]; % background color (grey)
flashCol=[1 1 1]; % the 'flash' color (white)
tgtColor=[0 1 0]; % the target indication color (green)
global textObject;

% the set of options the user will pick from
% this is what they will see on the screen
symbols={'A' 'B';
         'C' 'D';};
indices = [1, 3, 2, 4, 1, 3];
% N.B. Note the transpose, as screen coordinates (x,y) are transposed relative to 
%  matrix coordinates (row,col) we store the symbols such that row=x and col=y

% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------

% Usefull functions
% make the a stimulus grid with symbols in it, return the *text* handles
[h,symbs]=initGrid(symbols);

sendEvent('stimulus.feedback','start');

textObject = text(.5,.5,'','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.1,'color','white','visible','on'); 
set(textObject, 'string', "");
drawnow;

for loop=1:nSeq
    
    sendEvent('stimulus.sequence','start');
    
    getKeypress();
    set(h(indices(loop)),'color', tgtColor);
    drawnow;
    sleepSec(cueDuration);
    set(h(indices(loop)),'color', bgCol);
    drawnow;
    
    stimSeq=zeros(numel(symbols),nRepetitions*numel(symbols)); % [nSyb x nFlash] used record what flashed when
    nFlash=0;
    for innerloop=1:nRepetitions
        sendEvent('stimulus.repetition','start');

        for ei=1:numel(symbols)
            
            nFlash=nFlash+1;
            % record info about what was flashed at this time
            stimSeq(indices(ei),nFlash)=true;
            
            % get letter and send event
            cell = symbols(indices(ei));
            ev=sendEvent('stimulus.target.letter',cell{1});
            
            if indices(loop) == indices(ei)
                ev=sendEvent('stimulus.target','1', ev.sample);
            else
                ev=sendEvent('stimulus.target','0', ev.sample);
            end
            
            set(h(indices(ei)),'color', flashCol);
            sleepSec(stimDuration);
            drawnow;
            set(h(indices(ei)),'color', bgCol);
            sleepSec(stimDuration);
            drawnow;
        end
        sendEvent('stimulus.repetition','end');
    end
    
    % Feedback code
    % combine the classifier predictions with the stimulus used
    % wait for the signal processing pipeline to return the set of predictions
    if( verb>0 ) fprintf(1,'Waiting for predictions\n'); end;
    
    [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
    
    if ( ~isempty(devents) ) 
        % correlate the stimulus sequence with the classifier predictions to identify the most likely letter
        pred =[devents.value]; % get all the classifier predictions in order
        nPred=numel(pred);
        ss   = reshape(stimSeq(:,1:nFlash),[numel(symbols) nFlash]);
        corr = ss(:,1:nPred)*pred(:);  % N.B. guard for missing predictions!
        [ans,predTgt] = max(corr); % predicted target is highest correlation

        % show the classifier prediction
        set(h(predTgt),'color',tgtColor);
        drawnow;
        sendEvent('stimulus.prediction',symbols{predTgt});
    end
    sleepSec(feedbackDuration);
    % show prediction
    set(h(predTgt),'color',bgCol);
    
    sendEvent('stimulus.sequence','end');
end

sendEvent('stimulus.feedback','end');

% show thank you text
textObject = text(.5,.5,'','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color','white','visible','on'); 
set(textObject, 'string', "Thank you");
drawnow;

% wait for a keypress
function x = getKeypress()
    global textObject;
    set(textObject, 'string', "Press to continue");
    w = 0;
    % w=0 is mouseclick, w=1 is keypress
    while( w == 0)
        w = waitforbuttonpress;
    end
    set(textObject, 'string', "");
    sendEvent('stimulus.keypress','button');
end