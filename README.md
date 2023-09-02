# SightCom

In my country, there exists an inequality affecting visually impaired individuals who lack access to essential accessibility services. This has driven me to create a mobile app that can harness the power of AI to offer a transformative solution. By enabling the visually impaired to understand the world around them, this app directly aligns with two crucial United Nations Sustainable Development Goals (UNSDGs): Goal 3 - "Good Health and Well-being," and Goal 10 - "Reduced Inequalities." 

The app is constructed using the Flutter framework for the frontend, while the backend relies on the Clarifai API for AI processing. The app also queries a database lookup API for relevant product information based on the barcode.

The app contains five accessibility features, all of which can be activated through voice commands. These features are:
- [Scene Description](https://clarifai.com/salesforce/blip/models/general-english-image-caption-blip-2): Leveraging image captioning technology, the app verbally describes the objects captured by the camera. 
- [Color Recognition](https://clarifai.com/clarifai/main/models/color-recognition): The app enables users to identify colors of objects.
- [Text Recognition](https://clarifai.com/clarifai/main/models/ocr-scene-english-paddleocr): The app utilizes Optical Character Recognition (OCR) technology to convert text within the camera's view into speech.
- [Product Reader](https://clarifai.com/yuchen/workflow-test/models/BARCODE-QRCODE-Reader): Once a barcode is scanned, the app provides users with information about the product. [Barcode Lookup API](https://www.barcodelookup.com/)
- [QnA Chatbot](https://clarifai.com/meta/Llama-2/models/llama2-7b-chat): Powered by Llama 2 technology, users can asks questions and get responses from a virtual assistant. 

Check out more details about this project in this [Pitch Deck Slides](https://drive.google.com/file/d/16VvwspJh95xprBT_IIUpXIdf8I7wWhnF/view?usp=sharing)
