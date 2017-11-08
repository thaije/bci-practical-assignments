%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Student		:	Tjalling Haije
% Student ID	: 	s1011759
% Course		:	BCI Practical
% Assignment	: 	Tutorial Feature? ?Attention? ?BCI - stimulus / calibration
% Date			: 	21-10-2017 
% Description   :   This file does the stimulus generation and the 
%					calibration phase for the Feature Attention BCI (RSVP).
%					The uses is presented a random green letter from the 
%					alphabet. Afterwards all letters of the alphabet are
%					shown in a random order for a short time. 
%					The alphabet is shown a number of times. Afterwards
%					the user can take a break, press a letter, and repeat.
%
%                   In total 10 sequences runs * 50 epochs each = 50 repetitions. 
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

% set variables/parameters
global textObject;
global interRepetitionDuration;
global interLetterDuration;

interRunDuration = 2;
interRepetitionDuration = 2;
interLetterDuration = 0.1;

showCueAfter = 1;
showCueDuration = 2;
cueAlphabetPause = 1;

sequences = 10;
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



sendEvent('stimulus.training','start');

% do the calibration runs and their repetitions
for i=1:sequences;
    
    % wait for key press
    getKeypress();
    clearText();
    
    sendEvent('stimulus.seq',i);
    sendEvent('stimulus.seq', 'start');
    
    sleepSec(showCueAfter);
    
    % get a random letter and display it in green
    letter = getRandomLetter();
    sendEvent('stimulus.calibrationcue',letter);
    textObject.Color = 'green';
    updateText(letter);
    sleepSec(showCueDuration);
    
    % afterwards clear the screen and get ready for the alphabet
    clearText();
    sleepSec(cueAlphabetPause);
    
    % Do the repetitions
    for j=1:epochs;
        sendEvent('stimulus.epoch',j);
        doEpoch(letter); 
    end    
    
    % clear the screen
    clearText();
    sendEvent('stimulus.sequence','end');
    sleepSec(interRunDuration);
end

sendEvent('stimulus.training', 'end');
updateText("Thank you"); 


function x = doEpoch(cueLetter)
    global interRepetitionDuration;
    
    % get a random shuffle of the alphabet
    alph = getShuffledAlphabet();
        
    % Time for the subject to mentally prepare
    sleepSec(interRepetitionDuration);
    sendEvent('stimulus.epoch','start');
    
    sendEvent('stimulus.targetCue', cueLetter);
    
    % loop through the letters in the alphabet
    for letter=1:numel(alph);
        
        % display the letter
        ev = sendEvent('stimulus.letter', alph(letter));
        displayletter(alph(letter));      
        
        % send a special event if the letter is the target letter
        if(cueLetter == alph(letter))
            sendEvent('stimulus.target', '1', ev.sample);
        else
            sendEvent('stimulus.target', '0', ev.sample);
        end  
    end;
    
    % clear screen
    clearText();
    
    % send event and wait
    sendEvent('stimulus.epoch','end');
end

% update the text and do the corresponding actions
function x = displayletter(letter)
    global interLetterDuration;
    
    % show the letter on the screen
    updateText(letter);

    % Wait for next letter
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
    updateText("Press to continue");
    w = 0;
    % w=0 is mouseclick, w=1 is keypress
    while( w == 0)
        w = waitforbuttonpress;
    end
    sendEvent('stimulus.keypress','button');
end

% generate a random order for the letters
function alph = getShuffledAlphabet()
    a = ['A':'Z'];
    indices = randperm(length(a));  
    alph = a(indices);
end

% generate a random letter from the alphabet
function letter = getRandomLetter()
    alph = getShuffledAlphabet();
    R = round(1+25*rand(1,1));
    letter = alph(R);
end