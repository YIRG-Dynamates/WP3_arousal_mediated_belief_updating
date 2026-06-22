function D = PrepareDrawing(S,P)
% Prepare to draw some things on the screen

% Find window center, width and height (in pixels index).     
[D.win_center_x,D.win_center_y] = RectCenter(P.win_rect);                 

% Set some distances in meters - hardcoded and not very nice, but Screen('DisplaySize',S.screen_number) gives the wrong dimensions!     
D.screen_width = 0.477;
D.screen_height = 0.268;
D.dist_to_screen = 0.75;                                                    %As recorded in ARI lab on 18-03-2022 - 75 cm away from screen seems a little far, but necessary for eyetracker

% Calculate the size of one pixel (in meters).
width_of_1pix = D.screen_width/P.win_rect(3);                    
height_of_1pix = D.screen_height/P.win_rect(4);                  

% Express the distance to the screen in number of pixels (separate for width and height) 
D.dist2Screen_inPixWidth = D.dist_to_screen/width_of_1pix;
D.dist2Screen_inPixHeight = D.dist_to_screen/height_of_1pix;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare AVsynchrony Rect %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if S.AVsynchrony_test 
    %Set up a rectangle in the centre of the screen that can flicker
    part_of_screen = 1/3;
    width_offset = round(part_of_screen*P.win_rect(3)/2);
    height_offset = round(part_of_screen*P.win_rect(4)/2);
    base_rect = [-width_offset -height_offset width_offset height_offset];   %[LTRB]
    D.AVsynchrony_rect = CenterRectOnPointd(base_rect,D.win_center_x,D.win_center_y);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare eyetracker Rect %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set the maximum rectangle within which the Eyelink can 'track' the eyes (for calibration)
el_max_width_degrees = 10;                                                                                  %This was experimentally defined to be a good setting for the calibration to work on 
el_max_height_degrees = 7;                                                                                  %This equals a rectangle of ~24 x ~17 cm when dist to screen is 70 cm.
nr_pixels_max_width = round(tand(el_max_width_degrees)*D.dist2Screen_inPixWidth);                           %Those distances have to be set on the eyetracker computer manually.
nr_pixels_max_height = round(tand(el_max_height_degrees)*D.dist2Screen_inPixHeight);                        %The resolution does not need setting as it is overwritten in the 'setup'
D.el_dispRect_raw = [-nr_pixels_max_width -nr_pixels_max_height nr_pixels_max_width nr_pixels_max_height];  %[L,T,R,B]
%Use as (we prefer the dispRect to be in structure "P" rather than "D"):
%P.el_dispRect = CenterRectOnPoint(D.el_dispRect_raw, D.win_center_x, D.win_center_y);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare fixation cross %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

D.fixx_LineWidth = 2;                                                       %in pixels (integers only) for the cursor line-width
fixx_radius_angle = 1;                                                      %in visual angle (in degrees)
fixxWidth_pix = tand(fixx_radius_angle)*D.dist2Screen_inPixWidth;           
fixxHeight_pix = tand(fixx_radius_angle)*D.dist2Screen_inPixHeight;
% Coords for DrawLines always in order: 1st row = x_coords, 2nd row = y_coords: 1st column pair is start_coord, 2nd column is stop_coord).     
D.fixx_Coords = [ [-fixxWidth_pix fixxWidth_pix; 0 0] [0 0; -fixxHeight_pix fixxHeight_pix] ];
% All coords are relative to some centre point (x,y). Use as:     
% Screen('DrawLines', P.win, D.fixx_Coords, D.fixx_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 2);  %(the last '2' is for high quality smoothing)    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare direction indicator %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

D.dirI_LineWidth = 4;                                                       %in pixels (integers only) for the cursor line-width
% Coords for DrawLines always in order: 1st row = x_coords, 2nd row = y_coords: 1st column pair is start_coord, 2nd column is stop_coord).     
D.dirI_Coords = [-fixxWidth_pix 0; 0 0];
% All coords are relative to some centre point (x,y). Use as:     
% Screen('DrawLines', P.win, D.dirI_Coords, D.dirI_LineWidth, P.draw_color, [D.win_center_x,D.win_center_y], 2);  %(the last '2' is for high quality smoothing)  

