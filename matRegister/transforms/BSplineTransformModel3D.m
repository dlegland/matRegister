classdef BSplineTransformModel3D < ParametricTransform
%BSPLINETRANSFORMMODEL2D Cubic B-Spline Transform model in 3D
%
%   Class BSplineTransformModel3D
%
%   Grid is composed of M-by-N-by-P vertices, with M number of rows, N number
%   of columns and P number of planes. Iteration along x direction first.
%   Parameters correspond to shift vector associated to each vertex:
%   [vx111 vy111 vx211 vy211 ... vxIJK vyIJK ... vxMNP vyMNP]
%
%   Example
%   BSplineTransformModel3D
%
%   See also
%     BSplineTransformModel2D

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2018-08-09,    using Matlab 9.4.0.813654 (R2018a)
% Copyright 2018 INRA - BIA-BIBS.


%% Properties
properties
    % Number of vertices of the grid in each direction
    % (as a 1-by-3 row vector of non zero integers)
    gridSize;
    
    % Coordinates of the first vertex of the grid
    % (as a 1-by-3 row vector of double)
    gridOrigin;
    
    % Spacing between the vertices
    % (as a 1-by-3 row vector of double)
    gridSpacing;
end % end properties


%% Constructor
methods
    function this = BSplineTransformModel3D(varargin)
        % Constructor for BSplineTransformModel3D class
        %
        % T = BSplineTransformModel3D();
        % Creates a new transform initialized with default values
        %
        % T = BSplineTransformModel3D(GRIDSIZE, GRIDSPACING, GRIDORIGIN);
        % Creates a new transform by specifying the grid parameters.
        %
        
        if nargin == 0
            % Initialization with default values
            nd = 3;
            this.gridSize       = ones(1, nd);
            this.gridSpacing    = ones(1, nd);
            this.gridOrigin     = zeros(1, nd);
            initializeParameters();
                
        elseif nargin == 3
            this.gridSize       = varargin{1};
            this.gridSpacing    = varargin{2};
            this.gridOrigin     = varargin{3};
            initializeParameters();
        end

        function initializeParameters()
            dim = this.gridSize();
            np  = prod(dim) * length(dim);
            this.params = zeros(1, np);

            % initialize parameter names
            this.paramNames = cell(1, np);
            ind = 1;
            for iz = 1:this.gridSize(3)
                for iy = 1:this.gridSize(2)
                    for ix = 1:this.gridSize(1)
                        this.paramNames{ind} = sprintf('vx_%d_%d_%d', ix, iy, iz);
                        ind = ind + 1;
                        this.paramNames{ind} = sprintf('vy_%d_%d_%d', ix, iy, iz);
                        ind = ind + 1;
                        this.paramNames{ind} = sprintf('vz_%d_%d_%d', ix, iy, iz);
                        ind = ind + 1;
                    end
                end
            end
        end

    end

end % end constructors


%% Methods specific to class
methods
    function drawVertexShifts(this, varargin)
        % Draw the displacement associated to each vertex of the grid
        %
        % Example
        %    drawVertexShifts(T, 'g');
        %
        % See also
        %    drawGrid
        
        % get vertex array
        v = getGridVertices(this);
        % get array of shifts
        shifts = getVertexShifts(this);
        
        drawVector3d(v, shifts, varargin{:});
    end
    
    function drawGrid(this)
        % Draw the grid used to defined the deformation
        % (Do not deform the grid)
        %
        % Example
        %    drawGrid(T);
        %
        % See also
        %    drawVertexShifts

        % create vertex array
        v = getGridVertices(this);
        
        nv = prod(this.gridSize);
        inds = reshape(1:nv, this.gridSize);
        
        nX = this.gridSize(1);
        nY = this.gridSize(2);
        nZ = this.gridSize(3);
        
        % edges in direction x
        ne1 = (nX - 1) * nY * nZ;
        e1 = [reshape(inds(1:end-1, :, :), [ne1 1]) reshape(inds(2:end, :, :), [ne1 1])];
        
        % edges in direction y
        ne2 = nX * (nY - 1) * nZ;
        e2 = [reshape(inds(:, 1:end-1, :), [ne2 1]) reshape(inds(:, 2:end, :), [ne2 1])];
        
        % edges in direction z
        ne3 = nX * nY * (nZ - 1);
        e3 = [reshape(inds(:, :, 1:end-1), [ne3 1]) reshape(inds(:, :, 2:end), [ne3 1])];
        
        % create edge array
        e = cat(1, e1, e2, e3);

        drawGraph(v, e);
    end
    
    function vertices = getGridVertices(this)
        % Returns coordinates of grid vertices
        
        % base coordinates of grid vertices
        lx = (0:this.gridSize(1) - 1) * this.gridSpacing(1) + this.gridOrigin(1);
        ly = (0:this.gridSize(2) - 1) * this.gridSpacing(2) + this.gridOrigin(2);
        lz = (0:this.gridSize(3) - 1) * this.gridSpacing(3) + this.gridOrigin(3);
        
        % create base mesh
        % (use reverse order to make vertices iterate in x order first)
        [x, y, z] = meshgrid(lx, ly, lz);
        x = permute(x, [2 1 3]);
        y = permute(y, [2 1 3]);
        z = permute(z, [2 1 3]);
        
        % create vertex array
        vertices = [x(:) y(:) z(:)];
    end
    
    function shifts = getVertexShifts(this)
        % Returns shifts associated to each vertex as a N-by-3 array
        dx = reshape(this.params(1:3:end), this.gridSize);
        dy = reshape(this.params(2:3:end), this.gridSize);
        dz = reshape(this.params(3:3:end), this.gridSize);
        shifts = [dx(:) dy(:) dz(:)];
    end
