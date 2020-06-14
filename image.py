import numpy as np
import matplotlib.pyplot as plt

f = open("./firmware/image.dat", 'rb')
image = np.arange(784).reshape(28, 28)
for i in range(3):
    for i in range(28):
        for j in range(28):
            data = int(f.read(32), 2)
            f.read(1)
            print(data)
            image[i][j] = data
    imgplot = plt.imshow(image, cmap='gray')
    plt.show()
