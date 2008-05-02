use inc::Module::Install;

name 'JS-jQuery-Loader';
all_from 'lib/JS/jQuery/Loader.pm';

build_requires 'Test::More';

auto_install;

WriteAll;

