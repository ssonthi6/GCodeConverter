function codeConverter(codeIn)
%Open files to read and write
    fh = fopen(codeIn);
    line = fgetl(fh);
    
    word = strtok(codeIn,'.');
    word = [word '_out.txt'];
    fh1 = fopen(word, 'w');
    
    %Initializes variables we'll be using in the loop later
    x = 0;
    ex = 0;
    y = 0;
    ey = 0;
    z = 0;
    i = 0;
    j = 0;
    f = 0;
    
    %Puts header on gcode
    fprintf(fh1,'$X\n$H\nG92 X0 Y0 Z0\nG21\nG90\n');
    
    %Loop through each line in the code to figure out what to do with it
    while ischar(line)
        [cmd, read] = strtok(line);
        if ~strcmp(cmd,'G2') && ~strcmp(cmd,'G3') && ~strcmp(cmd,'G02') && ~strcmp(cmd,'G03')
            fprintf(fh1,'%s\n',line);
            
            %This part retrieves where the machine will move
            [code, read] = strtok(read);
            while ~isempty(code)
                switch code(1)
                    case 'X'
                        x = str2num(code(2:end));
                    case 'Y'
                        y = str2num(code(2:end));
                    case 'Z'
                        z = str2num(code(2:end));
                    case 'F'
                        f = str2num(code(2:end));
                end
                [code, read] = strtok(read);
            end
            
        else
            
            %This part retrieves the end location and center of the arc
            [code, read] = strtok(read);
            while ~isempty(code)
                switch code(1)
                    case 'X'
                        ex = str2num(code(2:end));
                    case 'Y'
                        ey = str2num(code(2:end));
                    case 'Z'
                        z = str2num(code(2:end));
                    case 'I'
                        i = str2num(code(2:end));
                    case 'J'
                        j = str2num(code(2:end));
                    case 'F'
                        f = str2num(code(2:end));
                end
                [code, read] = strtok(read);
            end
            
            %Find if it's clockwise or not
            switch cmd
                case 'G2'
                    cw = true;
                case 'G02'
                    cw = true;
                case 'G3'
                    cw = false;
                case 'G03'
                    cw = false;
            end
            
            %After arc is finished linearizing, put each line of cell array
            %into fileOut AND set the end x and y as the current location
            linesCA = linearize(x,y,i,j,ex,ey,cw,f);
            for w = 1:length(linesCA)
                fprintf(fh1,'%s\n',linesCA{w});
            end
            x = ex;
            y = ey;
        end
        
        %Get the next line and loop through while again
        line = fgetl(fh);
    end
    %end code and close the files
    fprintf(fh1,'M30');
    x
    y
    
    fclose(fh);
    fclose(fh1);
end