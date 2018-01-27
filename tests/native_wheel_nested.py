import cryptography.hazmat.backends


def main():
    # previously failed due to having native libs in a package tree
    backend = cryptography.hazmat.backends.default_backend()
    print 'backend:', backend


if __name__ == '__main__':
    main()
