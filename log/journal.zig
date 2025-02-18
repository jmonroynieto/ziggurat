const std = @import("std");

const sockaddr_un = extern struct {
    sun_family: u16,
    sun_path: [108]u8,
};

const JOURNAL_SOCKET_PATH = "/run/systemd/journal/socket";
const PATH_MAX = 108;

pub fn send_journald_message(allocator: std.mem.Allocator, message: []const u8, syslog_identifier: []const u8) void {
    const fd = std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.DGRAM, 0) catch unreachable;
    defer std.posix.close(fd);
    var addr: sockaddr_un = undefined;
    addr.sun_family = std.posix.AF.UNIX;

    const path = JOURNAL_SOCKET_PATH;
    if (path.len >= PATH_MAX) {
        return error.PathTooLong;
    }
    std.mem.copyForwards(u8, &addr.sun_path, path);
    addr.sun_path[path.len] = 0;

    const msg = std.fmt.allocPrint(
        allocator,
        "MESSAGE={s}\nSYSLOG_IDENTIFIER={s}\nPRIORITY=6\n\n",
        .{ message, syslog_identifier },
    ) catch unreachable;
    defer allocator.free(msg);
    const socketPtr: *const std.posix.sockaddr = @ptrCast(&addr);
    const addrLen: u32 = @intCast(@sizeOf(u16) + msg.len + 1);
    const sent = std.posix.sendto(fd, msg, 0, socketPtr, addrLen) catch unreachable;
    if (sent != msg.len) {
        std.debug.print("Failed to send journald message with SYSLOG_IDENTIFIER!\n", .{});
    }

    std.debug.print("Sent journald message with SYSLOG_IDENTIFIER!\n", .{});
}
