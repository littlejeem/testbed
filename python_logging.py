#!/usr/bin/env python3

import logging

#logging.basicConfig(format='%(asctime)s - %(message)s', datefmt='%d-%b-%y %H:%M:%S', format='- %(levelname)s -')
logging.basicConfig(format='%(asctime)s ubuntudevelop %(name)s: %(levelname)s - %(message)s', datefmt='%b %d %H:%M:%S')

print("some stuff happening")

logging.debug('This is a debug message')
logging.info('This is an info message')
logging.warning('This is a warning message')
logging.error('This is an error message')
logging.critical('This is a critical message')
