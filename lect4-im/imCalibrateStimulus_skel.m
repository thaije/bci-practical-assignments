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


% set variables/parameters
global textObject;
global interRepetitionDuration;
global stimulusDuration;
global showCueDuration;

interRunDuration = 2;
interRepetitionDuration = 2;
stimulusDuration = 3;

showCueDuration = 1;

sequences = 3;
epochs = 5;

% initialize sleep function, otherwise sleepSec might throw errors
initsleepSec();


% make the stimulus, i.e. put a text box in the middle of the axes
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
textObject = text(.5,.5,'','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color','white','visible','on'); 
drawnow;



sendEvent('stimulus.training', 'start');

% do the calibration runs and their repetitions
for i=1:sequences;
    
    % wait for key press
    getKeypress();
    
    sendEvent('stimulus.seq',i);
    sendEvent('stimulus.seq', 'start');
    
    % Do the repetitions
    for j=1:epochs;
        sendEvent('stimulus.epoch.start',j);
        doRepetition(); 
        sendEvent('stimulus.epoch.end',j);
        
        sleepSec(interRepetitionDuration);
    end
    
    % clear the screen
    clearText();
    sendEvent('stimulus.seq','end');
end

sendEvent('stimulus.training', 'end');
updateText("Thank you"); 


function x = doRepetition()
    global showCueDuration;
    global stimulusDuration;
    
    % get a random shuffle of the alphabet
    a = getRandomLetter();
        
    % Time for the subject to mentally prepare
    %sendEvent('stimulus.alphabet','start');
    
    updateText("-"); 
    sendEvent('stimulus.baseline','start');
    sleepSec(showCueDuration);
    sendEvent('stimulus.baseline','end');
    
    % loop through the letters in the alphabet    
    updateText(a); 
    sendEvent('stimulus.target', a);
    sendEvent('stimulus.trial','start');
    sleepSec(stimulusDuration);
    sendEvent('stimulus.trial','end');
    
    % clear screen
    clearText();
end

% update the text and do the corresponding actions
function x = displayletter(letter)
    global interLetterDuration;
    
    % show the letter on the screen
    updateText(letter);

    % send event and wait for next letter
    sendEvent('stimulus.letter',letter);
    sleepSec(interLetterDuration);
end

% Empty the screen
function x = clearText()
    global textObject;
    textObject.Color = 'white';
    updateText('');
    sendEvent('stimulus.cleardisplay',"true");
end

% update the text on the screen
function x = updateText(text)
    global textObject;
    set(textObject, 'string', text);
    drawnow update;
end

% wait for a keypress
function x = getKeypress()
    disp("Waiting for keypress");
    global textObject;
    set(textObject, 'string', "Press key to start");
    w = 0;
    % w=0 is mouseclick, w=1 is keypress
    while( w == 0)
        w = waitforbuttonpress;
    end
    set(textObject, 'string', "");
    sendEvent('stimulus.keypress','button');
end

% generate a random order for the letters
function a = getStimuli()
    a = ['LRLRLR'];
    indices = randperm(length(a));  
    a = a(indices);
end

% generate a random letter from the alphabet
function stimulus = getRandomLetter()
    a = getStimuli();
    R = round(1+5*rand(1,1))
    stimulus = a(R);
end
