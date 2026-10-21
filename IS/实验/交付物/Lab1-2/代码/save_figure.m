function save_figure(fig, file)
%SAVE_FIGURE  Export a figure as PNG with a light (printable) theme.
    if exist('theme', 'file') == 2 || exist('theme', 'builtin') == 5
        try, theme(fig, 'light'); catch, end
    end
    if exist('exportgraphics', 'file') == 2 || exist('exportgraphics', 'builtin') == 5
        exportgraphics(fig, file, 'Resolution', 200);
    else
        print(fig, file, '-dpng', '-r200');
    end
end
