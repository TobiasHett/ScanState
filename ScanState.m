%This script shows the current state of the scan on ELEXSYS EPR spectrometers.
%It requires the eprload.m and eprload.p in the same folder as this script.
%Please note that you have to properly set the paths to the AUTOSAVE-files on the spectrometer for the script to work.
%Further information can be found in the user's manual.

function Scanstate_master
clc, clear, close all
% **********************************Parameters to be set***************************************
% General settings.
pathName = 'Z:\xeprFiles\Acquisition\';                                           % Path of Acquisition Folder on ELEXSYS. If needed, change first letter 'Z' according to your settings.

Updatefrq=60;                                                                     % How many seconds to wait between two updates?
m=8;                                                                              % Number of Tau averaging steps.
opengl hardwarebasic;

% Save settings.
DestinationPath='D:\MySavedEPRData\';                                             % Where to save the data?
Savemode=1;                                                                       % Savemode: 0=no files will be stored; 1=only the last file of each scan will be stored; 2=every slice will be stored.
Figsave=1;                                                                        % Figsave: 0=no figure generated; 1=figure generated with savemode setting is stored. 2=figure generated with savemode but without the textbox setting is stored.
datsave=0;                                                                        % datsave: 1=Data will be stored as .dat-file.
% **********************************Parameters to be set***************************************

% Main program.
while true
clearvars -except pathName Updatefrq m i Savemode DestinationPath Figsave datsave
fileName = 'AUTOSAVE0000.DTA';                                                   % Filename of Autosave File on ELEXSYS.
filePath = strcat(pathName,fileName);

FileInfo = dir(strcat(pathName,'AUTOSAVE0000.DTA'));                             % Info of Autosave File.
FileInfo2 = dir(strcat(pathName,'AUTOPARSAVE.DTA'));                             % Info of Start-Parameter File.

[x, y, Pars] = eprload(filePath);                                                % Read .DTA file.    
 
%Get information on the experiment to calculate runtimes etc.
    c=Pars.NbScansToDo-Pars.NbScansDone;
    
% Get and convert phase cycling procedure from PulseSPEL Program.
    if isempty(Pars.PlsSPELLISTSlct)                                             % If no phase cycling is specified, set pc=1.
        pc=1;
    else
        pc=strcat('"', Pars.PlsSPELLISTSlct,'"');                                    % Generate the name of the PC, e.g. "2-Step"
        pos=strfind(Pars.PlsSPELPrgTxt,pc);                                          % Find the position of the name in the PulseSPEL program text
        tmp=regexp(Pars.PlsSPELPrgTxt(pos:end),'end','once');                        % Go to "end" of list which starts at pos+tmp-1:
        %of interest for analysis is region pos:pos+tmp-1
        tmp2=regexp(Pars.PlsSPELPrgTxt(pos:pos+tmp-1),'asg1','once');                % This is where asg starts in the text
        tmp3=regexp(Pars.PlsSPELPrgTxt(pos:pos+tmp-1),'bsg1','once');                % This is where bsg starts in the text
        tmp4=Pars.PlsSPELPrgTxt(pos+tmp2+3:pos+tmp3-4);                              % This is the string of interest (everything between asg and bsg)
        tmp4=strtrim(tmp4);                                                          % Trim leading and trailing whitespace
        tmp4=split(tmp4);                                                            % Split into parts at whitespaces
        pc=numel(tmp4);                                                              % Count the parts
        clearvars tmp tmp2 tmp3 tmp4
    end
    
% Get and convert shot repetition time.    
    srt=Pars.ShotRepTime;                                                       
    srt=regexp(srt,' us');
    srt=Pars.ShotRepTime(1:srt-1);

