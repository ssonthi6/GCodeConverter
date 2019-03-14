function [linesOut, err] = linearize(sx,sy,cx,cy,ex,ey,cw,f)
% Initialize error detector
err = false;
% Get start radius
    dx = sx - cx;
    dy = sy - cy;
    ang1 = atan3(dy,dx);
    sr = sqrt((dx)^2 + (dy)^2);
% Get end radius (Hopefully these match, but if not, it's not the end of 
% the world)
    dx = ex - cx;
    dy = ey - cy;
    ang2 = atan3(dy,dx);
    er = sqrt((dx)^2 + (dy)^2);
%Compare start and end radius with 1mm tolerance
diff = round(abs(sr - er));
if diff > 1
    err = err + 2;
end
% Find angle of arc (sweep)
    sweep = ang2 - ang1;
    if (~cw && sweep < 0) 
        ang2 = ang2 + 2*pi;
    elseif (cw && sweep > 0) 
        ang1 = ang1 + 2*PI;
    end
    sweep = ang2 - ang1;
    dr = er - sr;
    
  % get length of arc
  % float circ=PI*2.0*radius;
  % float len=theta*circ/(PI*2.0);
  % simplifies to:
    len1 = abs(sweep)*sr;
    len = sqrt((len1)^2 + (dr)^2);
    
    % get size of each segment
    % edit precision of the arc here
    segs = max([ceil(len/1.5),1]);
    
    %this variable will become a true if machine moves out of bounds
    bounds = 0;
    %Interpolate around arc with G1
    %prints to cell array linesOut
    linesOut = {};
    for step = 1:segs
        %portion of the arc it's at
        scale = (step)/(segs);
        %angle at this portion of the arc
        a = (sweep*scale) + ang1; 
        %distance from center accounting for error in start/end points
        r = (dr*scale) + sr;
        %gets new endpoint for linear movement
        nx = cx + (r*cos(a));
        nx = round(nx*1000)/1000;
        ny = cy + (r*sin(a));
        ny = round(ny*1000)/1000;
        linesOut(step,1) = {sprintf('G1 X%f Y%f F%f', nx,ny,f)};
        %If machine goes out of bounds, bounds becomes true
        if (nx < 0)||(nx > 1000)
            bounds = true;
        elseif (ny < 0)||(ny > 1000)
            bounds = true;
        end
    end
    %Update error code
    err = err + bounds;
end