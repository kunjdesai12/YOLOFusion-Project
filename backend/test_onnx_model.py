import cv2
import numpy as np
import onnxruntime as ort

kinetics_labels = ["jumping jacks", "running", "yoga"]

model_path = r"D:\Software_Development\face_project\resnet-34_kinetics.onnx"  # Updated path
try:
    session = ort.InferenceSession(model_path)
    input_name = session.get_inputs()[0].name
    input_shape = session.get_inputs()[0].shape
    output_shape = session.get_outputs()[0].shape
    print(f"Model input shape: {input_shape}, output shape: {output_shape}")
except Exception as e:
    print(f"Failed to load model: {e}")
    exit(1)

def preprocess_frame_for_har(frames, expected_time_steps=16):
    """Resize and normalize a sequence of frames for HAR model"""
    if len(frames) == 0:
        raise ValueError("No frames to process")
    
    resized_frames = [cv2.resize(frame, (112, 112)).astype(np.float32) for frame in frames]  # Changed to 112x112
    
    if len(resized_frames) < expected_time_steps:
        last_frame = resized_frames[-1]
        resized_frames.extend([last_frame] * (expected_time_steps - len(resized_frames)))
    elif len(resized_frames) > expected_time_steps:
        resized_frames = resized_frames[:expected_time_steps]
    
    frame_stack = np.stack(resized_frames, axis=0)
    frame_stack = np.transpose(frame_stack, (3, 0, 1, 2))  # [channels, time_steps, height, width]
    frame_stack = np.expand_dims(frame_stack, axis=0)  # [batch_size, channels, time_steps, height, width]
    frame_stack = frame_stack / 255.0  # Normalize to [0, 1]
    
    return frame_stack

video_path = r"D:\Software_Development\face_project\vedio\855564-hd_1920_1080_24fps.mp4"  # Update this path
cap = cv2.VideoCapture(video_path)

if not cap.isOpened():
    print(f"Error: Could not open video file {video_path}")
    exit(1)

frame_buffer = []
frame_num = 0

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    if frame_num % 5 == 0:
        frame_buffer.append(frame.copy())
        if len(frame_buffer) == 16:
            input_frame = preprocess_frame_for_har(frame_buffer)
            try:
                pred = session.run(None, {input_name: input_frame})[0]
                activity_class = int(np.argmax(pred))
                activity_class = max(0, min(activity_class, 2))  # Clamp to [0, 2] for 3 classes
                activity = kinetics_labels[activity_class]
                print(f"Frame {frame_num}: Predicted activity = {activity} (class {activity_class})")
            except Exception as e:
                print(f"Error processing frame {frame_num}: {e}")
            frame_buffer = frame_buffer[1:]  # Slide the window
    frame_num += 1

if len(frame_buffer) > 0:
    input_frame = preprocess_frame_for_har(frame_buffer)
    try:
        pred = session.run(None, {input_name: input_frame})[0]
        activity_class = int(np.argmax(pred))
        activity_class = max(0, min(activity_class, 2))  # Clamp to [0, 2]
        activity = kinetics_labels[activity_class]
        print(f"Frame {frame_num - 1}: Predicted activity = {activity} (class {activity_class})")
    except Exception as e:
        print(f"Error processing remaining frames: {e}")

cap.release()
print("Testing completed.")