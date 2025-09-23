import os
import cv2
import numpy as np
import tempfile
from ultralytics import YOLO
from insightface.app import FaceAnalysis
from feat import Detector
# import tensorflow as tf
from tensorflow.keras.models import load_model  # Use tensorflow.keras for compatibility
from tensorflow.keras.preprocessing.image import img_to_array
from PIL import Image
import math
import logging
from fastapi import FastAPI, WebSocket, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import base64
import colorsys
import torch
import torchvision
import torchvision.transforms as transforms

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ================== Environment Setup ==================
os.environ["INSIGHTFACE_HOME"] = "D:/Software_Development/face_project"  # Adjust if needed for server environment

# ================== Load Models ==================
try:
    logger.debug("Loading YOLO models...")

    # Object detection model (COCO pretrained yolov8x)
    object_model = YOLO("yolov8x.pt")

    # Face detection model (local downloaded yolov8x-face-lindevs)
    face_model = YOLO("yolov8x-face-lindevs.pt")

    # InsightFace (for gender, landmarks)
    insight_app = FaceAnalysis(name="buffalo_l", providers=['CPUExecutionProvider'])
    insight_app.prepare(ctx_id=0, det_size=(640, 640))

    # Py-Feat Emotion Detector
    emotion_detector = Detector(
        face_model="retinaface",
        landmark_model="mobilenet",
        au_model="xgb",
        emotion_model="resmasknet"
    )

    # Age Model (ResNet50 custom)
    AGE_MODEL_PATH = "age-detection-resnet50-model/best_model.h5"
    age_model = load_model(AGE_MODEL_PATH)

    logger.debug("Loading HAR model (R(2+1)D-18)...")
    har_model = torchvision.models.video.r2plus1d_18(weights=None)  # define model arch
    har_model.load_state_dict(torch.load("r2plus1d_18-91a641e6.pth"))  # load checkpoint
    har_model.eval()

    logger.debug("All models loaded successfully")
except Exception as e:
    logger.error(f"Failed to load models: {str(e)}")
    raise

# Color mapping for objects
object_class_names = object_model.names  # Use YOLO's actual trained class names
object_colors = {i: tuple(int(x * 255) for x in colorsys.hsv_to_rgb(i / 20.0, 0.7, 0.9)) for i in range(20)}
face_color = (0, 255, 0)

# Transformation for HAR model
video_transform = transforms.Compose([
    transforms.Resize((112, 112)),
    transforms.CenterCrop(112),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.43216, 0.394666, 0.37645],
                         std=[0.22803, 0.22145, 0.216989])
])

# ================== Utilities / Helpers ==================
def expand_box(box, scale, img_w, img_h):
    x1, y1, x2, y2 = box
    cx = (x1 + x2) / 2.0
    cy = (y1 + y2) / 2.0
    w = (x2 - x1) * scale
    h = (y2 - y1) * scale
    nx1 = int(max(0, cx - w / 2.0))
    ny1 = int(max(0, cy - h / 2.0))
    nx2 = int(min(img_w - 1, cx + w / 2.0))
    ny2 = int(min(img_h - 1, cy + h / 2.0))
    return nx1, ny1, nx2, ny2

def iou(boxA, boxB):
    xA = max(boxA[0], boxB[0])
    yA = max(boxA[1], boxB[1])
    xB = min(boxA[2], boxB[2])
    yB = min(boxA[3], boxB[3])
    interW = max(0, xB - xA)
    interH = max(0, yB - yA)
    interArea = interW * interH
    boxAArea = max(1, (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]))
    boxBArea = max(1, (boxB[2] - boxB[0]) * (boxB[3] - boxB[1]))
    return interArea / float(boxAArea + boxBArea - interArea + 1e-6)

def get_best_matched_insight_face(insight_faces, yolo_box, iou_threshold=0.3):
    best_iou = 0.0
    best_face = None
    for f in insight_faces:
        try:
            fx1, fy1, fx2, fy2 = f.bbox.astype(int)
        except Exception:
            continue
        score = iou(yolo_box, (fx1, fy1, fx2, fy2))
        if score > best_iou:
            best_iou = score
            best_face = f
    if best_iou >= iou_threshold:
        return best_face, best_iou
    return None, best_iou

def extract_landmarks(face_obj):
    attrs = ['kps', 'landmark_2d_106', 'landmark_2d_68', 'kps5', 'kps_5', 'landmark']
    for a in attrs:
        k = getattr(face_obj, a, None)
        if k is None:
            continue
        try:
            arr = np.asarray(k, dtype=float)
            if arr.ndim == 2 and arr.shape[1] >= 2 and arr.shape[0] >= 2:
                return arr
        except Exception:
            continue
    return None

