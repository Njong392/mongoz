const clib = @import("clib.zig");

pub const BsonError = error{
    allocError,
    bsonError,
    typeError,
};

//
// Json
//
pub const Json = struct{
    ptr: [*:0]u8,

    pub fn free(self: *const Json) void {
        clib.bson_free(self.ptr);
    }
};

//
// Bson type
//
pub const Type = struct {
    pub const EOD : c_uint = clib.BSON_TYPE_EOD;
    pub const DOUBLE : c_uint = clib.BSON_TYPE_DOUBLE;
    pub const UTF8 : c_uint = clib.BSON_TYPE_UTF8;
    pub const DOCUMENT : c_uint = clib.BSON_TYPE_DOCUMENT;
    pub const ARRAY : c_uint = clib.BSON_TYPE_ARRAY;
    pub const BINARY : c_uint = clib.BSON_TYPE_BINARY;
    pub const UNDEFINED : c_uint = clib.BSON_TYPE_UNDEFINED;
    pub const OID : c_uint = clib.BSON_TYPE_OID;
    pub const BOOL : c_uint = clib.BSON_TYPE_BOOL;
    pub const DATE_TIME : c_uint = clib.BSON_TYPE_DATE_TIME;
    pub const NULL : c_uint = clib.BSON_TYPE_NULL;
    pub const REGEX : c_uint = clib.BSON_TYPE_REGEX;
    pub const DBPOINTER : c_uint = clib.BSON_TYPE_DBPOINTER;
    pub const CODE : c_uint = clib.BSON_TYPE_CODE;
    pub const SYMBOL : c_uint = clib.BSON_TYPE_SYMBOL;
    pub const CODEWSCOPE : c_uint = clib.BSON_TYPE_CODEWSCOPE;
    pub const INT32 : c_uint = clib.BSON_TYPE_INT32;
    pub const TIMESTAMP : c_uint = clib.BSON_TYPE_TIMESTAMP;
    pub const INT64 : c_uint = clib.BSON_TYPE_INT64;
    pub const DECIMAL128 : c_uint = clib.BSON_TYPE_DECIMAL128;
    pub const MAXKEY : c_uint = clib.BSON_TYPE_MAXKEY;
    pub const MINKEY : c_uint = clib.BSON_TYPE_MINKEY;
};

//
// Bson value
//
pub const Value = struct {
    value: clib.bson_value_t,

    pub fn asInt32(self: *const Value) BsonError!i32 {
        return (ValuePtr{
          .ptr = &self.value,
        }).asInt32();
    }

    pub fn asInt64(self: *const Value) BsonError!i64 {
        return (ValuePtr{
          .ptr = &self.value,
        }).asInt64();
    }

    pub fn destroy(self: *Value) void {
        clib.bson_value_destroy(&self.value);
    }
};

pub const ValuePtr = struct{
    ptr: *const clib.bson_value_t,

    /// Create a copy of the value
    /// Must be freed by `destroy()`
    pub fn copy(self: *const ValuePtr) Value {
        var result: clib.bson_value_t = undefined;
        clib.bson_value_copy(self.ptr, &result);

        return Value{
            .value = result,
        };
    }

    pub fn asInt32(self: *const ValuePtr) BsonError!i32 {
        if (self.ptr.value_type == Type.INT32) {
            return self.ptr.value.v_int32;
        }

        return BsonError.typeError;
    }

    pub fn asInt64(self: *const ValuePtr) BsonError!i64 {
        if (self.ptr.value_type == Type.INT64) {
            return self.ptr.value.v_int64;
        }

        return BsonError.typeError;
    }
};

//
// Bson iterator
//
pub const Iter = struct{
    it: clib.bson_iter_t,

    pub fn next(self: *Iter) bool {
        return clib.bson_iter_next(&self.it);
    }

    pub fn key(self: *Iter) [*:0]const u8 {
        return clib.bson_iter_key(&self.it);
    }

    ///
    /// Return the value currently pointed by the iterator.
    /// The value is invalided if the iterator is modified.
    pub fn value(self: *Iter) ValuePtr {
        return ValuePtr{
            .ptr = clib.bson_iter_value(&self.it),
        };
    }

};

//
// Bson
//
pub const Bson = struct{
    ptr: *clib.bson_t,

    pub fn destroy(self: *const Bson) void {
        clib.bson_destroy(self.ptr);
    }

    pub fn appendUtf8(self: *const Bson, key: [:0]const u8, value: [:0]const u8) !void {
        if (!clib.bson_append_utf8(self.ptr, key, -1, value, -1))
            return BsonError.bsonError;
    }

    pub fn appendInt32(self: *const Bson, key: [:0]const u8, value: i32) !void {
        if (!clib.bson_append_int32(self.ptr, key, -1, value))
            return BsonError.bsonError;
    }

    pub fn appendInt64(self: *const Bson, key: [:0]const u8, value: i64) !void {
        if (!clib.bson_append_int64(self.ptr, key, -1, value))
            return BsonError.bsonError;
    }

    pub fn asCanonicalExtendedJson(self: *const Bson) !Json {
        var l: usize = undefined;

        if (clib.bson_as_canonical_extended_json(self.ptr, &l)) |json| {
            return Json{
                .ptr = json,
            };
        }

        return BsonError.bsonError;
    }

    pub fn hasField(self: *const Bson, key: [:0]const u8) bool {
        return clib.bson_has_field(self.ptr, key);
    }

    pub fn iter(self: *const Bson) BsonError!Iter {
        var it: clib.bson_iter_t = undefined;

        if (clib.bson_iter_init(&it, self.ptr)) {
            return Iter{
              .it = it,
            };
        }

        return BsonError.bsonError;
    }
};

pub fn new() !Bson {
    if (clib.bson_new()) |b| {
        return Bson{
          .ptr = b,
        };
    }

    return BsonError.allocError;
}
