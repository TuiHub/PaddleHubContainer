FROM python:3.7.10-slim

ARG PADDLE_OCR_TAG=release/2.6

ARG APT_PACKAGES="\
    git \
    g++ \
    libglib2.0-dev \
    libgl1-mesa-glx \
    libsm6 \
    libxrender1\
"
ARG PYTHON_PACKAGES="\
    shapely==1.8.1.post1 \
    scikit-image==0.17.2 \
    imgaug==0.4.0 \
    pyclipper==1.3.0.post2 \
    lmdb==1.3.0 \
    tqdm==4.64.0 \
    numpy==1.21.6 \
    visualdl==2.2.3 \
    python-Levenshtein==0.12.2 \
    opencv-contrib-python==4.2.0.32 \
    paddlenlp==2.0.0 \
    paddle2onnx==0.5.1 \
    paddlepaddle==2.4.2 \
    paddlehub==2.1.0 \
"

RUN apt-get update \
    && apt-get install -y --no-install-recommends $APT_PACKAGES \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir $PYTHON_PACKAGES

RUN git clone --depth 1 --branch $PADDLE_OCR_TAG https://github.com/PaddlePaddle/PaddleOCR /PaddleOCR

WORKDIR /PaddleOCR

RUN pip install --no-cache-dir -r requirements.txt

RUN mkdir -p /PaddleOCR/inference/
ADD https://paddleocr.bj.bcebos.com/PP-OCRv3/chinese/ch_PP-OCRv3_det_infer.tar /PaddleOCR/inference/
RUN tar xf /PaddleOCR/inference/ch_PP-OCRv3_det_infer.tar -C /PaddleOCR/inference/

ADD https://paddleocr.bj.bcebos.com/dygraph_v2.0/ch/ch_ppocr_mobile_v2.0_cls_infer.tar /PaddleOCR/inference/
RUN tar xf /PaddleOCR/inference/ch_ppocr_mobile_v2.0_cls_infer.tar -C /PaddleOCR/inference/

ADD https://paddleocr.bj.bcebos.com/PP-OCRv3/chinese/ch_PP-OCRv3_rec_infer.tar /PaddleOCR/inference/
RUN tar xf /PaddleOCR/inference/ch_PP-OCRv3_rec_infer.tar -C /PaddleOCR/inference/

RUN rm -rf /root/.cache/*

RUN hub install deploy/hubserving/ocr_system/
RUN hub install deploy/hubserving/ocr_cls/
RUN hub install deploy/hubserving/ocr_det/
RUN hub install deploy/hubserving/ocr_rec/

EXPOSE 9000

CMD ["/bin/bash","-c","hub serving start --modules ocr_system ocr_cls ocr_det ocr_rec -p 9000"]
