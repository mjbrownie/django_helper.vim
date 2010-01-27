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
    except:
        print "Cant Resolve url %s" % (url,)
        return

    try:
        #undecorated
        func_name = f.func_name
    except:
        #decorated
        func_name = f.view_func.func_name

    vim.command ('tag '  + func_name)

#Set all template directories in path so gf will go to them correctly {{{1

template_paths = []

if int(vim.eval('g:djhelp_setup_templates') )== 1:
    try:
        from settings import INSTALLED_APPS, TEMPLATE_DIRS
        import sys,os

        for mydir in TEMPLATE_DIRS:
            vim.command("set path+=" + mydir)

        for path in sys.path:
            for app in INSTALLED_APPS:
                template_path = path + '/' + app.replace('.', '/') + '/templates'
                if os.path.exists(template_path):
                    vim.command("set path+=" + template_path)
                    template_paths.append(template_path)
            vim.command("set path +=" + path)
    except:
        pass

#Test Client {{{1
def test_client(url, post=None , strip_tags = False):
    try:
        from django.test.client import Client

        c = Client()

    except:
        vim.command("echo 'Failed to import Client'")
        return

    try:
        if not post:
            r = c.get(url)
        else:
            r = c.post(url, data=post)

    except:
        vim.command("echo 'Failed to GET Response'")
        return

    try:
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
        vim.command("echo 'Failed to append vim'")

try:
    from django.db.models.loading import get_models, get_app, get_apps, get_model
    import os

    def get_app_models(app_name = None):
        vim.current.line = " ".join(f._meta.object_name \
        for f in get_models(get_app(app_name)))
        vim.command("s/ /\r/g")

    def get_app_list():
        vim.current.line = " ".join(f._meta.object_name \
        for f in get_models(get_app(app_name)))
        vim.command("s/ /\r/g")

    def get_field_list(app_name, model_name):
        vim.current.line = " ".join(
            get_model(app_name,model_name)._meta.get_all_field_names())
        vim.command("s/ /\r/g")

    def generate_admin():
        b = vim.current.buffer
        p,n = os.path.split(b.name)

        if not n == 'models.py':
            print "active buffer is not a models.py"
            return ''

        p2, appname = os.path.split(p)

        vim.command("edit %s/admin.py" % p)

        for m in get_models(get_app(appname)):
            b = vim.current.buffer
            b.append("#Classes generated by DAdminGenerator ")
            b.append('from django.contrib import admin')

            b.append('from %s.models import %s' % (
                appname,
                ",".join([m._meta.object_name for m in get_models(get_app(appname))])
            ))

            for m in get_models(get_app(appname)):
                has_inlines, has_name  = False, False

                for i in [r.model._meta.object_name for r in \
                    m._meta.get_all_related_objects()]:
                    has_inlines = True
                    b.append("class %sInline(admin.StackedInline):" % i)
                    b.append("    model=%s" % i)

                b.append("class %sAdmin(admin.ModelAdmin):" % m._meta.object_name)

                if 'name' in m._meta.get_all_field_names():
                    has_name = True
                    b.append("    search_fields = ['name']")

                if has_inlines:
                    for i in [r.model._meta.object_name for r in \
                        m._meta.get_all_related_objects()]:
                        has_inlines = True
                        b.append("    inlines = [")
                        b.append("        %sInline," % i)
                        b.append("              ]")

                if not has_inlines and not has_name:
                    b.append("    pass")

                b.append("")

            b.append(["admin.site.register(%s,%sAdmin)" % \
                (m._meta.object_name ,m._meta.object_name) for m in \
                get_models(get_app(appname))])

            return False

except:
    pass

EOP
"Function definitions  {{{1
com! -nargs=1 DUrlTag python url_to_tag(<f-args>)
com! -nargs=1 DClient python test_client(<f-args>)
com! -nargs=1 DGetAppModels python get_app_models(<f-args>)
com! -nargs=* DGetModelFields python get_field_list(<f-args>)
com! DAdminGenerator python generate_admin()