end


%% Modify or access the grid parameters
% the ix and iy parameters are the indices of the transform grid.
methods
    function ux = getUx(this, ix, iy)
        ind = sub2ind(this.gridSize, ix, iy, iz) * 3 - 2;
        ux = this.params(ind);
    end
    
    function setUx(this, ix, iy, iz, ux)
        ind = sub2ind(this.gridSize, ix, iy, iz) * 3 - 2;
        this.params(ind) = ux;
    end
    
    function uy = getUy(this, ix, iy, iz)
        ind = sub2ind(this.gridSize, ix, iy, iz) * 3 - 1;
        uy = this.params(ind);
    end
    
    function setUy(this, ix, iy, iz, uy)
        ind = sub2ind(this.gridSize, ix, iy, iz) * 3 - 1;
        this.params(ind) = uy;
    end
    
    function uz = getUz(this, ix, iy, iz)
        ind = sub2ind(this.gridSize, ix, iy, iz) * 3;
        uz = this.params(ind);
    end
    
    function setUz(this, ix, iy, iz, uz)
        ind = sub2ind(this.gridSize, ix, iy, iz) * 3;
        this.params(ind) = uz;
    end
end % end methods


%% Methods implementing the ParametricTransform interface
methods
    function jac = parametricJacobian(this, x, varargin)
        % Computes parametric jacobian for a specific position
        % 
        % jac = getParametricJacobian(this, x)
        % 
        % The result is a ND-by-NP array, where ND is the number of
        % dimension, and NP is the number of parameters.
        %
        % If x is a N-by-3 array, return result as a ND-by-NP-by-N array.
        %

        % extract coordinate of input point
        if isempty(varargin)
            y = x(:,2);
            z = x(:,3);
            x = x(:,1);
        else
            y = varargin{1};
            z = varargin{2};
        end

        % allocate result
        np = length(this.params);
        jac = zeros(3, np, length(x));
        dim = size(jac);
                
        % compute position wrt to the grid vertices (1-indexed)
        xg = (x - this.gridOrigin(1)) / this.gridSpacing(1) + 1;
        yg = (y - this.gridOrigin(2)) / this.gridSpacing(2) + 1;
        zg = (z - this.gridOrigin(3)) / this.gridSpacing(3) + 1;
        
        % coordinates within the unit tile
        xu = xg - floor(xg);
        yu = yg - floor(yg);
        zu = zg - floor(zg);
       
        baseFuns = {...
            @BSplines.beta3_0, ...
            @BSplines.beta3_1, ...
            @BSplines.beta3_2, ...
            @BSplines.beta3_3};
        
        % iteration on neighbor tiles 
        eval_i = zeros(size(xu));
        for i = -1:2
            % coordinates of neighbor grid vertex
            xv = floor(xg) + i;
            indOkX = xv >= 1 & xv <= this.gridSize(1);

            % evaluate weight associated to grid vertex
            fun_i = baseFuns{i+2};
            eval_i(indOkX) = fun_i(xu(indOkX));
            
            for j = -1:2
                yv = floor(yg) + j;
                indOkY = yv >= 1 & yv <= this.gridSize(2);

                % indices of points whose grid vertex is defined
                inds = indOkX & indOkY;
                
                % linear index of translation components
                indX = sub2ind(this.gridSize, xv(inds), yv(inds)) * 2 - 1;
                
                % spline basis for y vertex
                fun_j = baseFuns{j+2};
                
                % evaluate weight associated to current grid vertex
                b = eval_i(inds) .* fun_j(yu(inds));
                
                % index of parameters
                indP = ones(size(indX));
                
                % update jacobian for grid vectors located around current
                % points
                jac(sub2ind(dim, indP, indX, find(inds))) = b;
                jac(sub2ind(dim, indP+1, indX+1, find(inds))) = b;
            end
        end
    end
