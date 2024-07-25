#!/usr/bin/env python

from setuptools import setup
from eepastecli.__init__ import __version__ as eepastecli_version

with open("README.rst") as readme:
    long_description = readme.read()

with open("requirements.txt") as f:
    install_requires = f.read().split()

setup(
    name='EePasteCLI',
    version=eepastecli_version,
    description='Easter-eggs PrivateBin instance client for command line (based on pbincli)',
    long_description=long_description,
    long_description_content_type='text/x-rst',
    author='Easter-eggs',
    author_email='info@easter-eggs.com',
    url='https://gitlab.easter-eggs.com/ee/ee-paste-cli/',
    keywords='privatebin cryptography security',
    license='MIT',
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Topic :: Security :: Cryptography',
        'Topic :: Utilities',
    ],
    packages=['eepastecli'],
    install_requires=install_requires,
    python_requires='>=3',
    entry_points={
        'console_scripts': [
            'ee-paste=eepastecli.cli:main',
        ],
    },
    project_urls={
        'Bug Reports': 'https://gitlab.easter-eggs.com/ee/ee-paste-cli/issues',
        'Source': 'https://gitlab.easter-eggs.com/ee/ee-paste-cli/',
    },
)
