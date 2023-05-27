import streamlit as st
from PIL import Image
from SeeingAI.scene_desc import DescribeScene

st.set_page_config('Seeing AI Prototype', ':eyes:')
st.title('Seeing AI Prototype :eyes:')

tab1, tab2 = st.tabs(['Scene Description', 'Currency Recognition'])

with tab1:
    scene = DescribeScene(st.secrets['SeeingAI']['GPTKey'])
    buffer = st.camera_input('Take a picture of your surrounding!')
    if buffer:
        img = Image.open(buffer)
        anot, labels = scene.detect_objects(img)
        desc = scene.describe(labels)
        st.image(anot)
        st.text(desc)
