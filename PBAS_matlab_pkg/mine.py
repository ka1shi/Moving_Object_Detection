import matlab.engine

def minefun(filename):

    eng = matlab.engine.start_matlab()
    video = eng.VideoReader(filename)
    out = eng.VideoWriter('output.avi')

    eng.PBAS(video, out, nargout=0)
    return out

if __name__ == '__main__':
    try:
        arg = sys.argv[1]
    except IndexError:
        arg = None

    return_val = minefun(arg)