dirI_radius_angle = 0.5;
dirIWidth_pix = tand(dirI_radius_angle)*D.dist2Screen_inPixWidth;                       %half the size in pixels
dirIHeight_pix = tand(dirI_radius_angle)*D.dist2Screen_inPixHeight;
dirI_width_pix = cosd(60)*dirIWidth_pix;
dirI_height_pix = sind(60)*dirIHeight_pix;
% “pointList” is a matrix: each row specifies the (x,y) coordinates of a vertex.
D.dirI_pointList = [-dirIWidth_pix, 0; dirI_width_pix, -dirI_height_pix; dirI_width_pix, dirI_height_pix];

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare mini cursor %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

D.miniCursor_LineWidth = 2;                                                                         %in pixels (integers only) for the cursor line-width
miniCursor_radius_angle = 0.5;                                                                      %in visual angle (degrees)
miniCursorWidth_pix = tand(miniCursor_radius_angle)*D.dist2Screen_inPixWidth;                       %half the size in pixels
miniCursorHeight_pix = tand(miniCursor_radius_angle)*D.dist2Screen_inPixHeight;
% Coords for DrawLines always in order: 1st row = x_coords, 2nd row = y_coords: 1st column pair is start_coord, 2nd column is stop_coord).     
D.miniCursor_Coords = [ [-miniCursorWidth_pix miniCursorWidth_pix; 0 0] [0 0; -miniCursorHeight_pix miniCursorHeight_pix] ];
% Screen('DrawLines', P.win, D.miniCursor_Coords, D.miniCursor_LineWidth, P.draw_color, [mX,mY]);   %Don't use smoothing on moving cursor, it looks ugly.      

%%%%%%%%%%%%%%%%%%%%%%%%%%%             
%%% Prepare startButton %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

D.startButton_LineWidth = 2;                                                %in pixels (integers only) for the cursor line-width
D.startButton_Radius = 2;                                                   %horizontal and vertical visual angles
startButtonWidth_pix = tand(D.startButton_Radius)*D.dist2Screen_inPixWidth;              
startButtonHeight_pix = tand(D.startButton_Radius)*D.dist2Screen_inPixHeight;   
% Coords for FrameOval always in order [Left, Top, Right, Bottom]
D.startButton_Coords = [D.win_center_x-startButtonWidth_pix; D.win_center_y-startButtonHeight_pix; D.win_center_x+startButtonWidth_pix; D.win_center_y+startButtonHeight_pix];               
% Use as: Screen('FrameOval', P.win, P.draw_color, D.startButton_Coords, D.startButton_LineWidth);

%%%%%%%%%%%%%%%%%%%%%%
%%% Text positions %%%
%%%%%%%%%%%%%%%%%%%%%%

D.aboveStartButton = D.win_center_y-startButtonHeight_pix*3;
D.belowStartButton = D.win_center_y+startButtonHeight_pix*3;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare mini-break bar %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

D.breakBar_LineWidth = 2;                                                           %in pixels
breakBar_height = 1;                                                                %in degrees
breakBar_width = 8;                                                                 %in degrees
breakBar_height_pix = tand(breakBar_height)*D.dist2Screen_inPixHeight;              %in pixels
breakBar_width_pix = tand(breakBar_width)*D.dist2Screen_inPixWidth;                 %in pixels
xLoc_L = D.win_center_x-round(breakBar_width_pix/2);
xLoc_R = D.win_center_x+round(breakBar_width_pix/2);
yLoc_T = D.win_center_y-round(breakBar_height_pix/2);
yLoc_B = D.win_center_y+round(breakBar_height_pix/2);
D.breakBar_Coords = [xLoc_L, yLoc_T, xLoc_R, yLoc_B];                               %[L,T,R,B]
% Use as:
% Screen('FrameRect', P.win, P.draw_color, D.breakBar_Coords, D.breakBar_LineWidth);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Prepare answerButtons (aB) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

D.answerButton_LineWidth = 2;
D.aB_radius = 8;                                                            %radius of the outer boundary of the answerButtons (middle boundaries are given by the startButton) in degrees
aBHor_pix = tand(D.aB_radius)*D.dist2Screen_inPixWidth;                     %in pixels (from the centre)
aBVer_pix = tand(D.aB_radius)*D.dist2Screen_inPixHeight;     
D.aBcoords = [D.win_center_x-aBHor_pix; D.win_center_y-aBVer_pix; D.win_center_x+aBHor_pix; D.win_center_y+aBVer_pix];

