%% AREA_CYLINDER  Total surface area of a cylinder (handout section 2.4).
%  Total surface area = 2*pi*r*h  (side)  +  2*pi*r^2  (two end caps).

radius = 0.05;        % [m]
height = 0.20;        % [m]

side_area = 2*pi*radius*height;
end_area  = 2*pi*radius^2;
total_area = side_area + end_area;

fprintf('radius = %.3f m, height = %.3f m\n', radius, height);
fprintf('side   = %.6f m^2\n', side_area);
fprintf('2 ends = %.6f m^2\n', end_area);
fprintf('TOTAL  = %.6f m^2\n', total_area);
