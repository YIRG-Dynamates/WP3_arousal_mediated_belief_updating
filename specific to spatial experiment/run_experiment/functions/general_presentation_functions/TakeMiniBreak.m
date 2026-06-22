function keyCode = TakeMiniBreak(S,P,D)

S.timing.breakLength = 20;

%Initialize output argument
keyCode = zeros(1,256);

%Compute the percentage of the task that was done already
percDone = ceil(((P.trial_counter-1)/S.nTrials)*100);                           %in terms of number of trials reached

%Initialize text
textAbove = [num2str(S.timing.breakLength) ' sec minibreak: ' num2str(percDone) '% done.'];
textBelow = GiveMeAQuote;
boundsTextAbove = Screen(P.win,'TextBounds',textAbove);
boundsTextBelow = Screen(P.win,'TextBounds',textBelow);
coordsXYAboveText = [D.win_center_x-round(boundsTextAbove(3)/2), D.aboveStartButton-round(boundsTextAbove(4)/2)];
coordsXYBelowText = [D.win_center_x-round(boundsTextBelow(3)/2), D.belowStartButton-round(boundsTextBelow(4)/2)];

%Set start time
startTime = GetSecs;
if S.timing.breakLength > 0
    timeExceededBool = 0;
else
    timeExceededBool = 1;
end

%Width of bar in pixels
widthOfBarInPix = D.breakBar_Coords(3)-D.breakBar_Coords(1);

%Start while loop
EscapePressedBool = 0;
while ~timeExceededBool && ~EscapePressedBool

    %Get current time
    Currenttime = GetSecs;
    if (Currenttime-startTime) <= S.timing.breakLength
        timeFraction = (Currenttime-startTime) / S.timing.breakLength;
    else
        timeExceededBool = 1;       %Break from while loop
    end

    %Draw empty bar
    Screen('FrameRect', P.win, P.draw_color, D.breakBar_Coords, D.breakBar_LineWidth);

    %Draw filled part
    rightEdge = D.breakBar_Coords(1)+round(timeFraction*widthOfBarInPix);
    fillCoords = [D.breakBar_Coords(1), D.breakBar_Coords(2), rightEdge, D.breakBar_Coords(4)];  %[L,T,R,B]
    Screen('FillRect', P.win, P.draw_color, fillCoords);

    %Draw text
    DrawFormattedText(P.win, textAbove, coordsXYAboveText(1), coordsXYAboveText(2), P.draw_color);
    DrawFormattedText(P.win, textBelow, coordsXYBelowText(1), coordsXYBelowText(2), P.draw_color);

    %Flip the Screen
    Screen('DrawingFinished', P.win);
    Screen('Flip', P.win);

    % Escape pressed?
    [pressed, ~, keyCode, ~] = KbCheck;
    if pressed && keyCode(P.quitKey)
        EscapePressedBool = 1;      %Break from while loop
    end    
end %end of while loop

end %[EOF]

