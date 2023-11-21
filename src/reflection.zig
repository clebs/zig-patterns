const std = @import("std");

const MyType = struct {
    a: u32,
    b: []const u8,
    c: bool,
    d: f32,
};

test "reflection magic" {
    var x = MyType{
        .a = 0,
        .b = "",
        .c = false,
        .d = 0,
    };

    // This loop gets unrolled at comptime, getting all conditions for each field laid out.
    // Runtime values can be then accessed and assigned with the @field builtin and the field name.
    inline for (std.meta.fields(MyType)) |f| {
        if (f.type == []const u8) @field(x, f.name) = "Howdy!";
        if (f.type == f32) @field(x, f.name) = 3.14;
    }

    // Printing complex data types is not always perfect (see how the string is printed as bytes and float with scientific notation).
    std.debug.print("\nNot so great print:\n{any}\n", .{x});

    // We can use comptime reflection to print a nicer version:
    // f32 and strings get custom prints, but any other field is fine with the umbrella formatting.
    // Here we also use switch instead of if for some variation in the showcase. Unrolled loop will generate a switch block per field.
    std.debug.print("\nNicer print:\n", .{});
    inline for (std.meta.fields(@TypeOf(x))) |field| {
        switch (field.type) {
            f32 => std.debug.print(field.name ++ " = {d:.2}\n", .{@as(field.type, @field(x, field.name))}),
            []const u8 => std.debug.print(field.name ++ " = {s}\n", .{@as(field.type, @field(x, field.name))}),
            else => std.debug.print(field.name ++ " = {any}\n", .{@as(field.type, @field(x, field.name))}),
        }
    }
}
