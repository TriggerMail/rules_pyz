#!/usr/bin/env python
import json
import os
import stat
import sys
import time
import zipfile


def copy_files(zf, files_json):
    utc_now_parts = time.gmtime(time.time())
    for file_json in files_json:
        src = file_json['src']
        dst = file_json['dst']

        with open(src, 'rb') as in_f:
            data = in_f.read()

        # preserve the existing file's date time and permissions
        # https://stackoverflow.com/questions/39296101/python-zipfile-removes-execute-permissions-from-binaries
        src_stat = os.stat(src)
        zinfo = zipfile.ZipInfo(dst, time.gmtime(src_stat.st_mtime))
        zinfo.external_attr = src_stat.st_mode << 16
        zf.writestr(zinfo, data)


def link_manifest(parsed_manifest):
    output_path = parsed_manifest['output_path']
    interpreter_path = parsed_manifest['interpreter_path']
    if not interpreter_path.startswith('/'):
        interpreter_path = '/usr/bin/env ' + interpreter_path
    # Cannot add -S: runpy is in site-packages and is needed to load a zip
    # we have hacks in __main__.py to clean the environment, so don't pass args

    with open(output_path, 'wb') as f:
        f.write('#!')
        f.write(interpreter_path.encode('utf-8'))
        f.write('\n')

        # TODO: Time with ZIP_STORED; switch based on debug mode?
        with zipfile.ZipFile(f, 'w', zipfile.ZIP_DEFLATED) as zf:
            copy_files(zf, parsed_manifest['files'])

    os.chmod(output_path, 0755)


def main():
    if len(sys.argv) != 2:
        sys.stderr.write('Usage: linkzip (manifest.json path)\n')
        sys.exit(1)

    manifest_path = sys.argv[1]
    with open(manifest_path) as f:
        parsed_manifest = json.load(f)
    link_manifest(parsed_manifest)



if __name__ == '__main__':
    main()
