import bcrypt
import cffi


def main():
    # from the CFFI documentation:
    # https://cffi.readthedocs.io/en/latest/overview.html#simple-example-abi-level-in-line
    ffi = cffi.FFI()
    ffi.cdef("int printf(const char *format, ...);")
    C = ffi.dlopen(None)
    C.printf("hello from printf\n")

    print 'bcrypt hashed:', bcrypt.hashpw('password', bcrypt.gensalt())


if __name__ == '__main__':
    main()
