import zipfile, os
from shutil import copyfile, copytree, rmtree
from subprocess import call


def has_admin():
    if os.name == 'nt':
        try:
            temp = os.listdir(os.sep.join([os.environ.get('SystemRoot', 'C:\\windows'), 'temp']))
            return True
        except:
            return False
        else:
            return False


def extractZip(zip, dest):
    try:
        print("Unzipping " + zip)
        zf = zipfile.ZipFile(zip, "r")
        zf.extractall(dest)
        zf.close()
    except WindowsError or PermissionError or FileNotFoundError as e:
        exit(e)


if not has_admin():
    exit("Please run with admin privileges.")

choban = os.getcwd() + "\\choban.zip"
dir = os.getcwd()
programData = os.getenv("programdata")
cobanPath = programData + "\\choban"
toolsPath = os.getenv("programfiles") + "\\tools"

if os.path.exists("choban.zip"):
    if not os.path.exists(os.getcwd()+"\\choban"):
        os.makedirs(os.getcwd() + "\\choban\\programData")

    if os.path.exists(choban):
        extractZip(choban, os.getcwd() + "\\choban\\programData")

    copytree(dir + "\\choban\\programData", cobanPath)
    call("cmd /c setx chobanPath " + cobanPath)
    call('cmd /c setx chobanTools {0}'.format('"' + toolsPath + '"'))
    call('setx /M PATH "%PATH%;{0}"'.format(cobanPath))
    call('cmd /c choban --doctor')
    print("Sucessfully installed Choban. Please restart your command prompt and type choban --doctor for the first time.")
else:
    exit("choban.zip does not exists.")
