# ===----------------------------------------------------------------------=== #
#
# This file is Modular Inc proprietary.
#
# ===----------------------------------------------------------------------=== #
"""Implements the Error class.

These are Mojo built-ins, so you don't need to import them.
"""

from sys.info import alignof, sizeof

from memory.memory import _aligned_free, memcmp, memcpy
from memory.unsafe import DTypePointer

# ===----------------------------------------------------------------------===#
# Error
# ===----------------------------------------------------------------------===#


@register_passable
struct Error(Stringable):
    """This type represents an Error."""

    var data: DTypePointer[DType.int8]
    """A pointer to the beginning of the string data being referenced."""

    var loaded_length: Int
    """The length of the string being referenced.
    Error instances conditionally own their error message. To reduce
    the size of the error instance we use the sign bit of the length field
    to store the ownership value. When loaded_length is negative it indicates
    ownership and a free is executed in the destructor.
    """

    @always_inline("nodebug")
    fn __init__() -> Error:
        """Default constructor.

        Returns:
            The constructed Error object.
        """
        return Error {data: DTypePointer[DType.int8](), loaded_length: 0}

    @always_inline("nodebug")
    fn __init__(value: StringLiteral) -> Error:
        """Construct an Error object with a given string literal.

        Args:
            value: The error message.

        Returns:
            The constructed Error object.
        """
        return Error {data: value.data(), loaded_length: len(value)}

    @always_inline("nodebug")
    fn __init__(src: String) -> Error:
        """Construct an Error object with a given string.

        Args:
            src: The error message.

        Returns:
            The constructed Error object.
        """
        let length = len(src)
        let dest = Pointer[Int8].alloc(length + 1)
        memcpy(dest, src._as_ptr(), length)
        dest[length] = 0
        return Error {data: dest, loaded_length: -length}

    @always_inline("nodebug")
    fn __init__(borrowed src: StringRef) -> Error:
        """Construct an Error object with a given string ref.

        Args:
            src: The error message.

        Returns:
            The constructed Error object.
        """
        let length = len(src)
        let dest = DTypePointer[DType.int8].alloc(length + 1)
        memcpy(dest, src.data, length)
        dest[length] = 0
        return Error {data: dest, loaded_length: -length}

    fn __del__(owned self):
        """Releases memory if allocated."""
        if self.loaded_length < 0:
            self.data.free()

    @always_inline("nodebug")
    fn __copyinit__(existing: Self) -> Self:
        """Creates a deep copy of an existing error.

        Returns:
            The copy of the original error.
        """
        if existing.loaded_length < 0:
            let length = -existing.loaded_length
            let dest = Pointer[Int8].alloc(length + 1)
            memcpy(dest, existing.data, length)
            dest[length] = 0
            return Error {data: dest, loaded_length: existing.loaded_length}
        else:
            return Error {
                data: existing.data, loaded_length: existing.loaded_length
            }

    fn __bool__(self) -> Bool:
        """Returns True if the error is set and false otherwise.

        Returns:
          True if the error object contains a value and False otherwise.
        """
        return self.data.__bool__()

    fn __str__(self) -> String:
        """Converts the Error to string representation.

        Returns:
            A String of the error message.
        """
        return self._message()

    fn __repr__(self) -> String:
        """Converts the Error to printable representation.

        Returns:
            A printable representation of the error message.
        """
        return self.__str__()

    fn _message(self) -> String:
        """Converts the Error to string representation.

        Returns:
            A String of the error message.
        """
        if not self:
            return ""

        var length = self.loaded_length
        if length < 0:
            length = -length
        return String(StringRef(self.data, length))
