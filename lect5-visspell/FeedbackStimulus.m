%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Student		:	Tjalling Haije
% Student ID	: 	s1011759
% Course		:	BCI Practical
% Assignment	: 	Tutorial Feature? ?Attention? ?BCI - stimulus / calibration
% Date			: 	08-11-2017 
% Description   :   This file gives the stimulus and feedback during
%                   the BCI experiment. The user has to think of a letter
%                   in the alphabet, after which the user is shown each
%                   letter in the alphabet in a random order. Each loop
%                   events are send to the predictor, and predictions are
%                   received. After each sequence, the predicted letter is
%                   presented in blue on the screen to the user.       
%
%                   Some of the code has been written by Jason Farquhar
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
end

% set variables/parameters
global textObject;
global interEpochDuration;
global interLetterDuration;
global feedbackDuration;

interSeqDuration = 2;
interEpochDuration = 2;
interLetterDuration = 0.1;
feedbackDuration = 2;

startSeqAfter = 1;
userBrainstormingDuration = 2;
startEpochsAfter = 1;

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



sendEvent('stimulus.feedback','start');

% do the calibration runs and their repetitions
for i=1:sequences;
    state = [];
    % we keep all events in a list, because one call to buffer_newevents
    % does not return all predictions, so we call it multiple times
    d_events = [];
    [d_events, state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
    
    % wait for key press
    getKeypress();
    clearText();
    
    ev = sendEvent('stimulus.seq',i);
    sendEvent('stimulus.seq', 'start', ev.sample);
    
    sleepSec(startSeqAfter);
    
    % let the user think of a target letter
    set(textObject, 'fontsize', .08);
    updateText("Think of your target letter and get ready");
    sleepSec(userBrainstormingDuration);
    
    % clear the screen and get ready for the alphabet
    clearText();
    sleepSec(startEpochsAfter);

    % [letters x totalLetters] used record what letter showed when
    stimSeq=zeros(26,epochs*26); 
    
    % Do the epochs
    for j=1:epochs;
        sendEvent('stimulus.epoch',j);
        stimSeq = doEpoch(stimSeq, j-1); 
        
        % check for events and add them if we receive any
        [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
        if ( ~isempty(devents) )
            d_events = [d_events, devents];
        end
    end
        
    % clear the screen
    clearText();
    
    % Feedback code
    % check again for events
    [devents,state]=buffer_newevents(buffhost,buffport,state,'classifier.prediction',[],500);
    if ( ~isempty(devents) )
        d_events = [d_events, devents];
    end
        
    predictionLetter = '?';

    % combine the classifier predictions with the stimulus used
    if ( ~isempty(d_events) ) 
        % correlate the stimulus sequence with the classifier predictions to identify the most likely letter
        pred =[d_events.value]; % get all the classifier predictions in order
        nPred=numel(pred);
        nLetters = 26 * epochs;
        ss   = reshape(stimSeq(:,1:nLetters),[26 nLetters]);
        corr = ss(:,1:nPred)*pred(:);  % N.B. guard for missing predictions!
        [ans,predTgt] = max(corr); % predicted target is highest correlation

        % convert ascii to letter
        predictionLetter = char(predTgt + 64);
        
        % show prediction for certain period, and clear text afterwards
        sendEvent('stimulus.prediction', predictionLetter);
        displayFeedback(predictionLetter);
        clearText();
    end
   
    
    sendEvent('stimulus.seq','end', ev.sample);
    sleepSec(interSeqDuration);
end

sendEvent('stimulus.feedback', 'end');
updateText("Thank you"); 


function stimSeq = doEpoch(stimSeq, j)
    global interEpochDuration;
    
    % get a random shuffle of the alphabet
    alph = getShuffledAlphabet();
        
    sendEvent('stimulus.epoch','start');
    
    % loop through the letters in the alphabet
    for letter=1:numel(alph);
        % calc what number this letter has in this sequence
        nthLetter = (j * 26) + letter;
        
        % convert the letter to an index in the list
        letterCode = double(char(alph(letter))) - 64;
        
        % save the letter 
        stimSeq(letterCode, nthLetter) = true;
        
        % display the letter and send an event
        sendEvent('stimulus.letter', alph(letter));
        displayletter(alph(letter)); 
    end;
    
    % clear screen
    clearText();
    
    % send event and wait
    sendEvent('stimulus.epoch','end');
    sleepSec(interEpochDuration);
end

% update the text and do the corresponding actions
function x = displayletter(letter)
    global interLetterDuration;
    
    % show the letter on the screen
    updateText(letter);

    % Wait for next letter
    sleepSec(interLetterDuration);
end

% update the text and do the corresponding actions
function x = displayFeedback(letter)
    global feedbackDuration;
    global textObject;
    textObject.Color = 'blue';
    
    % show the letter on the screen
    updateText(letter);

    % Wait for next letter
    sleepSec(feedbackDuration);
end

% Empty the screen and reset default values
function x = clearText()
    global textObject;
    set(textObject, 'fontsize', .2);
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
    global textObject;
    set(textObject, 'fontsize', .1);
    updateText("Press to continue");
    w = 0;
    % w=0 is mouseclick, w=1 is keypress
    while( w == 0)
        w = waitforbuttonpress;
    end
    clearText();
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