end

%% Methods implementing the Transform interface
methods
    function point2 = transformPoint(this, point)
        % Compute coordinates of transformed point
        
        % initialize coordinate of result
        point2 = point;
        
        % compute position wrt to the grid vertices (1-indexed)
        xg = (point(:, 1) - this.gridOrigin(1)) / this.gridSpacing(1) + 1;
        yg = (point(:, 2) - this.gridOrigin(2)) / this.gridSpacing(2) + 1;
        zg = (point(:, 3) - this.gridOrigin(3)) / this.gridSpacing(3) + 1;
        
        % coordinates within the unit tile
        xu = xg - floor(xg);
        yu = yg - floor(yg);
        zu = zg - floor(zg);
       
        baseFuns = {...
            @BSplines.beta3_0, ...
            @BSplines.beta3_1, ...
            @BSplines.beta3_2, ...
            @BSplines.beta3_3};
        
        % iteration on neighbor tiles 
        eval_j = zeros(size(xu));
        eval_k = zeros(size(xu));
        for k = -1:2
            % coordinates of neighbor grid vertex
            zv = floor(zg) + k;
            indOkZ = zv >= 1 & zv <= this.gridSize(3);

            % evaluate weight associated to grid vertex
            fun_k = baseFuns{k+2};
            eval_k(indOkZ) = fun_k(zu(indOkZ));
            
            for j = -1:2
                % coordinates of neighbor grid vertex
                yv = floor(yg) + j;
                indOkY = yv >= 1 & yv <= this.gridSize(2);
            
                % evaluate weight associated to grid vertex
                fun_j = baseFuns{j+2};
                eval_j(indOkY) = fun_j(yu(indOkY));
                
                for i = -1:2