def align_and_extract(img, matched_face, yolo_box, expand_scale=1.25):
    h_img, w_img = img.shape[:2]
    if matched_face is not None:
        try:
            bx1, by1, bx2, by2 = matched_face.bbox.astype(int)
            box = expand_box((bx1, by1, bx2, by2), expand_scale, w_img, h_img)
            crop = img[box[1]:box[3], box[0]:box[2]].copy()
            kps = extract_landmarks(matched_face)
            if kps is not None and kps.shape[0] >= 2:
                left_eye = (kps[0][0] - box[0], kps[0][1] - box[1])
                right_eye = (kps[1][0] - box[0], kps[1][1] - box[1])
                if all(0 <= v < crop.shape[1] for v in (left_eye[0], right_eye[0])) and \
                   all(0 <= v < crop.shape[0] for v in (left_eye[1], right_eye[1])):
                    dx = right_eye[0] - left_eye[0]
                    dy = right_eye[1] - left_eye[1]
                    angle = math.degrees(math.atan2(dy, dx))
                    (ch, cw) = crop.shape[:2]
                    M = cv2.getRotationMatrix2D((cw/2, ch/2), -angle, 1.0)
                    rotated = cv2.warpAffine(crop, M, (cw, ch), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
                    return rotated
            return crop
        except Exception as e:
            logger.debug(f"align_and_extract (matched_face) failed: {e}")

    try:
        x1, y1, x2, y2 = yolo_box
        box = expand_box((x1, y1, x2, y2), expand_scale, w_img, h_img)
        crop = img[box[1]:box[3], box[0]:box[2]].copy()
        return crop
    except Exception as e:
        logger.debug(f"align_and_extract (fallback) failed: {e}")
        return None

def predict_age(face_bgr):
    if face_bgr is None or face_bgr.size == 0:
        return "N/A"
    try:
        h, w = face_bgr.shape[:2]
        if min(h, w) < 32:
            return "N/A"

        crops = [face_bgr, cv2.flip(face_bgr, 1)]
        preds = []

        for c in crops:
            c_rgb = cv2.cvtColor(c, cv2.COLOR_BGR2RGB)
            c_resized = cv2.resize(c_rgb, (256, 256), interpolation=cv2.INTER_LINEAR)
            arr = img_to_array(c_resized) / 255.0
            arr = np.expand_dims(arr, axis=0)
            p = age_model.predict(arr, verbose=0)
            preds.append(p)

        preds = np.vstack(preds)
        if preds.shape[-1] == 1:
            avg = float(preds.mean())
            age_val = int(round(avg))
        else:
            avg_probs = preds.mean(axis=0)
            age_val = int(np.argmax(avg_probs))

        age_val = max(0, min(100, age_val))
        return age_val
    except Exception as e:
        logger.debug(f"Age prediction failed: {e}")
        return "N/A"

def predict_gender_from_matched_face(matched_face, best_iou):
    if matched_face is None or best_iou < 0.25:
        return "N/A", 0.0
    try:
        gender_score = float(getattr(matched_face, "gender", 0.0))
        gender = "Male" if gender_score == 1 or gender_score > 0.5 else "Female"
        conf = gender_score if 0.0 <= gender_score <= 1.0 else min(max(gender_score, 0.0), 1.0)
        return gender, conf
    except Exception as e:
        logger.debug(f"predict_gender_from_matched_face failed: {e}")
        return "N/A", 0.0

def predict_emotion(face_bgr):
    if face_bgr is None or face_bgr.size == 0:
        return "Unknown", 0.0
    try:
        h, w = face_bgr.shape[:2]
        if min(h, w) < 48:
            return "Unknown", 0.0

        face_rgb = cv2.cvtColor(face_bgr, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(face_rgb)

        try:
            result = emotion_detector.detect_image(pil_img)
        except Exception:
            tmpf = None
            try:
                tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
                tmpf = tmp.name
                tmp.close()
                cv2.imwrite(tmpf, face_bgr)
                result = emotion_detector.detect_image(tmpf)
            finally:
                if tmpf is not None and os.path.exists(tmpf):
                    try:
                        os.remove(tmpf)
                    except Exception:
                        pass

        if result is not None and hasattr(result, "emotions") and not result.emotions.empty:
            emotion = result.emotions.iloc[0].idxmax()
            confidence = float(result.emotions.iloc[0].max())
            if confidence < 0.30:
                return "Unknown", confidence
            return emotion, confidence
        else:
            return "Unknown", 0.0
    except Exception as e:
        logger.debug(f"Emotion prediction failed: {e}")
        return "Unknown", 0.0

# ================== Frame Processing ==================
def process_frame(frame, model, mode):
    class_names = object_class_names if mode == "object" else ["Face"]
    colors = object_colors if mode == "object" else {0: face_color}
    
    logger.debug(f"Processing frame in {mode} mode")
    results = model.predict(frame, conf=0.5)
    detections = []

    if mode == "face":
        insight_faces = insight_app.get(frame)
        logger.debug(f"InsightFace returned {len(insight_faces)} faces")

    for result in results[0].boxes:
        x1, y1, x2, y2 = map(int, result.xyxy[0])
        if x2 <= x1 or y2 <= y1:
            continue
        conf = float(result.conf[0])
        cls_id = int(result.cls[0])

        if mode == "object":
            label = class_names[cls_id]
            color = colors.get(cls_id, (255, 255, 255))
        else:
            yolo_box = (x1, y1, x2, y2)
            matched_face, best_iou = get_best_matched_insight_face(insight_faces, yolo_box, iou_threshold=0.25)
            face_aligned = align_and_extract(frame, matched_face, yolo_box, expand_scale=1.25)
            if face_aligned is None or face_aligned.size == 0:
                logger.debug(f"Skipping face: empty crop")
                continue

            age = predict_age(face_aligned)
            gender, gender_conf = predict_gender_from_matched_face(matched_face, best_iou)
            emotion, emo_conf = predict_emotion(face_aligned)

            label = f"{gender}, {age}, {emotion}"
            color = face_color

        detections.append({
            "x1": x1, "y1": y1, "x2": x2, "y2": y2,
            "conf": conf, "label": label, "color": color
        })
    logger.debug(f"Detections: {detections}")
    return detections

# ================== Endpoints ==================

@app.post("/detect_objects/")
async def detect_objects(file: UploadFile = File(...)):
    logger.debug(f"Received object detection request: {file.filename}")
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if frame is None:
            logger.error("Failed to decode image")
            raise HTTPException(status_code=400, detail="Invalid image")
        detections = process_frame(frame, object_model, "object")
        return {"detections": detections}
    except Exception as e:
        logger.error(f"Error in detect_objects: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/detect_faces/")
async def detect_faces(file: UploadFile = File(...)):
    logger.debug(f"Received face detection request: {file.filename}")
    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if frame is None:
            logger.error("Failed to decode image")
            raise HTTPException(status_code=400, detail="Invalid image")
        detections = process_frame(frame, face_model, "face")
        return {"detections": detections}
    except Exception as e:
        logger.error(f"Error in detect_faces: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/process_video/{mode}")
async def process_video(mode: str, file: UploadFile = File(...)):
    if mode not in ["object", "face", "har"]:
        logger.error(f"Invalid mode: {mode}")
        raise HTTPException(status_code=400, detail="Invalid mode. Use 'object', 'face', or 'har'.")
    
    temp_path = "temp_video.mp4"
    logger.debug(f"Saving video to {temp_path}")
    try:
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        
        cap = cv2.VideoCapture(temp_path)
        all_detections = []
        frame_num = 0
        
        if mode in ["object", "face"]:
            model = object_model if mode == "object" else face_model

            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break
                if frame_num % 5 == 0:  # Process every 5th frame
                    detections = process_frame(frame, model, mode)
                    all_detections.append({"frame": frame_num, "detections": detections})
                frame_num += 1

        elif mode == "har":
            frames = []
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret:
                    break
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                pil_frame = transforms.ToPILImage()(frame_rgb)
                tensor_frame = video_transform(pil_frame)
                frames.append(tensor_frame)
            cap.release()

            if len(frames) < 16:
                raise HTTPException(status_code=400, detail="Video too short for HAR (needs at least 16 frames).")

            video_tensor = torch.stack(frames[:16], dim=1).unsqueeze(0)  # (1, C, T, H, W)
            with torch.no_grad():
                outputs = har_model(video_tensor)
                pred_class = torch.argmax(outputs, dim=1).item()
            
            all_detections.append({"predicted_class_id": pred_class})

            logger.info(f"Human activity recognition done. Predicted class ID: {pred_class}")


        cap.release()
        os.remove(temp_path)
        logger.debug(f"Processed {frame_num} frames, returning {len(all_detections)} results")
        return {"results": all_detections}
    except Exception as e:
        logger.error(f"Error in process_video: {str(e)}")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise HTTPException(status_code=500, detail=str(e))

@app.websocket("/ws_detect/{mode}")
async def websocket_endpoint(websocket: WebSocket, mode: str):
    await websocket.accept()
    model = object_model if mode == "object" else face_model
    logger.debug(f"WebSocket connected for {mode} detection")
    
    try:
        while True:
            data = await websocket.receive_text()
            if data == "close":
                break
            img_bytes = base64.b64decode(data)
            frame = cv2.imdecode(np.frombuffer(img_bytes, dtype=np.uint8), cv2.IMREAD_COLOR)
            detections = process_frame(frame, model, mode)
            await websocket.send_json({"detections": detections})
    except Exception as e:
        logger.error(f"WebSocket error: {str(e)}")
    finally:
        await websocket.close()
        logger.debug("WebSocket closed")