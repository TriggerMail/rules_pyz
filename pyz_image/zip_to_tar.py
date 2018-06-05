#!/usr/bin/env python
import argparse
import calendar
import cStringIO
import sys
import tarfile
import zipfile


def copyfiles(in_zip, out_tar, add_prefix_dir):
    assert add_prefix_dir == '' or (add_prefix_dir[0] != '/' and add_prefix_dir[-1] == '/')
    for zinfo in in_zip.infolist():
        tarinfo = tarfile.TarInfo(add_prefix_dir + zinfo.filename)
        tarinfo.mtime = calendar.timegm(zinfo.date_time)
        tarinfo.mode = zinfo.external_attr >> 16
        if tarinfo.mode == 0:
            # some zip files may not have extended mode bits
            tarinfo.mode = 0644
        tarinfo.size = zinfo.file_size

        member_f = in_zip.open(zinfo)
        out_tar.addfile(tarinfo, member_f)


def zip_to_tar(zip_path, output_path, add_prefix_dir):
    if add_prefix_dir != '':
        assert add_prefix_dir[0] != '/'
        assert add_prefix_dir[-1] != '/'
        add_prefix_dir += '/'

    with zipfile.ZipFile(zip_path, 'r') as in_zip:
        with tarfile.open(output_path, 'w') as out_tar:
            copyfiles(in_zip, out_tar, add_prefix_dir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('zip_path', help='Path to the zip file to read')
    parser.add_argument('output_path', help='Path to the tar file to be created')
    parser.add_argument('--add_prefix_dir', help='Adds a directory prefix to all files', default='')
    args = parser.parse_args()

    zip_to_tar(args.zip_path, args.output_path, args.add_prefix_dir)


if __name__ == '__main__':
    main()
