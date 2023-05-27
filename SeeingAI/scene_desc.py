from ultralytics import YOLO
from ultralytics.yolo.utils.plotting import Annotator
import numpy as np
import openai
import os

class DescribeScene:
    def __init__(self, key):
        self.model = YOLO('yolov8n.pt')
        openai.api_key = key
       
    def detect_objects(self, img):
        img = np.array(img)
        results = self.model.predict(img, verbose=False)

        labels = []
        for r in results:
            annotator = Annotator(img)
            boxes = r.boxes
            for box in boxes:
                b = box.xyxy[0]
                cls = self.model.names[int(box.cls)]
                labels.append(cls)
                annotator.box_label(b, cls, color=(255, 0, 0)) 

        anot = annotator.result()
        return anot, labels

    def describe(self, labels):
        prompt = f'''
        create a scene description (one short sentence) from these labels 
        detected by YOLO model: {labels}
        Don't include uncertain info.
        '''
        completion = openai.ChatCompletion.create(
                        model = 'gpt-3.5-turbo',
                        messages = [
                            {'role': 'user', 'content': prompt}
                        ],
                        temperature = 0)

        return completion['choices'][0]['message']['content']

if __name__ == "__main__":
    import pyttsx3
    from PIL import Image
    scene = DescribeScene()
    engine = pyttsx3.init()
    img = Image.open('test.jpg')
    anot, labels = scene.detect_objects(img)
    desc = scene.describe(labels)
    engine.say(desc)
    engine.runAndWait()
