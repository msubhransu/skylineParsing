function gifWrite(conf)
% GIFWRITE writes the output of the figure as a GIF
%   GIFWRITE(CONF) writes the output to 'out.gif' (this is always fixed) if
%   the CONF.GIF is true. Note if the file 'out.gif' exists then the new
%   frames are appended to this. The current frame to be written is what
%   getframe(1) returns.
%   
% Author: Subhransu Maji

if ~conf.gif
    return;
end

% Get frame and append it to the file
frame = getframe(1);
im = frame2im(frame);
[imind,cm] = rgb2ind(im,256);

% If the file exists then append to it, else create a new one
filename = 'out.gif';
if ~exist(filename,'file');
  imwrite(imind,cm,filename,'gif','Loopcount',inf);
else
  imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',0.1);
end