import os
import cv2
import numpy as np
import tempfile
from ultralytics import YOLO
from insightface.app import FaceAnalysis
from feat import Detector
from keras.models import load_model
from keras.preprocessing.image import img_to_array
from PIL import Image
import math

print("Import successful")

# ==================================================
# 0. SETUP
# ==================================================
os.environ["INSIGHTFACE_HOME"] = "D:/Software_Development/face_project"

# YOLOv8 Face Detector (boxes)
yolo_model = YOLO("yolov8x-face-lindevs.pt")

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

# Age Model (ResNet50 custom) - your model
AGE_MODEL_PATH = "age-detection-resnet50-model/best_model.h5"
age_model = load_model(AGE_MODEL_PATH)

# ==================================================
# Utilities / Helpers
# ==================================================
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
    # Try a few attribute names used by different insightface versions.
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
    """Return a nicely-cropped and eye-aligned face image (BGR)."""
    h_img, w_img = img.shape[:2]
    if matched_face is not None:
        try:
            bx1, by1, bx2, by2 = matched_face.bbox.astype(int)
            box = expand_box((bx1, by1, bx2, by2), expand_scale, w_img, h_img)
            crop = img[box[1]:box[3], box[0]:box[2]].copy()
            kps = extract_landmarks(matched_face)
            if kps is not None and kps.shape[0] >= 2:
                # first two points are usually eyes
                left_eye = (kps[0][0] - box[0], kps[0][1] - box[1])
                right_eye = (kps[1][0] - box[0], kps[1][1] - box[1])
                # ensure both eyes inside crop
                if all(0 <= v < crop.shape[1] for v in (left_eye[0], right_eye[0])) and \
                   all(0 <= v < crop.shape[0] for v in (left_eye[1], right_eye[1])):
                    dx = right_eye[0] - left_eye[0]
                    dy = right_eye[1] - left_eye[1]
                    angle = math.degrees(math.atan2(dy, dx))
                    # rotate crop to make eyes horizontal
                    (ch, cw) = crop.shape[:2]
                    M = cv2.getRotationMatrix2D((cw/2, ch/2), -angle, 1.0)
                    rotated = cv2.warpAffine(crop, M, (cw, ch), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REPLICATE)
                    return rotated
            # if no landmarks or not valid, return expanded bbox crop
            return crop
        except Exception as e:
            print(f"[DEBUG] align_and_extract (matched_face) failed: {e}")

    # fallback: use YOLO box expanded
    try:
        x1, y1, x2, y2 = yolo_box
        box = expand_box((x1, y1, x2, y2), expand_scale, w_img, h_img)
        crop = img[box[1]:box[3], box[0]:box[2]].copy()
        return crop
    except Exception as e:
        print(f"[DEBUG] align_and_extract (fallback) failed: {e}")
        return None

# ==================================================
# Age prediction (RGB input expected by Keras model)
# ==================================================
def predict_age(face_bgr):
    if face_bgr is None or face_bgr.size == 0:
        return "N/A"
    try:
        # Small-size guard
        h, w = face_bgr.shape[:2]
        if min(h, w) < 32:
            return "N/A"

        # Test-time augmentation (original + horizontal flip)
        crops = [face_bgr, cv2.flip(face_bgr, 1)]
        preds = []

        for c in crops:
            # convert to RGB (VERY IMPORTANT), resize to model input 256x256
            c_rgb = cv2.cvtColor(c, cv2.COLOR_BGR2RGB)
            c_resized = cv2.resize(c_rgb, (256, 256), interpolation=cv2.INTER_LINEAR)
            arr = img_to_array(c_resized) / 255.0
            arr = np.expand_dims(arr, axis=0)
            p = age_model.predict(arr, verbose=0)
            preds.append(p)

        preds = np.vstack(preds)  # shape (n_tta, dim)
        # regression if last dim == 1
        if preds.shape[-1] == 1:
            avg = float(preds.mean())
            age_val = int(round(avg))
        else:
            # classification: average class probabilities then argmax
            avg_probs = preds.mean(axis=0)  # shape (1, classes)
            age_val = int(np.argmax(avg_probs[0]))

        age_val = max(0, min(100, age_val))
        return age_val
    except Exception as e:
        print(f"[DEBUG] Age prediction failed: {e}")
        return "N/A"

