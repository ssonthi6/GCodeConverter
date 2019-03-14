function out = codeConverter(codeIn)
%Open files to read and write
fh = fopen(codeIn);
line = fgetl(fh);


word = [codeIn(1:end-4) '_out.txt'];
fh1 = fopen(word, 'w');

%Initializes variables we'll be using in the loop later
x = 0;
ex = 0;
y = 0;
ey = 0;
z = 0;
i = 0;
f = 0;

%error variable to count errors in code
error = 0;
out = {};

%line counter to track line number on parent code
lineNum = 0;

%Puts header on gcode
fprintf(fh1,'G21\n');

%Loop through each line in the code to figure out what to do with it
while ischar(line)
    lineNum = lineNum + 1;
    [cmd, read] = strtok(line);
    
    %sets err test for linearize to be empty
    err = [];
    
    %reset arc radius components to empty
    i = [];
    j = [];
    %         r = [];
    
    %detects if valid gcode commands are input
    if ~(cmd(1)=='G') && ~(cmd(1)=='M')
        error = error + 1;
        out{error,1} = sprintf('NOTICE Line %d: INVALID G-code command',lineNum);
    
    %Use this elseif statement when not working with arcs
    elseif ~strcmp(cmd,'G2') && ~strcmp(cmd,'G3') && ~strcmp(cmd,'G02') && ~strcmp(cmd,'G03')
        fprintf(fh1,'%s\n',line);
        
        %Initialize variables that will test if parameters are met
        ifX = false;
        ifY = false;
        ifZ = false;
        ifF = false;
        ifS = false;
        
        %This part retrieves where the machine will move
        [code, read] = strtok(read);
        while ~isempty(code)
            switch code(1)
                case 'X'
                    x = str2double(code(2:end));
                    ifX = true;
                case 'Y'
                    y = str2double(code(2:end));
                    ifY = true;
                case 'Z'
                    z = str2double(code(2:end));
                    ifZ = true;
                case 'F'
                    f = str2double(code(2:end));
                    ifF = true;
                case 'S'
                    ifS = true;
                case 'G'  
                    error = error + 1;
                    out{error,1} = sprintf('Line %d: Multiple G-codes found per line',lineNum);
                    break
            end
            [code, read] = strtok(read);
        end
        
        %test if the command has all of its correct parameters and add
        %error message if conditions are not met
        if strcmp(cmd,'G0') || strcmp(cmd,'G00') || strcmp(cmd,'G1') || strcmp(cmd,'G01')
            if ~any([ifX,ifY,ifZ,ifF])
                error = error + 1;
                out{error,1} = sprintf('Line %d: Not enough command inputs',lineNum);
            end
        elseif strcmp(cmd,'G4') || strcmp(cmd,'G04')
            if ifS == false
                error = error + 1;
                out{error,1} = sprintf('Line %d: Not enough command inputs',lineNum);
            end
        end
        
    else
        %This part retrieves the end location and center of the arc
        [code, read] = strtok(read);
        
        %initialize commend test variables
        ifX = false;
        ifY = false;
        ifF = false;
        
        while ~isempty(code)
            switch code(1)
                case 'X'
                    ex = str2double(code(2:end));
                    ifX = true;
                case 'Y'
                    ey = str2double(code(2:end));
                    ifY = true;
                case 'I'
                    i = str2double(code(2:end));
                case 'J'
                    j = str2double(code(2:end));
                case 'F'
                    f = str2double(code(2:end));
                    ifF = true;
                    %case 'R'
                    %r = str2double(code(2:end));
                case 'G'
                    error = error + 1;
                    out{error,1} = sprintf('Line %d: Multiple G-codes found per line',lineNum);
                    break
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
        %This tests if all necessary inputs are received
        if ~isempty(i) && ~isempty(j) && all([ifX,ifY,ifF])
            [linesCA,err] = linearize(x,y,i,j,ex,ey,cw,f);
            
            %After arc is finished linearizing, put each line of cell array
            %into fileOut AND set the end x and y as the current location
            for w = 1:length(linesCA)
                fprintf(fh1,'%s\n',linesCA{w});
            end
            %prints corresponding error message to out according to codenum
            switch err
                case 1
                    error = error + 1;
                    out{error,1} = sprintf('Line %d: Machine out of bounds error',lineNum);
                case 2
                    error = error + 1;
                    out{error,1} = sprintf('NOTICE Line %d: Arc radius is inconsistent',lineNum);
                case 3
                    error = error + 1;
                    out{error,1} = sprintf('Line %d: Machine out of bounds error',lineNum);
                    error = error + 1;
                    out{error,1} = sprintf('NOTICE Line %d: Arc radius is inconsistent',lineNum);
            end
            
            %             elseif ~isempty(r) && all([ifX,ifY,ifF])
            %                 [linesCA,err] = linearizeR(x,y,r,ex,ey,cw,f);
            %
            %                 %After arc is finished linearizing, put each line of cell array
            %                 %into fileOut AND set the end x and y as the current location
            %                 for w = 1:length(linesCA)
            %                     fprintf(fh1,'%s\n',linesCA{w});
            %                 end
            %                 %prints corresponding error message to out according to codenum
            %                 switch err
            %                     case 1
            %                         error = error + 1;
            %                         out{error,1} = sprintf('Line %d: Machine out of bounds error',lineNum);
            %                 end
            
        else
            error = error + 1;
            out{error,1} = sprintf('Line %d: Not enough command inputs',lineNum);
        end
        %update coordinates of g-code
        x = ex;
        y = ey;
    end
    %
    % If endpoint x or y is greater than 1000mm or less than 0mm, ==>
    % 'machine out of bounds error'
    % only works if arc code has not run, or if it returned no errors
    if (isempty(err) || isequal(err,false))&&((x < 0) || (x > 1000))
        error = error + 1;
        out{error,1} = sprintf('Line %d: Machine out of bounds error',lineNum);
    elseif (isempty(err) || isequal(err,false))&&((y < 0) || (y > 1000))
        error = error + 1;
        out{error,1} = sprintf('Line %d: Machine out of bounds error',lineNum);
    elseif (isempty(err) || isequal(err,false))&&(z < 0) %|| (z > some maximum depth)
        error = error + 1;
        out{error,1} = sprintf('Line %d: Machine out of bounds error',lineNum);
    end
    
    %Get the next line and loop through while again
    line = fgetl(fh);
end

%print end code line
fprintf(fh1,'M30');
x
y
%print errors
%sprintf('%d errors found in the gcode:', error)
out = [{sprintf('%d errors found in the gcode:', error)}; out];

fclose(fh);
fclose(fh1);
end