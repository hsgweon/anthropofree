from setuptools import setup

setup(
    name="anthropofree",
    version="1.0.0",
    scripts=['bin/anthropofree'], # This links your wrapper script
    install_requires=[],          # Conda handles the heavy lifting
)