# ==================================================
# Gender using matched insight_face (we return gender + confidence)
# ==================================================
def predict_gender_from_matched_face(matched_face, best_iou):
    if matched_face is None or best_iou < 0.25:
        return "N/A", 0.0
    try:
        gender_score = float(getattr(matched_face, "gender", 0.0))
        gender = "Male" if gender_score == 1 or gender_score > 0.5 else "Female"
        # insightface sometimes encodes gender as scalar 0/1; confidence not always present
        conf = gender_score if 0.0 <= gender_score <= 1.0 else min(max(gender_score, 0.0), 1.0)
        # If insightface provided a separate 'gender_score' or 'gender_prob', you can prefer that
        return gender, conf
    except Exception as e:
        print(f"[DEBUG] predict_gender_from_matched_face failed: {e}")
        return "N/A", 0.0

# ==================================================
# Emotion (Py-Feat) - robust: PIL or temp-file fallback
# ==================================================
def predict_emotion(face_bgr):
    if face_bgr is None or face_bgr.size == 0:
        return "Unknown", 0.0
    try:
        h, w = face_bgr.shape[:2]
        if min(h, w) < 48:
            return "Unknown", 0.0

        # convert to RGB and to PIL
        face_rgb = cv2.cvtColor(face_bgr, cv2.COLOR_BGR2RGB)
        pil_img = Image.fromarray(face_rgb)

        try:
            result = emotion_detector.detect_image(pil_img)
        except Exception as e_inner:
            # fallback: save to temp file and pass path
            tmpf = None
            try:
                tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
                tmpf = tmp.name
                tmp.close()
                # write BGR crop to file (cv2.imwrite expects BGR)
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
            # low-confidence filter
            if confidence < 0.30:
                return "Unknown", confidence
            return emotion, confidence
        else:
            return "Unknown", 0.0
    except Exception as e:
        print(f"[DEBUG] Emotion prediction failed: {e}")
        return "Unknown", 0.0

# ==================================================
# 2. MAIN SCRIPT
# ==================================================
if __name__ == "__main__":
    img_path = "profile.jpg"
    img = cv2.imread(img_path)
    if img is None:
        print(f"Error: Could not load image '{img_path}'")
        exit(1)

    # 1) YOLO face detection (boxes)
    yolo_results = yolo_model(img)
    # 2) InsightFace run once on the full image (for gender + landmarks)
    insight_faces = insight_app.get(img)
    print(f"[DEBUG] InsightFace returned {len(insight_faces)} faces")

    person_id = 1
    for r in yolo_results:
        for box in r.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            # validate box
            if x2 <= x1 or y2 <= y1:
                continue

            yolo_box = (x1, y1, x2, y2)
            # find matched insightface (if any)
            matched_face, best_iou = get_best_matched_insight_face(insight_faces, yolo_box, iou_threshold=0.25)

            # alignment + expanded crop (BGR)
            face_aligned = align_and_extract(img, matched_face, yolo_box, expand_scale=1.25)
            if face_aligned is None or face_aligned.size == 0:
                print(f"[DEBUG] Skipping person {person_id}: empty crop")
                continue

            # Age
            age = predict_age(face_aligned)

            # Gender
            gender, gender_conf = predict_gender_from_matched_face(matched_face, best_iou)

            # Emotion
            emotion, emo_conf = predict_emotion(face_aligned)

            # Log / print
            print(f"Person {person_id} -> Age: {age}, Gender: {gender} ({gender_conf:.2f}), Emotion: {emotion} ({emo_conf:.2f}), IoU: {best_iou:.2f}")

            # Draw results on image
            label = f"P{person_id} A:{age} G:{gender} E:{emotion}"
            cv2.rectangle(img, (x1, y1), (x2, y2), (0, 255, 0), 2)
            # background rectangle for label
            (tw, th), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 1)
            cv2.rectangle(img, (x1, max(0, y1 - 20)), (x1 + tw, y1), (0, 255, 0), -1)
            cv2.putText(img, label, (x1, y1 - 4), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 1)

            person_id += 1

    # show result
    cv2.imshow("Face Analysis", img)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
