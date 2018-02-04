# IMPORT ORDER IS CRITICAL
import sys
sys.path.insert(0, '.')

print 'orig', sys.path
orig_path = list(sys.path)

# google.cloud.datastore uses pkg_resources which messes with sys.path
# if the directory containing the zipped tools is on sys.path
import google.cloud.datastore

print 'after', sys.path
after_path = list(sys.path)

# should work: requires native code
import grpc


def main():
    if orig_path != after_path:
        print 'orig:', orig_path
        print 'after:', after_path
        raise Exception('paths should match')
    print 'SUCCESS'

if __name__ == '__main__':
    main()
