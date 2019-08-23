classdef NearestNeighborGradientEvaluator < ImageFunction
% Evaluate nearest neighbor gradient within image.
%
%   output = NearestNeighborGradientEvaluator(input)
%
%   Example
%   NearestNeighborGradientEvaluator
%
%   See also
%
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2010-12-09,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRA - Cepia Software Platform.

properties
    % the image whom gradient will be evaluated
    Image;
    
    % output type of interpolation, double by default
    OutputType = 'double';

    % default value for points outside image
    DefaultValue = NaN;
    
    % the filters used for gradient evaluation in each direction.
    % should be a cell array with as many columns as image dimension.
    Filters;
end

%% Constructors
methods
    function obj = NearestNeighborGradientEvaluator(varargin)
       
        if nargin == 0
            return;
        end
        
        % extract image to interpolate
        var = varargin{1};
        if isa(var, 'NearestNeighborGradientEvaluator')
            obj.Image = var.Image;
        elseif isa(var, 'Image')
            obj.Image = var;
        end
        varargin(1) = [];
        
        if channelNumber(obj.Image) > 1
            error('Gradient of vector images is not supported');
        end
        
        % setup default values depending on image dimension
        nd = ndims(obj.Image);
        switch nd
            case 1
                obj.Filters = {[1 0 -1]'};
            case 2
                sx = fspecial('sobel')'/8;
                obj.Filters = {sx, sx'};
            case 3
                [sx, sy, sz] = Image.create3dGradientKernels();
                obj.Filters = {sx, sy, sz};
        end
        
        % parse user specified options
        while length(varargin) > 1
            paramName = varargin{1};
            if strcmpi(paramName, 'defaultValue')
                obj.DefaultValue = varargin{2};
                
            elseif strcmpi(paramName, 'filters')
                obj.Filters = varargin{2};
                
            elseif strcmpi(paramName, 'outputType')
                obj.OutputType = varargin{2};
                
            else
                error(['Unknown parameter name: ' paramName]);
            end
            
            varargin(1:2) = [];
        end
    end
end

methods
    function [grad, isInside] = evaluate(obj, varargin)
        % Evaluate the gradient for the specified point(s).
        %
        %   GRAD = evaluate(OBJ, POINTS)
        %   Where POINTS is a N-by-2 array, return a N-by-2 array of gradients.
        %
        %   GRAD = evaluate(OBJ, PX, PY)
        %   Where PX and PY are arrays the same size, return an array with one
        %   dimension more that PX, containing gradient for each point.
        %
        %   [GRAD, ISINSIDE] = evaluate(...)
        %   Also returns an array of boolean indicating which points are within the
        %   image frame.
        %
        %   Example
        %   evaluate
        %
        %   See also
        %
        
        % ------
        % Author: David Legland
        % e-mail: david.legland@inra.fr
        % Created: 2010-10-11,    using Matlab 7.9.0.529 (R2009b)
        % Copyright 2010 INRA - Cepia Software Platform.
        
        % number of dimensions of base image
        nd = ndims(obj.Image);
        
        % size of elements: number of channels by number of frames
        elSize = elementSize(obj.Image);
        if elSize(1) > 1
            error('Can not evaluate gradient of a vector image');
        end
        
        % eventually convert inputs to a single nPoints-by-ndims array
        [point, dim] = ImageFunction.mergeCoordinates(varargin{:});
        
        if size(point, 2) ~= nd
            error('Dimension of input positions should be the same as image');
        end
        
        % Evaluates image value for a given position
        coord = pointToContinuousIndex(obj.Image, point);
        
        % size and number of dimension of input coordinates
        dim0 = dim;
        if dim0(end) == 1
            dim0 = dim0(1:end-1);
        end
        
        % number of positions to process
        N = size(coord, 1);
        
        % Create default result image
        dim2 = [dim0 nd];
        grad = ones(dim2) * obj.FillValue;
        
        % % Create default result image
        % defaultValue = NaN;
        % grad = ones([N 2])*defaultValue;
        
        % extract x and y
        xt = coord(:, 1);
        yt = coord(:, 2);
        if nd > 2
            zt = coord(:, 3);
        end
        
        % select points located inside interpolation area
        % (smaller than image physical size)
        siz = size(obj.Image);
        isBefore    = sum(coord < 1.5, 2) > 0;
        isAfter     = sum(coord >= (siz(ones(N,1), :))-.5, 2) > 0;
        isInside    = ~(isBefore | isAfter);
        
        xt = xt(isInside);
        yt = yt(isInside);
        if nd > 2
            zt = zt(isInside);
        end
        isInside = reshape(isInside, dim);
        
        % convert to indices
        inds = find(isInside);
        
        if length(obj.Filters) < nd
            error('Wrong initialization of gradient filters');
        end
        
        % values of the nearest neighbor
        if nd == 2
            sx = obj.Filters{1};
            sy = obj.Filters{2};
            
            for i = 1:length(inds)
                % indices of pixels before and after in each direction
                i1 = round(xt(i));
                j1 = round(yt(i));
                
                % create a local copy of the neighborhood
                im = cast(obj.Image(i1-1:i1+1, j1-1:j1+1), obj.OutputType);
                
                % compute gradients in each main direction
                grad(inds(i), 1) = -sum(sum(sum(im.*sx)));
                grad(inds(i), 2) = -sum(sum(sum(im.*sy)));
            end
            
        else
            sx = obj.Filters{1};
            sy = obj.Filters{2};
            sz = obj.Filters{3};
            
            for i = 1:length(inds)
                % indices of pixels before and after in each direction
                i1 = round(xt(i));
                j1 = round(yt(i));
                k1 = round(zt(i));
                
                % create a local copy of the neighborhood
                im = cast(obj.Image(i1-1:i1+1, j1-1:j1+1, k1-1:k1+1), ...
                    obj.OutputType);
                
                % compute gradients in each main direction
                grad(inds(i), 1) = -sum(sum(sum(im.*sx)));
                grad(inds(i), 2) = -sum(sum(sum(im.*sy)));
                grad(inds(i), 3) = -sum(sum(sum(im.*sz)));
            end
            
        end
        
    end
end
end