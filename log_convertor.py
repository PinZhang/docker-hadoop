# !/usr/bin/python

import os, sys, re
from urlparse import urlparse
from datetime import datetime

# TODO build path filters for each domain
path_filters = ['/adu-new.gif', '/adu.gif', 'adu-1.gif']
default_domain='adu.g-fox.cn'

output_files = {}
splitter = re.compile('\s*')
def process_log(row):
    # TODO field mapping?
    cols = map(''.join, re.findall(r'\"(.*?)\"|\[(.*?)\]|(\S+)', row))
    http_info = splitter.split(cols[4])

    ip = cols[0]
    timestamp = cols[3]
    method = http_info[0]
    url = http_info[1]
    status = cols[5]
    user_agent = cols[8]

    o = urlparse(url)
    if o.netloc == '':
        domain = default_domain
    else:
        domain = o.netloc

    url_path = o.path

    # Only handle the path in the filters
    if url_path not in path_filters:
        return

    url_query = o.query

    # part date string like: '15/Apr/2015:00:00:00'
    date = datetime.strptime(timestamp.split(' ')[0], '%d/%b/%Y:%H:%M:%S').date()
    date_str = '-'.join([str(date.year), str(date.month), str(date.day)])

    file_name = '$'.join([date_str, domain, url_path.replace('/', '_')])

    if output_files.has_key(file_name):
        f = output_files[file_name]
    else:
        f = open('log_data/' + file_name, 'w')
        output_files[file_name] = f

    f.write('\t'.join([date_str, domain, url_path, ip, timestamp, method, url_query, status, user_agent, '\n']))


def main():
    num = 0
    for line in sys.stdin:
        process_log(line)

        num += 1
        # print progress
        if num % 10000 == 0:
            print 'handled %d lines' % num

        # FIXME only handle 100 lines
        # if num > 100:
        #     break

    for file_name in output_files:
        f = output_files[file_name]
        f.flush()
        f.close()

if __name__ == '__main__':
    main()

