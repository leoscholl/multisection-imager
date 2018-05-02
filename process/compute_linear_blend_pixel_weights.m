function w_mat = compute_linear_blend_pixel_weights(size_I, alpha)
d_min_mat_i = zeros(size_I(1), 1);
d_min_mat_j = zeros(1, size_I(1));
for i = 1:size_I(1)
    d_min_mat_i(i,1) = min(i, size_I(1) - i + 1);
end
for j = 1:size_I(2)
    d_min_mat_j(1,j) = min(j, size_I(2) - j + 1);
end

w_mat = d_min_mat_i*d_min_mat_j;
w_mat = w_mat.^alpha;

end