% Compute duration, remaining time, endtime and runtime of the experiment.
    if iscell(x)  
        Time=Pars.XPTS*Pars.ShotsPLoop*m*pc*Pars.NbScansToDo*str2num(srt)*numel(x{1,2})/(1000*1000*60*60); % Total duration in hours for 2D-experiment.
    else
        Time=Pars.XPTS*Pars.ShotsPLoop*m*pc*Pars.NbScansToDo*str2num(srt)/(1000*1000*60*60);  % Total duration in hours for 1D-experiment.
    end

    Duration=datenum(Time/24)+FileInfo2.datenum;                                          % Endtime in datenum-format.
    Endtime=datetime(Duration,'ConvertFrom','datenum');                                   % Endtime in datetime-format.
    Runtime=datetime(FileInfo.datenum,'Convertfrom','datenum')-datetime(FileInfo2.datenum,'Convertfrom','datenum'); % Current runtime.

% Display info in command window.
    disp(['Scans Done: ', num2str(Pars.NbScansDone)])                                           
    disp(['Scans to do: ', num2str(Pars.NbScansToDo)])
    disp(['Scans remaining: ', num2str(c)])
    disp(['Approx. End: ', datestr(Endtime)])
    disp(['Captured: ', FileInfo.date])
    disp('----------------------------')

% Generate the figure.
    clf
    if iscell(x)                                                                            %In this case, it is a 2D experiment
        color=lines(numel(x{1,2}));                                                         %Generate a colormap for all traces
        names=num2cell(x{1,2});                                                             %Generate a the names of the traces
        for i=1:numel(x{1,2})
            subplot(numel(x{1,2}),1,i), plot(x{1,1},real(y(:,i)),'Color',color(i,:))        %Plot the traces
            ylabel(names(i),'FontWeight','bold')                                            %Put the y-labels to the axes
        end
    else                                                                                    %In this case, it is a 1D experiment
        plot(x,real(y))                                                                     %Simple plotting
        axis([min(x) max(x) min(real(y)) max(real(y))])
        ylabel('Intensity / a.u.')
    end
    
%Display info in the figure
    Text=strcat('{Captured: }', FileInfo.date);                                     % Collect text for info window in figure.
    Text2=strcat('{Runtime: }', char(Runtime));
    Text3=strcat(num2str(Pars.NbScansDone), '{ / }', num2str(Pars.NbScansToDo), '  Scans done');
    Text4=strcat('{Approx. End: }', datestr(Endtime));
    str={Text, Text2, Text3,Text4};                                                 % Merge text for info window in figure.
    xlabel(strcat(Pars.XNAM, " / ",Pars.XUNI))
    pos = [0.88 0.9 .0 .0];
    annotation('textbox',pos,'String',str,'FitBoxToText','on','HorizontalAlignment','right')

    fig=gcf;
    fig.Name=strcat('Current State of scan "', Pars.TITL,'"');                      % Set name of figure window.

    if Savemode~=0                                                                  % Call function savescan if Savemode unequal 0.
        savescan(pathName,DestinationPath,Savemode,Pars,Figsave,datsave,x,y)
    end

    pause(Updatefrq)    
end
end

% Function to save the current state of the experiment to your harddisk.
 function savescan(pathName,DestinationPath,Savemode,Pars,Figsave,datsave,x,y)
fileNameDTA = 'AUTOSAVE0000.DTA';                                                  % Filename of Autosave .DTA file on ELEXSYS
fileNameDSC = 'AUTOSAVE0000.DSC';                                                  % Filename of Autosave .DSC file on ELEXSYS
filePathDTA = (strcat(pathName, fileNameDTA));
filePathDSC = (strcat(pathName, fileNameDSC));
destinationpathDTA = (strcat(DestinationPath, fileNameDTA));
destinationpathDSC = (strcat(DestinationPath, fileNameDSC));

