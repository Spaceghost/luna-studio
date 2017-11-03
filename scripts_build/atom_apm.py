#!/usr/bin/env python3

import atom_prepare as ap

import os
from distutils import dir_util
import fileinput
import glob
import subprocess
import shutil
import platform
import requests
import zipfile
import io
import sys
import system as system
from common import working_directory
import stack_build
import atom_prepare

#########################################################
#                     PATHS                             #
#########################################################

third_party_path = ap.prep_path('../dist/third-party/')
atom_home_path = ap.prep_path('../dist/user-config/atom')
studio_package_name = "luna-studio"
studio_atom_source_path = ap.prep_path("../luna-studio/atom")
package_config_path = ap.prep_path("../config/packages")
packages_path = atom_home_path + '/packages/'

paths = {
    system.systems.WINDOWS: {
        'apm': '/Atom/resources/app/apm/bin/apm.cmd',
        'oniguruma': '/Atom/resources/app/node_modules/oniguruma',
    },
    system.systems.LINUX: {
        'apm': '/atom/usr/share/atom/resources/app/apm/bin/apm',
        'oniguruma': '/atom/usr/share/atom/resources/app/node_modules/oniguruma',
    },
    system.systems.DARWIN: {
        'apm': '/Atom.app/Contents/Resources/app/apm/bin/apm',
        'oniguruma': '/Atom.app/Contents/Resources/app/node_modules/oniguruma',
    },
}

def get_path(name):
    try:
        return third_party_path + paths[system.system][name]
    except KeyError as e:
        print("Unknown system: {}".format(e.args[0]))


apm_path = get_path('apm')
oniguruma_path = get_path('oniguruma')


atom_packages = {
    'luna-syntax': 'git@github.com:luna/luna-studio-syntax-theme.git',
    'luna-dark-ui': 'git@github.com:luna/luna-studio-ui-theme.git',
    'luna-dpi': 'git@github.com:luna/luna-studio-dpi.git',
    'luna-toolbar': 'git@github.com:luna/luna-studio-toolbar.git',
    'settings-view': 'git@github.com:luna/atom-settings-view.git',
    'tool-bar': 'git@github.com:luna/tool-bar.git',
}

#########################################################
#                   APM UTILS                           #
#########################################################

def run_process(*pargs):
    """Run a subprocess, wait for it to finish a return its stdout

    The stdout is utf-8-decoded for convenience.
    """
    proc = subprocess.Popen(pargs, stdout=subprocess.PIPE)
    proc.wait()
    output = proc.stdout.read()
    return output.decode('utf-8')


def run_apm(command, *args):
    """Run: apm <command> [args], wait for it to finish and return the result

    Sets the ATOM_HOME env variable to the global `atom_home_path`.
    """
    os.environ['ATOM_HOME'] = atom_home_path
    return run_process(apm_path, command, *args)


def copy_studio (package_path, gui_url, frontend_args):
    if gui_url:
        try:
            r = requests.get(gui_url)
            z = zipfile.ZipFile(io.BytesIO(r.content))
            z.extractall(package_path)
        except:
            print("Can not download gui from given url")
            print("Building frontend")
            stack_build.build_ghcjs(frontend_args, dev_mode=True)
            atom_prepare.run(dev_mode=True)
    else:
        stack_build.build_ghcjs(frontend_args, dev_mode=True)
        atom_prepare.run(dev_mode=True)

    dir_util.copy_tree(studio_atom_source_path, package_path)


def apm_luna_atom_package (package_name, package_address):
    with working_directory(packages_path):
        output = run_process('git', 'clone', package_address, package_name)
        print(output)

        with working_directory(package_name):
            output2 = run_apm('install', '.')
            print(output2)


def apm_luna_local_atom_package (package_name, package_path):
    with working_directory(package_path):
        output2 = run_apm('install', '.')
        print(output2)
        output3 = run_apm('link', '.')
        print(output3)


def init_apm(gui_url, frontend_args, link):
    package_path = atom_home_path + '/packages/' + studio_package_name
    print("Initializing APM in: {}".format(package_path))
    oniguruma_package_path = package_path + '/node_modules/oniguruma'
    if link:
        with working_directory(studio_atom_source_path):
            output = run_apm('install', '.')
            print(output)
            output2 = run_apm('link', '.')
            print(output2)
    else:
        os.makedirs(package_path, exist_ok=True)
        copy_studio(package_path, gui_url, frontend_args)
        dir_util.copy_tree(oniguruma_path, oniguruma_package_path)
        with working_directory(package_path):
            output = run_apm('install', '.')
            print(output)


def list_packages():
    return run_apm('list', '--installed', '--bare')


def apm_package(package_name, package_version):
    print("Installing Atom package: {} (version: {}) to {}".format(package_name, package_version, os.getcwd()))
    output = run_apm('install', package_name + '@' + package_version)
    print(output)


def apm_packages():
    installed_packages = list_packages()
    print('Installed packages: ', installed_packages)
    with open(package_config_path) as f:
        packages_list = f.read().splitlines()
        for package in packages_list:
            [pkg_name, pkg_ver] = package.split()
            if pkg_name not in installed_packages:
                apm_package(pkg_name, pkg_ver)
            elif (pkg_name + '@' + pkg_ver) not in installed_packages:
                    run_apm('uninstall', pkg_name)
                    apm_package(pkg_name, pkg_ver)


def run(gui_url, frontend_args, link=False):
    print("Installing Atom packages")
    init_apm(gui_url, frontend_args, link)
    for pkg_name, pkg_url in atom_packages.items():
        apm_luna_atom_package(pkg_name, pkg_url)
    apm_packages()


# if __name__ == '__main__':
#     run()
