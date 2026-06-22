function P = SetupKeyboard(P)
% Setup the keyboard for PTB

% KbName('UnifyKeyNames');  %Already done in RunScript.m with "PsychDefaultSetup(2);"

% Define keys for input

%P.quitKey   = KbName('ESCAPE');                                            % To exit the program
P.quitKey   = KbName('q');                                                  % To exit the program

P.upKey = KbName('UpArrow');
P.downKey = KbName('DownArrow');


P.Conf1key = KbName('\\');      %'^°' on German keyboards???
P.Conf2key = KbName('tab');
P.Conf3key = KbName('CapsLock');
P.Conf4key = KbName('LeftShift');
P.Conf1key_alt = KbName('`~');  %Alternative on non-German keyboards
P.responseKeys = [P.quitKey,P.upKey,P.downKey,P.Conf1key,P.Conf1key_alt,P.Conf2key,P.Conf3key,P.Conf4key];


end %[EOF]