%                     fprintf('%d,%d,%d\n', i, j, k);
                    
                    % coordinates of neighbor grid vertex
                    xv = floor(xg) + i;
                    indOkX = xv >= 1 & xv <= this.gridSize(1);
                
                    % indices of points whose grid vertex is defined
                    inds = indOkX & indOkY & indOkZ;
                    
                    % linear index of translation components
                    indX = sub2ind(this.gridSize, xv(inds), yv(inds), zv(inds)) * 3 - 2;
                    
                    % spline basis for x vertex
                    fun_i = baseFuns{i+2};
                    
                    % evaluate weight associated to current grid vertex
                    b = fun_i(xu(inds)) .* eval_j(inds) .* eval_k(inds);
                    
                    % update coordinates of transformed points
                    point2(inds,1) = point2(inds,1) + b .* this.params(indX)';
                    point2(inds,2) = point2(inds,2) + b .* this.params(indX+1)';
                    point2(inds,3) = point2(inds,3) + b .* this.params(indX+2)';
                end
            end
        end
    end
    
    function jac = jacobianMatrix(this, point)
        % Jacobian matrix of the given point
        %
        %   JAC = getJacobian(TRANS, PT)
        %   where PT is a N-by-3 array of points, returns the spatial
        %   jacobian matrix of each point in the form of a 3-by-3-by-N
        %   array.
        %
        
        %% Constants
        
        % bspline basis functions and derivative functions
        baseFuns = {...
            @BSplines.beta3_0, ...
            @BSplines.beta3_1, ...
            @BSplines.beta3_2, ...
            @BSplines.beta3_3};
        
        derivFuns = {...
            @BSplines.beta3_0d, ...
            @BSplines.beta3_1d, ...
            @BSplines.beta3_2d, ...
            @BSplines.beta3_3d};

        
        %% Initializations
       
        % extract grid spacing for normalization
        deltaX = this.gridSpacing(1);
        deltaY = this.gridSpacing(2);
        deltaZ = this.gridSpacing(3);
        
        % compute position of points wrt to grid vertices
        xg = (point(:, 1) - this.gridOrigin(1)) / deltaX + 1;
        yg = (point(:, 2) - this.gridOrigin(2)) / deltaY + 1;
        zg = (point(:, 3) - this.gridOrigin(3)) / deltaZ + 1;
        
        % initialize zeros translation vector
        nPts = length(xg);

        % coordinates within the unit tile
        xu = reshape(xg - floor(xg), [1 1 nPts]);
        yu = reshape(yg - floor(yg), [1 1 nPts]);       
        zu = reshape(zg - floor(zg), [1 1 nPts]);       
        
        % allocate memory for storing result, and initialize to identity
        % matrix
        jac = zeros(3, 3, size(point, 1));
        jac(1, 1, :) = 1;
        jac(2, 2, :) = 1;
        jac(3, 3, :) = 1;
        
        % pre-allocate weights for vertex grids
        bz  = zeros(size(zu));
        bzd = zeros(size(zu));
        by  = zeros(size(yu));
        byd = zeros(size(yu));
                
        %% Iteration on neighbor tiles
        for k = -1:2
            % y-coordinate of neighbor vertex
            zv = floor(zg) + k;
            indOkZ = zv >= 1 & zv <= this.gridSize(3);
            
            % compute z-coefficients of bezier function and derivative
            bz(indOkZ)  = baseFuns{k+2}(zu(indOkZ));
            bzd(indOkZ) = derivFuns{k+2}(zu(indOkZ));
            
            for j = -1:2
                % y-coordinate of neighbor vertex
                yv = floor(yg) + j;
                indOkY = yv >= 1 & yv <= this.gridSize(2);
                
                % compute y-coefficients of bezier function and derivative
                by(indOkY)  = baseFuns{j+2}(yu(indOkY));
                byd(indOkY) = derivFuns{j+2}(yu(indOkY));
                
                for i = -1:2
                    % x-coordinate of neighbor vertex
                    xv  = floor(xg) + i;
                    indOkX = xv >= 1 & xv <= this.gridSize(1);
                    
                    % indices of points whose grid vertex is defined
                    inds = indOkX & indOkY & indOkZ;
                    if all(~inds)
                        continue;
                    end
                    
                    % linear index of translation components
                    indX = sub2ind(this.gridSize, xv(inds), yv(inds), zv(inds)) * 3 - 2;
                    
                    % translation vector of the current vertex
                    dxv = reshape(this.params(indX),   [1 1 length(indX)]);
                    dyv = reshape(this.params(indX+1), [1 1 length(indX)]);
                    dzv = reshape(this.params(indX+2), [1 1 length(indX)]);
                    
                    % compute x-coefficients of bezier function and derivative
                    bx  = baseFuns{i+2}(xu(inds));
                    bxd = derivFuns{i+2}(xu(inds));
                    
                    % update elements of the 3-by-3 jacobian matrices
                    jac(1, 1, inds) = jac(1, 1, inds) + bxd .* by(inds) .* bz(inds) .* dxv / deltaX;
                    jac(1, 2, inds) = jac(1, 2, inds) + bx .* byd(inds) .* bz(inds) .* dxv / deltaY;
                    jac(1, 3, inds) = jac(1, 3, inds) + bx .* by(inds) .* bzd(inds) .* dxv / deltaZ;
                    jac(2, 1, inds) = jac(2, 1, inds) + bxd .* by(inds) .* bz(inds) .* dyv / deltaX;
                    jac(2, 2, inds) = jac(2, 2, inds) + bx .* byd(inds) .* bz(inds) .* dyv / deltaY;
                    jac(2, 3, inds) = jac(2, 3, inds) + bx .* by(inds) .* bzd(inds) .* dyv / deltaZ;
                    jac(3, 1, inds) = jac(3, 1, inds) + bxd .* by(inds) .* bz(inds) .* dzv / deltaX;
                    jac(3, 2, inds) = jac(3, 2, inds) + bx .* byd(inds) .* bz(inds) .* dzv / deltaY;
                    jac(3, 3, inds) = jac(3, 3, inds) + bx .* by(inds) .* bzd(inds) .* dzv / deltaZ;
                end
            end
        end
    end

    function deriv = secondDerivatives(this, point, indI, indJ)
        % Second derivatives for the given point(s)
        %
        % D2 = secondDerivatives(T, POINT, INDI, INDJ)
        % Return a M-by-2 array, with as many rows as the number of points.
        % First columns is the second derivative of the x-transform part,
        % and second column is the second derivative of the y-transform
        % part.
        
        %% Constants
        
        % bspline basis functions and derivative functions
        baseFuns = {...
            @BSplines.beta3_0, ...
            @BSplines.beta3_1, ...
            @BSplines.beta3_2, ...
            @BSplines.beta3_3};
        
        derivFuns = {...
            @BSplines.beta3_0d, ...
            @BSplines.beta3_1d, ...
            @BSplines.beta3_2d, ...
            @BSplines.beta3_3d};
        
        deriv2Funs = {...
            @BSplines.beta3_0s, ...
            @BSplines.beta3_1s, ...
            @BSplines.beta3_2s, ...
            @BSplines.beta3_3s};

        
        %% Initializations
       
        % extract grid spacing for normalization
        deltaX = this.gridSpacing(1);
        deltaY = this.gridSpacing(2);
        deltaZ = this.gridSpacing(3);
        
        % compute position of points wrt to grid vertices
        xg = (point(:, 1) - this.gridOrigin(1)) / deltaX + 1;
        yg = (point(:, 2) - this.gridOrigin(2)) / deltaY + 1;
        zg = (point(:, 3) - this.gridOrigin(3)) / deltaZ + 1;
        
        % initialize zeros translation vector
        nPts = length(xg);

        % coordinates within the unit tile
        xu = reshape(xg - floor(xg), [nPts 1]);
        yu = reshape(yg - floor(yg), [nPts 1]);
        zu = reshape(zg - floor(zg), [nPts 1]);
        
        % allocate memory for storing result
        deriv = zeros(size(point, 1), 3);
        
        % pre-allocate weights for vertex grids
        bz  = zeros(size(xu));
        bzd = zeros(size(xu));
        bzs = zeros(size(xu));
        by  = zeros(size(xu));
        byd = zeros(size(xu));
        bys = zeros(size(xu));
        bx  = zeros(size(xu));
        bxd = zeros(size(xu));
        bxs = zeros(size(xu));
        
        %% Iteration on neighbor tiles 
        for k = -1:2
            % z-coordinate of neighbor vertex
            zv = floor(zg) + k;
            indOkZ = zv >= 1 & zv <= this.gridSize(3);
            
            % compute z-coefficients of bezier function and derivative
            bz(indOkZ)  = baseFuns{k+2}(zu(indOkZ));
            bzd(indOkZ) = derivFuns{k+2}(zu(indOkZ));
            bzs(indOkZ) = deriv2Funs{k+2}(zu(indOkZ));
            
            for j = -1:2
                % y-coordinate of neighbor vertex
                yv = floor(yg) + j;
                indOkY = yv >= 1 & yv <= this.gridSize(2);
                
                % compute y-coefficients of bezier function and derivative
                by(indOkY)  = baseFuns{j+2}(yu(indOkY));
                byd(indOkY) = derivFuns{j+2}(yu(indOkY));
                bys(indOkY) = deriv2Funs{j+2}(yu(indOkY));
                
                for i = -1:2
                    % x-coordinate of neighbor vertex
                    xv  = floor(xg) + i;
                    indOkX = xv >= 1 & xv <= this.gridSize(1);
                    
                    % indices of points whose grid vertex is defined
                    inds = indOkX & indOkY & indOkZ;
                    if all(~inds)
                        continue;
                    end
                    
                    % linear index of translation components
                    indX = sub2ind([this.gridSize], xv(inds), yv(inds), zv(inds)) * 3 - 2;
                    
                    % translation vector of the current vertex
                    dxv = reshape(this.params(indX),   [length(indX) 1]);
                    dyv = reshape(this.params(indX+1), [length(indX) 1]);
                    dzv = reshape(this.params(indX+2), [length(indX) 1]);
                    
                    % compute x-coefficients of spline function and derivative
                    bx  = baseFuns{i+2}(xu(inds));
                    bxd = derivFuns{i+2}(xu(inds));
                    bxs = deriv2Funs{i+2}(xu(inds));
                    
                    % update second derivatives elements
                    if indI == 1 && indJ == 1
                        deriv(inds,1) = deriv(inds,1) + (bxs .* by(inds) .* bz(inds) .* dxv) / (deltaX^2);
                        deriv(inds,2) = deriv(inds,2) + (bxs .* by(inds) .* bz(inds) .* dyv) / (deltaX^2);
                        deriv(inds,3) = deriv(inds,3) + (bxs .* by(inds) .* bz(inds) .* dzv) / (deltaX^2);
                        
                    elseif indI == 2 && indJ == 2
                        deriv(inds,1) = deriv(inds,1) + (bx .* bys(inds) .* bz(inds) .* dxv) / (deltaY^2);
                        deriv(inds,2) = deriv(inds,2) + (bx .* bys(inds) .* bz(inds) .* dyv) / (deltaY^2);
                        deriv(inds,3) = deriv(inds,3) + (bx .* bys(inds) .* bz(inds) .* dzv) / (deltaY^2);
                        
                    elseif indI == 3 && indJ == 3
                        deriv(inds,1) = deriv(inds,1) + (bx .* by(inds) .* bzs(inds) .* dxv) / (deltaZ^2);
                        deriv(inds,2) = deriv(inds,2) + (bx .* by(inds) .* bzs(inds) .* dyv) / (deltaZ^2);
                        deriv(inds,3) = deriv(inds,3) + (bx .* by(inds) .* bzs(inds) .* dzv) / (deltaZ^2);
                        
                    elseif (indI == 1 && indJ == 2) || (indI == 2 && indJ == 1)
                        deriv(inds,1) = deriv(inds,1) + (bxd .* byd(inds) .* bz(inds) .* dxv) / (deltaX*deltaY);
                        deriv(inds,2) = deriv(inds,2) + (bxd .* byd(inds) .* bz(inds) .* dyv) / (deltaX*deltaY);
                        deriv(inds,3) = deriv(inds,3) + (bxd .* byd(inds) .* bz(inds) .* dzv) / (deltaX*deltaY);
                        
                    elseif (indI == 1 && indJ == 3) || (indI == 3 && indJ == 1)
                        deriv(inds,1) = deriv(inds,1) + (bxd .* by(inds) .* bzd(inds) .* dxv) / (deltaX*deltaZ);
                        deriv(inds,2) = deriv(inds,2) + (bxd .* by(inds) .* bzd(inds) .* dyv) / (deltaX*deltaZ);
                        deriv(inds,3) = deriv(inds,3) + (bxd .* by(inds) .* bzd(inds) .* dzv) / (deltaX*deltaZ);
                        
                    elseif (indI == 2 && indJ == 3) || (indI == 3 && indJ == 2)
                        deriv(inds,1) = deriv(inds,1) + (bx .* byd(inds) .* bzd(inds) .* dxv) / (deltaY*deltaZ);
                        deriv(inds,2) = deriv(inds,2) + (bx .* byd(inds) .* bzd(inds) .* dyv) / (deltaY*deltaZ);
                        deriv(inds,3) = deriv(inds,3) + (bx .* byd(inds) .* bzd(inds) .* dzv) / (deltaY*deltaZ);
                        
                    else
                        error('indI and indJ should be between 1 and 2');
                    end
                end
            end
        end
        
    end % secondDerivatives

    function lap = curvatureOperator(this, point)
        % Compute curvature operator at given position(s)
        %
        %   LAP = curvatureOperator(TRANS, PT)
        %   where PT is a N-by-3 array of points, returns the laplacian of
        %   each point in the form of a 3-by-3-by-N array.
        %
        
        % compute second derivatives (each array is Npts-by-2
        dx2 = secondDerivatives(this, point, 1, 1);
        dy2 = secondDerivatives(this, point, 2, 2);
        dz2 = secondDerivatives(this, point, 3, 3);
        
        % compute curvature operator
        lap = sum(dx2, 2).^2 + sum(dy2, 2).^2 + sum(dz2, 2).^2;
    end

    function dim = getDimension(this) %#ok<MANU>
        dim = 3;
    end
end


%% Serialization methods
methods
    function str = toStruct(this)
        % Converts to a structure to facilitate serialization
        str = struct('type', 'BSplineTransformModel3D', ...
            'gridSize', this.gridSize, ...
            'gridSpacing', this.gridSpacing, ...
            'gridOrigin', this.gridOrigin, ...
            'parameters', this.params);
    end
end
methods (Static)
    function transfo = fromStruct(str)
        % Creates a new instance from a structure
        transfo = BSplineTransformModel3D(str.gridSize, str.gridSpacing, str.gridOrigin);
        transfo.params = str.parameters;
    end
end

end % end classdef

