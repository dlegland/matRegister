classdef SumOfLocalVariances < ImageSetMetric
%SUMOFLOCALVARIANCES  One-line description here, please.
%
%   output = SumOfLocalVariances(input)
%
%   Example
%   SumOfLocalVariances
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2010-11-09,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRA - Cepia Software Platform.

%% Constructor
methods
    function obj = SumOfLocalVariances(varargin)
        % calls the parent constructor
        obj = obj@ImageSetMetric(varargin{:});
        
    end % constructor
    
end % methods

methods
    function res = computeValue(obj)
        % Compute metric value.
        %
        %   output = computeValue(input)
        %

        % extract number of images
        nImages = length(obj.Images);
        
        % number of points
        nPoints = size(obj.Points, 1);
        
        % all values and flags
        allValues   = zeros(nPoints, nImages);
        allIsInside = false(nPoints, nImages);
        
        % update values
        for i = 1:nImages
            [val, ind] = evaluate(obj.Images{i}, obj.Points);
            allValues(:,i) = val;
            allIsInside(:,i) = ind;
        end
        
        % compute indices of points which are inside all windows
        allInside = sum(allIsInside==0, 2)==0;
        
        % compute variance of valid points
        sigmaArray = var(allValues(allInside, :), 1, 2);
        
        % % uses value = 0 when samping outside of the image
        % sigmaArray(allIsInside) = 0;
        
        res = sum(sigmaArray) / sum(allInside);
    end
end

end % classdef
