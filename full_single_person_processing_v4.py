import os
import time
import cv2
import numpy as np
import re
import csv
from datetime import datetime

# import open3d as o3d
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from sklearn.cluster import KMeans

plt.ion()
 
# Create a custom colormap
cmap = plt.cm.jet
cmaplist = [cmap(i) for i in range(cmap.N)]
cmaplist[0] = (0.0, 0.0, 0.0, 1.0)  # Set the color for the value 0 to black
# Create the new colormap
custom_cmap = mcolors.LinearSegmentedColormap.from_list('Custom cmap', cmaplist, cmap.N)

# Define the folders
# camera_folder = 'camera_images/'
camera_folder = 'C:/ProgramData/Lucid Vision Labs/ArenaView/ArenaJp/Jupyter Source Code Examples/myfolder/3D_data_output/'

# Sorting function
def natural_sort_key(s):
    # Extract the number using regex
    return int(re.search(r'\d+', s).group())

# Load the camera specs upon start up
def load_camera_matrix():
    # Get the dimensions of the image
    height, width = 480,640
    print('image shape width x height:',width,'x',height)
    # Camera field of view in degrees
    fov_x = 108
    fov_y = 78
    # Calculate the focal length in pixels
    f_x = width / (2 * np.tan(np.radians(fov_x) / 2))
    f_y = height / (2 * np.tan(np.radians(fov_y) / 2))
    # Assume the principal point is at the center of the image
    c_x, c_y = width / 2, height / 2
    camera_matrix = np.array([[f_x, 0, c_x], [0, f_y, c_y], [0, 0, 1]], dtype=np.float64)
    print('camera matrix loaded')
    return camera_matrix,f_x, f_y, c_x, c_y
    
# Depth map from images
def get_depth_map(img,clip=False):
    depth_scale_factor = 0.001 * 0.25 # convert raw values to meters
    # Apply the depth scale factor to convert to actual depth values
    depth_map = img * depth_scale_factor
    if clip:
        # Clipping the values in the depth map above the threshold
        clipping_threshold = clip
        clipped_depth_map = np.where(depth_map > clipping_threshold, 0, depth_map)
        return clipped_depth_map
    return depth_map

# Plot two images    
def display_2_images(img1,img2,fig=None,axes=None):
    # Clear the axes instead of the figure, to avoid re-creating it
    axes[0].cla()  # Clear the first axis
    axes[1].cla()  # Clear the second axis

    # Update the images in the existing figure
    axes[0].imshow(img1, cmap=custom_cmap, vmin=0, vmax=17.5)
    axes[1].imshow(img2, cmap=custom_cmap, vmin=0, vmax=17.5)

    # Redraw the updated plot
    fig.canvas.draw()
    fig.canvas.flush_events()

# Get the background image by using the median over an interval with spacing
def create_background(n_interval=720,n_used=10,images=None):
    """
    Use existing images to create background image.
    24 fps -> 720 for 30 seconds 
    """
    # total interval of frames from which n_used are selected for the background
    if len(images)<n_interval: 
        img_idx = np.linspace(0, len(images)-1, n_used, dtype=int)
        print('lower image count than interval:',img_idx)
    else:
        img_idx = np.linspace(len(images) - n_interval, len(images)-1, n_used, dtype=int)
        print('higher image count than interval:',img_idx)

    list_of_depth_maps = []
    selected_images = [images[i] for i in img_idx]
    for image_path in selected_images:
        img = cv2.imread(camera_folder+image_path, cv2.IMREAD_UNCHANGED)
        distortion_coefficients = np.array([-0.01, -0.0, -0.0, -0.0, -0.01], dtype=np.float64) 
        img_undistorted = cv2.undistort(img, camera_matrix, distortion_coefficients)
        clipped_depth_map_cor = get_depth_map(img_undistorted,clip=50)
        list_of_depth_maps.append(clipped_depth_map_cor)
    # calculate background with the median
    running_median = np.median(np.array(list_of_depth_maps), axis=0)

    return running_median

