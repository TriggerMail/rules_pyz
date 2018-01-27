import google
print 'google:', google, google.__path__
import google.cloud
print 'google.cloud:', google.cloud
import google.cloud.datastore


def main():
    # tests "extras" dependencies, as well as native dependencies
    # google.cloud is also an "implicit" namespace package: the tool needs to make it a "real"
    # package
    print 'datatore:', google.cloud.datastore


if __name__ == '__main__':
    main()
