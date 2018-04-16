import sys
import traceback

print 'sys.path:', sys.path
print 'sys.modules:', sys.modules

_failed = False
def fail(module_name):
    global _failed
    sys.stderr.write('FAIL: import %s: expected import error\n' % (module_name))
    print 'google:', google.__path__
    _failed = True

try:
    import google
    fail('google')
except ImportError:
    traceback.print_exc()

try:
    import wheel
    fail('wheel')
except ImportError:
    traceback.print_exc()

if _failed:
    sys.exit(1)
else:
    print('SUCCESS')
