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


% make the target sequence
sentences={'hello world','this is new!','BCI is fun!'};
interSentenceDuration=5;
interCharDuration=1;


% ----------------------------------------------------------------------------
%    FILL IN YOUR CODE BELOW HERE
% ----------------------------------------------------------------------------


% useful functions


% make the stimulus, i.e. put a text box in the middle of the axes
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
h=text(.5,.5,'','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color',[1 1 1],'visible','on'); 
drawnow;

sendEvent('stimulus.seq','start');


for sent=1:numel(sentences);
    % get the current sentence
    currentSent = sentences(sent);
    currentSent = currentSent{1};
    
    message = "Waiting for keypress"

    % wait for button press
    w = 0;
    while( w == 0)
        w = waitforbuttonpress
    end
    sendEvent('stimulus.keypress','button');
    
    % clear string
    currentString = '';
    set(h,'string', currentString);
    drawnow update;
    sendEvent('stimulus.cleardisplay','true');
    
    message = "5 sec countdown to start"
    sleepSec(interSentenceDuration);
    sendEvent('stimulus.sentence','start');
    
    
        
    % loop through the letters in the sentences
    for letter=1:numel(currentSent);
        
        % get the current letter, concatenate to
        % the string and print to the screen
        letter = currentSent(letter);
        currentString = [currentString letter]
        set(h,'string', currentString);
        drawnow update;
        
        % send event and wait for next letter
        sendEvent('stimulus.addletter',letter);
        sleepSec(interCharDuration);
        
    end;
    
    % send event and wait
    sendEvent('stimulus.sentences','end');
    
end;

sendEvent('stimulus.seq','end');


% wait for a key press
%msg=msgbox({'Press OK to continue'},'Continue?');while ishandle(msg); pause(.2); end;
