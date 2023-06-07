import streamlit as st
from PIL import Image
from SeeingAI.scene_desc import DescribeScene
import json

st.set_page_config('SightCom', ':eyes:')
st.title('SightCom :eyes:')

with open('translations.json', 'r') as f:
    trans = json.loads(f.read())

lang = st.radio('Select a Language: ', ('English', 'Indonesian'))
tab_names = trans[lang]['tabs']
tabs = st.tabs(tab_names)

with tabs[0]:
    scene = DescribeScene(st.secrets['SightCom']['GPTKey'])
    buffer = st.camera_input('Take a picture of your surrounding!')
    if buffer:
        img = Image.open(buffer)
        anot, labels = scene.detect_objects(img)
        desc = scene.describe(labels)
        st.image(anot)
        st.text(desc)
