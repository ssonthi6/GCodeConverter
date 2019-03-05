function [ang] = atan3(dy,dx)
    ang = atan2(dy,dx);
    if (ang < 0) 
        ang = (pi * 2) + ang;
    end
end