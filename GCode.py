import math

posx = 0
posy = 0
CM_PER_SEGMENT = 10


def atan3(dy,dx):
    a = math.atan2(dy, dx)
    if(a < 0):
        a = (math.pi * 2.0) + a
    return a

def arc(cx,cy, x, y,direction) :
    #get radius
    dx = posx - cx
    dy = posy - cy
    radius = math.sqrt((dx*dx)+(dy*dy))

    #find the sweep of the arc
    angle1 = atan3(dy,dx)
    angle2 = atan3(y-cy,x-cx)
    sweep = angle2 - angle1

    if direction > 0 and sweep < 0:
        angle2 += 2 * math.pi
    elif direction < 0:
        angle1 += 2 * math.pi

    sweep = angle2 - angle1

    #get length of arc

    len = math.fabs(sweep) * radius

    i, num_segments = math.floor(len / CM_PER_SEGMENT)

    #declare variables outside of loops because compilers can be really dumb and inefficient some times.

    for i in range(num_segments):
        #interpolate around the arc
        fraction = float(i) / float(num_segments)
        angle3 = (sweep * fraction) + angle1

        #find the intermediate position
        nx = cx + math.cos(angle3) * radius
        ny = cy + math.sin(angle3) * radius
        #make a line to that intermediate position
        #line(nx,ny,posz)


    #line(x,y,posz)
