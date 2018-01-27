import os.path
import sys

def main():
    print '__file__', __file__
    # find the path containing this script: there should be a file called "resource.txt" there
    resource_path = os.path.join(os.path.dirname(__file__), 'resource.txt')
    with open(resource_path) as f:
        sys.stdout.write(f.read())


if __name__ == '__main__':
    main()
