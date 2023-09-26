const std = @import("std");
const assert = std.debug.assert;

/// Node is an interface for any type that has an update method.
const Node = struct {
    ptr: *anyopaque,
    updateFn: *const fn (self: *anyopaque) void,

    /// init creates a Node with the given type as inner pointer whose `update` function will be called when calling `Node.update`
    pub fn init(pointer: anytype) Node {
        // validate pointer
        const T = @TypeOf(pointer);
        assert(@typeInfo(T) == .Pointer); // chek the type is a pointer
        assert(@typeInfo(T).Pointer.size == .One);
        assert(@typeInfo(@typeInfo(T).Pointer.child) == .Struct);

        const gen = struct {
            fn update(ptr: *anyopaque) void {
                const self: T = @ptrCast(@alignCast(ptr));
                self.update();
            }
        };

        return .{
            .ptr = pointer,
            .updateFn = gen.update,
        };
    }

    pub fn update(self: Node) void {
        self.updateFn(self.ptr);
    }
};

/// Player satisfies the Node interface.
/// Inspired by gamedev, we made the example with what typically would be all different game entities that need to be updated.
const Player = struct {
    const Self = @This();

    counter: u8,

    pub fn update(self: *Self) void {
        // we added a counter member to tet that the node can have its state updated.
        self.counter += 1;
        std.debug.print("I am a player and counter is: {d}\n", .{self.counter});
    }
};

/// Enemy also satisfies the Node unterface but has a different implementation.
const Enemy = struct {
    const Self = @This();

    pub fn update(self: *Self) void {
        _ = self;
        std.debug.print("I am an enemy\n", .{});
    }
};

/// This function accepts any type that satisfies the Node interface.
/// This constraint is checked at compile time.
fn updateNode(node: anytype) void {
    node.update();
}

test "array of interfaces" {
    var p = Player{ .counter = 0 };
    var e = Enemy{};

    var nodes = [_]Node{ Node.init(&p), Node.init(&e) };

    for (nodes) |n| {
        updateNode(n);
    }

    // update nodes a second time to see that the counter on player changes.
    for (nodes) |n| {
        updateNode(n);
    }
}
