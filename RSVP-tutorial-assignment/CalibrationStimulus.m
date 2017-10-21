%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Student		:	Tjalling Haije
% Student ID	: 	s1011759
% Course		:	BCI Practical
% Assignment	: 	Tutorial Feature? ?Attention? ?BCI - stimulus / calibration
% Date			: 	21-10-2017 
% Terminology	:	Run = calibration run (new cue)
%                   Repetition = showing alphabet in random order
% Description   :   This file does the stimulus generation and the 
%					calibration phase for the Feature? ?Attention? ?BCI? (RSVP).
%                   It works by presenting a random green letter from the 
%                   alphabet as cue to the test subject, shown for 2s.
%                   After clearing the screen for 1s, the alphabet is shown 
%                   in a random order with a duration of 100ms per letter. 
%                   Each cue is tested by showing the alphabet in random 
%                   order 5 times, with 2 seconds between repetitions. 
%                   Furthermore are 10 calibration runs done, each run 
%                   with a random letter from the alphabet as cue.
%                   Which makes for a total of 10 calibration runs * 
%                   5 repetitions = 50 repetitions. 
%                   Important to note is that this script requires user 
%                   input to run, giving the subject the ability 
%                   to take a break between calibration runs.
%                   Each new run (new cue), including the first one, only 
%                   starts after the user presses a key.
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

runs = 10;
repetitions = 5;

% initialize sleep function, otherwise sleepSec might throw errors
initsleepSec();


% make the stimulus, i.e. put a text box in the middle of the axes
clf;
set(gcf,'color',[0 0 0],'toolbar','none','menubar','none'); % black figure
set(gca,'visible','off','color',[0 0 0]); % black axes
textObject = text(.5,.5,'','HorizontalAlignment','center','VerticalAlignment','middle',...
       'FontUnits','normalized','fontsize',.2,'color','white','visible','on'); 
drawnow;



sendEvent('stimulus.seq','start');

% do the calibration runs and their repetitions
for i=1:runs;
    
    % wait for key press
    getKeypress();
    
    sendEvent('stimulus.run','start');
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
    for j=1:repetitions;
       doRepetition(); 
       % wait for button press to continue
       % getKeypress();
    end
    
    % clear the screen
    clearText();
    disp("End of run");
    sendEvent('stimulus.run','end');
    sleepSec(interRunDuration);
end

sendEvent('stimulus.seq','end');


function x = doRepetition()
    global interRepetitionDuration;
    
    % get a random shuffle of the alphabet
    alph = getShuffledAlphabet();
        
    % Time for the subject to mentally prepare
    disp("countdown to start of repetition")
    sleepSec(interRepetitionDuration);
    sendEvent('stimulus.alphabet','start');
    
    % loop through the letters in the alphabet
    for letter=1:numel(alph);
        displayletter(alph(letter));        
    end;
    
    % clear screen
    clearText();
    
    % send event and wait
    sendEvent('stimulus.alphabet','end');
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
    R = round(1+26*rand(1,1));
    letter = alph(R);
end