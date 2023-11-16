/// Stack gotcha illustrates how using stack memory outside its scope causes subtle bugs that produce dangling pointers.
/// This makes undefined values appear when trying to access memory that was on the stack and has been freed when
/// returning from the scope it was created in.
/// It is also shown how subtle the bug is because the memory sometimes still has the correct values until something new
/// is pushed to the stack, making it hard to detect.
const std = @import("std");

const List = std.DoublyLinkedList(u8);

/// Wrong shows the gotcha in action and how being used to other languages it is easy to fall for this.
const Wrong = struct {
    items: List,

    fn add(self: *Wrong, x: u8) !void {
        // The node is created on the stack in the scope of `add`.
        // Once this function returns, when we access this node on the list, it will be a dangling pointer.
        // The memory the pointer adresses to could contain anything.
        var n = List.Node{ .data = x };
        self.items.append(&n);
    }
};

/// Correct shows how to properly do this using the Heap.
const Correct = struct {
    items: List,
    ally: std.mem.Allocator,

    fn add(self: *Correct, x: u8) !void {
        // The node is allocated on the heap and thus will live until freed.
        // When accessing this memory address from the node outside, it will contain the expected values.
        var n = try self.ally.create(List.Node);
        n.data = x;
        self.items.append(n);
    }
};

test "stack gotcha" {
    var l = Wrong{
        .items = List{},
    };

    // var l = Correct{
    // .items = List{},
    // .ally = std.testing.allocator,
    // };

    try l.add(42);

    // When running Wrong, the assertion will fail.
    // The value willchange after the scope of `add` is popped from the stack and something else is pushed to the stack (print statement).
    // The fact that memory stays unchanged until another call is pushed to the stack makes it hard to detect.
    // If the print statement is commented out, the test will pass even if the value can change anytime.
    std.debug.print("\nMy number is: {d}\n", .{l.items.first.?.data});
    std.debug.assert(l.items.first.?.data == 42);

    // Uncomment when running Correct
    // remember to not leak memory from the heap!!
    // std.testing.allocator.destroy(l.items.first.?);
}
