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
nSeq=15;
nRepetitions=5;  % the number of complete row/col stimulus before sequence is finished
cueDuration=2;
stimDuration=.1; % the length a row/col is highlighted
feedbackDuration=2; % length of time feedback is on the screen
bgCol=[.5 .5 .5]; % background color (grey)
flashCol=[1 1 1]; % the 'flash' color (white)
tgtCol=[0 1 0]; % the target indication color (green)
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

sendEvent('stimulus.training','start');

textObject = text(.5,.5,'','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.1,'color','white','visible','on'); 
set(textObject, 'string', "");
drawnow;

for loop=1:6
    
    sendEvent('stimulus.sequence','start');
    
    getKeypress();
    set(h(indices(loop)),'color', tgtCol);
    drawnow;
    sleepSec(cueDuration);
    set(h(indices(loop)),'color', bgCol);
    drawnow;
    
    for innerloop=1:nRepetitions
        sendEvent('stimulus.repetition','start');

        for ei=1:numel(symbols)
            
            % get letter and send event
            cell = symbols(indices(ei));
            sendEvent('stimulus.target.letter',cell{1});
            
            if indices(loop) == indices(ei)
                sendEvent('stimulus.target','1');
            else
                sendEvent('stimulus.target','0');
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
    
    % show prediction
    sendEvent('stimulus.sequence','end');
end

sendEvent('stimulus.training','end');

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