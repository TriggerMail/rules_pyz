import sys
import traceback

print 'sys.path:', sys.path
print 'sys.modules:', sys.modules

_failed = False
def fail():
    global _failed
    sys.stderr.write('FAIL: expected import error\n')
    print 'google:', google.__path__
    _failed = True

try:
    import google
    fail()
except ImportError:
    traceback.print_exc()

try:
    import wheel
    fail()
except ImportError:
    traceback.print_exc()

if _failed:
    sys.exit(1)
else:
    print('SUCCESS')
