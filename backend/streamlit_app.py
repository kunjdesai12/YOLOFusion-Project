import streamlit as st
import cv2
import logging
import time
from datetime import datetime
import os
from ultralytics import YOLO
import numpy as np
import base64
from io import BytesIO
from PIL import Image

# ---------- Logging Setup ----------
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
os.makedirs("Logfiles", exist_ok=True)
log_filename = os.path.join("Logfiles", f"log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
file_handler = logging.FileHandler(log_filename)
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logger.addHandler(file_handler)

# ---------- Download Link for Snapshots ----------
def get_image_download_link(img, filename):
    buffered = BytesIO()
    img.save(buffered, format="JPEG")
    img_str = base64.b64encode(buffered.getvalue()).decode()
    href = f'<a href="data:image/jpeg;base64,{img_str}" download="{filename}">Download {filename}</a>'
    return href

# ---------- Face Detection Runner ----------
def run_detection(source, model):
    stframe = st.empty()
    metrics = st.empty()
    snapshot_container = st.empty()

    cap = cv2.VideoCapture(source)
    if not cap.isOpened():
        st.error("Unable to open video source")
        logger.error("Failed to open video/camera")
        return

    frame_count = 0
    # total_faces_detected = 0
    start_time = time.time()
    last_snapshot_time = start_time
    snapshot_interval = 10
    log_interval = 2
    last_log_time = start_time

    stop_button = st.sidebar.button("⛔ Stop Processing")

    while cap.isOpened() and not stop_button:
        ret, frame = cap.read()
        if not ret:
            st.warning("No more frames or failed to grab frame.")
            break

        results = model(frame)
        faces = 0
        for result in results:
            boxes = result.boxes.xyxy
            confidences = result.boxes.conf
            class_ids = result.boxes.cls
            for box, conf, cls in zip(boxes, confidences, class_ids):
                if int(cls) == 0 and conf > 0.3:
                    x1, y1, x2, y2 = map(int, box)
                    faces += 1
                    cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    cv2.putText(frame, f"Conf: {conf:.2f}", (x1, y1 - 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,0), 1)

        # total_faces_detected += faces
        frame_count += 1
        current_time = time.time()

        if current_time - last_log_time >= log_interval:
            fps = frame_count / (current_time - start_time)
            # metrics.markdown(f"**FPS:** {fps:.2f} &nbsp; | &nbsp; **Faces this frame:** {faces} &nbsp; | &nbsp; **Total Faces:** {total_faces_detected}")
            metrics.markdown(f"**FPS:** {fps:.2f} &nbsp; | &nbsp; **Faces this frame:** {faces}")

            last_log_time = current_time

        # Snapshot every 10 seconds
        if current_time - last_snapshot_time >= snapshot_interval:
            snap_name = f"snapshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
            snapshot_path = os.path.join("Data", snap_name)
            cv2.imwrite(snapshot_path, frame)
            img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            snapshot_container.markdown(get_image_download_link(img, snap_name), unsafe_allow_html=True)
            last_snapshot_time = current_time
            logger.info(f"Snapshot taken: {snapshot_path}")

        # Display Frame
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        stframe.image(rgb_frame, channels="RGB", use_container_width=True)

        time.sleep(0.03)

    cap.release()
    end_time = time.time()
    avg_fps = frame_count / (end_time - start_time)
    # st.success(f"✅ Detection Completed\n\n**Total Frames:** {frame_count}\n**Total Faces Detected:** {total_faces_detected}\n**Average FPS:** {avg_fps:.2f}")
    st.success(f"✅ Detection Completed\n\n**Total Frames:** {frame_count}\n**Average FPS:** {avg_fps:.2f}")

    logger.info("Detection complete")

# ---------- Main App ----------
def main():
    st.set_page_config(page_title="YOLOv8 Face Detection", layout="wide")
    st.title("🔍 Real-Time Face Detection using YOLOv8")
    st.markdown("Use your **webcam** or upload a **video** to run face detection using YOLOv8.")

    os.makedirs("Data", exist_ok=True)
    os.makedirs("weights", exist_ok=True)
    model_path = os.path.join("weights", "yolov8x.pt")

    try:
        model = YOLO(model_path)
        logger.info("YOLOv8 loaded successfully.")
    except Exception as e:
        st.error(f"❌ Model Load Failed: {e}")
        return

    # Sidebar input method
    st.sidebar.header("🎛️ Settings")
    input_choice = st.sidebar.radio("Choose Input Source", ["📁 Upload Video", "📷 Use Webcam"])

    if input_choice == "📁 Upload Video":
        uploaded_file = st.sidebar.file_uploader("Upload Video", type=["mp4", "avi", "mov"])
        if uploaded_file:
            temp_path = os.path.join("Data", f"video_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp4")
            with open(temp_path, "wb") as f:
                f.write(uploaded_file.read())
            st.sidebar.success("✅ Video uploaded. Click below to start.")
            if st.sidebar.button("▶ Start Detection"):
                run_detection(temp_path, model)

    elif input_choice == "📷 Use Webcam":
        if st.sidebar.button("📷 Start Webcam Detection"):
            run_detection(0, model)  # 0 is default webcam

if __name__ == "__main__":
    main()
