function [linesOut] = linearize(sx,sy,cx,cy,ex,ey,cw,f)
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
    segs = max([ceil(len/10),1]);
    
    %Interpolate around arc with G1
    %prints to cell array linesOut
    linesOut = '';
    for step = 1:(segs+1)
        %portion of the arc it's at
        scale = (step)/(segs);
        %angle at this portion of the arc
        a = (sweep*scale) + ang1; 
        %distance from center accounting for error in start/end points
        r = (dr*scale) + sr;
        %gets new endpoint for linear movement
        nx = cx + (r*cos(a));
        ny = cy + (r*sin(a));
        linesOut(step,1) = {sprintf('G1 X%d Y%d F%d', nx,ny,f)};
    end
end