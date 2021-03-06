import os
import time
from docker import Client

from config import TIME_LIMIT


class TimeLimitReached(Exception):

    """Used in tests to limit blocking time."""


def time_limit_reached(start_time):
    if TIME_LIMIT < (time.time() - start_time):
        raise TimeLimitReached


def retry(func):
    success = False
    start_time = time.time()
    while not success and not time_limit_reached(start_time):
        print('retry: ' + func.func_name)
        success = func() is True
        if success is not True:
            time.sleep(1)
            continue
    return success


def build_docker_image(nocache=False, pull=True):
    version = os.environ.get('VERSION', 'sles12sp1')
    flavor = os.environ.get('FLAVOR') or 'products'
    docker_client = Client(base_url='unix://var/run/docker.sock')

    return docker_client.build(
        tag='registry.mgr.suse.de/toaster-{0}-{1}'.format(version, flavor),
        dockerfile='Dockerfile.{0}.{1}'.format(version, flavor),
        path=os.getcwd() + '/docker/',
        pull=pull,
        decode=True,
        forcerm=True,
        nocache=nocache
    )