if Savemode==1
 copyfile(filePathDTA,destinationpathDTA);                                          % Copies the .DTA and .DSC Autosave Files to your local HardDisk.
 copyfile(filePathDSC,destinationpathDSC);
 newname = [destinationpathDTA(1:end-8),'_', num2str(Pars.NbScansDone),'.DTA'];     % Renames the copied files.
 newname2 = [destinationpathDTA(1:end-8),'_', num2str(Pars.NbScansDone),'.DSC'];
 movefile(destinationpathDTA,newname);
 movefile(destinationpathDSC,newname2);
 
 if Figsave==1                                                                      % Saves the plot as .png file if requested.
     print(gcf,'MySavedPlot','-dpng','-r300')
     movefile('MySavedPlot.png',strcat(newname(1:end-3),'png'))
 end
 
  if Figsave==2                                                                     % Saves the plot without textbox as .png file if requested.
      figraw = figure('visible','off');
      if iscell(x)
        color=lines(numel(x{1,2}));                                                         %Generate a colormap
        names=num2cell(x{1,2});                                                             %Generate a the names of the traces
        for i=1:numel(x{1,2})
            subplot(numel(x{1,2}),1,i), plot(x{1,1},real(y(:,i)),'Color',color(i,:))        %Plot the traces
            ylabel(names(i),'FontWeight','bold')                                            %Put the y-labels to the axes
        end
      else
        plot(x,real(y))    
        ylabel('Intensity / a.u.')
        axis([min(x) max(x) min(real(y)) max(real(y))])
      end
     xlabel(strcat(Pars.XNAM, '{ / }',Pars.XUNI))
     saveas(figraw,'MySavedPlotRaw.png')
     movefile('MySavedPlotRaw.png',strcat(newname(1:end-3),'png'))
  end
 
  if datsave==1                                                                     % Saves the data as .dat file if requested.
    if iscell(x)
        dlmwrite('MySaveddat.dat',{x{1,1}',real(y),imag(y)},'delimiter',' ')
    else
        dlmwrite('MySaveddat.dat',{x,real(y),imag(y)},'delimiter',' ')
    end
    movefile('MySaveddat.dat',strcat(newname(1:end-3),'dat'))
  end
 
end

if Savemode==2
 copyfile(filePathDTA,destinationpathDTA);                                          % Copies the .DTA and .DSC Autosave Files on your local HardDisk
 copyfile(filePathDSC,destinationpathDSC);
 currentdate=num2str(yyyymmdd(datetime));
 currenttime=datestr(datetime('now'),'HH_MM_SS');
 newname = [destinationpathDTA(1:end-8),'_', num2str(Pars.NbScansDone),'_',currentdate,'_', currenttime,'.DTA']; % Renames the copied files.
 newname2 = [destinationpathDTA(1:end-8),'_', num2str(Pars.NbScansDone),'_',currentdate,'_', currenttime,'.DSC'];
 movefile(destinationpathDTA,newname);
 movefile(destinationpathDSC,newname2);
 
  if Figsave==1                                                                           % Saves the plot as .png file if requested.
     print(gcf,'MySavedPlot','-dpng','-r300')
     movefile('MySavedPlot.png',strcat(newname(1:end-3),'png'))
 
  end

  if Figsave==2                                                                            % Saves the plot without textbox as .png file if requested.
     figraw = figure('visible','off');
      if iscell(x)
       color=lines(numel(x{1,2}));                                                         %Generate a colormap
       names=num2cell(x{1,2});                                                             %Generate a the names of the traces
        for i=1:numel(x{1,2})
            subplot(numel(x{1,2}),1,i), plot(x{1,1},real(y(:,i)),'Color',color(i,:))        %Plot the traces
            ylabel(names(i),'FontWeight','bold')                                            %Put the y-labels to the axes 
        end
      else
        plot(x,real(y))    
        axis([min(x) max(x) min(real(y)) max(real(y))])
      ylabel('Intensity / a.u.')
      end
      
     xlabel(strcat(Pars.XNAM, '{ / }',Pars.XUNI))
     saveas(figraw,'MySavedPlotRaw.png')
     movefile('MySavedPlotRaw.png',strcat(newname(1:end-3),'png'))
  end
  
  if datsave==1                                                                     % Saves the data as .dat file if requested.
    if iscell(x)
        dlmwrite('MySaveddat.dat',{x{1,1}',real(y),imag(y)},'delimiter',' ')
    else
        dlmwrite('MySaveddat.dat',{x,real(y),imag(y)},'delimiter',' ')
    end
     movefile('MySaveddat.dat',strcat(newname(1:end-3),'dat'))
  end
  
 end
 end

 
 