def apply_opening(image, kernel_size=3,er_it=1,op_it=1):
    """
    Applies erosion followed by dilation (opening) on a 2D numpy array.
    
    Parameters:
        image (numpy.ndarray): A 2D numpy array representing the image.
        kernel_size (int): Size of the structuring element (kernel). Default is 3.
    
    Returns:
        numpy.ndarray: The processed image after opening operation.
    """
    # Create a square kernel of the specified size
    kernel = np.ones((kernel_size, kernel_size), np.uint8)
    
    # Apply erosion
    eroded_image = cv2.erode(image, kernel, iterations=er_it)
    
    # Apply dilation
    opened_image = cv2.dilate(eroded_image, kernel, iterations=op_it)
    
    return opened_image

def remove_low_intensity(image, relative_threshold=0.25):
    """
    do a 'high pass filter' applied such that 
    the lowest relative_threshold fraction (percentage/100) of the maximum intensity in the image is removed
    """
    im_max = image.max()
    image  /= im_max
    processed_image = image
    processed_image[processed_image < relative_threshold] = 0
    processed_image *= im_max
    return processed_image

def preprocess_image(image):
    er_op_image = apply_opening(image,kernel_size=3,er_it=2,op_it=2)
    processed_image = remove_low_intensity(er_op_image, relative_threshold=0.25)
    return processed_image

def cluster_depth_map(depth_map):
    # Reshape depth map for clustering
    depth_values = depth_map.reshape(-1, 1)
    
    # Apply K-means clustering
    kmeans = KMeans(n_clusters=2, random_state=0).fit(depth_values)
    labels = kmeans.labels_.reshape(depth_map.shape)

    # Ensure the label with the most elements is 0
    label_counts = np.bincount(labels.flatten())
    if label_counts[1] > label_counts[0]:
        labels = 1 - labels  # Swap labels (0 becomes 1, and 1 becomes 0)
    return labels

