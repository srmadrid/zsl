const types = @import("../../types.zig");

const vector = @import("../../vector.zig");

pub fn EnsureVector(comptime V: type, comptime N: type) type {
    comptime if (!types.isVector(V) or !types.isNumeric(N))
        @compileError("zsl.vector.EnsureVector: V must be a vector type and N must be anumeric type, got\n\tV = " ++
            @typeName(V) ++ "\n\tN = " ++ @typeName(N) ++ "\n");

    switch (comptime types.vectorType(V)) {
        .dense => return vector.Dense(N),
        .sparse => return vector.Sparse(N),
        .custom => {
            if (comptime types.hasMethod(V, "EnsureVector", fn (type, type) type, &.{ V, N }))
                return V.EnsureVector(V, N);

            @compileError("zsl.types.EnsureVector: " ++ @typeName(V) ++ " must implement `fn EnsureVector(type, type) type`");
        },
        .numeric => unreachable,
    }
}
