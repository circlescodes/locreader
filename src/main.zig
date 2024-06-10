const std = @import("std");

const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    switch (args.len) {
        0 => unreachable,
        1 => {
            std.log.err("Too little arguments.", .{});
            return;
        },
        else => {},
    }

    const cwd_string = std.fs.cwd().realpathAlloc(alloc, args[1]) catch |e| {
        switch (e) {
            error.FileNotFound => {
                std.log.err("Directory not found.", .{});
                return;
            },
            else => return e,
        }
    };
    defer alloc.free(cwd_string);

    var dir = std.fs.openDirAbsolute(cwd_string, .{
        .iterate = true,
    }) catch |e| {
        switch (e) {
            error.NotDir => {
                std.log.err("Your entered argument is not a directory.", .{});
                return;
            },
            else => return e,
        }
    };
    defer dir.close();

    var walker = try dir.walk(alloc);
    var total_files_checked: usize = 0;
    var total_lines: usize = 0;

    outer: while (try walker.next()) |entry| {
        if (entry.kind != .file)
            continue :outer;

        total_files_checked += 1;

        const read_file = try entry.dir.readFileAlloc(alloc, entry.basename, std.math.maxInt(usize));
        defer alloc.free(read_file);

        var lines: usize = 1;

        for (read_file) |c| {
            if (c == '\n')
                lines += 1;
        }

        total_lines += lines;

        try stdout.print("File: {s}; Lines: {d}\n", .{ entry.path, lines });
    }
    try stdout.writeByteNTimes('=', 36);
    // Here we add a new line at the start because the previous function does not output a new line at the end. 🤓
    try stdout.print("\nTotal Amount of Files Checked: {d}, Total Amount of Lines: {d}\n", .{ total_files_checked, total_lines });
}