def find_bounding_box_opencv_from_array(BW_image, plot_bb=False):
    binary_image = BW_image.astype(np.uint8)
    # Find contours
    contours, _ = cv2.findContours(binary_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Find the largest contour based on the area
    largest_contour = max(contours, key=cv2.contourArea)
    
    # Get the bounding box of the largest contour
    x, y, w, h = cv2.boundingRect(largest_contour)
    
    if plot_bb:
        # Draw the bounding box on the original image (for visualization)
        output_image = cv2.cvtColor(binary_image*255, cv2.COLOR_GRAY2BGR)
        cv2.rectangle(output_image, (x, y), (x+w, y+h), (0, 255, 0), 2)
        
        # Display the output image
        plt.imshow(cv2.cvtColor(output_image, cv2.COLOR_BGR2RGB))
        plt.title("Bounding Box")
        plt.axis('off')
        plt.show()
    
    return x, y, w, h
    
def find_two_bounding_boxes_opencv_from_array(BW_image, plot_bb=False):
    binary_image = BW_image.astype(np.uint8)
    
    # Find contours
    contours, _ = cv2.findContours(binary_image, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    # Sort contours based on area and take the two largest
    largest_contours = sorted(contours, key=cv2.contourArea, reverse=True)[:1]
    
    # Get the bounding boxes for the two largest contours
    bounding_boxes = [cv2.boundingRect(contour) for contour in largest_contours]
    
    # Calculate the areas for the bounding boxes
    bounding_box_areas = [(w * h) for (x, y, w, h) in bounding_boxes]
    
    if plot_bb:
        # Draw the bounding boxes on the original image (for visualization)
        output_image = cv2.cvtColor(binary_image * 255, cv2.COLOR_GRAY2BGR)
        for x, y, w, h in bounding_boxes:
            cv2.rectangle(output_image, (x, y), (x + w, y + h), (0, 255, 0), 2)
        
        # Display the output image
        plt.imshow(cv2.cvtColor(output_image, cv2.COLOR_BGR2RGB))
        plt.title("Bounding Boxes")
        plt.axis('off')
        plt.show()
    
    # Return both the bounding boxes and their corresponding areas
    return bounding_boxes, bounding_box_areas

def depth_map_to_point_cloud(depth_map, fx, fy, cx, cy, depth_scale): #, R, t
    point_cloud = []
    height, width = depth_map.shape
    for v in range(height):
        for u in range(width):
            if depth_map[v,u] != 0:
                d = depth_map[v, u] * depth_scale
                X_c = (u - cx) * d / fx
                Y_c = (v - cy) * d / fy
                Z_c = d 
                camera_point = np.array([X_c, Y_c, Z_c])
                camera_point = camera_point + [8,8,0]
                point_cloud.append(camera_point)
    return np.array(point_cloud)

def average_angle(image, fov_horizontal=108, fov_vertical=78):
    """
    Calculate the average angle of the elements that are 1 in the black and white image.
    The angle is relative to the camera's field of view (FOV).

    Args:
        image (numpy.ndarray): Black and white image (binary) as a numpy array.
        fov_horizontal (float): Horizontal field of view of the camera in degrees.
        fov_vertical (float): Vertical field of view of the camera in degrees.

    Returns:
        tuple: (average_horizontal_angle, average_vertical_angle)
    """
    # Get image dimensions
    height, width = image.shape

    # Angular resolution per pixel
    horizontal_angle_per_pixel = fov_horizontal / width
    vertical_angle_per_pixel = fov_vertical / height

    # Find coordinates of all pixels that are 1
    indices = np.argwhere(image == 1)

    if len(indices) == 0:
        return None, None  # No pixels with value 1, return None

    # Compute angles relative to the center of the image
    horizontal_angles = (indices[:, 1] - width / 2) * horizontal_angle_per_pixel
    vertical_angles = (indices[:, 0] - height / 2) * vertical_angle_per_pixel

    # Calculate average angles
    average_horizontal_angle = np.mean(horizontal_angles)
    average_vertical_angle = np.mean(vertical_angles)

    return average_horizontal_angle, average_vertical_angle

def calculate_bbox_angles(bounding_boxes, image, fov_horizontal=108, fov_vertical=78):
    angles = []
    image_height, image_width = image.shape
    
    # Image center
    center_x = image_width / 2
    center_y = image_height / 2
    
    # Convert FOV angles to radians for calculation
    fov_h_rad = np.deg2rad(fov_horizontal)
    fov_v_rad = np.deg2rad(fov_vertical)
    
    # Half the FOV in radians (from center to one edge)
    half_fov_h = fov_h_rad / 2
    half_fov_v = fov_v_rad / 2
    
    # Iterate over each bounding box and compute its center
    for (x, y, w, h) in bounding_boxes:
        # Find the center of the bounding box
        bbox_center_x = x + w / 2
        bbox_center_y = y + h / 2
        
        # Calculate the normalized distances from the image center
        norm_x = (bbox_center_x - center_x) / center_x  # normalized horizontal position (-1 to 1)
        norm_y = (bbox_center_y - center_y) / center_y  # normalized vertical position (-1 to 1)
        
        # Calculate the angles in radians
        angle_h = norm_x * half_fov_h
        angle_v = norm_y * half_fov_v
        
        # Convert angles to degrees
        angle_h_deg = np.rad2deg(angle_h)
        angle_v_deg = np.rad2deg(angle_v)
        
        # Store the results
        angles.append((angle_h_deg, angle_v_deg))
    
    return angles

def process_images(fx, fy, cx, cy, csv_filename):
    processing_idx = 0
    fig, axes = plt.subplots(1, 2, figsize=(10, 5))
    
    # Open CSV file to store bounding box and angle data
    with open(csv_filename, mode='a', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(['timestamp',
                         'x_1', 'y_1', 'w_1', 'h_1', 'angle_hor_1', 'angle_ver_1', 
                         'x_2', 'y_2', 'w_2', 'h_2', 'angle_hor_2', 'angle_ver_2'])  # CSV headers
        # x,y: coordinates of bottom left corner of bounding box
        # w,h: the width and height of the boxes
        # angle_hor,angle_ver: horizontal and vertical angles of centre of a box
        # calculate: w x h = area, 2w + 2h = circumference, (x+w/2,y+h/2) = (x,y)_centre
        while True:
            # List all files in the camera folder
            images = sorted(os.listdir(camera_folder), key=natural_sort_key)
            
            # Load last image and correct distortion
            img = cv2.imread(camera_folder + images[-1], cv2.IMREAD_UNCHANGED)
            distortion_coefficients = np.array([-0.01, -0.0, -0.0, -0.0, -0.01], dtype=np.float64)
            
            try:
                img_undistorted = cv2.undistort(img, camera_matrix, distortion_coefficients)
            except:
                img = cv2.imread(camera_folder + images[-2], cv2.IMREAD_UNCHANGED)
                img_undistorted = cv2.undistort(img, camera_matrix, distortion_coefficients)
            
            # Get depth map from corrected image
            clipped_depth_map_cor = get_depth_map(img_undistorted, clip=50)
            
            # Subtract background
            background_image = create_background(n_interval=120, n_used=10, images=images)
            bs_human_dm = -(clipped_depth_map_cor - background_image)
            
            # Clean the depth map
            cleaned_image = preprocess_image(bs_human_dm)
            
            # BW cluster with Kmeans for mask
            BW_dm = cluster_depth_map(cleaned_image)
            
            # Get bounding box
            bbox_opencv, bbox_areas = find_two_bounding_boxes_opencv_from_array(BW_dm, plot_bb=False)
            
            # Get angles of bounding box centers
            angles_list = calculate_bbox_angles(bbox_opencv, BW_dm, fov_horizontal=108, fov_vertical=78)
            
            # Plot the image with custom colormap
            axes[0].cla()  # Clear the first axis
            axes[1].cla()  # Clear the second axis
            axes[0].imshow(img, cmap='Greys')
            im0 = axes[1].imshow(clipped_depth_map_cor, cmap=custom_cmap, vmin=0, vmax=10)
            
            if processing_idx == 0:
                fig.colorbar(im0, label='Depth (meter)', pad=.05, fraction=0.034)
            
            for x, y, w, h in bbox_opencv:
                p = plt.Rectangle((x, y), w, h, fill=False, color='white')
                axes[1].add_patch(p)
            
            for i, (angle_hor, angle_ver) in enumerate(angles_list):
                text_str = f'horizontal: {angle_hor:.2f}$^\circ$\nvertical: {angle_ver:.2f}$^\circ$'
                axes[1].text(bbox_opencv[i][0], bbox_opencv[i][1] - 10, text_str, color='white', fontsize=10,
                             ha='right', va='bottom', bbox=dict(facecolor='black', alpha=0.5, pad=5))
            
            # Save bounding box data and angles to CSV file
            # If there are less than two bounding boxes, fill with placeholder values (e.g., None)
            current_timestamp = datetime.now().strftime("%d-%m-%y %H:%M:%S")
            bbox_data = [current_timestamp]
            for i in range(2):
                if i < len(bbox_opencv):
                    x, y, w, h = bbox_opencv[i]
                    angle_hor, angle_ver = angles_list[i]
                    bbox_data.extend([x, y, w, h, angle_hor, angle_ver])
                else:
                    bbox_data.extend([None, None, None, None, None, None])
            
            writer.writerow(bbox_data)
            
            # Redraw the updated plot
            fig.canvas.draw()
            fig.canvas.flush_events()
            processing_idx += 1
            time.sleep(.01)


if __name__ == "__main__":
    camera_matrix,fx, fy, cx, cy = load_camera_matrix()
    process_images(fx, fy, cx, cy,'C:/run_lidar_analysis/lidar_tracking.csv') # spanning 720 frames (30 seconds) use 10 frames
    # process_images(fx, fy, cx, cy,'lidar_tracking.csv') # spanning 720 frames (30 seconds) use 10 frames

