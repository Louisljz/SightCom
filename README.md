# SightCom

In my country, there exists an inequality affecting visually impaired individuals who lack access to essential accessibility services. This has driven me to create a mobile app that can harness the power of AI to offer a transformative solution. By enabling the visually impaired to understand the world around them, this app directly aligns with two crucial United Nations Sustainable Development Goals (UNSDGs): Goal 3 - "Good Health and Well-being," and Goal 10 - "Reduced Inequalities." 

The app is constructed using the Flutter framework for the frontend, while the backend relies on the Clarifai API for AI processing. The app also queries a database lookup API for relevant product information based on the barcode.

The app contains five accessibility features, all of which can be activated through voice commands. These features are:
- Scene Description: Leveraging image captioning technology, the app verbally describes the objects captured by the camera.
- Color Recognition: The app enables users to identify colors of objects.
- Text Recognition: The app utilizes Optical Character Recognition (OCR) technology to convert text within the camera's view into speech.
- Product Reader: Once a barcode is scanned, the app provides users with information about the product.
- QnA Chatbot: Powered by Llama 2 technology, users can asks questions and get responses from a virtual assistant. 
