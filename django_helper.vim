"django_helper.vim Some Helper Scripts for django
"Intro {{{1
"
"Author Michael Brown <mjbrownie@ NOSPAMMY gmail.com>
"
"if !findfile("settings.py") || !has("python")
"    finish
"endif
"Global variables defaults {{{1
if !exists('g:djhelp_split_command')
    let g:split_command = 'vert split'
endif

if !exists('g:djhelp_setup_templates')
    let g:djhelp_setup_templates = 1
endif

if !exists('g:djhelp_strip_tags')
    let g:djhelp_strip_tags = 0
endif

python << EOP
#Resolve a url to a tag {{{1
#
#Usage
#
#for a given django url path
#
#urlpatterns(
 #'/some/url/path', 'some.django.view.function_name'
#)
#
#:DUrl /some/relative/path/
#
#will resolve the path to the function and then call
#:tag function_name
#
#You need to have an up to date tags file and the command might choke on
#complicated views with lots of decorators etc.
#

import vim
try:
    from django.core.management import setup_environ
    import settings
    setup_environ(settings)
    from django.core.urlresolvers import resolve
except:
    pass

def url_to_tag(url):
    """
        gets the view funcname from a resolve call
    """
    try:
        f = resolve(url)[0]

        try:
            #undecorated
            func_name = f.func_name
        except:
            #decorated
            func_name = f.view_func.func_name

        print func_name

        vim.command ('tag '  + func_name)
    except:
       print 'Cant Resolve:' + url

#Set all template directories in path so gf will go to them correctly {{{1

template_paths = []

if int(vim.eval('g:djhelp_setup_templates') )== 1:
    try:
        from settings import INSTALLED_APPS, TEMPLATE_DIRS
        import sys,os

        for dir in TEMPLATE_DIRS:
            vim.command("set path+=" + dir)

        for path in sys.path:
            for app in INSTALLED_APPS:
                template_path = path + '/' + app.replace('.', '/') + '/templates'
                if os.path.exists(template_path):
                    vim.command("set path+=" + template_path)
                    template_paths.append(template_path)
    except:
        pass

#Test Client {{{1
def test_client(url, post=None , strip_tags = False):
    try:
        from django.test.client import Client

        c = Client()

        if not post:
            r = c.get(url)
        else:
            r = c.post(url, data=post)

        vim.command(vim.eval('g:split_command'))
        vim.command('enew')
        vim.current.buffer.append(r.content.split('\n'))
        if vim.eval( 'g:djhelp_strip_tags' ) == 1:
            vim.command('%s#<\_.\{-1,}>##g')
        else:
            vim.command('set ft=html')
        vim.command('norm gg')
        vim.command('set buftype=nofile')

    except:
        pass

EOP
"Function definitions  {{{1
com! -nargs=1 DUrlTag python url_to_tag(<f-args>)
com! -nargs=1 DClient python test_client(<f-args>)