%Subfunction that chooses one motivational quote at random
function quote = GiveMeAQuote()
    
    MotivationalQuotes = {'You are doing great';
                          'Keep up the good work';
                          'Do not give up';
                          'Your struggles develop your strengths';
                          'Learn from failure and keep moving forward';
                          'When in doubt, throw doubt out and have a little faith';
                          'Keep calm and locate those stimuli';
                          'You can do it';
                          'Give rest to the problems weighing you down';
                          'Greatness is upon you. You must believe it though';
                          'If you fail, keep trying';
                          'Smile, keep your head up, and stay positive';
                          'You will get through this';
                          'Never give up hope';
                          'One day you will look back at this and smile';
                          'Do not underestimate yourself';
                          'There is no shortcut for hard work';
                          'Life is like a manga. You need to keep going';
                          'Slow progress is better than no progress';
                          'Repetition rings a bell';
                          'When the vision is clear, the results will appear';
                          'You have traveled too far to quit';
                          'If you are feeling low, unappreciated, or forgotten... that is an illusion';
                          'Great struggles make for great stories';
                          'Motivation brings productivity';
                          'If you are going through hell, keep walking until you reach heaven';
                          'When people underestimate you is when you can make a breakthrough';
                          'Remember to look at that cross in the middle of the screen';
                          'Sit still and relax';
                          'Science is fun';
                          'You may fall many times, but you must keep going';
                          'Lilies bloom in ugly waters; you too can blossom in ugly situations';
                          'Soon you may realize just how close you are to winning';
                          'Hard work works harder than luck';
                          'We get brave, we move, we believe, we keep going';
                          'You are likely to fall when you stop pedalling your bicycle';
                          'Feel the satisfaction of every button pressed';
                          'Work with the process, not against it';
                          'You will find the way and reach the destination';
                          'Resistance is futile';
                          'You are valued...and what lies ahead...is brilliance';
                          'There are tomorrows on their way worth the struggles of today';
                          'You will never know how much you can accomplish until you try';
                          'Yesterday you said tomorrow; make today count';
                          'Dont want success, Deserve it';
                          'You may ask the experimenter for a hug if you need one...';
                          'It is absolutely essential to hang in there';
                          'This may be a moment to never forget';
                          'Stop now and always wonder. Press forward and tap the wonder';
                          'Great people face whatever comes their way';
                          'A new challenge keeps the brain kicking and the heart ticking';
                          'We must stay strong so we can keep going';
                          'Thank you so much for doing this';
                          'Enjoy the moment, life is sweet';
                          'Only a few more stimuli';
                          'It is moments like these that define who is awesome';
                          'Do no watch the clock. Do what it does. Keep going';
                          'Never let anyone bring you down';
                          'Life is all about determination';
                          'Psychology experiments equal mental sports with winners only';
                          'Sharks cannot swim backwards. Keep going forward';
                          'Psychological research leads to a better society';
                          'You are getting extremely good at this task';
                          'Do not lose your heart';
                          'Rivers know this: there is no hurry';
                          'The man who moves a mountain begins by carrying away small stones';
                          'It always seems impossible until it is done';
                          'Sometimes even to live is an act of courage';
                          'It is not enough that we do our best; sometimes we must do what is required';
                          'So comes snow after fire, and even dragons have their endings';
                          'Never yield to the apparently overwhelming might of the enemy';
                          'Storms make people stronger and they never last forever';
                          'You never know what is around the corner. It could be everything...';
                          'Let me not beg for the stilling of my pain, but for the heart to conquer it';
                          'When things go wrong, do not go with them';
                          'Every strike brings one closer to the next home run';
                          'Dripping water hollows out stone, not through force but through persistence';
                          'Your watch has not yet ended';
                          'Hardships make or break people';
                          'It is not how we fall. It is how we get back up again';
                          'Win or lose, I admire those who fight the good fight';
                          'Once you learn to quit, it becomes a habit';
                          'Continuous effort is the key to unlocking our potential';
                          'Persistence. Perfection. Patience. Power';
                          'The stronger you climb, the higher your pedestal';
                          'By perseverance the snail reached the ark';
                          'This is exactly why you went to university';
                          'Every step may be fruitful if you can see its purpose';
                          'Even in the mud and scum of things, something always, always sings';
                          'If we walk far enough, we shall sometime come to someplace';
                          'Pain is temporary. To quit lasts forever';
                          'What is written without effort, is read without pleasure';
                          'You are helping science move forward';
                          'This task is easy. Enjoy the easy tasks in life';
                          'Excellence is a habit';
                          'Oh what a wonderful soul so bright inside you';
                          'A few fly bites cannot stop a spirited horse';
                          'The man who is swimming against the stream knows the strength of it';
                          'Nothing great is ever achieved without much enduring';
                          'Do not blame the researcher';
                          'Hard work is always credited';
                          };
    
    nQuotes = length(MotivationalQuotes);
    quote = MotivationalQuotes{randi(nQuotes,1),1};
end %end of subfunction 'GiveMeAQuote'

%[EOF]