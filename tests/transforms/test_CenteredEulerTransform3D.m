function test_suite = test_CenteredEulerTransform3D(varargin)
%test_CenteredEulerTransform3D  Test file for class CenteredMotionTransform2D
%   output = test_CenteredEulerTransform3D(input)
%
%   Example
%   test_CenteredEulerTransform3D
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2010-06-17,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRA - Cepia Software Platform.

test_suite = buildFunctionHandleTestSuite(localfunctions);

function test_getAffineMatrix %#ok<*DEFNU>

center = [6 8 9];
T1  = createTranslation3d(-center);
rotX = createRotationOx(deg2rad(3));
rotY = createRotationOy(deg2rad(4));
rotZ = createRotationOz(deg2rad(5));
R   = composeTransforms3d(rotX, rotY, rotZ);
T2  = createTranslation3d(center);
T0  = createTranslation3d([6 7 8]);
matTh = T0 * T2 * R * T1;

T = CenteredEulerTransform3D([3 4 5 6 7 8], 'Center', center);

mat = affineMatrix(T);
assertElementsAlmostEqual(matTh, mat, 'absolute', .1);


function test_getDimension

center = [6 8 9];
T = CenteredEulerTransform3D([3 4 5 6 7 8], 'Center', center);

dim = getDimension(T);

assertEqual(3, dim);


function test_writeToFile

% prepare
fileName = 'transfoFile.txt';
if exist(fileName, 'file')
    delete(fileName);
end

% create transfo
center = [6 8 9];
T = CenteredEulerTransform3D([3 4 5 6 7 8], 'Center', center);
mat0 = affineMatrix(T);

% save the transfo
writeToFile(T, fileName);

% read a new transfo
T2 = CenteredEulerTransform3D.readFromFile(fileName);
mat2 = affineMatrix(T2);

assertElementsAlmostEqual(mat0, mat2, 'absolute', .1);

% clean up
delete(fileName);



function test_ToStruct
% Test call of function without argument

transfo = CenteredEulerTransform3D([10 20 30 10 20 30], 'Center', [50 50 50]);
str = toStruct(transfo);
transfo2 = CenteredEulerTransform3D.fromStruct(str);

assertTrue(isa(transfo2, 'CenteredEulerTransform3D'));


function test_readWrite
% Test call of function without argument

% prepare
fileName = 'CenteredEulerTransform3D.transfo';
if exist(fileName, 'file')
    delete(fileName);
end

% arrange
transfo = CenteredEulerTransform3D([10 20 30 10 20 30], 'Center', [50 50 50]);

% act
write(transfo, fileName);
transfo2 = Transform.read(fileName);

% assert
assertTrue(isa(transfo2, 'CenteredEulerTransform3D'));
assertElementsAlmostEqual(transfo2.Center, transfo.Center, 'absolute', .01);

% clean up
delete(fileName);