% based on the above aBcoords (of the full circle) we define which arcs we will show (in angles starting at the middle-top, going clockwise)     
% use as: Screen('FrameArc',P.win,P.draw_color,positionOfMainCircle,startAngle,sizeAngle,penWidth);         %with angles in degrees --> or use 'FillArc'      

D.aB_full_angleSize = 72;                                                   %circular size in degrees (full circle = 360°) of one full answerButton (L, R or Bottom)
D.aB_part_angleSize = D.aB_full_angleSize/4;

aB_part_angles = [D.aB_part_angleSize*2, D.aB_part_angleSize, 0, -D.aB_part_angleSize, -D.aB_part_angleSize*2];
D.aB_part_angles_R = 90 + aB_part_angles;                                                                         %#1 is lowest on screen, #5 is highest on screen
D.aB_part_angles_L = 270 - aB_part_angles;                                                                        %#1 is lowest on screen, #5 is highest on screen
D.aB_full_angles_R = D.aB_part_angles_R([1 5]);
D.aB_full_angles_L = D.aB_part_angles_L([1 5]);

% for each of the part_angles we need to know the intersection points with the inner and outer circles, such that we can draw lines (dividing the space into 4 options - confidence values.
aB_innerHeights_angles = sind(aB_part_angles)*D.startButton_Radius;
aB_innerHeights_pixels_R = D.win_center_y + tand(aB_innerHeights_angles)*D.dist2Screen_inPixHeight;
aB_innerHeights_pixels_L = D.win_center_y - tand(aB_innerHeights_angles)*D.dist2Screen_inPixHeight;

aB_innerWidths_angles = cosd(aB_part_angles)*D.startButton_Radius;
aB_innerWidths_pixels_R = D.win_center_x + tand(aB_innerWidths_angles)*D.dist2Screen_inPixWidth;
aB_innerWidths_pixels_L = D.win_center_x - tand(aB_innerWidths_angles)*D.dist2Screen_inPixWidth;

aB_outerHeights_angles = sind(aB_part_angles)*D.aB_radius;
aB_outerHeights_pixels_R = D.win_center_y + tand(aB_outerHeights_angles)*D.dist2Screen_inPixHeight;
aB_outerHeights_pixels_L = D.win_center_y - tand(aB_outerHeights_angles)*D.dist2Screen_inPixHeight;

aB_outerWidths_angles = cosd(aB_part_angles)*D.aB_radius;
aB_outerWidths_pixels_R = D.win_center_x + tand(aB_outerWidths_angles)*D.dist2Screen_inPixWidth;
aB_outerWidths_pixels_L = D.win_center_x - tand(aB_outerWidths_angles)*D.dist2Screen_inPixWidth;    

% first row is x coordinates, second row is y coordinates.
% two consecutive columns form a pair of (x,y) coordinates (start, end).
% use as: Screen('DrawLines', P.win, line_coords, penWidth, P.grey);
D.aB_line_coords_R_parts = [];
D.aB_line_coords_L_parts = [];
D.aB_line_coords_R_full = [];
D.aB_line_coords_L_full = [];
for i=1:5
    line_R_start = [aB_innerWidths_pixels_R(i); aB_innerHeights_pixels_R(i)];
    line_R_end   = [aB_outerWidths_pixels_R(i); aB_outerHeights_pixels_R(i)];
    D.aB_line_coords_R_parts = [D.aB_line_coords_R_parts line_R_start line_R_end];

    line_L_start = [aB_innerWidths_pixels_L(i); aB_innerHeights_pixels_L(i)];
    line_L_end   = [aB_outerWidths_pixels_L(i); aB_outerHeights_pixels_L(i)];
    D.aB_line_coords_L_parts = [D.aB_line_coords_L_parts line_L_start line_L_end];

    if i == 1 || i == 5
        D.aB_line_coords_R_full = [D.aB_line_coords_R_full line_R_start line_R_end];
        D.aB_line_coords_L_full = [D.aB_line_coords_L_full line_L_start line_L_end];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% confidence scale (double arrow lines) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

aB_scale_angle = D.aB_radius*1.5;
aB_scale_Horpix = tand(aB_scale_angle)*D.dist2Screen_inPixWidth;          
aB_scale_highest_point = aB_outerHeights_pixels_L(1);
aB_scale_lowest_point = aB_outerHeights_pixels_L(5);
aB_scale_size_arrow = (aB_scale_lowest_point - aB_scale_highest_point)*(1/8);

aB_scale_X1 = aB_scale_Horpix - aB_scale_size_arrow;
aB_scale_X2 = aB_scale_Horpix;
aB_scale_X3 = aB_scale_Horpix + aB_scale_size_arrow;
aB_scale_X_coords = [aB_scale_X2, aB_scale_X2, aB_scale_X1, aB_scale_X2, aB_scale_X2, aB_scale_X3, aB_scale_X1, aB_scale_X2, aB_scale_X2, aB_scale_X3];
aB_scale_X_coords_R = D.win_center_x + aB_scale_X_coords;
aB_scale_X_coords_L = D.win_center_x - aB_scale_X_coords;

aB_scale_Y1 = aB_scale_lowest_point;
aB_scale_Y2 = aB_scale_lowest_point-aB_scale_size_arrow;
aB_scale_Y3 = aB_scale_highest_point+aB_scale_size_arrow;
aB_scale_Y4 = aB_scale_highest_point;
aB_scale_Y_coords = [aB_scale_Y4, aB_scale_Y1, aB_scale_Y2, aB_scale_Y1, aB_scale_Y1, aB_scale_Y2, aB_scale_Y3, aB_scale_Y4, aB_scale_Y4, aB_scale_Y3];

D.aB_scale_lines_coords_R = [aB_scale_X_coords_R; aB_scale_Y_coords];
D.aB_scale_lines_coords_L = [aB_scale_X_coords_L; aB_scale_Y_coords];

% Scale text positions (uncertain <-> certain)
D.aB_scale_text_Xright = max(D.aB_scale_lines_coords_R(1,:));
D.aB_scale_text_Xleft = min(D.aB_scale_lines_coords_L(1,:));

D.aB_scale_text_Ytop = min(D.aB_scale_lines_coords_R(2,:));
D.aB_scale_text_Ybottom = max(D.aB_scale_lines_coords_R(2,:));

diffBottomTop = D.aB_scale_text_Ybottom - D.aB_scale_text_Ytop;
D.aB_scale_text_Ytop2 = D.aB_scale_text_Ytop + diffBottomTop*(1/3);
D.aB_scale_text_Ybottom2 = D.aB_scale_text_Ytop + diffBottomTop*(2/3);

%%%%%%%%%%%%%%%%%%%%%%%
%%% Rotation arrows %%%
%%%%%%%%%%%%%%%%%%%%%%%

D.rotationArrows_LineWidth = 7; % max for some graphics hardware
D.rotationArrows_radius = 2;                                                
raHor_pix = tand(D.rotationArrows_radius)*D.dist2Screen_inPixWidth;                     %in pixels (from the centre)
raVer_pix = tand(D.rotationArrows_radius)*D.dist2Screen_inPixHeight;     
D.rotationArrows_coords = [D.win_center_x-raHor_pix; D.win_center_y-raVer_pix; D.win_center_x+raHor_pix; D.win_center_y+raVer_pix];

%we define which arcs we will show (in angles starting at the middle-top, going clockwise)   
D.rotationArrows_angleStart_L1 = 270;   D.rotationArrows_angleSize_L1 = 75;
D.rotationArrows_angleStart_L2 = 0;     D.rotationArrows_angleSize_L2 = 90;
D.rotationArrows_angleStart_R1 = 270;   D.rotationArrows_angleSize_R1 = 90;
D.rotationArrows_angleStart_R2 = 15;    D.rotationArrows_angleSize_R2 = 75;
% use as: Screen('FrameArc',P.win,P.draw_color,D.rotationArrows_coords,D.rotationArrows_angleStart_L1,D.rotationArrows_angleSize,D.rotationArrows_LineWidth);         %with angles in degrees --> or use 'FillArc'  

%Add the arrow pointers
arrow_pointer_angleSize = D.rotationArrows_radius/3;
apHor_pix = tand(arrow_pointer_angleSize)*D.dist2Screen_inPixWidth;                     
apVer_pix = tand(arrow_pointer_angleSize)*D.dist2Screen_inPixHeight;

%first row is x coordinates, second row is y coordinates. Two consecutive columns form a pair of (x,y) coordinates (start, end).
startCoord_L1 = [D.rotationArrows_coords(1); D.win_center_y];
startCoord_L2R1 = [D.win_center_x; D.rotationArrows_coords(2)];
startCoord_R2 = [D.rotationArrows_coords(3); D.win_center_y];

D.rotationArrows_pointerCoords_L1 = startCoord_L1+[[0;0],[-apHor_pix; -apVer_pix],[0;0],[+apHor_pix; -apVer_pix]] + [1 1 1 1; 0 0 0 0] * 0.5*D.rotationArrows_LineWidth;
D.rotationArrows_pointerCoords_L2 = startCoord_L2R1+[[0;0],[+apHor_pix; -apVer_pix],[0;0],[+apHor_pix; +apVer_pix]] + [0 0 0 0; 1 1 1 1] * 0.5*D.rotationArrows_LineWidth;
D.rotationArrows_pointerCoords_R1 = startCoord_L2R1+[[0;0],[-apHor_pix; -apVer_pix],[0;0],[-apHor_pix; +apVer_pix]] + [0 0 0 0; 1 1 1 1] * 0.5*D.rotationArrows_LineWidth;
D.rotationArrows_pointerCoords_R2 = startCoord_R2+[[0;0],[-apHor_pix; -apVer_pix],[0;0],[+apHor_pix; -apVer_pix]] - [1 1 1 1; 0 0 0 0] * 0.5*D.rotationArrows_LineWidth;
% use as: Screen('DrawLines', P.win, D.rotationArrows_pointerCoords_L1, D.rotationArrows_LineWidth, P.draw_color);

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Confidence boxes %%%
%%%%%%%%%%%%%%%%%%%%%%%%

D.confBox_lineWidth = 1;
D.confText = {'very certain','somewhat certain','somewhat uncertain','very uncertain'};
maxHor = 0;
maxVer = 0;
for i=1:4
    D.boundsConfText{i} = Screen(P.win, 'TextBounds', D.confText{i});   %[L,T,R,B] from [0,0]
    maxHor = max(maxHor,D.boundsConfText{i}(3));
    maxVer = max(maxVer,D.boundsConfText{i}(4));
end
halfHor = round(.5*(maxHor + .2*maxHor));
halfVer = round(.5*(maxVer + .5*maxVer));
confBox_default = [-halfHor, -halfVer, halfHor, halfVer];
D.confBox_1 = confBox_default + [D.win_center_x, D.win_center_y + startButtonHeight_pix + 0.0*halfVer, D.win_center_x, D.win_center_y + startButtonHeight_pix + 0.0*halfVer]; 
D.confBox_2 = confBox_default + [D.win_center_x, D.win_center_y + startButtonHeight_pix + 2.5*halfVer, D.win_center_x, D.win_center_y + startButtonHeight_pix + 2.5*halfVer]; 
D.confBox_3 = confBox_default + [D.win_center_x, D.win_center_y + startButtonHeight_pix + 5.0*halfVer, D.win_center_x, D.win_center_y + startButtonHeight_pix + 5.0*halfVer]; 
D.confBox_4 = confBox_default + [D.win_center_x, D.win_center_y + startButtonHeight_pix + 7.5*halfVer, D.win_center_x, D.win_center_y + startButtonHeight_pix + 7.5*halfVer]; 
% use as: Screen('FrameRect', P.win,  P.draw_color,  D.confBox_1, D.confBox_lineWidth);

%%%%%%%%%%%%%%%%%%%%%%%
%%% Feedback circle %%%
%%%%%%%%%%%%%%%%%%%%%%%

D.feedbackButton_LineWidth = 1;                                             %in pixels (integers only) for the cursor line-width
D.feedbackButton_Radius = D.startButton_Radius/3;                                     
feedbackButtonWidth_pix = tand(D.feedbackButton_Radius)*D.dist2Screen_inPixWidth;              
feedbackButtonHeight_pix = tand(D.feedbackButton_Radius)*D.dist2Screen_inPixHeight;   
% Coords for FrameOval always in order [Left, Top, Right, Bottom]
D.feedbackButton_Coords = [D.win_center_x-feedbackButtonWidth_pix; D.win_center_y-feedbackButtonHeight_pix; D.win_center_x+feedbackButtonWidth_pix; D.win_center_y+feedbackButtonHeight_pix];               
% Use as: Screen('FillOval', P.win, P.draw_color, D.feedbackButton_Coords);
% Use as: Screen('FrameOval', P.win, P.draw_color, D.feedbackButton_Coords, D.startButton_LineWidth);

end %[EOF]
