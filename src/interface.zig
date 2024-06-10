const std = @import("std");
const assert = std.debug.assert;

// Different ways of doing polymorphism with different trade-offs.
// This is quite similar to interfaces and overlaps with it.

// Base types

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

// 1. Tagged unions: best approach for speed and best fit for the language syntax.
// Worse memory, each instance takes as much space as the biggest type in the union.
// Usually fine if types are similar.
// Less flexible since we have to have all supported types inside the union (might be possible to generate with comptime).
const UnionNode = union(enum) {
    player: *Player,
    enemy: *Enemy,

    pub fn update(self: UnionNode) void {
        switch (self) {
            inline else => |un| {
                un.update();
            },
        }
    }
};

test "union node" {
    // vars here are declared on the stack but usually these would be allocated.
    var p = Player{ .counter = 0 };
    var e = Enemy{};
    const nodes = [_]UnionNode{ UnionNode{ .player = &p }, UnionNode{ .enemy = &e } };

    // print a new line at the beginning
    std.debug.print("\n", .{});

    for (nodes) |n| {
        n.update();
    }

    // update nodes a second time to see that the counter on player changes.
    for (nodes) |n| {
        n.update();
    }
}

// 2. VTable: slower than enum since it has to deref pointers but much more similar to interfaces in other languages.
// More memory efficient if types implementing this vary in size.
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

        const vtable = struct {
            fn update(ptr: *anyopaque) void {
                const self: T = @ptrCast(@alignCast(ptr));
                self.update();

                // alternatively call update like this to check at compile time if it has an update method
                // @typeInfo(T).Pointer.child.update()
            }
        };

        return .{
            .ptr = pointer,
            .updateFn = vtable.update,
        };
    }

    pub fn update(self: Node) void {
        self.updateFn(self.ptr);
    }
};

test "vTable" {
    var p = Player{ .counter = 0 };
    var e = Enemy{};

    const nodes = [_]Node{ Node.init(&p), Node.init(&e) };

    // print a new line at the beginning
    std.debug.print("\n", .{});

    for (nodes) |n| {
        n.update();
    }

    // update nodes a second time to see that the counter on player changes.
    for (nodes) |n| {
        n.update();
    }
}
