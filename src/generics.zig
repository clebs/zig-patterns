const std = @import("std");

fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        const Item = struct {
            data: T,
            next: ?*Item,
        };

        ally: std.mem.Allocator,
        start: ?*Item,
        end: ?*Item,

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .ally = alloc,
                .start = null,
                .end = null,
            };
        }

        pub fn enqueue(self: *Self, item: T) !void {
            const i = try self.ally.create(Item);

            i.* = Item{ .data = item, .next = null };

            if (self.end) |end| end.next = i else self.start = i;

            self.end = i;
        }

        pub fn dequeue(self: *Self) ?T {
            const start = self.start orelse return null;
            defer self.ally.destroy(start);

            if (start.next) |next| {
                self.start = next;
            } else {
                self.start = null;
                self.end = null;
            }

            return start.data;
        }
    };
}

test "queue" {
    // Create a Queue<i32> type
    const IntQueue = Queue(i32);

    // create an instance of the type
    var q1 = IntQueue.init(std.testing.allocator);
    try q1.enqueue(42);
    try q1.enqueue(25);

    try std.testing.expectEqual(@as(?i32, 42), q1.dequeue());
    try std.testing.expectEqual(@as(?i32, 25), q1.dequeue());
}
