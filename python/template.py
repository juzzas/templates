#!/usr/bin/env python

# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# 
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <http://unlicense.org>

"""A simple python script template.
"""

from __future__ import print_function
import argparse
import logging
import os
import signal
import sys

class Processor(object):
    def __init__(self, infile, outfile):
        """Processor class constructor.

        Keyword arguments:
        infile -- File object of the input file
        outfile -- File object of the input file
        """
        self._infile = infile
        self._outfile = outfile
        self._remote_host = None
        self._remote_user = None
        self._remote_password = None
        
        if 'REMOTE_PASSWORD' in os.environ:
            self._remote_password = os.environ['REMOTE_PASSWORD']

    @property
    def infile(self):
        """Return the filename of the infile File object."""
        if not self._infile:
            return None

        return self._infile.name

    @property
    def outfile(self):
        """Return the filename of the outfile File object."""
        if not self._outfile:
            return None

        return self._outfile.name

    @property
    def remote_host(self):
        """Get the Remote Host property."""
        return self._remote_host

    @remote_host.setter
    def remote_host(self, val):
        """Set the Remote Host property."""
        self._remote_host = val

    @property
    def remote_user(self):
        """Get the Remote User property."""
        return self._remote_user

    @remote_user.setter
    def remote_user(self, val):
        """Set the Remote User property."""
        self._remote_user = val

    @property
    def remote_password(self):
        """Get the Remote Password property."""
        return self._remote_password

    @remote_password.setter
    def remote_password(self, val):
        """Set the Remote Password property."""
        self._remote_password = val

    def process(self):
        """ Process infile to outfile."""
        if not self._remote_password:
            raise RuntimeError("no password given or set REMOTE_PASSWORD variable in the environment")

        for line in self._infile:
            self._outfile.write(" >> " + line)


def signal_handler(signal, frame):
    logger.getLogger(__name__)
    logger.debug("term received")
    sys.exit(0)


def main(arguments):
    signal.signal(signal.SIGTERM, signal_handler)

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)

    parser.add_argument('infile', nargs='?', help="input file",
                        default=sys.stdin, type=argparse.FileType('r'))
    parser.add_argument('-r', '--remote', help="the remote host name or IP address", type=str, required=True)
    parser.add_argument('-u', '--username', help="the remote username", type=str, required=True)
    parser.add_argument('-p', '--password', help="the remote password", type=str)
    parser.add_argument('-o', '--outfile', help="output file",
                        default=sys.stdout, type=argparse.FileType('w'))
    parser.add_argument("-v", "--verbose", action="count",
                        help="increase output verbosity")

    args = parser.parse_args(arguments)

    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    logformatter = logging.Formatter('[ %(levelname)s ] %(message)s')

    # create console handler and set level to verbosity count
    ch = logging.StreamHandler()
    ch.setFormatter(logformatter)

    if args.verbose == 1:
        ch.setLevel(logging.INFO)
    elif args.verbose > 1:
        ch.setLevel(logging.DEBUG)
    else:
        ch.setLevel(logging.WARN)

    logger.addHandler(ch)

    # create file handler and set level to INFO
    fh = logging.FileHandler(filename='/tmp/{}.log'.format(os.path.basename(__file__)))
    fh.setLevel(logging.INFO)
    fh.setFormatter(logformatter)
    logger.addHandler(fh)

    try:
        exit_code = 0;

        processor = Processor(args.infile, args.outfile)
        if not processor:
            logger.critical("unable to process")
            exit(2)

        logger.info("Processing {} to {}".format(processor.infile, processor.outfile))

        if args.username:
            processor.remote_user = args.username

        if args.remote:
            processor.remote_host = args.remote

        if args.password:
            processor.remote_password = args.password

        logger.info("Host: {}".format(processor.remote_host))
        logger.info("User: {}".format(processor.remote_user))

        processor.process()

    except KeyboardInterrupt:
        logger.debug("quit")
        
    except RuntimeError, err:
        logger.error(str(err))
        exit_code = 1
        
    finally:
        logger.debug("done")

    return exit_code

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

