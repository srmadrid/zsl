const meta = @import("../../meta.zig");

const vector = @import("../../vector.zig");

pub fn EnsureVector(comptime V: type, comptime N: type) type {
    comptime if (!meta.isVector(V) or !meta.isNumeric(N))
        @compileError("zsl.vector.EnsureVector: V must be a vector type and N must be anumeric type, got\n\tV = " ++
            @typeName(V) ++ "\n\tN = " ++ @typeName(N) ++ "\n");

    switch (comptime meta.vectorType(V)) {
        .dense => return vector.Dense(N),
        .sparse => return vector.Sparse(N),
        .custom => {
            if (comptime meta.hasMethod(V, "EnsureVector", fn (type, type) type, &.{ V, N }))
                return V.EnsureVector(V, N);

            @compileError("zsl.vector.EnsureVector: " ++ @typeName(V) ++ " must implement `fn EnsureVector(type, type) type`");
        },
        .numeric => unreachable,
    }
}
