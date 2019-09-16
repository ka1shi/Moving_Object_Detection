import numpy as np
import cv2
import PBAS_no_neigh_1


filename = 'car-overhead-1.avi'
#vidcap = imageio.get_reader(filename, 'ffmpeg')

#vidcap = VideoFileClip("car-overhead-1.avi")

vidcap = cv2.VideoCapture(filename)
print vidcap.grab()

#fourcc = cv2.VideoWriter_fourcc(*'XVID')
#out = cv2.VideoWriter('output.avi', fourcc, 25, (640, 480))

#out = cv2.VideoWriter("output.avi", cv2.VideoWriter_fourcc(*"XVID"), 30,(640, 480))

#fourcc =  cv2.cv.CV_FOURCC(*'XVID')
out = cv2.VideoWriter("output.avi", fourcc, 2, (640, 480), 1)

x = PBAS_no_neigh_1.initialize()
x.PBAS(vidcap, out)

vidcap.release()
out.release()
cv2.destroyAllWindows()
